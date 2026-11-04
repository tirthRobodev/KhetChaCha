"""FastAPI Application Entry Point for KhetChacha Agriculture AI Engine."""

from __future__ import annotations

from contextlib import asynccontextmanager
import logging
import os
import shutil
from pathlib import Path
from typing import List

from fastapi import Depends, FastAPI, File, HTTPException, UploadFile, status
from fastapi.middleware.cors import CORSMiddleware
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request as StarletteRequest
from starlette.responses import Response as StarletteResponse

from ai_engine.backend.config import Settings, get_settings
from ai_engine.backend.dependencies import ServiceContainer, get_service_container
from ai_engine.language_engine.language_mapper import SUPPORTED_LANGUAGES
from ai_engine.models.request_models import (
    FarmerChatRequest,
    KnowledgeSearchRequest,
    OnlineSearchRequest,
)
from ai_engine.models.response_models import (
    EvidenceSource,
    FarmerChatResponse,
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
    description="Intelligent Agronomic Chat, Vector Search, and Indian Language Engine for Indian Farmers",
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


@app.post("/api/v1/chat", response_model=FarmerChatResponse, tags=["Farmer Intelligence"])
def farmer_chat(
    request: FarmerChatRequest,
    container: ServiceContainer = Depends(get_service_container),
) -> FarmerChatResponse:
    """Main AI text intelligence endpoint for farmer queries in 22 Indian languages + English."""
    try:
        response = container.response_generator.generate_response(request)
        return response
    except Exception as e:
        logger.error(f"Chat generation error: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"An error occurred while generating agricultural advisory: {str(e)}",
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

