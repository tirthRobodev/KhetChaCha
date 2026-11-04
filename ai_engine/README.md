# 🌾 KhetChacha Farmer AI Text Intelligence Engine & Search Engine

> **High-Performance Agricultural Intelligence Engine for Indian Farmers**  
> Built with FastAPI, Google Gemini API, Local-First Vector Retrieval, and full support for all **22 8th Schedule Indian Languages + English**.

---

## 📋 Architectural Overview

The KhetChacha AI Engine is a self-contained Python intelligence subsystem situated inside the KhetChacha project (`ai_engine/`). It empowers the KhetChacha Flutter Android application with hyper-local, multilingual, and evidence-grounded agronomic advisory.

```
                              ┌──────────────────────────────────┐
                              │  KhetChacha Flutter Android App  │
                              │ (Chat UI, Location, Weather, GPS)│
                              └─────────────────┬────────────────┘
                                                │ REST API (JSON)
                                                ▼
                              ┌──────────────────────────────────┐
                              │       FastAPI Backend Server     │
                              │      (ai_engine/backend/main.py) │
                              └─────────────────┬────────────────┘
                                                │
                 ┌──────────────────────────────┴──────────────────────────────┐
                 ▼                                                             ▼
┌─────────────────────────────────┐                           ┌─────────────────────────────────┐
│       Language Engine           │                           │    Safety & Medicine Validator  │
│  - 22 Indian Languages + English│                           │  - CIBRC / ICAR Dosage Check    │
│  - Regional Vocabulary Lexicon  │                           │  - Banned Chemicals Detection   │
│  - Zero-dependency Detector     │                           │  - Mandatory PPE & Weather Alert│
└────────────────┬────────────────┘                           └────────────────┬────────────────┘
                 │                                                             │
                 ▼                                                             ▼
┌──────────────────────────────────────────────────────────────────────────────────────────────┐
│                      Phase 6 Search Engine Orchestrator                                     │
│  1. Classify query intent (Pest, Fertilizer, Market, Weather)                               │
│  2. Execute Local PDF Search FIRST (ICAR / SAU Handbooks)                                   │
│  3. Evaluate Local Confidence Score (>= 0.35 threshold)                                      │
│  4. If insufficient -> Trigger Online Fallback Search (ICAR/KVK Priority)                   │
└───────────────────────────────────────────────┬──────────────────────────────────────────────┘
                                                │
                 ┌──────────────────────────────┴──────────────────────────────┐
                 ▼                                                             ▼
┌─────────────────────────────────┐                           ┌─────────────────────────────────┐
│     Local PDF Vector Store      │                           │      Online Search Grounding    │
│  - data/agriculture_pdfs/       │                           │  - Gemini Google Search Grounding│
│  - Hybrid BM25 + Semantic Vector│                           │  - Configurable Web HTTP Scraper │
│  - SHA-256 Incremental Indexer  │                           │  - Domain Authority Verification │
└────────────────┬────────────────┘                           └────────────────┬────────────────┘
                 │                                                             │
                 └──────────────────────────────┬──────────────────────────────┘
                                                ▼
                              ┌──────────────────────────────────┐
                              │        Google Gemini LLM         │
                              │   (gemini-2.5-flash / Pro)       │
                              │  - Strict Farmer Voice (40-100w) │
                              │  - Numbered Action Steps         │
                              │  - Grounded Evidence Provenance  │
                              └──────────────────────────────────┘
```

---

## 🚀 Key Features

1. **Multilingual Precision across all 22 Indian Languages**:
   - Assamese, Bengali, Bodo, Dogri, Gujarati, Hindi, Kannada, Kashmiri, Konkani, Maithili, Malayalam, Manipuri, Marathi, Nepali, Odia, Punjabi, Sanskrit, Santali, Sindhi, Tamil, Telugu, Urdu, and English.
   - Script-specific Unicode boundary analysis and regional vocabulary expansion (`કપાસ`, `ઈયળ`, `પીળા પાન`, `નરમા`, `झुलसा`).

2. **Phase 6 Local-First Search Orchestrator**:
   - Queries locally indexed ICAR, KVK, and State Agricultural University (AAU, JAU, NAU, PAU) PDF manuals first.
   - Automatically falls back to online search providers when local evidence is insufficient or when real-time market/weather data is requested.

3. **CIBRC & ICAR Agricultural Safety Guardrails**:
   - Immediate interception of banned substances in India (Endosulfan, Monocrotophos, Paraquat).
   - Flagging of hazardous mixtures (e.g. Copper Oxychloride + Organophosphates, Trichoderma + synthetic fungicides).
   - Mandatory PPE and spray timing precautions (wind direction, mask, avoid midday sun).
   - Safe uncertainty handling prompting farmer to share leaf photo or call Kisan Call Centre (`1800-180-1551`).

