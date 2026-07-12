import logging
import random
from datetime import datetime, timedelta, timezone
from typing import Any, Dict, List, Optional

import httpx

from config import settings

logger = logging.getLogger(__name__)


# ─── Mock helpers ─────────────────────────────────────────────────────────────

def _generate_mock_slots(date_str: str, doctor: Dict) -> List[Dict]:
    try:
        base = datetime.fromisoformat(date_str)
    except ValueError:
        base = datetime.now(timezone.utc).replace(hour=0, minute=0, second=0, microsecond=0)

    wh = doctor.get("working_hours", {"start": "09:00", "end": "17:00"})
    start_h = int(wh.get("start", "09:00").split(":")[0])
    end_h = int(wh.get("end", "17:00").split(":")[0])
    break_s = int(doctor.get("break_start", "13:00").split(":")[0])
    break_e = int(doctor.get("break_end", "14:00").split(":")[0])

    slots = []
    current = base.replace(hour=start_h, minute=0, second=0, microsecond=0)
    end = base.replace(hour=end_h, minute=0, second=0, microsecond=0)

    while current < end:
        hour = current.hour
        if not (break_s <= hour < break_e):
            slots.append({
                "start": current.isoformat(),
                "end": (current + timedelta(minutes=30)).isoformat(),
                "available": random.choices([True, False], weights=[3, 1])[0],
            })
        current += timedelta(minutes=30)

    return slots


# ─── Cal.com Service ──────────────────────────────────────────────────────────

async def get_availability(doctor: Dict, date: str) -> List[Dict]:
    if settings.USE_MOCK_EXTERNAL:
        return _generate_mock_slots(date, doctor)

    try:
        async with httpx.AsyncClient(timeout=10.0) as client:
            resp = await client.get(
                f"{settings.CALCOM_BASE_URL}/availability",
                params={
                    "apiKey": settings.CALCOM_API_KEY,
                    "username": doctor.get("cal_username"),
                    "eventTypeId": doctor.get("cal_event_type_id"),
                    "dateFrom": date,
                    "dateTo": date,
                },
            )
            resp.raise_for_status()
            data = resp.json()
            return data.get("slots", {}).get(date, [])
    except Exception as e:
        logger.error(f"Cal.com availability error: {e}")
        raise Exception("CALCOM_UNAVAILABLE")


async def create_booking(
    doctor: Dict,
    patient: Dict,
    start_time: str,
    reason: str,
    idempotency_key: str = "",
) -> Dict:
    if settings.USE_MOCK_EXTERNAL:
        return {
            "uid": f"mock-booking-{idempotency_key or 'new'}",
            "id": f"mock-{int(datetime.now().timestamp())}",
            "status": "ACCEPTED",
            "startTime": start_time,
        }

    try:
        async with httpx.AsyncClient(timeout=10.0) as client:
            resp = await client.post(
                f"{settings.CALCOM_BASE_URL}/bookings",
                params={"apiKey": settings.CALCOM_API_KEY},
                json={
                    "eventTypeId": int(doctor.get("cal_event_type_id", 0)),
                    "start": start_time,
                    "responses": {
                        "name": patient.get("name"),
                        "email": patient.get("email", f"{patient.get('phone')}@placeholder.com"),
                        "phone": patient.get("phone"),
                        "notes": reason,
                    },
                    "timeZone": "UTC",
                    "language": "en",
                    "metadata": {"idempotencyKey": idempotency_key},
                },
                headers={"Idempotency-Key": idempotency_key} if idempotency_key else {},
            )
            if resp.status_code == 409:
                raise Exception("SLOT_TAKEN")
            resp.raise_for_status()
            return resp.json()
    except Exception as e:
        if "SLOT_TAKEN" in str(e):
            raise
        logger.error(f"Cal.com create booking error: {e}")
        raise Exception("CALCOM_UNAVAILABLE")


async def reschedule_booking(cal_booking_id: str, new_start_time: str) -> Dict:
    if settings.USE_MOCK_EXTERNAL:
        return {"uid": cal_booking_id, "status": "ACCEPTED", "startTime": new_start_time}

    try:
        async with httpx.AsyncClient(timeout=10.0) as client:
            resp = await client.patch(
                f"{settings.CALCOM_BASE_URL}/bookings/{cal_booking_id}",
                params={"apiKey": settings.CALCOM_API_KEY},
                json={"start": new_start_time},
            )
            resp.raise_for_status()
            return resp.json()
    except Exception as e:
        logger.error(f"Cal.com reschedule error: {e}")
        raise Exception("CALCOM_UNAVAILABLE")


async def cancel_booking(cal_booking_id: str, reason: str = "") -> bool:
    if settings.USE_MOCK_EXTERNAL:
        return True

    try:
        async with httpx.AsyncClient(timeout=10.0) as client:
            resp = await client.delete(
                f"{settings.CALCOM_BASE_URL}/bookings/{cal_booking_id}",
                params={"apiKey": settings.CALCOM_API_KEY},
                json={"reason": reason},
            )
            resp.raise_for_status()
            return True
    except Exception as e:
        logger.error(f"Cal.com cancel error: {e}")
        return False
