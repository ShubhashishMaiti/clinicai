from datetime import datetime, timezone
from typing import Optional
from fastapi import APIRouter, Depends, Query
from database import get_db
from auth import get_current_doctor
from services import calcom

router = APIRouter()


def _serialize(doc: dict) -> dict:
    result = {}
    for k, v in doc.items():
        if isinstance(v, datetime):
            result[k] = v.isoformat()
        else:
            result[k] = v
    return result


@router.get("")
async def get_calendar(
    view: str = Query("day", regex="day|week|month"),
    date: str = Query(...),
    doctor=Depends(get_current_doctor),
):
    db = get_db()
    doctor_id = doctor["doctor_id"]

    from datetime import timedelta
    try:
        base_date = datetime.fromisoformat(date).replace(tzinfo=timezone.utc)
    except ValueError:
        base_date = datetime.now(timezone.utc).replace(hour=0, minute=0, second=0, microsecond=0)

    if view == "day":
        start = base_date.replace(hour=0, minute=0, second=0, microsecond=0)
        end = base_date.replace(hour=23, minute=59, second=59, microsecond=0)
    elif view == "week":
        # Start from Monday
        weekday = base_date.weekday()
        start = (base_date - timedelta(days=weekday)).replace(hour=0, minute=0, second=0, microsecond=0)
        end = (start + timedelta(days=6)).replace(hour=23, minute=59, second=59, microsecond=0)
    else:  # month
        start = base_date.replace(day=1, hour=0, minute=0, second=0, microsecond=0)
        # Last day of month
        if start.month == 12:
            end = start.replace(year=start.year + 1, month=1, day=1) - timedelta(seconds=1)
        else:
            end = start.replace(month=start.month + 1, day=1) - timedelta(seconds=1)

    # Appointments
    appointments = await db.appointments.find(
        {"doctor_id": doctor_id, "start_time": {"$gte": start, "$lte": end}},
        {"_id": 0},
    ).sort("start_time", 1).to_list(200)

    # Blocked slots
    blocked = await db.blocked_slots.find(
        {"doctor_id": doctor_id, "start_time": {"$gte": start, "$lte": end}},
        {"_id": 0},
    ).sort("start_time", 1).to_list(50)

    # Available slots (from Cal.com / mock)
    available_slots = []
    if view == "day":
        try:
            slots = await calcom.get_availability(doctor, date)
            available_slots = [s for s in slots if s.get("available")]
        except Exception:
            pass

    return {
        "view": view,
        "date": date,
        "appointments": [_serialize(a) for a in appointments],
        "blocked_slots": [_serialize(b) for b in blocked],
        "available_slots": available_slots,
    }


@router.get("/availability")
async def get_availability(date: str = Query(...), doctor=Depends(get_current_doctor)):
    try:
        slots = await calcom.get_availability(doctor, date)
        return {"date": date, "slots": slots}
    except Exception as e:
        if "CALCOM_UNAVAILABLE" in str(e):
            from fastapi import HTTPException
            raise HTTPException(status_code=503, detail={"code": "CALCOM_UNAVAILABLE", "message": "Availability service unavailable"})
        raise
