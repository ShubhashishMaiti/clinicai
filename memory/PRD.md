# ClinicAI — Product Requirements Document

## Overview
ClinicAI is a multi-tenant AI Receptionist SaaS for medical clinics. The mobile app is used exclusively by doctors. Patients interact only via phone calls handled by a Vapi AI voice receptionist.

## Architecture
```
Patient phone call → Vapi AI receptionist → FastAPI backend (port 8001)
                                              ├─▶ Cal.com API   (availability, bookings)
                                              ├─▶ Twilio        (SMS confirmations)
                                              ├─▶ Claude Sonnet 4.5 (AI patient summaries)
                                              ├─▶ MongoDB       (multi-tenant data)
                                              └─▶ WebSocket     → Doctor mobile app (realtime push)
```

## Multi-Tenancy
- Each doctor has a unique Vapi inbound phone number (`doctors.inbound_phone`)
- One shared Vapi assistant with N phone numbers (Variant A)
- Backend resolves doctor from `call.phoneNumber.number` in webhook
- Every MongoDB query scoped by `doctor_id` derived from JWT
- HMAC-SHA256 verification on all Vapi webhooks

## Backend Spec
- **Framework**: FastAPI
- **Port**: 8001
- **Route prefix**: `/api`
- **Database**: MongoDB (motor async driver)
- **Auth**: JWT Bearer, bcrypt passwords, 7-day expiry

### Collections
| Collection | Purpose |
|---|---|
| `doctors` | Doctor accounts + clinic config |
| `patients` | Patient records (per doctor) |
| `appointments` | Booking records |
| `blocked_slots` | Doctor-blocked time |
| `notifications` | In-app notifications |
| `activity_log` | Audit trail |
| `ai_summary_cache` | Claude summary cache (24h TTL) |

### Environment Flag
`USE_MOCK_EXTERNAL=true` — all external services (Vapi, Cal.com, Twilio, Claude) return realistic mock data. Set to `false` after pasting real API keys.

## Mobile App
- **Framework**: Flutter
- **Design**: White + Blue (#2563EB), Sora font, 20px radius cards
- **Screens**: Login, Dashboard, Calendar, Appointments, Patients, Profile
- **Real-time**: WebSocket connection for live appointment push

## Key User Flows
1. Patient calls → Vapi AI greets → books appointment → doctor sees live notification
2. Doctor views dashboard → today's schedule with NOW indicator
3. Doctor taps appointment → complete/reschedule/cancel
4. Doctor views patient → AI-generated summary + history
5. Doctor books manually → 3-step flow (patient → slot → confirm)
