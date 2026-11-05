"""Unit tests for pluggable LLM Providers (Gemini & OpenAI)."""

import pytest
from ai_engine.backend.config import Settings
from ai_engine.backend.dependencies import ServiceContainer
from ai_engine.providers.base_provider import BaseLLMProvider
from ai_engine.providers.gemini_provider import GeminiProvider
from ai_engine.providers.openai_provider import OpenAIProvider


def test_gemini_provider_unconfigured():
    provider = GeminiProvider(api_key=None)
    assert not provider.is_available
    assert provider.provider_name == "gemini"
    assert provider.model_name == "gemini-2.5-flash"
    assert provider.generate_content("test prompt") is None
    metrics = provider.get_usage_metrics()
    assert metrics["provider"] == "gemini"
    assert metrics["total_requests"] == 0


def test_openai_provider_unconfigured():
    provider = OpenAIProvider(api_key=None)
    assert not provider.is_available
    assert provider.provider_name == "openai"
    assert provider.model_name == "gpt-4o-mini"
    assert provider.generate_content("test prompt") is None
    metrics = provider.get_usage_metrics()
    assert metrics["provider"] == "openai"
    assert metrics["total_requests"] == 0


def test_openai_provider_mock_response(monkeypatch):
    provider = OpenAIProvider(api_key="sk-test-mock-key")
    assert provider.is_available

    class MockResponse:
        status_code = 200
        def json(self):
            return {
                "choices": [{"message": {"content": '{"short_answer": "Test answer"}'}}],
                "usage": {"prompt_tokens": 15, "completion_tokens": 25},
            }

    class MockClient:
        def __enter__(self):
            return self
        def __exit__(self, *args):
            pass
        def post(self, *args, **kwargs):
            return MockResponse()

    import httpx
    monkeypatch.setattr(httpx, "Client", lambda **kwargs: MockClient())

    result = provider.generate_content("Hello")
    assert result == '{"short_answer": "Test answer"}'
    metrics = provider.get_usage_metrics()
    assert metrics["successful_requests"] == 1
    assert metrics["prompt_tokens"] == 15
    assert metrics["candidates_tokens"] == 25


def test_service_container_openai_switching():
    settings = Settings(
        active_llm_provider="openai",
        openai_api_key="sk-test-container-key",
        openai_model="gpt-4o",
    )
    container = ServiceContainer(settings)
    assert container.llm_provider.provider_name == "openai"
    assert container.llm_provider.model_name == "gpt-4o"
    assert container.response_generator.llm_provider == container.llm_provider

