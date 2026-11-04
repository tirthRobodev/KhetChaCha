"""Pydantic response models for KhetChacha Agriculture AI Engine."""

from __future__ import annotations

from typing import Any, Dict, List, Optional
from pydantic import BaseModel, Field, model_validator


class EvidenceSource(BaseModel):
    """Represents a verified agricultural evidence source cited in the response."""
    title: str = Field(..., description="Document title or website publication heading.")
    document_name: Optional[str] = Field(default=None, description="PDF file name if source is local.")
    page_number: Optional[int] = Field(default=None, description="Page number if from local PDF.")
    page: Optional[int] = Field(default=None, description="Alias for page_number.")
    page_or_section: Optional[str] = Field(default=None, description="Page number or section if from local PDF/knowledge.")
    url: Optional[str] = Field(default=None, description="Verified URL if evidence was derived from online research.")
    source_type: str = Field(
        default="local_pdf",
        description="Source classification: 'local_pdf', 'online_web', 'gemini_grounding', 'online_icar', 'online_kvk'."
    )
    snippet: Optional[str] = Field(default=None, description="Concise excerpt containing the supporting evidence.")
    confidence_score: float = Field(default=0.0, description="Confidence similarity score (0.0 to 1.0).")
    relevance_score: float = Field(default=0.0, description="Alias for confidence_score.")

    @model_validator(mode="after")
    def sync_aliases(self) -> "EvidenceSource":
        if self.page is not None and self.page_number is None:
            self.page_number = self.page
        elif self.page_number is not None and self.page is None:
            self.page = self.page_number

        if self.confidence_score > 0 and self.relevance_score == 0:
            self.relevance_score = self.confidence_score
        elif self.relevance_score > 0 and self.confidence_score == 0:
            self.confidence_score = self.relevance_score

        return self


class FarmerChatResponse(BaseModel):
    """
    Standard structured response delivered to the mobile application.
    Consistent, Flutter-friendly, and multilingual.
    """
    success: bool = Field(default=True, description="Indicates if the query was processed successfully.")
    language: str = Field(default="gu", description="Language code of the answer (e.g. 'gu', 'hi', 'en').")
    language_name: str = Field(default="Gujarati", description="Full English display name of the language.")
    answer: str = Field(
        default="",
        description="Farmer-friendly answer (approx 40-100 words) with actionable steps."
    )
    short_answer: Optional[str] = Field(
        default=None,
        description="Short direct answer strictly between 40-100 words."
    )
    detailed_explanation: Optional[str] = Field(
        default=None,
        description="In-depth agronomic explanation covering cause, biology, and IPM."
    )
    confidence_score: float = Field(default=0.85, description="Overall answer confidence score.")
    source_type: str = Field(
        default="local_pdf",
        description="Primary evidence tier: 'local_pdf', 'online_web', 'gemini_grounding', 'hybrid_fallback'."
    )
    sources: List[EvidenceSource] = Field(
        default_factory=list,
        description="List of verified authoritative sources cited for this advisory."
    )
    action_steps: List[str] = Field(
        default_factory=list,
        description="Numbered practical action steps for the farmer."
    )
    safety_precautions: List[str] = Field(
        default_factory=list,
        description="Personal protective equipment (PPE) and spray precautions."
    )
    safety_advisory: Optional[str] = Field(
        default=None,
        description="Formatted safety advisory string."
    )
    crop_detected: Optional[str] = Field(
        default=None,
        description="Primary crop identified in the query."
    )
    symptoms_identified: List[str] = Field(
        default_factory=list,
        description="Key agronomic symptoms detected."
    )
    search_strategy_used: str = Field(
        default="local_only",
        description="Retrieval strategy: 'local_only', 'online_only', 'hybrid_fallback'."
    )
    requires_photo: bool = Field(
        default=False,
        description="True if symptoms are ambiguous and require leaf/plant photo."
    )
    needs_more_information: bool = Field(
        default=False,
        description="Alias for requires_photo."
    )
    suggested_follow_up: Optional[str] = Field(
        default=None,
        description="Helpful follow-up prompt or question for the farmer."
    )
    conversation_id: Optional[str] = Field(
        default=None,
        description="Session identifier."
    )

    @model_validator(mode="after")
    def sync_chat_fields(self) -> "FarmerChatResponse":
        if self.short_answer and not self.answer:
            self.answer = self.short_answer
        elif self.answer and not self.short_answer:
            self.short_answer = self.answer

        if self.requires_photo and not self.needs_more_information:
            self.needs_more_information = True
        elif self.needs_more_information and not self.requires_photo:
            self.requires_photo = True

        if self.safety_precautions and not self.safety_advisory:
            self.safety_advisory = "; ".join(self.safety_precautions)

        return self


