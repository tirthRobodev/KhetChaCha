"""Persistent hybrid vector store with semantic and keyword (BM25-style) retrieval."""

from __future__ import annotations

import json
import logging
import math
import os
import re
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple

from ai_engine.knowledge_base.embeddings import cosine_similarity
from ai_engine.pdf_processor.document_chunker import DocumentChunk

logger = logging.getLogger(__name__)


class ScoredChunk:
    """A retrieved chunk with hybrid, semantic, and keyword similarity scores."""

    def __init__(
        self,
        chunk: DocumentChunk,
        hybrid_score: float,
        semantic_score: float,
        keyword_score: float,
    ):
        self.chunk = chunk
        self.hybrid_score = hybrid_score
        self.semantic_score = semantic_score
        self.keyword_score = keyword_score

    def to_dict(self) -> Dict[str, Any]:
        d = self.chunk.to_dict()
        d["hybrid_score"] = round(self.hybrid_score, 4)
        d["semantic_score"] = round(self.semantic_score, 4)
        d["keyword_score"] = round(self.keyword_score, 4)
        return d


class VectorStore:
    """In-memory persistent hybrid vector and inverted keyword store."""

    def __init__(self, db_dir: Path | str):
        self.db_dir = Path(db_dir)
        self.db_dir.mkdir(parents=True, exist_ok=True)
        self.index_file = self.db_dir / "vector_index.json"

        self.chunks: Dict[str, DocumentChunk] = {}
        self.vectors: Dict[str, List[float]] = {}
        self.inverted_index: Dict[str, List[str]] = {}  # token -> list of chunk_ids
        self.doc_lengths: Dict[str, int] = {}
        self.avg_doc_length: float = 1.0

        self.load()

    def _tokenize(self, text: str) -> List[str]:
        return [w.lower() for w in re.findall(r"[\w']+", text, flags=re.UNICODE) if len(w) > 1]

    def add_chunk(self, chunk: DocumentChunk, vector: List[float]) -> None:
        """Adds or updates a chunk and its vector in the store."""
        cid = chunk.chunk_id
        self.chunks[cid] = chunk
        self.vectors[cid] = vector

        tokens = self._tokenize(chunk.text)
        self.doc_lengths[cid] = len(tokens)

        # Update inverted index
        for t in set(tokens):
            if t not in self.inverted_index:
                self.inverted_index[t] = []
            if cid not in self.inverted_index[t]:
                self.inverted_index[t].append(cid)

        # Also index metadata tags as searchable tokens
        for tag in chunk.crops + chunk.symptoms + chunk.actions:
            t = tag.lower()
            if t not in self.inverted_index:
                self.inverted_index[t] = []
            if cid not in self.inverted_index[t]:
                self.inverted_index[t].append(cid)

    def add_chunks_batch(
        self,
        chunks: List[DocumentChunk],
        vectors: List[List[float]],
    ) -> None:
        """Batch ingestion of chunks with their embedding vectors."""
        for chunk, vector in zip(chunks, vectors):
            self.add_chunk(chunk, vector)

        self._recompute_stats()

    def remove_document_chunks(self, document_name: str) -> int:
        """Removes all chunks associated with a specific document."""
        to_remove = [cid for cid, ch in self.chunks.items() if ch.document_name == document_name]
        for cid in to_remove:
            self.chunks.pop(cid, None)
            self.vectors.pop(cid, None)
            self.doc_lengths.pop(cid, None)

        # Rebuild inverted index
        self.inverted_index.clear()
        for cid, ch in self.chunks.items():
            tokens = self._tokenize(ch.text)
            for t in set(tokens):
                if t not in self.inverted_index:
                    self.inverted_index[t] = []
                self.inverted_index[t].append(cid)
            for tag in ch.crops + ch.symptoms + ch.actions:
                t = tag.lower()
                if t not in self.inverted_index:
                    self.inverted_index[t] = []
                if cid not in self.inverted_index[t]:
                    self.inverted_index[t].append(cid)

        self._recompute_stats()
        return len(to_remove)

    def _recompute_stats(self) -> None:
        if self.doc_lengths:
            self.avg_doc_length = sum(self.doc_lengths.values()) / max(1, len(self.doc_lengths))
        else:
            self.avg_doc_length = 1.0

    def compute_bm25_score(self, query_tokens: List[str], chunk_id: str) -> float:
        """Computes BM25-inspired lexical matching score for a chunk."""
        k1 = 1.5
        b = 0.75
        doc_len = self.doc_lengths.get(chunk_id, 1)
        score = 0.0
        total_docs = max(1, len(self.chunks))

        chunk = self.chunks.get(chunk_id)
        if not chunk:
            return 0.0

        chunk_tokens = self._tokenize(chunk.text)
        chunk_tags = {t.lower() for t in chunk.crops + chunk.symptoms + chunk.actions}

        for q_tok in query_tokens:
            q_tok_lower = q_tok.lower()
            df = len(self.inverted_index.get(q_tok_lower, []))
            if df == 0:
                continue

            idf = math.log(1.0 + (total_docs - df + 0.5) / (df + 0.5))
            tf = chunk_tokens.count(q_tok_lower)

            # Metadata tag match bonus
            if q_tok_lower in chunk_tags:
                tf += 3.0

            if tf > 0:
                numerator = tf * (k1 + 1.0)
                denominator = tf + k1 * (1.0 - b + b * (doc_len / max(1.0, self.avg_doc_length)))
                score += idf * (numerator / max(0.001, denominator))

        return score

    def search(
        self,
        query: str,
        query_vector: List[float],
        top_k: int = 5,
        crop_filter: Optional[str] = None,
        min_hybrid_score: float = 0.15,
        semantic_weight: float = 0.65,
    ) -> List[ScoredChunk]:
        """Hybrid search combining semantic cosine similarity and BM25 lexical matching."""
        if not self.chunks:
            return []

        query_tokens = self._tokenize(query)
        scored_candidates: List[ScoredChunk] = []

        # Find BM25 max for normalization
        raw_keyword_scores: Dict[str, float] = {}
        max_bm25 = 0.001
        for cid in self.chunks.keys():
            k_score = self.compute_bm25_score(query_tokens, cid)
            raw_keyword_scores[cid] = k_score
            if k_score > max_bm25:
                max_bm25 = k_score

        for cid, chunk in self.chunks.items():
            # Apply crop filter if provided
            if crop_filter:
                cf = crop_filter.lower()
                chunk_crops = [c.lower() for c in chunk.crops]
                if cf not in chunk_crops and cf not in chunk.text.lower():
                    continue

            # Semantic score
            chunk_vec = self.vectors.get(cid, [])
            sem_score = cosine_similarity(query_vector, chunk_vec)

            # Normalized keyword score
            norm_kw_score = min(1.0, raw_keyword_scores.get(cid, 0.0) / max_bm25) if max_bm25 > 0 else 0.0

            # Hybrid score
            hybrid_score = (semantic_weight * sem_score) + ((1.0 - semantic_weight) * norm_kw_score)

            if hybrid_score >= min_hybrid_score:
                scored_candidates.append(
                    ScoredChunk(
                        chunk=chunk,
                        hybrid_score=hybrid_score,
                        semantic_score=sem_score,
                        keyword_score=norm_kw_score,
                    )
                )

        # Sort descending by hybrid score
        scored_candidates.sort(key=lambda x: x.hybrid_score, reverse=True)
        return scored_candidates[:top_k]

    def save(self) -> None:
        """Serializes the vector store to disk."""
        data = {
            "chunks": {cid: ch.to_dict() for cid, ch in self.chunks.items()},
            "vectors": self.vectors,
            "doc_lengths": self.doc_lengths,
        }
        try:
            with open(self.index_file, "w", encoding="utf-8") as f:
                json.dump(data, f, ensure_ascii=False)
            logger.info(f"Saved {len(self.chunks)} chunks to vector index at {self.index_file}")
        except Exception as e:
            logger.error(f"Failed to save vector index: {e}")

    def load(self) -> None:
        """Loads the vector store from disk if present."""
        if not self.index_file.exists():
            return

        try:
            with open(self.index_file, "r", encoding="utf-8") as f:
                data = json.load(f)

            raw_chunks = data.get("chunks", {})
            self.chunks = {cid: DocumentChunk.from_dict(cd) for cid, cd in raw_chunks.items()}
            self.vectors = data.get("vectors", {})
            self.doc_lengths = data.get("doc_lengths", {})

            # Rebuild inverted index
            self.inverted_index.clear()
            for cid, ch in self.chunks.items():
                tokens = self._tokenize(ch.text)
                for t in set(tokens):
                    if t not in self.inverted_index:
                        self.inverted_index[t] = []
                    self.inverted_index[t].append(cid)
                for tag in ch.crops + ch.symptoms + ch.actions:
                    t = tag.lower()
                    if t not in self.inverted_index:
                        self.inverted_index[t] = []
                    if cid not in self.inverted_index[t]:
                        self.inverted_index[t].append(cid)

            self._recompute_stats()
            logger.info(f"Loaded {len(self.chunks)} chunks from {self.index_file}")
        except Exception as e:
            logger.warning(f"Could not load vector store from {self.index_file}: {e}")

    def clear(self) -> None:
        """Wipes all chunks and vectors."""
        self.chunks.clear()
        self.vectors.clear()
        self.inverted_index.clear()
        self.doc_lengths.clear()
        self.avg_doc_length = 1.0
        if self.index_file.exists():
            self.index_file.unlink(missing_ok=True)

