"""Worksheet generation orchestration: build -> translate -> validate -> persist."""
from __future__ import annotations

import json
import logging
from typing import Any, Dict, List, Optional

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.translation.providers import (
    CorpusNmtProvider,
    TranslationNotConfiguredError,
    TranslationProviderError,
    TranslationRateLimitedError,
    TranslationUnsupportedError,
)
from app.translation.registry import (
    LanguageCapabilityRegistry,
    normalize_language_code,
)
from app.worksheets.builder import ScaffoldBuilder
from app.worksheets.schemas import WorksheetDocument, WorksheetGenerationParams, WorksheetGenerationResult
from app.worksheets.translator import (
    extract_translatable_fields,
    provider_api_languages,
    rebase_source,
    recombine,
)
from app.worksheets.validator import check_numeric_preserved, validate_worksheet

logger = logging.getLogger(__name__)

_LANGUAGE_NAMES = {
    "hi": "Hindi", "en": "English", "sat": "Santali", "ho": "Ho", "unr": "Mundari",
    "bn": "Bengali", "gu": "Gujarati", "kn": "Kannada", "ml": "Malayalam",
    "mr": "Marathi", "od": "Odia", "pa": "Punjabi", "ta": "Tamil", "te": "Telugu",
}


def _content_id_for(params: WorksheetGenerationParams) -> str:
    nipun = (params.nipun_code or params.nipun_outcome or "GEN").upper()
    nipun = "".join(ch for ch in nipun if ch.isalnum())[:12] or "GEN"
    subj = "".join(ch for ch in params.subject.upper() if ch.isalnum())[:6] or "SUBJ"
    _, resolved_target = params.resolved_languages()
    tgt = normalize_language_code(resolved_target or params.target_language)
    return f"WS-G{params.grade}-{subj}-{nipun}-{tgt}-{params.request_id[:8]}"


async def _load_verified_map(db: AsyncSession, target_code: str) -> Dict[str, str]:
    """Preload VERIFIED community-corpus translations for a target language."""
    from app.db.models.language_pack import VerifiedPhrase
    from app.db.models.school import Language

    try:
        q = (
            select(VerifiedPhrase.source_text, VerifiedPhrase.translated_text)
            .join(Language, VerifiedPhrase.target_language_id == Language.id)
            .where(
                Language.code == target_code,
                VerifiedPhrase.verification_status == "VERIFIED",
            )
            .limit(5000)
        )
        rows = (await db.execute(q)).all()
        return {str(src).strip().lower(): str(tgt) for src, tgt in rows if src and tgt}
    except Exception as exc:
        logger.warning("Verified-phrase preload failed: %s", exc)
        return {}


async def _nmt_model_registered(db: AsyncSession, target_code: str) -> Optional[str]:
    """Return the registered NMT model name for a language, if any."""
    from app.db.models.language_pack import ModelVersion

    try:
        q = (
            select(ModelVersion.model_name)
            .where(
                ModelVersion.model_type == "nmt",
                ModelVersion.language_code == target_code,
                ModelVersion.release_status == "RELEASED",
            )
            .limit(1)
        )
        row = (await db.execute(q)).scalar_one_or_none()
        return str(row) if row else None
    except Exception as exc:
        logger.warning("ModelVersion lookup failed: %s", exc)
        return None


async def _ensure_teacher(db: AsyncSession, teacher_user_id: Optional[str]) -> str:
    """Resolve the Teacher row id owned by the authenticated JWT subject.

    The caller MUST pass the verified JWT ``sub``. Client-supplied teacher
    ids are never trusted, and we never attribute content to an arbitrary
    first teacher row: unknown users get their own minimal row.
    """
    from app.db.models.school import Teacher

    if not teacher_user_id or not teacher_user_id.strip():
        raise ValueError("teacher_user_id (JWT sub) is required")
    clean_id = teacher_user_id.strip()
    res = await db.execute(select(Teacher).where(Teacher.user_id == clean_id))
    teacher = res.scalar_one_or_none()
    if teacher:
        return teacher.id
    fallback = Teacher(
        user_id=clean_id,
        name="Primary School Teacher",
        email=f"worksheet-{clean_id[:24]}@provisioned.local",
    )
    db.add(fallback)
    await db.flush()
    return fallback.id


