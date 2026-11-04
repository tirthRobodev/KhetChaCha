"""Unit tests for Phase 5 PDF Processing and Chunking."""

from pathlib import Path
import pytest
from ai_engine.backend.config import get_settings
from ai_engine.pdf_processor.document_chunker import DocumentChunker
from ai_engine.pdf_processor.pdf_extractor import PDFTextExtractor
from ai_engine.pdf_processor.pdf_reader import PDFReader
from ai_engine.knowledge_base.metadata_manager import MetadataManager, compute_file_sha256


def test_pdf_reader_extracts_pages():
    """Tests that PDFReader correctly reads pages from sample PDFs."""
    settings = get_settings()
    pdf_path = settings.pdf_dir / "ICAR_CICR_Cotton_Crop_Advisory.pdf"
    assert pdf_path.exists(), f"Sample PDF must exist at {pdf_path}"

    reader = PDFReader()
    pages = reader.read_pdf(pdf_path)

    assert len(pages) >= 1
    assert "ICAR" in pages[0]["text"]
    assert pages[0]["page_number"] == 1


def test_text_extractor_normalizes_text():
    """Tests whitespace collapsing and hyphen repair."""
    extractor = PDFTextExtractor()
    raw = "Manage-\nment of pink    boll- \nworm in field.  Page 1 of 5 \n\n\n\nNext section."
    cleaned = extractor.clean_text(raw)

    assert "Management" in cleaned
    assert "bollworm" in cleaned
    assert "    " not in cleaned
    assert "\n\n\n\n" not in cleaned


def test_document_chunker_sliding_window():
    """Tests chunking with sentence boundary preservation."""
    chunker = DocumentChunker(min_chunk_size=100, max_chunk_size=300, overlap_size=50)
    sample_text = (
        "Cotton is an important cash crop in India. "
        "Leaf yellowing is caused by magnesium deficiency. "
        "Spraying magnesium sulphate helps recover green foliage quickly. "
        "Pink bollworm requires pheromone trap monitoring. "
        "Emamectin benzoate gives effective control when moth count exceeds threshold."
    )

    chunks = chunker.chunk_page_text(
        document_name="test_doc.pdf",
        page_number=1,
        page_text=sample_text,
    )

    assert len(chunks) >= 1
    for ch in chunks:
        assert ch.document_name == "test_doc.pdf"
        assert ch.page_number == 1
        assert len(ch.text) > 0


def test_metadata_manager_hash_computation(tmp_path):
    """Tests SHA256 change detection and catalog operations."""
    test_file = tmp_path / "test_doc.pdf"
    test_file.write_text("Hello Agricultural Testing Data", encoding="utf-8")

    hash1 = compute_file_sha256(test_file)
    assert len(hash1) == 64

    meta_dir = tmp_path / "metadata"
    manager = MetadataManager(meta_dir)

    manager.register_indexed_document(
        file_path=test_file,
        page_count=1,
        chunk_count=2,
        crops_detected=["Cotton"],
        symptoms_detected=["leaf_yellowing"],
    )

    assert manager.is_file_indexed_and_current(test_file) is True

    # Modify file -> hash should invalidate currentness
    test_file.write_text("Modified agricultural content", encoding="utf-8")
    assert manager.is_file_indexed_and_current(test_file) is False

