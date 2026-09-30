"""Santali multilingual flashcard endpoints (Hi/En/Sat only)."""
from fastapi import APIRouter, Depends, status
from fastapi.responses import Response
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.ai.schemas import GenerationJobResponse, TeacherGenerationRequest
from app.core.dependencies import get_current_user, get_db, require_teacher
from app.core.exceptions import BadRequestException, NotFoundException
from app.core.security import UserContext
from app.services.generation_jobs import generation_job_manager

router = APIRouter(tags=["Santali Flashcards"])


@router.post(
    "/content/flashcards/generate",
    response_model=GenerationJobResponse,
    status_code=status.HTTP_202_ACCEPTED,
    summary="Request Santali flashcard generation (Hi/En/Sat only)",
)
async def generate_santali_flashcards(
    req: TeacherGenerationRequest,
    current_user: UserContext = Depends(require_teacher),
):
    req.content_type = "flashcard"
    mode = (req.language_mode or "hi_sat").strip()
    if mode not in ("hi_sat", "en_sat", "hi_en_sat"):
        raise BadRequestException(
            "language_mode must be one of hi_sat, en_sat, hi_en_sat."
        )
    if req.grade not in (1, 2, 3, 4, 5):
        raise BadRequestException(
            f"Grade {req.grade} is unsupported. Only Classes 1-5 are supported."
        )
    if req.card_count is not None and not (1 <= req.card_count <= 20):
        raise BadRequestException("card_count must be between 1 and 20.")
    if not (req.topic or "").strip():
        raise BadRequestException("Topic must not be empty.")
    job = generation_job_manager.create_job(
        req=req, teacher_id=current_user.user_id, provider=None,
    )
    if job.status == "PENDING":
        generation_job_manager.schedule_job(job.job_id)
    return job


@router.get(
    "/content/flashcards/catalog",
    summary="Prototype flashcard image catalog (image-first, no Sarvam)",
)
async def get_flashcard_catalog(
    current_user: UserContext = Depends(get_current_user),
):
    """Topics and pictures served straight from the prototype image catalog.

    Requests whose topic matches a catalog topic are built from the bundled
    pictures and printed Santali labels (source IMAGE_CATALOG); any other
    topic uses the Sarvam pipeline (source AI_GENERATED). Asset paths are
    logical Flutter asset identifiers, never server disk paths.
    """
    from app.flashcards.image_library import (
        SOURCE_IMAGE_CATALOG,
        flashcard_image_library,
    )

    return {
        "source": SOURCE_IMAGE_CATALOG,
        "topics": [d.to_summary() for d in flashcard_image_library.decks()],
        "items": flashcard_image_library.catalog_items(),
    }


@router.get(
    "/content/flashcards/jobs/{job_id}",
    response_model=GenerationJobResponse,
    summary="Get Santali flashcard job status",
)
async def get_santali_flashcard_job(
    job_id: str,
    current_user: UserContext = Depends(get_current_user),
):
    job = generation_job_manager.get_job(job_id)
    if not job:
        raise NotFoundException("GenerationJob", job_id)
    if (generation_job_manager.job_owner(job_id) or "") != current_user.user_id:
        raise NotFoundException("GenerationJob", job_id)
    return job


@router.get(
    "/content/flashcards/{content_id}/download",
    summary="Download generated flashcard PDF (canonical server copy)",
    response_class=Response,
)
async def download_santali_flashcard_pdf(
    content_id: str,
    db: AsyncSession = Depends(get_db),
    current_user: UserContext = Depends(get_current_user),
):
    from app.db.models.resource import SavedMaterial
    from app.flashcards.pdf import render_flashcard_pdf
    from app.flashcards.schemas import FlashcardDocument, FlashcardItem

    res = await db.execute(
        select(SavedMaterial).where(
            (SavedMaterial.local_id == content_id) | (SavedMaterial.id == content_id),
            SavedMaterial.deleted_at.is_(None),
        )
    )
    material = res.scalar_one_or_none()
    if material is None or not isinstance(material.payload, dict):
        raise NotFoundException("Flashcard", content_id)
    from app.core.ownership import (
        ensure_owner_match as _ensure_owner,
        require_teacher as _require_teacher,
    )
    _teacher = await _require_teacher(db, current_user)
    _ensure_owner(getattr(material, "teacher_id", None), _teacher.id, "Flashcard", content_id)
    payload = material.payload
    if payload.get("content_type") != "flashcard" or not payload.get("cards"):
        raise NotFoundException("Flashcard", content_id)
    cards = []
    for i, c in enumerate(payload["cards"] or []):
        if not isinstance(c, dict):
            continue
        cards.append(FlashcardItem(
            id=str(c.get("id", f"card_{i + 1:02d}")),
            number=int(c.get("number", i + 1)),
            concept=str(c.get("concept", "")),
            type=str(c.get("type", payload.get("flashcard_type", "vocabulary"))),
            hindi=c.get("hindi"),
            english=c.get("english"),
            santali=str(c.get("santali", "")),
            visual=dict(c.get("visual", {}) or {}),
            provider=str(c.get("provider", "server")),
            translated=bool(c.get("translated", True)),
        ))
    meta = payload.get("metadata") if isinstance(payload.get("metadata"), dict) else {}
    doc = FlashcardDocument(
        content_id=content_id,
        request_id=str(payload.get("request_id", content_id)),
        title=str(payload.get("title", "Flashcards")),
        cards=cards,
        metadata={
            "grade": payload.get("grade"),
            "section": payload.get("section"),
            "subject": payload.get("subject"),
            "topic": payload.get("topic"),
            "language_mode": payload.get("language_mode"),
            "flashcard_type": payload.get("flashcard_type"),
            "pronunciation": payload.get("pronunciation"),
        } | {k: v for k, v in meta.items() if k not in ()},
    )
    pdf_bytes = render_flashcard_pdf(doc)
    return Response(
        content=pdf_bytes,
        media_type="application/pdf",
        headers={"Content-Disposition": f'attachment; filename="{content_id}.pdf"'},
    )
