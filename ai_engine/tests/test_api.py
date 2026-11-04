"""API integration tests for FastAPI backend endpoints."""

import io
import pytest
from fastapi.testclient import TestClient
from ai_engine.backend.main import app


@pytest.fixture
def client():
    return TestClient(app)


def test_health_endpoint(client):
    """Tests GET /health returns 200 OK and expected stats."""
    response = client.get("/health")
    assert response.status_code == 200
    data = response.json()

    assert data["status"] == "healthy"
    assert data["version"] == "1.0.0"
    assert data["supported_languages_count"] >= 23
    assert data["vector_store_chunks"] >= 1


def test_knowledge_status_endpoint(client):
    """Tests GET /api/v1/knowledge/status returns catalog and chunk statistics."""
    response = client.get("/api/v1/knowledge/status")
    assert response.status_code == 200
    data = response.json()

    assert data["total_documents"] >= 2
    assert data["total_chunks"] >= 4
    assert "Cotton" in data["crops_indexed"]


def test_knowledge_search_endpoint(client):
    """Tests POST /api/v1/knowledge/search returns verified PDF evidence."""
    payload = {
        "query": "cotton leaf yellowing chlorosis",
        "top_k": 3,
        "crop": "Cotton",
    }
    response = client.post("/api/v1/knowledge/search", json=payload)
    assert response.status_code == 200
    data = response.json()

    assert data["total_results"] >= 1
    assert len(data["sources"]) >= 1
    assert "ICAR_CICR_Cotton_Crop_Advisory.pdf" in data["sources"][0]["document_name"]


def test_farmer_chat_endpoint_gujarati(client):
    """Tests POST /api/v1/chat with natural farmer query in Gujarati."""
    payload = {
        "question": "મારા કપાસના પાનમાં પીળાશ દેખાય છે, શું કરવું?",
        "language": "gu",
        "current_crop": "Cotton",
        "land_size": "4 Bigha",
    }
    response = client.post("/api/v1/chat", json=payload)
    assert response.status_code == 200
    data = response.json()

    assert data["success"] is True
    assert data["language"] == "gu"
    assert len(data["answer"]) > 20
    assert len(data["action_steps"]) >= 1
    assert len(data["safety_precautions"]) >= 1
    assert data["crop_detected"] == "Cotton"


def test_farmer_chat_endpoint_hindi(client):
    """Tests POST /api/v1/chat with farmer query in Hindi."""
    payload = {
        "question": "कपास में गुलाबी सुंडी का नियंत्रण कैसे करें?",
        "language": "hi",
        "current_crop": "Cotton",
    }
    response = client.post("/api/v1/chat", json=payload)
    assert response.status_code == 200
    data = response.json()

    assert data["success"] is True
    assert data["language"] == "hi"
    assert len(data["answer"]) > 20
    assert len(data["action_steps"]) >= 1


def test_farmer_chat_endpoint_ambiguity_clarification(client):
    """Tests POST /api/v1/chat handles ambiguous queries with photo request."""
    payload = {
        "question": "છોડ સુકાઈ રહ્યો છે",
        "language": "gu",
    }
    response = client.post("/api/v1/chat", json=payload)
    assert response.status_code == 200
    data = response.json()

    assert data["requires_photo"] is True
    assert "1800-180-1551" in data["answer"]


def test_pdf_upload_endpoint(client, tmp_path):
    """Tests POST /api/v1/knowledge/upload with in-memory PDF."""
    from ai_engine.scripts.generate_sample_pdfs import create_groundnut_guide_pdf
    temp_pdf = tmp_path / "test_upload_advisory.pdf"
    create_groundnut_guide_pdf(temp_pdf)

    with open(temp_pdf, "rb") as f:
        response = client.post(
            "/api/v1/knowledge/upload",
            files={"file": ("test_upload_advisory.pdf", f, "application/pdf")},
        )

    assert response.status_code == 200
    data = response.json()
    assert data["success"] is True
    assert data["filename"] == "test_upload_advisory.pdf"
    assert data["pages_extracted"] >= 1
    assert data["chunks_created"] >= 1

    # Cleanup test chunks to prevent polluting subsequent search tests
    from ai_engine.backend.dependencies import get_service_container
    container = get_service_container()
    container.vector_store.chunks = {
        cid: c for cid, c in container.vector_store.chunks.items()
        if c.document_name != "test_upload_advisory.pdf"
    }
    container.vector_store.save()

