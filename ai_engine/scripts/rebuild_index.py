"""CLI script to wipe and completely rebuild the vector store from scratch."""

from __future__ import annotations

import sys
from pathlib import Path

# Add project root to sys.path
sys.path.insert(0, str(Path(__file__).resolve().parent.parent.parent))

from ai_engine.backend.dependencies import get_service_container


def main():
    print("=" * 60)
    print("KhetChacha Knowledge Base Full Rebuild")
    print("=" * 60)

    container = get_service_container()
    res = container.pdf_indexer.rebuild_all()

    print("Rebuild completed:")
    print(f"  Total Files Found: {res['total_files']}")
    print(f"  Successfully Indexed: {res['indexed']}")
    print(f"  Errors: {res['errors']}")
    print(f"  Total Chunks in Vector Store: {len(container.vector_store.chunks)}")


if __name__ == "__main__":
    main()
