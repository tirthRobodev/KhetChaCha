"""Regression tests for multilingual UTF-8 encoding — Gujarati, Hindi, Punjabi, Tamil.

These tests verify:
1. _parse_gemini_output never corrupts non-ASCII text (the unicode_escape bug is gone).
2. FarmerChatResponse serialises to JSON with intact Indic script.
3. The JSON response round-trips cleanly (simulate what Flutter receives).
4. TTS text field is also clean Unicode.
"""
from __future__ import annotations

import json
import sys

import pytest


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _make_response_generator():
    """Instantiate ResponseGenerator with mocked dependencies (no live Gemini)."""
    from unittest.mock import MagicMock
    from ai_engine.gemini.response_generator import ResponseGenerator

    gemini = MagicMock()
    gemini.is_available = False  # offline mode — avoids live API calls
    gemini.generate_content.return_value = None

    orchestrator = MagicMock()
    result = MagicMock()
    result.sources = []
    result.is_evidence_sufficient = False
    result.strategy_used = "local_only"
    orchestrator.retrieve_evidence.return_value = result

    return ResponseGenerator(gemini_client=gemini, search_orchestrator=orchestrator)


GUJARATI_SAMPLE = "કપાસમાં ગુલાબી ઈયળ"
GUJARATI_CHARS  = ["ક", "પ", "સ", "ા", "ં", "ગ", "ઈ", "ળ"]

HINDI_SAMPLE    = "कपास में गुलाबी बोलवर्म"
HINDI_CHARS     = ["क", "प", "स", "म", "ग", "ब", "र"]

PUNJABI_SAMPLE  = "ਕਪਾਹ ਵਿੱਚ ਗੁਲਾਬੀ ਸੁੰਡੀ"
PUNJABI_CHARS   = ["ਕ", "ਪ", "ਹ", "ਗ", "ਲ", "ਬ"]

TAMIL_SAMPLE    = "பருத்தியில் இளஞ்சிவப்பு புழு"
TAMIL_CHARS     = ["ப", "ர", "த", "இ", "ள", "ச", "வ", "ழ"]


# ---------------------------------------------------------------------------
# 1. _parse_gemini_output must NOT corrupt Indic script
# ---------------------------------------------------------------------------

