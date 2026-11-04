import re
from typing import List, Dict, Any
from pathlib import Path
from .pdf_reader import pdf_reader, PdfReader
from .ocr_processor import ocr_processor, OcrProcessor


class PdfExtractor:
    """Cleans, normalizes, and validates extracted PDF text."""

    def __init__(self, reader: PdfReader = pdf_reader, ocr: OcrProcessor = ocr_processor):
        self.reader = reader
        self.ocr = ocr

    def clean_text(self, raw_text: str) -> str:
        """Removes duplicate whitespace, fixes broken hyphens, removes non-printable characters."""
        if not raw_text:
            return ""

        # Normalize line endings
        text = raw_text.replace("\r\n", "\n").replace("\r", "\n")

        # Join words hyphenated across lines
        text = re.sub(r'(\w+)-\s*\n\s*(\w+)', r'\1\2', text)

        # Remove repeated header/footer boilerplate (e.g. "Page 1 of 12")
        text = re.sub(r'(?i)page\s+\d+\s+of\s+\d+', '', text)

        # Collapse excessive newlines and whitespace
        text = re.sub(r'\n{3,}', '\n\n', text)
        text = re.sub(r'[ \t]{2,}', ' ', text)

        return text.strip()

    def clean_extracted_text(self, raw_text: str) -> str:
        """Alias for clean_text."""
        return self.clean_text(raw_text)

    def is_low_density_page(self, text: str, min_char_count: int = 40) -> bool:
        """Checks if a page has very low character density indicating scanned or image content."""
        cleaned = self.clean_text(text)
        return len(cleaned) < min_char_count

    def extract_document(self, file_path: Path) -> List[Dict[str, Any]]:
        """
        Extracts and cleans all pages of a PDF document.
        Detects if pages are scanned (low character density < 40 chars) and flags them.
        """
        raw_pages = self.reader.read_file(file_path)
        processed_pages = []

        for p in raw_pages:
            cleaned = self.clean_text(p["text"])
            is_scanned = len(cleaned) < 40

            processed_pages.append({
                "page_number": p["page_number"],
                "text": cleaned,
                "is_scanned": is_scanned,
                "filename": p["filename"],
                "file_path": p["file_path"],
                "character_count": len(cleaned)
            })

        return processed_pages


# Ergonomic aliases
PDFTextExtractor = PdfExtractor
pdf_extractor = PdfExtractor()
