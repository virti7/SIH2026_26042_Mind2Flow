from typing import List, Optional
from fastapi import APIRouter, Depends, Query
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.dependencies import get_db, require_admin
from app.core.security import UserContext
from app.db.models.language_pack import ModelVersion
from app.model_versions.schemas import ModelVersionCreate, ModelVersionResponse

router = APIRouter(prefix="/model-versions", tags=["Model Versions"])


@router.get("", response_model=List[ModelVersionResponse], summary="List Model Versions")
async def list_model_versions(
    model_type: Optional[str] = Query(None),
    language_code: Optional[str] = Query(None),
    db: AsyncSession = Depends(get_db),
):
    """
    Returns metadata for on-device AI models (ASR, NMT, TTS).
    Does NOT run live models on server.
    """
    query = select(ModelVersion)
    if model_type:
        query = query.where(ModelVersion.model_type == model_type.lower())
    if language_code:
        query = query.where(ModelVersion.language_code == language_code.lower())

    res = await db.execute(query.order_by(ModelVersion.created_at.desc()))
    return res.scalars().all()


@router.post("", response_model=ModelVersionResponse, summary="Register Model Version (Admin only)")
async def create_model_version(
    req: ModelVersionCreate,
    db: AsyncSession = Depends(get_db),
    admin_user: UserContext = Depends(require_admin),
):
    model = ModelVersion(**req.model_dump())
    db.add(model)
    await db.commit()
    await db.refresh(model)
    return model
