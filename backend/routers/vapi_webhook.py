import hashlib
import hmac
import json
import logging
import sys
from datetime import datetime, timedelta, timezone

from fastapi import APIRouter, HTTPException, Request
from database import get_db
from config import settings
from services.vapi import handle_vapi_function_call, build_assistant_overrides
from services import twilio
from routers.websocket import broadcast
from models import Patient, Appointment, Notification

router = APIRouter()
logger = logging.getLogger(__name__)


def _dbg(msg: str):
    """Dual-output debug: both logger.info and print to stdout (for Render logs)."""
    logger.info(msg)
    print(f"[VAPI_DEBUG] {msg}", flush=True)


def _serialize(doc: dict) -> dict:
    result = {}
    for k, v in doc.items():
        if isinstance(v, datetime):
            result[k] = v.isoformat()
        else:
            result[k] = v
    return result


@router.post("/webhook")
async def vapi_webhook(request: Request):
    body = await request.body()
    headers_dict = dict(request.headers)

    _dbg(f"=== VAPI WEBHOOK RECEIVED ===")
    _dbg(f"Body length: {len(body)} bytes")
    _dbg(f"Headers: {json.dumps({k: v for k, v in headers_dict.items() if 'auth' not in k.lower()})}")

    # ── HMAC verification ────────────────────────────────────────────────────
    signature = request.headers.get("x-vapi-signature", "")
    _dbg(f"x-vapi-signature header: '{signature}'")
    _dbg(f"VAPI_SERVER_SECRET configured: {bool(settings.VAPI_SERVER_SECRET)}")

    if signature and settings.VAPI_SERVER_SECRET:
        expected = hmac.new(
            settings.VAPI_SERVER_SECRET.encode(),
            body,
            hashlib.sha256,
        ).hexdigest()
        _dbg(f"HMAC expected: {expected[:16]}... | received: {signature[:16]}...")
        if not hmac.compare_digest(expected, signature):
            _dbg(f"HMAC MISMATCH — rejecting. Expected={expected}, Got={signature}")
            raise HTTPException(
                status_code=401,
                detail={"code": "UNAUTHORIZED", "message": "Invalid Vapi signature"},
            )
        _dbg("HMAC verification PASSED")
    elif not signature and settings.VAPI_SERVER_SECRET:
        # Vapi web calls (browser SDK) do not send x-vapi-signature.
        # Phone calls always send it. Allow through but log clearly.
        _dbg("HMAC check SKIPPED — no signature header (web/browser call or Vapi dashboard test). Proceeding.")
    else:
        _dbg(f"HMAC check SKIPPED (signature present={bool(signature)}, secret configured={bool(settings.VAPI_SERVER_SECRET)})")

    # ── Parse JSON ───────────────────────────────────────────────────────────
    try:
        payload = json.loads(body)
    except json.JSONDecodeError as e:
        _dbg(f"JSON parse error: {e}")
        raise HTTPException(status_code=400, detail="Invalid JSON")

    _dbg(f"Full payload: {json.dumps(payload, default=str)[:2000]}")
    _dbg(f"Payload top-level keys: {list(payload.keys())}")

    message = payload.get("message", {})
    msg_type = message.get("type", "")
    call = message.get("call", {})

    _dbg(f"message.type = '{msg_type}'")
    _dbg(f"message keys: {list(message.keys())}")
    _dbg(f"call keys: {list(call.keys())}")

    # ── Resolve doctor from inbound phone number ─────────────────────────────
    phone_number_obj = (
        call.get("phoneNumber")
        or message.get("phoneNumber")
        or payload.get("phoneNumber")
        or {}
    )
    called_number = (
        phone_number_obj.get("number")
        or call.get("to")
        or ""
    )
    caller_number = (
        call.get("customer", {}).get("number", "")
        or call.get("from", "")
        or ""
    )
    _dbg(f"phoneNumber object: {phone_number_obj}")
    _dbg(f"Called number (to): '{called_number}'")
    _dbg(f"Caller number (from): '{caller_number}'")

    db = get_db()
    doctor = None

    if called_number:
        doctor = await db.doctors.find_one(
            {"inbound_phone": called_number}, {"_id": 0}
        )
        _dbg(f"Doctor lookup by inbound_phone='{called_number}': {'FOUND' if doctor else 'NOT FOUND'}")

    if not doctor:
        # Fallback: first non-admin doctor
        doctor = await db.doctors.find_one({"is_admin": False}, {"_id": 0})
        _dbg(f"Fallback doctor (first non-admin): {'FOUND' if doctor else 'NOT FOUND'}")

    if not doctor:
        # Last resort: any doctor
        doctor = await db.doctors.find_one({}, {"_id": 0})
        _dbg(f"Last-resort doctor (any): {'FOUND' if doctor else 'NOT FOUND'}")

    if not doctor:
        _dbg("ERROR: No doctor found in database at all!")
        return {"error": "No doctor found for this number"}

    doctor_id = doctor["doctor_id"]
    _dbg(f"Resolved doctor: id={doctor_id}, name={doctor.get('name')}, clinic={doctor.get('clinic_name')}")
    _dbg(f"Doctor inbound_phone: '{doctor.get('inbound_phone', 'NOT SET')}'")
    _dbg(f"USE_MOCK_EXTERNAL: {settings.USE_MOCK_EXTERNAL}")

    # ── assistant-request ────────────────────────────────────────────────────
    if msg_type == "assistant-request":
        _dbg(f"Handling assistant-request for doctor {doctor_id}")
        overrides = build_assistant_overrides(doctor)
        overrides_inner = overrides.get("assistantOverrides", {})
        _dbg(f"Assistant overrides built (keys): {list(overrides_inner.keys())}")
        _dbg(f"Tools count in model: {len(overrides_inner.get('model', {}).get('tools', []))}")

        # Vapi assistant-request: respond with {"assistantId": "...", "assistantOverrides": {...}}
        # assistantOverrides.model MUST include tools so Vapi knows what functions exist
        if settings.VAPI_ASSISTANT_ID:
            response = {
                "assistantId": settings.VAPI_ASSISTANT_ID,
                "assistantOverrides": overrides_inner,
            }
        else:
            # Return a full inline assistant definition with tools embedded
            response = {
                "assistant": {
                    "firstMessage": overrides_inner.get("firstMessage", "Hello, how can I help you?"),
                    "model": overrides_inner.get("model", {
                        "provider": "openai",
                        "model": "gpt-4o",
                        "tools": [],
                    }),
                    "voice": {"provider": "11labs", "voiceId": "rachel"},
                }
            }
        _dbg(f"assistant-request response keys: {list(response.keys())}")
        _dbg(f"assistant-request response (truncated): {json.dumps(response, default=str)[:1000]}")
        return response

    # ── function-call (Vapi v1 shape) ────────────────────────────────────────
    elif msg_type == "function-call":
        func_call = message.get("functionCall", {})
        function_name = func_call.get("name", "")
        raw_params = func_call.get("parameters", {})
        parameters = _parse_parameters(raw_params)

        _dbg(f"function-call: name='{function_name}', raw_params={raw_params}, parsed_params={parameters}")

        result = await handle_vapi_function_call(function_name, parameters, doctor)
        _dbg(f"function-call result: {result}")

        if function_name == "bookAppointment":
            await _handle_booking(db, doctor, parameters, result)

        response = {"result": result.get("result", "Done")}
        _dbg(f"Returning function-call response: {response}")
        return response

    # ── tool-calls (Vapi v2 shape) ────────────────────────────────────────────
    elif msg_type == "tool-calls":
        tool_call_list = message.get("toolCallList", [])
        _dbg(f"tool-calls: {len(tool_call_list)} tool(s) in list")

        results = []
        for i, tool_call in enumerate(tool_call_list):
            tool_call_id = tool_call.get("id", "")
            func = tool_call.get("function", {})
            function_name = func.get("name", "")
            raw_params = func.get("arguments", {})
            parameters = _parse_parameters(raw_params)

            _dbg(f"tool-call[{i}]: id={tool_call_id}, name='{function_name}', params={parameters}")

            result = await handle_vapi_function_call(function_name, parameters, doctor)
            _dbg(f"tool-call[{i}] result: {result}")

            if function_name == "bookAppointment":
                await _handle_booking(db, doctor, parameters, result)

            results.append({
                "toolCallId": tool_call_id,
                "result": result.get("result", "Done"),
            })

        response = {"results": results}
        _dbg(f"Returning tool-calls response: {response}")
        return response

    # ── end-of-call-report ───────────────────────────────────────────────────
    elif msg_type == "end-of-call-report":
        summary = message.get("summary", "")
        caller_phone = call.get("customer", {}).get("number", "")
        _dbg(
            f"Call ended for doctor {doctor_id}. "
            f"Caller: {caller_phone}. Summary: {summary[:200]}"
        )
        return {"received": True}

    # ── status-update ────────────────────────────────────────────────────────
    elif msg_type == "status-update":
        status = message.get("status", "")
        _dbg(f"Status update: {status} for call {call.get('id', 'unknown')}")
        return {"received": True}

    # ── speech-update ────────────────────────────────────────────────────────
    elif msg_type == "speech-update":
        _dbg(f"Speech update received (ignoring)")
        return {"received": True}

    # ── transcript ───────────────────────────────────────────────────────────
    elif msg_type == "transcript":
        _dbg(f"Transcript received (ignoring)")
        return {"received": True}

    # ── hang ─────────────────────────────────────────────────────────────────
    elif msg_type == "hang":
        _dbg(f"Hang event received for doctor {doctor_id}")
        return {"received": True}

    # ── unknown ──────────────────────────────────────────────────────────────
    else:
        _dbg(f"UNHANDLED message type '{msg_type}' — returning assistant overrides as fallback")
        _dbg(f"Full message for unhandled type: {json.dumps(message, default=str)[:1000]}")
        # For unknown types, return assistant overrides as safe fallback
        if settings.VAPI_ASSISTANT_ID:
            overrides = build_assistant_overrides(doctor)
            return {
                "assistantId": settings.VAPI_ASSISTANT_ID,
                "assistantOverrides": overrides.get("assistantOverrides", {}),
            }
        return {"received": True}


