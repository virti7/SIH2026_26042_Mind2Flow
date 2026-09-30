"""Worksheet generation request/response schemas."""
from typing import Any, Dict, List, Optional
from pydantic import BaseModel, Field, field_validator


class WorksheetGenerationParams(BaseModel):
    """Full teacher-selected worksheet parameters (online + offline + sync)."""

    request_id: str = Field(..., description="Unique request UUID (idempotency key)")
    teacher_id: Optional[str] = None
    device_id: Optional[str] = None
    grade: int = Field(..., ge=1, le=12)
    section: Optional[str] = Field(default=None, description="Classroom section, e.g. A")
    subject: str
    # Topic handling: curriculum reference OR free-text custom topic.
    topic_source: str = Field(default="curriculum", description="curriculum | custom")
    topic_id: Optional[str] = None
    topic_input_language: str = Field(default="en", description="hi | en (custom topic language)")
    topic: str = Field(..., description="Topic text exactly as entered/selected")
    nipun_outcome: Optional[str] = None
    nipun_code: Optional[str] = None
    # Bilingual pair. source_language/language_1 and target_language/language_2
    # are aliases: language_1 is the primary side, language_2 the secondary.
    source_language: str = "hi"
    target_language: str
    language_1: Optional[str] = None
    language_2: Optional[str] = None
    worksheet_type: str = "practice"
    worksheet_types: Optional[List[str]] = Field(default=None, description="All selected types")
    question_count: int = Field(..., ge=1, le=50)
    difficulty: str = "medium"
    visual_support: bool = True
    visual_illustrations: Optional[bool] = None
    bilingual_answers: bool = True
    bilingual_answer_spaces: Optional[bool] = None
    audio_cue: bool = False
    audio_pronunciation: Optional[bool] = None
    output_format: str = "bilingual_worksheet_v1"
    origin: str = "online"  # online | offline
    created_at: Optional[str] = None

    @field_validator("subject", "topic", "target_language")
    @classmethod
    def _non_empty(cls, v: str) -> str:
        if not (v or "").strip():
            raise ValueError("must not be empty")
        return v.strip()

    def resolved_languages(self) -> tuple:
        """Return (language_1, language_2) with alias fallback."""
        l1 = (self.language_1 or self.source_language or "hi").strip()
        l2 = (self.language_2 or self.target_language or "").strip()
        return l1, l2

    def resolved_types(self) -> List[str]:
        """Return every selected worksheet type as canonical codes."""
        from app.worksheets.builder import normalize_worksheet_types

        if self.worksheet_types:
            return normalize_worksheet_types(self.worksheet_types)
        return normalize_worksheet_types(self.worksheet_type or "practice")

    def resolved_visual(self) -> bool:
        return self.visual_illustrations if self.visual_illustrations is not None else self.visual_support

    def resolved_bilingual_answers(self) -> bool:
        return self.bilingual_answer_spaces if self.bilingual_answer_spaces is not None else self.bilingual_answers

    def resolved_audio(self) -> bool:
        return self.audio_pronunciation if self.audio_pronunciation is not None else self.audio_cue


class BilingualField(BaseModel):
    source: str
    target: str
    provider: str = "sarvam-translate"
    translated: bool = True


class WorksheetQuestionDoc(BaseModel):
    id: str
    number: int
    type: str
    prompt: BilingualField
    options: List[Dict[str, Any]] = []
    answer: Dict[str, Any] = {}
    hint: Optional[BilingualField] = None
    visual: Optional[str] = None


class WorksheetDocument(BaseModel):
    content_id: str
    request_id: str
    title: BilingualField
    instructions: BilingualField
    questions: List[WorksheetQuestionDoc]
    teacher_notes: Optional[BilingualField] = None
    metadata: Dict[str, Any] = {}


class WorksheetGenerationResult(BaseModel):
    request_id: str
    content_id: Optional[str] = None
    status: str  # READY | REVIEW_REQUIRED | FAILED
    provider: Optional[str] = None
    coverage: Dict[str, Any] = {}
    content: Optional[Dict[str, Any]] = None
    assets: Dict[str, Any] = {}
    saved_material_id: Optional[str] = None
    review_gates: Optional[Dict[str, str]] = None
    error: Optional[str] = None
    retryable: bool = False
