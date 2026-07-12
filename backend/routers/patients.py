from datetime import datetime, timezone
from typing import Optional
from fastapi import APIRouter, Depends, HTTPException, Query
from database import get_db
from auth import get_current_doctor
from models import CreatePatientRequest, UpdatePatientRequest
from services.ai import generate_patient_summary

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
async def list_patients(q: Optional[str] = None, doctor=Depends(get_current_doctor)):
    db = get_db()
    query = {"doctor_id": doctor["doctor_id"]}
    if q:
        query["$or"] = [
            {"name": {"$regex": q, "$options": "i"}},
            {"phone": {"$regex": q, "$options": "i"}},
        ]
    patients = await db.patients.find(query, {"_id": 0}).sort("name", 1).to_list(200)
    return [_serialize(p) for p in patients]


@router.post("")
async def create_patient(req: CreatePatientRequest, doctor=Depends(get_current_doctor)):
    db = get_db()
    doctor_id = doctor["doctor_id"]
    existing = await db.patients.find_one({"doctor_id": doctor_id, "phone": req.phone})
    if existing:
        raise HTTPException(status_code=409, detail={"code": "DUPLICATE", "message": "Patient with this phone already exists"})

    from models import Patient
    patient = Patient(
        doctor_id=doctor_id,
        name=req.name,
        phone=req.phone,
        age=req.age,
        gender=req.gender,
        email=req.email,
        notes=req.notes,
    )
    await db.patients.insert_one({**patient.model_dump(), "_id": patient.patient_id})
    return _serialize(patient.model_dump())


@router.get("/{patient_id}")
async def get_patient(patient_id: str, doctor=Depends(get_current_doctor)):
    db = get_db()
    patient = await db.patients.find_one(
        {"patient_id": patient_id, "doctor_id": doctor["doctor_id"]}, {"_id": 0}
    )
    if not patient:
        raise HTTPException(status_code=404, detail={"code": "NOT_FOUND", "message": "Patient not found"})

    # Get appointments
    appointments = await db.appointments.find(
        {"patient_id": patient_id, "doctor_id": doctor["doctor_id"]},
        {"_id": 0},
    ).sort("start_time", -1).to_list(50)

    # AI summary
    summary = await generate_patient_summary(patient, appointments)

    result = _serialize(patient)
    result["ai_summary"] = summary
    result["appointments"] = [_serialize(a) for a in appointments]
    return result


@router.patch("/{patient_id}")
async def update_patient(patient_id: str, req: UpdatePatientRequest, doctor=Depends(get_current_doctor)):
    db = get_db()
    patient = await db.patients.find_one(
        {"patient_id": patient_id, "doctor_id": doctor["doctor_id"]}, {"_id": 0}
    )
    if not patient:
        raise HTTPException(status_code=404, detail={"code": "NOT_FOUND", "message": "Patient not found"})

    updates = {k: v for k, v in req.model_dump().items() if v is not None}
    updates["updated_at"] = datetime.now(timezone.utc)
    await db.patients.update_one({"patient_id": patient_id}, {"$set": updates})

    updated = await db.patients.find_one({"patient_id": patient_id}, {"_id": 0})
    from routers.websocket import broadcast
    await broadcast(doctor["doctor_id"], {"event": "patient.updated", "patient": _serialize(updated)})
    return _serialize(updated)
