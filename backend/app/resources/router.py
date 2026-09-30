from datetime import datetime, timezone
from typing import List, Optional
from fastapi import APIRouter, BackgroundTasks, Depends, Query, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.ai.schemas import GenerationJobResponse, TeacherGenerationRequest
from app.core.dependencies import get_current_user, get_db, require_reviewer, require_teacher
from app.core.security import UserContext
from app.db.models.resource import Flashcard, SavedMaterial, Worksheet
from app.db.models.school import Teacher
from app.core.exceptions import BadRequestException, NotFoundException
from app.resources.schemas import (
    FlashcardCreate,
    FlashcardResponse,
    FlashcardDeckResponse,
    FlashcardDeckDetailResponse,
    SavedMaterialCreate,
    SavedMaterialResponse,
    WorksheetCreate,
    WorksheetResponse,
)
from app.services.generation_jobs import generation_job_manager

router = APIRouter(tags=["Resources"])


@router.post(
    "/flashcards/generate",
    response_model=GenerationJobResponse,
    status_code=status.HTTP_202_ACCEPTED,
    summary="Request Bilingual Flashcard Generation (Asynchronous)",
)
async def generate_flashcards(
    req: TeacherGenerationRequest,
    background_tasks: BackgroundTasks,
    current_user: UserContext = Depends(require_teacher),
):
    """Teacher-facing flashcard generation.
    Deterministic blueprint resolution, curriculum validation, Sarvam / Mock generation.
    """
    req.content_type = "flashcard"
    # Validate grade (Grade 1 and Grade 2 prototype scope)
    if req.grade not in (1, 2):
        raise BadRequestException(f"Grade {req.grade} is unsupported. Only Grade 1 and Grade 2 are supported.")
    # Validate language
    if req.target_language and req.target_language not in ("sat", "ho", "mundari", "unr", "hi"):
        raise BadRequestException(f"Language '{req.target_language}' is not supported.")

    job = generation_job_manager.create_job(
        req=req,
        teacher_id=current_user.user_id,
        provider=None,
    )
    if job.status == "PENDING":
        background_tasks.add_task(generation_job_manager.execute_job_sync, job.job_id)
    return job


@router.get(
    "/flashcards/jobs/{job_id}",
    response_model=GenerationJobResponse,
    summary="Get Flashcard Job Status",
)
async def get_flashcard_job_status(
    job_id: str,
    current_user: UserContext = Depends(get_current_user),
):
    job = generation_job_manager.get_job(job_id)
    if not job:
        raise NotFoundException("GenerationJob", job_id)
    return job


@router.post(
    "/flashcards/jobs/{job_id}/approve",
    response_model=GenerationJobResponse,
    summary="Approve Flashcard Job",
)
async def approve_flashcard_job(
    job_id: str,
    body: Optional[dict] = None,
    current_user: UserContext = Depends(require_teacher),
):
    body = body or {}
    job = generation_job_manager.get_job(job_id)
    if not job:
        raise NotFoundException("GenerationJob", job_id)
    updated = generation_job_manager.approve_job(
        job_id=job_id,
        reviewer_id=current_user.user_id,
        santali_script_confirmed=body.get("santali_script_confirmed"),
        notes=body.get("notes"),
    )
    if not updated:
        raise BadRequestException(f"Failed to approve job {job_id}")
    return updated


