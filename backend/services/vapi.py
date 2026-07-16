import logging
import random
from datetime import datetime, timedelta, timezone
from typing import Any, Dict, List, Optional

from config import settings

logger = logging.getLogger(__name__)


# ─── Mock helpers ─────────────────────────────────────────────────────────────

def _mock_slots(date_str: str) -> List[Dict]:
    try:
        base = datetime.fromisoformat(date_str)
    except Exception:
        base = datetime.now(timezone.utc)
    slots = []
    hours = [9, 9, 10, 10, 11, 14, 14, 15, 15, 16]
    for i, hour in enumerate(hours):
        minute = 0 if i % 2 == 0 else 30
        start = base.replace(hour=hour, minute=minute, second=0, microsecond=0)
        slots.append({
            "start": start.isoformat(),
            "end": (start + timedelta(minutes=30)).isoformat(),
            "available": random.choice([True, True, True, False]),
        })
    return slots


# ─── Entry point ──────────────────────────────────────────────────────────────

async def handle_vapi_function_call(
    function_name: str,
    parameters: Dict[str, Any],
    doctor: Dict,
) -> Dict:
    """Route Vapi function calls to mock or real implementation."""
    logger.info(
        f"[VapiService] handle_vapi_function_call: name={function_name}, "
        f"USE_MOCK={settings.USE_MOCK_EXTERNAL}, params={parameters}"
    )
    if settings.USE_MOCK_EXTERNAL:
        return await _mock_vapi_function(function_name, parameters, doctor)
    return await _real_vapi_function(function_name, parameters, doctor)


# ─── Mock implementation ──────────────────────────────────────────────────────

async def _mock_vapi_function(function_name: str, parameters: Dict, doctor: Dict) -> Dict:
    if function_name == "checkAvailability":
        date = parameters.get("date", datetime.now(timezone.utc).date().isoformat())
        slots = _mock_slots(date)
        available = [s for s in slots if s["available"]]
        times = ", ".join(s["start"][11:16] for s in available[:5])
        return {"result": f"Available slots on {date}: {times}"}

    elif function_name == "bookAppointment":
        return {
            "result": "Appointment booked successfully. You will receive an SMS confirmation shortly.",
            "booking_id": f"mock-booking-{datetime.now().timestamp():.0f}",
        }

    elif function_name == "rescheduleAppointment":
        return {"result": "Appointment rescheduled successfully."}

    elif function_name == "cancelAppointment":
        return {"result": "Appointment cancelled successfully."}

    return {"result": "Function executed successfully."}


# ─── Real implementation ──────────────────────────────────────────────────────