def to_flutter_payload(doc: WorksheetDocument, coverage: Dict[str, Any], provider: str) -> Dict[str, Any]:
    """Flutter-compatible worksheet payload (preview + SavedMaterials mapping)."""
    meta = doc.metadata
    src = meta.get("source_language", "hi")
    questions = []
    for q in doc.questions:
        opts = []
        for opt in q.options:
            text = opt.get("text", {})
            if isinstance(text, dict):
                opts.append(str(text.get("target") or text.get("source") or opt.get("value")))
            else:
                opts.append(str(opt.get("value")))
        questions.append(
            {
                "questionNumber": q.number,
                # Legacy preview slots: primary = requested source side,
                # secondary = requested target side (languages in metadata).
                "promptHindi": q.prompt.source,
                "promptTribal": q.prompt.target,
                "prompt_source": q.prompt.source,
                "prompt_target": q.prompt.target,
                "prompt_source_lang": meta.get("source_language"),
                "prompt_target_lang": meta.get("target_language"),
                "promptTranslated": q.prompt.translated,
                "visualIllustration": q.visual or "",
                "options": opts,
                "answer": str(q.answer.get("value", "")),
                "hint": q.hint.target if q.hint else None,
                "type": q.type,
                "id": q.id,
            }
        )
    return {
        "content_id": doc.content_id,
        "request_id": doc.request_id,
        "title": doc.title.target or doc.title.source,
        "title_hi": doc.title.source,
        "title_source": doc.title.source,
        "title_target": doc.title.target,
        "grade": meta.get("grade"),
        "section": meta.get("section"),
        "subject": meta.get("subject"),
        "topic": meta.get("topic"),
        "topic_source": meta.get("topic_source"),
        "topic_id": meta.get("topic_id"),
        "topic_input_language": meta.get("topic_input_language"),
        "curriculum_id": meta.get("nipun_code") or meta.get("nipun_outcome"),
        "nipun_outcome": meta.get("nipun_outcome"),
        "nipun_statement": meta.get("nipun_statement"),
        "source_language": src,
        "target_language": meta.get("target_language"),
        "language_1": meta.get("source_language"),
        "language_2": meta.get("target_language"),
        "difficulty": meta.get("difficulty"),
        "content_type": "worksheet",
        "worksheet_type": meta.get("worksheet_type"),
        "worksheet_types": meta.get("worksheet_types") or [meta.get("worksheet_type")],
        "question_count": len(doc.questions),
        "visual_support": meta.get("visual_support"),
        "visual_illustrations": meta.get("visual_support"),
        "bilingual_answers": meta.get("bilingual_answers"),
        "bilingual_answer_spaces": meta.get("bilingual_answers"),
        "audio_cue": meta.get("audio_cue"),
        "audio_pronunciation": meta.get("audio_cue"),
        "generated_at": meta.get("generated_at"),
        "instructions": {"source": doc.instructions.source, "target": doc.instructions.target},
        "teacher_notes": (
            {"source": doc.teacher_notes.source, "target": doc.teacher_notes.target}
            if doc.teacher_notes else None
        ),
        "questions": questions,
        "translation": {
            "provider": provider,
            "coverage": coverage,
            "complete": not coverage.get("untranslated_fields"),
        },
        "metadata": meta,
    }


