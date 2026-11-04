# KHETCHACHA — PHYSICAL DEVICE CHAT TIMEOUT & DUPLICATE MESSAGE ROOT CAUSE & RESOLUTION REPORT

**Project:** KhetChaCha Agriculture Intelligence Mobile & AI Engine  
**Date:** November 4, 2026  
**Auditor:** Senior Mobile Architect & AI Backend Performance Lead  
**Physical Device Host:** `http://10.180.217.194:8000`  
**Test Status:** Flutter Tests: 217/217 Passed | Python Pytest: 49/49 Passed | Flutter Analyze: 0 Issues  

---

## 1. Executive Summary

During testing of the KhetChaCha mobile app on a physical Android smartphone connected to the local development network:
- The device browser could access `http://10.180.217.194:8000/health`.
- However, the Flutter AI Chat screen persistently failed with a server timeout.
- The same farmer question appeared three times in duplicate bubbles in the chat screen.
- The Uvicorn server console showed zero incoming `POST /api/v1/chat` requests.

An end-to-end investigation identified **four compounding root causes** across Flutter network routing, Android OS security policy, UI state debouncing, and Python backend Gemini fallback mechanics. All four root causes have been systematically resolved and verified with automated test suites.

---

## 2. Root Cause Analysis

### Root Cause 1 — Flutter Base URL defaulted to Android Emulator Loopback (`10.0.2.2`)
* **Location:** `lib/services/ai_chat_api_service.dart`
* **Defect:** 
  ```dart
  if (kReleaseMode) {
    return defaultProductionBaseUrl; // 'https://api.khetchacha.com'
  } else if (Platform.isAndroid) {
    return defaultEmulatorBaseUrl;   // 'http://10.0.2.2:8000'
  }
  ```
  * In release APK builds (`flutter build apk --release`), the app defaulted to `https://api.khetchacha.com`, which had no server deployed.
  * In debug builds on Android, `Platform.isAndroid` defaulted to `http://10.0.2.2:8000` (the Android Studio Emulator loopback alias). On a physical Android smartphone, `10.0.2.2` is a dead route.
  * Requests from the app never reached the computer's local IP (`10.180.217.194`), explaining why Uvicorn saw zero incoming `POST /api/v1/chat` requests while the phone's Chrome browser succeeded when typing the IP manually.

### Root Cause 2 — Android OS Cleartext HTTP Security Blocking
* **Location:** `android/app/src/main/AndroidManifest.xml`
* **Defect:** Starting in Android 9 (API 28), cleartext unencrypted HTTP traffic (such as `http://10.180.217.194:8000`) is disabled by default for application network sockets.
* **Symptom:** Without `android:usesCleartextTraffic="true"`, mobile Chrome (which has its own network stack) can load HTTP URLs, but the Flutter application process is rejected by the Android OS network security policy.

### Root Cause 3 — Duplicate Question Bubbles on Retry & Lack of In-Flight Button Lock
* **Location:** `lib/screens/quick_access/ask_khet_chacha_ai_page.dart`
* **Defect:**
  1. The Retry button handler removed the error bubble and called `_sendMessage(customText: retryQuestion)`.
  2. Inside `_sendMessage`, the user question was unconditionally added to `_messages`:
     ```dart
     _messages.add(_ChatMessageItem(id: userMsgId, sender: 'user', text: text));
     ```
  3. Because the user's original question was never removed, each retry created another duplicate user question bubble. If a farmer retried twice after timeout, three identical user questions appeared in a row.
  4. The Send button `IconButton` and `TextField.onSubmitted` remained active during in-flight network requests, allowing rapid taps to send redundant requests.

### Root Cause 4 — Gemini Model Quota Bottleneck & 90-Second Retry Hang on Backend
* **Location:** `ai_engine/gemini/gemini_client.py` and `ai_engine/backend/config.py`
* **Defect:**
  1. `GeminiClient` attempted candidate models: `gemini-3.8-flash` and `gemini-flash-latest`, which had exceeded free-tier daily quotas (`429 Quota Exceeded`).
  2. With `max_retries = 3` and `timeout = 30s`, if `gemini-flash-lite-latest` had a temporary cold-start latency, the backend retried the quota-limited models across 3 cycles, locking the worker thread for up to 90 seconds.
  3. `EmbeddingGenerator` was configured with `models/text-embedding-004` (which returned `404 Not Found` on this API key tier), causing every embedding search to delay on a 404 network roundtrip before falling back.

---

## 3. Technical Fixes Implemented

### Fix 1: Configurable Physical Device URL & Production Development Defaults
* **File:** `lib/services/ai_chat_api_service.dart`
* Added `defaultPhysicalDevBaseUrl = 'http://10.180.217.194:8000'`.
* Added `isPhysicalAndroidDevice = true` with `setPhysicalAndroidDevice(bool)`.
* Support compile-time environment override `--dart-define=AI_API_BASE_URL=...` and persistent `SharedPreferences`.
* Increased client `responseTimeout` from 25s to 45s (based on direct empirical backend latency measurements).
* Added non-sensitive diagnostic request tracing (logging Request ID, timestamp, URL, query metadata, HTTP status, and duration in ms; zero PII or credentials logged).

