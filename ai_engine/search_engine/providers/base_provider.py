"""Abstract base class for search engine providers."""

from __future__ import annotations

from abc import ABC, abstractmethod
from typing import List
from ai_engine.models.response_models import EvidenceSource


class BaseSearchProvider(ABC):
    """Abstract interface that all search providers must implement."""

    @abstractmethod
    def search(self, query: str, max_results: int = 5) -> List[EvidenceSource]:
        """Executes a search query and returns verified EvidenceSource objects."""
        pass

    @property
    @abstractmethod
    def provider_name(self) -> str:
        """Returns the unique name of the provider."""
        pass

