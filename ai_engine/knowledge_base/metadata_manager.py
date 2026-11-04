"""Metadata manager for tracking indexed PDFs, hashes, and document catalog."""

from __future__ import annotations

import json
import logging
import os
import hashlib
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Dict, List, Optional

logger = logging.getLogger(__name__)


def compute_file_sha256(file_path: Path | str) -> str:
    """Computes SHA-256 hash of a file for change detection."""
    sha = hashlib.sha256()
    with open(file_path, "rb") as f:
        for chunk in iter(lambda: f.read(65536), b""):
            sha.update(chunk)
    return sha.hexdigest()


class MetadataManager:
    """Manages index manifest and document metadata catalog."""

    def __init__(self, metadata_dir: Path | str):
        self.metadata_dir = Path(metadata_dir)
        self.metadata_dir.mkdir(parents=True, exist_ok=True)
        self.manifest_file = self.metadata_dir / "index_manifest.json"
        self.catalog_file = self.metadata_dir / "document_catalog.json"
        self._manifest: Dict[str, Any] = self._load_json(self.manifest_file, default={"documents": {}, "last_updated": None})
        self._catalog: Dict[str, Any] = self._load_json(self.catalog_file, default={"documents": []})

    def _load_json(self, path: Path, default: Any) -> Any:
        if path.exists():
            try:
                with open(path, "r", encoding="utf-8") as f:
                    return json.load(f)
            except Exception as e:
                logger.warning(f"Error reading {path}, using default: {e}")
        return default

    def _save_json(self, path: Path, data: Any) -> None:
        try:
            with open(path, "w", encoding="utf-8") as f:
                json.dump(data, f, indent=2, ensure_ascii=False)
        except Exception as e:
            logger.error(f"Failed to save metadata to {path}: {e}")

    def get_document_record(self, doc_filename: str) -> Optional[Dict[str, Any]]:
        return self._manifest.get("documents", {}).get(doc_filename)

    def is_file_indexed_and_current(self, file_path: Path) -> bool:
        """Returns True if file has already been indexed and hash matches."""
        filename = file_path.name
        record = self.get_document_record(filename)
        if not record:
            return False
        current_hash = compute_file_sha256(file_path)
        return record.get("sha256") == current_hash

    def register_indexed_document(
        self,
        file_path: Path,
        page_count: int,
        chunk_count: int,
        crops_detected: List[str],
        symptoms_detected: List[str],
        title: Optional[str] = None,
    ) -> None:
        """Records a successfully indexed PDF in manifest and catalog."""
        filename = file_path.name
        file_hash = compute_file_sha256(file_path)
        now_iso = datetime.now(timezone.utc).isoformat()

        record = {
            "filename": filename,
            "path": str(file_path.resolve()),
            "sha256": file_hash,
            "file_size_bytes": file_path.stat().st_size,
            "page_count": page_count,
            "chunk_count": chunk_count,
            "crops": sorted(list(set(crops_detected))),
            "symptoms": sorted(list(set(symptoms_detected))),
            "title": title or filename.replace("_", " ").replace(".pdf", "").title(),
            "indexed_at": now_iso,
        }

        self._manifest["documents"][filename] = record
        self._manifest["last_updated"] = now_iso
        self._save_json(self.manifest_file, self._manifest)

        # Update catalog list
        catalog_docs = [d for d in self._catalog.get("documents", []) if d.get("filename") != filename]
        catalog_docs.append(record)
        self._catalog["documents"] = catalog_docs
        self._save_json(self.catalog_file, self._catalog)

    def remove_document(self, filename: str) -> None:
        """Removes a document from manifest and catalog."""
        if filename in self._manifest.get("documents", {}):
            del self._manifest["documents"][filename]
            self._manifest["last_updated"] = datetime.now(timezone.utc).isoformat()
            self._save_json(self.manifest_file, self._manifest)

        catalog_docs = [d for d in self._catalog.get("documents", []) if d.get("filename") != filename]
        self._catalog["documents"] = catalog_docs
        self._save_json(self.catalog_file, self._catalog)

    def clear(self) -> None:
        """Clears all metadata records."""
        self._manifest = {"documents": {}, "last_updated": None}
        self._catalog = {"documents": []}
        self._save_json(self.manifest_file, self._manifest)
        self._save_json(self.catalog_file, self._catalog)

    def get_catalog_summary(self) -> Dict[str, Any]:
        """Returns statistics of indexed documents."""
        docs = list(self._manifest.get("documents", {}).values())
        total_pages = sum(d.get("page_count", 0) for d in docs)
        total_chunks = sum(d.get("chunk_count", 0) for d in docs)
        all_crops = sorted(list({c for d in docs for c in d.get("crops", [])}))
        all_symptoms = sorted(list({s for d in docs for s in d.get("symptoms", [])}))

        return {
            "total_documents": len(docs),
            "total_pages": total_pages,
            "total_chunks": total_chunks,
            "crops_covered": all_crops,
            "symptoms_covered": all_symptoms,
            "last_updated": self._manifest.get("last_updated"),
            "documents": [d["filename"] for d in docs],
        }

