from datetime import datetime, timezone
from fastapi import APIRouter, Depends, HTTPException
from database import get_db
from auth import get_current_doctor
from models import BlockSlotRequest, BlockedSlot

router = APIRouter()


def _serialize(doc: dict) -> dict:
    result = {}
    for k, v in doc.items():
        if isinstance(v, datetime):
            result[k] = v.isoformat()
        else:
            result[k] = v
    return result


@router.post("/block")
async def block_slot(req: BlockSlotRequest, doctor=Depends(get_current_doctor)):
    db = get_db()
    slot = BlockedSlot(
        doctor_id=doctor["doctor_id"],
        start_time=req.start,
        end_time=req.end,
        reason=req.reason,
    )
    await db.blocked_slots.insert_one({**slot.model_dump(), "_id": slot.slot_id})
    return _serialize(slot.model_dump())


@router.delete("/block/{slot_id}")
async def delete_blocked_slot(slot_id: str, doctor=Depends(get_current_doctor)):
    db = get_db()
    result = await db.blocked_slots.delete_one(
        {"slot_id": slot_id, "doctor_id": doctor["doctor_id"]}
    )
    if result.deleted_count == 0:
        raise HTTPException(status_code=404, detail={"code": "NOT_FOUND", "message": "Blocked slot not found"})
    return {"deleted": True, "slot_id": slot_id}
