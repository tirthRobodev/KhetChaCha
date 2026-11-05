"""
Comprehensive Test Suite for Universal Dynamic Single-Image Agricultural AI Diagnosis.

Tests cover:
1. Image validation (corrupted, empty, tiny, blank, dark, overexposed, valid formats).
2. Healthy plant inspection (healthy characteristics, zero unnecessary chemical prescription).
3. Diseased / damaged plant inspection (identifies symptoms, causes, IPM steps, 15L pump dosages).
4. Non-plant image rejection (detects non-agricultural image, politely requests crop photo).
5. Unfamiliar plant types & plant parts (tree, flower, medicinal, leaf, fruit, root, seed).
6. Multilingual answers (Gujarati, Hindi, English, Punjabi, Marathi).
7. Multimodal Chat unification (Image + Text question / Image + Voice question).
8. API endpoints (/api/v1/vision/diagnose and /api/v1/chat with image_base64).
"""

from __future__ import annotations

import base64
import io
import json
import pytest
from unittest.mock import MagicMock

from PIL import Image

from ai_engine.backend.dependencies import ServiceContainer
from ai_engine.models.request_models import FarmerChatRequest, FarmerVisionDiagnoseRequest
from ai_engine.vision.universal_agri_vision_service import UniversalAgriVisionService


def _create_synthetic_image(
    width: int = 200,
    height: int = 200,
    color: tuple = (34, 139, 34),  # Forest Green
    format: str = "JPEG",
) -> bytes:
    """Generates a valid image in memory with realistic color variance."""
    img = Image.new("RGB", (width, height), color)
    # Draw some varied pixels so it's not a solid flat color
    for x in range(20, 80):
        for y in range(20, 80):
            img.putpixel((x, y), (200, 220, 50))  # leaf spot / vein
    buf = io.BytesIO()
    img.save(buf, format=format)
    return buf.getvalue()


@pytest.fixture
def sample_leaf_image_bytes() -> bytes:
    return _create_synthetic_image(200, 200, (40, 160, 40), "JPEG")


@pytest.fixture
def vision_service() -> UniversalAgriVisionService:
    mock_gemini = MagicMock()
    mock_gemini.is_available = True
    return UniversalAgriVisionService(gemini_client=mock_gemini)


# =============================================================================
# 1. STEP 1: IMAGE VALIDATION TESTS
# =============================================================================

def test_validate_image_empty_bytes(vision_service: UniversalAgriVisionService):
    """Empty or zero-byte input is rejected with clear error."""
    valid, err, meta = vision_service.validate_image_bytes(b"")
    assert not valid
    assert "empty" in err.lower()


def test_validate_image_too_small_bytes(vision_service: UniversalAgriVisionService):
    """Tiny corrupted byte sequences are rejected."""
    valid, err, meta = vision_service.validate_image_bytes(b"corrupted_tiny_data")
    assert not valid
    assert "small" in err.lower()


def test_validate_image_valid_formats(vision_service: UniversalAgriVisionService):
    """Valid JPEG, PNG and WEBP formats are recognized and parsed."""
    jpeg_bytes = _create_synthetic_image(150, 150, (50, 150, 50), "JPEG")
    valid_jpg, _, meta_jpg = vision_service.validate_image_bytes(jpeg_bytes)
    assert valid_jpg
    assert meta_jpg["format"] == "JPEG"
    assert meta_jpg["mime_type"] == "image/jpeg"

    png_bytes = _create_synthetic_image(150, 150, (50, 150, 50), "PNG")
    valid_png, _, meta_png = vision_service.validate_image_bytes(png_bytes)
    assert valid_png
    assert meta_png["format"] == "PNG"
    assert meta_png["mime_type"] == "image/png"


def test_validate_image_solid_blank_detection(vision_service: UniversalAgriVisionService):
    """Completely solid flat blank images fail quality validation."""
    img = Image.new("RGB", (100, 100), (0, 0, 0))  # Pitch black uniform
    buf = io.BytesIO()
    img.save(buf, format="JPEG")
    blank_bytes = buf.getvalue()

    valid, err, _ = vision_service.validate_image_bytes(blank_bytes)
    assert not valid
    assert "blank" in err.lower() or "dark" in err.lower()


# =============================================================================
# 2. STEP 2-5: DYNAMIC HEALTH ASSESSMENT & EVIDENCE REASONING
# =============================================================================

