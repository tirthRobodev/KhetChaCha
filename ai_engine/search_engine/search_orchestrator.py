"""Search Orchestrator implementing Phase 6 Local-First + Online Fallback architecture."""

from __future__ import annotations

import logging
from typing import Any, Dict, List, Optional

from ai_engine.models.response_models import EvidenceSource
from ai_engine.search_engine.local_search import LocalSearchEngine
from ai_engine.search_engine.online_search import OnlineSearchEngine
from ai_engine.search_engine.ranking import SearchRanker
from ai_engine.search_engine.search_router import SearchRouter
from ai_engine.search_engine.structured_search import StructuredKnowledgeSearchEngine

logger = logging.getLogger(__name__)


class SearchOrchestratorResult:
    """Encapsulates retrieval results and strategy metadata."""

    def __init__(
        self,
        sources: List[EvidenceSource],
        strategy_used: str,
        query_analysis: Dict[str, Any],
        local_results_count: int,
        online_results_count: int,
        structured_results_count: int = 0,
        is_evidence_sufficient: bool = True,
    ):
        self.sources = sources
        self.strategy_used = strategy_used
        self.query_analysis = query_analysis
        self.local_results_count = local_results_count
        self.online_results_count = online_results_count
        self.structured_results_count = structured_results_count
        self.is_evidence_sufficient = is_evidence_sufficient


class SearchOrchestrator:
    """Coordinates local PDF search, structured crop knowledge search, and online fallback search."""

    def __init__(
        self,
        local_search: LocalSearchEngine,
        online_search: OnlineSearchEngine,
        structured_search: Optional[StructuredKnowledgeSearchEngine] = None,
        local_min_score: float = 0.35,
        max_evidence_sources: int = 5,
        ranker: Optional[SearchRanker] = None,
    ):
        self.local_search = local_search
        self.online_search = online_search
        self.structured_search = structured_search or StructuredKnowledgeSearchEngine()
        self.local_min_score = local_min_score
        self.max_evidence_sources = max_evidence_sources
        self.ranker = ranker or SearchRanker()

    def retrieve_evidence(
        self,
        query: str,
        crop: Optional[str] = None,
        force_online: bool = False,
    ) -> SearchOrchestratorResult:
        """Executes multi-tier retrieval: Local PDF -> Structured Knowledge -> Trusted Online Search."""
        analysis = SearchRouter.classify_query(query)
        detected_crops = analysis.get("crops_detected", [])
        active_crop = crop or (detected_crops[0] if detected_crops else None)

        local_pdf_sources: List[EvidenceSource] = []
        structured_sources: List[EvidenceSource] = []
        online_sources: List[EvidenceSource] = []
        strategy_used = "local_only"

        # Step 1: Local PDF Search FIRST
        if not force_online:
            try:
                local_pdf_sources = self.local_search.search(
                    query=query,
                    crop=active_crop,
                    top_k=self.max_evidence_sources,
                    min_score=self.local_min_score,
                )
            except Exception as e:
                logger.warning(f"Local PDF search encountered an error: {e}")

        # Step 2: Structured Crop Knowledge Search (Gold-standard profiles, diseases, pests)
        try:
            structured_sources = self.structured_search.search(
                query=query,
                crop=active_crop,
                top_k=self.max_evidence_sources,
                min_score=0.30,
            )
        except Exception as e:
            logger.warning(f"Structured knowledge search encountered an error: {e}")

        # Step 3: Evaluate Combined Local Evidence Quality
        local_combined = local_pdf_sources + structured_sources
        has_sufficient_local = bool(
            local_combined
            and any(s.confidence_score >= self.local_min_score for s in local_combined)
        )

        # Step 4: Trigger Trusted Online Search if local is insufficient or forced
        needs_online = force_online or not has_sufficient_local or analysis.get("category") == "market_and_pricing"

        if needs_online:
            logger.info("Local evidence insufficient or online required. Executing trusted online search...")
            try:
                online_sources = self.online_search.search(
                    query=query,
                    max_results=self.max_evidence_sources,
                )
                if local_combined:
                    strategy_used = "hybrid_fallback"
                else:
                    strategy_used = "online_only" if online_sources else "fallback_empty"
            except Exception as e:
                logger.warning(f"Online search failed: {e}")
                strategy_used = "local_only" if local_combined else "fallback_empty"
        else:
            strategy_used = "local_only"

        # Step 5: Merge, Rank, and Deduplicate across all tiers
        all_candidates = local_pdf_sources + structured_sources + online_sources
        final_sources = self.ranker.rank_and_deduplicate(
            all_candidates,
            max_results=self.max_evidence_sources,
        )

        is_sufficient = bool(final_sources and final_sources[0].confidence_score >= 0.25)

        return SearchOrchestratorResult(
            sources=final_sources,
            strategy_used=strategy_used,
            query_analysis=analysis,
            local_results_count=len(local_pdf_sources),
            online_results_count=len(online_sources),
            structured_results_count=len(structured_sources),
            is_evidence_sufficient=is_sufficient,
        )

