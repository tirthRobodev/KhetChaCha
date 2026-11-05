"""Unified FastAPI Entry Point for KhetChacha Agricultural AI Backend.

Re-exports the singleton production FastAPI application from `ai_engine.backend.main`,
ensuring that any entry point (backend.app or ai_engine.backend.main) runs the exact
same unified agricultural AI brain.
"""

from ai_engine.backend.main import app

__all__ = ["app"]
