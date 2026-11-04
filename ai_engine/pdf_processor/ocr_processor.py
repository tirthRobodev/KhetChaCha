import logging
from pathlib import Path
from typing import Optional

logger = logging.getLogger(__name__)


class OcrProcessor:
    """
    OCR Fallback Engine for scanned agricultural PDFs.
    Detects whether OCR libraries are installed and provides text extraction from images.
    """

    def __init__(self):
        self._has_tesseract = False
        try:
            import pytesseract
            self._has_tesseract = True
        except ImportError:
            self._has_tesseract = False

    @property
    def is_ocr_available(self) -> bool:
        """Returns True if an OCR engine (pytesseract) is available on the host system."""
        return self._has_tesseract

    def is_available(self) -> bool:
        """Ergonomic method checking if OCR is available."""
        return self._has_tesseract

    def process_image(self, image_bytes: bytes, lang: str = "eng+guj+hin") -> str:
        """Runs OCR on image bytes if engine is available; otherwise returns empty string."""
        if not self._has_tesseract:
            logger.info("OCR engine not installed on host. Skipping image OCR.")
            return ""

        try:
            import pytesseract
            from PIL import Image
            import io

            img = Image.open(io.BytesIO(image_bytes))
            text = pytesseract.image_to_string(img, lang=lang)
            return text.strip()
        except Exception as e:
            logger.warning(f"OCR processing failed: {e}")
            return ""

    def ocr_pdf_page(self, pdf_path: Path | str, page_number: int) -> str:
        """Attempts OCR on a specific PDF page if pypdfium2 / pdf2image and tesseract exist."""
        if not self._has_tesseract:
            return ""
        try:
            import pypdf
            reader = pypdf.PdfReader(str(pdf_path))
            if page_number - 1 < len(reader.pages):
                page = reader.pages[page_number - 1]
                for img_obj in page.images:
                    res = self.process_image(img_obj.data)
                    if res:
                        return res
            return ""
        except Exception as e:
            logger.warning(f"PDF page OCR failed for {pdf_path}: {e}")
            return ""


# Ergonomic aliases
OCRProcessor = OcrProcessor
ocr_processor = OcrProcessor()
