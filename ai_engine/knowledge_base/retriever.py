"""Knowledge base retriever connecting embeddings, vector store, and evidence models."""

from __future__ import annotations

import logging
from typing import List, Optional

from ai_engine.knowledge_base.embeddings import EmbeddingGenerator
from ai_engine.knowledge_base.vector_store import VectorStore
from ai_engine.language_engine.regional_vocabulary import expand_query_terms
from ai_engine.models.response_models import EvidenceSource

logger = logging.getLogger(__name__)


class KnowledgeRetriever:
    """Orchestrates query expansion, vector search, and evidence formatting for local PDFs."""

    def __init__(self, vector_store: VectorStore, embedding_generator: EmbeddingGenerator):
        self.vector_store = vector_store
        self.embedding_generator = embedding_generator

    def retrieve(
        self,
        query: str,
        top_k: int = 4,
        crop_filter: Optional[str] = None,
        min_score: float = 0.25,
    ) -> List[EvidenceSource]:
        """Performs multilingual-aware hybrid retrieval from local PDF vector store."""
        if not self.vector_store.chunks:
            logger.info("Knowledge base is empty. Returning 0 local evidence sources.")
            return []

        # Expand query with regional synonyms (e.g. કપાસ -> cotton, kapās)
        expanded_query = expand_query_terms(query)

        # Generate query vector
        query_vector = self.embedding_generator.embed_query(expanded_query)

        # Execute hybrid search
        scored_chunks = self.vector_store.search(
            query=expanded_query,
            query_vector=query_vector,
            top_k=top_k,
            crop_filter=crop_filter,
            min_hybrid_score=min_score,
        )

        evidence_list: List[EvidenceSource] = []
        for sc in scored_chunks:
            chunk = sc.chunk
            # Format clean snippet
            snippet_text = chunk.text.strip()
            if len(snippet_text) > 350:
                snippet_text = snippet_text[:350] + "..."

            evidence = EvidenceSource(
                title=f"{chunk.document_name} (Page {chunk.page_number})",
                document_name=chunk.document_name,
                page_number=chunk.page_number,
                snippet=snippet_text,
                confidence_score=round(sc.hybrid_score, 3),
                source_type="local_pdf",
            )
            evidence_list.append(evidence)

        return evidence_list

