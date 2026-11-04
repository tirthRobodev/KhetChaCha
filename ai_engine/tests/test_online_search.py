"""Unit tests for Phase 6 Search Engine, Source Verification, and Orchestration."""

import pytest
from ai_engine.backend.dependencies import get_service_container
from ai_engine.models.response_models import EvidenceSource
from ai_engine.search_engine.ranking import SearchRanker
from ai_engine.search_engine.search_router import SearchRouter
from ai_engine.search_engine.source_verifier import SourceVerifier


def test_source_verifier_authority_tiers():
    """Validates domain authority classification for ICAR, SAUs, and government portals."""
    verifier = SourceVerifier()

    assert verifier.get_authority_tier("https://icar.org.in/advisory/cotton") == 1
    assert verifier.get_authority_tier("https://kvk.icar.gov.in/bulletin") == 1
    assert verifier.get_authority_tier("https://aau.in/plant-pathology") == 1
    assert verifier.get_authority_tier("https://agricoop.nic.in/schemes") == 1
    assert verifier.get_authority_tier("https://vikaspedia.in/agriculture") == 2
    assert verifier.get_authority_tier("https://random-commercial-blog.com/news") == 3


def test_source_verifier_boost_multipliers():
    """Confirms ICAR and government domains receive authority boosts."""
    verifier = SourceVerifier()

    boost_icar = verifier.calculate_authority_multiplier("https://icar.org.in/cotton")
    boost_portal = verifier.calculate_authority_multiplier("https://vikaspedia.in/farming")
    boost_generic = verifier.calculate_authority_multiplier("https://generic-site.com")

    assert boost_icar == 1.4
    assert boost_portal == 1.15
    assert boost_generic == 1.0


def test_search_ranker_deduplication_and_boosting():
    """Tests that duplicates are purged and authority sources are ranked on top."""
    ranker = SearchRanker()

    src1 = EvidenceSource(
        title="Generic Advice",
        url="https://generic-site.com/cotton",
        snippet="Apply spray",
        confidence_score=0.70,
        source_type="online_web",
    )
    src2 = EvidenceSource(
        title="Duplicate Generic Advice",
        url="https://generic-site.com/cotton?ref=123",
        snippet="Apply spray",
        confidence_score=0.65,
        source_type="online_web",
    )
    src3 = EvidenceSource(
        title="ICAR Official Advisory",
        url="https://icar.org.in/cotton-bulletin",
        snippet="ICAR verified dose",
        confidence_score=0.68,
        source_type="online_web",
    )

    ranked = ranker.rank_and_deduplicate([src1, src2, src3], max_results=3)

    assert len(ranked) == 2  # src2 deduped against src1
    # ICAR source (0.68 * 1.4 = 0.952) should be ranked first ahead of generic (0.70 * 1.0 = 0.70)
    assert ranked[0].title == "ICAR Official Advisory"
    assert ranked[0].confidence_score > ranked[1].confidence_score


def test_search_router_query_classification():
    """Tests query categorization across agricultural domains."""
    pest_res = SearchRouter.classify_query("મારા કપાસમાં ગુલાબી ઈયળ આવી ગઈ છે")
    assert pest_res["category"] == "pest_and_disease"
    assert pest_res["prioritize_local"] is True

    fert_res = SearchRouter.classify_query("गेहूं में यूरिया और डीएपी खाद कब डालनी चाहिए?")
    assert fert_res["category"] == "soil_and_fertilizer"

    market_res = SearchRouter.classify_query("અમદાવાદ એપીએમસી કપાસનો આજનો બજાર ભાવ શું છે?")
    assert market_res["category"] == "market_and_pricing"
    assert market_res["prioritize_local"] is False


def test_search_orchestrator_local_first_decision():
    """Validates that local ICAR PDF is chosen first for recognized crop issues."""
    container = get_service_container()
    res = container.search_orchestrator.retrieve_evidence("કપાસમાં પાન પીળા પડે છે")

    assert res.strategy_used in {"local_only", "hybrid_fallback"}
    assert len(res.sources) >= 1
    assert res.local_results_count >= 1

