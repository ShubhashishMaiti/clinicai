import asyncio
import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from config import settings
from database import connect_db, disconnect_db
from seed import run_seed
from routers import auth, admin, dashboard, appointments, patients, profile, calendar, slots, search, notifications, vapi_webhook
from routers.websocket import router as ws_router

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    await connect_db()
    await run_seed()
    yield
    await disconnect_db()


app = FastAPI(
    title="ClinicAI Backend",
    version="1.0.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router, prefix="/api/auth", tags=["auth"])
app.include_router(admin.router, prefix="/api/admin", tags=["admin"])
app.include_router(dashboard.router, prefix="/api/dashboard", tags=["dashboard"])
app.include_router(appointments.router, prefix="/api/appointments", tags=["appointments"])
app.include_router(patients.router, prefix="/api/patients", tags=["patients"])
app.include_router(profile.router, prefix="/api/profile", tags=["profile"])
app.include_router(calendar.router, prefix="/api/calendar", tags=["calendar"])
app.include_router(slots.router, prefix="/api/slots", tags=["slots"])
app.include_router(search.router, prefix="/api/search", tags=["search"])
app.include_router(notifications.router, prefix="/api/notifications", tags=["notifications"])
app.include_router(vapi_webhook.router, prefix="/api/vapi", tags=["vapi"])
app.include_router(ws_router, prefix="/api", tags=["websocket"])


@app.get("/api/health")
async def health():
    return {"status": "ok", "version": "1.0.0"}


if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8001, reload=True)
