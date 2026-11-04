"""Ranking and deduplication engine for search evidence."""

from __future__ import annotations

from typing import List
from ai_engine.models.response_models import EvidenceSource
from ai_engine.search_engine.source_verifier import SourceVerifier


class SearchRanker:
    """Ranks, deduplicates, and re-scores evidence sources based on credibility and relevance."""

    def __init__(self, verifier: SourceVerifier | None = None):
        self.verifier = verifier or SourceVerifier()

    def rank_and_deduplicate(
        self,
        sources: List[EvidenceSource],
        max_results: int = 5,
    ) -> List[EvidenceSource]:
        """Deduplicates and re-ranks sources applying domain authority boosters."""
        if not sources:
            return []

        seen_keys = set()
        deduped: List[EvidenceSource] = []

        for src in sources:
            # Create a unique key for deduplication
            if src.url:
                clean_url = src.url.split("?")[0].rstrip("/")
                key = f"url:{clean_url}"
            elif src.document_name and src.page_number is not None:
                key = f"doc:{src.document_name}:p{src.page_number}"
            else:
                key = f"snip:{src.snippet[:60].strip().lower()}"

            if key in seen_keys:
                continue
            seen_keys.add(key)

            # Apply authority multiplier
            multiplier = 1.0
            if src.url:
                multiplier = self.verifier.calculate_authority_multiplier(src.url)
            elif src.source_type == "local_pdf":
                # Local vetted ICAR/Univ PDFs get authority boost
                multiplier = 1.35

            boosted_score = min(0.99, round(src.confidence_score * multiplier, 3))

            ranked_src = EvidenceSource(
                title=src.title,
                url=src.url,
                document_name=src.document_name,
                page_number=src.page_number,
                snippet=src.snippet,
                confidence_score=boosted_score,
                source_type=src.source_type,
            )
            deduped.append(ranked_src)

        # Sort descending by boosted confidence score
        deduped.sort(key=lambda s: s.confidence_score, reverse=True)
        return deduped[:max_results]