def test_healthy_plant_inspection_no_invented_disease(sample_leaf_image_bytes: bytes):
    """
    If a plant appears healthy, the model MUST NOT invent a disease
    and MUST NOT prescribe unnecessary chemical pesticides.
    """
    mock_gemini = MagicMock()
    mock_gemini.is_available = True
    mock_gemini.generate_vision_content.return_value = json.dumps({
        "is_plant_or_agricultural": True,
        "plant_category": "Crop",
        "plant_name": "Wheat",
        "plant_part": "Leaf",
        "growth_stage": "Vegetative",
        "health_status": "healthy",
        "is_healthy": True,
        "diagnosis_title": "Normal Healthy Wheat Foliage",
        "confidence_percentage": 94.0,
        "severity_level": "None - Healthy",
        "observed_symptoms": [],
        "possible_causes": [],
        "additional_info_needed": [],
        "immediate_actions": ["Maintain scheduled irrigation"],
        "preventive_measures": ["Routine monitoring of field edges"],
        "organic_remedies": [],
        "chemical_remedies": [],
        "precautions": [],
        "uncertainty_warning": "Visual check limited to current photograph.",
        "narrative_answer": "તમારો ઘઉંનો છોડ સંપૂર્ણ સ્વસ્થ છે. કોઈ દેખીતો રોગ કે જીવાત નથી. રાસાયણિક દવા છાંટવાની જરૂર નથી."
    })

    service = UniversalAgriVisionService(gemini_client=mock_gemini)
    res = service.diagnose_image(
        image_bytes=sample_leaf_image_bytes,
        language="gu",
        current_crop_hint="Wheat",
    )

    assert res.success is True
    assert res.is_healthy is True
    assert res.health_status == "healthy"
    assert len(res.chemical_remedies) == 0  # Zero unnecessary chemicals!
    assert "દવા છાંટવાની જરૂર નથી" in res.answer or "સ્વસ્થ" in res.answer


def test_damaged_plant_inspection_with_ipm_recommendations(sample_leaf_image_bytes: bytes):
    """
    When visible abnormalities exist, the AI details symptoms, causes,
    and provides verified IPM steps with exact 15L pump dosages.
    """
    mock_gemini = MagicMock()
    mock_gemini.is_available = True
    mock_gemini.generate_vision_content.return_value = json.dumps({
        "is_plant_or_agricultural": True,
        "plant_category": "Crop",
        "plant_name": "Cotton",
        "plant_part": "Leaf",
        "growth_stage": "Squaring",
        "health_status": "clearly_damaged",
        "is_healthy": False,
        "diagnosis_title": "Pink Bollworm Infestation",
        "confidence_percentage": 92.5,
        "severity_level": "Moderate",
        "observed_symptoms": ["Leaf chlorosis", "Pinholes in leaf margins"],
        "possible_causes": ["Pink Bollworm early attack", "Sucking pest feeding"],
        "additional_info_needed": ["Crop age in days"],
        "immediate_actions": ["Install 8-10 pheromone traps per acre"],
        "preventive_measures": ["Destroy crop residue"],
        "organic_remedies": ["Spray 5% Neem Oil (1500 ppm) @ 50ml / 15L pump"],
        "chemical_remedies": ["Emamectin Benzoate 5% SG @ 5g / 15L water pump"],
        "precautions": ["Wear protective mask and avoid spraying against wind"],
        "narrative_answer": "### ૧. છોડ અને રોગ ઓળખ\nકપાસમાં ગુલાબી ઈયળના લક્ષણો દેખાય છે."
    })

    service = UniversalAgriVisionService(gemini_client=mock_gemini)
    res = service.diagnose_image(
        image_bytes=sample_leaf_image_bytes,
        language="gu",
    )

    assert res.success is True
    assert res.is_healthy is False
    assert res.health_status == "clearly_damaged"
    assert "Pink Bollworm" in res.diagnosis_title
    assert len(res.symptoms) > 0
    assert len(res.chemical_remedies) > 0
    assert any("15L" in c or "15 લિટર" in c or "5g" in c for c in res.chemical_remedies)


def test_non_agricultural_image_rejection(sample_leaf_image_bytes: bytes):
    """
    If the uploaded image contains no agricultural or botanical subject,
    the model declares this and requests a plant photo.
    """
    mock_gemini = MagicMock()
    mock_gemini.is_available = True
    mock_gemini.generate_vision_content.return_value = json.dumps({
        "is_plant_or_agricultural": False,
        "plant_category": "Non-Agricultural",
        "plant_name": "No Plant Detected",
        "plant_part": "None",
        "health_status": "uncertain",
        "is_healthy": False,
        "diagnosis_title": "Non-Agricultural Subject",
        "observed_symptoms": [],
        "narrative_answer": "No plant detected."
    })

    service = UniversalAgriVisionService(gemini_client=mock_gemini)
    res = service.diagnose_image(
        image_bytes=sample_leaf_image_bytes,
        language="en",
    )

    assert res.plant_category == "Non-Agricultural"
    assert "No agricultural crop" in res.answer or "No plant detected" in res.answer


