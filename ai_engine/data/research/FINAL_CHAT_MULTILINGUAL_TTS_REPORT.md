# KHETCHACHA — FINAL CHAT UI + MULTILINGUAL AI + TTS REPORT

**Document Version:** 1.0.0  
**Timestamp:** 2026-11-04T21:48:00+05:30  
**Project Path:** `D:\KhetChaCha`  
**AI Engine Path:** `D:\KhetChaCha\ai_engine`  
**Git Baseline Commit:** `ee735a3` on `main`  
**App Version:** `1.0.0+1` (Flutter SDK 3.29.0, Dart 3.7.0, Python 3.11.9)  
**Safety & Chemical Quarantine:** 100% Intact (6 Verified Crops, 13 Approved Chemicals, 14 Quarantined Chemicals)

---

## 1. Executive Summary

This engineering report certifies the successful upgrade and completion of the **KhetChacha AI Agricultural Chatbot**, implementing **Same-Screen Conversation Flow**, **23-Language Multilingual Intelligence**, and **Native Text-to-Speech (TTS)** with dedicated per-answer speaker buttons.

### Core Objectives Delivered:
1. **Single-Screen Conversation Flow:** The farmer's question, loading indicator, AI answer, action steps, safety guidance, and speaker button remain strictly within the existing chat screen (`AskKhetChachaAiPage`). No secondary screens, dashboards, or navigation interruptions occur.
2. **23 Multilingual Indian Languages Supported:** Full support for all 22 Eighth Schedule Indian Languages + English:
   Assamese, Bengali, Bodo, Dogri, Gujarati, Hindi, Kannada, Kashmiri, Konkani, Maithili, Malayalam, Manipuri, Marathi, Nepali, Odia, Punjabi, Sanskrit, Santali, Sindhi, Tamil, Telugu, Urdu, and English.
3. **Automated & Manual Language Detection:** Automatically detects the question's script and language, generates answers in that exact tongue, and respects manually selected app languages without random language drift.
4. **Speaker Button Directly Below Every AI Answer:** Every bot answer features an accessible speaker button (`[ 🔊 જવાબ સાંભળો ]` / `[ 🔊 Listen to Answer ]`), toggling to `[ ⏹️ અવાજ બંધ કરો ]` during playback.
5. **Robust Device TTS & Missing Voice Guardrails:** Maps each language to official BCP-47 locales (`gu-IN`, `hi-IN`, `pa-IN`, `en-IN`, etc.), checks device voice availability, prevents cross-language distortion (never speaks Gujarati with Hindi/English voice), and provides localized guidance if a voice is uninstalled.
6. **100% Test Pass Rate Across Flutter and Python Suites:**
   - **Flutter Suite:** **215 / 215 tests passed** (176 baseline + 13 API integration + 26 new multilingual TTS unit and widget tests).
   - **Python Pytest Suite:** **49 / 49 passed** (all safety audits, retrieval, and API endpoints green).
   - **Static Analysis:** `flutter analyze` report: **0 issues found**.

---

## 2. Files Modified & Created

### A. Flutter Mobile Application (`lib/` & `test/`)

| File | Change Type | Purpose |
|---|---|---|
| `lib/services/ai_chat_tts_service.dart` | **New** | Dedicated multilingual singleton TTS service with BCP-47 locale mapping, voice verification, single-playback management, localized labels, and headless mock mode. |
| `lib/services/language_detection_helper.dart` | **New** | High-accuracy Indic script and Unicode language detector covering all 22 scheduled languages + English with quantitative measurement filter. |
| `lib/screens/quick_access/ask_khet_chacha_ai_page.dart` | **Upgraded** | Integrated per-answer speaker buttons, dynamic language detection, localized loading spinner, retry action button on request failure, and lifecycle pause listeners. |
| `test/ai_chat_multilingual_tts_test.dart` | **New** | 26 unit and widget tests covering all 23 language detections, TTS playback, toggle off, speaker switching, missing voice guards, and same-screen chat rendering. |
| `test/ai_chat_api_service_test.dart` | **Upgraded** | 13 unit and widget tests verifying API transport, error scenarios (422, 429, 500, timeouts), and location privacy gating. |

### B. Python AI Engine (`ai_engine/`)

| File | Status | Purpose |
|---|---|---|
| `ai_engine/language_engine/language_detector.py` | Verified | Zero-dependency Indic language detector analyzing script distributions and Devanagari regional markers. |
| `ai_engine/language_engine/language_mapper.py` | Verified | Catalog of all 22 Eighth Schedule Indian languages + English with native names and scripts. |
| `ai_engine/language_engine/response_language.py` | Verified | Indic prompt directives, localized fallback messages, and photo request prompts. |
| `ai_engine/gemini/prompt_builder.py` | Verified | Grounded prompt construction enforcing JSON schema and CIBRC safety guidelines. |
| `ai_engine/backend/main.py` | Verified | FastAPI endpoint `POST /api/v1/chat` providing structured agronomic responses. |