### Fix 2: Enabled Android Cleartext Traffic
* **File:** `android/app/src/main/AndroidManifest.xml`
* Added `android:usesCleartextTraffic="true"` to `<application>`.

### Fix 3: Eliminated Duplicate Message Bubbles & Added Send Button Lock
* **File:** `lib/screens/quick_access/ask_khet_chacha_ai_page.dart`
* Added `bool isRetry = false` parameter to `_sendMessage`.
* On retry, the original user question bubble is preserved and no duplicate user bubble is created.
* Disabled Send button (`onPressed: _isSending ? null : () => _sendMessage()`) and styled with disabled state (`#B0BEC5`).
* Disabled `TextField` (`enabled: !_isSending`) during in-flight queries.

### Fix 4: AI Engine Embedding Model & Fast Fallback Chain
* **Files:** `ai_engine/backend/config.py`, `ai_engine/.env`, `ai_engine/gemini/gemini_client.py`, `ai_engine/knowledge_base/embeddings.py`
* Updated default embedding model to `gemini-embedding-001` (3072 dimensions, zero 404 errors, 0.36s retrieval).
* Optimized `GeminiClient` candidate models to active quota-verified models: `['gemini-flash-lite-latest', 'gemini-3.5-flash-lite']`.
* Adjusted `max_retries = 2` and per-request timeout to 22s so that offline agronomic fallback responds promptly if Gemini is unavailable.

---

## 4. Empirical Direct Backend Latency Benchmark

Direct benchmark executed over physical network IP `http://10.180.217.194:8000`:

| Pipeline Step | Measured Time | Output / Status |
| :--- | :--- | :--- |
| **GET /health (Physical IP)** | **19.6 ms** | HTTP 200 `{"status": "healthy", "gemini_available": true}` |
| **Structured Knowledge Search** | **< 10 ms** | 4 authoritative disease/pest profiles matched |
| **Local PDF Vector Search** | **360 ms** | 1 verified ICAR advisory chunk matched |
| **Search Orchestrator Evidence Retrieval** | **360 ms** | 5 high-confidence grounding sources |
| **Gemini Inference (gemini-flash-lite-latest)** | **13.5 s – 18.8 s** | Full Gujarati advisory with action steps & precautions |
| **Safety Engine Verification & Alerts** | **< 20 ms** | Verified zero banned chemicals; injected PPE reminders |
| **Total Live POST /api/v1/chat Latency** | **21.79 s** | **HTTP 200 OK** |

Flutter's updated `45-second` response timeout easily accommodates the 21.79s processing time with >20s safety margin.

---

## 5. Verification Results

### A. Python Backend Test Suite
```bash
python -m pytest ai_engine/tests/
```
* **Result:** **49 passed out of 49 tests (100%)**
  * `test_agricultural_safety_audit.py`: 11/11 passed
  * `test_api.py`: 7/7 passed
  * `test_crop_knowledge.py`: 7/7 passed
  * `test_languages.py`: 6/6 passed
  * `test_local_search.py`: 4/4 passed
  * `test_online_search.py`: 5/5 passed
  * `test_pdf_processing.py`: 4/4 passed
  * `test_safety.py`: 5/5 passed

### B. Flutter Mobile Test Suite
```bash
flutter test
```
* **Result:** **217 passed out of 217 tests (100%)**
  * `test/ai_chat_api_service_test.dart`: 15/15 passed (including physical base URL and retry non-duplication widget tests)
  * `test/ai_chat_multilingual_tts_test.dart`: 26/26 passed
  * Full application test suite: 217/217 passed

### C. Static Analysis
```bash
flutter analyze lib/screens/quick_access/ask_khet_chacha_ai_page.dart lib/services/ai_chat_api_service.dart
```
* **Result:** **0 issues found**

---

## 6. How to Run & Verify on Physical Android Device

1. **Keep the Backend Server Running:**
   ```powershell
   python -m uvicorn ai_engine.backend.main:app --host 0.0.0.0 --port 8000
   ```
   Confirm from your phone browser: `http://10.180.217.194:8000/health` returns `{"status":"healthy"}`.

2. **Run or Build the Flutter Application:**
   * For direct debug run:
     ```powershell
     flutter run -d <your-device-id>
     ```
   * Or build a release APK:
     ```powershell
     flutter build apk --release
     ```
     The APK is generated at `build/app/outputs/flutter-apk/app-release.apk`.

3. **Verify AI Chat in-app:**
   * Open "ખેતચાચા AI પૂછો" (Ask KhetChacha AI).
   * Type any farming query (e.g., "કપાસના પાન પીળા કેમ થાય છે?").
   * Observe:
     - The Send button displays a spinner and disables while waiting.
     - Within ~20s, the AI response appears directly below the question in the same scrollable screen.
     - Exactly one question bubble is present.
     - The Listen (સાંભળો) button synthesizes speech.
     - In case of simulated network disconnect, Retry preserves the single question bubble without duplicating.

