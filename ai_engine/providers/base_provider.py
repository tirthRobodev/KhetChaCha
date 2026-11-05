"""Abstract Base Class for LLM Providers (Gemini, OpenAI, etc.)."""

from __future__ import annotations

from abc import ABC, abstractmethod
from typing import Any, Dict, Optional


class BaseLLMProvider(ABC):
    """Abstract interface defining required methods for all LLM providers."""

    @property
    @abstractmethod
    def provider_name(self) -> str:
        """Returns the identifier of the provider (e.g. 'gemini', 'openai')."""
        pass

    @property
    @abstractmethod
    def model_name(self) -> str:
        """Returns the active model name."""
        pass

    @property
    @abstractmethod
    def is_available(self) -> bool:
        """Returns True if the provider is properly configured with valid credentials."""
        pass

    @abstractmethod
    def generate_content(
        self,
        prompt: str,
        system_instruction: Optional[str] = None,
        max_output_tokens: Optional[int] = None,
    ) -> Optional[str]:
        """Generates text completion based on prompt and system instructions.

        Returns string response or None if generation failed.
        """
        pass

    @abstractmethod
    def get_usage_metrics(self) -> Dict[str, Any]:
        """Returns provider-specific usage metrics (requests, tokens, errors)."""
        pass