@router.get(
    "/flashcards/decks",
    response_model=List[FlashcardDeckResponse],
    summary="List Available Flashcard Decks",
)
async def list_flashcard_decks(
    grade: Optional[int] = Query(None),
    db: AsyncSession = Depends(get_db),
    current_user: UserContext = Depends(get_current_user),
):
    """Returns distinct flashcard decks available for classroom use."""
    from sqlalchemy import func
    query = select(
        Flashcard.deck_name,
        func.count(Flashcard.id).label("card_count"),
        Flashcard.grade,
        Flashcard.language_id,
        func.min(Flashcard.created_at).label("created_at"),
    ).group_by(Flashcard.deck_name, Flashcard.grade, Flashcard.language_id)

    if grade is not None:
        query = query.where(Flashcard.grade == grade)

    res = await db.execute(query)
    rows = res.all()
    decks = [
        FlashcardDeckResponse(
            deck_name=r.deck_name,
            card_count=r.card_count,
            grade=r.grade,
            language_id=r.language_id,
            created_at=r.created_at,
        )
        for r in rows
    ]

    # Also include any decks from SavedMaterial(type="flashcard")
    saved_res = await db.execute(
        select(SavedMaterial).where(SavedMaterial.material_type == "flashcard", SavedMaterial.deleted_at.is_(None))
    )
    saved_materials = saved_res.scalars().all()
    seen_decks = {d.deck_name for d in decks}
    for sm in saved_materials:
        sm_title = str(getattr(sm, "title", "") or "")
        if sm_title not in seen_decks:
            seen_decks.add(sm_title)
            sm_payload = sm.payload if isinstance(sm.payload, dict) else {}
            items = sm_payload.get("items", []) or sm_payload.get("cards", [])
            decks.append(
                FlashcardDeckResponse(
                    deck_name=sm_title,
                    card_count=len(items) if items else 5,
                    grade=int(sm_payload.get("grade", 1)),
                    language_id=str(sm_payload.get("target_language", "sat")),
                    created_at=getattr(sm, "created_at", None),
                )
            )

    return decks


@router.get(
    "/flashcards/decks/{deck_name}",
    response_model=FlashcardDeckDetailResponse,
    summary="Get Flashcard Deck Detail with Cards",
)
async def get_flashcard_deck(
    deck_name: str,
    db: AsyncSession = Depends(get_db),
    current_user: UserContext = Depends(get_current_user),
):
    """Returns all cards belonging to a named deck."""
    res = await db.execute(select(Flashcard).where(Flashcard.deck_name == deck_name))
    cards = res.scalars().all()
    if not cards:
        saved_res = await db.execute(
            select(SavedMaterial).where(
                SavedMaterial.material_type == "flashcard",
                (SavedMaterial.title == deck_name)
                | (SavedMaterial.id == deck_name)
                | (SavedMaterial.local_id == deck_name),
                SavedMaterial.deleted_at.is_(None),
            )
        )
        sm = saved_res.scalar_one_or_none()
        if not sm:
            raise NotFoundException("Flashcard deck", deck_name)

        sm_title = str(getattr(sm, "title", "") or "")
        sm_id = str(getattr(sm, "id", "") or "")
        sm_created_at = getattr(sm, "created_at", None)
        sm_payload = sm.payload if isinstance(sm.payload, dict) else {}
        raw_items = sm_payload.get("items", []) or sm_payload.get("cards", [])
        cards_list: list[FlashcardResponse] = []
        for idx, it in enumerate(raw_items):
            front = it.get("front", {})
            back = it.get("back", {})
            front_text = front.get("hi") if isinstance(front, dict) else str(front)
            back_text = back.get("sat") if isinstance(back, dict) else str(back)
            cards_list.append(
                FlashcardResponse(
                    id=f"{sm_id}_{idx}",
                    deck_name=sm_title,
                    front_text=front_text or "",
                    back_text=back_text or "",
                    grade=int(sm_payload.get("grade", 1)),
                    language_id=str(sm_payload.get("target_language", "sat")),
                    created_at=sm_created_at or datetime.now(timezone.utc),
                )
            )
        return FlashcardDeckDetailResponse(
            deck_name=sm_title,
            grade=int(sm_payload.get("grade", 1)),
            language_id=str(sm_payload.get("target_language", "sat")),
            cards=cards_list,
        )

    first_card = cards[0] if cards else None
    first_grade = int(getattr(first_card, "grade", 1)) if first_card else 1
    first_lang = str(getattr(first_card, "language_id", None) or "") if (first_card and getattr(first_card, "language_id", None)) else None

    return FlashcardDeckDetailResponse(
        deck_name=deck_name,
        grade=first_grade,
        language_id=first_lang,
        cards=[FlashcardResponse.model_validate(c) for c in cards],
    )


@router.post(
    "/worksheets/generate",
    response_model=GenerationJobResponse,
    status_code=status.HTTP_202_ACCEPTED,
    summary="Request Bilingual Worksheet Generation (Asynchronous)",
)
async def generate_worksheet(
    req: TeacherGenerationRequest,
    background_tasks: BackgroundTasks,
    current_user: UserContext = Depends(require_teacher),
):
    """Teacher-facing worksheet generation.

    Accepts the full teacher-selected parameters (grade, subject, topic, NIPUN
    outcome, source/target languages, worksheet type, question count,
    difficulty, visual/oral options). The server creates an idempotent
    generation job, runs the bilingual pipeline with the provider matching the
    requested target language (Sarvam Translate where supported, custom Ho /
    Mundari pipelines otherwise), and the client polls the job status —
    no extra Sync press is needed when online.
    """
    job = generation_job_manager.create_job(
        req=req,
        teacher_id=current_user.user_id,
        provider=None,
    )
    if job.status == "PENDING":
        background_tasks.add_task(generation_job_manager.execute_job_sync, job.job_id)
    return job


