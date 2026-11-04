from pathlib import Path
from typing import List, Dict, Any, Optional
import pypdf


class PdfReader:
    """Extracts raw text and metadata page-by-page from agricultural PDF documents."""

    def read_file(self, file_path: Path | str) -> List[Dict[str, Any]]:
        """
        Reads a PDF file from disk and returns a list of page dicts:
        [{"page_number": 1, "text": "...", "page_count": 10}, ...]
        """
        path = Path(file_path)
        if not path.exists():
            raise FileNotFoundError(f"PDF file not found: {path}")

        pages_data = []
        try:
            reader = pypdf.PdfReader(str(path))
            total_pages = len(reader.pages)

            for idx, page in enumerate(reader.pages):
                page_text = page.extract_text() or ""
                pages_data.append({
                    "page_number": idx + 1,
                    "text": page_text,
                    "page_count": total_pages,
                    "filename": path.name,
                    "file_path": str(path),
                })
        except Exception as e:
            raise RuntimeError(f"Failed to read PDF '{path.name}': {e}") from e

        return pages_data

    def read_pdf(self, file_path: Path | str) -> List[Dict[str, Any]]:
        """Alias for read_file."""
        return self.read_file(file_path)


# Ergonomic aliases
PDFReader = PdfReader
pdf_reader = PdfReader()
