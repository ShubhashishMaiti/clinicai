import hashlib
import hmac
import json
import logging
from datetime import datetime, timedelta, timezone

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
    logger.info(f"[Vapi] Incoming webhook body length: {len(body)}")

    # ── HMAC verification ────────────────────────────────────────────────────
    signature = request.headers.get("x-vapi-signature", "")
    if signature and settings.VAPI_SERVER_SECRET:
        expected = hmac.new(
            settings.VAPI_SERVER_SECRET.encode(),
            body,
            hashlib.sha256,
        ).hexdigest()
        if not hmac.compare_digest(signature, expected):
            logger.warning("[Vapi] HMAC signature mismatch — rejecting request")
            raise HTTPException(
                status_code=401,
                detail={"code": "UNAUTHORIZED", "message": "Invalid Vapi signature"},
            )

    try:
        payload = json.loads(body)
    except json.JSONDecodeError:
        raise HTTPException(status_code=400, detail="Invalid JSON")

    logger.info(f"[Vapi] Payload keys: {list(payload.keys())}")

    message = payload.get("message", {})
    msg_type = message.get("type", "")
    call = message.get("call", {})

    logger.info(f"[Vapi] Message type: {msg_type}")

    # ── Resolve doctor from inbound phone number ─────────────────────────────
    # Vapi sends the called number in several possible locations depending on
    # whether it is a phone-number call or a web call.
    phone_number_obj = (
        call.get("phoneNumber")
        or message.get("phoneNumber")
        or payload.get("phoneNumber")
        or {}
    )
    called_number = (
        phone_number_obj.get("number")
        or call.get("to")
        or ""
    )
    logger.info(f"[Vapi] Called number resolved to: '{called_number}'")

    db = get_db()
    doctor = None

    if called_number:
        doctor = await db.doctors.find_one(
            {"inbound_phone": called_number}, {"_id": 0}
        )
        logger.info(f"[Vapi] Doctor lookup by inbound_phone='{called_number}': {'found' if doctor else 'not found'}")

    if not doctor:
        # Fallback: first non-admin doctor
        doctor = await db.doctors.find_one({"is_admin": False}, {"_id": 0})
        logger.info(f"[Vapi] Fallback doctor: {'found' if doctor else 'not found'}")

    if not doctor:
        logger.error("[Vapi] No doctor found — returning error")
        return {"error": "No doctor found for this number"}

    doctor_id = doctor["doctor_id"]
    logger.info(f"[Vapi] Resolved doctor_id={doctor_id}, name={doctor.get('name')}")

    # ── assistant-request ────────────────────────────────────────────────────
    if msg_type == "assistant-request":
        overrides = build_assistant_overrides(doctor)
        logger.info(f"[Vapi] Returning assistant overrides for doctor {doctor_id}")
        # Vapi expects the assistantOverrides object at the top level of the
        # response body for assistant-request events.
        return overrides

    # ── function-call (Vapi v1 shape) ────────────────────────────────────────
    elif msg_type == "function-call":
        func_call = message.get("functionCall", {})
        function_name = func_call.get("name", "")
        # parameters may be a JSON string or already a dict
        raw_params = func_call.get("parameters", {})
        parameters = _parse_parameters(raw_params)

        logger.info(f"[Vapi] function-call: name={function_name}, params={parameters}")

        result = await handle_vapi_function_call(function_name, parameters, doctor)
        logger.info(f"[Vapi] function-call result: {result}")

        if function_name == "bookAppointment":
            await _handle_booking(db, doctor, parameters, result)

        return {"result": result.get("result", "Done")}

    # ── tool-calls (Vapi v2 shape) ────────────────────────────────────────────
    elif msg_type == "tool-calls":
        tool_call_list = message.get("toolCallList", [])
        logger.info(f"[Vapi] tool-calls received: {len(tool_call_list)} tool(s)")

        results = []
        for tool_call in tool_call_list:
            tool_call_id = tool_call.get("id", "")
            func = tool_call.get("function", {})
            function_name = func.get("name", "")
            raw_params = func.get("arguments", {})
            parameters = _parse_parameters(raw_params)

            logger.info(f"[Vapi] tool-call: id={tool_call_id}, name={function_name}, params={parameters}")

            result = await handle_vapi_function_call(function_name, parameters, doctor)
            logger.info(f"[Vapi] tool-call result: {result}")

            if function_name == "bookAppointment":
                await _handle_booking(db, doctor, parameters, result)

            results.append({
                "toolCallId": tool_call_id,
                "result": result.get("result", "Done"),
            })

        return {"results": results}

    # ── end-of-call-report ───────────────────────────────────────────────────
    elif msg_type == "end-of-call-report":
        summary = message.get("summary", "")
        caller_phone = call.get("customer", {}).get("number", "")
        logger.info(
            f"[Vapi] Call ended for doctor {doctor_id}. "
            f"Caller: {caller_phone}. Summary: {summary[:100]}"
        )
        return {"received": True}

    # ── status-update / other ────────────────────────────────────────────────
    else:
        logger.info(f"[Vapi] Unhandled message type '{msg_type}' — returning assistant overrides")
        return build_assistant_overrides(doctor)


