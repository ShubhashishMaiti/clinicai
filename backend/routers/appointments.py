from datetime import datetime, timezone
from typing import Optional
from fastapi import APIRouter, Depends, HTTPException, Query
from database import get_db
from auth import get_current_doctor
from models import CreateAppointmentRequest, RescheduleRequest, CompleteRequest, CancelRequest
from services import calcom, twilio
import uuid

router = APIRouter()


def _serialize(a: dict) -> dict:
    result = {}
    for k, v in a.items():
        if isinstance(v, datetime):
            result[k] = v.isoformat()
        else:
            result[k] = v
    return result


@router.get("")
async def list_appointments(
    filter: str = Query("upcoming", regex="today|tomorrow|upcoming|completed|cancelled|rescheduled|all"),
    q: Optional[str] = None,
    doctor=Depends(get_current_doctor),
):
    db = get_db()
    doctor_id = doctor["doctor_id"]
    now = datetime.now(timezone.utc)
    today_start = now.replace(hour=0, minute=0, second=0, microsecond=0)
    today_end = now.replace(hour=23, minute=59, second=59, microsecond=0)

    from datetime import timedelta
    tomorrow_start = today_start + timedelta(days=1)
    tomorrow_end = today_end + timedelta(days=1)

    query = {"doctor_id": doctor_id}

    if filter == "today":
        query["start_time"] = {"$gte": today_start, "$lte": today_end}
    elif filter == "tomorrow":
        query["start_time"] = {"$gte": tomorrow_start, "$lte": tomorrow_end}
    elif filter == "upcoming":
        query["start_time"] = {"$gt": now}
        query["status"] = {"$in": ["confirmed", "pending"]}
    elif filter in ("completed", "cancelled", "rescheduled"):
        query["status"] = filter
    # "all" — no extra filter

    if q:
        query["$or"] = [
            {"patient_name": {"$regex": q, "$options": "i"}},
            {"reason": {"$regex": q, "$options": "i"}},
        ]

    appointments = await db.appointments.find(query, {"_id": 0}).sort("start_time", 1).to_list(100)
    return [_serialize(a) for a in appointments]


@router.post("")
async def create_appointment(req: CreateAppointmentRequest, doctor=Depends(get_current_doctor)):
    db = get_db()
    doctor_id = doctor["doctor_id"]
    now = datetime.now(timezone.utc)

    # Upsert patient
    patient_id = req.patient_id
    if not patient_id:
        existing_patient = await db.patients.find_one(
            {"doctor_id": doctor_id, "phone": req.patient_phone}, {"_id": 0}
        )
        if existing_patient:
            patient_id = existing_patient["patient_id"]
        else:
            from models import Patient
            patient = Patient(
                doctor_id=doctor_id,
                name=req.patient_name,
                phone=req.patient_phone,
                age=req.patient_age,
                gender=req.patient_gender,
            )
            await db.patients.insert_one({**patient.model_dump(), "_id": patient.patient_id})
            patient_id = patient.patient_id

    # Check for conflicts
    conflict = await db.appointments.find_one({
        "doctor_id": doctor_id,
        "status": {"$in": ["confirmed", "pending"]},
        "start_time": {"$lt": req.start_time + __import__("datetime").timedelta(minutes=req.duration_minutes)},
        "end_time": {"$gt": req.start_time},
    })
    if conflict:
        raise HTTPException(status_code=409, detail={"code": "SLOT_TAKEN", "message": "Time slot already booked"})

    # Create Cal.com booking
    idempotency_key = str(uuid.uuid4())
    cal_booking_id = None
    try:
        patient_doc = await db.patients.find_one({"patient_id": patient_id}, {"_id": 0})
        cal_result = await calcom.create_booking(
            doctor=doctor,
            patient=patient_doc or {"name": req.patient_name, "phone": req.patient_phone},
            start_time=req.start_time.isoformat(),
            reason=req.reason,
            idempotency_key=idempotency_key,
        )
        cal_booking_id = cal_result.get("uid") or cal_result.get("id")
    except Exception as e:
        if "SLOT_TAKEN" in str(e):
            raise HTTPException(status_code=409, detail={"code": "SLOT_TAKEN", "message": "Slot already taken on Cal.com"})
        # CALCOM_UNAVAILABLE — proceed without Cal.com
        pass

    from models import Appointment
    from datetime import timedelta
    appt = Appointment(
        doctor_id=doctor_id,
        patient_id=patient_id,
        patient_name=req.patient_name,
        patient_phone=req.patient_phone,
        reason=req.reason,
        start_time=req.start_time,
        end_time=req.start_time + timedelta(minutes=req.duration_minutes),
        duration_minutes=req.duration_minutes,
        status="confirmed",
        cal_booking_id=str(cal_booking_id) if cal_booking_id else None,
    )
    await db.appointments.insert_one({**appt.model_dump(), "_id": appt.appointment_id})

    # SMS confirmation (graceful failure)
    sms_ok = await twilio.send_booking_confirmation(
        req.patient_phone, req.patient_name, doctor["name"],
        req.start_time.strftime("%b %d at %I:%M %p"),
    )

    # WebSocket broadcast
    from routers.websocket import broadcast
    await broadcast(doctor_id, {"event": "appointment.created", "appointment": _serialize(appt.model_dump())})

    # Notification
    from models import Notification
    notif = Notification(
        doctor_id=doctor_id,
        title="New Appointment",
        body=f"{req.patient_name} booked for {req.start_time.strftime('%b %d at %I:%M %p')}",
        type="booking",
        related_id=appt.appointment_id,
    )
    await db.notifications.insert_one({**notif.model_dump(), "_id": notif.notification_id})

    result = _serialize(appt.model_dump())
    if not sms_ok:
        result["warning"] = {"code": "SMS_FAILED_BOOKING_OK", "message": "Booking confirmed but SMS failed"}
    return result