class TestParseGeminiOutputEncoding:
    """The critical encoding path: JSON text from Gemini → parsed dict."""

    def _parse(self, rg, raw_json_text: str) -> dict:
        return rg._parse_gemini_output(raw_json_text, "gu")

    def test_gujarati_direct_json_roundtrip(self):
        """Gujarati text in a valid JSON payload must survive _parse_gemini_output."""
        rg = _make_response_generator()
        answer = "કપાસમાં ગુલાબી ઈયળ (Pink Bollworm) ના ઉપદ્રવ માટે ક્લોરાન્ટ્રાનિલિપ્રોલ 18.5% SC વાપરો."
        payload = json.dumps({"short_answer": answer, "detailed_explanation": answer})
        result = self._parse(rg, payload)
        assert result["short_answer"] == answer, (
            f"Gujarati text was corrupted!\n"
            f"Expected: {answer!r}\n"
            f"Got:      {result['short_answer']!r}"
        )
        for ch in GUJARATI_CHARS:
            assert ch in result["short_answer"], f"Gujarati character '{ch}' missing from answer"

    def test_hindi_direct_json_roundtrip(self):
        """Hindi Devanagari in valid JSON must survive _parse_gemini_output."""
        rg = _make_response_generator()
        answer = "कपास में गुलाबी बोलवर्म के लिए क्लोरेंट्रानिलिप्रोल 18.5% एससी का प्रयोग करें।"
        payload = json.dumps({"short_answer": answer, "detailed_explanation": answer})
        result = self._parse(rg, payload)
        assert result["short_answer"] == answer, (
            f"Hindi text was corrupted!\nExpected: {answer!r}\nGot: {result['short_answer']!r}"
        )
        for ch in HINDI_CHARS:
            assert ch in result["short_answer"], f"Hindi character '{ch}' missing"

    def test_punjabi_direct_json_roundtrip(self):
        """Punjabi Gurmukhi in valid JSON must survive _parse_gemini_output."""
        rg = _make_response_generator()
        answer = "ਕਪਾਹ ਵਿੱਚ ਗੁਲਾਬੀ ਸੁੰਡੀ ਲਈ ਕਲੋਰਾਂਟ੍ਰਾਨਿਲਿਪ੍ਰੋਲ ਦੀ ਵਰਤੋਂ ਕਰੋ।"
        payload = json.dumps({"short_answer": answer, "detailed_explanation": answer})
        result = self._parse(rg, payload)
        assert result["short_answer"] == answer, (
            f"Punjabi text was corrupted!\nExpected: {answer!r}\nGot: {result['short_answer']!r}"
        )
        for ch in PUNJABI_CHARS:
            assert ch in result["short_answer"], f"Punjabi character '{ch}' missing"

    def test_tamil_direct_json_roundtrip(self):
        """Tamil script in valid JSON must survive _parse_gemini_output."""
        rg = _make_response_generator()
        answer = "பருத்தியில் இளஞ்சிவப்பு புழு தாக்குதலுக்கு குளோரான்ட்ரானிலிப்ரோல் பயன்படுத்தவும்."
        payload = json.dumps({"short_answer": answer, "detailed_explanation": answer})
        result = self._parse(rg, payload)
        assert result["short_answer"] == answer, (
            f"Tamil text was corrupted!\nExpected: {answer!r}\nGot: {result['short_answer']!r}"
        )
        for ch in TAMIL_CHARS:
            assert ch in result["short_answer"], f"Tamil character '{ch}' missing"

    def test_unicode_escape_sequences_decoded_correctly(self):
        """\\uXXXX escape sequences from Gemini JSON output must decode to correct Unicode."""
        rg = _make_response_generator()
        expected = "કપાસના પાકમાં રોગ નિયંત્રણ અને ઉપાયો"
        escaped_json = json.dumps({"short_answer": expected, "detailed_explanation": "cotton disease management"}, ensure_ascii=True)
        result = self._parse(rg, escaped_json)
        assert result["short_answer"] == expected, (
            f"Unicode escape not decoded: {result['short_answer']!r}"
        )

    def test_no_latin1_corruption_pattern(self):
        """The corrupted pattern 'àª' must NOT appear anywhere in the output."""
        rg = _make_response_generator()
        answer = "કૃષિ સલાહ: ખેડૂત મિત્ર, ઓર્ગેનિક ખેતી અપનાવો."
        payload = json.dumps({"short_answer": answer, "detailed_explanation": answer})
        result = self._parse(rg, payload)
        corrupted_marker = "\u00e0\u00aa"  # 'àª' — the Latin-1 misread of Gujarati UTF-8
        assert corrupted_marker not in result["short_answer"], (
            "Latin-1 corruption pattern 'àª' found in output — unicode_escape bug is still present!"
        )

    def test_regression_old_unicode_escape_would_corrupt(self):
        """Directly verify the old bug: bytes(str, 'utf-8').decode('unicode_escape') corrupts Gujarati."""
        gujarati = "કપાસ"
        # The OLD (broken) method:
        try:
            broken = bytes(gujarati, "utf-8").decode("unicode_escape", "ignore")
        except Exception:
            broken = ""
        # The NEW (correct) method:
        correct_via_json = json.loads('"' + gujarati + '"')
        # Verify the old method was indeed broken
        assert broken != gujarati, "Expected old method to corrupt the string — test assumption failed"
        # Verify the new method is correct
        assert correct_via_json == gujarati, f"json.loads method failed: {correct_via_json!r}"


# ---------------------------------------------------------------------------
# 2. FarmerChatResponse JSON serialisation preserves Indic script
# ---------------------------------------------------------------------------

