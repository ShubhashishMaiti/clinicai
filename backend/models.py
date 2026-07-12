from datetime import datetime, timezone
from typing import Optional, List, Dict, Any
from pydantic import BaseModel, Field
import uuid


def new_id() -> str:
    return str(uuid.uuid4())


def utcnow() -> datetime:
    return datetime.now(timezone.utc)


# ─── Doctor ───────────────────────────────────────────────────────────────────

class WorkingHours(BaseModel):
    start: str = "09:00"
    end: str = "17:00"


class Doctor(BaseModel):
    doctor_id: str = Field(default_factory=new_id)
    email: str
    password_hash: str
    name: str
    phone: str = ""
    clinic_name: str = ""
    clinic_address: str = ""
    specialization: str = ""
    inbound_phone: str = ""
    cal_username: str = ""
    cal_event_type_id: str = ""
    working_hours: WorkingHours = Field(default_factory=WorkingHours)
    working_days: List[str] = ["Mon", "Tue", "Wed", "Thu", "Fri"]
    break_start: str = "13:00"
    break_end: str = "14:00"
    vacation_mode: bool = False
    notification_prefs: Dict[str, bool] = Field(default_factory=lambda: {
        "new_booking": True,
        "cancellation": True,
        "reschedule": True,
        "sms_confirmation": True,
    })
    is_admin: bool = False
    created_at: datetime = Field(default_factory=utcnow)


# ─── Patient ──────────────────────────────────────────────────────────────────

class Patient(BaseModel):
    patient_id: str = Field(default_factory=new_id)
    doctor_id: str
    name: str
    phone: str
    age: Optional[int] = None
    gender: str = ""
    email: str = ""
    notes: str = ""
    created_at: datetime = Field(default_factory=utcnow)
    updated_at: datetime = Field(default_factory=utcnow)


# ─── Appointment ──────────────────────────────────────────────────────────────

class Appointment(BaseModel):
    appointment_id: str = Field(default_factory=new_id)
    doctor_id: str
    patient_id: str
    patient_name: str
    patient_phone: str
    reason: str = ""
    start_time: datetime
    end_time: datetime
    duration_minutes: int = 30
    status: str = "confirmed"  # confirmed | completed | cancelled | rescheduled | pending
    cal_booking_id: Optional[str] = None
    notes: str = ""
    is_first_visit: bool = False
    created_at: datetime = Field(default_factory=utcnow)
    updated_at: datetime = Field(default_factory=utcnow)


# ─── Blocked Slot ─────────────────────────────────────────────────────────────

class BlockedSlot(BaseModel):
    slot_id: str = Field(default_factory=new_id)
    doctor_id: str
    start_time: datetime
    end_time: datetime
    reason: str = ""
    created_at: datetime = Field(default_factory=utcnow)


# ─── Notification ─────────────────────────────────────────────────────────────

class Notification(BaseModel):
    notification_id: str = Field(default_factory=new_id)
    doctor_id: str
    title: str
    body: str
    type: str = "info"  # info | booking | cancellation | reschedule
    related_id: str = ""
    read: bool = False
    created_at: datetime = Field(default_factory=utcnow)


# ─── Activity Log ─────────────────────────────────────────────────────────────

class ActivityLog(BaseModel):
    log_id: str = Field(default_factory=new_id)
    doctor_id: str
    action: str
    entity_type: str = ""
    entity_id: str = ""
    details: Dict[str, Any] = Field(default_factory=dict)
    created_at: datetime = Field(default_factory=utcnow)


# ─── AI Summary Cache ─────────────────────────────────────────────────────────

class AISummaryCache(BaseModel):
    patient_id: str
    doctor_id: str
    summary: str
    generated_at: datetime = Field(default_factory=utcnow)
    expires_at: datetime


# ─── Request / Response Schemas ───────────────────────────────────────────────

class LoginRequest(BaseModel):
    email: str
    password: str


class RegisterAdminRequest(BaseModel):
    email: str
    password: str
    name: str
    clinic_name: str = "Admin Clinic"


class OnboardDoctorRequest(BaseModel):
    email: str
    password: str
    name: str
    phone: str = ""
    clinic_name: str
    clinic_address: str = ""
    specialization: str = ""
    inbound_phone: str = ""
    cal_username: str = ""
    cal_event_type_id: str = ""
    working_hours: WorkingHours = Field(default_factory=WorkingHours)
    working_days: List[str] = ["Mon", "Tue", "Wed", "Thu", "Fri"]


class CreateAppointmentRequest(BaseModel):
    patient_id: Optional[str] = None
    patient_name: str
    patient_phone: str
    patient_age: Optional[int] = None
    patient_gender: str = ""
    reason: str = ""
    start_time: datetime
    duration_minutes: int = 30


class RescheduleRequest(BaseModel):
    new_start_time: datetime
    duration_minutes: int = 30


class CompleteRequest(BaseModel):
    notes: str = ""


class CancelRequest(BaseModel):
    reason: str = ""


class BlockSlotRequest(BaseModel):
    start: datetime
    end: datetime
    reason: str = ""


class CreatePatientRequest(BaseModel):
    name: str
    phone: str
    age: Optional[int] = None
    gender: str = ""
    email: str = ""
    notes: str = ""


class UpdatePatientRequest(BaseModel):
    name: Optional[str] = None
    phone: Optional[str] = None
    age: Optional[int] = None
    gender: Optional[str] = None
    email: Optional[str] = None
    notes: Optional[str] = None


class UpdateProfileRequest(BaseModel):
    name: Optional[str] = None
    phone: Optional[str] = None
    clinic_name: Optional[str] = None
    clinic_address: Optional[str] = None
    specialization: Optional[str] = None
    working_hours: Optional[WorkingHours] = None
    working_days: Optional[List[str]] = None
    break_start: Optional[str] = None
    break_end: Optional[str] = None
    vacation_mode: Optional[bool] = None
    notification_prefs: Optional[Dict[str, bool]] = None
