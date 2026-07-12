import logging
from datetime import datetime, timedelta, timezone
from typing import Dict, List, Optional

from config import settings
from database import get_db

logger = logging.getLogger(__name__)

MOCK_SUMMARY_TEMPLATE = """Patient {name} ({age} y/o {gender}) has visited {visit_count} time(s). 
Most recent visit was for {last_reason}. 
{extra}"""


async def generate_patient_summary(patient: Dict, appointments: List[Dict]) -> str:
    """Generate AI patient summary using Claude Sonnet 4.5 with 24h cache."""
    db = get_db()
    patient_id = patient.get("patient_id")
    doctor_id = patient.get("doctor_id")

    # Check cache
    cached = await db.ai_summary_cache.find_one(
        {"patient_id": patient_id, "doctor_id": doctor_id},
        {"_id": 0},
    )
    if cached and cached.get("expires_at", datetime.min.replace(tzinfo=timezone.utc)) > datetime.now(timezone.utc):
        return cached["summary"]

    # Generate summary
    summary = await _generate_summary(patient, appointments)

    # Cache for 24h
    expires_at = datetime.now(timezone.utc) + timedelta(hours=24)
    await db.ai_summary_cache.update_one(
        {"patient_id": patient_id, "doctor_id": doctor_id},
        {"$set": {
            "patient_id": patient_id,
            "doctor_id": doctor_id,
            "summary": summary,
            "generated_at": datetime.now(timezone.utc),
            "expires_at": expires_at,
        }},
        upsert=True,
    )
    return summary


async def _generate_summary(patient: Dict, appointments: List[Dict]) -> str:
    if settings.USE_MOCK_EXTERNAL or not settings.ANTHROPIC_API_KEY:
        return _mock_summary(patient, appointments)

    try:
        import anthropic
        client = anthropic.Anthropic(api_key=settings.ANTHROPIC_API_KEY)

        completed = [a for a in appointments if a.get("status") == "completed"]
        upcoming = [a for a in appointments if a.get("status") in ("confirmed", "pending")]
        reasons = list({a.get("reason", "") for a in completed if a.get("reason")})

        prompt = f"""Generate a concise 2-3 sentence clinical summary for this patient record.

Patient: {patient.get('name')}, {patient.get('age', 'unknown')} y/o {patient.get('gender', '')}
Phone: {patient.get('phone')}
Total visits: {len(completed)}
Visit reasons: {', '.join(reasons[:5]) if reasons else 'Not recorded'}
Upcoming appointments: {len(upcoming)}
Doctor notes: {patient.get('notes', 'None')}

Write a professional, factual summary a doctor would find useful at a glance. No diagnosis. No speculation."""

        message = client.messages.create(
            model="claude-sonnet-4-5",
            max_tokens=200,
            messages=[{"role": "user", "content": prompt}],
        )
        return message.content[0].text.strip()
    except Exception as e:
        logger.error(f"Claude AI summary error: {e}")
        return _mock_summary(patient, appointments)


def _mock_summary(patient: Dict, appointments: List[Dict]) -> str:
    completed = [a for a in appointments if a.get("status") == "completed"]
    reasons = [a.get("reason", "") for a in completed if a.get("reason")]
    last_reason = reasons[-1] if reasons else "general consultation"
    visit_count = len(completed)

    extras = [
        "No known allergies on file.",
        "Patient prefers morning appointments.",
        "Follow-up recommended in 3 months.",
        "Patient has been compliant with previous treatment plans.",
    ]
    import random
    extra = random.choice(extras)

    return MOCK_SUMMARY_TEMPLATE.format(
        name=patient.get("name", "Patient"),
        age=patient.get("age", "unknown"),
        gender=patient.get("gender", ""),
        visit_count=visit_count,
        last_reason=last_reason,
        extra=extra,
    ).strip()


async def invalidate_summary_cache(patient_id: str, doctor_id: str):
    db = get_db()
    await db.ai_summary_cache.delete_one({"patient_id": patient_id, "doctor_id": doctor_id})
