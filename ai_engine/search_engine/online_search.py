"""Online agricultural search manager with caching and provider orchestration."""

from __future__ import annotations

import logging
import time
from typing import Dict, List, Optional, Tuple

from ai_engine.models.response_models import EvidenceSource
from ai_engine.search_engine.providers.base_provider import BaseSearchProvider
from ai_engine.search_engine.ranking import SearchRanker

logger = logging.getLogger(__name__)


class OnlineSearchEngine:
    """Manages online search queries across providers with TTL caching."""

    def __init__(
        self,
        providers: List[BaseSearchProvider],
        cache_ttl_seconds: int = 3600,
        ranker: Optional[SearchRanker] = None,
    ):
        self.providers = providers
        self.cache_ttl_seconds = cache_ttl_seconds
        self.ranker = ranker or SearchRanker()
        # Query -> (timestamp, List[EvidenceSource])
        self._cache: Dict[str, Tuple[float, List[EvidenceSource]]] = {}

    def search(
        self,
        query: str,
        max_results: int = 5,
        use_cache: bool = True,
    ) -> List[EvidenceSource]:
        """Searches across configured online providers with fallback and caching."""
        clean_q = query.strip().lower()

        # Check in-memory cache
        if use_cache and clean_q in self._cache:
            ts, cached_sources = self._cache[clean_q]
            if time.time() - ts < self.cache_ttl_seconds:
                logger.info(f"Returning {len(cached_sources)} cached online search results for: '{query}'")
                return cached_sources

        accumulated_sources: List[EvidenceSource] = []

        for provider in self.providers:
            try:
                logger.info(f"Querying search provider '{provider.provider_name}'...")
                res = provider.search(query, max_results=max_results)
                if res:
                    accumulated_sources.extend(res)
                    # If primary provider returned good results, break or continue
                    if len(accumulated_sources) >= max_results:
                        break
            except Exception as e:
                logger.warning(f"Provider {provider.provider_name} failed: {e}")

        # Rank and deduplicate
        ranked = self.ranker.rank_and_deduplicate(accumulated_sources, max_results=max_results)

        # Cache results
        if use_cache:
            self._cache[clean_q] = (time.time(), ranked)

        return ranked

    def clear_cache(self) -> None:
        """Clears the query cache."""
        self._cache.clear()

