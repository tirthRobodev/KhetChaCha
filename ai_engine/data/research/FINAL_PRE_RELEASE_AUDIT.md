# KHETCHACHA 1.0.0+1 — FINAL PRE-RELEASE SAFETY AND BACKEND AUDIT

**Date**: 2026-11-05  
**Auditor**: Senior Agricultural AI Safety Auditor & Backend Systems Engineer  
**Workspace**: `D:\KhetChaCha`  
**Backend Host**: `http://10.180.217.194:8000`  
**Git Branch**: `main` (Preserved intact; Zero Git commits/pushes performed)  

---

## 1. EXECUTIVE SUMMARY & AUDIT VERDICT

| Category | Audit Result | Status |
| :--- | :---: | :---: |
| **Agricultural Dosage Verification** | 100% verified against ICAR-CICR official bulletin; 0 contradictions | **PASSED** |
| **Semantic Cache Safety** | Personalization bypass verified; 0 cross-farmer data leakage; invalidation on upload | **PASSED** |
| **Chemical Safety & Registration** | 13 verified label-authorized chemicals; 14 unverified quarantined; weedicides blocked | **PASSED** |
| **Backend Process Lifecycle** | Single persistent process via WMI; safe PID tracking; duplicate prevention; clean stop | **PASSED** |
| **Token Usage & Measurement** | Deterministic & cache hits consume strictly 0 tokens; measured live LLM usage | **PASSED** |
| **Python Regression Tests** | 60 / 60 passed (100%) | **PASSED** |
| **Flutter Mobile Tests** | 217 / 217 passed (100%) | **PASSED** |
| **Flutter Code Analysis** | 0 warnings, 0 errors | **PASSED** |
| **Pre-Release Audit Verdict** | **PRODUCTION READY (Zero Critical Agricultural Safety Blockers)** | **APPROVED** |

---

## 2. SECTION 1 — AGRICULTURAL DOSAGE AUDIT

### 2.1 Inspection of DosageConsistencyValidator
The `DosageConsistencyValidator` (`ai_engine/safety/dosage_validator.py`) was audited line-by-line:
1. **Multi-Section Consistency**: Validates that all chemical and fertilizer quantities mentioned in `short_answer`, `action_steps`, and `detailed_explanation` match within $\pm 35\%$ tolerance or else triggers a `Contradictory Dosage Rejection` alert.
2. **Reconciliation & Sanitization**: When a response contains conflicting numbers (e.g. an overdose of 500 g/pump alongside 150 g/pump), `reconcile_and_sanitize_response` automatically sanitizes the text to the authoritative ICAR standard.
3. **No Approval Based Only on Mathematics**: Dosage values are checked against the `AUTHORITATIVE_DOSAGE_REGISTRY` (containing CIBRC/ICAR verified formulation, allowable range, and target crop). A mathematically consistent dose for an unapproved or unregistered chemical is strictly rejected.

### 2.2 Cotton Magnesium Sulphate Calculations & Official Evidence
- **Official Source**: ICAR - Central Institute for Cotton Research (CICR) *National Agricultural Advisory Bulletin: Comprehensive Cotton Health & Pest Management* (`ICAR_CICR_Cotton_Crop_Advisory.pdf`, Page 1, Chunk `ICAR_CICR_Cotton_Crop_Advisory.pdf_p1_c0`).
- **Official Bulletin Text**:
  > *"Recommended Advisory: Spray Magnesium Sulphate (MgSO4) @ 10 grams per liter of water (150 grams per 15-liter pump) along with Urea @ 10-15 grams per liter. Apply 2 sprays at 15-day intervals during flowering and boll development."*
- **Mathematical Dilution Verification**:
  $$\text{Standard Concentration} = 1.0\% = 10.0\text{ g/L}$$
  $$\text{Knapsack Pump Volume} = 15\text{ Liters}$$
  $$\text{Pump Dosage} = 10.0\text{ g/L} \times 15\text{ L} = 150.0\text{ g}$$
  $$\text{Acreage Rate} = 1.5\text{ kg per acre in } 150\text{--}200\text{ L water}$$
