"""Local PDF search module wrapping vector store and retriever."""

from __future__ import annotations

import logging
from typing import List, Optional

from ai_engine.knowledge_base.retriever import KnowledgeRetriever
from ai_engine.models.response_models import EvidenceSource

logger = logging.getLogger(__name__)


class LocalSearchEngine:
    """Executes searches against locally indexed agricultural PDF manuals and extension guides."""

    def __init__(self, retriever: KnowledgeRetriever, min_score_threshold: float = 0.25):
        self.retriever = retriever
        self.min_score_threshold = min_score_threshold

    def search(
        self,
        query: str,
        crop: Optional[str] = None,
        top_k: int = 4,
        min_score: Optional[float] = None,
    ) -> List[EvidenceSource]:
        """Searches indexed PDFs with query expansion and scoring threshold."""
        threshold = min_score if min_score is not None else self.min_score_threshold
        results = self.retriever.retrieve(
            query=query,
            top_k=top_k,
            crop_filter=crop,
            min_score=threshold,
        )
        logger.info(f"LocalSearchEngine returned {len(results)} sources for query '{query}'")
        return results

