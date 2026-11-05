"""Pydantic request models for KhetChacha Agriculture AI Engine."""

from __future__ import annotations

from typing import Any, Dict, Optional, Union
from pydantic import BaseModel, Field, model_validator


class LocationContext(BaseModel):
    """Geographical location details."""
    village: Optional[str] = None
    taluka: Optional[str] = None
    district: Optional[str] = None
    state: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None


class WeatherContext(BaseModel):
    """Atmospheric conditions at the farm."""
    temperature_celsius: Optional[float] = None
    humidity_percent: Optional[float] = None
    condition: Optional[str] = None
    rain_forecast: Optional[str] = None


class FarmerChatRequest(BaseModel):
    """Incoming request payload for Farmer AI Chat endpoint."""
    question: Optional[str] = Field(
        default="",
        description="The farmer's question in any of 22 Indian languages or English."
    )
    query: Optional[str] = Field(
        default="",
        description="Alias for question."
    )
    language: Optional[str] = Field(
        default="auto",
        description="ISO 639-1 language code (e.g. 'gu', 'hi', 'pa', 'en', 'auto')."
    )
    language_code: Optional[str] = Field(
        default=None,
        description="Alias for language."
    )
    grounding: Optional[Dict[str, Any]] = Field(
        default=None,
        description="Grounding context dictionary from legacy clients."
    )
    conversation_id: Optional[str] = Field(
        default=None,
        description="Optional session identifier for multi-turn advisory."
    )
    session_id: Optional[str] = Field(
        default=None,
        description="Alias for conversation_id."
    )
    current_crop: Optional[str] = Field(
        default=None,
        description="Crop under consideration."
    )
    crop: Optional[str] = Field(
        default=None,
        description="Alias for current_crop."
    )
    crop_age_days: Optional[int] = Field(
        default=None,
        description="Age of crop in days."
    )
    soil_type: Optional[str] = Field(
        default=None,
        description="Soil type (e.g., 'Black Cotton Soil', 'Alluvial', 'Sandy Loam')."
    )
    land_size: Optional[Union[float, str]] = Field(
        default=None,
        description="Land holding size description (e.g. '4.5 Acres', '5 Bigha', 5.0)."
    )
    land_area: Optional[float] = Field(
        default=None,
        description="Numeric land area."
    )
    land_unit: Optional[str] = Field(
        default=None,
        description="Unit of land ('Acre', 'Bigha', 'Guntha', 'Hectare')."
    )
    farmer_state: Optional[str] = Field(
        default=None,
        description="Farmer state."
    )
    farmer_district: Optional[str] = Field(
        default=None,
        description="Farmer district."
    )
    location: Optional[LocationContext] = Field(
        default=None,
        description="Detailed GPS and administrative location context."
    )
    weather: Optional[WeatherContext] = Field(
        default=None,
        description="Local weather observations and forecasts."
    )
    image_base64: Optional[str] = Field(
        default=None,
        description="Base64 encoded image string for multimodal diagnosis."
    )
    image_mime_type: Optional[str] = Field(
        default="image/jpeg",
        description="MIME type of the encoded image (image/jpeg, image/png, etc.)."
    )

    @model_validator(mode="before")
    @classmethod
    def sync_request_fields(cls, data: Any) -> Any:
        if isinstance(data, dict):
            # Sync question and query
            q = data.get("question") or data.get("query") or ""
            img = data.get("image_base64")
            if not str(q).strip() and img and str(img).strip():
                q = "Diagnose this plant image"
            data["question"] = str(q).strip()
            data["query"] = str(q).strip()

            # Sync language and language_code
            lang = data.get("language") or data.get("language_code") or "auto"
            data["language"] = lang
            data["language_code"] = lang

            # Sync crop and current_crop
            crp = data.get("crop") or data.get("current_crop")

            # Sync grounding if passed
            gr = data.get("grounding")
            if isinstance(gr, dict):
                if not crp and gr.get("detectedCrop"):
                    crp = gr.get("detectedCrop")
                if not data.get("farmer_district") and gr.get("district"):
                    data["farmer_district"] = gr.get("district")
                if not data.get("farmer_state") and gr.get("state"):
                    data["farmer_state"] = gr.get("state")

            data["crop"] = crp
            data["current_crop"] = crp

            # Sync session_id and conversation_id
            sid = data.get("session_id") or data.get("conversation_id")
            data["session_id"] = sid
            data["conversation_id"] = sid

        return data


class SpeechIntentRequest(BaseModel):
    """Incoming request for voice STT speech intent analysis."""
    text: str = Field(..., description="Recognized speech transcript words.")
    language_code: Optional[str] = Field(default="gu", description="Speech recognition language code.")


class FarmerVisionDiagnoseRequest(BaseModel):
    """Incoming request payload for Dynamic Single-Image Agricultural AI Diagnosis."""
    image_base64: str = Field(..., description="Base64 encoded plant, crop, fruit, vegetable, tree, leaf or root image bytes.")
    mime_type: Optional[str] = Field(default="image/jpeg", description="MIME type of the image (image/jpeg, image/png, image/webp).")
    question: Optional[str] = Field(default=None, description="Optional text inquiry or voice transcription accompanying the image.")
    language: Optional[str] = Field(default="auto", description="Target response language code ('gu', 'hi', 'en', 'pa', 'mr').")
    conversation_id: Optional[str] = Field(default=None, description="Optional session identifier for chat history.")
    farmer_district: Optional[str] = Field(default=None, description="Farmer district for local agronomic context.")
    farmer_state: Optional[str] = Field(default=None, description="Farmer state for regional climatic context.")
    current_crop: Optional[str] = Field(default=None, description="Optional crop hint from farmer profile if known.")


class KnowledgeSearchRequest(BaseModel):
    """Query payload for searching the local PDF agricultural knowledge base."""
    query: str = Field(..., min_length=1, max_length=1000, description="Search query string.")
    top_k: int = Field(default=5, ge=1, le=20, description="Number of top relevant evidence chunks to return.")
    crop: Optional[str] = Field(default=None, description="Optional crop keyword filter.")
    crop_filter: Optional[str] = Field(default=None, description="Alias for crop filter.")
    min_score: float = Field(default=0.25, description="Minimum confidence score threshold.")

    @model_validator(mode="before")
    @classmethod
    def sync_crop_filter(cls, data: Any) -> Any:
        if isinstance(data, dict):
            c = data.get("crop") or data.get("crop_filter")
            data["crop"] = c
            data["crop_filter"] = c
        return data


class OnlineSearchRequest(BaseModel):
    """Direct query payload for the online agricultural research engine."""
    query: str = Field(..., min_length=1, max_length=1000, description="Search query string.")
    max_results: int = Field(default=5, ge=1, le=15, description="Maximum number of authoritative results.")
    provider: Optional[str] = Field(default=None, description="Optional specific search provider override.")
