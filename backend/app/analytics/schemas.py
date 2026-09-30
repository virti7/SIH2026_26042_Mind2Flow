from datetime import datetime
from typing import Any, Dict, List, Optional
from pydantic import BaseModel, ConfigDict


class AnalyticsSummaryResponse(BaseModel):
    total_teachers: int
    total_schools: int
    total_lessons: int
    total_assessments_taken: int
    total_sync_operations_processed: int
    total_translation_feedback: int
    total_verified_phrases: int
    active_language_packs: int
    timestamp: datetime


class SyncLogResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    operation_id: str
    device_id: str
    entity_type: str
    entity_id: str
    operation: str
    status: str
    error_details: Optional[str] = None
    received_at: datetime
    processed_at: datetime

