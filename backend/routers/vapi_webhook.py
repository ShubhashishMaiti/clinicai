import hashlib
import hmac
import json
import logging
from datetime import datetime, timezone

from fastapi import APIRouter, HTTPException, Request
from database import get_db
from config import settings
from services.vapi import handle_vapi_function_call, build_assistant_overrides
from services import twilio
from routers.websocket import broadcast
from models import Patient, Appointment, Notification

router = APIRouter()
logger = logging.getLogger(__name__)


def _serialize(doc: dict) -> dict:
    result = {}
    for k, v in doc.items():
        if isinstance(v, datetime):
            result[k] = v.isoformat()
        else:
            result[k] = v
    return result


@router.post("/webhook")
async def vapi_webhook(request: Request):
    body = await request.body()

    # HMAC verification
    signature = request.headers.get("x-vapi-signature", "")
    if signature:
        expected = hmac.new(
            settings.VAPI_SERVER_SECRET.encode(),
            body,
            hashlib.sha256,
        ).hexdigest()
        if not hmac.compare_digest(expected, signature):
            raise HTTPException(status_code=401, detail={"code": "UNAUTHORIZED", "message": "Invalid Vapi signature"})

    try:
        payload = json.loads(body)
    except json.JSONDecodeError:
        raise HTTPException(status_code=400, detail="Invalid JSON")

    message = payload.get("message", {})
    msg_type = message.get("type", "")
    call = message.get("call", {})

    # Resolve doctor from called phone number
    called_number = (
        call.get("phoneNumber", {}).get("number")
        or call.get("to")
        or payload.get("phoneNumber", {}).get("number", "")
    )

    db = get_db()
    doctor = None
    if called_number:
        doctor = await db.doctors.find_one({"inbound_phone": called_number}, {"_id": 0})

    if not doctor:
        # Fallback: first non-admin doctor
        doctor = await db.doctors.find_one({"is_admin": False}, {"_id": 0})

    if not doctor:
        return {"error": "No doctor found for this number"}

    doctor_id = doctor["doctor_id"]

    # Handle different message types
    if msg_type == "assistant-request":
        # Return assistant overrides with doctor context
        return build_assistant_overrides(doctor)

    elif msg_type == "function-call":
        func_call = message.get("functionCall", {})
        function_name = func_call.get("name", "")
        parameters = func_call.get("parameters", {})

        result = await handle_vapi_function_call(function_name, parameters, doctor)

        # If bookAppointment, upsert patient + appointment
        if function_name == "bookAppointment":
            await _handle_booking(db, doctor, parameters, result)

        return {"result": result.get("result", "Done")}

    elif msg_type == "end-of-call-report":
        # Log the call
        summary = message.get("summary", "")
        caller_phone = call.get("customer", {}).get("number", "")
        logger.info(f"Call ended for doctor {doctor_id}. Caller: {caller_phone}. Summary: {summary[:100]}")
        return {"received": True}

    # Default: return assistant overrides
    return build_assistant_overrides(doctor)


async def _handle_booking(db, doctor, parameters: dict, cal_result: dict):
    """Upsert patient + appointment from Vapi booking function call."""
    doctor_id = doctor["doctor_id"]
    patient_name = parameters.get("patientName", parameters.get("name", "Unknown"))
    patient_phone = parameters.get("patientPhone", parameters.get("phone", ""))
    reason = parameters.get("reason", "")
    start_time_str = parameters.get("startTime", parameters.get("date", ""))

    if not patient_phone:
        return

    # Upsert patient
    existing_patient = await db.patients.find_one(
        {"doctor_id": doctor_id, "phone": patient_phone}, {"_id": 0}
    )
    if existing_patient:
        patient_id = existing_patient["patient_id"]
    else:
        patient = Patient(
            doctor_id=doctor_id,
            name=patient_name,
            phone=patient_phone,
        )
        await db.patients.insert_one({**patient.model_dump(), "_id": patient.patient_id})
        patient_id = patient.patient_id

    # Parse start time
    try:
        if start_time_str:
            start_time = datetime.fromisoformat(start_time_str.replace("Z", "+00:00"))
        else:
            start_time = datetime.now(timezone.utc)
    except Exception:
        start_time = datetime.now(timezone.utc)

    from datetime import timedelta
    end_time = start_time + timedelta(minutes=30)

    # Create appointment
    appt = Appointment(
        doctor_id=doctor_id,
        patient_id=patient_id,
        patient_name=patient_name,
        patient_phone=patient_phone,
        reason=reason,
        start_time=start_time,
        end_time=end_time,
        status="confirmed",
        cal_booking_id=cal_result.get("booking_id"),
    )
    await db.appointments.insert_one({**appt.model_dump(), "_id": appt.appointment_id})

    # SMS confirmation
    await twilio.send_booking_confirmation(
        patient_phone, patient_name, doctor["name"],
        start_time.strftime("%b %d at %I:%M %p"),
    )

    # WebSocket broadcast
    await broadcast(doctor_id, {
        "event": "appointment.created",
        "appointment": _serialize(appt.model_dump()),
    })

    # Notification
    notif = Notification(
        doctor_id=doctor_id,
        title="New Booking via AI Receptionist",
        body=f"{patient_name} booked for {start_time.strftime('%b %d at %I:%M %p')}",
        type="booking",
        related_id=appt.appointment_id,
    )
    await db.notifications.insert_one({**notif.model_dump(), "_id": notif.notification_id})
