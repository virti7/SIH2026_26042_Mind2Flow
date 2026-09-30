from datetime import datetime
from typing import Any, Dict, List, Optional
from pydantic import BaseModel, ConfigDict


class ContentGenerationRequest(BaseModel):
    learning_outcome_id: Optional[str] = None
    blueprint_id: Optional[str] = None
    content_type: str = "lesson"  # lesson, activity, worksheet, flashcard, assessment
    grade: int = 1
    subject: str = "Hindi"
    target_language: str = "Ho"
    provider: str = "mock"  # only the offline mock provider remains
    mock_mode: bool = False
    force: bool = False
    additional_instructions: Optional[str] = None


class GeneratedContentResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    learning_outcome_id: Optional[str] = None
    content_type: str
    prompt_used: str
    raw_output: Dict[str, Any]
    validated_output: Optional[Dict[str, Any]] = None
    status: str  # GENERATED, REVIEW, APPROVED, PUBLISHED
    created_by: Optional[str] = None
    reviewed_by: Optional[str] = None
    review_notes: Optional[str] = None
    created_at: datetime


class ContentStatusUpdateRequest(BaseModel):
    status: str  # REVIEW, APPROVED, PUBLISHED
    review_notes: Optional[str] = None
    validated_output: Optional[Dict[str, Any]] = None
    publish_to_catalog: bool = False


class ReviewUpdateRequest(BaseModel):
    status: Optional[str] = None  # pending, in_review, changes_requested, approved, rejected
    gates: Optional[Dict[str, str]] = None  # hindi, santali, curriculum, answer_key, provisional_range
    santali_script_confirmed: Optional[str] = None  # Olck, Deva, Beng, Orya, Latn
    notes: Optional[str] = None


class ReviewRecordResponse(BaseModel):
    schema_version: str
    content_id: str
    blueprint_id: str
    curriculum_id: str
    content_sha256: str
    validator_report: Dict[str, Any]
    review_status: str
    gates: Dict[str, str]
    santali_script_confirmed: Optional[str] = None
    reviewer_notes: List[Dict[str, Any]] = []
    approved_by: Optional[List[str]] = None
    approved_at: Optional[str] = None


class ContentPublishRequest(BaseModel):
    dry_run: bool = False
    publish_to_catalog: bool = True


class ContentPublishResponse(BaseModel):
    content_id: str
    content_type: str
    status: str  # published, already_published, dry_run
    is_idempotent: bool = False
    record_ids: Dict[str, Any] = {}
    storage_paths: List[str] = []
    details: Optional[Dict[str, Any]] = None


class TeacherGenerationRequest(BaseModel):
    content_type: str = "worksheet"  # worksheet, flashcard
    grade: int = 1
    section: Optional[str] = None
    subject: str = "Mathematics"
    curriculum_id: Optional[str] = None
    learning_outcome_id: Optional[str] = None
    outcome_code: Optional[str] = None
    target_language: str = "sat"  # sat, ho, mundari
    difficulty: str = "medium"  # easy, medium, hard
    worksheet_type: Optional[str] = "practice"
    worksheet_types: Optional[List[str]] = None
    question_count: Optional[int] = 3
    # Santali multilingual flashcard parameters (additive; worksheet
    # clients omit them). language_mode is Hi/En/Sat only.
    language_mode: Optional[str] = None  # hi_sat | en_sat | hi_en_sat
    flashcard_type: Optional[str] = None  # vocabulary | object_identification | ...
    card_count: Optional[int] = None  # 1-20
    visual_style: Optional[str] = None  # illustrated | vector | photo_neutral
    pronunciation: Optional[bool] = None
    learning_outcome: Optional[str] = None
    strand: Optional[str] = None
    idempotency_key: Optional[str] = None
    # Full worksheet parameters (additive; older clients omit them).
    request_id: Optional[str] = None
    topic: Optional[str] = None
    topic_source: Optional[str] = None  # curriculum | custom
    topic_id: Optional[str] = None
    topic_input_language: Optional[str] = None  # hi | en
    nipun_outcome: Optional[str] = None
    source_language: Optional[str] = None
    language_1: Optional[str] = None
    language_2: Optional[str] = None
    visual_support: Optional[bool] = None
    visual_illustrations: Optional[bool] = None
    bilingual_answers: Optional[bool] = None
    bilingual_answer_spaces: Optional[bool] = None
    audio_cue: Optional[bool] = None
    audio_pronunciation: Optional[bool] = None
    device_id: Optional[str] = None
    teacher_id: Optional[str] = None
    origin: Optional[str] = None
    created_at: Optional[str] = None


class GenerationJobResponse(BaseModel):
    job_id: str
    status: str  # PENDING, GENERATING, VALIDATING, REVIEW_REQUIRED, APPROVED, READY, FAILED
    content_id: Optional[str] = None
    content_type: str
    grade: int
    target_language: str
    error: Optional[str] = None
    review_gates: Optional[Dict[str, str]] = None
    content: Optional[Dict[str, Any]] = None
    assets: Optional[Dict[str, Any]] = None
    created_at: datetime
    updated_at: datetime
    provider: Optional[str] = None
    translation_coverage: Optional[Dict[str, Any]] = None


class JobApproveRequest(BaseModel):
    santali_script_confirmed: Optional[str] = "Olck"
    notes: Optional[str] = None