4. **Zero-Dependency Vector Store**:
   - Fast, deterministic in-memory hybrid vector engine with BM25 keyword matching and persistent JSON serialization.
   - Operates 100% offline out-of-the-box without requiring heavy external C++ binaries or external vector database servers.

---

## 📂 Directory Structure

```
ai_engine/
├── .env.example              # Blueprint environment configuration
├── requirements.txt          # Python dependencies
├── backend/
│   ├── config.py             # BaseSettings configuration
│   ├── dependencies.py       # Dependency injection container
│   └── main.py               # FastAPI application with CORS and 6 endpoints
├── gemini/
│   ├── gemini_client.py      # Resilient Gemini API client with exponential backoff
│   ├── prompt_builder.py     # Farmer persona & prompt builder
│   ├── context_manager.py    # Multi-turn conversation memory
│   └── response_generator.py # Full advisory generation pipeline
├── knowledge_base/
│   ├── embeddings.py         # Dual-mode embeddings (Gemini + Local TF-IDF)
│   ├── vector_store.py       # Persistent hybrid vector store
│   ├── metadata_manager.py   # PDF SHA256 index manifest and catalog
│   └── retriever.py          # Multilingual hybrid retriever
├── language_engine/
│   ├── language_mapper.py    # 22 Scheduled Indian languages catalog
│   ├── language_detector.py  # Pure-Python script & marker detector
│   ├── regional_vocabulary.py# Agronomic dictionary & query expansion
│   └── response_language.py  # Native script system directives
├── pdf_processor/
│   ├── pdf_reader.py         # pypdf page extraction
│   ├── ocr_processor.py      # OCR fallback engine
│   ├── pdf_extractor.py      # Text cleaning and hyphen normalization
│   ├── document_chunker.py   # Sliding-window semantic chunker
│   └── pdf_indexer.py        # End-to-end PDF indexing pipeline
├── safety/
│   ├── agriculture_safety.py # PPE, weather, and bee alerts
│   ├── medicine_validation.py# CIBRC dosage validation & banned chemical check
│   └── uncertainty_handler.py# Low-confidence & photo triage
├── search_engine/
│   ├── providers/            # Gemini Grounding & Web search providers
│   ├── source_verifier.py    # Domain authority validator (ICAR, KVK, SAU)
│   ├── ranking.py            # Deduplication & credibility boosting
│   ├── local_search.py       # Local PDF search wrapper
│   ├── online_search.py      # Online search manager with TTL caching
│   ├── search_router.py      # Query classification
│   └── search_orchestrator.py# Local-first + online fallback decision tree
├── data/
│   ├── agriculture_pdfs/     # Local PDF repository
│   ├── vector_database/      # Serialized vector index
│   └── metadata/             # Index manifest & document catalog
├── scripts/
│   ├── generate_sample_pdfs.py # Generates official sample PDFs
│   ├── import_pdfs.py        # CLI tool to index new PDFs
│   ├── rebuild_index.py      # CLI tool to wipe and re-index
│   └── run_all_tests.py      # Master test runner
└── tests/                    # Complete pytest suite (31 tests)
```

---

## ⚡ Quick Start

### 1. Install Dependencies
```bash
cd ai_engine
pip install -r requirements.txt
```

### 2. Configure Environment
Copy `.env.example` to `.env` and insert your Gemini API Key:
```env
GEMINI_API_KEY=your_gemini_api_key_here
GEMINI_MODEL=gemini-2.5-flash
ONLINE_SEARCH_ENABLED=true
LOCAL_SEARCH_MIN_SCORE=0.35
```

### 3. Generate & Index Agricultural PDFs
```bash
python scripts/generate_sample_pdfs.py
python scripts/import_pdfs.py --force
```

### 4. Run Test Suite
```bash
python scripts/run_all_tests.py
# Or run pytest directly:
pytest tests/ -v
```

### 5. Launch FastAPI Backend
```bash
uvicorn backend.main:app --host 0.0.0.0 --port 8000 --reload
```
Interactive API documentation will be available at:  
👉 `http://localhost:8000/docs`

---

## 🌐 API Endpoints Reference

| Method | Endpoint | Description |
|---|---|---|
| `GET` | `/health` | Real-time system health, Gemini status, and indexed vector counts |
| `POST` | `/api/v1/chat` | Main farmer chat endpoint (multilingual, grounded, safety-validated) |
| `POST` | `/api/v1/search` | Direct search against verified ICAR/KVK online sources |
| `POST` | `/api/v1/knowledge/search` | Search locally indexed PDF manuals with BM25 + semantic vector similarity |
| `POST` | `/api/v1/knowledge/upload` | Upload & index a new agricultural PDF extension guide |
| `GET` | `/api/v1/knowledge/status` | Statistics and catalog of currently indexed PDF documents |

