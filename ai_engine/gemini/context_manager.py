"""In-memory multi-turn conversational context manager."""

from __future__ import annotations

import time
from typing import Dict, List, Optional


class ConversationContextManager:
    """Manages multi-turn conversation memory keyed by session ID."""

    def __init__(self, max_turns: int = 6, ttl_seconds: int = 7200):
        self.max_turns = max_turns
        self.ttl_seconds = ttl_seconds
        # session_id -> {"last_active": float, "history": List[Dict[str, str]]}
        self._sessions: Dict[str, Dict[str, Any]] = {}

    def get_history(self, session_id: Optional[str]) -> List[Dict[str, str]]:
        """Retrieves conversational history for a session."""
        if not session_id or session_id not in self._sessions:
            return []

        session_data = self._sessions[session_id]
        # Check TTL
        if time.time() - session_data["last_active"] > self.ttl_seconds:
            del self._sessions[session_id]
            return []

        return session_data["history"]

    def add_user_message(self, session_id: Optional[str], text: str) -> None:
        """Records a user query in session history."""
        if not session_id:
            return

        self._ensure_session(session_id)
        self._sessions[session_id]["history"].append({"role": "user", "content": text})
        self._prune(session_id)

    def add_assistant_message(self, session_id: Optional[str], text: str) -> None:
        """Records an assistant response in session history."""
        if not session_id:
            return

        self._ensure_session(session_id)
        self._sessions[session_id]["history"].append({"role": "assistant", "content": text})
        self._prune(session_id)

    def _ensure_session(self, session_id: str) -> None:
        now = time.time()
        if session_id not in self._sessions:
            self._sessions[session_id] = {"last_active": now, "history": []}
        else:
            self._sessions[session_id]["last_active"] = now

    def _prune(self, session_id: str) -> None:
        history = self._sessions[session_id]["history"]
        if len(history) > self.max_turns * 2:
            # Keep the most recent max_turns * 2 messages
            self._sessions[session_id]["history"] = history[-(self.max_turns * 2):]

    def clear_session(self, session_id: str) -> None:
        """Removes a session from memory."""
        self._sessions.pop(session_id, None)

