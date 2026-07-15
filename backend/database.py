import logging
from motor.motor_asyncio import AsyncIOMotorClient
from config import settings

logger = logging.getLogger(__name__)

client: AsyncIOMotorClient = None
db = None


async def connect_db():
    global client, db
    try:
        client = AsyncIOMotorClient(settings.MONGO_URL)
        db = client[settings.MONGO_DB_NAME]
        await client.admin.command("ping")
        logger.info(f"Connected to MongoDB: {settings.MONGO_DB_NAME}")
        await _create_indexes()
    except Exception as e:
        logger.error(f"MongoDB connection failed: {e}")
        raise


async def disconnect_db():
    global client
    if client:
        client.close()
        logger.info("MongoDB disconnected")


async def _create_indexes():
    # Drop the old inbound_phone index if it exists without sparse=True,
    # then recreate it correctly. This handles the case where the index was
    # previously created without sparse=True (which caused DuplicateKeyError
    # when multiple doctors had inbound_phone: "").
    try:
        index_info = await db.doctors.index_information()
        if "inbound_phone_1" in index_info:
            existing = index_info["inbound_phone_1"]
            # If the existing index is not sparse, drop and recreate it
            if not existing.get("sparse", False):
                await db.doctors.drop_index("inbound_phone_1")
                logger.info("Dropped non-sparse inbound_phone index — will recreate as sparse")
    except Exception as e:
        logger.warning(f"Could not inspect/drop inbound_phone index: {e}")

    await db.doctors.create_index("email", unique=True)
    await db.doctors.create_index("inbound_phone", unique=True, sparse=True)
    await db.patients.create_index([("doctor_id", 1), ("phone", 1)], unique=True)
    await db.appointments.create_index([("doctor_id", 1), ("start_time", 1)])
    await db.appointments.create_index("cal_booking_id", sparse=True)
    await db.blocked_slots.create_index([("doctor_id", 1), ("start_time", 1)])
    await db.notifications.create_index([("doctor_id", 1), ("created_at", -1)])
    await db.activity_log.create_index([("doctor_id", 1), ("created_at", -1)])
    await db.ai_summary_cache.create_index([("patient_id", 1), ("doctor_id", 1)], unique=True)
    await db.ai_summary_cache.create_index("expires_at", expireAfterSeconds=0)
    logger.info("MongoDB indexes created")


def get_db():
    return db
