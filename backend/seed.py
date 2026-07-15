"""
Seed script: runs on startup when the admin account does not exist.
Creates: 1 admin account only.
"""
import logging
from datetime import datetime, timezone

from auth import hash_password
from database import get_db
from models import Doctor

logger = logging.getLogger(__name__)

ADMIN_EMAIL = "shubho.maiti@gmail.com"
ADMIN_PASSWORD = "shubho08"


async def run_seed():
    db = get_db()

    # Check if admin already exists
    existing = await db.doctors.find_one({"email": ADMIN_EMAIL})
    if existing:
        logger.info("Admin account already exists — skipping seed")
        return

    logger.info("Seeding database: creating admin account...")

    admin = Doctor(
        email=ADMIN_EMAIL,
        password_hash=hash_password(ADMIN_PASSWORD),
        name="Admin",
        clinic_name="ClinicAI",
        is_admin=True,
    )
    await db.doctors.insert_one({**admin.model_dump(), "_id": admin.doctor_id})
    logger.info(f"Created admin: {ADMIN_EMAIL}")
    logger.info("Seed complete ✓")