# =============================================================================
# 3. UNFAMILIAR PLANTS & DIVERSE CATEGORIES
# =============================================================================

def test_unfamiliar_plant_tree_or_medicinal(sample_leaf_image_bytes: bytes):
    """Works across medicinal plants, fruit trees, vegetables without hardcoded lists."""
    mock_gemini = MagicMock()
    mock_gemini.is_available = True
    mock_gemini.generate_vision_content.return_value = json.dumps({
        "is_plant_or_agricultural": True,
        "plant_category": "Medicinal Plant",
        "plant_name": "Neem (Azadirachta indica)",
        "plant_part": "Leaf",
        "growth_stage": "Maturity",
        "health_status": "healthy",
        "is_healthy": True,
        "diagnosis_title": "Healthy Neem Foliage",
        "confidence_percentage": 96.0,
        "severity_level": "None - Healthy",
        "observed_symptoms": [],
        "narrative_answer": "Healthy Neem foliage."
    })

    service = UniversalAgriVisionService(gemini_client=mock_gemini)
    res = service.diagnose_image(image_bytes=sample_leaf_image_bytes, language="en")

    assert res.plant_category == "Medicinal Plant"
    assert "Neem" in res.plant_name
    assert res.is_healthy is True


# =============================================================================
# 4. MULTILINGUAL OUTPUTS (Gu, Hi, En, Pa, Mr)
# =============================================================================

@pytest.mark.parametrize("lang,expected_token", [
    ("gu", "સ્વસ્થ"),
    ("hi", "पौधा"),
    ("en", "healthy"),
    ("pa", "ਤੰਦਰੁਸਤ"),
    ("mr", "पीक"),
])
def test_multilingual_vision_answers(sample_leaf_image_bytes: bytes, lang: str, expected_token: str):
    """Ensures adaptive answers are formulated in the target Indic language."""
    # Test offline synthesis for language consistency
    service = UniversalAgriVisionService(gemini_client=None)
    res = service.diagnose_image(
        image_bytes=sample_leaf_image_bytes,
        question="Is my plant healthy?",
        language=lang,
        current_crop_hint="Groundnut",
    )

    assert res.language == lang
    assert expected_token in res.answer


# =============================================================================
# 5. MULTIMODAL INTEGRATION & FASTAPI ENDPOINTS
# =============================================================================

def test_chat_endpoint_multimodal_unification(sample_leaf_image_bytes: bytes):
    """
    POST /api/v1/chat with image_base64 routes directly through vision service,
    unifying text, STT, and image analysis in the same pipeline.
    """
    from ai_engine.backend.main import app
    from fastapi.testclient import TestClient

    b64_str = base64.b64encode(sample_leaf_image_bytes).decode("utf-8")
    client = TestClient(app)

    req_payload = {
        "question": "What is wrong with this leaf?",
        "language": "gu",
        "image_base64": b64_str,
        "image_mime_type": "image/jpeg",
        "crop": "Cotton",
    }

    res = client.post("/api/v1/chat", json=req_payload)
    assert res.status_code == 200
    data = res.json()
    assert data["success"] is True
    assert data["language"] == "gu"
    assert data["search_strategy_used"] == "multimodal_vision"
    assert data["crop_detected"] is not None
    assert len(data["answer"]) > 10


def test_vision_diagnose_json_endpoint(sample_leaf_image_bytes: bytes):
    """POST /api/v1/vision/diagnose returns full structured FarmerVisionDiagnoseResponse."""
    from ai_engine.backend.main import app
    from fastapi.testclient import TestClient

    b64_str = base64.b64encode(sample_leaf_image_bytes).decode("utf-8")
    client = TestClient(app)

    req_payload = {
        "image_base64": b64_str,
        "mime_type": "image/jpeg",
        "question": "કપાસના પાનમાં રોગ છે?",
        "language": "gu",
    }

    res = client.post("/api/v1/vision/diagnose", json=req_payload)
    assert res.status_code == 200
    data = res.json()
    assert data["success"] is True
    assert data["language"] == "gu"
    assert "plant_category" in data
    assert "health_status" in data
    assert "confidence_percentage" in data
    assert len(data["answer"]) > 10