- **Verification Result**: Every action step, short answer, and detailed explanation in Gujarati (`૧૫ લીટર પંપમાં ૧૫૦ ગ્રામ`), Hindi (`१५ लीटर पंप में १५० ग्राम`), and English (`150 g per 15-liter pump`) agrees 100% with zero deviation.

---

## 3. SECTION 2 — SEMANTIC CACHE SAFETY AUDIT

### 3.1 Cache Key Structure & Isolation
The in-memory semantic cache (`_safe_cache`) enforces strict partition boundaries:
- **Cache Key Format**: `f"{active_lang}:{request.crop or ''}:{clean_q}"`
- **Language Isolation**: Gujarati queries (`gu`), Hindi queries (`hi`), and English queries (`en`) generate completely isolated keys. A Gujarati question will never return a Hindi answer.
- **Crop Isolation**: A query for "leaf yellowing" under Cotton will never retrieve cached advice for Tomato or Groundnut.
- **Source Retention**: Cached responses retain their full array of `EvidenceSource` objects, preserving document names, page citations, and relevance scores.

### 3.2 Personalization & Cross-Farmer Privacy Guard
To ensure personalized advice (e.g. fertilizer calculations for specific land holdings or crop stages) is never cross-served to unrelated farmers:
```python
is_personalized = bool(
    request.land_size
    or request.land_area
    or request.session_id
    or (request.crop_age_days and request.crop_age_days > 0)
    or request.soil_type
    or request.farmer_district
    or request.farmer_state
)
```
- **Rule**: If `is_personalized == True`, the query **bypasses the cache on lookup** and is **never stored in the cache on write**.

### 3.3 Cache Invalidation on Knowledge Ingestion
- `ResponseGenerator.clear_cache()` is hooked into the `/api/v1/knowledge/upload` endpoint in `ai_engine/backend/main.py`.
- Whenever a new agricultural PDF is uploaded or indexed, the entire response cache is immediately purged, preventing stale advisories.

---

## 4. SECTION 3 — CHEMICAL SAFETY & REGISTRATION AUDIT

### 4.1 Agrochemical Inventory Audit
An exhaustive scan of all 27 chemical treatment records across the knowledge base was performed via `audit_chemical_inventory.py`:

| Status | Count | Characteristics |
| :--- | :---: | :--- |
| **Verified Authoritative** | **13** | Label-authorized by CIBRC / ICAR package of practices; exact active ingredient, formulation, dosage per pump/acre, application method, Pre-Harvest Interval (PHI in days), and Personal Protective Equipment (PPE) specified. |
| **Quarantined (`needs_review`)** | **14** | Placeholder or university circular mentions requiring label verification. Strictly prohibited from being recommended as exact synthetic sprays. |

#### Verified Chemical Recommendations Inventory:
1. **Cotton** — Magnesium Sulphate ($10\text{ g/L}$, $150\text{ g/pump}$, $\text{PHI: } 0\text{d}$) — *Magnesium deficiency / Lalio*
2. **Cotton** — Emamectin Benzoate 5% SG ($9\text{--}10\text{ g/pump}$, $\text{PHI: } 15\text{d}$) — *Pink Bollworm*
3. **Cotton** — Chlorantraniliprole 18.5% SC ($6\text{--}7\text{ ml/pump}$, $\text{PHI: } 20\text{d}$) — *Bollworm Complex*
4. **Groundnut** — Mancozeb 75% WP ($30\text{--}35\text{ g/pump}$, $\text{PHI: } 15\text{d}$) — *Tikka Leaf Spot*
5. **Groundnut** — Hexaconazole 5% EC ($25\text{--}30\text{ ml/pump}$, $\text{PHI: } 20\text{d}$) — *Tikka & Rust*
6. **Wheat** — Propiconazole 25% EC ($15\text{--}20\text{ ml/pump}$, $\text{PHI: } 30\text{d}$) — *Yellow & Brown Rust*
7. **Wheat** — Tebuconazole 25.9% EC ($15\text{ ml/pump}$, $\text{PHI: } 30\text{d}$) — *Rusts & Foliar Blight*
8. **Chickpea** — Chlorantraniliprole 18.5% SC ($5\text{--}6\text{ ml/pump}$, $\text{PHI: } 11\text{d}$) — *Pod Borer*
9. **Chickpea** — Emamectin Benzoate 5% SG ($8\text{--}10\text{ g/pump}$, $\text{PHI: } 14\text{d}$) — *Pod Borer*
10. **Tomato** — Mancozeb 75% WP ($30\text{--}35\text{ g/pump}$, $\text{PHI: } 5\text{d}$) — *Early Blight*
11. **Tomato** — Azoxystrobin + Difenoconazole 18.2% + 11.4% SC ($15\text{ ml/pump}$, $\text{PHI: } 5\text{d}$) — *Early & Late Blight*
12. **Mango** — Imidacloprid 17.8% SL ($5\text{--}6\text{ ml/pump}$, $\text{PHI: } 45\text{d}$) — *Mango Hopper*
13. **Mango** — Thiamethoxam 25% WG ($6\text{--}8\text{ g/pump}$, $\text{PHI: } 30\text{d}$) — *Mango Hopper*