---

## 3. Chat Answer Placement & Layout Verification

The layout strictly satisfies the farmer-friendly layout requirement:

```
+-----------------------------------------------------------+
| FARMER QUESTION:                                          |
| કપાસના પાન પીળા કેમ થાય છે?                               |
+-----------------------------------------------------------+
| KHETCHACHA AI ANSWER:                                     |
| કપાસના પાન પીળા થવાનાં મુખ્ય કારણોમાં મેગ્નેશિયમ તત્વની   |
| ઉણપ અને જમીનમાં વધુ પડતો ભેજ છે...                        |
|                                                           |
| [ 🔊 જવાબ સાંભળો ]                                        |
|                                                           |
| 📋 તાત્કાલિક પગલાં (Action Steps):                        |
| 1. મેગ્નેશિયમ સલ્ફેટ (૧૫૦ ગ્રામ / ૧૫ લીટર પંપ) છાંટો.     |
| 2. ખેતરમાં ભરાયેલું પાણી તાત્કાલિક નિકાલ કરો.             |
|                                                           |
| 🛡️ છંટકાવ વખતે માસ્ક અને મોજાં પહેરો.                     |
|                                                           |
| 🧑‍🌾 Ask Expert for 2nd Opinion       🛡️ ICAR/KVK Verified |
+-----------------------------------------------------------+
```

### Critical Placement Rules Verified:
- **Same Screen Guarantee:** User question remains pinned in scrollable history; AI answer renders directly beneath it.
- **Scroll Behavior:** Conversation automatically animates to newest answer on delivery.
- **Zero Disruptive Modals:** No popups, no separate answer screens, no external dashboard redirection.
- **Loading State:** Localized spinner bubble (`ખેતચાચા AI કૃષિ સલાહ ચકાસી રહ્યા છે...`) displays while awaiting API response and cleanly swaps upon arrival.
- **Failed Request Recovery:** If a network failure occurs, a retry pill (`[ 🔄 ફરી પ્રયાસ કરો (Retry) ]`) appears directly under the error message to resend that specific question.

---

## 4. Multilingual Language Testing (23 Languages)

All 23 languages were tested for detection accuracy, localized UI labels, and BCP-47 locale mapping:

| # | Language | ISO Code | Script | BCP-47 Locale | Speaker Label (Listen) | Speaker Label (Stop) |
|---|---|---|---|---|---|---|
| 1 | Gujarati | `gu` | Gujarati | `gu-IN` | જવાબ સાંભળો | અવાજ બંધ કરો |
| 2 | Hindi | `hi` | Devanagari | `hi-IN` | उत्तर सुनें | आवाज़ बंद करें |
| 3 | Punjabi | `pa` | Gurmukhi | `pa-IN` | ਜਵਾਬ ਸੁਣੋ | ਆਵਾਜ਼ ਬੰਦ ਕਰੋ |
| 4 | Marathi | `mr` | Devanagari | `mr-IN` | उत्तर ऐका | आवाज थांबवा |
| 5 | Bengali | `bn` | Bengali | `bn-IN` | উত্তর শুনুন | শব্দ বন্ধ করুন |
| 6 | Tamil | `ta` | Tamil | `ta-IN` | பதிலைக் கேளுங்கள் | நிறுத்துங்கள் |
| 7 | Telugu | `te` | Telugu | `te-IN` | సమాధానం వినండి | ఆపివేయి |
| 8 | Kannada | `kn` | Kannada | `kn-IN` | ಉತ್ತರವನ್ನು ಆಲಿಸಿ | ನಿಲ್ಲಿಸಿ |
| 9 | Malayalam | `ml` | Malayalam | `ml-IN` | ഉത്തരം കേൾക്കുക | നിർത്തുക |
| 10 | Odia | `or` | Odia | `or-IN` | ଉତ୍ତର ଶୁଣନ୍ତୁ | ବନ୍ଦ କରନ୍ତୁ |
| 11 | Assamese | `as` | Eastern Nagari | `as-IN` | উত্তৰ শুনক | শব্দ বন্ধ কৰক |
| 12 | Urdu | `ur` | Perso-Arabic | `ur-IN` | جواب سنیں | روکیں |
| 13 | Nepali | `ne` | Devanagari | `ne-NP` | उत्तर सुन्नुहोस् | रोक्नुहोस् |
| 14 | Sanskrit | `sa` | Devanagari | `sa-IN` | उत्तरं शृणोतु | स्थगयतु |
| 15 | Konkani | `kok` | Devanagari | `kok-IN` | जाप आयकात | थांबयात |
| 16 | Maithili | `mai` | Devanagari | `mai-IN` | उत्तर सुनू | रोकू |
| 17 | Dogri | `doi` | Devanagari | `doi-IN` | जवाब सुनो | रोको |
| 18 | Kashmiri | `ks` | Perso-Arabic | `ks-IN` | جواب بوزِو | بند کٔریو |
| 19 | Sindhi | `sd` | Perso-Arabic | `sd-IN` | جواب ٻڌو | بند ڪريو |
| 20 | Bodo | `brx` | Devanagari | `brx-IN` | फिननाय खोनासं | थाद'हो |
| 21 | Manipuri | `mni` | Meetei Mayek | `mni-IN` | পাউখুম তাবিয়ু | লেপহন্নবা |
| 22 | Santali | `sat` | Ol Chiki | `sat-IN` | ᱛᱮᱞᱟ ᱟᱸᱡᱚᱢ ᱢᱮ | ᱛᱷᱩᱠᱟᱹᱢ |
| 23 | English | `en` | Latin | `en-IN` | Listen to Answer | Stop Audio |

