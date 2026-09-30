from typing import List, Optional
from fastapi import APIRouter, Depends, Query
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.dependencies import get_db, require_reviewer
from app.core.security import UserContext
from app.db.models.language_pack import VerifiedPhrase
from app.verified_phrases.schemas import VerifiedPhraseCreate, VerifiedPhraseResponse

router = APIRouter(prefix="/verified-phrases", tags=["Verified Phrases Bank"])


@router.get("", response_model=List[VerifiedPhraseResponse], summary="List Verified Phrases")
async def list_verified_phrases(
    category: Optional[str] = Query(None),
    domain: Optional[str] = Query(None),
    status: Optional[str] = Query("VERIFIED"),
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=200),
    db: AsyncSession = Depends(get_db),
):
    """
    Returns curated high-confidence phrases for inclusion into regional language packs.
    """
    query = select(VerifiedPhrase)
    if status:
        query = query.where(VerifiedPhrase.verification_status == status)
    if category:
        query = query.where(VerifiedPhrase.category == category)
    if domain:
        query = query.where(VerifiedPhrase.domain == domain)

    res = await db.execute(query.offset(skip).limit(limit).order_by(VerifiedPhrase.created_at.desc()))
    return res.scalars().all()


@router.post("", response_model=VerifiedPhraseResponse, summary="Add Verified Phrase (Reviewer/Admin only)")
async def create_verified_phrase(
    req: VerifiedPhraseCreate,
    db: AsyncSession = Depends(get_db),
    reviewer: UserContext = Depends(require_reviewer),
):
    phrase = VerifiedPhrase(
        source_text=req.source_text,
        translated_text=req.translated_text,
        source_language_id=req.source_language_id,
        target_language_id=req.target_language_id,
        category=req.category,
        domain=req.domain,
        verification_status=req.verification_status,
        verified_by=reviewer.user_id,
    )
    db.add(phrase)
    await db.commit()
    await db.refresh(phrase)
    return phrase
