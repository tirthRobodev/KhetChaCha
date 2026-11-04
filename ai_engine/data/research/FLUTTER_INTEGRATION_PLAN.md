# 📱 KhetChacha — Flutter + Python AI Engine Integration Plan

**Inspection Date:** `2026-11-04T21:15:00+05:30`  
**Architects:** `Senior Flutter Architect & Python FastAPI Integration Lead`  
**Workspace:** `D:\KhetChaCha`  
**Current Baseline Commit:** `ee735a3`  
**Flutter Version:** `1.0.0+1`  
**Pytest Status:** `49/49 PASSED (100%)`  
**Flutter Test Status:** `176/176 PASSED (100%)`

---

## 1. System Architecture & Inventory

### A. Python FastAPI Backend Engine
- **Entry Point:** `ai_engine/backend/main.py`
- **Configuration:** `ai_engine/backend/config.py` (Defaults: host `0.0.0.0`, port `8000`)
- **Active Gemini Model:** `gemini-flash-lite-latest`
- **Active Route Definitions:**
  1. `GET /health` — Real-time health, model availability, vector statistics.
  2. `POST /api/v1/chat` — Primary multilingual agricultural advisor endpoint.
  3. `POST /api/v1/search` — Online agricultural portal search (ICAR, KVK).
  4. `POST /api/v1/knowledge/search` — Hybrid vector + BM25 keyword search over local PDF advisories.
  5. `POST /api/v1/knowledge/upload` — Ingestion & chunking of agricultural PDF guides.
  6. `GET /api/v1/knowledge/status` — Catalog statistics of indexed agricultural documents.
- **Backend Capabilities Gap (Audited):**
  - **Vision/Image Diagnosis Endpoint:** Does NOT exist on backend (PDF upload only).
  - **Audio Transcription Endpoint:** Does NOT exist on backend.
  - *Architectural Directive:* Do NOT invent fake endpoints for vision or voice. Connect the text intelligence `/api/v1/chat` endpoint; preserve existing client-side camera/mic UI shortcuts.

### B. Flutter Mobile Application (`D:\KhetChaCha`)
- **Package Manager / Dependencies (`pubspec.yaml`):**
  - Networking: `http: ^1.2.2` (standard, stable HTTP client)
  - Location: `geolocator: ^14.1.2`
  - Permissions: `permission_handler: ^11.3.1`
  - Storage: `shared_preferences: ^2.3.2`
  - Text-to-Speech: `flutter_tts: ^4.2.5`
- **Android Permissions (`AndroidManifest.xml`):**
  - `android.permission.INTERNET` (Present)
  - `android.permission.ACCESS_NETWORK_STATE` (Present)
  - `android.permission.ACCESS_FINE_LOCATION` & `ACCESS_COARSE_LOCATION` (Present)
  - `android.permission.CAMERA` (Present)
  - `android.permission.RECORD_AUDIO` (Present)
- **Primary AI Screens & Services:**
  - Screen: `lib/screens/quick_access/ask_khet_chacha_ai_page.dart` (Main chatbot UI)
  - Screen: `lib/screens/ai/image_ai_diagnosis_page.dart` (Image scanner UI)
  - Screen: `lib/screens/ai/voice_assistant_page.dart` (Voice assistant UI)
  - Service: `lib/services/location_service.dart` (GPS, reverse geocoding, mock mode)
  - Service: `lib/services/weather_service.dart` (Open-Meteo live weather)
  - Service: `lib/services/language_service.dart` (22 scheduled Indian languages)
  - Service: `lib/services/permission_service.dart` (Android 14+ guarded runtime requests)

---

## 2. Pydantic Request & Response Schema Specifications

### `POST /api/v1/chat`
#### Request Payload (`FarmerChatRequest`):
```json
{
  "question": "string (Farmer's agricultural query in any of 22 languages)",
  "language": "string (ISO 639-1 code: 'gu', 'hi', 'pa', 'en', 'auto')",
  "current_crop": "string (Optional active crop name, e.g. 'Cotton', 'Wheat')",
  "crop_age_days": 45,
  "soil_type": "string (e.g. 'Black Cotton Soil')",
  "land_size": 4.0,
  "land_unit": "Bigha",
  "location": {
    "village": "string",
    "taluka": "string",
    "district": "string",
    "state": "string",
    "latitude": 23.0225,
    "longitude": 72.5714
  },
  "weather": {
    "temperature_celsius": 32.5,
    "humidity_percent": 68.0,
    "condition": "string",
    "rain_forecast": "string"
  },
  "conversation_id": "string (Session ID for conversational continuity)"
}
```