@router.patch("/{appointment_id}/reschedule")
async def reschedule_appointment(appointment_id: str, req: RescheduleRequest, doctor=Depends(get_current_doctor)):
    db = get_db()
    doctor_id = doctor["doctor_id"]
    appt = await db.appointments.find_one({"appointment_id": appointment_id, "doctor_id": doctor_id}, {"_id": 0})
    if not appt:
        raise HTTPException(status_code=404, detail={"code": "NOT_FOUND", "message": "Appointment not found"})

    from datetime import timedelta
    new_end = req.new_start_time + timedelta(minutes=req.duration_minutes)

    if appt.get("cal_booking_id"):
        try:
            await calcom.reschedule_booking(appt["cal_booking_id"], req.new_start_time.isoformat())
        except Exception:
            pass

    now = datetime.now(timezone.utc)
    await db.appointments.update_one(
        {"appointment_id": appointment_id},
        {"$set": {
            "start_time": req.new_start_time,
            "end_time": new_end,
            "duration_minutes": req.duration_minutes,
            "status": "rescheduled",
            "updated_at": now,
        }},
    )

    await twilio.send_reschedule_notice(
        appt["patient_phone"], appt["patient_name"], doctor["name"],
        req.new_start_time.strftime("%b %d at %I:%M %p"),
    )

    updated = await db.appointments.find_one({"appointment_id": appointment_id}, {"_id": 0})
    from routers.websocket import broadcast
    await broadcast(doctor_id, {"event": "appointment.updated", "appointment": _serialize(updated)})
    return _serialize(updated)


@router.post("/{appointment_id}/cancel")
async def cancel_appointment(appointment_id: str, req: CancelRequest, doctor=Depends(get_current_doctor)):
    db = get_db()
    doctor_id = doctor["doctor_id"]
    appt = await db.appointments.find_one({"appointment_id": appointment_id, "doctor_id": doctor_id}, {"_id": 0})
    if not appt:
        raise HTTPException(status_code=404, detail={"code": "NOT_FOUND", "message": "Appointment not found"})

    if appt.get("cal_booking_id"):
        await calcom.cancel_booking(appt["cal_booking_id"], req.reason)

    now = datetime.now(timezone.utc)
    await db.appointments.update_one(
        {"appointment_id": appointment_id},
        {"$set": {"status": "cancelled", "notes": req.reason, "updated_at": now}},
    )

    await twilio.send_cancellation_notice(
        appt["patient_phone"], appt["patient_name"], doctor["name"],
        appt["start_time"].strftime("%b %d at %I:%M %p") if isinstance(appt["start_time"], datetime) else str(appt["start_time"]),
    )

    updated = await db.appointments.find_one({"appointment_id": appointment_id}, {"_id": 0})
    from routers.websocket import broadcast
    await broadcast(doctor_id, {"event": "appointment.cancelled", "appointment": _serialize(updated)})
    return _serialize(updated)


@router.post("/{appointment_id}/complete")
async def complete_appointment(appointment_id: str, req: CompleteRequest, doctor=Depends(get_current_doctor)):
    db = get_db()
    doctor_id = doctor["doctor_id"]
    appt = await db.appointments.find_one({"appointment_id": appointment_id, "doctor_id": doctor_id}, {"_id": 0})
    if not appt:
        raise HTTPException(status_code=404, detail={"code": "NOT_FOUND", "message": "Appointment not found"})

    now = datetime.now(timezone.utc)
    await db.appointments.update_one(
        {"appointment_id": appointment_id},
        {"$set": {"status": "completed", "notes": req.notes, "updated_at": now}},
    )

    # Invalidate AI summary cache
    from services.ai import invalidate_summary_cache
    await invalidate_summary_cache(appt["patient_id"], doctor_id)

    updated = await db.appointments.find_one({"appointment_id": appointment_id}, {"_id": 0})
    from routers.websocket import broadcast
    await broadcast(doctor_id, {"event": "appointment.updated", "appointment": _serialize(updated)})
    return _serialize(updated)