# Worksheets
@router.get("/worksheets", response_model=List[WorksheetResponse], summary="List Worksheets")
async def list_worksheets(
    grade: Optional[int] = Query(None),
    subject: Optional[str] = Query(None),
    learning_outcome_id: Optional[str] = Query(None),
    db: AsyncSession = Depends(get_db),
    current_user: UserContext = Depends(get_current_user),
):
    query = select(Worksheet)
    if grade is not None:
        query = query.where(Worksheet.grade == grade)
    if subject:
        query = query.where(Worksheet.subject == subject)
    if learning_outcome_id:
        query = query.where(Worksheet.learning_outcome_id == learning_outcome_id)

    res = await db.execute(query)
    return res.scalars().all()


@router.post("/worksheets", response_model=WorksheetResponse, summary="Create Worksheet (Reviewer/Admin only)")
async def create_worksheet(
    req: WorksheetCreate,
    db: AsyncSession = Depends(get_db),
    reviewer_user: UserContext = Depends(require_reviewer),
):
    worksheet = Worksheet(**req.model_dump())
    db.add(worksheet)
    await db.commit()
    await db.refresh(worksheet)
    return worksheet


# Flashcards
@router.get("/flashcards", response_model=List[FlashcardResponse], summary="List Flashcards")
async def list_flashcards(
    deck_name: Optional[str] = Query(None),
    grade: Optional[int] = Query(None),
    db: AsyncSession = Depends(get_db),
    current_user: UserContext = Depends(get_current_user),
):
    query = select(Flashcard)
    if deck_name:
        query = query.where(Flashcard.deck_name == deck_name)
    if grade is not None:
        query = query.where(Flashcard.grade == grade)

    res = await db.execute(query)
    return res.scalars().all()


@router.post("/flashcards", response_model=FlashcardResponse, summary="Create Flashcard (Reviewer/Admin only)")
async def create_flashcard(
    req: FlashcardCreate,
    db: AsyncSession = Depends(get_db),
    reviewer_user: UserContext = Depends(require_reviewer),
):
    flashcard = Flashcard(**req.model_dump())
    db.add(flashcard)
    await db.commit()
    await db.refresh(flashcard)
    return flashcard


# Saved Materials (Teacher's personal materials library)
@router.get("/saved-materials", response_model=List[SavedMaterialResponse], summary="List Teacher's Saved Materials")
async def list_saved_materials(
    material_type: Optional[str] = Query(None),
    db: AsyncSession = Depends(get_db),
    current_user: UserContext = Depends(get_current_user),
):
    res = await db.execute(select(Teacher).where(Teacher.user_id == current_user.user_id))
    teacher = res.scalar_one_or_none()
    teacher_id = teacher.id if teacher else "anonymous-teacher"

    query = select(SavedMaterial).where(
        SavedMaterial.teacher_id == teacher_id,
        SavedMaterial.deleted_at.is_(None),
    )
    if material_type:
        query = query.where(SavedMaterial.material_type == material_type)

    result = await db.execute(query.order_by(SavedMaterial.created_at.desc()))
    return result.scalars().all()


@router.post("/saved-materials", response_model=SavedMaterialResponse, summary="Save Teacher Material")
async def save_material(
    req: SavedMaterialCreate,
    db: AsyncSession = Depends(get_db),
    current_user: UserContext = Depends(get_current_user),
):
    res = await db.execute(select(Teacher).where(Teacher.user_id == current_user.user_id))
    teacher = res.scalar_one_or_none()
    teacher_id = teacher.id if teacher else "anonymous-teacher"

    material = SavedMaterial(
        teacher_id=teacher_id,
        title=req.title,
        material_type=req.material_type,
        payload=req.payload,
        local_id=req.local_id,
    )
    db.add(material)
    await db.commit()
    await db.refresh(material)
    return material