class KnowledgeSearchResult(BaseModel):
    """Response returned by the knowledge search endpoint."""
    query: str
    crop: Optional[str] = None
    total_results: int = 0
    sources: List[EvidenceSource] = Field(default_factory=list)
    results: List[EvidenceSource] = Field(default_factory=list)

    @model_validator(mode="after")
    def sync_results(self) -> "KnowledgeSearchResult":
        if self.sources and not self.results:
            self.results = self.sources
        elif self.results and not self.sources:
            self.sources = self.results
        if self.total_results == 0:
            self.total_results = len(self.sources)
        return self


class KnowledgeStatusResponse(BaseModel):
    """Current health and volume status of the local PDF knowledge base."""
    total_documents: int = 0
    total_pages: int = 0
    total_chunks: int = 0
    indexed_documents_count: int = 0
    total_chunks_count: int = 0
    crops_indexed: List[str] = Field(default_factory=list)
    symptoms_indexed: List[str] = Field(default_factory=list)
    documents: List[Any] = Field(default_factory=list)
    last_updated: Optional[str] = None
    last_indexed_at: Optional[str] = None

    @model_validator(mode="after")
    def sync_status_fields(self) -> "KnowledgeStatusResponse":
        if self.total_documents > 0 and self.indexed_documents_count == 0:
            self.indexed_documents_count = self.total_documents
        elif self.indexed_documents_count > 0 and self.total_documents == 0:
            self.total_documents = self.indexed_documents_count

        if self.total_chunks > 0 and self.total_chunks_count == 0:
            self.total_chunks_count = self.total_chunks
        elif self.total_chunks_count > 0 and self.total_chunks == 0:
            self.total_chunks = self.total_chunks_count

        if self.last_updated and not self.last_indexed_at:
            self.last_indexed_at = self.last_updated
        elif self.last_indexed_at and not self.last_updated:
            self.last_updated = self.last_indexed_at

        return self


class FileUploadResponse(BaseModel):
    """Response returned upon uploading an agricultural PDF document."""
    success: bool = True
    filename: str
    status: str = "success"
    message: str = ""
    file_size_bytes: int = 0
    pages_extracted: int = 0
    chunks_created: int = 0
    chunks_indexed: int = 0
    crops_detected: List[str] = Field(default_factory=list)
    symptoms_detected: List[str] = Field(default_factory=list)

    @model_validator(mode="after")
    def sync_upload_fields(self) -> "FileUploadResponse":
        if self.chunks_created > 0 and self.chunks_indexed == 0:
            self.chunks_indexed = self.chunks_created
        elif self.chunks_indexed > 0 and self.chunks_created == 0:
            self.chunks_created = self.chunks_indexed
        return self


class HealthResponse(BaseModel):
    """API health status and runtime capabilities."""
    status: str = "healthy"
    version: str = "1.0.0"
    gemini_available: bool = False
    gemini_configured: bool = False
    gemini_model: str = "gemini-2.5-flash"
    vector_store_chunks: int = 0
    indexed_documents_count: int = 0
    indexed_documents: int = 0
    supported_languages_count: int = 23

    @model_validator(mode="after")
    def sync_health_fields(self) -> "HealthResponse":
        if self.gemini_available and not self.gemini_configured:
            self.gemini_configured = True
        elif self.gemini_configured and not self.gemini_available:
            self.gemini_available = True

        if self.indexed_documents_count > 0 and self.indexed_documents == 0:
            self.indexed_documents = self.indexed_documents_count
        elif self.indexed_documents > 0 and self.indexed_documents_count == 0:
            self.indexed_documents_count = self.indexed_documents

        return self
