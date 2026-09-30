"""Post-translation structural validation for bilingual worksheets."""
from __future__ import annotations

import unicodedata
from typing import Dict, List, Optional


def _numbers(text: str) -> List[int]:
    """Numeric values as ints, normalizing Unicode decimal digits (e.g. Ol Chiki)."""
    out: List[int] = []
    for ch in text or "":
        if ch.isdigit():
            try:
                out.append(unicodedata.digit(ch))
            except (ValueError, TypeError):
                continue
    return out


def check_numeric_preserved(pairs: List[tuple]) -> List[str]:
    """Check (field_id, source_text, translated_text) pairs keep their numbers."""
    errors: List[str] = []
    for field_id, source_text, translated_text in pairs:
        if sorted(_numbers(source_text)) != sorted(_numbers(translated_text)):
            errors.append(f"Field {field_id} numeric values changed in translation.")
    return errors


def validate_worksheet(
    doc,
    *,
    expected_count: int,
    expected_ids: List[str],
    nipun_code=None,
    nipun_outcome=None,
    target_language: str,
    provider_name: str,
    source_language: Optional[str] = None,
    expected_source_provider: Optional[str] = None,
    expected_target_provider: Optional[str] = None,
    coverage: Optional[Dict] = None,
    expected_types: Optional[List[str]] = None,
    grade: Optional[int] = None,
    subject: Optional[str] = None,
    section: Optional[str] = None,
    topic: Optional[str] = None,
) -> List[str]:
    """Return a list of validation errors (empty = valid)."""
    errors: List[str] = []

    # Question count + IDs unchanged, ordering preserved.
    actual_ids = [q.id for q in doc.questions]
    if len(doc.questions) != expected_count:
        errors.append(
            f"Question count changed: expected {expected_count}, got {len(doc.questions)}."
        )
    if actual_ids != expected_ids:
        errors.append(f"Question IDs/order changed: expected {expected_ids}, got {actual_ids}.")

    # Required fields non-empty in both languages.
    if not doc.title.source.strip() or not doc.title.target.strip():
        errors.append("Worksheet title is empty.")
    if not doc.instructions.source.strip() or not doc.instructions.target.strip():
        errors.append("Worksheet instructions are empty.")
    for q in doc.questions:
        if not q.prompt.source.strip() or not q.prompt.target.strip():
            errors.append(f"Question {q.id} prompt is empty.")
        if not q.options:
            errors.append(f"Question {q.id} has no options.")
        opt_ids = [o.get("option_id") for o in q.options]
        if q.answer.get("option_id") not in opt_ids:
            errors.append(f"Question {q.id} answer does not map to an option.")

    # Numeric values preserved per question (same multiset of numbers,
    # Unicode-digit aware so Indic scripts compare correctly).
    for q in doc.questions:
        if sorted(_numbers(q.prompt.source)) != sorted(_numbers(q.prompt.target)):
            errors.append(f"Question {q.id} numeric values changed in translation.")
        for opt in q.options:
            text = opt.get("text", {})
            if isinstance(text, dict):
                if sorted(_numbers(str(text.get("source", "")))) != sorted(
                    _numbers(str(text.get("target", "")))
                ):
                    errors.append(f"Question {q.id} option numbers changed.")
                    break

    # NIPUN code/outcome preserved in metadata.
    meta = doc.metadata or {}
    if nipun_code and meta.get("nipun_code") != nipun_code:
        errors.append("NIPUN code was not preserved.")
    if nipun_outcome and meta.get("nipun_outcome") != nipun_outcome:
        errors.append("NIPUN outcome was not preserved.")

    # Worksheet types: every selected type must be represented.
    if not meta.get("worksheet_type"):
        errors.append("Worksheet type was not preserved.")
    if expected_types:
        present = {q.type for q in doc.questions}
        for t in expected_types:
            if t not in present:
                errors.append(f"Worksheet type '{t}' has no questions.")
        if len(doc.questions) != expected_count:
            pass  # already reported above; keep single count error.

    # Class / subject / section / topic completeness.
    if grade is not None and meta.get("grade") != grade:
        errors.append("Class/grade does not match the request.")
    if subject is not None and (meta.get("subject") or "").strip() != subject.strip():
        errors.append("Subject does not match the request.")
    if section is not None and section.strip():
        if (meta.get("section") or "").strip() != section.strip():
            errors.append("Section does not match the request.")
    if topic is not None and topic.strip():
        if (meta.get("topic") or "").strip() != topic.strip():
            errors.append("Topic does not match the request.")

    # Bilingual completeness: both sides non-empty for every question.
    for q in doc.questions:
        if not (q.prompt.source or "").strip() or not (q.prompt.target or "").strip():
            if f"Question {q.id} prompt is empty." not in errors:
                errors.append(f"Question {q.id} prompt is empty.")

    # Target language + provider match the request.
    if (meta.get("target_language") or "").strip().lower() != target_language.strip().lower():
        errors.append("Target language does not match the requested language.")
    if source_language is not None and (
        meta.get("source_language") or ""
    ).strip().lower() != source_language.strip().lower():
        errors.append("Source language does not match the requested language.")
    for q in doc.questions:
        for field in (q.prompt, q.hint):
            if field is not None and field.translated and field.provider not in (
                provider_name, "passthrough",
            ):
                errors.append(f"Question {q.id} provider mismatch.")
                break

    # Source/target legs must have run through the selected providers.
    if coverage is not None:
        if expected_target_provider and coverage.get("target_provider") not in (
            expected_target_provider, "none",
        ):
            errors.append("Target translation did not use the selected provider.")
        if expected_source_provider and coverage.get("source_provider") not in (
            expected_source_provider, "none",
        ):
            errors.append("Source translation did not use the selected provider.")

    return errors
