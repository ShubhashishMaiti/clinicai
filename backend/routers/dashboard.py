from datetime import datetime, timezone
from fastapi import APIRouter, Depends
from database import get_db
from auth import get_current_doctor

router = APIRouter()


@router.get("/summary")
async def dashboard_summary(doctor=Depends(get_current_doctor)):
    db = get_db()
    doctor_id = doctor["doctor_id"]
    now = datetime.now(timezone.utc)
    today_start = now.replace(hour=0, minute=0, second=0, microsecond=0)
    today_end = now.replace(hour=23, minute=59, second=59, microsecond=0)

    # KPI counts
    base = {"doctor_id": doctor_id}
    today_q = {**base, "start_time": {"$gte": today_start, "$lte": today_end}}

    today_total = await db.appointments.count_documents(today_q)
    upcoming = await db.appointments.count_documents({
        **base,
        "start_time": {"$gt": now},
        "status": {"$in": ["confirmed", "pending"]},
    })
    completed = await db.appointments.count_documents({**base, "status": "completed"})
    cancelled = await db.appointments.count_documents({**base, "status": "cancelled"})
    pending = await db.appointments.count_documents({**base, "status": "pending"})
    rescheduled = await db.appointments.count_documents({**base, "status": "rescheduled"})

    # Today's timeline
    today_appointments = await db.appointments.find(
        {**today_q, "status": {"$nin": ["cancelled"]}},
        {"_id": 0},
    ).sort("start_time", 1).to_list(20)

    # Recent patients (last 5 unique)
    recent_appts = await db.appointments.find(
        {**base, "status": "completed"},
        {"_id": 0, "patient_id": 1, "patient_name": 1, "start_time": 1},
    ).sort("start_time", -1).limit(10).to_list(10)

    seen = set()
    recent_patients = []
    for a in recent_appts:
        pid = a.get("patient_id")
        if pid and pid not in seen:
            seen.add(pid)
            patient = await db.patients.find_one({"patient_id": pid}, {"_id": 0})
            if patient:
                recent_patients.append(patient)
        if len(recent_patients) >= 5:
            break

    hour = now.hour
    if hour < 12:
        greeting = "Good morning ☀️"
    elif hour < 17:
        greeting = "Good afternoon 🌤️"
    else:
        greeting = "Good evening 🌙"

    return {
        "greeting": greeting,
        "doctor_name": doctor["name"],
        "clinic_name": doctor.get("clinic_name", ""),
        "kpi": {
            "today": today_total,
            "upcoming": upcoming,
            "completed": completed,
            "cancelled": cancelled,
            "pending": pending,
            "rescheduled": rescheduled,
        },
        "today_timeline": [_serialize_appointment(a) for a in today_appointments],
        "recent_patients": recent_patients,
    }


def _serialize_appointment(a: dict) -> dict:
    result = {}
    for k, v in a.items():
        if isinstance(v, datetime):
            result[k] = v.isoformat()
        else:
            result[k] = v
    return result
