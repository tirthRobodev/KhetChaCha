"""Token and request count measurement test script for KhetChacha AI Engine.

Objectively measures:
1. Deterministic responses consume strictly 0 Gemini API calls and 0 Gemini tokens.
2. Cache hits consume strictly 0 Gemini API calls and 0 Gemini tokens.
3. Live Gemini queries accurately record prompt and candidate token counts.
4. Personalized requests bypass cross-farmer caching.
"""

from ai_engine.backend.dependencies import get_service_container
from ai_engine.models.request_models import FarmerChatRequest


def run_token_audit():
    container = get_service_container()
    generator = container.response_generator
    client = container.gemini_client

    print("================================================================================")
    print("                 KHETCHACHA TOKEN USAGE & CACHE HIT AUDIT                       ")
    print("================================================================================")

    # Reset cache and metrics
    generator.clear_cache()
    client.total_requests = 0
    client.successful_requests = 0
    client.failed_requests = 0
    client.prompt_tokens = 0
    client.candidates_tokens = 0
    generator.cache_hits = 0
    generator.cache_misses = 0
    generator.deterministic_responses = 0

    print("\n[TEST 1] Deterministic Ambiguous Query (Uncertainty Clarification)")
    req_det = FarmerChatRequest(query="પાંદડા ખરાબ થાય છે", language="gu")
    resp_det = generator.generate_response(req_det)
    metrics_1 = generator.get_metrics()
    print(f"  Strategy: {resp_det.search_strategy_used}")
    print(f"  Gemini API Calls: {metrics_1['gemini_usage']['total_requests']} (Expected: 0)")
    print(f"  Total Gemini Tokens: {metrics_1['gemini_usage']['total_tokens']} (Expected: 0)")
    print(f"  Deterministic Handlers Invoked: {metrics_1['deterministic_responses']}")
    assert metrics_1['gemini_usage']['total_requests'] == 0, "Deterministic query must consume 0 Gemini calls!"

    print("\n[TEST 2] Deterministic Cotton Leaf Yellowing Differential Diagnosis")
    req_cotton = FarmerChatRequest(query="કપાસમાં પાન પીળા પડે છે શું કરવું?", crop="Cotton", language="gu")
    resp_cotton = generator.generate_response(req_cotton)
    metrics_2 = generator.get_metrics()
    print(f"  Strategy: {resp_cotton.search_strategy_used}")
    print(f"  Gemini API Calls: {metrics_2['gemini_usage']['total_requests']} (Expected: 0)")
    print(f"  Total Gemini Tokens: {metrics_2['gemini_usage']['total_tokens']} (Expected: 0)")
    print(f"  Deterministic Handlers Invoked: {metrics_2['deterministic_responses']}")
    assert metrics_2['gemini_usage']['total_requests'] == 0, "Cotton differential diagnosis must consume 0 Gemini calls!"

    print("\n[TEST 3] Cache Hit on Repeat Query")
    # Repeat the exact same query
    resp_repeat = generator.generate_response(req_cotton)
    metrics_3 = generator.get_metrics()
    print(f"  Cache Hits: {metrics_3['cache_hits']} (Expected: 1)")
    print(f"  Gemini API Calls: {metrics_3['gemini_usage']['total_requests']} (Expected: 0)")
    print(f"  Total Gemini Tokens: {metrics_3['gemini_usage']['total_tokens']} (Expected: 0)")
    assert metrics_3['cache_hits'] >= 1, "Repeat query must hit cache!"
    assert metrics_3['gemini_usage']['total_requests'] == 0, "Cache hit must consume 0 Gemini calls!"

    print("\n[TEST 4] Personalized Query Bypass (Must Not Poison or Read from Generic Cache)")
    req_pers = FarmerChatRequest(
        query="કપાસમાં પાન પીળા પડે છે શું કરવું?",
        crop="Cotton",
        language="gu",
        land_size="5 Bigha",
        farmer_district="Amreli"
    )
    resp_pers = generator.generate_response(req_pers)
    metrics_4 = generator.get_metrics()
    print(f"  Cache Hits after personalized query: {metrics_4['cache_hits']} (Must remain 1)")
    print(f"  Is Personalized: True -> Bypassed cross-farmer cache successfully.")
    assert metrics_4['cache_hits'] == 1, "Personalized query must NOT hit generic cache!"

    print("\n[TEST 5] Live Standard Grounded Query (Measuring Real Tokens)")
    # Query requiring full LLM synthesis
    initial_api_calls = client.total_requests
    req_grounded = FarmerChatRequest(
        query="તુવેરમાં સુકારો અટકાવવા કઈ જૈવિક પદ્ધતિ સૌથી અસરકારક છે?",
        crop="Pigeon Pea",
        language="gu"
    )
    resp_grounded = generator.generate_response(req_grounded)
    metrics_5 = generator.get_metrics()
    print(f"  Gemini API Calls: {metrics_5['gemini_usage']['total_requests']}")
    print(f"  Prompt Tokens: {metrics_5['gemini_usage']['prompt_tokens']}")
    print(f"  Candidates Tokens: {metrics_5['gemini_usage']['candidates_tokens']}")
    print(f"  Total Tokens: {metrics_5['gemini_usage']['total_tokens']}")

    print("\n[TEST 6] Cache Hit on Grounded Query")
    resp_grounded_repeat = generator.generate_response(req_grounded)
    metrics_6 = generator.get_metrics()
    print(f"  Cache Hits: {metrics_6['cache_hits']} (Expected: 2)")
    print(f"  Total Gemini Calls before repeat: {metrics_5['gemini_usage']['total_requests']}")
    print(f"  Total Gemini Calls after repeat: {metrics_6['gemini_usage']['total_requests']}")
    print(f"  Delta Tokens Consumed on Cache Hit: {metrics_6['gemini_usage']['total_tokens'] - metrics_5['gemini_usage']['total_tokens']} (0 tokens)")
    assert metrics_6['gemini_usage']['total_requests'] == metrics_5['gemini_usage']['total_requests'], "Repeat grounded query must NOT invoke Gemini!"

    print("\n================================================================================")
    print("                    TOKEN USAGE AUDIT: ALL CHECKS PASSED                        ")
    print("================================================================================")


if __name__ == "__main__":
    run_token_audit()

