from datetime import datetime
from typing import Optional
from fastapi import APIRouter, Depends, Query
from database import get_db
from auth import get_current_doctor

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
async def global_search(q: str = Query(..., min_length=1), doctor=Depends(get_current_doctor)):
    db = get_db()
    doctor_id = doctor["doctor_id"]

    appointments = await db.appointments.find(
        {
            "doctor_id": doctor_id,
            "$or": [
                {"patient_name": {"$regex": q, "$options": "i"}},
                {"reason": {"$regex": q, "$options": "i"}},
            ],
        },
        {"_id": 0},
    ).limit(10).to_list(10)

    patients = await db.patients.find(
        {
            "doctor_id": doctor_id,
            "$or": [
                {"name": {"$regex": q, "$options": "i"}},
                {"phone": {"$regex": q, "$options": "i"}},
            ],
        },
        {"_id": 0},
    ).limit(10).to_list(10)

    return {
        "query": q,
        "appointments": [_serialize(a) for a in appointments],
        "patients": [_serialize(p) for p in patients],
    }
