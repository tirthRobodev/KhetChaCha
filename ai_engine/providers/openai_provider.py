"""OpenAI / ChatGPT LLM Provider Implementation."""

from __future__ import annotations

import json
import logging
import time
from typing import Any, Dict, List, Optional

from ai_engine.providers.base_provider import BaseLLMProvider

logger = logging.getLogger(__name__)


class OpenAIProvider(BaseLLMProvider):
    """OpenAI API Provider for ChatGPT models (e.g. gpt-4o, gpt-4o-mini).

    Uses resilient HTTP client (httpx or urllib) with zero client-side key exposure.
    """

    def __init__(
        self,
        api_key: Optional[str] = None,
        model_name: str = "gpt-4o-mini",
        api_base_url: str = "https://api.openai.com/v1",
        temperature: float = 0.2,
        max_output_tokens: int = 3072,
        timeout_seconds: float = 30.0,
        max_retries: int = 3,
        initial_backoff_seconds: float = 2.0,
    ):
        self.api_key = api_key
        self._model_name = model_name
        self.api_base_url = api_base_url.rstrip("/")
        self.temperature = temperature
        self.max_output_tokens = max_output_tokens
        self.timeout_seconds = timeout_seconds
        self.max_retries = max_retries
        self.initial_backoff = initial_backoff_seconds

        self.total_requests: int = 0
        self.successful_requests: int = 0
        self.failed_requests: int = 0
        self.prompt_tokens: int = 0
        self.completion_tokens: int = 0

        self._is_configured = bool(self.api_key and self.api_key.strip())
        if self._is_configured:
            logger.info(f"OpenAIProvider configured with model: {self._model_name}")

    @property
    def provider_name(self) -> str:
        return "openai"

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
        """Calls OpenAI Chat Completions API with exponential backoff and error handling."""
        if not self._is_configured:
            logger.info("OpenAIProvider: API key not provided or unconfigured. Returning None.")
            return None

        messages: List[Dict[str, str]] = []
        if system_instruction:
            messages.append({"role": "system", "content": system_instruction})
        messages.append({"role": "user", "content": prompt})

        effective_max_tokens = max_output_tokens or self.max_output_tokens
        payload: Dict[str, Any] = {
            "model": self._model_name,
            "messages": messages,
            "temperature": self.temperature,
            "max_tokens": effective_max_tokens,
            "response_format": {"type": "json_object"},
        }

        endpoint = f"{self.api_base_url}/chat/completions"
        headers = {
            "Authorization": f"Bearer {self.api_key}",
            "Content-Type": "application/json",
        }

        backoff = self.initial_backoff
        last_exception = None

        for attempt in range(1, self.max_retries + 1):
            try:
                self.total_requests += 1
                try:
                    import httpx
                    with httpx.Client(timeout=self.timeout_seconds) as client:
                        resp = client.post(endpoint, headers=headers, json=payload)
                        if resp.status_code == 200:
                            data = resp.json()
                            content = data["choices"][0]["message"]["content"]
                            self.successful_requests += 1
                            usage = data.get("usage", {})
                            self.prompt_tokens += usage.get("prompt_tokens", 0)
                            self.completion_tokens += usage.get("completion_tokens", 0)
                            return content
                        else:
                            last_exception = Exception(f"HTTP {resp.status_code}: {resp.text}")
                            logger.warning(f"OpenAI API call returned status {resp.status_code}: {resp.text}")
                except ImportError:
                    # Fallback to standard library urllib
                    import urllib.request
                    req_data = json.dumps(payload).encode("utf-8")
                    req = urllib.request.Request(endpoint, data=req_data, headers=headers, method="POST")
                    with urllib.request.urlopen(req, timeout=self.timeout_seconds) as response:
                        if response.status == 200:
                            body = response.read().decode("utf-8")
                            data = json.loads(body)
                            content = data["choices"][0]["message"]["content"]
                            self.successful_requests += 1
                            usage = data.get("usage", {})
                            self.prompt_tokens += usage.get("prompt_tokens", 0)
                            self.completion_tokens += usage.get("completion_tokens", 0)
                            return content
            except Exception as e:
                last_exception = e
                logger.warning(f"OpenAI API attempt {attempt} failed: {e}")

            if attempt < self.max_retries:
                time.sleep(min(backoff, 4.0))
                backoff *= 1.5

        self.failed_requests += 1
        logger.error(f"All {self.max_retries} OpenAI retries exhausted. Last error: {last_exception}")
        return None

    def get_usage_metrics(self) -> Dict[str, Any]:
        return {
            "provider": self.provider_name,
            "model": self.model_name,
            "total_requests": self.total_requests,
            "successful_requests": self.successful_requests,
            "failed_requests": self.failed_requests,
            "prompt_tokens": self.prompt_tokens,
            "candidates_tokens": self.completion_tokens,
        }

