"""Gemini API-powered search grounding provider."""

from __future__ import annotations

import logging
from typing import List, Optional

from ai_engine.models.response_models import EvidenceSource
from ai_engine.search_engine.providers.base_provider import BaseSearchProvider
from ai_engine.search_engine.source_verifier import SourceVerifier

logger = logging.getLogger(__name__)


class GeminiSearchProvider(BaseSearchProvider):
    """Integrates Gemini Google Search Grounding to retrieve live web evidence."""

    def __init__(self, api_key: Optional[str] = None, model_name: str = "gemini-2.5-flash"):
        self.api_key = api_key
        self.model_name = model_name
        self.verifier = SourceVerifier()
        self._is_ready = bool(api_key and api_key.strip())

    @property
    def provider_name(self) -> str:
        return "gemini_grounding"

    def search(self, query: str, max_results: int = 5) -> List[EvidenceSource]:
        """Queries Gemini with Search Grounding enabled and extracts grounding chunks."""
        if not self._is_ready:
            logger.info("Gemini Search Provider: API key not provided or empty. Returning empty list.")
            return []

        try:
            import google.generativeai as genai
            genai.configure(api_key=self.api_key)

            # Agricultural contextualization
            prompt = (
                f"You are searching authoritative agricultural research, ICAR, KVK, and government portals. "
                f"Find verified information for: {query}"
            )

            # Instantiate model with search grounding tool
            model = genai.GenerativeModel(
                model_name=self.model_name,
                tools="google_search_retrieval",
            )

            response = model.generate_content(prompt)
            results: List[EvidenceSource] = []

            # Check for grounding metadata in candidates
            if response.candidates:
                candidate = response.candidates[0]
                grounding_metadata = getattr(candidate, "grounding_metadata", None)

                if grounding_metadata:
                    chunks = getattr(grounding_metadata, "grounding_chunks", [])
                    for chunk in chunks:
                        web = getattr(chunk, "web", None)
                        if web:
                            url = getattr(web, "uri", None)
                            title = getattr(web, "title", "Agricultural Reference")

                            if not self.verifier.is_credible_source(url):
                                continue

                            results.append(
                                EvidenceSource(
                                    title=title,
                                    url=url,
                                    snippet=f"Grounding source from {title}",
                                    confidence_score=0.85,
                                    source_type="gemini_grounding",
                                )
                            )

            # If grounding metadata was empty but text was generated, extract any sources from text
            if not results and response.text:
                results.append(
                    EvidenceSource(
                        title="Gemini Verified Knowledge",
                        snippet=response.text[:300],
                        confidence_score=0.75,
                        source_type="gemini_grounding",
                    )
                )

            return results[:max_results]

        except Exception as e:
            logger.warning(f"Gemini grounding search encountered exception: {e}")
            return []

