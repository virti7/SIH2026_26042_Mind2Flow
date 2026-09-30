"""Santali flashcard request/response schemas.

Only three languages are allowed in this generator: Hindi (hi),
English (en), Santali (sat). No Ho, no Mundari, no other language.
"""
from typing import Any, Dict, List, Optional
from pydantic import BaseModel, Field, field_validator

# Internal codes for this generator.
ALLOWED_CODES = {"hi", "en", "sat"}
# BCP-47 codes for API labels.
BCP47_CODES = {"hi": "hi-IN", "en": "en-IN", "sat": "sat-IN"}

# Language modes teacher can choose.
LANGUAGE_MODES = ("hi_sat", "en_sat", "hi_en_sat")

# Flashcard types served by the single underlying generator.
FLASHCARD_TYPES = (
    "vocabulary",
    "object_identification",
    "action",
    "number",
    "shape",
    "color",
    "concept",
)

VISUAL_STYLES = ("illustrated", "vector", "photo_neutral")


class FlashcardGenerationParams(BaseModel):
    """Teacher-selected flashcard parameters (online + offline + sync)."""

    request_id: str = Field(..., description="Unique request UUID (idempotency key)")
    teacher_id: Optional[str] = None
    device_id: Optional[str] = None
    grade: int = Field(..., ge=1, le=5)
    section: Optional[str] = None
    subject: str = Field(...)
    topic: str = Field(..., description="Topic text exactly as entered/selected")
    topic_source: str = Field(default="curriculum")
    topic_id: Optional[str] = None
    topic_input_language: str = Field(default="en")
    nipun_outcome: Optional[str] = None
    nipun_code: Optional[str] = None
    strand: Optional[str] = None
    language_mode: str = Field(default="hi_sat")
    flashcard_type: str = Field(default="vocabulary")
    card_count: int = Field(default=8, ge=1, le=20)
    difficulty: str = Field(default="medium")
    visual_style: str = Field(default="illustrated")
    pronunciation: bool = Field(default=False)
    origin: str = "online"
    created_at: Optional[str] = None

    @field_validator("subject", "topic")
    @classmethod
    def _non_empty(cls, v: str) -> str:
        if not (v or "").strip():
            raise ValueError("must not be empty")
        return v.strip()

    @field_validator("language_mode")
    @classmethod
    def _mode_ok(cls, v: str) -> str:
        if (v or "").strip() not in LANGUAGE_MODES:
            raise ValueError(f"language_mode must be one of {list(LANGUAGE_MODES)}")
        return v.strip()

    @field_validator("flashcard_type")
    @classmethod
    def _type_ok(cls, v: str) -> str:
        if (v or "").strip() not in FLASHCARD_TYPES:
            raise ValueError(f"flashcard_type must be one of {list(FLASHCARD_TYPES)}")
        return v.strip()

    def source_languages(self) -> List[str]:
        """Anchor languages authored by the curriculum scaffold."""
        if self.language_mode == "hi_sat":
            return ["hi"]
        if self.language_mode == "en_sat":
            return ["en"]
        return ["hi", "en"]

    def includes(self, code: str) -> bool:
        if code == "sat":
            return True
        if self.language_mode == "hi_sat":
            return code == "hi"
        if self.language_mode == "en_sat":
            return code == "en"
        return code in ("hi", "en")


class FlashcardItem(BaseModel):
    id: str
    number: int
    concept: str
    type: str
    hindi: Optional[str] = None
    english: Optional[str] = None
    santali: str = ""
    # Exact anchor text + language the Santali output was translated from
    # (deterministic per language mode; see service TRILINGUAL FLOW note).
    santali_source: str = ""
    santali_source_lang: str = ""
    pronunciation_hi: Optional[str] = None
    pronunciation_en: Optional[str] = None
    pronunciation_sat: Optional[str] = None
    visual: Dict[str, Any] = {}
    provider: str = "sarvam-translate"
    translated: bool = True


class FlashcardDocument(BaseModel):
    content_id: str
    request_id: str
    title: str
    cards: List[FlashcardItem]
    metadata: Dict[str, Any] = {}


class FlashcardGenerationResult(BaseModel):
    request_id: str
    content_id: Optional[str] = None
    status: str  # READY | FAILED
    provider: Optional[str] = None
    coverage: Dict[str, Any] = {}
    content: Optional[Dict[str, Any]] = None
    assets: Dict[str, Any] = {}
    saved_material_id: Optional[str] = None
    error: Optional[str] = None
    retryable: bool = False