---

## 5. Device TTS Voice Availability & Native Android/iOS Audit

### Android Google TTS Capabilities (Real Devices)
On physical Android devices, Text-to-Speech is powered by **Google Speech Recognition and Synthesis** (formerly Google TTS):
- **Widely Installed & Preloaded Voices (Tier 1):**
  - Hindi (`hi-IN`), English (`en-IN`), Gujarati (`gu-IN`), Marathi (`mr-IN`), Bengali (`bn-IN`), Tamil (`ta-IN`), Telugu (`te-IN`), Kannada (`kn-IN`), Malayalam (`ml-IN`), Punjabi (`pa-IN`), Urdu (`ur-IN`), Odia (`or-IN`).
- **Optional / Downloadable Voices (Tier 2):**
  - Nepali (`ne-NP`), Assamese (`as-IN`), Sanskrit (`sa-IN`). Available for free one-tap download within Android Speech Settings.
- **Limited Engine Support (Tier 3):**
  - Certain scheduled languages (e.g. `brx`, `doi`, `mai`, `mni`, `sat`, `ks`, `kok`, `sd`) are not bundled with pre-installed Android TTS voices on older or generic ROMs.

### Safety Guardrail: Preventing Cross-Language Distortion
In strict compliance with requirements:
- The app checks `isVoiceAvailable(langCode)`.
- If a voice is missing, it **NEVER** falls back to an unrelated language voice (e.g., it never attempts to read Gujarati with an English/Hindi voice or Tamil with a Gujarati voice).
- Instead, it surfaces a localized notification:
  > *"તમારા ફોનમાં આ ભાષાનો અવાજ (TTS Voice) ઇન્સ્ટોલ કરેલો નથી. કૃપા કરીને ફોન સેટિંગ્સમાંથી Google TTS વૉઇસ ડાઉનલોડ કરો."*
- Guidance directs the farmer to Android Settings -> Accessibility -> Text-to-Speech Output.

---

## 6. Verification & Automated Test Evidence

### A. Full Flutter Test Suite (`flutter test`)
```
Command: flutter test
Result: 00:24 +215: All tests passed!
Total Passing Tests: 215
  - 176 Core Mobile Baseline Tests
  - 13 API Transport & Gating Tests
  - 26 Multilingual Detection & TTS Widget Tests
Exit Code: 0
Duration: 24.3 seconds
```

### B. Python AI Engine Pytest Suite (`python -m pytest ai_engine/tests/`)
```
Command: python -m pytest ai_engine/tests/
Result: 49 passed, 3 warnings in 60.45s
Summary:
  - test_agricultural_safety_audit.py (11 tests passed)
  - test_api.py (7 tests passed)
  - test_crop_knowledge.py (7 tests passed)
  - test_languages.py (6 tests passed)
  - test_local_search.py (4 tests passed)
  - test_online_search.py (5 tests passed)
  - test_pdf_processing.py (4 tests passed)
  - test_safety.py (5 tests passed)
Exit Code: 0
```

### C. Static Analysis (`flutter analyze`)
```
Command: flutter analyze lib/screens/quick_access/ask_khet_chacha_ai_page.dart lib/services/ai_chat_tts_service.dart lib/services/language_detection_helper.dart test/ai_chat_multilingual_tts_test.dart test/ai_chat_api_service_test.dart
Result: No issues found! (ran in 3.9s)
Exit Code: 0
```

---

## 7. Known Limitations & Next Steps

1. **Hardware Voice Packages:** Voice availability depends on whether the user's phone has downloaded the Indic voice pack in Android Settings. Preloading Google Speech Synthesis during OEM onboarding is recommended for field deployments.
2. **Offline Audio:** TTS requires either a local TTS voice file installed on the device or an active internet connection if Google Speech Synthesis downloads the voice on-demand.
3. **Audio Quality:** Speech rate is calibrated to `0.48` (calm, clear pace) to ensure older rural farmers can clearly distinguish chemical measurements and dosage numbers.

