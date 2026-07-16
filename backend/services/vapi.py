import json
import logging
import random
from datetime import datetime, timedelta, timezone
from typing import Any, Dict, List, Optional

from config import settings

logger = logging.getLogger(__name__)


def _dbg(msg: str):
    """Dual-output debug: both logger.info and print to stdout (for Render logs)."""
    logger.info(msg)
    print(f"[VAPI_SVC_DEBUG] {msg}", flush=True)


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
    _dbg(
        f"=== handle_vapi_function_call ==="
        f" name='{function_name}'"
        f" USE_MOCK={settings.USE_MOCK_EXTERNAL}"
        f" doctor_id={doctor.get('doctor_id')}"
        f" params={json.dumps(parameters, default=str)}"
    )
    if settings.USE_MOCK_EXTERNAL:
        result = await _mock_vapi_function(function_name, parameters, doctor)
    else:
        result = await _real_vapi_function(function_name, parameters, doctor)
    _dbg(f"handle_vapi_function_call result: {result}")
    return result


# ─── Mock implementation ──────────────────────────────────────────────────────

async def _mock_vapi_function(function_name: str, parameters: Dict, doctor: Dict) -> Dict:
    _dbg(f"_mock_vapi_function: {function_name}")
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

    _dbg(f"_real_vapi_function: '{function_name}' for doctor={doctor_id}")

    # ── checkAvailability ────────────────────────────────────────────────────
    if function_name == "checkAvailability":
        date_str = parameters.get("date", datetime.now(timezone.utc).date().isoformat())
        _dbg(f"checkAvailability: doctor={doctor_id}, date='{date_str}'")

        try:
            target_date = datetime.fromisoformat(date_str).replace(
                hour=0, minute=0, second=0, microsecond=0, tzinfo=timezone.utc
            )
        except Exception as e:
            _dbg(f"checkAvailability: failed to parse date '{date_str}': {e} — using today")
            target_date = datetime.now(timezone.utc).replace(
                hour=0, minute=0, second=0, microsecond=0
            )

        day_end = target_date + timedelta(days=1)
        _dbg(f"checkAvailability: querying range {target_date.isoformat()} → {day_end.isoformat()}")

        # Fetch existing confirmed appointments for that day
        existing_appts = await db.appointments.find(
            {
                "doctor_id": doctor_id,
                "start_time": {"$gte": target_date, "$lt": day_end},
                "status": {"$in": ["confirmed", "pending"]},
            },
            {"start_time": 1, "end_time": 1, "_id": 0},
        ).to_list(length=100)
        _dbg(f"checkAvailability: found {len(existing_appts)} existing appointments")

        # Fetch blocked slots for that day
        blocked = await db.blocked_slots.find(
            {
                "doctor_id": doctor_id,
                "start_time": {"$gte": target_date, "$lt": day_end},
            },
            {"start_time": 1, "end_time": 1, "_id": 0},
        ).to_list(length=100)
        _dbg(f"checkAvailability: found {len(blocked)} blocked slots")

        booked_starts = {
            _to_utc(a["start_time"]).strftime("%H:%M")
            for a in existing_appts
        }
        blocked_starts = {
            _to_utc(b["start_time"]).strftime("%H:%M")
            for b in blocked
        }
        unavailable = booked_starts | blocked_starts
        _dbg(f"checkAvailability: unavailable times: {sorted(unavailable)}")

        # Build slots from doctor working hours
        wh = doctor.get("working_hours", {})
        if not isinstance(wh, dict):
            wh = {}
        start_h, start_m = _parse_time(wh.get("start", "09:00"))
        end_h, end_m = _parse_time(wh.get("end", "17:00"))
        break_start_h, break_start_m = _parse_time(doctor.get("break_start", "13:00"))
        break_end_h, break_end_m = _parse_time(doctor.get("break_end", "14:00"))

        _dbg(f"checkAvailability: working hours {start_h}:{start_m:02d}-{end_h}:{end_m:02d}, break {break_start_h}:{break_start_m:02d}-{break_end_h}:{break_end_m:02d}")

        available_slots = []
        cursor = target_date.replace(hour=start_h, minute=start_m)
        end_of_day = target_date.replace(hour=end_h, minute=end_m)
        break_start_dt = target_date.replace(hour=break_start_h, minute=break_start_m)
        break_end_dt = target_date.replace(hour=break_end_h, minute=break_end_m)

        while cursor < end_of_day:
            slot_end = cursor + timedelta(minutes=30)
            time_label = cursor.strftime("%H:%M")
            in_break = break_start_dt <= cursor < break_end_dt
            if not in_break and time_label not in unavailable:
                available_slots.append(time_label)
            cursor = slot_end

        _dbg(f"checkAvailability: available_slots={available_slots}")

        if available_slots:
            result_str = f"Available slots on {date_str}: " + ", ".join(available_slots[:8])
        else:
            result_str = f"No available slots on {date_str}. Please try another date."

        _dbg(f"checkAvailability result: '{result_str}'")
        return {"result": result_str}

    # ── bookAppointment ──────────────────────────────────────────────────────
    elif function_name == "bookAppointment":
        patient_name = parameters.get("patientName") or parameters.get("name") or "Unknown"
        patient_phone = parameters.get("patientPhone") or parameters.get("phone") or ""
        start_time_str = parameters.get("startTime") or parameters.get("date") or ""
        reason = parameters.get("reason", "")

        _dbg(
            f"bookAppointment: doctor={doctor_id}, patient='{patient_name}', "
            f"phone='{patient_phone}', start='{start_time_str}', reason='{reason}'"
        )

        if not patient_phone:
            return {"result": "I need your phone number to book the appointment. Could you please provide it?"}

        if not start_time_str:
            return {"result": "I need a preferred date and time to book the appointment. What time works for you?"}

        try:
            start_time = datetime.fromisoformat(start_time_str.replace("Z", "+00:00"))
            _dbg(f"bookAppointment: parsed start_time={start_time.isoformat()}")
        except Exception as e:
            _dbg(f"bookAppointment: failed to parse start_time '{start_time_str}': {e}")
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
            _dbg(f"bookAppointment: CONFLICT found at {start_time.isoformat()}")
            return {"result": f"The slot at {start_time.strftime('%I:%M %p')} is no longer available. Please choose another time."}

        _dbg(f"bookAppointment: slot is free, confirming booking")
        return {
            "result": f"Great! I've noted your appointment for {start_time.strftime('%B %d at %I:%M %p')}. You will receive an SMS confirmation shortly.",
            "booking_id": None,
            # The actual DB write is done in vapi_webhook._handle_booking
        }

    # ── rescheduleAppointment ────────────────────────────────────────────────
    elif function_name == "rescheduleAppointment":
        patient_phone = parameters.get("patientPhone") or parameters.get("phone") or ""
        new_time_str = parameters.get("newStartTime") or parameters.get("newTime") or parameters.get("startTime") or ""

        _dbg(
            f"rescheduleAppointment: doctor={doctor_id}, "
            f"phone='{patient_phone}', new_time='{new_time_str}'"
        )

        if not patient_phone:
            return {"result": "I need your phone number to find your appointment. Could you please provide it?"}

        # Find the most recent upcoming appointment for this patient
        # Motor find_one with sort requires using find().sort().limit()
        appt_cursor = db.appointments.find(
            {
                "doctor_id": doctor_id,
                "patient_phone": patient_phone,
                "status": {"$in": ["confirmed", "pending"]},
                "start_time": {"$gte": datetime.now(timezone.utc)},
            }
        ).sort("start_time", 1).limit(1)
        appts = await appt_cursor.to_list(length=1)
        appt = appts[0] if appts else None

        _dbg(f"rescheduleAppointment: found appointment: {appt is not None}")

        if not appt:
            return {"result": "I couldn't find an upcoming appointment for your phone number. Please check and try again."}

        if not new_time_str:
            return {"result": "What date and time would you like to reschedule to?"}

        try:
            new_start = datetime.fromisoformat(new_time_str.replace("Z", "+00:00"))
            _dbg(f"rescheduleAppointment: new_start={new_start.isoformat()}")
        except Exception as e:
            _dbg(f"rescheduleAppointment: failed to parse new_time '{new_time_str}': {e}")
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

        _dbg(f"rescheduleAppointment: updated appointment {appt['appointment_id']} to {new_start.isoformat()}")
        return {
            "result": f"Your appointment has been rescheduled to {new_start.strftime('%B %d at %I:%M %p')}. You will receive an SMS confirmation."
        }

    # ── cancelAppointment ────────────────────────────────────────────────────
    elif function_name == "cancelAppointment":
        patient_phone = parameters.get("patientPhone") or parameters.get("phone") or ""

        _dbg(f"cancelAppointment: doctor={doctor_id}, phone='{patient_phone}'")

        if not patient_phone:
            return {"result": "I need your phone number to find your appointment. Could you please provide it?"}

        # Motor find_one with sort requires using find().sort().limit()
        appt_cursor = db.appointments.find(
            {
                "doctor_id": doctor_id,
                "patient_phone": patient_phone,
                "status": {"$in": ["confirmed", "pending"]},
                "start_time": {"$gte": datetime.now(timezone.utc)},
            }
        ).sort("start_time", 1).limit(1)
        appts = await appt_cursor.to_list(length=1)
        appt = appts[0] if appts else None

        _dbg(f"cancelAppointment: found appointment: {appt is not None}")

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

        appt_start = appt.get("start_time")
        if isinstance(appt_start, datetime):
            time_str = appt_start.strftime("%B %d at %I:%M %p")
        else:
            time_str = str(appt_start)

        _dbg(f"cancelAppointment: cancelled appointment {appt['appointment_id']}")
        return {
            "result": f"Your appointment on {time_str} has been cancelled successfully."
        }

    # ── unknown function ─────────────────────────────────────────────────────
    else:
        _dbg(f"UNKNOWN function name: '{function_name}'")
        return {"result": "I'm sorry, I couldn't process that request. Please try again."}


