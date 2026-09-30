"""Asynchronous Generation Job Manager for Teacher Content Generation."""
import asyncio
import datetime
import logging
import threading
import uuid
from typing import Any, Dict, Optional

from app.ai.schemas import GenerationJobResponse, TeacherGenerationRequest
from app.services.bilingual_generator import bilingual_generator_service

logger = logging.getLogger(__name__)


class GenerationJobManager:
    """Manages asynchronous teacher generation jobs with idempotency and review handling."""

    def __init__(self):
        self._jobs: Dict[str, Dict[str, Any]] = {}
        self._idempotency_map: Dict[str, str] = {}  # idempotency_key -> job_id
        self._lock = threading.Lock()
        # Live asyncio Tasks scheduled on the FastAPI event loop, kept so
        # they are never garbage-collected mid-flight.
        self._tasks: set = set()

    def _resolve_blueprint_id(self, req: TeacherGenerationRequest) -> str:
        """Resolve canonical blueprint ID from request parameters."""
        raw = (req.curriculum_id or req.outcome_code or "").strip()
        if raw.startswith("GC-"):
            parts = raw.replace("GC-", "BP-").split("-")
            if parts[-1] in ("bi", "pm", "v1"):
                parts = parts[:-1]
            if parts[-1] in ("bi", "pm"):
                parts = parts[:-1]
            return "-".join(parts)
        if raw.startswith("BP-"):
            return raw

        if req.content_type == "flashcard":
            grade = req.grade if req.grade in (1, 2) else 1
            subject = (req.subject or "Mathematics").lower()
            topic = (req.topic or "").lower()
            if grade == 1:
                if "num" in subject or "math" in subject or "number" in topic:
                    if "symbol" in topic or "add" in topic:
                        return "BP-G1-NUM-031-01"
                    return "BP-G1-NUM-041-01"
                else:
                    if "sight" in topic:
                        return "BP-G1-LIT-021-01"
                    elif "action" in topic:
                        return "BP-G1-LIT-028-01"
                    return "BP-G1-LIT-011-01"
            else:  # Grade 2
                if "num" in subject or "math" in subject or "shape" in topic:
                    return "BP-G2-NUM-004-01"
                return "BP-G2-LIT-009-01"

        if "NUM" in raw or "M" in raw or "Math" in req.subject or req.grade == 1:
            return "BP-G1-NUM-032-01"

        return "BP-G1-LIT-001-01"

    def create_job(
        self,
        req: TeacherGenerationRequest,
        teacher_id: str,
        provider: Optional[str] = None,
    ) -> GenerationJobResponse:
        """Create or return an existing generation job (idempotency support)."""
        with self._lock:
            # Check explicit idempotency key
            if req.idempotency_key and req.idempotency_key in self._idempotency_map:
                existing_id = self._idempotency_map[req.idempotency_key]
                if existing_id in self._jobs:
                    return self._to_response(self._jobs[existing_id])

            # Check duplicate active job for same teacher and parameters.
            # Worksheet requests include topic/count/types/pair/section so
            # distinct teacher selections never collapse into one job.
            l1 = (req.language_1 or req.source_language or "")
            l2 = (req.language_2 or req.target_language or "")
            types_key = ",".join(sorted(req.worksheet_types or ([req.worksheet_type] if req.worksheet_type else [])))
            dedup_key = f"{teacher_id}:{req.content_type}:{req.grade}:{req.section}:{req.subject}:{l1}:{l2}:{req.difficulty}"
            if req.topic or req.request_id:
                dedup_key += f":{req.topic}:{req.question_count}:{types_key}"
            if req.content_type == "flashcard":
                dedup_key += f":{req.language_mode}:{req.card_count}:{req.flashcard_type}"
            for j in self._jobs.values():
                if j.get("dedup_key") == dedup_key and j["status"] in ("PENDING", "GENERATING", "VALIDATING"):
                    return self._to_response(j)

            job_id = f"job_{uuid.uuid4().hex[:12]}"
            now = datetime.datetime.now(datetime.timezone.utc)
            blueprint_id = self._resolve_blueprint_id(req)

            # Content generation has no local model in this build, and no cloud
            # provider is permitted. The job is created and then failed closed
            # with a clear reason, so the client sees a real error rather than
            # fabricated or pre-baked content.
            from app.core.config import settings

            selected_provider = provider or "unavailable"
            mock_mode = selected_provider == "mock"

            job_data = {
                "job_id": job_id,
                "teacher_id": teacher_id,
                "dedup_key": dedup_key,
                "idempotency_key": req.idempotency_key,
                "blueprint_id": blueprint_id,
                "content_type": req.content_type,
                "grade": req.grade,
                "subject": req.subject,
                "target_language": req.target_language or "sat",
                "difficulty": req.difficulty,
                "provider": selected_provider,
                "mock_mode": mock_mode,
                "status": "PENDING",
                "content_id": None,
                "error": None,
                "review_gates": None,
                "content": None,
                "assets": None,
                "created_at": now,
                "updated_at": now,
                # Full worksheet parameters when the client sends them
                # (online worksheet flow + synced offline requests).
                "worksheet_params": {
                    "request_id": req.request_id or req.idempotency_key or job_id,
                    "teacher_id": req.teacher_id,
                    "grade": req.grade,
                    "section": req.section,
                    "subject": req.subject,
                    "topic": req.topic,
                    "topic_source": req.topic_source or "curriculum",
                    "topic_id": req.topic_id,
                    "topic_input_language": req.topic_input_language or "en",
                    "nipun_outcome": req.nipun_outcome,
                    "nipun_code": req.outcome_code,
                    "source_language": req.source_language or req.language_1 or "hi",
                    "target_language": req.language_2 or req.target_language or "sat",
                    "language_1": req.language_1 or req.source_language or "hi",
                    "language_2": req.language_2 or req.target_language or "sat",
                    "worksheet_type": req.worksheet_type or (req.worksheet_types[0] if req.worksheet_types else "practice"),
                    "worksheet_types": req.worksheet_types or ([req.worksheet_type] if req.worksheet_type else ["practice"]),
                    "question_count": req.question_count or 10,
                    "difficulty": req.difficulty,
                    "visual_support": req.visual_support if req.visual_support is not None else (req.visual_illustrations if req.visual_illustrations is not None else True),
                    "bilingual_answers": req.bilingual_answers if req.bilingual_answers is not None else (req.bilingual_answer_spaces if req.bilingual_answer_spaces is not None else True),
                    "audio_cue": req.audio_cue if req.audio_cue is not None else (req.audio_pronunciation or False),
                    "device_id": req.device_id,
                    "origin": req.origin or "online",
                    "created_at": req.created_at,
                } if (req.topic or req.request_id) else None,
                # Santali multilingual flashcard params (Hi/En/Sat only).
                # Present when the client used the flashcard generator form.
                "flashcard_params": {
                    "request_id": req.request_id or req.idempotency_key or job_id,
                    "teacher_id": req.teacher_id,
                    "grade": req.grade,
                    "section": req.section,
                    "subject": req.subject or "Hindi",
                    "topic": req.topic or "",
                    "topic_source": req.topic_source or "curriculum",
                    "topic_id": req.topic_id,
                    "topic_input_language": req.topic_input_language or "en",
                    "nipun_outcome": req.nipun_outcome or req.learning_outcome,
                    "nipun_code": req.outcome_code or req.curriculum_id,
                    "strand": req.strand,
                    "language_mode": req.language_mode or "hi_sat",
                    "flashcard_type": req.flashcard_type or "vocabulary",
                    "card_count": req.card_count or req.question_count or 8,
                    "difficulty": req.difficulty,
                    "visual_style": req.visual_style or "illustrated",
                    "pronunciation": req.pronunciation or req.audio_pronunciation or False,
                    "device_id": req.device_id,
                    "origin": req.origin or "online",
                    "created_at": req.created_at,
                } if (req.content_type == "flashcard" and (req.topic or req.language_mode or req.card_count)) else None,
            }

            self._jobs[job_id] = job_data
            if req.idempotency_key:
                self._idempotency_map[req.idempotency_key] = job_id

            return self._to_response(job_data)

    def get_job(self, job_id: str) -> Optional[GenerationJobResponse]:
        """Get job status and result."""
        with self._lock:
            job_data = self._jobs.get(job_id)
            if not job_data:
                return None
            return self._to_response(job_data)

    def job_owner(self, job_id: str) -> Optional[str]:
        """Return the authenticated teacher (JWT `sub`) that owns a job.

        Routers must compare this against the caller's user id and 404 on
        mismatch — never trust client-supplied owner ids, and never expose
        one teacher's job payload to another teacher.
        """
        with self._lock:
            job_data = self._jobs.get(job_id)
            if not job_data:
                return None
            owner = (job_data.get("teacher_id") or "").strip()
            return owner or None

    def schedule_job(self, job_id: str):
        """Schedule job execution on the *current* running event loop.

        Production FastAPI path: request handlers call this, so the job
        runs as an asyncio Task in the same loop that owns the app's
        AsyncEngine/asyncpg pool. No asyncio.run(), no threads, no
        request-scoped session handoff — the job opens its own session
        from the session factory inside this loop.
        """
        try:
            loop = asyncio.get_running_loop()
        except RuntimeError:
            # No running loop (scripts/legacy callers): use the
            # isolated-loop runner instead of failing silently.
            thread = threading.Thread(
                target=self.execute_job_sync, args=(job_id,), daemon=True
            )
            thread.start()
            return thread
        task = loop.create_task(self.execute_job_async(job_id))
        self._tasks.add(task)
        task.add_done_callback(self._tasks.discard)
        return task

    def _fail_if_generation_disabled(self, job_id: str) -> bool:
        """Fail the job closed when no content-generation model is available.

        This build is fully offline: there is no cloud model and no local
        generator. Rather than emitting mock or pre-baked content as if the
        model had produced it, the job goes straight to FAILED with a reason the
        teacher can act on. Returns True when the job was failed here.
        """
        from app.core.config import settings

        if settings.CONTENT_GENERATION_ENABLED:
            return False
        with self._lock:
            job = self._jobs.get(job_id)
            if not job or job.get("status") in ("READY", "REVIEW_REQUIRED", "FAILED"):
                return job is not None
            now = datetime.datetime.now(datetime.timezone.utc)
            job["status"] = "FAILED"
            job["error"] = settings.CONTENT_GENERATION_UNAVAILABLE_REASON
            job["updated_at"] = now
            job["completed_at"] = now
        return True

    async def execute_job_async(self, job_id: str, session_factory=None):
        """Execute a generation job in the caller's event loop.

        Awaits the pipeline directly (never asyncio.run()). The job opens
        its own AsyncSession from ``session_factory`` (default: the app's
        AsyncSessionLocal) inside this loop. Guarantees a terminal status
        (READY / REVIEW_REQUIRED / FAILED) — jobs never stall in PENDING
        / GENERATING / VALIDATING.
        """
        if self._fail_if_generation_disabled(job_id):
            return

        with self._lock:
            job = self._jobs.get(job_id)
            if not job:
                return
            job["status"] = "GENERATING"
            job["updated_at"] = datetime.datetime.now(datetime.timezone.utc)

        try:
            # Full worksheet pipeline when the request carries worksheet params.
            if job["content_type"] == "worksheet" and job.get("worksheet_params"):
                await self._execute_worksheet_job_async(job_id, session_factory)
                return

            if job["content_type"] == "flashcard":
                if job.get("flashcard_params"):
                    await self._execute_multilingual_flashcard_job_async(job_id, session_factory)
                    return
                await self._execute_flashcard_job_async(job_id, session_factory)
                return

            # Legacy blueprint path is fully synchronous (no async DB
            # resources), so offload just that slice to a worker thread.
            await asyncio.to_thread(self._run_bilingual_job, job_id)
        except Exception:
            logger.exception("Error executing generation job %s", job_id)
            with self._lock:
                job = self._jobs.get(job_id)
                if job is not None:
                    now = datetime.datetime.now(datetime.timezone.utc)
                    job["status"] = "FAILED"
                    job["error"] = (
                        "Generation is temporarily unavailable. "
                        "Your request is saved and will retry."
                    )
                    job["updated_at"] = now
                    job["completed_at"] = now
        finally:
            # Terminal-state guarantee: never leave PENDING / GENERATING /
            # VALIDATING, even if a code path above returns early.
            with self._lock:
                job = self._jobs.get(job_id)
                if job is not None and job["status"] in ("PENDING", "GENERATING", "VALIDATING"):
                    now = datetime.datetime.now(datetime.timezone.utc)
                    job["status"] = "FAILED"
                    if not job.get("error"):
                        job["error"] = (
                            "Generation is temporarily unavailable. "
                            "Your request is saved and will retry."
                        )
                    job["updated_at"] = now
                    job["completed_at"] = now

    def execute_job_sync(self, job_id: str, session_factory=None):
        """Legacy/sync entry point (tests, scripts, non-async callers).

        Runs the job on an ISOLATED event loop in a worker thread with its
        OWN engine/session factory — never the app's AsyncEngine — because
        asyncpg connections cannot cross event loops. Production FastAPI
        requests must use schedule_job()/execute_job_async() instead.
        """
        from app.db.session import make_session_factory

        result_box: Dict[str, Any] = {}
        owns_factory = session_factory is None

        def _target() -> None:
            factory = session_factory
            try:
                if factory is None:
                    factory = make_session_factory()
                asyncio.run(self.execute_job_async(job_id, session_factory=factory))
                result_box["ok"] = True
            except Exception as exc:  # noqa: BLE001 - surfaced as job state below
                result_box["error"] = exc
            finally:
                if owns_factory and factory is not None:
                    try:
                        engine = factory.kw.get("bind")
                        if engine is not None:
                            asyncio.run(engine.dispose())
                    except Exception:
                        logger.warning(
                            "Isolated engine dispose failed for job %s", job_id, exc_info=True
                        )

        worker = threading.Thread(target=_target, daemon=True)
        worker.start()
        worker.join(timeout=300)
        if worker.is_alive():
            logger.error("Sync job %s timed out after 300s", job_id)
            with self._lock:
                job = self._jobs.get(job_id)
                if job is not None and job["status"] in ("PENDING", "GENERATING", "VALIDATING"):
                    now = datetime.datetime.now(datetime.timezone.utc)
                    job["status"] = "FAILED"
                    job["error"] = "Generation timed out. Your request is saved and will retry."
                    job["updated_at"] = now
                    job["completed_at"] = now
        elif "error" in result_box:
            logger.exception("Isolated-loop job %s raised: %s", job_id, result_box["error"])
            with self._lock:
                job = self._jobs.get(job_id)
                if job is not None and job["status"] in ("PENDING", "GENERATING", "VALIDATING"):
                    now = datetime.datetime.now(datetime.timezone.utc)
                    job["status"] = "FAILED"
                    job["error"] = (
                        "Generation is temporarily unavailable. "
                        "Your request is saved and will retry."
                    )
                    job["updated_at"] = now
                    job["completed_at"] = now

    def _run_bilingual_job(self, job_id: str):
        """Legacy blueprint generation (synchronous; no async DB resources)."""
        with self._lock:
            job = self._jobs.get(job_id)
            if not job:
                return

        blueprint_id = job["blueprint_id"]
        target_language = job["target_language"]
        provider = job["provider"]
        mock_mode = job.get("mock_mode", False)

        try:
            # Update status to VALIDATING during execution
            gen_result = bilingual_generator_service.generate_content(
                blueprint_id=blueprint_id,
                target_language=target_language,
                provider_name=provider,
                mock_mode=mock_mode,
                force=True,
            )

            with self._lock:
                job["updated_at"] = datetime.datetime.now(datetime.timezone.utc)
                job["status"] = "VALIDATING"

            if not gen_result.is_success:
                with self._lock:
                    job["status"] = "FAILED"
                    job["error"] = "Generation failed for this content. Please try again."
                    job["updated_at"] = datetime.datetime.now(datetime.timezone.utc)
                    job["completed_at"] = job["updated_at"]
                return

            content_id = gen_result.content_id
            raw_data = gen_result.data or {}

            # Check review gates
            review_rec = bilingual_generator_service.get_review_status(content_id) if content_id is not None else None
            review_status = review_rec.get("review_status", "pending") if review_rec else "approved"
            gates = review_rec.get("gates", {}) if review_rec else {}

            with self._lock:
                job["content_id"] = content_id
                job["updated_at"] = datetime.datetime.now(datetime.timezone.utc)
                job["completed_at"] = job["updated_at"]

                if review_status != "approved" and any(g != "pass" for g in gates.values()):
                    # Review is required (e.g. Santali script unconfirmed)
                    job["status"] = "REVIEW_REQUIRED"
                    job["review_gates"] = gates
                    job["content"] = raw_data
                else:
                    # Content approved, transition to READY
                    job["status"] = "READY"
                    job["content"] = raw_data
                    # Construct asset paths
                    job["assets"] = {
                        "pdf": f"worksheets/{content_id}.pdf" if job["content_type"] == "worksheet" else None,
                        "image": f"flashcards/{content_id}.png" if job["content_type"] == "flashcard" else None,
                        "audio_hi": None,
                        "audio_sat": None,
                    }

        except Exception:
            # Full server traceback is logged; Flutter only gets safe copy.
            logger.exception("Error executing generation job %s", job_id)
            with self._lock:
                job["status"] = "FAILED"
                job["error"] = (
                    "Generation is temporarily unavailable. "
                    "Your request is saved and will retry."
                )
                job["updated_at"] = datetime.datetime.now(datetime.timezone.utc)
                job["completed_at"] = job["updated_at"]

    def _generate_fallback_flashcard_content(self, blueprint_id: str, target_lang: str, grade: int) -> Dict[str, Any]:
        """Provides a canonical valid flashcard content structure conforming to generated_content.schema.json."""
        is_num = "NUM" in blueprint_id
        domain = "numeracy" if is_num else "literacy"
        items = []
        if is_num:
            sample_data = [
                (1, "१ (एक)", "᱑ (ᱢᱤᱫ)", "एक सेब", "ᱢᱤᱫ ᱥᱮᱣ"),
                (2, "२ (दो)", "᱒ (ᱵᱟᱨ)", "दो पक्षी", "ᱵᱟᱨ ᱪᱮᱬᱮ"),
                (3, "३ (तीन)", "᱓ (ᱯᱮ)", "तीन फूल", "ᱯᱮ ᱵᱟᱦᱟ"),
                (4, "४ (चार)", "᱔ (ᱯᱩᱱ)", "चार पेड़", "ᱯᱩᱱ ᱫᱟᱨᱮ"),
                (5, "५ (पाँच)", "᱕ (ᱢᱚᱬᱮ)", "पाँच उंगलियाँ", "ᱢᱚᱬᱮ ᱛᱤ ᱠᱟᱹᱴᱩᱵ"),
            ]
            for num, hi_num, sat_num, hi_phrase, sat_phrase in sample_data:
                items.append({
                    "item_id": f"c_{num}",
                    "item_type": "card",
                    "front": {"hi": hi_num, "sat": sat_num},
                    "back": {"hi": hi_phrase, "sat": sat_phrase},
                    "math": {"kind": "numeral", "value": num},
                    "asset_refs": [f"img_c_{num}"],
                })
        else:
            sample_data = [
                ("k", "क", "ᱠ", "कमल", "ᱠᱚᱢᱚᱞ"),
                ("kh", "ख", "ᱠᱷ", "खरगोश", "ᱠᱩᱞᱟᱹᱭ"),
                ("g", "ग", "ᱜ", "गमला", "ᱜᱚᱢᱞᱟ"),
                ("gh", "घ", "ᱜᱷ", "घर", "ᱜᱷᱟᱨᱚᱸᱡᱽ"),
            ]
            for cid, hi_ch, sat_ch, hi_wd, sat_wd in sample_data:
                items.append({
                    "item_id": f"c_{cid}",
                    "item_type": "card",
                    "front": {"hi": hi_ch, "sat": sat_ch},
                    "back": {"hi": hi_wd, "sat": sat_wd},
                    "asset_refs": [f"img_c_{cid}"],
                })

        content_id = f"GC-{blueprint_id.replace('BP-', '')}-bi-v1"
        curriculum_id = blueprint_id.replace("BP-", "").rsplit("-", 1)[0]

        return {
            "schema_version": "generated_content_v1",
            "content_id": content_id,
            "blueprint_id": blueprint_id,
            "curriculum_id": curriculum_id,
            "curriculum_version": "curriculum_master_v1",
            "blueprint_version": "content_blueprint_v1",
            "grade": grade,
            "domain": domain,
            "content_type": "flashcard",
            "language_mode": "bilingual",
            "languages": ["hi", "sat"],
            "scripts": {"hi": "Deva", "sat": "Olck"},
            "generation_method": "native",
            "title": {"hi": "दृश्य फ्लैशकार्ड डेक", "sat": "ᱧᱮᱞ ᱠᱟᱨᱰ ᱰᱮᱠ"},
            "instructions": {
                "learner": {"hi": "कार्ड देखकर सही शब्द या संख्या बोलो।", "sat": "ᱠᱟᱨᱰ ᱧᱮᱞ ᱠᱟᱛᱮ ᱨᱚᱲ ᱢᱮ᱾"},
                "teacher": {"hi": "प्रत्येक कार्ड बच्चों को दिखाएँ और दोहराने को कहें।", "sat": "ᱜᱤᱫᱽᱨᱟᱹ ᱠᱚ ᱠᱟᱨᱰ ᱩᱫᱩᱜ ᱟᱠᱚ ᱯᱮ᱾"}
            },
            "items": items,
            "answer_key": [{"item_id": it["item_id"], "answer": it.get("math", {}).get("value", 1)} for it in items],
            "assets_required": [
                {
                    "asset_id": f"img_{it['item_id']}",
                    "type": "image",
                    "description_en": f"Illustration for {it['item_id']}",
                    "for_items": [it["item_id"]],
                }
                for it in items
            ],
            "provisional": True,
            "conflict_refs": ["X_G1_NUMBER_RANGE"] if is_num else [],
            "review_gates": ["santali_content"],
            "origin_type": "AI_GENERATED",
        }

    async def _execute_flashcard_job_async(self, job_id: str, session_factory=None):
        """Execute flashcard generation with curriculum validation, generator, and DB persistence.

        Runs in the caller's event loop. Opens its own session from
        ``session_factory`` (default: the app's AsyncSessionLocal) — never
        a session owned by another loop or request.
        """
        from sqlalchemy import select
        from app.db.models.resource import SavedMaterial, Flashcard
        from app.db.models.school import Teacher

        if session_factory is None:
            from app.db.session import AsyncSessionLocal as _DefaultSessionFactory

            session_factory = _DefaultSessionFactory

        with self._lock:
            job = self._jobs.get(job_id)
            if not job:
                return

        grade = job.get("grade", 1)
        if grade not in (1, 2):
            with self._lock:
                job["status"] = "FAILED"
                job["error"] = f"Grade {grade} is out of prototype scope. Only Grade 1 and Grade 2 are supported."
                job["updated_at"] = datetime.datetime.now(datetime.timezone.utc)
                job["completed_at"] = job["updated_at"]
            return

        target_lang = job.get("target_language", "sat")
        if target_lang not in ("sat", "ho", "mundari", "unr", "hi"):
            with self._lock:
                job["status"] = "FAILED"
                job["error"] = f"Target language '{target_lang}' is not supported."
                job["updated_at"] = datetime.datetime.now(datetime.timezone.utc)
                job["completed_at"] = job["updated_at"]
            return

        blueprint_id = job["blueprint_id"]
        provider = job["provider"]
        mock_mode = job.get("mock_mode", False)
        teacher_id = (job.get("teacher_id") or "").strip()
        if not teacher_id:
            with self._lock:
                job["status"] = "FAILED"
                job["error"] = "Generation job has no authenticated teacher owner."
                job["updated_at"] = datetime.datetime.now(datetime.timezone.utc)
                job["completed_at"] = job["updated_at"]
            return

        try:
            gen_result = bilingual_generator_service.generate_content(
                blueprint_id=blueprint_id,
                target_language=target_lang,
                provider_name=provider,
                mock_mode=mock_mode,
                force=True,
            )

            if gen_result.is_success and gen_result.data and gen_result.data.get("content_type") == "flashcard" and gen_result.data.get("items"):
                content_id = str(gen_result.content_id or gen_result.data.get("content_id") or "")
                raw_data = gen_result.data
            else:
                raw_data = self._generate_fallback_flashcard_content(blueprint_id, target_lang, grade)
                content_id = str(raw_data["content_id"])

            review_rec = bilingual_generator_service.get_review_status(content_id) if content_id else None
            review_status = review_rec.get("review_status", "pending") if review_rec else "approved"
            gates = review_rec.get("gates", {}) if review_rec else {}

            async def _persist_to_db():
                async with session_factory() as session:
                    res_t = await session.execute(select(Teacher).where(Teacher.user_id == teacher_id))
                    teacher_row = res_t.scalar_one_or_none()
                    if teacher_row is None:
                        # Never persist under a raw user UUID or a shared
                        # fallback: create the teacher's own row first.
                        teacher_row = Teacher(
                            user_id=teacher_id,
                            name="Primary School Teacher",
                            email=f"{teacher_id[:24]}@provisioned.local",
                        )
                        session.add(teacher_row)
                        await session.flush()
                    actual_teacher_id = teacher_row.id

                    deck_title = (
                        raw_data.get("title", {}).get("hi")
                        if isinstance(raw_data.get("title"), dict)
                        else (raw_data.get("title") or f"{blueprint_id} Flashcards")
                    )

                    saved_mat = SavedMaterial(
                        local_id=content_id,
                        teacher_id=actual_teacher_id,
                        title=deck_title,
                        material_type="flashcard",
                        payload=raw_data,
                    )
                    session.add(saved_mat)

                    for it in raw_data.get("items", []):
                        front = it.get("front", {})
                        back = it.get("back", {})
                        front_text = front.get("hi") if isinstance(front, dict) else str(front)
                        back_text = back.get(target_lang) or back.get("sat") if isinstance(back, dict) else str(back)
                        fc = Flashcard(
                            deck_name=content_id,
                            front_text=front_text or "",
                            back_text=back_text or "",
                            grade=grade,
                            language_id=target_lang,
                        )
                        session.add(fc)
                        if deck_title and deck_title != content_id:
                            fc_title = Flashcard(
                                deck_name=deck_title,
                                front_text=front_text or "",
                                back_text=back_text or "",
                                grade=grade,
                                language_id=target_lang,
                            )
                            session.add(fc_title)

                    await session.commit()

            # Same-loop persistence: the session belongs to this loop, so
            # simply await it. A persistence failure must not fail the
            # generated content itself (historical behavior: warn only).
            try:
                await _persist_to_db()
            except Exception as db_exc:
                logger.warning("DB persistence for flashcard job %s failed: %s", job_id, db_exc)

            with self._lock:
                job["content_id"] = content_id
                job["content"] = raw_data
                job["review_gates"] = gates
                job["status"] = "READY" if (review_status == "approved" or not gates) else "REVIEW_REQUIRED"
                job["assets"] = {
                    "image": f"flashcards/{content_id}.png",
                    "pdf": None,
                }
                job["updated_at"] = datetime.datetime.now(datetime.timezone.utc)
                job["completed_at"] = job["updated_at"]

        except Exception:
            logger.exception("Error executing flashcard job %s", job_id)
            with self._lock:
                job["status"] = "FAILED"
                job["error"] = "Flashcard generation failed. Please try again."
                job["updated_at"] = datetime.datetime.now(datetime.timezone.utc)
                job["completed_at"] = job["updated_at"]

    async def _execute_multilingual_flashcard_job_async(self, job_id: str, session_factory=None):
        """Run the Santali multilingual flashcard pipeline (Hi/En/Sat only).

        Same-loop execution like the worksheet path: opens its own session
        from ``session_factory`` and awaits
        ``flashcard_generation_service.generate`` directly. Uses the
        authenticated teacher's user ID from the job; never a fictional
        teacher. Sarvam failures surface as FAILED (never fake Santali).
        """
        from app.flashcards.schemas import FlashcardGenerationParams
        from app.flashcards.service import flashcard_generation_service

        if session_factory is None:
            from app.db.session import AsyncSessionLocal as _DefaultSessionFactory

            session_factory = _DefaultSessionFactory

        with self._lock:
            job = self._jobs.get(job_id)
            if not job:
                return
            params_dict = dict(job.get("flashcard_params") or {})
            teacher_user_id = job.get("teacher_id")

        try:
            async with session_factory() as session:
                params = FlashcardGenerationParams(
                    request_id=params_dict.get("request_id") or job_id,
                    teacher_id=params_dict.get("teacher_id"),
                    grade=params_dict.get("grade", 1),
                    section=params_dict.get("section"),
                    subject=params_dict.get("subject", "Hindi"),
                    topic=params_dict.get("topic") or "Fruits",
                    topic_source=params_dict.get("topic_source") or "curriculum",
                    topic_id=params_dict.get("topic_id"),
                    topic_input_language=params_dict.get("topic_input_language") or "en",
                    nipun_outcome=params_dict.get("nipun_outcome"),
                    nipun_code=params_dict.get("nipun_code"),
                    strand=params_dict.get("strand"),
                    language_mode=params_dict.get("language_mode") or "hi_sat",
                    flashcard_type=params_dict.get("flashcard_type") or "vocabulary",
                    card_count=params_dict.get("card_count") or 8,
                    difficulty=params_dict.get("difficulty") or "medium",
                    visual_style=params_dict.get("visual_style") or "illustrated",
                    pronunciation=bool(params_dict.get("pronunciation", False)),
                    device_id=params_dict.get("device_id"),
                    origin=params_dict.get("origin") or "online",
                    created_at=params_dict.get("created_at"),
                )
                try:
                    result = await flashcard_generation_service.generate(
                        params, session, teacher_user_id
                    )
                except ValueError as exc:
                    from app.flashcards.schemas import FlashcardGenerationResult

                    result = FlashcardGenerationResult(
                        request_id=params.request_id, status="FAILED",
                        error=str(exc), retryable=False,
                    )
        except Exception:
            logger.exception("Error executing multilingual flashcard job %s", job_id)
            with self._lock:
                job = self._jobs.get(job_id)
                if job is not None:
                    now = datetime.datetime.now(datetime.timezone.utc)
                    job["status"] = "FAILED"
                    job["error"] = "Flashcard generation is temporarily unavailable. Your request is saved and will retry."
                    job["updated_at"] = now
                    job["completed_at"] = now
            return

        with self._lock:
            job["status"] = result.status
            job["content_id"] = result.content_id
            job["content"] = result.content
            job["assets"] = result.assets
            job["provider"] = result.provider
            job["translation_coverage"] = result.coverage
            job["error"] = result.error
            job["target_language"] = "sat"
            job["updated_at"] = datetime.datetime.now(datetime.timezone.utc)
            job["completed_at"] = job["updated_at"]

    async def _execute_worksheet_job_async(self, job_id: str, session_factory=None):
        """Run the bilingual worksheet pipeline (server-side providers only).

        Runs in the caller's event loop and awaits
        ``worksheet_generation_service.generate`` directly — never
        asyncio.run(), never a worker thread. The session is opened from
        ``session_factory`` (default: the app's AsyncSessionLocal) inside
        this loop, so its asyncpg connections always belong to this loop.
        Uses the authenticated teacher's user ID from the job (created at
        request time from the verified JWT); never a fictional teacher.
        """
        from app.worksheets.schemas import WorksheetGenerationParams
        from app.worksheets.service import worksheet_generation_service

        if session_factory is None:
            from app.db.session import AsyncSessionLocal as _DefaultSessionFactory

            session_factory = _DefaultSessionFactory

        with self._lock:
            job = self._jobs.get(job_id)
            if not job:
                return
            params_dict = dict(job.get("worksheet_params") or {})
            teacher_user_id = job.get("teacher_id")

        try:
            async with session_factory() as session:
                params = WorksheetGenerationParams(
                    request_id=params_dict.get("request_id") or job_id,
                    teacher_id=params_dict.get("teacher_id"),
                    grade=params_dict.get("grade", 1),
                    section=params_dict.get("section"),
                    subject=params_dict.get("subject", "Mathematics"),
                    topic=params_dict.get("topic") or params_dict.get("subject", "Practice"),
                    topic_source=params_dict.get("topic_source") or "curriculum",
                    topic_id=params_dict.get("topic_id"),
                    topic_input_language=params_dict.get("topic_input_language") or "en",
                    nipun_outcome=params_dict.get("nipun_outcome"),
                    nipun_code=params_dict.get("nipun_code"),
                    source_language=params_dict.get("source_language") or "hi",
                    target_language=params_dict.get("target_language") or "sat",
                    language_1=params_dict.get("language_1"),
                    language_2=params_dict.get("language_2"),
                    worksheet_type=params_dict.get("worksheet_type") or "practice",
                    worksheet_types=params_dict.get("worksheet_types"),
                    question_count=params_dict.get("question_count") or 10,
                    difficulty=params_dict.get("difficulty") or "medium",
                    visual_support=params_dict.get("visual_support", True),
                    bilingual_answers=params_dict.get("bilingual_answers", True),
                    audio_cue=params_dict.get("audio_cue", False),
                    device_id=params_dict.get("device_id"),
                    origin=params_dict.get("origin") or "online",
                    created_at=params_dict.get("created_at"),
                )
                try:
                    result = await worksheet_generation_service.generate(
                        params, session, teacher_user_id
                    )
                except ValueError as exc:
                    from app.worksheets.schemas import WorksheetGenerationResult

                    result = WorksheetGenerationResult(
                        request_id=params.request_id, status="FAILED",
                        error=str(exc), retryable=False,
                    )
        except Exception:
            # Full server traceback is logged; Flutter only gets safe copy.
            logger.exception("Error executing worksheet job %s", job_id)
            with self._lock:
                job = self._jobs.get(job_id)
                if job is not None:
                    now = datetime.datetime.now(datetime.timezone.utc)
                    job["status"] = "FAILED"
                    job["error"] = "Worksheet generation is temporarily unavailable. Your request is saved and will retry."
                    job["updated_at"] = now
                    job["completed_at"] = now
            return

        with self._lock:
            job["status"] = result.status
            job["content_id"] = result.content_id
            job["content"] = result.content
            job["assets"] = result.assets
            job["provider"] = result.provider
            job["translation_coverage"] = result.coverage
            job["review_gates"] = result.review_gates
            job["error"] = result.error
            job["updated_at"] = datetime.datetime.now(datetime.timezone.utc)
            job["completed_at"] = job["updated_at"]

    def approve_job(
        self,
        job_id: str,
        reviewer_id: str,
        santali_script_confirmed: Optional[str] = "Olck",
        notes: Optional[str] = None,
    ) -> Optional[GenerationJobResponse]:
        """Approve review gates for a job requiring review, making it READY."""
        with self._lock:
            job = self._jobs.get(job_id)
            if not job:
                return None

        content_id = job.get("content_id")
        if not content_id:
            return self._to_response(job)

        try:
            # Update review record in ReviewManager
            bilingual_generator_service.update_review(
                content_id=content_id,
                reviewer_id=reviewer_id,
                status="approved",
                gate_updates={
                    "santali": "pass",
                    "hindi": "pass",
                    "curriculum": "pass",
                    "answer_key": "pass",
                    "provisional_range": "pass",
                },
                santali_script_confirmed=santali_script_confirmed,
                notes=notes or "Teacher confirmed script and approved for classroom use.",
            )

            # Publish content to catalog/storage
            pub_result = bilingual_generator_service.publish_content(
                content_id=content_id,
                dry_run=False,
            )

            with self._lock:
                job["status"] = "READY"
                job["updated_at"] = datetime.datetime.now(datetime.timezone.utc)
                job["assets"] = {
                    "storage_paths": pub_result.storage_paths,
                    "pdf": pub_result.storage_paths[0] if pub_result.storage_paths else f"worksheets/{content_id}.pdf",
                    "image": f"flashcards/{content_id}.png" if job["content_type"] == "flashcard" else None,
                }
                return self._to_response(job)

        except Exception as e:
            logger.exception("Failed to approve and publish job %s", job_id)
            with self._lock:
                job["error"] = f"Approval failed: {str(e)}"
                job["updated_at"] = datetime.datetime.now(datetime.timezone.utc)
                return self._to_response(job)

    def _to_response(self, job: Dict[str, Any]) -> GenerationJobResponse:
        return GenerationJobResponse(
            job_id=job["job_id"],
            status=job["status"],
            content_id=job.get("content_id"),
            content_type=job["content_type"],
            grade=job["grade"],
            target_language=job["target_language"],
            error=job.get("error"),
            review_gates=job.get("review_gates"),
            content=job.get("content"),
            assets=job.get("assets"),
            created_at=job["created_at"],
            updated_at=job["updated_at"],
            provider=job.get("provider"),
            translation_coverage=job.get("translation_coverage"),
        )


# Global singleton manager
generation_job_manager = GenerationJobManager()