def _parse_parameters(raw) -> dict:
    """Normalise parameters that may arrive as a JSON string or a dict."""
    if isinstance(raw, str):
        try:
            parsed = json.loads(raw)
            _dbg(f"_parse_parameters: parsed JSON string → {parsed}")
            return parsed
        except (json.JSONDecodeError, TypeError):
            _dbg(f"_parse_parameters: failed to parse string '{raw}'")
            return {}
    if isinstance(raw, dict):
        return raw
    _dbg(f"_parse_parameters: unexpected type {type(raw)} for value {raw}")
    return {}


async def _handle_booking(db, doctor, parameters: dict, cal_result: dict):
    """Upsert patient + appointment from Vapi booking function call."""
    doctor_id = doctor["doctor_id"]
    patient_name = parameters.get("patientName") or parameters.get("name") or "Unknown"
    patient_phone = parameters.get("patientPhone") or parameters.get("phone") or ""
    reason = parameters.get("reason", "")
    start_time_str = parameters.get("startTime") or parameters.get("date") or ""

    _dbg(
        f"_handle_booking: doctor={doctor_id}, patient={patient_name}, "
        f"phone={patient_phone}, start={start_time_str}, cal_result={cal_result}"
    )

    if not patient_phone:
        _dbg("_handle_booking: no patient phone — skipping DB write")
        return

    # Upsert patient
    existing_patient = await db.patients.find_one(
        {"doctor_id": doctor_id, "phone": patient_phone}, {"_id": 0}
    )
    if existing_patient:
        patient_id = existing_patient["patient_id"]
        _dbg(f"_handle_booking: existing patient found: {patient_id}")
    else:
        patient = Patient(
            doctor_id=doctor_id,
            name=patient_name,
            phone=patient_phone,
        )
        await db.patients.insert_one({**patient.model_dump(), "_id": patient.patient_id})
        patient_id = patient.patient_id
        _dbg(f"_handle_booking: new patient created: {patient_id}")

    # Parse start time
    try:
        if start_time_str:
            start_time = datetime.fromisoformat(start_time_str.replace("Z", "+00:00"))
        else:
            start_time = datetime.now(timezone.utc)
        _dbg(f"_handle_booking: parsed start_time={start_time.isoformat()}")
    except Exception as e:
        _dbg(f"_handle_booking: failed to parse start_time '{start_time_str}': {e}")
        start_time = datetime.now(timezone.utc)

    end_time = start_time + timedelta(minutes=30)

    # Create appointment
    appt = Appointment(
        doctor_id=doctor_id,
        patient_id=patient_id,
        patient_name=patient_name,
        patient_phone=patient_phone,
        reason=reason,
        start_time=start_time,
        end_time=end_time,
        status="confirmed",
        cal_booking_id=cal_result.get("booking_id"),
    )
    await db.appointments.insert_one({**appt.model_dump(), "_id": appt.appointment_id})
    _dbg(f"_handle_booking: appointment created: {appt.appointment_id}")

    # SMS confirmation
    try:
        await twilio.send_booking_confirmation(
            patient_phone,
            patient_name,
            doctor["name"],
            start_time.strftime("%b %d at %I:%M %p"),
        )
        _dbg(f"_handle_booking: SMS sent to {patient_phone}")
    except Exception as e:
        _dbg(f"_handle_booking: SMS send failed (non-fatal): {e}")

    # WebSocket broadcast
    try:
        await broadcast(doctor_id, {
            "event": "appointment.created",
            "appointment": _serialize(appt.model_dump()),
        })
        _dbg(f"_handle_booking: WebSocket broadcast sent for doctor {doctor_id}")
    except Exception as e:
        _dbg(f"_handle_booking: WebSocket broadcast failed (non-fatal): {e}")

    # Notification
    try:
        notif = Notification(
            doctor_id=doctor_id,
            title="New Booking via AI Receptionist",
            body=f"{patient_name} booked for {start_time.strftime('%b %d at %I:%M %p')}",
            type="booking",
            related_id=appt.appointment_id,
        )
        await db.notifications.insert_one({**notif.model_dump(), "_id": notif.notification_id})
        _dbg(f"_handle_booking: notification created: {notif.notification_id}")
    except Exception as e:
        _dbg(f"_handle_booking: notification creation failed (non-fatal): {e}")
