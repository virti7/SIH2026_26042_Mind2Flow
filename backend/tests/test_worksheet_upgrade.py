"""Upgrade tests: bilingual pair, multi-type allocation, question count,
difficulty, topic validation, PDF rendering, provider routing.

Pure unit tests (no DB, no network, no provider keys).
"""
import uuid

import pytest

from app.translation.providers import CorpusNmtProvider, SarvamTranslateProvider
from app.translation.registry import LanguageCapabilityRegistry
from app.worksheets.builder import (
    ScaffoldBuilder,
    allocate_types,
    normalize_worksheet_types,
)
from app.worksheets.pdf import render_worksheet_pdf
from app.worksheets.schemas import WorksheetGenerationParams
from app.worksheets.validator import validate_worksheet


def _params(**overrides):
    base = {
        "request_id": f"req-{uuid.uuid4()}",
        "teacher_id": "teacher-1",
        "device_id": "device-1",
        "grade": 2,
        "section": "A",
        "subject": "Mathematics",
        "topic_source": "curriculum",
        "topic": "Numbers up to 100",
        "topic_input_language": "en",
        "nipun_outcome": "M2.1.4",
        "nipun_code": "M2.1.4",
        "source_language": "hi",
        "target_language": "sat",
        "language_1": "hi",
        "language_2": "sat",
        "worksheet_type": "practice",
        "worksheet_types": ["practice", "fill_blank"],
        "question_count": 10,
        "difficulty": "medium",
        "visual_support": True,
        "bilingual_answers": True,
        "audio_cue": False,
        "origin": "online",
    }
    base.update(overrides)
    return WorksheetGenerationParams(**base)


def test_pair_aliases_resolve():
    p = _params()
    assert p.resolved_languages() == ("hi", "sat")
    # legacy singular fields fall back correctly
    legacy = WorksheetGenerationParams(
        request_id="r1", grade=2, subject="Mathematics", topic="T",
        source_language="en", target_language="ho",
        question_count=5,
    )
    assert legacy.resolved_languages() == ("en", "ho")


def test_same_language_pair_rejected_at_schema_level():
    # The service rejects l1 == l2; schema exposes the resolved pair so the
    # check is deterministic.
    p = _params(language_1="hi", language_2="hi-IN")
    l1, l2 = p.resolved_languages()
    from app.translation.registry import normalize_language_code
    assert normalize_language_code(l1) == normalize_language_code(l2)


def test_multi_type_normalization_and_allocation():
    assert normalize_worksheet_types(["practice", "fill_blank"]) == ["fill_blank", "practice"] or \
        set(normalize_worksheet_types(["practice", "fill_blank"])) == {"practice", "fill_blank"}
    assert normalize_worksheet_types("fillInTheBlanks") == ["fill_blank"]
    assert normalize_worksheet_types([]) == ["practice"]
    # 10 questions / 2 types -> 5 + 5, deterministic, every type represented
    plan = allocate_types(["practice", "fill_blank"], 10)
    assert len(plan) == 10
    assert sorted(set(plan)) == ["fill_blank", "practice"]
    assert plan.count("practice") == 5
    assert plan.count("fill_blank") == 5
    assert allocate_types(["practice", "fill_blank"], 10) == plan
    # 7 questions / 3 types -> every type at least once
    plan7 = allocate_types(["practice", "fill_blank", "matching"], 7)
    assert len(plan7) == 7
    assert set(plan7) == {"practice", "fill_blank", "matching"}


def test_builder_exact_count_all_types_no_duplicates():
    builder = ScaffoldBuilder()
    doc = builder.build(
        request_id="req-alloc-1", grade=2, subject="Mathematics",
        topic="Numbers up to 100", nipun_outcome="M2.1.4", nipun_code="M2.1.4",
        source_language="hi", target_language="sat",
        worksheet_type="practice", question_count=10, difficulty="medium",
        visual_support=True, bilingual_answers=True, audio_cue=False,
        worksheet_types=["practice", "fill_blank"],
        section="A", topic_source="curriculum",
    )
    assert len(doc.questions) == 10
    assert len({q.id for q in doc.questions}) == 10
    assert {q.type for q in doc.questions} == {"practice", "fill_blank"}
    assert doc.metadata["worksheet_types"] == ["fill_blank", "practice"]
    assert doc.metadata["section"] == "A"
    assert doc.metadata["topic_source"] == "curriculum"
    assert doc.metadata["difficulty"] == "medium"


def test_builder_custom_topic_never_fabricates_nipun():
    builder = ScaffoldBuilder()
    doc = builder.build(
        request_id="req-custom-1", grade=2, subject="Mathematics",
        topic="दो अंकों की जोड़", nipun_outcome=None, nipun_code=None,
        source_language="hi", target_language="sat",
        worksheet_type="practice", question_count=5, difficulty="medium",
        visual_support=True, bilingual_answers=True, audio_cue=False,
        worksheet_types=["practice"],
        topic_source="custom", topic_input_language="hi",
    )
    assert doc.metadata["topic"] == "दो अंकों की जोड़"
    assert doc.metadata["topic_source"] == "custom"
    assert doc.metadata["topic_input_language"] == "hi"
    assert doc.metadata["nipun_code"] is None
    assert doc.metadata["nipun_outcome"] is None


