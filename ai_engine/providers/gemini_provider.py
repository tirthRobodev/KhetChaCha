"""Google Gemini LLM Provider Implementation."""

from __future__ import annotations

import logging
import time
from typing import Any, Dict, List, Optional

from ai_engine.providers.base_provider import BaseLLMProvider

logger = logging.getLogger(__name__)


class GeminiProvider(BaseLLMProvider):
    """Production Gemini LLM Provider supporting resilient model fallbacks and retry mechanisms."""

    def __init__(
        self,
        api_key: Optional[str] = None,
        model_name: str = "gemini-2.5-flash",
        temperature: float = 0.2,
        max_output_tokens: int = 3072,
        timeout_seconds: float = 30.0,
        max_retries: int = 3,
        initial_backoff_seconds: float = 2.0,
    ):
        self.api_key = api_key
        self._model_name = model_name
        self.temperature = temperature
        self.max_output_tokens = max_output_tokens
        self.timeout_seconds = timeout_seconds
        self.max_retries = max_retries
        self.initial_backoff = initial_backoff_seconds

        # Token & Request Metrics Accounting
        self.total_requests: int = 0
        self.successful_requests: int = 0
        self.failed_requests: int = 0
        self.prompt_tokens: int = 0
        self.candidates_tokens: int = 0

        self._is_configured = False
        if self.api_key and self.api_key.strip():
            try:
                import google.generativeai as genai
                genai.configure(api_key=self.api_key)
                self._is_configured = True
                logger.info(f"GeminiProvider initialized successfully with model: {self._model_name}")
            except Exception as e:
                logger.warning(f"Failed to configure GeminiProvider: {e}")

    @property
    def provider_name(self) -> str:
        return "gemini"

    @property
    def model_name(self) -> str:
        return self._model_name

    @property
    def is_available(self) -> bool:
        return self._is_configured

    def generate_content(
        self,
        prompt: str,
        system_instruction: Optional[str] = None,
        max_output_tokens: Optional[int] = None,
    ) -> Optional[str]:
        """Calls Gemini API with exponential backoff and candidate model fallback."""
        if not self._is_configured:
            logger.info("GeminiProvider: API key not provided or unconfigured. Returning None.")
            return None

        import google.generativeai as genai

        backoff = self.initial_backoff
        last_exception = None
        effective_max_tokens = max_output_tokens or self.max_output_tokens

        candidate_models = []
        for m in [self._model_name, "gemini-2.5-flash", "gemini-flash-lite-latest", "gemini-3.5-flash-lite"]:
            if m and m not in candidate_models:
                candidate_models.append(m)

        for attempt in range(1, self.max_retries + 1):
            for model_to_try in candidate_models:
                try:
                    self.total_requests += 1
                    generation_config = genai.types.GenerationConfig(
                        temperature=self.temperature,
                        max_output_tokens=effective_max_tokens,
                    )

                    model = genai.GenerativeModel(
                        model_name=model_to_try,
                        system_instruction=system_instruction,
                        generation_config=generation_config,
                    )

                    response = model.generate_content(prompt, request_options={"timeout": self.timeout_seconds})
                    if response and response.text:
                        self.successful_requests += 1
                        if hasattr(response, "usage_metadata") and response.usage_metadata:
                            self.prompt_tokens += getattr(response.usage_metadata, "prompt_token_count", 0)
                            self.candidates_tokens += getattr(response.usage_metadata, "candidates_token_count", 0)
                        else:
                            self.prompt_tokens += max(1, len(prompt) // 4)
                            self.candidates_tokens += max(1, len(response.text) // 4)
                        return response.text

                    logger.warning(f"Empty response from Gemini on attempt {attempt} with {model_to_try}")
                except Exception as e:
                    last_exception = e
                    logger.warning(f"Gemini API call failed with {model_to_try}: {e}")
                    continue

            if attempt < self.max_retries:
                time.sleep(min(backoff, 4.0))
                backoff *= 1.5

        self.failed_requests += 1
        logger.error(f"All {self.max_retries} Gemini retries exhausted. Last error: {last_exception}")
        return None

    def get_usage_metrics(self) -> Dict[str, Any]:
        return {
            "provider": self.provider_name,
            "model": self.model_name,
            "total_requests": self.total_requests,
            "successful_requests": self.successful_requests,
            "failed_requests": self.failed_requests,
            "prompt_tokens": self.prompt_tokens,
            "candidates_tokens": self.candidates_tokens,
        }

