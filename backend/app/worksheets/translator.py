"""Translatable-field extraction and bilingual recombination.

Only human-readable text fields are translated. IDs, numbers, answer
metadata, asset references, NIPUN codes, and internal fields are never
sent to a provider.
"""
from __future__ import annotations

from typing import Dict, List, Tuple

from app.translation.providers import (
    BatchTranslation,
    TranslationItem,
    TranslationProvider,
    TranslationResult,
)
from app.translation.registry import normalize_language_code
from app.worksheets.schemas import (
    BilingualField,
    WorksheetDocument,
    WorksheetQuestionDoc,
)


def extract_translatable_fields(doc: WorksheetDocument) -> List[TranslationItem]:
    """Collect every translatable leaf with a stable field id."""
    items = [
        TranslationItem("title", doc.title.source),
        TranslationItem("instructions", doc.instructions.source),
    ]
    for q in doc.questions:
        items.append(TranslationItem(f"{q.id}.prompt", q.prompt.source))
        for opt in q.options:
            text = opt.get("text")
            if isinstance(text, dict) and text.get("source"):
                items.append(TranslationItem(f"{q.id}.opt.{opt.get('option_id')}", text["source"]))
        if q.hint and q.hint.source:
            items.append(TranslationItem(f"{q.id}.hint", q.hint.source))
    if doc.teacher_notes and doc.teacher_notes.source:
        items.append(TranslationItem("teacher_notes", doc.teacher_notes.source))
    return [it for it in items if it.text and it.text.strip()]


def _field_from_result(source: str, result: TranslationResult) -> BilingualField:
    return BilingualField(
        source=source,
        target=result.text if result.translated else source,
        provider=result.provider,
        translated=result.translated,
    )


def recombine(
    doc: WorksheetDocument,
    results: BatchTranslation,
    provider_name: str,
) -> Tuple[WorksheetDocument, Dict[str, int]]:
    """Fill target fields from translation results. Returns (doc, coverage)."""
    by_id = {r.field_id: r for r in results.results}
    translated = 0
    untranslated_fields: List[str] = []

    def _fill(field_id: str, source: str) -> BilingualField:
        nonlocal translated
        res = by_id.get(field_id)
        if res is None or not res.translated:
            if res is not None:
                untranslated_fields.append(field_id)
            return BilingualField(source=source, target=source, provider=provider_name, translated=False)
        translated += 1
        return _field_from_result(source, res)

    doc.title = _fill("title", doc.title.source)
    doc.instructions = _fill("instructions", doc.instructions.source)
    for q in doc.questions:
        q.prompt = _fill(f"{q.id}.prompt", q.prompt.source)
        for opt in q.options:
            text = opt.get("text")
            if isinstance(text, dict) and text.get("source"):
                filled = _fill(f"{q.id}.opt.{opt.get('option_id')}", text["source"])
                opt["text"] = filled.model_dump()
        if q.hint and q.hint.source:
            q.hint = _fill(f"{q.id}.hint", q.hint.source)
    if doc.teacher_notes and doc.teacher_notes.source:
        doc.teacher_notes = _fill("teacher_notes", doc.teacher_notes.source)

    total = len(by_id)
    coverage = {
        "total_fields": total,
        "translated_fields": translated,
        "untranslated_fields": untranslated_fields,
        "provider": provider_name,
    }
    return doc, coverage


def provider_api_languages(provider: TranslationProvider, source: str, target: str) -> Tuple[str, str]:
    """Resolve the language codes to send to the provider."""
    src = normalize_language_code(source)
    tgt = normalize_language_code(target)
    # Every remaining provider speaks internal codes; the local service maps them
    # to FLORES/BCP-47 tags itself.
    return src, tgt


def rebase_source(doc: WorksheetDocument, provider_name: str) -> WorksheetDocument:
    """Promote a completed source-leg translation into the source side.

    Every field must have been translated; the caller fails the request
    otherwise, so the anchor language is never partially served. Returns a
    new document whose ``source`` texts are the translated anchor texts and
    whose ``target`` texts are empty, ready for the target leg. IDs, order,
    options, answers, visuals, and metadata are preserved untouched.
    """
    untranslated = []

    def _promote(field_id: str, field: BilingualField) -> BilingualField:
        if not field.translated or not field.target.strip():
            untranslated.append(field_id)
        return BilingualField(
            source=field.target if field.translated else field.source,
            target="",
            provider="pending",
            translated=False,
        )

    questions = []
    for q in doc.questions:
        options = []
        for opt in q.options:
            text = opt.get("text")
            if isinstance(text, dict) and text.get("source") is not None:
                filled = _promote(
                    f"{q.id}.opt.{opt.get('option_id')}",
                    BilingualField(
                        source=text.get("source", ""),
                        target=text.get("target", ""),
                        provider=text.get("provider", provider_name),
                        translated=bool(text.get("translated", False)),
                    ),
                )
                new_opt = dict(opt)
                new_opt["text"] = filled.model_dump()
                options.append(new_opt)
            else:
                options.append(opt)
        questions.append(
            WorksheetQuestionDoc(
                id=q.id,
                number=q.number,
                type=q.type,
                prompt=_promote(f"{q.id}.prompt", q.prompt),
                options=options,
                answer=dict(q.answer),
                hint=_promote(f"{q.id}.hint", q.hint) if q.hint else None,
                visual=q.visual,
            )
        )

    if untranslated:
        raise ValueError(
            "Source anchor incomplete for fields: " + ", ".join(untranslated[:5])
        )
    return WorksheetDocument(
        content_id=doc.content_id,
        request_id=doc.request_id,
        title=_promote("title", doc.title),
        instructions=_promote("instructions", doc.instructions),
        questions=questions,
        teacher_notes=(
            _promote("teacher_notes", doc.teacher_notes) if doc.teacher_notes else None
        ),
        metadata=dict(doc.metadata),
    )