async def _real_vapi_function(function_name: str, parameters: Dict, doctor: Dict) -> Dict:
    """Real DB-backed Vapi function handlers."""
    from database import get_db
    db = get_db()
    doctor_id = doctor.get("doctor_id", "")

    # ── checkAvailability ────────────────────────────────────────────────────
    if function_name == "checkAvailability":
        date_str = parameters.get("date", datetime.now(timezone.utc).date().isoformat())
        logger.info(f"[VapiService] checkAvailability: doctor={doctor_id}, date={date_str}")

        try:
            target_date = datetime.fromisoformat(date_str).replace(
                hour=0, minute=0, second=0, microsecond=0, tzinfo=timezone.utc
            )
        except Exception:
            target_date = datetime.now(timezone.utc).replace(
                hour=0, minute=0, second=0, microsecond=0
            )

        day_end = target_date + timedelta(days=1)

        # Fetch existing confirmed appointments for that day
        existing_appts = await db.appointments.find(
            {
                "doctor_id": doctor_id,
                "start_time": {"$gte": target_date, "$lt": day_end},
                "status": {"$in": ["confirmed", "pending"]},
            },
            {"start_time": 1, "end_time": 1, "_id": 0},
        ).to_list(length=100)

        # Fetch blocked slots for that day
        blocked = await db.blocked_slots.find(
            {
                "doctor_id": doctor_id,
                "start_time": {"$gte": target_date, "$lt": day_end},
            },
            {"start_time": 1, "end_time": 1, "_id": 0},
        ).to_list(length=100)

        booked_starts = {
            _to_utc(a["start_time"]).strftime("%H:%M")
            for a in existing_appts
        }
        blocked_starts = {
            _to_utc(b["start_time"]).strftime("%H:%M")
            for b in blocked
        }
        unavailable = booked_starts | blocked_starts

        # Build slots from doctor working hours
        wh = doctor.get("working_hours", {})
        start_h, start_m = _parse_time(wh.get("start", "09:00"))
        end_h, end_m = _parse_time(wh.get("end", "17:00"))
        break_start_h, break_start_m = _parse_time(doctor.get("break_start", "13:00"))
        break_end_h, break_end_m = _parse_time(doctor.get("break_end", "14:00"))

        available_slots = []
        cursor = target_date.replace(hour=start_h, minute=start_m)
        end_of_day = target_date.replace(hour=end_h, minute=end_m)
        break_start_dt = target_date.replace(hour=break_start_h, minute=break_start_m)
        break_end_dt = target_date.replace(hour=break_end_h, minute=break_end_m)

        while cursor < end_of_day:
            slot_end = cursor + timedelta(minutes=30)
            time_label = cursor.strftime("%H:%M")
            in_break = cursor >= break_start_dt and cursor < break_end_dt
            if not in_break and time_label not in unavailable:
                available_slots.append(time_label)
            cursor = slot_end

        if available_slots:
            result_str = f"Available slots on {date_str}: " + ", ".join(available_slots[:8])
        else:
            result_str = f"No available slots on {date_str}. Please try another date."

        logger.info(f"[VapiService] checkAvailability result: {result_str}")
        return {"result": result_str}

    # ── bookAppointment ──────────────────────────────────────────────────────
    elif function_name == "bookAppointment":
        patient_name = parameters.get("patientName") or parameters.get("name") or "Unknown"
        patient_phone = parameters.get("patientPhone") or parameters.get("phone") or ""
        start_time_str = parameters.get("startTime") or parameters.get("date") or ""
        reason = parameters.get("reason", "")

        logger.info(
            f"[VapiService] bookAppointment: doctor={doctor_id}, "
            f"patient={patient_name}, phone={patient_phone}, start={start_time_str}"
        )

        if not patient_phone:
            return {"result": "I need your phone number to book the appointment. Could you please provide it?"}

        if not start_time_str:
            return {"result": "I need a preferred date and time to book the appointment. What time works for you?"}

        try:
            start_time = datetime.fromisoformat(start_time_str.replace("Z", "+00:00"))
        except Exception:
            return {"result": f"I couldn't understand the time '{start_time_str}'. Please provide a date and time like '2024-01-15 10:00'."}

        # Check the slot is still free
        slot_end = start_time + timedelta(minutes=30)
        conflict = await db.appointments.find_one({
            "doctor_id": doctor_id,
            "start_time": {"$lt": slot_end},
            "end_time": {"$gt": start_time},
            "status": {"$in": ["confirmed", "pending"]},
        })
        if conflict:
            return {"result": f"The slot at {start_time.strftime('%I:%M %p')} is no longer available. Please choose another time."}

        return {
            "result": f"Great! I've noted your appointment for {start_time.strftime('%B %d at %I:%M %p')}. You will receive an SMS confirmation shortly.",
            "booking_id": None,
            # The actual DB write is done in vapi_webhook._handle_booking
        }

    # ── rescheduleAppointment ────────────────────────────────────────────────
    elif function_name == "rescheduleAppointment":
        patient_phone = parameters.get("patientPhone") or parameters.get("phone") or ""
        new_time_str = parameters.get("newStartTime") or parameters.get("newTime") or parameters.get("startTime") or ""

        logger.info(
            f"[VapiService] rescheduleAppointment: doctor={doctor_id}, "
            f"phone={patient_phone}, new_time={new_time_str}"
        )

        if not patient_phone:
            return {"result": "I need your phone number to find your appointment. Could you please provide it?"}

        # Find the most recent upcoming appointment for this patient
        appt = await db.appointments.find_one(
            {
                "doctor_id": doctor_id,
                "patient_phone": patient_phone,
                "status": {"$in": ["confirmed", "pending"]},
                "start_time": {"$gte": datetime.now(timezone.utc)},
            },
            sort=[("start_time", 1)],
        )

        if not appt:
            return {"result": "I couldn't find an upcoming appointment for your phone number. Please check and try again."}

        if not new_time_str:
            return {"result": "What date and time would you like to reschedule to?"}

        try:
            new_start = datetime.fromisoformat(new_time_str.replace("Z", "+00:00"))
        except Exception:
            return {"result": f"I couldn't understand the new time '{new_time_str}'. Please provide a date and time."}

        new_end = new_start + timedelta(minutes=30)

        await db.appointments.update_one(
            {"appointment_id": appt["appointment_id"]},
            {
                "$set": {
                    "start_time": new_start,
                    "end_time": new_end,
                    "status": "confirmed",
                    "updated_at": datetime.now(timezone.utc),
                }
            },
        )

        logger.info(f"[VapiService] Rescheduled appointment {appt['appointment_id']} to {new_start}")
        return {
            "result": f"Your appointment has been rescheduled to {new_start.strftime('%B %d at %I:%M %p')}. You will receive an SMS confirmation."
        }

    # ── cancelAppointment ────────────────────────────────────────────────────
    elif function_name == "cancelAppointment":
        patient_phone = parameters.get("patientPhone") or parameters.get("phone") or ""

        logger.info(
            f"[VapiService] cancelAppointment: doctor={doctor_id}, phone={patient_phone}"
        )

        if not patient_phone:
            return {"result": "I need your phone number to find your appointment. Could you please provide it?"}

        appt = await db.appointments.find_one(
            {
                "doctor_id": doctor_id,
                "patient_phone": patient_phone,
                "status": {"$in": ["confirmed", "pending"]},
                "start_time": {"$gte": datetime.now(timezone.utc)},
            },
            sort=[("start_time", 1)],
        )

        if not appt:
            return {"result": "I couldn't find an upcoming appointment for your phone number."}

        await db.appointments.update_one(
            {"appointment_id": appt["appointment_id"]},
            {
                "$set": {
                    "status": "cancelled",
                    "updated_at": datetime.now(timezone.utc),
                }
            },
        )

        logger.info(f"[VapiService] Cancelled appointment {appt['appointment_id']}")
        return {
            "result": f"Your appointment on {appt['start_time'].strftime('%B %d at %I:%M %p')} has been cancelled successfully."
        }

    # ── unknown function ─────────────────────────────────────────────────────
    else:
        logger.warning(f"[VapiService] Unknown function: {function_name}")
        return {"result": "I'm sorry, I couldn't process that request. Please try again."}


