"""PDF Indexer orchestrating reading, OCR fallback, cleaning, chunking, and embedding."""

from __future__ import annotations

import logging
from pathlib import Path
from typing import Any, Dict, List, Optional

from ai_engine.knowledge_base.embeddings import EmbeddingGenerator
from ai_engine.knowledge_base.metadata_manager import MetadataManager
from ai_engine.knowledge_base.vector_store import VectorStore
from ai_engine.language_engine.regional_vocabulary import identify_query_attributes
from ai_engine.pdf_processor.document_chunker import DocumentChunk, DocumentChunker
from ai_engine.pdf_processor.ocr_processor import OCRProcessor
from ai_engine.pdf_processor.pdf_extractor import PDFTextExtractor
from ai_engine.pdf_processor.pdf_reader import PDFReader

logger = logging.getLogger(__name__)


class PDFIndexer:
    """Manages the end-to-end ingestion pipeline from raw PDFs to indexed vectors."""

    def __init__(
        self,
        pdf_dir: Path | str,
        vector_store: VectorStore,
        metadata_manager: MetadataManager,
        embedding_generator: EmbeddingGenerator,
        ocr_processor: Optional[OCRProcessor] = None,
    ):
        self.pdf_dir = Path(pdf_dir)
        self.pdf_dir.mkdir(parents=True, exist_ok=True)
        self.vector_store = vector_store
        self.metadata_manager = metadata_manager
        self.embedding_generator = embedding_generator
        self.pdf_reader = PDFReader()
        self.extractor = PDFTextExtractor()
        self.chunker = DocumentChunker()
        self.ocr_processor = ocr_processor or OCRProcessor()

    def index_single_file(self, file_path: Path | str, force: bool = False) -> Dict[str, Any]:
        """Indexes a single PDF document."""
        path = Path(file_path)
        if not path.exists() or path.suffix.lower() != ".pdf":
            raise FileNotFoundError(f"Valid PDF file not found at: {path}")

        filename = path.name

        if not force and self.metadata_manager.is_file_indexed_and_current(path):
            logger.info(f"Skipping already indexed and unchanged file: {filename}")
            return {
                "filename": filename,
                "status": "skipped",
                "message": "File already indexed and current.",
            }

        logger.info(f"Indexing PDF: {filename}...")

        # Remove old chunks if previously indexed
        self.vector_store.remove_document_chunks(filename)

        # Read pages
        pages = self.pdf_reader.read_pdf(path)
        if not pages:
            logger.warning(f"No pages extracted from {filename}")
            return {
                "filename": filename,
                "status": "empty",
                "message": "No pages extracted.",
            }

        all_chunks: List[DocumentChunk] = []
        all_crops: List[str] = []
        all_symptoms: List[str] = []
        global_chunk_idx = 0

        for page in pages:
            raw_text = page.get("text", "") if isinstance(page, dict) else getattr(page, "text", "")
            page_num = page.get("page_number", 1) if isinstance(page, dict) else getattr(page, "page_number", 1)

            # If raw text is too short, attempt OCR
            if self.extractor.is_low_density_page(raw_text, min_char_count=40):
                if self.ocr_processor.is_available():
                    logger.info(f"Low text density on page {page_num} of {filename}. Running OCR...")
                    ocr_text = self.ocr_processor.ocr_pdf_page(path, page_num)
                    if ocr_text and len(ocr_text) > len(raw_text):
                        raw_text = ocr_text

            clean_text = self.extractor.clean_extracted_text(raw_text)
            if not clean_text.strip():
                continue

            # Identify taxonomy tags
            attrs = identify_query_attributes(clean_text)
            all_crops.extend(attrs.get("crops", []))
            all_symptoms.extend(attrs.get("symptoms", []))

            # Chunk page text
            page_chunks = self.chunker.chunk_page_text(
                document_name=filename,
                page_number=page_num,
                page_text=clean_text,
                global_chunk_start_idx=global_chunk_idx,
            )
            all_chunks.extend(page_chunks)
            global_chunk_idx += len(page_chunks)

        if not all_chunks:
            logger.warning(f"No valid text chunks produced for {filename}")
            return {
                "filename": filename,
                "status": "no_chunks",
                "message": "No valid text chunks produced from document.",
            }

        # Generate embeddings in batch
        chunk_texts = [c.text for c in all_chunks]
        vectors = self.embedding_generator.embed_documents(chunk_texts)

        # Add to vector store
        self.vector_store.add_chunks_batch(all_chunks, vectors)
        self.vector_store.save()

        # Update metadata manifest
        self.metadata_manager.register_indexed_document(
            file_path=path,
            page_count=len(pages),
            chunk_count=len(all_chunks),
            crops_detected=all_crops,
            symptoms_detected=all_symptoms,
        )

        logger.info(f"Successfully indexed {filename}: {len(pages)} pages, {len(all_chunks)} chunks.")
        return {
            "filename": filename,
            "status": "success",
            "pages": len(pages),
            "chunks": len(all_chunks),
            "crops": sorted(list(set(all_crops))),
            "symptoms": sorted(list(set(all_symptoms))),
        }

    def index_all_pdfs(self, force: bool = False) -> Dict[str, Any]:
        """Scans the configured PDF directory and indexes all PDF files."""
        pdf_files = list(self.pdf_dir.glob("*.pdf"))
        logger.info(f"Found {len(pdf_files)} PDF files in {self.pdf_dir}")

        indexed_count = 0
        skipped_count = 0
        error_count = 0
        results: List[Dict[str, Any]] = []

        for pdf_path in sorted(pdf_files):
            try:
                res = self.index_single_file(pdf_path, force=force)
                results.append(res)
                if res.get("status") == "success":
                    indexed_count += 1
                elif res.get("status") == "skipped":
                    skipped_count += 1
                else:
                    error_count += 1
            except Exception as e:
                logger.error(f"Error indexing {pdf_path.name}: {e}")
                results.append({"filename": pdf_path.name, "status": "error", "error": str(e)})
                error_count += 1

        return {
            "total_files": len(pdf_files),
            "indexed": indexed_count,
            "skipped": skipped_count,
            "errors": error_count,
            "results": results,
            "catalog_summary": self.metadata_manager.get_catalog_summary(),
        }

    def rebuild_all(self) -> Dict[str, Any]:
        """Clears existing vector store and metadata, then indexes all PDFs from scratch."""
        logger.warning("Rebuilding vector store and metadata catalog from scratch...")
        self.vector_store.clear()
        self.metadata_manager.clear()
        return self.index_all_pdfs(force=True)
