"""Configurable web search provider targeting authoritative agricultural domains."""

from __future__ import annotations

import logging
import re
from typing import List, Optional
import httpx

from ai_engine.models.response_models import EvidenceSource
from ai_engine.search_engine.providers.base_provider import BaseSearchProvider
from ai_engine.search_engine.source_verifier import SourceVerifier

logger = logging.getLogger(__name__)


class ConfigurableWebSearchProvider(BaseSearchProvider):
    """Searches the web via HTTP API prioritized for Indian agricultural portals."""

    def __init__(
        self,
        endpoint_url: str = "https://html.duckduckgo.com/html/",
        timeout_seconds: float = 8.0,
        enable_agricultural_scoping: bool = True,
    ):
        self.endpoint_url = endpoint_url
        self.timeout_seconds = timeout_seconds
        self.enable_agricultural_scoping = enable_agricultural_scoping
        self.verifier = SourceVerifier()

    @property
    def provider_name(self) -> str:
        return "configurable_web"

    def _build_scoped_query(self, query: str) -> str:
        if not self.enable_agricultural_scoping:
            return query
        # Boost ICAR / KVK / Indian agriculture context
        return f"{query} agriculture ICAR KVK India"

    def search(self, query: str, max_results: int = 5) -> List[EvidenceSource]:
        """Performs HTTP search and extracts titles, links, and snippets."""
        scoped_query = self._build_scoped_query(query)
        headers = {
            "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36",
            "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
            "Accept-Language": "en-US,en;q=0.9,hi;q=0.8,gu;q=0.7",
        }

        try:
            with httpx.Client(timeout=self.timeout_seconds, follow_redirects=True) as client:
                resp = client.post(
                    self.endpoint_url,
                    data={"q": scoped_query, "b": ""},
                    headers=headers,
                )

                if resp.status_code != 200:
                    logger.warning(f"Web search returned HTTP {resp.status_code}")
                    return []

                return self._parse_html_results(resp.text, max_results)

        except Exception as e:
            logger.warning(f"Web search provider request failed ({e}). Returning empty list.")
            return []

    def _parse_html_results(self, html: str, max_results: int) -> List[EvidenceSource]:
        """Extracts search results from DuckDuckGo HTML response."""
        results: List[EvidenceSource] = []

        # Regex parsing for lightweight zero-dependency extraction
        # Matches result titles, snippets, and URLs
        result_blocks = re.findall(
            r'<div class="result results_links[^"]*".*?class="result__snippet[^"]*">(.*?)</div>',
            html,
            re.DOTALL | re.IGNORECASE,
        )

        # Alternative generic extraction if block regex doesn't match
        link_matches = re.findall(
            r'<a class="result__url"[^>]*href="([^"]+)"[^>]*>(.*?)</a>.*?<a class="result__snippet"[^>]*>(.*?)</a>',
            html,
            re.DOTALL | re.IGNORECASE,
        )

        for href, display_url, snippet in link_matches:
            # Unescape and clean text
            clean_snippet = re.sub(r"<[^>]+>", "", snippet).strip()
            clean_url = href.strip()

            # Handle DDG redirect uddg param
            if "uddg=" in clean_url:
                from urllib.parse import parse_qs, urlparse, unquote
                parsed = urlparse(clean_url)
                params = parse_qs(parsed.query)
                if "uddg" in params:
                    clean_url = unquote(params["uddg"][0])

            if not self.verifier.is_credible_source(clean_url):
                continue

            domain = self.verifier.extract_domain(clean_url)
            title = f"{domain} - Agricultural Advisory"

            results.append(
                EvidenceSource(
                    title=title,
                    url=clean_url,
                    snippet=clean_snippet[:350],
                    confidence_score=0.65,
                    source_type="online_web",
                )
            )

            if len(results) >= max_results:
                break

        return results

