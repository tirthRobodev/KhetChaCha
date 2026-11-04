"""Document chunking module for KhetChacha Agriculture AI Engine.

Splits extracted PDF text into semantically cohesive, overlapping chunks
preserving sentence boundaries, accompanied by rich metadata for vector retrieval.
"""

from __future__ import annotations

import re
from typing import Any, Dict, List
from ai_engine.language_engine.regional_vocabulary import identify_query_attributes


class DocumentChunk:
    """Represents a chunk of text with associated document metadata."""

    def __init__(
        self,
        chunk_id: str,
        document_name: str,
        page_number: int,
        chunk_index: int,
        text: str,
        crops: List[str] | None = None,
        symptoms: List[str] | None = None,
        actions: List[str] | None = None,
        metadata: Dict[str, Any] | None = None,
    ):
        self.chunk_id = chunk_id
        self.document_name = document_name
        self.page_number = page_number
        self.chunk_index = chunk_index
        self.text = text
        self.crops = crops or []
        self.symptoms = symptoms or []
        self.actions = actions or []
        self.metadata = metadata or {}

    def to_dict(self) -> Dict[str, Any]:
        return {
            "chunk_id": self.chunk_id,
            "document_name": self.document_name,
            "page_number": self.page_number,
            "chunk_index": self.chunk_index,
            "text": self.text,
            "crops": self.crops,
            "symptoms": self.symptoms,
            "actions": self.actions,
            "metadata": self.metadata,
        }

    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> "DocumentChunk":
        return cls(
            chunk_id=data["chunk_id"],
            document_name=data["document_name"],
            page_number=data["page_number"],
            chunk_index=data["chunk_index"],
            text=data["text"],
            crops=data.get("crops", []),
            symptoms=data.get("symptoms", []),
            actions=data.get("actions", []),
            metadata=data.get("metadata", {}),
        )


class DocumentChunker:
    """Sliding-window semantic chunker with sentence boundary protection."""

    # Sentence boundaries across English and Indic scripts (including Purna Viram '।')
    SENTENCE_SPLIT_REGEX = re.compile(r"(?<=[.!?।\n])\s+")

    def __init__(
        self,
        min_chunk_size: int = 400,
        max_chunk_size: int = 850,
        overlap_size: int = 120,
    ):
        self.min_chunk_size = min_chunk_size
        self.max_chunk_size = max_chunk_size
        self.overlap_size = overlap_size

    def chunk_page_text(
        self,
        document_name: str,
        page_number: int,
        page_text: str,
        global_chunk_start_idx: int = 0,
    ) -> List[DocumentChunk]:
        """Chunks a single page's text respecting sentence boundaries."""
        clean_text = page_text.strip()
        if not clean_text:
            return []

        # Split into sentences or lines
        raw_sentences = self.SENTENCE_SPLIT_REGEX.split(clean_text)
        sentences = [s.strip() for s in raw_sentences if s.strip()]

        if not sentences:
            return []

        chunks: List[DocumentChunk] = []
        current_sentences: List[str] = []
        current_length = 0
        chunk_idx = global_chunk_start_idx

        for sentence in sentences:
            sentence_len = len(sentence)

            # If a single sentence exceeds max_chunk_size, break it cleanly
            if sentence_len > self.max_chunk_size:
                # Flush existing buffer first
                if current_sentences:
                    chunk_text = " ".join(current_sentences).strip()
                    if chunk_text:
                        chunks.append(self._create_chunk(document_name, page_number, chunk_idx, chunk_text))
                        chunk_idx += 1
                        current_sentences = []
                        current_length = 0

                # Break the oversized sentence by words
                words = sentence.split()
                sub_buf: List[str] = []
                sub_len = 0
                for w in words:
                    if sub_len + len(w) + 1 > self.max_chunk_size and sub_buf:
                        chunk_text = " ".join(sub_buf).strip()
                        chunks.append(self._create_chunk(document_name, page_number, chunk_idx, chunk_text))
                        chunk_idx += 1
                        sub_buf = [w]
                        sub_len = len(w)
                    else:
                        sub_buf.append(w)
                        sub_len += len(w) + 1
                if sub_buf:
                    chunk_text = " ".join(sub_buf).strip()
                    chunks.append(self._create_chunk(document_name, page_number, chunk_idx, chunk_text))
                    chunk_idx += 1
                continue

            # Standard accumulation
            if current_length + sentence_len + 1 > self.max_chunk_size and current_sentences:
                chunk_text = " ".join(current_sentences).strip()
                chunks.append(self._create_chunk(document_name, page_number, chunk_idx, chunk_text))
                chunk_idx += 1

                # Calculate overlap: carry forward trailing sentences within overlap_size
                overlap_sentences: List[str] = []
                overlap_len = 0
                for prev_s in reversed(current_sentences):
                    if overlap_len + len(prev_s) + 1 <= self.overlap_size:
                        overlap_sentences.insert(0, prev_s)
                        overlap_len += len(prev_s) + 1
                    else:
                        break

                current_sentences = list(overlap_sentences)
                current_length = sum(len(s) + 1 for s in current_sentences)

            current_sentences.append(sentence)
            current_length += sentence_len + 1

        # Flush any remaining text
        if current_sentences:
            chunk_text = " ".join(current_sentences).strip()
            if chunk_text:
                chunks.append(self._create_chunk(document_name, page_number, chunk_idx, chunk_text))

        return chunks

    def _create_chunk(
        self,
        document_name: str,
        page_number: int,
        chunk_idx: int,
        text: str,
    ) -> DocumentChunk:
        """Enriches a text chunk with agronomic taxonomy attributes."""
        attrs = identify_query_attributes(text)
        chunk_id = f"{document_name}_p{page_number}_c{chunk_idx}"

        return DocumentChunk(
            chunk_id=chunk_id,
            document_name=document_name,
            page_number=page_number,
            chunk_index=chunk_idx,
            text=text,
            crops=attrs.get("crops", []),
            symptoms=attrs.get("symptoms", []),
            actions=attrs.get("actions", []),
            metadata={
                "char_length": len(text),
                "word_count": len(text.split()),
            },
        )

