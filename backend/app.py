import os
import re
from typing import Dict, Any, Optional
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

app = FastAPI(
    title="KhetChaCha Multilingual Agricultural AI Engine",
    version="1.0.0",
    description="High-performance AI backend powering KhetChaCha's voice and text farming assistants."
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Optional Gemini API Key from environment
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY", "")

# Initialize Gemini if key is provided
_gemini_model = None
if GEMINI_API_KEY:
    try:
        import google.generativeai as genai
        genai.configure(api_key=GEMINI_API_KEY)
        _gemini_model = genai.GenerativeModel("gemini-1.5-flash")
    except Exception as e:
        print(f"Notice: Gemini initialization deferred: {e}")


class ChatRequest(BaseModel):
    query: str
    language_code: str = "gu"
    grounding: Optional[Dict[str, Any]] = None


class SpeechIntentRequest(BaseModel):
    text: str
    language_code: str = "gu"


@app.get("/api/v1/health")
def health_check():
    return {
        "status": "healthy",
        "service": "KhetChaCha Agri AI Engine",
        "version": "1.0.0",
        "gemini_configured": bool(GEMINI_API_KEY)
    }


@app.post("/api/v1/speech-intent")
def analyze_speech_intent(request: SpeechIntentRequest):
    text_lower = request.text.lower()
    
    # 1. Detect Crop
    detected_crop = "Cotton"
    if any(k in text_lower for k in ["wheat", "ઘઉં", "गेहूं", "ਕਣਕ"]):
        detected_crop = "Wheat"
    elif any(k in text_lower for k in ["rice", "paddy", "ડાંગર", "ચોખા", "धान", "चावल"]):
        detected_crop = "Paddy (Rice)"
    elif any(k in text_lower for k in ["groundnut", "મગફળી", "मूंगफली"]):
        detected_crop = "Groundnut"
    elif any(k in text_lower for k in ["tomato", "ટામેટા", "टमाटर"]):
        detected_crop = "Tomato"
    elif any(k in text_lower for k in ["cumin", "જીરું", "जीरा"]):
        detected_crop = "Cumin"

    # 2. Detect Primary Intent
    intent = "pest_disease"
    if any(k in text_lower for k in ["ખાતર", "fertilizer", "urea", "खाद", "dap", "npk"]):
        intent = "fertilizer_management"
    elif any(k in text_lower for k in ["ભાવ", "price", "rate", "મંડી", "मंडी"]):
        intent = "mandi_pricing"
    elif any(k in text_lower for k in ["હવામાન", "વરસાદ", "weather", "rain", "मावठा"]):
        intent = "weather_advisory"

    # 3. Urgency
    is_urgent = any(k in text_lower for k in ["મરી જાય છે", "ખરી પડે છે", "સુકારો", "તીવ્ર", "इमरजेंसी", "urgent"])

    return {
        "detected_crop": detected_crop,
        "intent": intent,
        "is_urgent": is_urgent,
        "language_code": request.language_code
    }


@app.post("/api/v1/chat")
async def chat_endpoint(request: ChatRequest):
    query = request.query.strip()
    if not query:
        raise HTTPException(status_code=400, detail="Query cannot be empty")

    lang = request.language_code
    grounding = request.grounding or {}
    crop = grounding.get("detectedCrop", "Cotton")

    # 1. Try Gemini Generative AI if key is present
    if _gemini_model:
        try:
            system_instruction = f"""
You are KhetChaCha AI, the Senior Agricultural Advisor for Indian farmers.
Location: {grounding.get('district', 'Rajkot')}, {grounding.get('state', 'Gujarat')}.
Crop: {crop}. Farmer Name: {grounding.get('farmerName', 'Kisan Mitra')}.
Requested Language: {lang}.

CRITICAL INSTRUCTIONS:
Always structure your response in the 6-part agricultural framework:
PART 1: Understanding your problem
PART 2: Likely causes / Diagnosis
PART 3: Recommended actions (Biological / Organic & Chemical)
PART 4: Timing & step-by-step application
PART 5: Precautions & exact dosages (per 15-litre knapsack sprayer pump)
PART 6: Additional information needed from farmer

Do not truncate. Prescribe exact active ingredients and dosages per 15L pump.
Reply in the user's requested language ({lang}).
"""
            prompt = f"{system_instruction}\n\nFarmer Query: {query}"
            response = _gemini_model.generate_content(prompt)
            if response and response.text:
                full_text = response.text
                sections = _parse_sections(full_text)
                return {
                    "text": full_text,
                    "language_code": lang,
                    "sections": sections,
                    "source": "gemini"
                }
        except Exception as e:
            print(f"Notice: Gemini call failed, falling back to expert knowledge base: {e}")

    # 2. High-Quality Grounded Fallback Engine
    result = _build_grounded_response(query, lang, grounding, crop)
    return {
        "text": result["text"],
        "language_code": lang,
        "sections": result["sections"],
        "source": "grounded_knowledge_base"
    }


def _build_grounded_response(query: str, lang: str, grounding: Dict[str, Any], crop: str) -> Dict[str, Any]:
    lower = query.lower()
    is_fertilizer = any(k in lower for k in ["fertilizer", "ખાતર", "खाद", "urea", "dap", "npk"])
    is_price = any(k in lower for k in ["ભાવ", "price", "rate", "મંડી", "मंडी"])

    if lang == "gu":
        if is_price:
            p1 = f"{crop} ના હાલના APMC બજાર ભાવ અને શ્રેષ્ઠ વેચાણ મથકની માહિતી."
            p2 = "આવક અને ગુણવત્તાના આધારે વિવિધ મંડીઓમાં ભાવ તફાવત જોવા મળે છે."
            p3 = "• મોડેલ ભાવ: ₹૭,૧૦૦ થી ₹૭,૫૦૦ પ્રતિ ક્વિન્ટલ.\n• વેચાણ સલાહ: સુકવણી અને ગ્રેડિંગ કરીને વેચવાથી ક્વિન્ટલે ₹૨૦૦-૩૦૦ વધુ ભાવ મળી શકે છે."
            p4 = "૧. સવારે ૯ થી ૧૨ વાગ્યા વચ્ચે મંડીમાં હરાજી માટે પાક પહોંચાડવો.\n૨. ખેતચાચા એપમાં 'APMC ભાવ સરખામણી' થી નજીકની ૩ મંડીઓના દૈનિક ભાવ ચકાસો."
            p5 = "• સાવચેતી: માલ તુલાવ્યા પછી અધિકૃત વજન પાવતી અને વેપારીનું લાયસન્સ અચૂક ચકાસવું."
            p6 = "તમારી પાસે કેટલો જથ્થો તૈયાર છે? તમારો જિલ્લો અને તાલુકો જણાવો."
        elif is_fertilizer:
            p1 = f"{crop} પાક માટે સંતુલિત ખાતર વ્યવસ્થાપન અને પોષક તત્વોની જરૂરિયાત."
            p2 = "વધુ પડતો યુરિયા આપવાથી પાક વાનસ્પતિક વૃદ્ધિ કરે છે અને જીવાતોનો ઉપદ્રવ વધે છે; પોટાશ અને ફોસ્ફરસનો અભાવ દાણા નબળા પાડે છે."
            p3 = "• પાયાનો ડોઝ: ડીએપી અથવા એનપીકે (NPK 12:32:16) આપો.\n• પૂર્તિ ખાતર: વાવણીના ૩૦ અને ૬૦ દિવસે યુરિયાના નાના હપ્તા સાથે ૧૯:૧૯:૧૯ અથવા ૦૦:૫૨:૩૪ નો સ્પ્રે કરો."
            p4 = "૧. ફૂલ બેસવાની અવસ્થાએ બોરોન ૨૦% (૨૦ ગ્રામ/૧૫ લિટર) નો સ્પ્રે કરવો.\n૨. દાણા/ઝીંડવા ભરાવાના સમયે ૦૦:૦૦:૫૦ ૭૫ ગ્રામ/પંપ આપવું."
            p5 = "• પંપ દીઠ સ્પ્રે પ્રમાણ: ૧૯:૧૯:૧૯ વોટર સોલ્યુબલ ખાતર ૭૫ ગ્રામ પ્રતિ ૧૫ લિટર પંપ.\n• સાવચેતી: બપોરના તડકામાં રાસાયણિક ખાતરનો સ્પ્રે ન કરવો. જમીનમાં પૂરતો ભેજ હોવો જોઈએ."
            p6 = "તમારી જમીનનો પ્રકાર કેવો છે? છેલ્લે જમીન ચકાસણી ક્યારે કરાવી હતી?"
        else:
            p1 = f"તમારા {crop} પાકમાં પાંદડા પીળા પડવા, જીવાતનો ઉપદ્રવ અથવા ફૂલ ખરી પડવાની સમસ્યા ધ્યાને લીધી."
            p2 = f"{crop} પાકમાં મુખ્યત્વે ગુલાબી ઈયળ (Pink Bollworm), સફેદ માખી અથવા થ્રિપ્સ જવાબદાર હોઈ શકે છે."
            p3 = "• જૈવિક ઉપાય: એકરે ૮-૧૦ ફેરોમોન ટ્રેપ અથવા ૧૫ પીળા ચીકણા કાર્ડ લગાવો. લીંબોળીનું તેલ (૧૫૦૦ ppm) ૫૦ મિલી સ્પ્રે કરો.\n• રાસાયણિક ઉપાય: ઈયળ માટે ઇમામેક્ટીન બેન્ઝોએટ ૫% એસજી; સફેદ માખી માટે ડાયફેન્થિયુરોન ૫૦% ડબલ્યુપી વાપરો."
            p4 = "૧. પ્રથમ સ્પ્રે સાંજના સમયે (પવન શાંત હોય ત્યારે) કરો.\n૨. ઉપદ્રવ વધુ હોય તો ૧૦-૧૨ દિવસ પછી બીજી દવાનો સ્પ્રે કરો.\n૩. સ્પ્રે કરતા પહેલા જમીનમાં પૂરતો ભેજ હોવો જરૂરી છે."
            p5 = "• પંપ દીઠ પ્રમાણ: ૧૫ લિટર પાણીના પંપમાં ઇમામેક્ટીન બેન્ઝોએટ ૫ ગ્રામ અથવા ક્લોરાન્ટ્રાનિલીપ્રોલ ૬ મિલી નાખવું. વધુ ડોઝ ન નાખવો.\n• નિયમો: સ્પ્રે કરતી વખતે મોં પર માસ્ક અને હાથમોજાં પહેરો."
            p6 = "પાકની ચોક્કસ ઉંમર કેટલી છે? શું પાંદડા નીચે સફેદ જીવાત દેખાય છે? પાંદડાનો ફોટો એપમાં 'AI રોગ સ્કેનર' દ્વારા મોકલો."

        full_text = f"""### ૧. તમારી સમસ્યાની સમજ
{p1}

### ૨. સંભવિત કારણો અને રોગ નિદાન
{p2}

### ૩. ભલામણ કરેલ પગલાં (જૈવિક અને રાસાયણિક)
{p3}

### ૪. સમય અને વિગતવાર તબક્કા
{p4}

### ૫. સાવચેતી અને ચોક્કસ દવા પ્રમાણ (૧૫ લિટર પંપ)
{p5}

### ૬. વધુ જરૂરી માહિતી
{p6}"""
    elif lang == "hi":
        p1 = f"आपके {crop} की फसल में पत्तियों का पीला पड़ना, कीटों का प्रकोप एवं फूलों का गिरना नोट किया गया है।"
        p2 = f"{crop} में मुख्य रूप से गुलाबी सुंडी (Pink Bollworm), सफेद मक्खी या पोषक तत्वों की कमी इसका कारण हो सकती है।"
        p3 = "• जैविक नियंत्रण: प्रति एकड़ 8-10 फेरोमोन ट्रैप लगाएं। नीम का तेल (1500 ppm) 50 मिली प्रति पंप छिड़कें।\n• रासायनिक नियंत्रण: इमामेक्टिन बेंजोएट 5% एसजी 5 ग्राम प्रति 15 लीटर पंप में छिड़कें।"
        p4 = "१. छिड़काव शाम के समय करें।\n२. 10-12 दिन बाद छिड़काव दोहराएं।"
        p5 = "• प्रति पंप मात्रा: 15 लीटर वाले स्प्रे पंप में इमामेक्टिन बेंजोएट 5 ग्राम मिलाएं।\n• सुरक्षा: छिड़काव के समय दस्ताने और मास्क का प्रयोग करें।"
        p6 = "फसल की बुवाई को कितने दिन हुए हैं? ऐप के 'AI स्कैनर' से फोटो अपलोड करें।"

        full_text = f"""### १. आपकी समस्या की समझ
{p1}

### २. संभावित कारण एवं पहचान
{p2}

### ३. अनुशंसित उपाय (जैविक एवं रासायनिक)
{p3}

### ४. समय एवं चरणबद्ध छिड़काव
{p4}

### ५. सावधानियां एवं सटीक खुराक (15 लीटर पंप)
{p5}

### ६. अतिरिक्त आवश्यक जानकारी
{p6}"""
    else:
        p1 = f"Understood the symptoms of leaf yellowing, pest attack, and flower drop in your {crop} crop."
        p2 = f"Likely causes include Pink Bollworm infestation, Sucking Pests (Whitefly/Thrips), or nutrient imbalance in {crop}."
        p3 = "• Organic Action: Install 8-10 Pheromone Traps/acre. Spray Neem Oil 1500ppm @ 50ml/15L pump.\n• Chemical Action: Spray Emamectin Benzoate 5% SG @ 5g/15L water."
        p4 = "1. Spray in evening hours during calm wind conditions.\n2. Repeat after 10-12 days if pest population remains high."
        p5 = "• Exact Dosage per 15L Pump: 5g Emamectin Benzoate 5% SG. Wear protective mask and gloves."
        p6 = "What is the crop age? Please share a photo via AI Camera Scan."

        full_text = f"""### 1. Understanding Your Problem
{p1}

### 2. Likely Causes & Diagnosis
{p2}

### 3. Recommended Actions (Organic & Chemical)
{p3}

### 4. Timing & Step-by-Step Application
{p4}

### 5. Precautions & Exact Dosages (15L Pump)
{p5}

### 6. Additional Information Needed
{p6}"""

    return {
        "text": full_text,
        "sections": {
            "problemUnderstanding": p1,
            "likelyCauses": p2,
            "recommendedActions": p3,
            "timingAndSteps": p4,
            "precautionsAndDosages": p5,
            "additionalInfoNeeded": p6
        }
    }


def _parse_sections(text: str) -> Dict[str, str]:
    sections = {}
    keys = [
        "problemUnderstanding", "likelyCauses", "recommendedActions",
        "timingAndSteps", "precautionsAndDosages", "additionalInfoNeeded"
    ]
    parts = re.split(r'###\s*(?:[0-9]|૧|૨|૩|૪|૫|૬)\.\s*', text)
    if len(parts) > 1:
        for idx, part in enumerate(parts[1:7]):
            if idx < len(keys):
                sections[keys[idx]] = part.strip()
    return sections

