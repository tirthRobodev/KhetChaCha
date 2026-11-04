"""Gemini API client with configurable model, exponential backoff, timeout, and retry handling."""

from __future__ import annotations

import logging
import re
import time
from typing import Any, Dict, List, Optional

logger = logging.getLogger(__name__)


class GeminiClient:
    """Wrapper around Google Generative AI API with resiliency and quota handling patterns."""

    def __init__(
        self,
        api_key: Optional[str] = None,
        model_name: str = "gemini-3.8-flash",
        temperature: float = 0.2,
        max_output_tokens: int = 600,
        timeout_seconds: float = 30.0,
        max_retries: int = 3,
        initial_backoff_seconds: float = 2.0,
    ):
        self.api_key = api_key
        self.model_name = model_name
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
                logger.info(f"GeminiClient initialized successfully with model: {self.model_name}")
            except Exception as e:
                logger.warning(f"Failed to configure GeminiClient: {e}")

    @property
    def is_available(self) -> bool:
        """Returns True if Gemini API key is configured."""
        return self._is_configured

    def generate_content(
        self,
        prompt: str,
        system_instruction: Optional[str] = None,
    ) -> Optional[str]:
        """Calls Gemini API with exponential backoff retry and model fallback on transient quota errors."""
        if not self._is_configured:
            logger.info("GeminiClient: API key not provided or unconfigured. Returning None.")
            return None

        import google.generativeai as genai

        backoff = self.initial_backoff
        last_exception = None

        candidate_models = []
        # Put active working models with verified quota first
        for m in [self.model_name, "gemini-flash-lite-latest", "gemini-3.5-flash-lite"]:
            if m and m not in candidate_models:
                candidate_models.append(m)

        for attempt in range(1, self.max_retries + 1):
            for model_to_try in candidate_models:
                try:
                    generation_config = genai.types.GenerationConfig(
                        temperature=self.temperature,
                        max_output_tokens=self.max_output_tokens,
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
                            # Conservative heuristic: ~4 chars per token
                            self.prompt_tokens += max(1, len(prompt) // 4)
                            self.candidates_tokens += max(1, len(response.text) // 4)
                        return response.text

                    logger.warning(f"Empty response from Gemini on attempt {attempt} with {model_to_try}")
                except Exception as e:
                    last_exception = e
                    logger.warning(f"Gemini API call failed with {model_to_try}: {e}")
                    # Try next candidate model immediately without waiting
                    continue

            # Only back off if all candidate models failed in this round
            if attempt < self.max_retries:
                time.sleep(min(backoff, 4.0))
                backoff *= 1.5

        self.failed_requests += 1
        logger.error(f"All {self.max_retries} Gemini retries exhausted. Last error: {last_exception}")
        return None

    def get_usage_metrics(self) -> Dict[str, Any]:
        """Returns cumulative token and request metrics."""
        return {
            "total_requests": self.total_requests,
            "successful_requests": self.successful_requests,
            "failed_requests": self.failed_requests,
            "prompt_tokens": self.prompt_tokens,
            "candidates_tokens": self.candidates_tokens,
            "total_tokens": self.prompt_tokens + self.candidates_tokens,
        }
