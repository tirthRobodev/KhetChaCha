"""Dependency injection container for KhetChacha AI Engine backend services."""

from __future__ import annotations

from functools import lru_cache
from typing import Optional

from ai_engine.backend.config import Settings, get_settings
from ai_engine.gemini.context_manager import ConversationContextManager
from ai_engine.gemini.gemini_client import GeminiClient
from ai_engine.gemini.response_generator import ResponseGenerator
from ai_engine.knowledge_base.embeddings import EmbeddingGenerator
from ai_engine.knowledge_base.metadata_manager import MetadataManager
from ai_engine.knowledge_base.retriever import KnowledgeRetriever
from ai_engine.knowledge_base.vector_store import VectorStore
from ai_engine.pdf_processor.ocr_processor import OCRProcessor
from ai_engine.pdf_processor.pdf_indexer import PDFIndexer
from ai_engine.safety.agriculture_safety import AgricultureSafetyEngine
from ai_engine.search_engine.local_search import LocalSearchEngine
from ai_engine.search_engine.online_search import OnlineSearchEngine
from ai_engine.search_engine.structured_search import StructuredKnowledgeSearchEngine
from ai_engine.search_engine.providers.configurable_web_provider import ConfigurableWebSearchProvider
from ai_engine.search_engine.providers.gemini_search_provider import GeminiSearchProvider
from ai_engine.search_engine.ranking import SearchRanker
from ai_engine.search_engine.search_orchestrator import SearchOrchestrator


class ServiceContainer:
    """Manages stateful service lifecycles across the application."""

    def __init__(self, settings: Settings):
        self.settings = settings

        # 1. Metadata and Vector Storage
        self.metadata_manager = MetadataManager(metadata_dir=settings.metadata_dir)
        self.embedding_generator = EmbeddingGenerator(
            api_key=settings.gemini_api_key,
            model_name=settings.gemini_embedding_model,
        )
        self.vector_store = VectorStore(db_dir=settings.vector_db_dir)

        # 2. PDF Processing & Indexing
        self.ocr_processor = OCRProcessor()
        self.pdf_indexer = PDFIndexer(
            pdf_dir=settings.pdf_dir,
            vector_store=self.vector_store,
            metadata_manager=self.metadata_manager,
            embedding_generator=self.embedding_generator,
            ocr_processor=self.ocr_processor,
        )

        # 3. Knowledge Retrieval & Search
        self.retriever = KnowledgeRetriever(
            vector_store=self.vector_store,
            embedding_generator=self.embedding_generator,
        )
        self.local_search = LocalSearchEngine(
            retriever=self.retriever,
            min_score_threshold=settings.local_search_min_score,
        )

        # 4. Online Search Providers
        web_provider = ConfigurableWebSearchProvider()
        gemini_search_provider = GeminiSearchProvider(
            api_key=settings.gemini_api_key,
            model_name=settings.gemini_model_name,
        )
        self.online_search = OnlineSearchEngine(
            providers=[gemini_search_provider, web_provider],
            cache_ttl_seconds=3600,
        )

        # 5. Search Orchestrator
        self.structured_search = StructuredKnowledgeSearchEngine(
            knowledge_dir=settings.data_dir / "knowledge"
        )
        self.search_orchestrator = SearchOrchestrator(
            local_search=self.local_search,
            online_search=self.online_search,
            structured_search=self.structured_search,
            local_min_score=settings.local_search_min_score,
            max_evidence_sources=settings.max_evidence_sources,
        )

        # 6. Gemini LLM & Response Generator
        self.gemini_client = GeminiClient(
            api_key=settings.gemini_api_key,
            model_name=settings.gemini_model_name,
            timeout_seconds=settings.gemini_timeout_seconds,
            max_retries=settings.gemini_max_retries,
        )
        self.context_manager = ConversationContextManager()
        self.safety_engine = AgricultureSafetyEngine()
        self.response_generator = ResponseGenerator(
            gemini_client=self.gemini_client,
            search_orchestrator=self.search_orchestrator,
            safety_engine=self.safety_engine,
            context_manager=self.context_manager,
        )


_container_instance: Optional[ServiceContainer] = None


def get_service_container() -> ServiceContainer:
    """Returns singleton service container instance."""
    global _container_instance
    if _container_instance is None:
        settings = get_settings()
        _container_instance = ServiceContainer(settings)
    return _container_instance