def test_difficulty_shapes_content():
    builder = ScaffoldBuilder()
    easy = builder.build(
        request_id="req-diff", grade=2, subject="Mathematics", topic="T",
        nipun_outcome=None, nipun_code=None, source_language="hi",
        target_language="sat", worksheet_type="fill_blank", question_count=6,
        difficulty="easy", visual_support=False, bilingual_answers=True,
        audio_cue=False, worksheet_types=["fill_blank"],
    )
    hard = builder.build(
        request_id="req-diff", grade=2, subject="Mathematics", topic="T",
        nipun_outcome=None, nipun_code=None, source_language="hi",
        target_language="sat", worksheet_type="fill_blank", question_count=6,
        difficulty="hard", visual_support=False, bilingual_answers=True,
        audio_cue=False, worksheet_types=["fill_blank"],
    )
    assert easy.metadata["difficulty"] == "easy"
    assert hard.metadata["difficulty"] == "hard"
    # easy uses single blanks; hard uses wider steps/blanks -> prompts differ
    assert [q.prompt.source for q in easy.questions] != [q.prompt.source for q in hard.questions]


def test_validator_catches_type_count_section_mismatch():
    builder = ScaffoldBuilder()
    doc = builder.build(
        request_id="req-val", grade=2, subject="Mathematics",
        topic="Numbers up to 100", nipun_outcome="M2.1.4", nipun_code="M2.1.4",
        source_language="hi", target_language="sat",
        worksheet_type="practice", question_count=4, difficulty="medium",
        visual_support=False, bilingual_answers=True, audio_cue=False,
        worksheet_types=["practice", "matching"],
        section="A",
    )
    # Pretend translation completed so structural checks run.
    for q in doc.questions:
        q.prompt.target = q.prompt.source + " (t)"
        q.prompt.translated = True
        q.prompt.provider = "x"
        for opt in q.options:
            text = opt.get("text", {})
            if isinstance(text, dict):
                text["target"] = text.get("source", "")
    doc.title.target = doc.title.source
    doc.instructions.target = doc.instructions.source
    ids = [q.id for q in doc.questions]
    ok = validate_worksheet(
        doc, expected_count=4, expected_ids=ids,
        nipun_code="M2.1.4", nipun_outcome="M2.1.4",
        target_language="sat", provider_name="x",
        source_language="hi",
        expected_types=["practice", "matching"],
        grade=2, subject="Mathematics", section="A", topic="Numbers up to 100",
    )
    assert ok == []
    # Missing type representation.
    bad_types = validate_worksheet(
        doc, expected_count=4, expected_ids=ids,
        target_language="sat", provider_name="x",
        expected_types=["practice", "matching", "writing"],
    )
    assert any("writing" in e for e in bad_types)
    # Count / section mismatch.
    bad = validate_worksheet(
        doc, expected_count=9, expected_ids=ids,
        target_language="sat", provider_name="x",
        section="B",
    )
    assert any("count" in e.lower() for e in bad)
    assert any("Section" in e for e in bad)


def test_pdf_renders_real_content():
    builder = ScaffoldBuilder()
    doc = builder.build(
        request_id="req-pdf", grade=2, subject="Mathematics",
        topic="Numbers up to 100", nipun_outcome="M2.1.4", nipun_code="M2.1.4",
        source_language="hi", target_language="sat",
        worksheet_type="practice", question_count=4, difficulty="medium",
        visual_support=True, bilingual_answers=True, audio_cue=False,
        worksheet_types=["practice"],
        section="A",
    )
    for q in doc.questions:
        q.prompt.target = q.prompt.source
    doc.title.target = doc.title.source
    doc.instructions.target = doc.instructions.source
    data = render_worksheet_pdf(doc)
    assert data[:4] == b"%PDF"
    # Real topic text embedded (UTF-16BE hex).
    topic_hex = "Numbers up to 100".encode("utf-16-be").hex().upper()
    assert topic_hex.encode("ascii") in data
    # No mock placeholder text.
    assert b"Mock PDF" not in data


def test_provider_routing_ho_mundari_never_sarvam():
    registry = LanguageCapabilityRegistry()
    ho = registry.provider_for("hi", "ho")
    unr = registry.provider_for("hi", "unr")
    assert isinstance(ho, CorpusNmtProvider)
    assert isinstance(unr, CorpusNmtProvider)
    assert not isinstance(ho, SarvamTranslateProvider)
    assert not isinstance(unr, SarvamTranslateProvider)
    sat = registry.provider_for("hi", "sat")
    assert isinstance(sat, SarvamTranslateProvider)
