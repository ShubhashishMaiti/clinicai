"""
Seed script: runs on startup when collections are empty.
Creates: 1 admin, 3 doctors, 15 patients, ~40 appointments, blocked slots, notifications.
"""
import logging
import random
from datetime import datetime, timedelta, timezone

from auth import hash_password
from database import get_db
from models import (
    Doctor, Patient, Appointment, BlockedSlot, Notification, WorkingHours, new_id
)

logger = logging.getLogger(__name__)

ADMIN_EMAIL = "admin@clinic.com"
ADMIN_PASSWORD = "Admin@123"
DOCTOR_PASSWORD = "Demo@123"

DOCTORS_DATA = [
    {
        "email": "dr.smith@clinic.com",
        "name": "Dr. Sarah Smith",
        "phone": "+14155550201",
        "clinic_name": "Bloom Family Clinic",
        "clinic_address": "123 Oak Street, San Francisco, CA 94102",
        "specialization": "General Physician",
        "inbound_phone": "+14155550101",
        "cal_username": "dr-sarah-smith",
        "cal_event_type_id": "1001",
        "working_hours": {"start": "09:00", "end": "17:00"},
        "working_days": ["Mon", "Tue", "Wed", "Thu", "Fri"],
        "break_start": "13:00",
        "break_end": "14:00",
    },
    {
        "email": "dr.patel@clinic.com",
        "name": "Dr. Anil Patel",
        "phone": "+14155550202",
        "clinic_name": "Sunrise Dental",
        "clinic_address": "456 Maple Ave, San Francisco, CA 94103",
        "specialization": "Dentist",
        "inbound_phone": "+14155550102",
        "cal_username": "dr-anil-patel",
        "cal_event_type_id": "1002",
        "working_hours": {"start": "08:00", "end": "16:00"},
        "working_days": ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat"],
        "break_start": "12:00",
        "break_end": "13:00",
    },
    {
        "email": "dr.chen@clinic.com",
        "name": "Dr. Emily Chen",
        "phone": "+14155550203",
        "clinic_name": "Serene Skin",
        "clinic_address": "789 Pine Blvd, San Francisco, CA 94104",
        "specialization": "Dermatologist",
        "inbound_phone": "+14155550103",
        "cal_username": "dr-emily-chen",
        "cal_event_type_id": "1003",
        "working_hours": {"start": "10:00", "end": "18:00"},
        "working_days": ["Tue", "Wed", "Thu", "Fri", "Sat"],
        "break_start": "13:30",
        "break_end": "14:30",
    },
]

PATIENTS_DATA = [
    # Dr. Smith's patients (5)
    {"name": "Priya Sharma", "phone": "+14155551001", "age": 34, "gender": "Female", "email": "priya@example.com"},
    {"name": "James Wilson", "phone": "+14155551002", "age": 52, "gender": "Male", "email": "james@example.com"},
    {"name": "Maria Garcia", "phone": "+14155551003", "age": 28, "gender": "Female", "email": "maria@example.com"},
    {"name": "Robert Chen", "phone": "+14155551004", "age": 67, "gender": "Male", "email": "robert@example.com"},
    {"name": "Aisha Mohammed", "phone": "+14155551005", "age": 41, "gender": "Female", "email": "aisha@example.com"},
    # Dr. Patel's patients (5)
    {"name": "David Kim", "phone": "+14155551006", "age": 29, "gender": "Male", "email": "david@example.com"},
    {"name": "Sofia Rossi", "phone": "+14155551007", "age": 35, "gender": "Female", "email": "sofia@example.com"},
    {"name": "Michael Brown", "phone": "+14155551008", "age": 44, "gender": "Male", "email": "michael@example.com"},
    {"name": "Fatima Al-Hassan", "phone": "+14155551009", "age": 31, "gender": "Female", "email": "fatima@example.com"},
    {"name": "Carlos Rivera", "phone": "+14155551010", "age": 58, "gender": "Male", "email": "carlos@example.com"},
    # Dr. Chen's patients (5)
    {"name": "Emma Thompson", "phone": "+14155551011", "age": 26, "gender": "Female", "email": "emma@example.com"},
    {"name": "Raj Patel", "phone": "+14155551012", "age": 38, "gender": "Male", "email": "raj@example.com"},
    {"name": "Yuki Tanaka", "phone": "+14155551013", "age": 23, "gender": "Female", "email": "yuki@example.com"},
    {"name": "Samuel Okafor", "phone": "+14155551014", "age": 45, "gender": "Male", "email": "samuel@example.com"},
    {"name": "Lily Zhang", "phone": "+14155551015", "age": 32, "gender": "Female", "email": "lily@example.com"},
]

