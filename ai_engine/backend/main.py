"""FastAPI Application Entry Point for KhetChacha Agriculture AI Engine."""

from __future__ import annotations

import base64
from contextlib import asynccontextmanager
import logging
import os
import shutil
from pathlib import Path
from typing import List, Optional

from fastapi import Depends, FastAPI, File, Form, HTTPException, UploadFile, status
from fastapi.middleware.cors import CORSMiddleware
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request as StarletteRequest
from starlette.responses import Response as StarletteResponse

from ai_engine.backend.config import Settings, get_settings
from ai_engine.backend.dependencies import ServiceContainer, get_service_container
from ai_engine.language_engine.language_mapper import SUPPORTED_LANGUAGES
from ai_engine.models.request_models import (
    FarmerChatRequest,
    FarmerVisionDiagnoseRequest,
    KnowledgeSearchRequest,
    OnlineSearchRequest,
    SpeechIntentRequest,
)
from ai_engine.models.response_models import (
    EvidenceSource,
    FarmerChatResponse,
    FarmerVisionDiagnoseResponse,
    FileUploadResponse,
    HealthResponse,
    KnowledgeSearchResult,
    KnowledgeStatusResponse,
)

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(name)s: %(message)s")
logger = logging.getLogger("khetchacha_backend")

settings = get_settings()


@asynccontextmanager
async def lifespan(app: FastAPI):
    """
    Persistent Lifespan Startup & Teardown Handler.
    Warms singleton service container ONCE on server startup:
    - Pre-loads vector store chunks
    - Pre-loads agricultural metadata
    - Pre-warms Gemini connectivity check
    - Initializes language engine
    """
    logger.info("Initializing KhetChacha AI Engine persistent services...")
    container = get_service_container()
    logger.info(
        f"KhetChacha AI Engine initialized successfully: "
        f"Vector Chunks={len(container.vector_store.chunks)}, "
        f"Gemini Available={container.gemini_client.is_available}, "
        f"Languages={len(SUPPORTED_LANGUAGES)}"
    )
    yield
    logger.info("KhetChacha AI Engine shutting down gracefully.")


app = FastAPI(
    title="KhetChacha Agriculture AI Engine",
    description="Intelligent Agronomic Chat, Multimodal Vision Diagnosis, Vector Search, and Indian Language Engine for Indian Farmers",
    version="1.0.0",
    lifespan=lifespan,
)

# Enable CORS for Flutter mobile integration and local dev tools
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


class Utf8CharsetMiddleware(BaseHTTPMiddleware):
    """Ensures all JSON API responses include charset=utf-8 in Content-Type header.

    Without this, the Dart http package may fall back to Latin-1 decoding on Android,
    causing Gujarati, Hindi and other Indic scripts to render as garbled characters.
    """

    async def dispatch(self, request: StarletteRequest, call_next) -> StarletteResponse:
        response = await call_next(request)
        ct = response.headers.get("content-type", "")
        if "application/json" in ct and "charset" not in ct:
            response.headers["content-type"] = "application/json; charset=utf-8"
        return response


app.add_middleware(Utf8CharsetMiddleware)


@app.get("/health", response_model=HealthResponse, tags=["System"])
def health_check(
    container: ServiceContainer = Depends(get_service_container),
    cfg: Settings = Depends(get_settings),
) -> HealthResponse:
    """Returns real-time health, Gemini availability, vector index statistics, and language coverage."""
    return HealthResponse(
        status="healthy",
        version="1.0.0",
        gemini_available=container.gemini_client.is_available,
        gemini_model=cfg.gemini_model_name,
        vector_store_chunks=len(container.vector_store.chunks),
        indexed_documents_count=len(container.metadata_manager.get_catalog_summary().get("documents", [])),
        supported_languages_count=len(SUPPORTED_LANGUAGES),
    )


@app.get("/api/v1/health", tags=["System"])
def api_v1_health(
    container: ServiceContainer = Depends(get_service_container),
    cfg: Settings = Depends(get_settings),
):
    """Health check endpoint matching legacy /api/v1/health contract."""
    return {
        "status": "healthy",
        "service": "KhetChaCha Agri AI Engine",
        "version": "1.0.0",
        "gemini_configured": container.gemini_client.is_available,
        "vector_store_chunks": len(container.vector_store.chunks),
        "supported_languages_count": len(SUPPORTED_LANGUAGES),
    }


