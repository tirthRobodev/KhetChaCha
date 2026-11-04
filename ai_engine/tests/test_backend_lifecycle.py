"""Tests for persistent backend lifecycle, service container singleton, and token caching."""

import concurrent.futures
import pytest
from ai_engine.backend.dependencies import get_service_container
from ai_engine.gemini.gemini_client import GeminiClient
from ai_engine.gemini.response_generator import ResponseGenerator
from ai_engine.models.request_models import FarmerChatRequest
from ai_engine.search_engine.search_orchestrator import SearchOrchestrator, SearchOrchestratorResult


def test_service_container_singleton_lifespan():
    """Confirms get_service_container returns the exact same persistent instance without reallocating."""
    container1 = get_service_container()
    container2 = get_service_container()
    assert container1 is container2
    assert container1.vector_store is not None
    assert container1.gemini_client is not None
    assert container1.response_generator is not None


def test_safe_cache_avoids_duplicate_gemini_calls(monkeypatch):
    """Verifies that sending identical non-personalized queries hits the in-memory safe cache with 0 LLM calls."""
    container = get_service_container()
    call_counter = {"count": 0}

    # Patch Gemini client generate_content to track invocation count
    def mock_generate_content(prompt, system_instruction=None):
        call_counter["count"] += 1
        return '{"short_answer": "ટેસ્ટ ઉત્તર - લીમડાનું તેલ વાપરો.", "detailed_explanation": "વિગતવાર સલાહ.", "action_steps": ["નિયમિત નિરીક્ષણ"], "safety_precautions": ["માસ્ક પહેરો"]}'

    monkeypatch.setattr(container.gemini_client, "generate_content", mock_generate_content)
    monkeypatch.setattr(container.gemini_client, "_is_configured", True)

    req = FarmerChatRequest(query="ઘઉંમાં ઉધઈ નિયંત્રણ માટે શું કરવું?", language="gu")

    # First call: may execute generation and cache it
    resp1 = container.response_generator.generate_response(req)
    initial_calls = call_counter["count"]

    # Second call with identical query: must hit _safe_cache (0 new LLM calls)
    resp2 = container.response_generator.generate_response(req)
    assert call_counter["count"] == initial_calls
    assert resp2.short_answer == resp1.short_answer


def test_concurrent_chat_requests(monkeypatch):
    """Verifies backend handles multiple concurrent chat requests safely in parallel."""
    container = get_service_container()

    def mock_concurrent_gen(prompt, system_instruction=None):
        return '{"short_answer": "સફળ જવાબ - લીમડાનું અર્ક વાપરો.", "detailed_explanation": "વિગતવાર કૃષિ સલાહ.", "action_steps": ["નિયમિત નિરીક્ષણ"], "safety_precautions": ["માસ્ક પહેરો"]}'

    monkeypatch.setattr(container.gemini_client, "generate_content", mock_concurrent_gen)
    monkeypatch.setattr(container.gemini_client, "_is_configured", True)

    queries = [
        "કપાસમાં ગુલાબી ઈયળ માટે શું કરવું?",
        "મગફળીમાં સફેદ ઘેણનું નિયંત્રણ",
        "તડબૂચમાં વેલા સુકાઈ જાય છે",
        "ડાંગરમાં ગાભમારાની ઈયળનો ઉપાય",
        "ચણામાં પોપટા વેધક ઈયળ",
    ]

    def process_query(q):
        req = FarmerChatRequest(query=q, language="gu")
        return container.response_generator.generate_response(req)

    with concurrent.futures.ThreadPoolExecutor(max_workers=5) as executor:
        futures = [executor.submit(process_query, q) for q in queries]
        results = [f.result(timeout=10.0) for f in futures]

    assert len(results) == len(queries)
    for res in results:
        assert res.short_answer is not None
        assert len(res.short_answer) > 10
        assert res.language == "gu"


def test_quota_fallback_to_deterministic_advisory(monkeypatch):
    """Simulates Gemini HTTP 429 quota limit and confirms immediate graceful fallback without 500 error."""
    container = get_service_container()

    # Simulate quota exhaustion returning None
    monkeypatch.setattr(container.gemini_client, "generate_content", lambda *args, **kwargs: None)

    req = FarmerChatRequest(query="કપાસમાં થ્રીપ્સ જીવાત નિયંત્રણ", crop="cotton", language="gu")
    resp = container.response_generator.generate_response(req)

    assert resp is not None
    assert resp.short_answer is not None
    # Must contain safe agronomic advice (e.g. neem oil / bio-control)
    assert "લીમડા" in resp.short_answer or "નિયંત્રણ" in resp.short_answer or "કપાસ" in resp.short_answer
    assert resp.confidence_score > 0.0
