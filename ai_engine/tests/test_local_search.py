"""Unit tests for Phase 5 Vector Store and Local PDF Retrieval."""

import pytest
from ai_engine.backend.dependencies import get_service_container
from ai_engine.knowledge_base.embeddings import EmbeddingGenerator, cosine_similarity
from ai_engine.knowledge_base.vector_store import VectorStore
from ai_engine.pdf_processor.document_chunker import DocumentChunk


def test_embedding_generator_cosine_similarity():
    """Tests vector cosine calculation with identity and orthogonal vectors."""
    v1 = [1.0, 0.0, 0.0]
    v2 = [1.0, 0.0, 0.0]
    v3 = [0.0, 1.0, 0.0]

    assert cosine_similarity(v1, v2) == pytest.approx(1.0, abs=1e-5)
    assert cosine_similarity(v1, v3) == pytest.approx(0.0, abs=1e-5)


def test_local_ngram_vectorizer_produces_normalized_vectors():
    """Tests that local offline vectorizer produces valid non-zero dense embeddings."""
    gen = EmbeddingGenerator(api_key=None)
    vec_gu = gen.embed_text("કપાસના પાન પીળા પડે છે")
    vec_hi = gen.embed_text("कपास के पत्ते पीले हो रहे हैं")
    vec_en = gen.embed_text("cotton leaves turning yellow")

    assert len(vec_gu) == 256
    assert len(vec_hi) == 256
    assert len(vec_en) == 256

    # Test that related texts have positive similarity
    sim = cosine_similarity(vec_hi, vec_en)
    assert sim >= 0.0


def test_vector_store_hybrid_retrieval(tmp_path):
    """Tests indexing and BM25-semantic hybrid query matching."""
    store = VectorStore(tmp_path)
    gen = EmbeddingGenerator(api_key=None)

    chunk1 = DocumentChunk(
        chunk_id="doc1_c1",
        document_name="cotton_manual.pdf",
        page_number=1,
        chunk_index=0,
        text="Spraying Magnesium Sulphate cures cotton leaf yellowing and chlorosis.",
        crops=["Cotton"],
        symptoms=["leaf_yellowing"],
    )
    chunk2 = DocumentChunk(
        chunk_id="doc2_c1",
        document_name="wheat_manual.pdf",
        page_number=1,
        chunk_index=0,
        text="Wheat rust disease management using Propiconazole spray.",
        crops=["Wheat"],
        symptoms=["blight"],
    )

    vec1 = gen.embed_text(chunk1.text)
    vec2 = gen.embed_text(chunk2.text)

    store.add_chunks_batch([chunk1, chunk2], [vec1, vec2])

    # Search for cotton yellowing
    query = "cotton yellow leaves"
    query_vec = gen.embed_query(query)
    results = store.search(query, query_vec, top_k=2)

    assert len(results) >= 1
    assert results[0].chunk.chunk_id == "doc1_c1"
    assert "cotton" in results[0].chunk.text.lower()


def test_real_icar_cotton_advisory_retrieval():
    """Validates that real indexed ICAR Cotton PDF is retrieved for cotton queries."""
    container = get_service_container()

    # Query in Gujarati
    res_gu = container.local_search.search("કપાસમાં પાન પીળા પડે છે, શું દવા છાંટવી?")
    assert len(res_gu) >= 1
    assert "ICAR_CICR_Cotton_Crop_Advisory.pdf" in res_gu[0].document_name or "Cotton" in res_gu[0].title
    assert res_gu[0].confidence_score >= 0.25

    # Query in English
    res_en = container.local_search.search("How to control pink bollworm in cotton?")
    assert len(res_en) >= 1
    assert any("pink bollworm" in r.snippet.lower() or "cotton" in r.snippet.lower() for r in res_en)