@app.post("/api/v1/speech-intent", tags=["Voice Intelligence"])
def analyze_speech_intent(request: SpeechIntentRequest):
    """Analyzes speech-to-text transcript for crop detection, intent classification, and urgency."""
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
        "language_code": request.language_code or "gu",
    }


@app.post("/api/v1/chat", response_model=FarmerChatResponse, tags=["Farmer Intelligence"])
def farmer_chat(
    request: FarmerChatRequest,
    container: ServiceContainer = Depends(get_service_container),
) -> FarmerChatResponse:
    """Main AI text intelligence and multimodal endpoint for farmer queries in 22 Indian languages + English."""
    clean_q = (request.question or request.query or "").strip()
    has_img = bool(request.image_base64 and request.image_base64.strip())
    if not clean_q and not has_img:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Query cannot be empty",
        )

    try:
        # Multimodal Vision Routing: if image_base64 is present, seamlessly route to vision service
        if request.image_base64 and request.image_base64.strip():
            logger.info("FarmerChatRequest contains image_base64. Routing to UniversalAgriVisionService.")
            try:
                img_bytes = base64.b64decode(request.image_base64)
            except Exception as e:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=f"Invalid base64 encoded image string: {e}",
                )

            vision_res = container.vision_service.diagnose_image(
                image_bytes=img_bytes,
                mime_type=request.image_mime_type or "image/jpeg",
                question=request.question,
                language=request.language or "gu",
                farmer_district=request.farmer_district,
                farmer_state=request.farmer_state,
                current_crop_hint=request.current_crop,
            )

            return FarmerChatResponse(
                success=vision_res.success,
                language=vision_res.language,
                language_name=vision_res.language_name,
                answer=vision_res.answer,
                short_answer=vision_res.answer[:250],
                detailed_explanation=vision_res.answer,
                confidence_score=round(vision_res.confidence_percentage / 100.0, 2),
                source_type="gemini_vision" if container.gemini_client.is_available else "local_pdf",
                sources=vision_res.sources,
                action_steps=vision_res.immediate_actions,
                safety_precautions=vision_res.precautions,
                crop_detected=vision_res.plant_name,
                symptoms_identified=vision_res.symptoms,
                search_strategy_used="multimodal_vision",
                requires_photo=not vision_res.success,
                conversation_id=request.conversation_id,
                plant_category=vision_res.plant_category,
                plant_part=vision_res.plant_part,
                health_status=vision_res.health_status,
            )

        response = container.response_generator.generate_response(request)
        return response
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Chat generation error: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"An error occurred while generating agricultural advisory: {str(e)}",
        )


@app.post("/api/v1/vision/diagnose", response_model=FarmerVisionDiagnoseResponse, tags=["Agricultural Vision"])
def vision_diagnose_json(
    request: FarmerVisionDiagnoseRequest,
    container: ServiceContainer = Depends(get_service_container),
) -> FarmerVisionDiagnoseResponse:
    """Diagnoses an uploaded single image (Base64) of any crop, fruit, vegetable, tree, leaf, root, or seed."""
    try:
        img_bytes = base64.b64decode(request.image_base64)
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Invalid base64 encoded image string: {e}",
        )

    return container.vision_service.diagnose_image(
        image_bytes=img_bytes,
        mime_type=request.mime_type or "image/jpeg",
        question=request.question,
        language=request.language or "gu",
        farmer_district=request.farmer_district,
        farmer_state=request.farmer_state,
        current_crop_hint=request.current_crop,
    )