REASONS = [
    "Annual checkup", "Flu symptoms", "Back pain", "Headache", "Skin rash",
    "Dental cleaning", "Tooth pain", "Cavity filling", "Acne treatment",
    "Follow-up visit", "Blood pressure check", "Prescription renewal",
    "Allergy consultation", "Eczema flare-up", "Teeth whitening",
]

STATUSES = ["confirmed", "confirmed", "confirmed", "completed", "completed", "cancelled", "pending", "rescheduled"]


def _random_time(base: datetime, hour_start: int = 9, hour_end: int = 17) -> datetime:
    hour = random.randint(hour_start, hour_end - 1)
    minute = random.choice([0, 30])
    return base.replace(hour=hour, minute=minute, second=0, microsecond=0)


async def run_seed():
    db = get_db()

    # Check if already seeded
    count = await db.doctors.count_documents({})
    if count > 0:
        logger.info("Database already seeded — skipping")
        return

    logger.info("Seeding database...")
    now = datetime.now(timezone.utc)

    # ── Admin ──────────────────────────────────────────────────────────────────
    admin = Doctor(
        email=ADMIN_EMAIL,
        password_hash=hash_password(ADMIN_PASSWORD),
        name="Admin User",
        clinic_name="ClinicAI HQ",
        is_admin=True,
    )
    await db.doctors.insert_one({**admin.model_dump(), "_id": admin.doctor_id})
    logger.info(f"Created admin: {ADMIN_EMAIL}")

    # ── Doctors ────────────────────────────────────────────────────────────────
    doctor_ids = []
    for d_data in DOCTORS_DATA:
        doctor = Doctor(
            email=d_data["email"],
            password_hash=hash_password(DOCTOR_PASSWORD),
            name=d_data["name"],
            phone=d_data["phone"],
            clinic_name=d_data["clinic_name"],
            clinic_address=d_data["clinic_address"],
            specialization=d_data["specialization"],
            inbound_phone=d_data["inbound_phone"],
            cal_username=d_data["cal_username"],
            cal_event_type_id=d_data["cal_event_type_id"],
            working_hours=WorkingHours(**d_data["working_hours"]),
            working_days=d_data["working_days"],
            break_start=d_data["break_start"],
            break_end=d_data["break_end"],
            is_admin=False,
        )
        await db.doctors.insert_one({**doctor.model_dump(), "_id": doctor.doctor_id})
        doctor_ids.append(doctor.doctor_id)
        logger.info(f"Created doctor: {d_data['email']}")

    # ── Patients ───────────────────────────────────────────────────────────────
    patient_ids = []
    for i, p_data in enumerate(PATIENTS_DATA):
        # Assign 5 patients per doctor
        doctor_id = doctor_ids[i // 5]
        patient = Patient(
            doctor_id=doctor_id,
            name=p_data["name"],
            phone=p_data["phone"],
            age=p_data["age"],
            gender=p_data["gender"],
            email=p_data["email"],
        )
        await db.patients.insert_one({**patient.model_dump(), "_id": patient.patient_id})
        patient_ids.append((patient.patient_id, doctor_id, p_data))

    logger.info(f"Created {len(patient_ids)} patients")

    # ── Appointments (~40) ─────────────────────────────────────────────────────
    appointment_count = 0
    day_offsets = [-2, -1, -1, 0, 0, 0, 0, 0, 1, 1, 1, 2, 3, 5, 7, 8, 10, 12, 14]

    for patient_id, doctor_id, p_data in patient_ids:
        # 2-3 appointments per patient
        num_appts = random.randint(2, 3)
        used_offsets = random.sample(day_offsets, min(num_appts, len(day_offsets)))

        for offset in used_offsets:
            base_date = (now + timedelta(days=offset)).replace(
                hour=0, minute=0, second=0, microsecond=0
            )
            start_time = _random_time(base_date)
            end_time = start_time + timedelta(minutes=30)

            # Determine status based on time
            if offset < 0:
                status = random.choice(["completed", "completed", "cancelled"])
            elif offset == 0:
                status = random.choice(["confirmed", "confirmed", "pending", "completed"])
            else:
                status = random.choice(["confirmed", "confirmed", "pending", "rescheduled"])

            reason = random.choice(REASONS)
            is_first = random.random() < 0.3

            appt = Appointment(
                doctor_id=doctor_id,
                patient_id=patient_id,
                patient_name=p_data["name"],
                patient_phone=p_data["phone"],
                reason=reason,
                start_time=start_time,
                end_time=end_time,
                duration_minutes=30,
                status=status,
                cal_booking_id=f"mock-cal-{new_id()[:8]}",
                notes="Follow-up recommended" if status == "completed" and random.random() < 0.4 else "",
                is_first_visit=is_first,
            )
            await db.appointments.insert_one({**appt.model_dump(), "_id": appt.appointment_id})
            appointment_count += 1

    logger.info(f"Created {appointment_count} appointments")

    # ── Blocked Slots ──────────────────────────────────────────────────────────
    blocked_data = [
        {
            "doctor_id": doctor_ids[0],
            "start": now.replace(hour=12, minute=0, second=0, microsecond=0) + timedelta(days=2),
            "end": now.replace(hour=13, minute=0, second=0, microsecond=0) + timedelta(days=2),
            "reason": "Lunch",
        },
        {
            "doctor_id": doctor_ids[0],
            "start": now.replace(hour=15, minute=0, second=0, microsecond=0) + timedelta(days=3),
            "end": now.replace(hour=17, minute=0, second=0, microsecond=0) + timedelta(days=3),
            "reason": "Conference",
        },
        {
            "doctor_id": doctor_ids[1],
            "start": now.replace(hour=10, minute=0, second=0, microsecond=0) + timedelta(days=1),
            "end": now.replace(hour=11, minute=0, second=0, microsecond=0) + timedelta(days=1),
            "reason": "Personal",
        },
        {
            "doctor_id": doctor_ids[2],
            "start": now.replace(hour=14, minute=0, second=0, microsecond=0) + timedelta(days=4),
            "end": now.replace(hour=16, minute=0, second=0, microsecond=0) + timedelta(days=4),
            "reason": "CME Training",
        },
    ]

    for b in blocked_data:
        slot = BlockedSlot(
            doctor_id=b["doctor_id"],
            start_time=b["start"],
            end_time=b["end"],
            reason=b["reason"],
        )
        await db.blocked_slots.insert_one({**slot.model_dump(), "_id": slot.slot_id})

    logger.info("Created blocked slots")

    # ── Notifications ──────────────────────────────────────────────────────────
    notif_data = [
        {
            "doctor_id": doctor_ids[0],
            "title": "New Booking",
            "body": "Priya Sharma booked for today at 10:00 AM",
            "type": "booking",
        },
        {
            "doctor_id": doctor_ids[0],
            "title": "Appointment Cancelled",
            "body": "James Wilson cancelled his appointment",
            "type": "cancellation",
        },
        {
            "doctor_id": doctor_ids[1],
            "title": "New Booking via AI Receptionist",
            "body": "David Kim booked for tomorrow at 9:30 AM",
            "type": "booking",
        },
        {
            "doctor_id": doctor_ids[2],
            "title": "Appointment Rescheduled",
            "body": "Emma Thompson rescheduled to next Monday",
            "type": "reschedule",
        },
    ]

    for n in notif_data:
        notif = Notification(
            doctor_id=n["doctor_id"],
            title=n["title"],
            body=n["body"],
            type=n["type"],
        )
        await db.notifications.insert_one({**notif.model_dump(), "_id": notif.notification_id})

    logger.info("Seed complete ✓")
