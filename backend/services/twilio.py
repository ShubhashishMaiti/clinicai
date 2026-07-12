import logging
from typing import Optional

from config import settings

logger = logging.getLogger(__name__)


async def send_sms(to: str, body: str) -> bool:
    """Send SMS via Twilio. Gracefully fails — never breaks parent operation."""
    if settings.USE_MOCK_EXTERNAL:
        logger.info(f"[MOCK SMS] To: {to} | Body: {body}")
        return True

    try:
        from twilio.rest import Client
        client = Client(settings.TWILIO_ACCOUNT_SID, settings.TWILIO_AUTH_TOKEN)
        message = client.messages.create(
            body=body,
            from_=settings.TWILIO_FROM_NUMBER,
            to=to,
        )
        logger.info(f"SMS sent: {message.sid} to {to}")
        return True
    except Exception as e:
        logger.error(f"SMS_FAILED: {e} — booking proceeds normally")
        return False


async def send_booking_confirmation(patient_phone: str, patient_name: str, doctor_name: str, appointment_time: str) -> bool:
    body = (
        f"Hi {patient_name}! Your appointment with {doctor_name} is confirmed for "
        f"{appointment_time}. Reply CANCEL to cancel. — ClinicAI"
    )
    return await send_sms(patient_phone, body)


async def send_cancellation_notice(patient_phone: str, patient_name: str, doctor_name: str, appointment_time: str) -> bool:
    body = (
        f"Hi {patient_name}, your appointment with {doctor_name} on {appointment_time} "
        f"has been cancelled. Call us to rebook. — ClinicAI"
    )
    return await send_sms(patient_phone, body)


async def send_reschedule_notice(patient_phone: str, patient_name: str, doctor_name: str, new_time: str) -> bool:
    body = (
        f"Hi {patient_name}, your appointment with {doctor_name} has been rescheduled to "
        f"{new_time}. — ClinicAI"
    )
    return await send_sms(patient_phone, body)
