import os
from functools import lru_cache
from pathlib import Path
from typing import List, Optional
from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict


# Base directories
AI_ENGINE_DIR = Path(__file__).resolve().parent.parent
PROJECT_ROOT = AI_ENGINE_DIR.parent


class Settings(BaseSettings):
    """
    Central Configuration for KhetChacha Farmer AI Engine.
    All parameters are dynamically overridable via environment variables or .env file.
    """
    model_config = SettingsConfigDict(
        env_file=str(AI_ENGINE_DIR / ".env"),
        env_file_encoding="utf-8",
        extra="ignore"
    )

    # 1. Google Gemini API
    gemini_api_key: Optional[str] = Field(default=None, alias="GEMINI_API_KEY")
    gemini_model: str = Field(default="gemini-flash-lite-latest", alias="GEMINI_MODEL")
    gemini_embedding_model: str = Field(default="gemini-embedding-001", alias="GEMINI_EMBEDDING_MODEL")
    gemini_request_timeout_seconds: float = Field(default=22.0, alias="GEMINI_REQUEST_TIMEOUT_SECONDS")
    gemini_max_retries: int = Field(default=2, alias="GEMINI_MAX_RETRIES")

    # 2. Search Engine & Grounding
    online_search_enabled: bool = Field(default=True, alias="ONLINE_SEARCH_ENABLED")
    online_search_provider: str = Field(default="gemini_grounding", alias="ONLINE_SEARCH_PROVIDER")
    online_search_timeout_seconds: float = Field(default=8.0, alias="ONLINE_SEARCH_TIMEOUT_SECONDS")
    local_search_min_score: float = Field(default=0.35, alias="LOCAL_SEARCH_MIN_SCORE")
    max_search_results: int = Field(default=5, alias="MAX_SEARCH_RESULTS")

    # 3. Data Storage Paths
    data_dir: Path = AI_ENGINE_DIR / "data"
    agriculture_pdfs_dir: Path = AI_ENGINE_DIR / "data" / "agriculture_pdfs"
    extracted_text_dir: Path = AI_ENGINE_DIR / "data" / "extracted_text"
    processed_docs_dir: Path = AI_ENGINE_DIR / "data" / "processed_documents"
    vector_db_dir: Path = AI_ENGINE_DIR / "data" / "vector_database"
    metadata_dir: Path = AI_ENGINE_DIR / "data" / "metadata"

    # Property Aliases for ergonomic access
    @property
    def pdf_dir(self) -> Path:
        return self.agriculture_pdfs_dir

    @property
    def gemini_model_name(self) -> str:
        return self.gemini_model

    @property
    def gemini_timeout_seconds(self) -> float:
        return self.gemini_request_timeout_seconds

    @property
    def max_evidence_sources(self) -> int:
        return self.max_search_results

    # 4. Server & Security
    api_host: str = Field(default="0.0.0.0", alias="API_HOST")
    api_port: int = Field(default=8000, alias="API_PORT")
    debug: bool = Field(default=False, alias="DEBUG")
    cors_origins: List[str] = ["*"]
    max_upload_size_bytes: int = 50 * 1024 * 1024  # 50 MB limit

    def ensure_directories(self) -> None:
        """Ensure all runtime data directories exist."""
        for d in [
            self.data_dir,
            self.agriculture_pdfs_dir,
            self.extracted_text_dir,
            self.processed_docs_dir,
            self.vector_db_dir,
            self.metadata_dir,
        ]:
            d.mkdir(parents=True, exist_ok=True)


@lru_cache()
def get_settings() -> Settings:
    """Returns singleton cached settings instance."""
    s = Settings()
    s.ensure_directories()
    return s


# Global singleton instance
settings = get_settings()
