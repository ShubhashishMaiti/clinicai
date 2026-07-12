from datetime import datetime, timezone
from fastapi import APIRouter, Depends
from database import get_db
from auth import get_current_doctor
from models import UpdateProfileRequest

router = APIRouter()


@router.get("")
async def get_profile(doctor=Depends(get_current_doctor)):
    return {k: v for k, v in doctor.items() if k != "password_hash"}


@router.patch("")
async def update_profile(req: UpdateProfileRequest, doctor=Depends(get_current_doctor)):
    db = get_db()
    updates = {}
    for k, v in req.model_dump().items():
        if v is not None:
            if hasattr(v, "model_dump"):
                updates[k] = v.model_dump()
            else:
                updates[k] = v
    updates["updated_at"] = datetime.now(timezone.utc)
    await db.doctors.update_one({"doctor_id": doctor["doctor_id"]}, {"$set": updates})
    updated = await db.doctors.find_one({"doctor_id": doctor["doctor_id"]}, {"_id": 0, "password_hash": 0})
    return updated
