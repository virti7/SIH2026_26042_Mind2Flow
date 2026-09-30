from typing import List
from fastapi import APIRouter, Depends
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.dependencies import get_db, require_admin
from app.core.exceptions import ConflictException, NotFoundException
from app.core.security import UserContext
from app.db.models.school import Language
from app.languages.schemas import LanguageCreate, LanguageResponse

router = APIRouter(prefix="/languages", tags=["Languages"])


@router.get("", response_model=List[LanguageResponse], summary="List Languages")
async def list_languages(
    db: AsyncSession = Depends(get_db),
):
    """
    Returns all supported educational and tribal languages (Hindi, Ho, Mundari, Santali, etc.).
    Open to authenticated and guest clients.
    """
    res = await db.execute(select(Language).order_by(Language.name))
    return res.scalars().all()


@router.get("/{code}", response_model=LanguageResponse, summary="Get Language by Code")
async def get_language(
    code: str,
    db: AsyncSession = Depends(get_db),
):
    res = await db.execute(select(Language).where(Language.code == code.lower()))
    lang = res.scalar_one_or_none()
    if not lang:
        raise NotFoundException("Language", code)
    return lang


@router.post("", response_model=LanguageResponse, summary="Register New Language (Admin only)")
async def create_language(
    req: LanguageCreate,
    db: AsyncSession = Depends(get_db),
    admin_user: UserContext = Depends(require_admin),
):
    existing = await db.execute(select(Language).where(Language.code == req.code.lower()))
    if existing.scalar_one_or_none():
        raise ConflictException(f"Language with code '{req.code}' already exists")

    lang = Language(
        code=req.code.lower(),
        name=req.name,
        script=req.script,
        is_active=req.is_active,
    )
    db.add(lang)
    await db.commit()
    await db.refresh(lang)
    return lang
