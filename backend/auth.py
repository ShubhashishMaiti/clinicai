import hashlib
import hmac
import logging
from datetime import datetime, timedelta, timezone
from typing import Optional

import bcrypt
import jwt
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer

from config import settings
from database import get_db

logger = logging.getLogger(__name__)

bearer_scheme = HTTPBearer()


def hash_password(password: str) -> str:
    password_bytes = password.encode("utf-8")[:72]
    salt = bcrypt.gensalt()
    return bcrypt.hashpw(password_bytes, salt).decode("utf-8")


def verify_password(plain: str, hashed: str) -> bool:
    plain_bytes = plain.encode("utf-8")[:72]
    hashed_bytes = hashed.encode("utf-8")
    return bcrypt.checkpw(plain_bytes, hashed_bytes)


def create_token(doctor_id: str) -> str:
    expire = datetime.now(timezone.utc) + timedelta(days=settings.JWT_EXPIRE_DAYS)
    payload = {"sub": doctor_id, "exp": expire}
    return jwt.encode(payload, settings.JWT_SECRET, algorithm=settings.JWT_ALGORITHM)


def decode_token(token: str) -> Optional[str]:
    try:
        payload = jwt.decode(token, settings.JWT_SECRET, algorithms=[settings.JWT_ALGORITHM])
        return payload.get("sub")
    except jwt.ExpiredSignatureError:
        raise HTTPException(status_code=401, detail={"code": "SESSION_EXPIRED", "message": "Session expired"})
    except jwt.InvalidTokenError:
        raise HTTPException(status_code=401, detail={"code": "UNAUTHORIZED", "message": "Invalid token"})


async def get_current_doctor(
    credentials: HTTPAuthorizationCredentials = Depends(bearer_scheme),
):
    doctor_id = decode_token(credentials.credentials)
    db = get_db()
    doctor = await db.doctors.find_one({"doctor_id": doctor_id}, {"_id": 0})
    if not doctor:
        raise HTTPException(status_code=401, detail={"code": "UNAUTHORIZED", "message": "Doctor not found"})
    return doctor


async def get_admin_doctor(doctor=Depends(get_current_doctor)):
    if not doctor.get("is_admin"):
        raise HTTPException(status_code=403, detail={"code": "UNAUTHORIZED", "message": "Admin access required"})
    return doctor


def verify_vapi_signature(payload: bytes, signature: str) -> bool:
    """Verify HMAC-SHA256 Vapi webhook signature."""
    expected = hmac.new(
        settings.VAPI_SERVER_SECRET.encode(),
        payload,
        hashlib.sha256,
    ).hexdigest()
    return hmac.compare_digest(expected, signature)