@app.post("/api/v1/vision/upload", response_model=FarmerVisionDiagnoseResponse, tags=["Agricultural Vision"])
async def vision_diagnose_file(
    file: UploadFile = File(...),
    question: Optional[str] = Form(None),
    language: Optional[str] = Form("auto"),
    farmer_district: Optional[str] = Form(None),
    farmer_state: Optional[str] = Form(None),
    current_crop: Optional[str] = Form(None),
    container: ServiceContainer = Depends(get_service_container),
) -> FarmerVisionDiagnoseResponse:
    """Diagnoses an uploaded single image file of any crop, fruit, vegetable, tree, leaf, root, or seed."""
    content = await file.read()
    return container.vision_service.diagnose_image(
        image_bytes=content,
        mime_type=file.content_type or "image/jpeg",
        question=question,
        language=language or "gu",
        farmer_district=farmer_district,
        farmer_state=farmer_state,
        current_crop_hint=current_crop,
    )


@app.post("/api/v1/search", response_model=List[EvidenceSource], tags=["Search"])
def online_search(
    request: OnlineSearchRequest,
    container: ServiceContainer = Depends(get_service_container),
) -> List[EvidenceSource]:
    """Searches verified online agricultural portals, ICAR, and KVK resources."""
    try:
        results = container.online_search.search(
            query=request.query,
            max_results=request.max_results,
        )
        return results
    except Exception as e:
        logger.error(f"Online search error: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Online search failed: {str(e)}",
        )


@app.post("/api/v1/knowledge/search", response_model=KnowledgeSearchResult, tags=["Knowledge Base"])
def search_knowledge_base(
    request: KnowledgeSearchRequest,
    container: ServiceContainer = Depends(get_service_container),
) -> KnowledgeSearchResult:
    """Executes hybrid vector + BM25 keyword search over local agricultural PDFs."""
    try:
        sources = container.local_search.search(
            query=request.query,
            crop=request.crop,
            top_k=request.top_k,
            min_score=request.min_score,
        )
        return KnowledgeSearchResult(
            query=request.query,
            crop=request.crop,
            total_results=len(sources),
            sources=sources,
        )
    except Exception as e:
        logger.error(f"Knowledge search error: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Local knowledge search failed: {str(e)}",
        )


@app.post("/api/v1/knowledge/upload", response_model=FileUploadResponse, tags=["Knowledge Base"])
async def upload_pdf_knowledge(
    file: UploadFile = File(...),
    container: ServiceContainer = Depends(get_service_container),
    cfg: Settings = Depends(get_settings),
) -> FileUploadResponse:
    """Uploads and indexes an agricultural PDF guide, university manual, or extension circular."""
    if not file.filename.lower().endswith(".pdf"):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Only PDF documents (.pdf) are supported.",
        )

    destination_path = cfg.pdf_dir / file.filename
    try:
        # Save file to pdf directory
        with open(destination_path, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)

        # Index the newly saved file
        index_result = container.pdf_indexer.index_single_file(destination_path, force=True)

        # Invalidate response cache so updated knowledge is reflected immediately
        container.response_generator.clear_cache()

        return FileUploadResponse(
            filename=file.filename,
            status=index_result.get("status", "success"),
            message="Document uploaded and indexed successfully into vector knowledge base.",
            pages_extracted=index_result.get("pages", 0),
            chunks_created=index_result.get("chunks", 0),
            crops_detected=index_result.get("crops", []),
            symptoms_detected=index_result.get("symptoms", []),
        )
    except Exception as e:
        logger.error(f"PDF upload and indexing error: {e}", exc_info=True)
        if destination_path.exists():
            destination_path.unlink(missing_ok=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to process and index PDF: {str(e)}",
        )


@app.get("/api/v1/knowledge/status", response_model=KnowledgeStatusResponse, tags=["Knowledge Base"])
def get_knowledge_status(
    container: ServiceContainer = Depends(get_service_container),
) -> KnowledgeStatusResponse:
    """Returns status, statistics, and catalog details of the indexed agricultural knowledge base."""
    summary = container.metadata_manager.get_catalog_summary()
    return KnowledgeStatusResponse(
        total_documents=summary.get("total_documents", 0),
        total_pages=summary.get("total_pages", 0),
        total_chunks=summary.get("total_chunks", 0),
        crops_indexed=summary.get("crops_covered", []),
        symptoms_indexed=summary.get("symptoms_covered", []),
        documents=summary.get("documents", []),
        last_updated=summary.get("last_updated"),
    )
