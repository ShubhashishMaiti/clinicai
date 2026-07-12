from fastapi import APIRouter, Depends, HTTPException
from database import get_db
from models import OnboardDoctorRequest, Doctor
from auth import get_admin_doctor, hash_password

router = APIRouter()


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