#### Response Payload (`FarmerChatResponse`):
```json
{
  "success": true,
  "language": "gu",
  "language_name": "Gujarati",
  "answer": "string (40-100 words farmer-friendly answer)",
  "detailed_explanation": "string (150-300 words agronomic explanation)",
  "action_steps": ["string (Numbered practical field steps)"],
  "safety_precautions": ["string (Mandatory PPE and safety guidance)"],
  "crop_detected": "Cotton",
  "symptoms_identified": ["leaf yellowing"],
  "confidence_score": 0.95,
  "sources": [
    {
      "title": "string",
      "document_name": "string",
      "page_number": 1,
      "page_or_section": "string",
      "source_type": "local_pdf",
      "snippet": "string",
      "confidence_score": 0.98
    }
  ],
  "search_strategy_used": "string ('local_only', 'differential_diagnosis', etc.)",
  "requires_photo": false
}
```

---

## 3. Flutter API Client Architecture (PHASE 2)

We will implement a clean, decoupled service:
`lib/services/ai_chat_api_service.dart`

### Key Design Pillars:
1. **Configurable Base URL:**
   - Development (Android Emulator): `http://10.0.2.2:8000`
   - Development (Physical Device / LAN): `http://<LAN_IP>:8000`
   - Production: `https://api.khetchacha.com`
   - Configurable via `SharedPreferences` or runtime property.
2. **Resilience & Timeouts:**
   - Connection timeout: 10 seconds.
   - Read timeout: 25 seconds.
3. **No Hardcoded Secrets:**
   - Zero Gemini or backend secret keys inside Flutter code.
4. **Structured Error Handling:**
   - Handles `SocketException` / offline gracefully.
   - Handles `TimeoutException` without crashing.
   - Handles HTTP 422, 429, and 500 with user-friendly, localized agricultural guidance.
   - **Rule:** Never silently fabricate pesticide dosages on network failure.

---

## 4. UI & Chat Integration Blueprint (PHASE 3)

In `lib/screens/quick_access/ask_khet_chacha_ai_page.dart`:
- Replace the mock `_getAiResponse` with `AiChatApiService.instance.sendMessage(...)`.
- Automatically package context:
  - Active language from `LanguageService.instance.currentLanguage.code`.
  - Active crop from `widget.profile.effectiveProducts` or `widget.profile.crops`.
  - District, village, and state from `widget.profile`.
  - GPS coordinates from `LocationService.instance.lastKnownLocation` **only if location permission is granted**.
  - Weather context from `WeatherService.instance` if valid cached/live weather exists.
- In the chat bubble UI:
  - Display the short answer cleanly.
  - If `detailed_explanation` is present, provide an expandable "વિગતવાર માહિતી (Detailed Info)" panel.
  - Display `action_steps` with numbered bullet points.
  - Display `safety_precautions` in a designated safety card (warning icon + orange/green styling).
  - If `requires_photo` is true, display a prominent button: "📸 પાકનો સ્પષ્ટ ફોટો મોકલો (Upload Photo)" opening the Image AI scanner.
  - If `sources` are present, show a subtle "સ્ત્રોત: ICAR / કૃષિ વિજ્ઞાન કેન્દ્ર" citation badge.

---

## 5. Security & Permission Guardrails (PHASE 5 & 6)

1. **Permission Guard:** Location coordinates (`latitude`, `longitude`) are sent **only if** `PermissionService.instance.checkStatus(KhetPermissionType.location) == KhetPermissionState.granted`.
2. **Offline Safety:** If the network is down or backend is offline, inform the farmer honestly:
   - *"સર્વર સાથે સંપર્ક થઈ શક્યો નથી. કૃપા કરીને ઇન્ટરનેટ કનેક્શન તપાસો અથવા કિસાન કોલ સેન્ટર (1800-180-1551) નો સંપર્ક કરો."*
   - Never inject invented chemical doses on failure.
3. **Zero Secrets in Mobile:** The mobile APK communicates with the Python backend without embedding Google Gemini API keys.

---

## 6. Testing Strategy (PHASE 7)

Add comprehensive Flutter unit and widget tests in `test/ai_chat_api_service_test.dart`:
- Successful Gujarati response parsing.
- English response parsing.
- Handling HTTP 429 (rate limit).
- Handling HTTP 422 (validation error).
- Handling HTTP 500 (server error).
- Handling SocketException (network down).
- Handling TimeoutException.
- Verifying `requires_photo: true` flag.
- Verifying location coordinates omitted when permission is denied.
- Zero regressions across existing 176 Flutter tests.
- Zero regressions across 49 Python tests.