# ─── Assistant overrides ──────────────────────────────────────────────────────

def build_assistant_overrides(doctor: Dict) -> Dict:
    """Build Vapi assistantOverrides with doctor-specific context."""
    working_hours = doctor.get("working_hours", {"start": "09:00", "end": "17:00"})
    if isinstance(working_hours, dict):
        wh_start = working_hours.get("start", "09:00")
        wh_end = working_hours.get("end", "17:00")
    else:
        wh_start = "09:00"
        wh_end = "17:00"

    working_days = ", ".join(doctor.get("working_days", ["Mon", "Tue", "Wed", "Thu", "Fri"]))

    system_prompt = f"""You are the AI receptionist for {doctor.get('name', 'the doctor')} at {doctor.get('clinic_name', 'the clinic')}.

Doctor: {doctor.get('name')}
Clinic: {doctor.get('clinic_name')}
Specialization: {doctor.get('specialization', 'General')}
Working Hours: {wh_start} - {wh_end}
Working Days: {working_days}

Your job is to:
1. Greet callers warmly and introduce yourself as the AI receptionist
2. Collect the caller's name, phone number, reason for visit, and preferred appointment time
3. Check availability using the checkAvailability function before booking
4. Book appointments using the bookAppointment function
5. Handle rescheduling using rescheduleAppointment and cancellations using cancelAppointment
6. Always confirm details before finalising any booking

Always be professional, empathetic, and efficient. If you cannot help, offer to take a message."""

    return {
        "assistantOverrides": {
            "firstMessage": (
                f"Hello! Thank you for calling {doctor.get('clinic_name', 'our clinic')}. "
                f"I'm the AI receptionist for {doctor.get('name')}. How can I help you today?"
            ),
            "model": {
                "messages": [{"role": "system", "content": system_prompt}]
            },
        }
    }


# ─── Helpers ──────────────────────────────────────────────────────────────────

def _parse_time(time_str: str):
    """Parse 'HH:MM' → (hour, minute)."""
    try:
        parts = time_str.split(":")
        return int(parts[0]), int(parts[1])
    except Exception:
        return 9, 0


def _to_utc(dt) -> datetime:
    """Ensure datetime is UTC-aware."""
    if isinstance(dt, datetime):
        if dt.tzinfo is None:
            return dt.replace(tzinfo=timezone.utc)
        return dt
    return datetime.now(timezone.utc)
