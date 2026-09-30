"""Approved local-context library for culturally grounded worksheets.

Loads an optional JSON library of approved classroom objects/vocabulary:
{"objects": [{"name_hi": "...", "name_en": "...", "grades": [1, 2], "subjects": [...]}]}
When unavailable, the builder falls back to standard curriculum-safe objects.
An LLM is never asked to invent cultural facts.
"""
from __future__ import annotations

import json
import logging
from pathlib import Path
from typing import Any, Dict, List, Optional

logger = logging.getLogger(__name__)

# Curriculum-safe neutral objects (standard Hindi vocabulary, no cultural claims).
FALLBACK_OBJECTS = [
    {"name_hi": "आम", "name_en": "mango"},
    {"name_hi": "कंचे", "name_en": "marbles"},
    {"name_hi": "छड़ें", "name_en": "sticks"},
    {"name_hi": "गेंद", "name_en": "ball"},
    {"name_hi": "फूल", "name_en": "flower"},
    {"name_hi": "तारे", "name_en": "stars"},
    {"name_hi": "चूड़ियाँ", "name_en": "bangles"},
    {"name_hi": "किताबें", "name_en": "books"},
]


class LocalContextLibrary:
    def __init__(self, path: Optional[str] = None):
        from app.core.config import settings

        self.path = path or settings.WORKSHEET_LOCAL_CONTEXT_PATH
        self._objects: List[Dict[str, Any]] = []
        self._loaded = False

    def _ensure_loaded(self) -> None:
        if self._loaded:
            return
        self._loaded = True
        if not self.path:
            return
        try:
            data = json.loads(Path(self.path).read_text(encoding="utf-8"))
            objects = data.get("objects") if isinstance(data, dict) else None
            if isinstance(objects, list):
                self._objects = [o for o in objects if isinstance(o, dict) and o.get("name_hi")]
        except Exception as exc:
            logger.warning("Local-context library unreadable (%s); using fallback.", exc)

    def objects_for(self, grade: int, subject: str) -> List[Dict[str, Any]]:
        """Approved objects for grade/subject; fallback when library is absent."""
        self._ensure_loaded()
        if not self._objects:
            return list(FALLBACK_OBJECTS)
        matched = [
            o for o in self._objects
            if (not o.get("grades") or grade in o["grades"])
            and (not o.get("subjects") or subject in o["subjects"])
        ]
        return matched or list(FALLBACK_OBJECTS)
