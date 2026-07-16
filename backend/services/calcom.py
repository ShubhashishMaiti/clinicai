import json
import logging
import random
from datetime import datetime, timedelta, timezone
from typing import Any, Dict, List, Optional

import httpx

from config import settings

logger = logging.getLogger(__name__)


def _dbg(msg: str):
    """Dual-output debug: both logger.info and print to stdout (for Render logs)."""
    logger.info(msg)
    print(f"[CALCOM_DEBUG] {msg}", flush=True)


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
    _dbg(f"get_availability: doctor={doctor.get('doctor_id')}, date='{date}', USE_MOCK={settings.USE_MOCK_EXTERNAL}")

    if settings.USE_MOCK_EXTERNAL:
        slots = _generate_mock_slots(date, doctor)
        _dbg(f"get_availability (mock): returning {len(slots)} slots")
        return slots

    cal_username = doctor.get("cal_username", "")
    cal_event_type_id = doctor.get("cal_event_type_id", "")
    _dbg(f"get_availability: cal_username='{cal_username}', cal_event_type_id='{cal_event_type_id}'")
    _dbg(f"get_availability: CALCOM_BASE_URL='{settings.CALCOM_BASE_URL}', API_KEY configured={bool(settings.CALCOM_API_KEY)}")

    try:
        async with httpx.AsyncClient(timeout=10.0) as client:
            url = f"{settings.CALCOM_BASE_URL}/availability"
            params = {
                "apiKey": settings.CALCOM_API_KEY,
                "username": cal_username,
                "eventTypeId": cal_event_type_id,
                "dateFrom": date,
                "dateTo": date,
            }
            _dbg(f"get_availability: GET {url} params={json.dumps({k: v for k, v in params.items() if k != 'apiKey'})}")
            resp = await client.get(url, params=params)
            _dbg(f"get_availability: response status={resp.status_code}")
            _dbg(f"get_availability: response body={resp.text[:500]}")
            resp.raise_for_status()
            data = resp.json()
            slots = data.get("slots", {}).get(date, [])
            _dbg(f"get_availability: parsed {len(slots)} slots for date {date}")
            return slots
    except Exception as e:
        _dbg(f"get_availability: ERROR: {type(e).__name__}: {e}")
        raise Exception("CALCOM_UNAVAILABLE")


async def create_booking(
    doctor: Dict,
    patient: Dict,
    start_time: str,
    reason: str,
    idempotency_key: str = "",
) -> Dict:
    _dbg(f"create_booking: doctor={doctor.get('doctor_id')}, patient={patient.get('name')}, start='{start_time}', USE_MOCK={settings.USE_MOCK_EXTERNAL}")

    if settings.USE_MOCK_EXTERNAL:
        result = {
            "uid": f"mock-booking-{idempotency_key or 'new'}",
            "id": f"mock-{int(datetime.now().timestamp())}",
            "status": "ACCEPTED",
            "startTime": start_time,
        }
        _dbg(f"create_booking (mock): {result}")
        return result

    cal_event_type_id = doctor.get("cal_event_type_id", 0)
    _dbg(f"create_booking: cal_event_type_id={cal_event_type_id}, API_KEY configured={bool(settings.CALCOM_API_KEY)}")

    try:
        async with httpx.AsyncClient(timeout=10.0) as client:
            url = f"{settings.CALCOM_BASE_URL}/bookings"
            body = {
                "eventTypeId": int(cal_event_type_id),
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
            }
            _dbg(f"create_booking: POST {url} body={json.dumps(body)[:500]}")
            resp = await client.post(
                url,
                params={"apiKey": settings.CALCOM_API_KEY},
                json=body,
                headers={"Idempotency-Key": idempotency_key} if idempotency_key else {},
            )
            _dbg(f"create_booking: response status={resp.status_code}")
            _dbg(f"create_booking: response body={resp.text[:500]}")
            if resp.status_code == 409:
                _dbg("create_booking: SLOT_TAKEN (409)")
                raise Exception("SLOT_TAKEN")
            resp.raise_for_status()
            result = resp.json()
            _dbg(f"create_booking: success, booking_id={result.get('uid') or result.get('id')}")
            return result
    except Exception as e:
        if "SLOT_TAKEN" in str(e):
            raise
        _dbg(f"create_booking: ERROR: {type(e).__name__}: {e}")
        raise Exception("CALCOM_UNAVAILABLE")


async def reschedule_booking(cal_booking_id: str, new_start_time: str) -> Dict:
    _dbg(f"reschedule_booking: booking_id='{cal_booking_id}', new_start='{new_start_time}', USE_MOCK={settings.USE_MOCK_EXTERNAL}")

    if settings.USE_MOCK_EXTERNAL:
        result = {"uid": cal_booking_id, "status": "ACCEPTED", "startTime": new_start_time}
        _dbg(f"reschedule_booking (mock): {result}")
        return result

    try:
        async with httpx.AsyncClient(timeout=10.0) as client:
            url = f"{settings.CALCOM_BASE_URL}/bookings/{cal_booking_id}"
            _dbg(f"reschedule_booking: PATCH {url}")
            resp = await client.patch(
                url,
                params={"apiKey": settings.CALCOM_API_KEY},
                json={"start": new_start_time},
            )
            _dbg(f"reschedule_booking: response status={resp.status_code}, body={resp.text[:300]}")
            resp.raise_for_status()
            return resp.json()
    except Exception as e:
        _dbg(f"reschedule_booking: ERROR: {type(e).__name__}: {e}")
        raise Exception("CALCOM_UNAVAILABLE")


async def cancel_booking(cal_booking_id: str, reason: str = "") -> bool:
    _dbg(f"cancel_booking: booking_id='{cal_booking_id}', reason='{reason}', USE_MOCK={settings.USE_MOCK_EXTERNAL}")

    if settings.USE_MOCK_EXTERNAL:
        _dbg("cancel_booking (mock): returning True")
        return True

    try:
        async with httpx.AsyncClient(timeout=10.0) as client:
            url = f"{settings.CALCOM_BASE_URL}/bookings/{cal_booking_id}"
            _dbg(f"cancel_booking: DELETE {url}")
            resp = await client.delete(
                url,
                params={"apiKey": settings.CALCOM_API_KEY},
                json={"reason": reason},
            )
            _dbg(f"cancel_booking: response status={resp.status_code}, body={resp.text[:300]}")
            resp.raise_for_status()
            return True
    except Exception as e:
        _dbg(f"cancel_booking: ERROR: {type(e).__name__}: {e}")
        return False