class WorksheetGenerationService:
    def __init__(self, registry: Optional[LanguageCapabilityRegistry] = None):
        self.registry = registry or LanguageCapabilityRegistry()
        self.builder = ScaffoldBuilder()

    async def generate(
        self,
        params: WorksheetGenerationParams,
        db: AsyncSession,
        teacher_user_id: Optional[str] = None,
    ) -> WorksheetGenerationResult:
        l1, l2 = params.resolved_languages()
        source = normalize_language_code(l1 or params.source_language)
        target = normalize_language_code(l2 or params.target_language)

        # Bilingual pair rule: the two sides must differ.
        if source == target:
            return WorksheetGenerationResult(
                request_id=params.request_id, status="FAILED",
                error="Worksheet Language 1 and Language 2 must be different.",
                retryable=False,
            )

        # Custom-topic guard: non-empty text preserved as entered; never
        # invent a NIPUN code for custom topics.
        if (params.topic_source or "curriculum") == "custom":
            if not (params.topic or "").strip():
                return WorksheetGenerationResult(
                    request_id=params.request_id, status="FAILED",
                    error="Custom topic must not be empty.",
                    retryable=False,
                )
        requested_types = params.resolved_types()

        # Unknown codes fail clearly through the result (never an exception,
        # never silent fallback to another language). Support is derived from
        # the registry configuration, not a hardcoded list.
        if not self.registry.is_supported_language(source):
            return WorksheetGenerationResult(
                request_id=params.request_id, status="FAILED",
                error=(
                    f"Source language '{params.source_language}' is not currently configured."
                ),
                retryable=False,
            )
        if not self.registry.is_supported_language(target):
            return WorksheetGenerationResult(
                request_id=params.request_id, status="FAILED",
                error="Translation for this language is not currently configured.",
                retryable=False,
            )

        # The registry is the single authority for provider routing.
        # Ho/Mundari can only ever resolve to custom pipelines (never Sarvam).
        target_provider = None
        if target != source:
            try:
                target_provider = self.registry.provider_for(source, target)
            except TranslationNotConfiguredError as exc:
                return WorksheetGenerationResult(
                    request_id=params.request_id, status="FAILED",
                    error=str(exc), retryable=False,
                )
        source_provider = None
        if source != "hi":
            try:
                source_provider = self.registry.provider_for("hi", source)
            except TranslationNotConfiguredError as exc:
                lang_name = _LANGUAGE_NAMES.get(source, source)
                return WorksheetGenerationResult(
                    request_id=params.request_id, status="FAILED",
                    error=(
                        f"Source language {lang_name} is not currently configured. {exc}"
                    ),
                    retryable=False,
                )

        await self._wire_corpus(db, target_provider, target)
        await self._wire_corpus(db, source_provider, source)

        # Canonical curriculum-safe Hindi scaffold (the only authored source).
        # Requested language_1 is served by the source translation leg below.
        doc = self.builder.build(
            request_id=params.request_id, grade=params.grade, subject=params.subject,
            topic=params.topic, nipun_outcome=params.nipun_outcome, nipun_code=params.nipun_code,
            source_language="hi",
            target_language=target,
            worksheet_type=requested_types[0], question_count=params.question_count,
            difficulty=params.difficulty, visual_support=params.resolved_visual(),
            bilingual_answers=params.resolved_bilingual_answers(), audio_cue=params.resolved_audio(),
            worksheet_types=requested_types,
            section=params.section,
            topic_source=params.topic_source or "curriculum",
            topic_id=params.topic_id,
            topic_input_language=params.topic_input_language or "en",
        )
        doc.content_id = _content_id_for(params)
        expected_ids = [q.id for q in doc.questions]

        coverage_source: Dict[str, Any] = {
            "provider": "none", "total_fields": 0, "translated_fields": 0,
            "untranslated_fields": [],
        }

        # ---- Source leg: Hindi anchor -> requested source language. ----
        # The anchor must be COMPLETE: a partially served source language
        # would mislead the teacher, so anything short of full coverage fails.
        if source_provider is not None:
            items = extract_translatable_fields(doc)
            api0, api1 = provider_api_languages(source_provider, "hi", source)
            try:
                import asyncio

                batch = await asyncio.to_thread(
                    source_provider.translate_batch, items, api0, api1
                )
            except TranslationRateLimitedError as exc:
                return self._failed(params, source_provider, f"{exc} Your request is saved and will retry.", True)
            except TranslationUnsupportedError as exc:
                return self._failed(params, source_provider, str(exc), False)
            except TranslationProviderError:
                return self._failed(
                    params, source_provider,
                    "Worksheet generation is temporarily unavailable. Your request is saved and will retry.",
                    True,
                )
            except TranslationNotConfiguredError as exc:
                lang_name = _LANGUAGE_NAMES.get(source, source)
                return self._failed(
                    params, source_provider,
                    f"{exc} ({lang_name} cannot currently serve as a source language.)",
                    False,
                )
            num_errors = check_numeric_preserved([
                (it.field_id, it.text, self._batch_text(batch, it.field_id)) for it in items
            ])
            if num_errors:
                return self._failed(
                    params, source_provider,
                    "Generated worksheet failed validation: " + "; ".join(num_errors[:3]), False,
                )
            doc, src_coverage = recombine(doc, batch, source_provider.name)
            try:
                doc = rebase_source(doc, source_provider.name)
            except ValueError:
                lang_name = _LANGUAGE_NAMES.get(source, source)
                return WorksheetGenerationResult(
                    request_id=params.request_id, status="FAILED",
                    provider=source_provider.name,
                    error=(
                        f"Insufficient translation coverage to serve {lang_name} as a "
                        f"source language ({src_coverage.get('translated_fields', 0)}/"
                        f"{src_coverage.get('total_fields', 0)} fields). "
                        "Configure a verified corpus, glossary, or NMT endpoint on the server."
                    ),
                    retryable=False,
                )
            doc.metadata["source_language"] = source
            coverage_source = dict(src_coverage)
            coverage_source["provider"] = source_provider.name
            coverage_source["api_source"] = api0
            coverage_source["api_target"] = api1

        # ---- Same-language shortcut: anchor already serves both sides. ----
        if target_provider is None:
            anchor_name = source_provider.name if source_provider else "none"
            self._copy_source_to_target(doc, anchor_name)
            coverage = {
                "total_fields": 0, "translated_fields": 0, "untranslated_fields": [],
                "provider": anchor_name, "source_provider": anchor_name,
                "target_provider": anchor_name, "copied_from_source": True,
            }
            copy_errors = validate_worksheet(
                doc, expected_count=params.question_count, expected_ids=expected_ids,
                nipun_code=params.nipun_code, nipun_outcome=params.nipun_outcome,
                target_language=target, provider_name=anchor_name,
                source_language=source,
                expected_source_provider=anchor_name,
                expected_target_provider=anchor_name,
                coverage=coverage,
                expected_types=requested_types,
                grade=params.grade, subject=params.subject,
                section=params.section, topic=params.topic,
            )
            if copy_errors:
                return WorksheetGenerationResult(
                    request_id=params.request_id, status="FAILED", provider=anchor_name,
                    error="Generated worksheet failed validation: " + "; ".join(copy_errors[:3]),
                    retryable=False,
                )
            return await self._persist(params, db, teacher_user_id, doc, anchor_name, coverage)

        # ---- Target leg: requested source -> requested target. ----
        items = extract_translatable_fields(doc)
        api_src, api_tgt = provider_api_languages(target_provider, source, target)
        try:
            import asyncio

            batch = await asyncio.to_thread(
                target_provider.translate_batch, items, api_src, api_tgt
            )
        except TranslationRateLimitedError as exc:
            return self._failed(params, target_provider, f"{exc} Your request is saved and will retry.", True)
        except TranslationUnsupportedError as exc:
            return self._failed(params, target_provider, str(exc), False)
        except TranslationProviderError:
            return self._failed(
                params, target_provider,
                "Worksheet generation is temporarily unavailable. Your request is saved and will retry.",
                True,
            )
        except TranslationNotConfiguredError as exc:
            return self._failed(params, target_provider, str(exc), False)

        doc, coverage = recombine(doc, batch, target_provider.name)
        coverage["source_provider"] = coverage_source.get("provider", "none")
        coverage["target_provider"] = target_provider.name
        coverage["api_source"] = api_src
        coverage["api_target"] = api_tgt
        errors = validate_worksheet(
            doc, expected_count=params.question_count, expected_ids=expected_ids,
            nipun_code=params.nipun_code, nipun_outcome=params.nipun_outcome,
            target_language=target, provider_name=target_provider.name,
            source_language=source,
            expected_source_provider=coverage_source.get("provider", "none"),
            expected_target_provider=target_provider.name,
            coverage=coverage,
            expected_types=requested_types,
            grade=params.grade, subject=params.subject,
            section=params.section, topic=params.topic,
        )
        if errors:
            return WorksheetGenerationResult(
                request_id=params.request_id, status="FAILED", provider=target_provider.name,
                error="Generated worksheet failed validation: " + "; ".join(errors[:3]),
                retryable=False,
            )

        untranslated = coverage.get("untranslated_fields") or []
        if untranslated:
            if coverage.get("translated_fields", 0) == 0:
                # Provider exists but has no usable coverage: clear error,
                # not a silently untranslated worksheet.
                lang_name = _LANGUAGE_NAMES.get(target, target)
                return WorksheetGenerationResult(
                    request_id=params.request_id, status="FAILED",
                    provider=target_provider.name,
                    error=(
                        f"Translation for {lang_name} is not currently configured. "
                        "Configure a verified corpus, glossary, or NMT endpoint on the server."
                    ),
                    retryable=False,
                )
            # Partial custom-pipeline coverage -> teacher review via existing gates.
            result = await self._persist(params, db, teacher_user_id, doc, target_provider.name, coverage)
            result.status = "REVIEW_REQUIRED"
            result.review_gates = {
                "translation_coverage": (
                    f"partial: {coverage['translated_fields']}/{coverage['total_fields']} fields"
                )
            }
            return result
        return await self._persist(params, db, teacher_user_id, doc, target_provider.name, coverage)

    @staticmethod
    def _batch_text(batch, field_id: str) -> str:
        for res in batch.results:
            if res.field_id == field_id:
                return res.text
        return ""

    @staticmethod
    def _failed(params, provider, message: str, retryable: bool) -> WorksheetGenerationResult:
        name = provider.name if provider is not None else "none"
        return WorksheetGenerationResult(
            request_id=params.request_id, status="FAILED", provider=name,
            error=message, retryable=retryable,
        )

    async def _wire_corpus(self, db: AsyncSession, provider, target: Optional[str]) -> None:
        """Attach the verified community-corpus lookup to custom pipelines."""
        if provider is None or not isinstance(provider, CorpusNmtProvider):
            return
        verified_map = await _load_verified_map(db, target or "")
        if not verified_map:
            model = await _nmt_model_registered(db, target or "")
            if model:
                logger.info("NMT model %s registered for %s", model, target)
        provider._verified_lookup = lambda text, src, tgt: verified_map.get(text.strip().lower())

    def _copy_source_to_target(self, doc: WorksheetDocument, provider: str) -> None:
        from app.worksheets.schemas import BilingualField

        def _copy(text: str) -> BilingualField:
            return BilingualField(source=text, target=text, provider=provider, translated=True)

        doc.title = _copy(doc.title.source)
        doc.instructions = _copy(doc.instructions.source)
        for q in doc.questions:
            q.prompt = _copy(q.prompt.source)
            for opt in q.options:
                text = opt.get("text")
                if isinstance(text, dict) and text.get("source"):
                    opt["text"] = _copy(text["source"]).model_dump()
            if q.hint and q.hint.source:
                q.hint = _copy(q.hint.source)
        if doc.teacher_notes and doc.teacher_notes.source:
            doc.teacher_notes = _copy(doc.teacher_notes.source)

    async def _persist(
        self,
        params: WorksheetGenerationParams,
        db: AsyncSession,
        teacher_user_id: Optional[str],
        doc: WorksheetDocument,
        provider_name: str,
        coverage: Dict[str, Any],
    ) -> WorksheetGenerationResult:
        from app.db.models.resource import SavedMaterial
        from app.storage.service import storage_service

        import datetime as _dt
        doc.metadata["generated_at"] = _dt.datetime.now(_dt.timezone.utc).isoformat()
        doc.metadata["version"] = 1
        payload = to_flutter_payload(doc, coverage, provider_name)
        # JWT subject wins: client-supplied params.teacher_id is ignored
        # when a verified teacher_user_id is present.
        teacher_id = await _ensure_teacher(db, teacher_user_id or params.teacher_id)

        # Idempotent upsert on local_id == request_id AND owner: one
        # teacher must never overwrite another teacher's worksheet.
        res = await db.execute(
            select(SavedMaterial).where(SavedMaterial.local_id == params.request_id)
        )
        material = res.scalar_one_or_none()
        if material is not None and getattr(material, "teacher_id", None) != teacher_id:
            raise PermissionError("Worksheet belongs to a different teacher account.")
        if material is None:
            material = SavedMaterial(
                local_id=params.request_id,
                teacher_id=teacher_id,
                title=payload["title"],
                material_type="worksheet",
                payload=payload,
            )
            db.add(material)
            await db.flush()
        else:
            material.title = payload["title"]
            material.payload = payload
            material.teacher_id = teacher_id

        # Generated artifacts to configured storage when live; logical path otherwise.
        # The PDF is rendered from the ACTUAL generated worksheet (never a mock).
        artifact_path = f"worksheets/{doc.content_id}.json"
        pdf_path = f"worksheets/{doc.content_id}.pdf"
        try:
            stored_path = storage_service.upload_text_object(
                storage_service.bucket_worksheets, artifact_path, json.dumps(payload, ensure_ascii=False),
            )
        except Exception as exc:
            logger.warning("Artifact upload failed; keeping logical path: %s", exc)
            stored_path = artifact_path
        try:
            from app.worksheets.pdf import render_worksheet_pdf
            pdf_bytes = render_worksheet_pdf(doc)
            try:
                stored_pdf = storage_service.upload_bytes(
                    storage_service.bucket_worksheets, pdf_path, pdf_bytes,
                    content_type="application/pdf",
                )
            except Exception as exc:
                logger.warning("PDF upload failed; keeping logical path: %s", exc)
                stored_pdf = pdf_path
        except Exception as exc:
            logger.warning("PDF render failed: %s", exc)
            stored_pdf = None
        await db.commit()

        assets: Dict[str, Any] = {"worksheet_json": stored_path, "saved_material_id": material.id}
        if stored_pdf:
            assets["pdf"] = stored_pdf
        assets["version"] = 1
        assets["generated_at"] = doc.metadata.get("generated_at")

        return WorksheetGenerationResult(
            request_id=params.request_id,
            content_id=doc.content_id,
            status="READY",
            provider=provider_name,
            coverage=coverage,
            content=payload,
            assets=assets,
            saved_material_id=material.id,
        )


worksheet_generation_service = WorksheetGenerationService()
