from fastapi import APIRouter, HTTPException, Depends
from database import get_db
from models import LoginRequest, RegisterAdminRequest
from auth import hash_password, verify_password, create_token, get_current_doctor

router = APIRouter()


@router.post("/register-admin")
async def register_admin(req: RegisterAdminRequest):
    db = get_db()
    existing = await db.doctors.count_documents({})
    if existing > 0:
        raise HTTPException(status_code=400, detail={"code": "ADMIN_EXISTS", "message": "Admin already bootstrapped"})

    from models import Doctor
    doctor = Doctor(
        email=req.email.lower(),
        password_hash=hash_password(req.password),
        name=req.name,
        clinic_name=req.clinic_name,
        is_admin=True,
    )
    await db.doctors.insert_one({**doctor.model_dump(), "_id": doctor.doctor_id})
    token = create_token(doctor.doctor_id)
    return {
        "access_token": token,
        "doctor_id": doctor.doctor_id,
        "name": doctor.name,
        "email": doctor.email,
        "is_admin": True,
    }


@router.post("/login")
async def login(req: LoginRequest):
    db = get_db()
    doctor = await db.doctors.find_one({"email": req.email.lower()}, {"_id": 0})
    if not doctor or not verify_password(req.password, doctor.get("password_hash", "")):
        raise HTTPException(
            status_code=401,
            detail={"code": "UNAUTHORIZED", "message": "Invalid credentials"},
        )

    token = create_token(doctor["doctor_id"])
    return {
        "access_token": token,
        "doctor_id": doctor["doctor_id"],
        "name": doctor["name"],
        "email": doctor["email"],
        "phone": doctor.get("phone", ""),
        "clinic_name": doctor.get("clinic_name", ""),
        "specialization": doctor.get("specialization", ""),
        "cal_username": doctor.get("cal_username", ""),
        "cal_event_type_id": doctor.get("cal_event_type_id", ""),
        "inbound_phone": doctor.get("inbound_phone", ""),
        "is_admin": doctor.get("is_admin", False),
    }


@router.get("/me")
async def get_me(doctor=Depends(get_current_doctor)):
    return {k: v for k, v in doctor.items() if k != "password_hash"}