class TestFarmerChatResponseEncoding:
    """Verify Pydantic model serialises Unicode cleanly."""

    def test_gujarati_pydantic_serialisation(self):
        from ai_engine.models.response_models import FarmerChatResponse
        answer = "કૃષિ AI સલાહ: ખેડૂત મિત્ર!"
        resp = FarmerChatResponse(
            success=True, language="gu", language_name="Gujarati",
            answer=answer, short_answer=answer,
            action_steps=["ખેતરનું નિરીક્ષણ કરો."],
            safety_precautions=["માસ્ક અને મોજા પહેરો."],
        )
        # Serialise to JSON the same way FastAPI does (Pydantic v2)
        json_str = resp.model_dump_json()
        parsed = json.loads(json_str)
        assert parsed["answer"] == answer, f"Gujarati corrupted in Pydantic serialisation: {parsed['answer']!r}"

    def test_hindi_pydantic_serialisation(self):
        from ai_engine.models.response_models import FarmerChatResponse
        answer = "कृषि AI सलाह: किसान भाई!"
        resp = FarmerChatResponse(
            success=True, language="hi", language_name="Hindi",
            answer=answer, short_answer=answer,
        )
        json_str = resp.model_dump_json()
        parsed = json.loads(json_str)
        assert parsed["answer"] == answer, f"Hindi corrupted: {parsed['answer']!r}"

    def test_punjabi_pydantic_serialisation(self):
        from ai_engine.models.response_models import FarmerChatResponse
        answer = "ਕ੍ਰਿਸ਼ੀ AI ਸਲਾਹ: ਕਿਸਾਨ ਮਿੱਤਰ!"
        resp = FarmerChatResponse(
            success=True, language="pa", language_name="Punjabi",
            answer=answer, short_answer=answer,
        )
        json_str = resp.model_dump_json()
        parsed = json.loads(json_str)
        assert parsed["answer"] == answer, f"Punjabi corrupted: {parsed['answer']!r}"

    def test_tamil_pydantic_serialisation(self):
        from ai_engine.models.response_models import FarmerChatResponse
        answer = "விவசாய AI ஆலோசனை: விவசாயி நண்பர்!"
        resp = FarmerChatResponse(
            success=True, language="ta", language_name="Tamil",
            answer=answer, short_answer=answer,
        )
        json_str = resp.model_dump_json()
        parsed = json.loads(json_str)
        assert parsed["answer"] == answer, f"Tamil corrupted: {parsed['answer']!r}"

    def test_tts_text_field_encoding(self):
        """TTS text must carry the same correctly-encoded Unicode as the main answer."""
        from ai_engine.models.response_models import FarmerChatResponse
        answer = "ખેડૂત મિત્ર, ઓર્ગેનિક ખેતી અપનાવો."
        resp = FarmerChatResponse(
            success=True, language="gu", language_name="Gujarati",
            answer=answer, short_answer=answer,
        )
        # TTS text is derived from the answer field
        json_str = resp.model_dump_json()
        parsed = json.loads(json_str)
        # Verify no Latin-1 corruption in answer (used for TTS)
        corrupted = "\u00e0\u00aa"
        assert corrupted not in parsed.get("answer", ""), "TTS source field has Latin-1 corruption"
        assert corrupted not in parsed.get("short_answer", ""), "TTS short_answer has Latin-1 corruption"


# ---------------------------------------------------------------------------
# 3. Full offline generate_response round-trip for Gujarati query
# ---------------------------------------------------------------------------

class TestGenerateResponseEncoding:
    """End-to-end offline response generation must preserve Gujarati."""

    def test_gujarati_offline_response_no_corruption(self):
        from ai_engine.models.request_models import FarmerChatRequest
        rg = _make_response_generator()
        req = FarmerChatRequest(query=GUJARATI_SAMPLE, language="gu")
        response = rg.generate_response(req)
        answer = response.answer or response.short_answer or ""
        corrupted = "\u00e0\u00aa"
        assert corrupted not in answer, (
            f"Latin-1 corruption 'àª' found in Gujarati offline response: {answer[:200]!r}"
        )
        # The offline response always includes Gujarati text from _generate_offline_response
        assert any(ch in answer for ch in GUJARATI_CHARS), (
            f"No Gujarati characters found in offline response: {answer[:200]!r}"
        )

    def test_hindi_offline_response_no_corruption(self):
        from ai_engine.models.request_models import FarmerChatRequest
        rg = _make_response_generator()
        req = FarmerChatRequest(query=HINDI_SAMPLE, language="hi")
        response = rg.generate_response(req)
        answer = response.answer or response.short_answer or ""
        corrupted_hi = "\u00e0\u00a4"  # Latin-1 misread of Hindi Devanagari bytes
        assert corrupted_hi not in answer, (
            f"Latin-1 corruption found in Hindi offline response: {answer[:200]!r}"
        )

    def test_action_steps_no_corruption(self):
        """Action steps in Gujarati must also be clean Unicode."""
        from ai_engine.models.request_models import FarmerChatRequest
        rg = _make_response_generator()
        req = FarmerChatRequest(query=GUJARATI_SAMPLE, language="gu")
        response = rg.generate_response(req)
        corrupted = "\u00e0\u00aa"
        for step in response.action_steps:
            assert corrupted not in step, f"Latin-1 corruption in action_step: {step!r}"