### 4.2 Prohibited Chemical Interception
Non-selective herbicides and prohibited weedicides (Glyphosate, Paraquat, Atrazine, 2,4-D, Endosulfan, Monocrotophos) are strictly intercepted by `DosageConsistencyValidator.validate_crop_chemical_authorization` in English, Gujarati (`ગ્લાયફોસેટ`, `પેરાક્વોટ`), and Hindi (`ग्लिफोसेट`, `पैराक्वॉट`), raising Critical Safety Alerts.

---

## 5. SECTION 4 — BACKEND PROCESS LIFECYCLE AUDIT

### 5.1 Process Spawning & Independence
- **WMI Detached Spawning**: In `ai_engine/start_khetchacha.ps1`, the server process is launched via `Invoke-CimMethod -ClassName Win32_Process -MethodName Create`, ensuring the process survives PowerShell session termination.
- **Port 8000 Listener Binding**: Process listens persistently on `0.0.0.0:8000` with PID stored in `ai_engine/khetchacha_backend.pid`.

### 5.2 Single Instance & Duplicate Prevention
- `start_khetchacha.ps1` queries `http://127.0.0.1:8000/health` prior to launching.
- If the server is already active and healthy, it reports `[OK] KhetChacha Backend is ALREADY RUNNING and healthy!`, refreshes the PID, and exits with code 0 without spawning duplicate processes.

### 5.3 Safe Process Termination
- `ai_engine/stop_khetchacha.ps1` safely terminates only the specific KhetChacha PID listening on port 8000, cleans up `khetchacha_backend.pid`, and releases the port.

---

## 6. SECTION 5 — TOKEN USAGE & EMPIRICAL MEASUREMENT AUDIT

Measured using `ai_engine/tests/measure_token_usage.py`:

```text
================================================================================
                 KHETCHACHA TOKEN USAGE & CACHE HIT AUDIT                       
================================================================================

[TEST 1] Deterministic Ambiguous Query (Uncertainty Clarification)
  Strategy: local_only
  Gemini API Calls: 0 (Expected: 0)
  Total Gemini Tokens: 0 (Expected: 0)

[TEST 2] Deterministic Cotton Leaf Yellowing Differential Diagnosis
  Strategy: differential_diagnosis
  Gemini API Calls: 0 (Expected: 0)
  Total Gemini Tokens: 0 (Expected: 0)

[TEST 3] Cache Hit on Repeat Query
  Cache Hits: 1 (Expected: 1)
  Gemini API Calls: 0 (Expected: 0)
  Total Gemini Tokens: 0 (Expected: 0)

[TEST 4] Personalized Query Bypass (Must Not Poison or Read from Generic Cache)
  Cache Hits after personalized query: 1 (Must remain 1)
  Is Personalized: True -> Bypassed cross-farmer cache successfully.

[TEST 5] Live Standard Grounded Query (Measuring Real Tokens)
  Gemini API Calls: 1
  Prompt Tokens: 1,855
  Candidates Tokens: 1,192
  Total Tokens: 3,047

[TEST 6] Cache Hit on Grounded Query
  Cache Hits: 2 (Expected: 2)
  Delta Tokens Consumed on Cache Hit: 0 (0 tokens)

================================================================================
                    TOKEN USAGE AUDIT: ALL CHECKS PASSED                        
================================================================================
```

---

## 7. SECTION 6 — REGRESSION TEST OUTPUTS