def _parse_parameters(raw) -> dict:
    """Normalise parameters that may arrive as a JSON string or a dict."""
    if isinstance(raw, str):
        try:
            return json.loads(raw)
        except (json.JSONDecodeError, TypeError):
            return {}
    if isinstance(raw, dict):
        return raw
    return {}


async def _handle_booking(db, doctor, parameters: dict, cal_result: dict):
    """Upsert patient + appointment from Vapi booking function call."""
    doctor_id = doctor["doctor_id"]
    patient_name = parameters.get("patientName") or parameters.get("name") or "Unknown"
    patient_phone = parameters.get("patientPhone") or parameters.get("phone") or ""
    reason = parameters.get("reason", "")
    start_time_str = parameters.get("startTime") or parameters.get("date") or ""

    logger.info(
        f"[Vapi] _handle_booking: doctor={doctor_id}, patient={patient_name}, "
        f"phone={patient_phone}, start={start_time_str}"
    )

    if not patient_phone:
        logger.warning("[Vapi] _handle_booking: no patient phone — skipping DB write")
        return

    # Upsert patient
    existing_patient = await db.patients.find_one(
        {"doctor_id": doctor_id, "phone": patient_phone}, {"_id": 0}
    )
    if existing_patient:
        patient_id = existing_patient["patient_id"]
        logger.info(f"[Vapi] Existing patient found: {patient_id}")
    else:
        patient = Patient(
            doctor_id=doctor_id,
            name=patient_name,
            phone=patient_phone,
        )
        await db.patients.insert_one({**patient.model_dump(), "_id": patient.patient_id})
        patient_id = patient.patient_id
        logger.info(f"[Vapi] New patient created: {patient_id}")

    # Parse start time
    try:
        if start_time_str:
            start_time = datetime.fromisoformat(start_time_str.replace("Z", "+00:00"))
        else:
            start_time = datetime.now(timezone.utc)
    except Exception:
        start_time = datetime.now(timezone.utc)

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
    logger.info(f"[Vapi] Appointment created: {appt.appointment_id}")

    # SMS confirmation
    try:
        await twilio.send_booking_confirmation(
            patient_phone,
            patient_name,
            doctor["name"],
            start_time.strftime("%b %d at %I:%M %p"),
        )
    except Exception as e:
        logger.warning(f"[Vapi] SMS send failed (non-fatal): {e}")

    # WebSocket broadcast
    try:
        await broadcast(doctor_id, {
            "event": "appointment.created",
            "appointment": _serialize(appt.model_dump()),
        })
    except Exception as e:
        logger.warning(f"[Vapi] WebSocket broadcast failed (non-fatal): {e}")

    # Notification
    notif = Notification(
        doctor_id=doctor_id,
        title="New Booking via AI Receptionist",
        body=f"{patient_name} booked for {start_time.strftime('%b %d at %I:%M %p')}",
        type="booking",
        related_id=appt.appointment_id,
    )
    await db.notifications.insert_one({**notif.model_dump(), "_id": notif.notification_id})
    logger.info(f"[Vapi] Notification created: {notif.notification_id}")
