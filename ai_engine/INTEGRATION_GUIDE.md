# 📱 KhetChacha Flutter App Integration Guide

> **Architectural Blueprint for Connecting KhetChacha Flutter APK to Python AI Engine**  
> *Note: Prepared strictly under Phase 13 guidelines. Existing Flutter codebase remains 100% untouched.*

---

## 🎯 Integration Goals

The KhetChacha Flutter application will send:
1. Farmer Question (in voice-to-text or typed in Gujarati, Hindi, Punjabi, etc.)
2. Selected or Detected Language code (`gu`, `hi`, `pa`, `ta`, etc.)
3. Real-time GPS Location (Village, Taluka, District, State, Lat/Long)
4. Current Farm Weather (Temperature, Humidity, Rain forecast)
5. Active Crop, Soil Type, and Land Holding Details

And will receive from `POST /api/v1/chat`:
- `short_answer`: Farmer-friendly direct response (40-100 words) with numbered steps
- `detailed_explanation`: Expandable in-depth agronomic advice
- `action_steps`: Discrete actionable checklist
- `safety_precautions`: Mandatory PPE & spray warnings
- `sources`: Authoritative cited sources (ICAR / KVK document or URL)
- `requires_photo`: Boolean flag indicating if farmer should upload a photo of the affected plant

---

## 📡 Endpoint Specification

### `POST /api/v1/chat`

#### Request Payload (JSON)
```json
{
  "question": "મારા કપાસના પાનમાં પીળાશ દેખાય છે, શું કરવું?",
  "language": "gu",
  "conversation_id": "session_12345",
  "current_crop": "Cotton",
  "crop_age_days": 45,
  "soil_type": "Black Cotton Soil",
  "land_size": "4 Bigha",
  "farmer_state": "Gujarat",
  "farmer_district": "Rajkot",
  "location": {
    "village": "Gondal",
    "taluka": "Gondal",
    "district": "Rajkot",
    "state": "Gujarat",
    "latitude": 21.9619,
    "longitude": 70.7923
  },
  "weather": {
    "temperature_celsius": 32.5,
    "humidity_percent": 68.0,
    "condition": "Partly Cloudy",
    "rain_forecast": "No rain expected for 48 hours"
  }
}
```

#### Response Payload (JSON)
```json
{
  "success": true,
  "language": "gu",
  "language_name": "Gujarati",
  "answer": "નમસ્તે ખેડૂત મિત્ર! તમારા કપાસ પાકમાં પીળાશ માટે તાત્કાલિક પગલાં:\n1. મેગ્નેશિયમ સલ્ફેટ (150 ગ્રામ / 15 લીટર પંપ) નો છંટકાવ કરવો.\n2. જમીનમાં વધારે પાણી ન ભરાય તેનું ધ્યાન રાખો.\n3. ચૂસિયા જીવાત જણાય તો લીમડાનું તેલ (1500 PPM) 45 મિલી છાંટવું.",
  "short_answer": "નમસ્તે ખેડૂત મિત્ર! તમારા કપાસ પાકમાં પીળાશ માટે તાત્કાલિક પગલાં:\n1. મેગ્નેશિયમ સલ્ફેટ (150 ગ્રામ / 15 લીટર પંપ) નો છંટકાવ કરવો.\n2. જમીનમાં વધારે પાણી ન ભરાય તેનું ધ્યાન રાખો.\n3. ચૂસિયા જીવાત જણાય તો લીમડાનું તેલ (1500 PPM) 45 મિલી છાંટવું.",
  "detailed_explanation": "કપાસના પાકમાં પાંદડા પીળા પડવાનું મુખ્ય કારણ મેગ્નેશિયમ અથવા નાઈટ્રોજન પોષકતત્વોની ઉણપ હોઈ શકે છે. આ સ્થિતિને સામાન્ય રીતે 'લાલિયો' અથવા હરિતદ્રવ્યની ખામી કહેવામાં આવે છે. 15 દિવસના અંતરે 2 છંટકાવ કરવાથી પાંદડામાં હરિતદ્રવ્ય પાછું આવે છે.",
  "confidence_score": 0.92,
  "source_type": "local_pdf",
  "sources": [
    {
      "title": "ICAR - Central Institute for Cotton Research (CICR) Bulletin",
      "document_name": "ICAR_CICR_Cotton_Crop_Advisory.pdf",
      "page_number": 1,
      "snippet": "Leaf yellowing (chlorosis) in cotton is primarily caused by micronutrient deficiency, specifically Magnesium deficiency...",
      "confidence_score": 0.88,
      "source_type": "local_pdf"
    }
  ],
  "action_steps": [
    "મેગ્નેશિયમ સલ્ફેટનો છંટકાવ સવારે 10 વાગ્યા પહેલા કરવો.",
    "જમીનમાં ભેજનું યોગ્ય નિયમન જાળવવું.",
    "પાંદડા નીચે ચૂસિયા જીવાતની તપાસ કરવી."
  ],
  "safety_precautions": [
    "છંટકાવ કરતી વખતે મોઢા પર માસ્ક અને હાથમાં રબરના મોજા અવશ્ય પહેરો.",
    "પવનની દિશામાં જ છંટકાવ કરવો. બાળકો અને પશુઓને દૂર રાખવા."
  ],
  "crop_detected": "Cotton",
  "symptoms_identified": ["leaf_yellowing"],
  "search_strategy_used": "local_only",
  "requires_photo": false
}
```

---

## 🛠 Recommended Flutter Integration Steps (For Next Phase)

When ready to connect the Flutter frontend:

1. **Add Base URL to Config**:
   In `lib/core/constants/api_constants.dart` or `.env`:
   ```dart
   // For Android Emulator:
   static const String aiEngineBaseUrl = "http://10.0.2.2:8000";
   // For Physical Android Device on same Wi-Fi:
   // static const String aiEngineBaseUrl = "http://<YOUR_PC_LOCAL_IP>:8000";
   ```

2. **Create Dart Service `ai_engine_service.dart`**:
   Connects Flutter's `AskKhetChachaAIPage` directly via `http.post(Uri.parse('$aiEngineBaseUrl/api/v1/chat'))`.

3. **Bind Real Sensors**:
   - `LocationService.getCurrentPosition()` -> populates `location` object.
   - `WeatherService.getWeatherForLocation()` -> populates `weather` object.
   - `LanguageService.currentLanguageCode` -> sets `language` field.

