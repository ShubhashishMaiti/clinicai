import logging
import random
from datetime import datetime, timedelta, timezone
from typing import Any, Dict, List, Optional

from config import settings

logger = logging.getLogger(__name__)


# ─── Mock helpers ─────────────────────────────────────────────────────────────

def _mock_slots(date_str: str) -> List[Dict]:
    base = datetime.fromisoformat(date_str)
    slots = []
    for hour in [9, 9, 10, 10, 11, 14, 14, 15, 15, 16]:
        minute = 0 if len(slots) % 2 == 0 else 30
        start = base.replace(hour=hour, minute=minute, second=0, microsecond=0)
        slots.append({
            "start": start.isoformat(),
            "end": (start + timedelta(minutes=30)).isoformat(),
            "available": random.choice([True, True, True, False]),
        })
    return slots


# ─── Vapi Service ─────────────────────────────────────────────────────────────

async def handle_vapi_function_call(
    function_name: str,
    parameters: Dict[str, Any],
    doctor: Dict,
) -> Dict:
    """Handle Vapi function calls with mock or real mode."""
    if settings.USE_MOCK_EXTERNAL:
        return await _mock_vapi_function(function_name, parameters, doctor)
    return await _real_vapi_function(function_name, parameters, doctor)


async def _mock_vapi_function(function_name: str, parameters: Dict, doctor: Dict) -> Dict:
    if function_name == "checkAvailability":
        date = parameters.get("date", datetime.now(timezone.utc).date().isoformat())
        slots = _mock_slots(date)
        available = [s for s in slots if s["available"]]
        return {
            "result": f"Available slots on {date}: " + ", ".join(
                [s["start"][11:16] for s in available[:5]]
            )
        }
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


async def _real_vapi_function(function_name: str, parameters: Dict, doctor: Dict) -> Dict:
    # Real Vapi function calls would be handled here
    # For now, fall back to mock
    logger.warning(f"Real Vapi function call not implemented: {function_name}")
    return await _mock_vapi_function(function_name, parameters, doctor)


def build_assistant_overrides(doctor: Dict) -> Dict:
    """Build Vapi assistantOverrides with doctor-specific context."""
    working_hours = doctor.get("working_hours", {"start": "09:00", "end": "17:00"})
    working_days = ", ".join(doctor.get("working_days", ["Mon", "Tue", "Wed", "Thu", "Fri"]))

    system_prompt = f"""You are the AI receptionist for {doctor.get('name', 'the doctor')} at {doctor.get('clinic_name', 'the clinic')}.

Doctor: {doctor.get('name')}
Clinic: {doctor.get('clinic_name')}
Specialization: {doctor.get('specialization', 'General')}
Working Hours: {working_hours.get('start', '09:00')} - {working_hours.get('end', '17:00')}
Working Days: {working_days}

Your job is to:
1. Greet callers warmly
2. Collect their name, phone number, reason for visit, and preferred appointment time
3. Check availability using checkAvailability function
4. Book appointments using bookAppointment function
5. Handle rescheduling and cancellations

Always be professional, empathetic, and efficient."""

    return {
        "assistantOverrides": {
            "firstMessage": f"Hello! Thank you for calling {doctor.get('clinic_name', 'our clinic')}. I'm the AI receptionist for {doctor.get('name')}. How can I help you today?",
            "model": {
                "messages": [{"role": "system", "content": system_prompt}]
            },
        }
    }