### 7.1 Python Automated Tests
```powershell
python -m pytest ai_engine/tests/ -v
```
```text
============================= test session starts =============================
collected 60 items

ai_engine/tests/test_agricultural_quality.py::test_cotton_leaf_yellowing_differential_diagnosis_gujarati PASSED [  1%]
ai_engine/tests/test_agricultural_quality.py::test_cotton_leaf_yellowing_differential_diagnosis_english PASSED [  3%]
ai_engine/tests/test_agricultural_quality.py::test_magnesium_deficiency_dosage_exactness PASSED [  5%]
ai_engine/tests/test_agricultural_quality.py::test_waterlogging_drainage_advisory_no_chemical_spray PASSED [  6%]
ai_engine/tests/test_agricultural_quality.py::test_contradictory_dosage_rejection_and_reconciliation PASSED [  8%]
ai_engine/tests/test_agricultural_quality.py::test_unsupported_chemical_recommendation_rejection PASSED [ 10%]
ai_engine/tests/test_agricultural_quality.py::test_insufficient_evidence_prohibits_exact_dose PASSED [ 11%]
ai_engine/tests/test_agricultural_safety_audit.py::test_unsafe_or_unsupported_chemical_recommendations PASSED [ 13%]
ai_engine/tests/test_agricultural_safety_audit.py::test_missing_official_source_evidence PASSED [ 15%]
ai_engine/tests/test_agricultural_safety_audit.py::test_incorrect_dosage_units PASSED [ 16%]
ai_engine/tests/test_agricultural_safety_audit.py::test_missing_safety_warnings PASSED [ 18%]
ai_engine/tests/test_agricultural_safety_audit.py::test_gujarati_numerical_translation PASSED [ 20%]
ai_engine/tests/test_agricultural_safety_audit.py::test_diagnosis_uncertainty_and_single_ambiguous_symptoms PASSED [ 21%]
ai_engine/tests/test_agricultural_safety_audit.py::test_gemini_quota_and_error_fallbacks PASSED [ 23%]
ai_engine/tests/test_agricultural_safety_audit.py::test_retrieval_source_traceability PASSED [ 25%]
ai_engine/tests/test_agricultural_safety_audit.py::test_duplicate_research_records PASSED [ 26%]
ai_engine/tests/test_agricultural_safety_audit.py::test_incorrect_verified_status PASSED [ 28%]
ai_engine/tests/test_agricultural_safety_audit.py::test_no_api_key_exposure PASSED [ 30%]
ai_engine/tests/test_api.py::test_health_endpoint PASSED                 [ 31%]
ai_engine/tests/test_api.py::test_knowledge_status_endpoint PASSED       [ 33%]
ai_engine/tests/test_api.py::test_knowledge_search_endpoint PASSED       [ 35%]
ai_engine/tests/test_api.py::test_farmer_chat_endpoint_gujarati PASSED   [ 36%]
ai_engine/tests/test_api.py::test_farmer_chat_endpoint_hindi PASSED      [ 38%]
ai_engine/tests/test_api.py::test_farmer_chat_endpoint_ambiguity_clarification PASSED [ 40%]
ai_engine/tests/test_api.py::test_pdf_upload_endpoint PASSED             [ 41%]
ai_engine/tests/test_backend_lifecycle.py::test_service_container_singleton_lifespan PASSED [ 43%]
ai_engine/tests/test_backend_lifecycle.py::test_safe_cache_avoids_duplicate_gemini_calls PASSED [ 45%]
ai_engine/tests/test_backend_lifecycle.py::test_concurrent_chat_requests PASSED [ 46%]
ai_engine/tests/test_backend_lifecycle.py::test_quota_fallback_to_deterministic_advisory PASSED [ 48%]
ai_engine/tests/test_crop_knowledge.py::test_catalogue_covers_all_300_input_entries PASSED [ 50%]
ai_engine/tests/test_crop_knowledge.py::test_catalogue_reconciliation_multi_category_overlaps PASSED [ 51%]
ai_engine/tests/test_crop_knowledge.py::test_gold_standard_crop_profiles_schema_valid PASSED [ 53%]
ai_engine/tests/test_crop_knowledge.py::test_disease_and_pest_records_schema_valid PASSED [ 55%]
ai_engine/tests/test_crop_knowledge.py::test_zero_banned_chemicals_in_knowledge_base PASSED [ 56%]
ai_engine/tests/test_crop_knowledge.py::test_source_traceability PASSED  [ 58%]
ai_engine/tests/test_crop_knowledge.py::test_research_manifest_integrity PASSED [ 60%]
ai_engine/tests/test_languages.py::test_all_22_scheduled_languages_plus_english_present PASSED [ 61%]
ai_engine/tests/test_languages.py::test_language_lookups PASSED          [ 63%]
ai_engine/tests/test_languages.py::test_language_detector_indic_scripts PASSED [ 65%]
ai_engine/tests/test_languages.py::test_regional_vocabulary_attribute_identification PASSED [ 66%]
ai_engine/tests/test_languages.py::test_regional_query_expansion PASSED  [ 68%]
ai_engine/tests/test_languages.py::test_response_language_formatting_directives PASSED [ 70%]
ai_engine/tests/test_local_search.py::test_embedding_generator_cosine_similarity PASSED [ 71%]
ai_engine/tests/test_local_search.py::test_local_ngram_vectorizer_produces_normalized_vectors PASSED [ 73%]
ai_engine/tests/test_local_search.py::test_vector_store_hybrid_retrieval PASSED [ 75%]
ai_engine/tests/test_local_search.py::test_real_icar_cotton_advisory_retrieval PASSED [ 76%]
ai_engine/tests/test_online_search.py::test_source_verifier_authority_tiers PASSED [ 78%]
ai_engine/tests/test_online_search.py::test_source_verifier_boost_multipliers PASSED [ 80%]
ai_engine/tests/test_online_search.py::test_search_ranker_deduplication_and_boosting PASSED [ 81%]
ai_engine/tests/test_online_search.py::test_search_router_query_classification PASSED [ 83%]
ai_engine/tests/test_online_search.py::test_search_orchestrator_local_first_decision PASSED [ 85%]
ai_engine/tests/test_pdf_processing.py::test_pdf_reader_extracts_pages PASSED [ 86%]
ai_engine/tests/test_pdf_processing.py::test_text_extractor_normalizes_text PASSED [ 88%]
ai_engine/tests/test_pdf_processing.py::test_document_chunker_sliding_window PASSED [ 90%]
ai_engine/tests/test_pdf_processing.py::test_metadata_manager_hash_computation PASSED [ 91%]
ai_engine/tests/test_safety.py::test_banned_substances_detection PASSED  [ 93%]
ai_engine/tests/test_safety.py::test_hazardous_chemical_mixtures PASSED  [ 95%]
ai_engine/tests/test_safety.py::test_dosage_validation_limits PASSED     [ 96%]
ai_engine/tests/test_safety.py::test_safety_engine_mandatory_ppe_injection PASSED [ 98%]
ai_engine/tests/test_safety.py::test_uncertainty_handler_for_ambiguous_queries PASSED [100%]

======================= 60 passed, 3 warnings in 39.40s =======================
```

### 7.2 Flutter Mobile Tests
```powershell
flutter test
```
```text
00:22 +217: All tests passed!
```

### 7.3 Flutter Static Analysis
```powershell
flutter analyze lib/ test/
```
```text
Analyzing 2 items...
No issues found! (ran in 10.2s)
```

---

## 8. SECTION 7 — UNRESOLVED RISKS & RELEASE READINESS EVALUATION

### 8.1 Unresolved Risks Analysis
- **Unverified Crop Catalogue Entries (265 entries)**: Currently quarantined with `status: not_started` or `needs_review`. The system safely prohibits exact synthetic chemical recommendations for these entries, defaulting to bio-control (Neem, Trichoderma) and directing farmers to local KVK agronomists and the Kisan Call Centre (`1800-180-1551`).
- **Network / Remote API Outages**: Tested and hardened. On HTTP 429 quota exhaustion or HTTP 504 gateway timeout, the engine immediately activates local deterministic synthesis without raising HTTP 500 errors.

### 8.2 Production Readiness Verdict
**RELEASE READY**: All agricultural safety, dosage mathematical dilution, process persistence, and token optimization directives are fully met. The working tree is preserved without any Git commits or pushes.

