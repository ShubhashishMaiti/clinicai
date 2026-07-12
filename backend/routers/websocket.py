import asyncio
import json
import logging
from datetime import datetime
from typing import Dict, Set

from fastapi import APIRouter, WebSocket, WebSocketDisconnect, Query
from auth import decode_token
from database import get_db

router = APIRouter()
logger = logging.getLogger(__name__)

# doctor_id -> set of active WebSocket connections
_connections: Dict[str, Set[WebSocket]] = {}


async def broadcast(doctor_id: str, event: dict):
    """Broadcast an event to all WebSocket connections for a doctor."""
    connections = _connections.get(doctor_id, set())
    if not connections:
        return

    message = json.dumps(event, default=str)
    dead = set()
    for ws in connections:
        try:
            await ws.send_text(message)
        except Exception:
            dead.add(ws)

    for ws in dead:
        connections.discard(ws)


@router.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket, token: str = Query(...)):
    # Authenticate
    try:
        doctor_id = decode_token(token)
    except Exception:
        await websocket.close(code=4001)
        return

    db = get_db()
    doctor = await db.doctors.find_one({"doctor_id": doctor_id}, {"_id": 0})
    if not doctor:
        await websocket.close(code=4001)
        return

    await websocket.accept()
    logger.info(f"WebSocket connected: doctor {doctor_id}")

    if doctor_id not in _connections:
        _connections[doctor_id] = set()
    _connections[doctor_id].add(websocket)

    try:
        # Send initial connection confirmation
        await websocket.send_text(json.dumps({"event": "connected", "doctor_id": doctor_id}))

        while True:
            # Keep alive — wait for ping or disconnect
            try:
                data = await asyncio.wait_for(websocket.receive_text(), timeout=30.0)
                if data == "ping":
                    await websocket.send_text("pong")
            except asyncio.TimeoutError:
                # Send keepalive ping
                await websocket.send_text(json.dumps({"event": "ping"}))
    except WebSocketDisconnect:
        logger.info(f"WebSocket disconnected: doctor {doctor_id}")
    except Exception as e:
        logger.error(f"WebSocket error for doctor {doctor_id}: {e}")
    finally:
        _connections.get(doctor_id, set()).discard(websocket)
