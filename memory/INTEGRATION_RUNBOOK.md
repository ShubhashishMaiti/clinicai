# Integration Runbook

## Overview
This runbook walks you through connecting ClinicAI to real external services.
Currently running with `USE_MOCK_EXTERNAL=true` — all services are mocked.

---

## Step 1: Vapi Setup

### 1.1 Create a Vapi Account
1. Go to [dashboard.vapi.ai](https://dashboard.vapi.ai)
2. Sign up / log in

### 1.2 Create the Shared Assistant
1. Click **Assistants** → **Create Assistant**
2. Name it: `ClinicAI Receptionist`
3. Set the **Server URL** to: `https://your-backend-domain.com/api/vapi/webhook`
4. Under **Server Secret**, generate a secret and copy it → this is `VAPI_SERVER_SECRET`
5. Save the assistant → copy the **Assistant ID** → this is `VAPI_ASSISTANT_ID`

### 1.3 Buy Phone Numbers (one per doctor)
1. Click **Phone Numbers** → **Buy Number**
2. Buy 3 numbers (one for each demo doctor)
3. Assign each number to the `ClinicAI Receptionist` assistant
4. Update each doctor's `inbound_phone` in MongoDB to match the purchased numbers

### 1.4 Get API Key
1. Go to **Account** → **API Keys**
2. Create a key → this is `VAPI_API_KEY`

---

## Step 2: Cal.com Setup

### 2.1 Create a Cal.com Account
1. Go to [cal.com](https://cal.com) and sign up

### 2.2 Create Event Types (one per doctor)
1. For each doctor, create a **30-minute** event type
2. Note the **Event Type ID** from the URL (e.g., `/event-types/12345`)
3. Update each doctor's `cal_event_type_id` in MongoDB

### 2.3 Generate API Key
1. Go to **Settings** → **Developer** → **API Keys**
2. Create a key → this is `CALCOM_API_KEY`

---

## Step 3: Twilio Setup

### 3.1 Create a Twilio Account
1. Go to [console.twilio.com](https://console.twilio.com)
2. Sign up / log in

### 3.2 Get Credentials
1. From the dashboard, copy:
   - **Account SID** → `TWILIO_ACCOUNT_SID`
   - **Auth Token** → `TWILIO_AUTH_TOKEN`

### 3.3 Buy a Phone Number
1. Go to **Phone Numbers** → **Buy a Number**
2. Buy an SMS-capable number → this is `TWILIO_FROM_NUMBER`

---

## Step 4: Anthropic (Claude) Setup

1. Go to [console.anthropic.com](https://console.anthropic.com)
2. Create an API key → this is `ANTHROPIC_API_KEY`

---

## Step 5: Paste Environment Variables

Edit `backend/.env`:

```env
USE_MOCK_EXTERNAL=false

VAPI_API_KEY=your_vapi_api_key_here
VAPI_ASSISTANT_ID=your_vapi_assistant_id_here
VAPI_SERVER_SECRET=your_vapi_server_secret_here

CALCOM_API_KEY=your_calcom_api_key_here

TWILIO_ACCOUNT_SID=your_twilio_account_sid_here
TWILIO_AUTH_TOKEN=your_twilio_auth_token_here
TWILIO_FROM_NUMBER=+1XXXXXXXXXX

ANTHROPIC_API_KEY=your_anthropic_api_key_here
```

---

## Step 6: Restart Backend

```bash
cd backend
uvicorn main:app --host 0.0.0.0 --port 8001 --reload
```

---

## Verification Checklist
- [ ] Vapi webhook URL set to `https://your-domain.com/api/vapi/webhook`
- [ ] Vapi server secret matches `VAPI_SERVER_SECRET` in `.env`
- [ ] Each doctor's `inbound_phone` matches a Vapi phone number
- [ ] Cal.com event type IDs updated per doctor
- [ ] Twilio number can send SMS
- [ ] `USE_MOCK_EXTERNAL=false` in `.env`
- [ ] Backend restarted

---

## Webhook Test (curl)

```bash
# Test Vapi webhook (mock signature)
curl -X POST https://your-domain.com/api/vapi/webhook \
  -H "Content-Type: application/json" \
  -d '{"message":{"type":"assistant-request","call":{"phoneNumber":{"number":"+14155550101"}}}}'
```

Expected response: `assistantOverrides` with Dr. Smith's clinic context.
