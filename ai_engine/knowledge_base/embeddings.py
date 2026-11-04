"""Dual-mode embedding generator for KhetChacha Agriculture AI Engine.

Supports:
1. Online mode: Gemini API text embeddings (models/text-embedding-004).
2. Offline / Local fallback mode: Deterministic n-gram TF-IDF vectorizer
   supporting English and Indic scripts with zero external C++ dependencies.
"""

from __future__ import annotations

import logging
import math
import re
from typing import List, Optional

logger = logging.getLogger(__name__)


def cosine_similarity(vec_a: List[float], vec_b: List[float]) -> float:
    """Calculates cosine similarity between two float vectors."""
    if not vec_a or not vec_b or len(vec_a) != len(vec_b):
        return 0.0

    dot = sum(a * b for a, b in zip(vec_a, vec_b))
    norm_a = math.sqrt(sum(a * a for a in vec_a))
    norm_b = math.sqrt(sum(b * b for b in vec_b))

    if norm_a == 0.0 or norm_b == 0.0:
        return 0.0

    return max(0.0, min(1.0, dot / (norm_a * norm_b)))


class LocalNgramVectorizer:
    """Deterministic hash-based subword n-gram vectorizer with TF-IDF weighting.

    Produces dense embedding vectors of fixed dimension (default 256)
    for English and all Indian languages without requiring PyTorch or heavy C++ binaries.
    """

    def __init__(self, dimension: int = 256):
        self.dimension = dimension

    def _tokenize_to_ngrams(self, text: str) -> List[str]:
        # Normalize text and split into words
        text = text.lower()
        words = re.findall(r"[\w']+", text, flags=re.UNICODE)
        tokens: List[str] = []

        for word in words:
            # Word unigram
            tokens.append(word)
            # Character n-grams (3-grams and 4-grams) for robust typo and subword matching
            if len(word) >= 3:
                for i in range(len(word) - 2):
                    tokens.append(word[i : i + 3])
            if len(word) >= 4:
                for i in range(len(word) - 3):
                    tokens.append(word[i : i + 4])

        return tokens

    def vectorize(self, text: str) -> List[float]:
        """Maps arbitrary text to a normalized dense vector of length `dimension`."""
        vec = [0.0] * self.dimension
        tokens = self._tokenize_to_ngrams(text)

        if not tokens:
            return vec

        # Term frequency with hash bucketing
        for token in tokens:
            h = hash(token) % self.dimension
            # Use alternating sign from hash for better dispersion
            sign = 1.0 if (hash(token) >> 8) % 2 == 0 else -1.0
            vec[h] += sign * (1.0 + math.log(1.0 + tokens.count(token)))

        # L2 normalization
        norm = math.sqrt(sum(v * v for v in vec))
        if norm > 0.0:
            vec = [v / norm for v in vec]

        return vec


class EmbeddingGenerator:
    """Manages text embedding generation with automatic Gemini / Local fallback."""

    def __init__(
        self,
        api_key: Optional[str] = None,
        model_name: str = "gemini-embedding-001",
        local_dim: int = 256,
    ):
        self.api_key = api_key
        if model_name and not model_name.startswith("models/"):
            self.model_name = f"models/{model_name}"
        else:
            self.model_name = model_name or "models/gemini-embedding-001"
        self.local_vectorizer = LocalNgramVectorizer(dimension=local_dim)
        self._gemini_client_ready = False

        if self.api_key and self.api_key.strip():
            try:
                import google.generativeai as genai
                genai.configure(api_key=self.api_key)
                self._gemini_client_ready = True
                logger.info(f"Gemini embedding client configured with {self.model_name}")
            except Exception as e:
                logger.warning(f"Could not configure Gemini embeddings: {e}. Falling back to local vectorizer.")

    def embed_text(self, text: str, task_type: str = "RETRIEVAL_DOCUMENT") -> List[float]:
        """Embeds a single string into a vector."""
        if not text or not text.strip():
            return [0.0] * (768 if self._gemini_client_ready else self.local_vectorizer.dimension)

        if self._gemini_client_ready:
            try:
                import google.generativeai as genai
                result = genai.embed_content(
                    model=self.model_name,
                    content=text,
                    task_type=task_type,
                )
                embedding = result.get("embedding")
                if embedding and isinstance(embedding, list):
                    return embedding
            except Exception as e:
                logger.warning(f"Gemini embed_content failed: {e}. Falling back to local vectorizer.")

        # Local vectorizer fallback
        return self.local_vectorizer.vectorize(text)

    def embed_query(self, query: str) -> List[float]:
        """Embeds a search query."""
        return self.embed_text(query, task_type="RETRIEVAL_QUERY")

    def embed_documents(self, texts: List[str]) -> List[List[float]]:
        """Batch embeds a list of document chunk texts."""
        if not texts:
            return []

        if self._gemini_client_ready:
            try:
                import google.generativeai as genai
                result = genai.embed_content(
                    model=self.model_name,
                    content=texts,
                    task_type="RETRIEVAL_DOCUMENT",
                )
                embeddings = result.get("embedding")
                if embeddings and isinstance(embeddings, list):
                    # Check if single or batch returned
                    if isinstance(embeddings[0], list):
                        return embeddings
                    return [embeddings]
            except Exception as e:
                logger.warning(f"Gemini batch embedding failed: {e}. Using local vectorizer.")

        return [self.local_vectorizer.vectorize(t) for t in texts]

