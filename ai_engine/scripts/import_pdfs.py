"""CLI script to import and index agricultural PDFs into KhetChacha knowledge base."""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

# Add project root to sys.path
sys.path.insert(0, str(Path(__file__).resolve().parent.parent.parent))

from ai_engine.backend.config import get_settings
from ai_engine.backend.dependencies import get_service_container


def main():
    parser = argparse.ArgumentParser(description="Index agricultural PDFs into vector store.")
    parser.add_argument("--force", action="store_true", help="Force re-indexing of all PDFs even if unchanged")
    parser.add_argument("--file", type=str, default=None, help="Path to specific PDF file to index")
    args = parser.parse_args()

    settings = get_settings()
    container = get_service_container()

    print("=" * 60)
    print("KhetChacha Knowledge Base PDF Indexer")
    print("=" * 60)

    if args.file:
        file_path = Path(args.file)
        print(f"Indexing specific file: {file_path}")
        res = container.pdf_indexer.index_single_file(file_path, force=args.force)
        print("Result:", res)
    else:
        print(f"Scanning directory: {settings.pdf_dir}")
        res = container.pdf_indexer.index_all_pdfs(force=args.force)
        print(f"Indexing completed: {res['indexed']} indexed, {res['skipped']} skipped, {res['errors']} errors.")
        print(f"Total Chunks in Vector Store: {len(container.vector_store.chunks)}")


if __name__ == "__main__":
    main()