# ─── Assistant overrides ──────────────────────────────────────────────────────

def build_assistant_overrides(doctor: Dict) -> Dict:
    """Build Vapi assistantOverrides with doctor-specific context and full tool definitions."""
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

    # Full tool definitions — Vapi MUST receive these to know what tools exist
    tools = [
        {
            "type": "function",
            "function": {
                "name": "checkAvailability",
                "description": "Check available appointment slots for a given date. Call this before booking to confirm a slot is free.",
                "parameters": {
                    "type": "object",
                    "properties": {
                        "date": {
                            "type": "string",
                            "description": "The date to check availability for, in ISO 8601 format (YYYY-MM-DD). Example: '2024-07-18'",
                        }
                    },
                    "required": ["date"],
                },
            },
            "server": {
                "url": f"{settings.BACKEND_URL}/api/vapi/webhook",
            },
        },
        {
            "type": "function",
            "function": {
                "name": "bookAppointment",
                "description": "Book an appointment for a patient. Only call after confirming the slot is available via checkAvailability.",
                "parameters": {
                    "type": "object",
                    "properties": {
                        "patientName": {
                            "type": "string",
                            "description": "Full name of the patient",
                        },
                        "patientPhone": {
                            "type": "string",
                            "description": "Patient's phone number including country code, e.g. +14155550100",
                        },
                        "startTime": {
                            "type": "string",
                            "description": "Appointment start time in ISO 8601 format, e.g. '2024-07-18T16:00:00'",
                        },
                        "reason": {
                            "type": "string",
                            "description": "Reason for the visit or chief complaint",
                        },
                    },
                    "required": ["patientName", "patientPhone", "startTime"],
                },
            },
            "server": {
                "url": f"{settings.BACKEND_URL}/api/vapi/webhook",
            },
        },
        {
            "type": "function",
            "function": {
                "name": "rescheduleAppointment",
                "description": "Reschedule an existing appointment to a new date and time.",
                "parameters": {
                    "type": "object",
                    "properties": {
                        "patientPhone": {
                            "type": "string",
                            "description": "Patient's phone number to look up their existing appointment",
                        },
                        "newStartTime": {
                            "type": "string",
                            "description": "New appointment start time in ISO 8601 format, e.g. '2024-07-20T10:00:00'",
                        },
                    },
                    "required": ["patientPhone", "newStartTime"],
                },
            },
            "server": {
                "url": f"{settings.BACKEND_URL}/api/vapi/webhook",
            },
        },
        {
            "type": "function",
            "function": {
                "name": "cancelAppointment",
                "description": "Cancel an existing upcoming appointment for a patient.",
                "parameters": {
                    "type": "object",
                    "properties": {
                        "patientPhone": {
                            "type": "string",
                            "description": "Patient's phone number to look up their existing appointment",
                        },
                    },
                    "required": ["patientPhone"],
                },
            },
            "server": {
                "url": f"{settings.BACKEND_URL}/api/vapi/webhook",
            },
        },
    ]

    return {
        "assistantOverrides": {
            "firstMessage": (
                f"Hello! Thank you for calling {doctor.get('clinic_name', 'our clinic')}. "
                f"I'm the AI receptionist for {doctor.get('name')}. How can I help you today?"
            ),
            "model": {
                "provider": "openai",
                "model": "gpt-4o",
                "messages": [{"role": "system", "content": system_prompt}],
                "tools": tools,
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
