from fastapi import APIRouter, Depends, HTTPException
from database import get_db
from models import OnboardDoctorRequest, Doctor
from auth import get_admin_doctor, hash_password
from typing import Optional, List, Dict, Any
from pydantic import BaseModel

router = APIRouter()


class UpdateDoctorRequest(BaseModel):
    name: Optional[str] = None
    email: Optional[str] = None
    password: Optional[str] = None
    phone: Optional[str] = None
    clinic_name: Optional[str] = None
    clinic_address: Optional[str] = None
    specialization: Optional[str] = None
    inbound_phone: Optional[str] = None
    cal_username: Optional[str] = None
    cal_event_type_id: Optional[str] = None
    working_hours: Optional[Dict[str, str]] = None
    working_days: Optional[List[str]] = None


@router.post("/doctors")
async def onboard_doctor(req: OnboardDoctorRequest, admin=Depends(get_admin_doctor)):
    db = get_db()
    existing = await db.doctors.find_one({"email": req.email.lower()})
    if existing:
        raise HTTPException(status_code=409, detail={"code": "DUPLICATE", "message": "Doctor email already exists"})

    doctor = Doctor(
        email=req.email.lower(),
        password_hash=hash_password(req.password),
        name=req.name,
        phone=req.phone,
        clinic_name=req.clinic_name,
        clinic_address=req.clinic_address,
        specialization=req.specialization,
        inbound_phone=req.inbound_phone,
        cal_username=req.cal_username,
        cal_event_type_id=req.cal_event_type_id,
        working_hours=req.working_hours,
        working_days=req.working_days,
        is_admin=False,
    )
    await db.doctors.insert_one({**doctor.model_dump(), "_id": doctor.doctor_id})
    result = doctor.model_dump()
    result.pop("password_hash", None)
    return result


@router.get("/doctors")
async def list_doctors(admin=Depends(get_admin_doctor)):
    db = get_db()
    doctors = await db.doctors.find({}, {"_id": 0, "password_hash": 0}).to_list(None)
    return doctors


@router.patch("/doctors/{doctor_id}")
async def update_doctor(doctor_id: str, req: UpdateDoctorRequest, admin=Depends(get_admin_doctor)):
    db = get_db()
    existing = await db.doctors.find_one({"doctor_id": doctor_id})
    if not existing:
        raise HTTPException(status_code=404, detail={"code": "NOT_FOUND", "message": "Doctor not found"})

    update_data: Dict[str, Any] = {}
    if req.name is not None:
        update_data["name"] = req.name
    if req.phone is not None:
        update_data["phone"] = req.phone
    if req.clinic_name is not None:
        update_data["clinic_name"] = req.clinic_name
    if req.clinic_address is not None:
        update_data["clinic_address"] = req.clinic_address
    if req.specialization is not None:
        update_data["specialization"] = req.specialization
    if req.inbound_phone is not None:
        update_data["inbound_phone"] = req.inbound_phone
    if req.cal_username is not None:
        update_data["cal_username"] = req.cal_username
    if req.cal_event_type_id is not None:
        update_data["cal_event_type_id"] = req.cal_event_type_id
    if req.working_hours is not None:
        update_data["working_hours"] = req.working_hours
    if req.working_days is not None:
        update_data["working_days"] = req.working_days
    if req.password is not None and req.password.strip():
        update_data["password_hash"] = hash_password(req.password)

    if update_data:
        await db.doctors.update_one({"doctor_id": doctor_id}, {"$set": update_data})

    updated = await db.doctors.find_one({"doctor_id": doctor_id}, {"_id": 0, "password_hash": 0})
    return updated


@router.delete("/doctors/{doctor_id}")
async def delete_doctor(doctor_id: str, admin=Depends(get_admin_doctor)):
    db = get_db()
    existing = await db.doctors.find_one({"doctor_id": doctor_id})
    if not existing:
        raise HTTPException(status_code=404, detail={"code": "NOT_FOUND", "message": "Doctor not found"})

    # Prevent deleting admin accounts
    if existing.get("is_admin", False):
        raise HTTPException(status_code=403, detail={"code": "FORBIDDEN", "message": "Cannot delete admin accounts"})

    await db.doctors.delete_one({"doctor_id": doctor_id})
    return {"message": "Doctor removed successfully"}
