from datetime import datetime
from fastapi import APIRouter, Depends
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
async def get_notifications(doctor=Depends(get_current_doctor)):
    db = get_db()
    notifications = await db.notifications.find(
        {"doctor_id": doctor["doctor_id"]},
        {"_id": 0},
    ).sort("created_at", -1).limit(50).to_list(50)
    return [_serialize(n) for n in notifications]


@router.post("/{notification_id}/read")
async def mark_read(notification_id: str, doctor=Depends(get_current_doctor)):
    db = get_db()
    await db.notifications.update_one(
        {"notification_id": notification_id, "doctor_id": doctor["doctor_id"]},
        {"$set": {"read": True}},
    )
    return {"read": True}


@router.post("/read-all")
async def mark_all_read(doctor=Depends(get_current_doctor)):
    db = get_db()
    await db.notifications.update_many(
        {"doctor_id": doctor["doctor_id"]},
        {"$set": {"read": True}},
    )
    return {"read": True}
