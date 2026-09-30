"""Deterministic source-language worksheet builder.

Builds a structured worksheet from teacher parameters + NIPUN/curriculum data
using seeded curriculum-safe scaffolds (seeded by request_id, so the same
request always builds the same scaffold — idempotency friendly).

Grade ranges honour backend/generator/canonical/curriculum_master_v1.json:
- Grade 1: numerals 0-20, counting sets <= 20, addition sums <= 18,
  subtraction within 9 (rules X_G1_NUMBER_RANGE / X_G1_COUNT_RANGE /
  X_G1_ADDSUB_RANGE).
- Grade 2: numbers 0-99, no 3-digit numbers (rule X_G2_NUMBER_RANGE).
"""
from __future__ import annotations

import json
import logging
import random
from functools import lru_cache
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple

from app.worksheets.local_context import LocalContextLibrary
from app.worksheets.schemas import BilingualField, WorksheetDocument, WorksheetQuestionDoc

logger = logging.getLogger(__name__)

_HI_ONES = [
    "शून्य", "एक", "दो", "तीन", "चार", "पाँच", "छह", "सात", "आठ", "नौ", "दस",
    "ग्यारह", "बारह", "तेरह", "चौदह", "पंद्रह", "सोलह", "सत्रह", "अठारह", "उन्नीस", "बीस",
]
_HI_TENS = ["", "", "बीस", "तीस", "चालीस", "पचास", "साठ", "सत्तर", "अस्सी", "नब्बे"]

_EN_ONES = [
    "zero", "one", "two", "three", "four", "five", "six", "seven", "eight",
    "nine", "ten", "eleven", "twelve", "thirteen", "fourteen", "fifteen",
    "sixteen", "seventeen", "eighteen", "nineteen", "twenty",
]
_EN_TENS = ["", "", "twenty", "thirty", "forty", "fifty", "sixty", "seventy", "eighty", "ninety"]

_OBJECT_EMOJI = {
    "आम": "🍎", "कंचे": "🔮", "छड़ें": "🥢", "गेंद": "⚽",
    "फूल": "🌸", "तारे": "⭐", "चूड़ियाँ": "📿", "किताबें": "📚",
}

SUPPORTED_SOURCES = ("hi", "en")

_TYPE_ALIASES = {
    "practice": "practice",
    "counting": "counting",
    "fillintheblanks": "fill_blank",
    "fill_blank": "fill_blank",
    "fill-blank": "fill_blank",
    "matching": "matching",
    "multiplechoice": "multiple_choice",
    "multiple_choice": "multiple_choice",
    "writing": "writing",
    "reading": "reading",
}


def normalize_worksheet_type(raw: str) -> str:
    key = (raw or "practice").strip().lower().replace(" ", "").replace("_", "")
    # keep camelCase boundary: fillInTheBlanks -> fillintheblanks
    return _TYPE_ALIASES.get(key, "practice")


def normalize_worksheet_types(raw: Any) -> List[str]:
    """Normalize one or many worksheet types to canonical codes.

    Accepts a single string or a list. Unknown codes fall back to
    "practice" individually (never drops a valid selection silently).
    """
    if raw is None:
        return ["practice"]
    items = raw if isinstance(raw, list) else [raw]
    out: List[str] = []
    for item in items:
        if not isinstance(item, str) or not item.strip():
            continue
        # also accept comma-separated strings from legacy clients
        for part in item.split(","):
            if part.strip():
                out.append(normalize_worksheet_type(part))
    # de-duplicate preserving order
    seen: List[str] = []
    for t in out:
        if t not in seen:
            seen.append(t)
    return seen or ["practice"]


def allocate_types(types: List[str], count: int) -> List[str]:
    """Deterministic question allocation across selected worksheet types.

    Strategy (documented): round-robin over the selected types in sorted
    order, seeded only by position (not random), so the same request always
    yields the same per-type counts. Each type gets floor(count/n) or
    ceil(count/n) questions; every selected type is represented at least
    once when count >= number of types. No question is duplicated: each
    slot builds a fresh scaffold of its allocated type.
    """
    canonical = normalize_worksheet_types(types)
    ordered = sorted(canonical)
    return [ordered[i % len(ordered)] for i in range(count)]


def normalize_difficulty(raw: str) -> str:
    key = (raw or "medium").strip().lower()
    if key in ("easy", "सरल"):
        return "easy"
    if key in ("hard", "challenging", "कठिन", "चुनौतीपूर्ण"):
        return "hard"
    return "medium"


def hindi_number_word(n: int) -> str:
    if 0 <= n <= 20:
        return _HI_ONES[n]
    tens, ones = divmod(n, 10)
    if ones == 0:
        return _HI_TENS[tens]
    return f"{_HI_TENS[tens]} { _HI_ONES[ones]}".strip()


def english_number_word(n: int) -> str:
    if 0 <= n <= 20:
        return _EN_ONES[n]
    if n < 100:
        tens, ones = divmod(n, 10)
        if ones == 0:
            return _EN_TENS[tens]
        return f"{_EN_TENS[tens]}-{_EN_ONES[ones]}"
    return str(n)


def grade_number_cap(grade: int) -> int:
    if grade <= 1:
        return 20
    if grade == 2:
        return 99
    return 999


@lru_cache(maxsize=1)
def _load_curriculum_master() -> Any:
    candidates = [
        Path(__file__).resolve().parents[2] / "generator" / "canonical" / "curriculum_master_v1.json",
        Path.cwd() / "generator" / "canonical" / "curriculum_master_v1.json",
        Path.cwd() / "backend" / "generator" / "canonical" / "curriculum_master_v1.json",
    ]
    for path in candidates:
        if path.exists():
            try:
                return json.loads(path.read_text(encoding="utf-8"))
            except Exception as exc:
                logger.warning("Curriculum master unreadable: %s", exc)
                return None
    return None


def find_outcome_statement(code: Optional[str]) -> Optional[str]:
    """Best-effort lookup of the NIPUN outcome statement from curriculum master."""
    if not code:
        return None
    master = _load_curriculum_master()
    if master is None:
        return None
    target = code.strip().lower()
    stack: List[Any] = [master]
    while stack:
        node = stack.pop()
        if isinstance(node, dict):
            node_code = str(node.get("code", "")).strip().lower()
            if node_code == target:
                for key in ("statement", "outcome", "description", "title", "competency"):
                    val = node.get(key)
                    if isinstance(val, str) and val.strip():
                        return val.strip()
                return None
            stack.extend(node.values())
        elif isinstance(node, list):
            stack.extend(node)
    return None


def _distractors(rng: random.Random, correct: int, cap: int, count: int = 2) -> List[int]:
    options = {correct}
    candidates = [correct + 1, correct - 1, correct + 2, correct - 2, correct + 10, correct - 10]
    rng.shuffle(candidates)
    for c in candidates:
        if len(options) > count:
            break
        if 0 <= c <= cap and c not in options:
            options.add(c)
    n = correct + 3
    while len(options) <= count:
        if 0 <= n <= cap and n not in options:
            options.add(n)
        n += 1
    ordered = list(options)
    rng.shuffle(ordered)
    return ordered


class ScaffoldBuilder:
    """Builds the source-language WorksheetDocument for a generation request."""

    def __init__(self, local_context: Optional[LocalContextLibrary] = None):
        self.local_context = local_context or LocalContextLibrary()

    def build(
        self,
        *,
        request_id: str,
        grade: int,
        subject: str,
        topic: str,
        nipun_outcome: Optional[str],
        nipun_code: Optional[str],
        source_language: str,
        target_language: str,
        worksheet_type: str = "practice",
        question_count: int = 10,
        difficulty: str = "medium",
        visual_support: bool = True,
        bilingual_answers: bool = True,
        audio_cue: bool = False,
        worksheet_types: Optional[List[str]] = None,
        section: Optional[str] = None,
        topic_source: str = "curriculum",
        topic_id: Optional[str] = None,
        topic_input_language: str = "en",
    ) -> WorksheetDocument:
        if source_language not in SUPPORTED_SOURCES:
            raise ValueError(
                f"Source language '{source_language}' is not supported for generation."
            )
        types = normalize_worksheet_types(worksheet_types or worksheet_type)
        primary_type = sorted(types)[0]
        diff = normalize_difficulty(difficulty)
        rng = random.Random(request_id)
        cap = grade_number_cap(grade)
        # Difficulty genuinely shapes content: easy shrinks number ranges and
        # uses single blanks; hard widens ranges, adds steps of 2-3 and hints.
        diff_cap = cap
        if diff == "easy":
            diff_cap = min(cap, 20 if grade >= 2 else cap)
        elif diff == "hard":
            diff_cap = cap
        objects = self.local_context.objects_for(grade, subject)
        # Custom topics carry no fabricated NIPUN code: only curriculum topics
        # resolve an outcome statement.
        outcome_text = None
        if (topic_source or "curriculum") == "curriculum":
            outcome_text = find_outcome_statement(nipun_code or nipun_outcome)

        en = source_language == "en"
        title_text = (
            f"{topic} — Practice Worksheet" if en else f"{topic} — अभ्यास पत्रक"
        )
        instructions_text = self._instructions(en, primary_type, cap)
        teacher_notes_text = self._teacher_notes(
            en, nipun_code or nipun_outcome, outcome_text, source_language, target_language
        )

        # Deterministic multi-type allocation: every selected type represented,
        # no duplicated questions (each slot is a fresh scaffold of its type).
        plan = allocate_types(types, question_count)
        questions: List[WorksheetQuestionDoc] = []
        for i, qtype in enumerate(plan):
            questions.append(
                self._build_question(
                    rng=rng, index=i, qtype=qtype, cap=diff_cap, grade=grade,
                    objects=objects, en=en, diff=diff, visual_support=visual_support,
                )
            )

        def _field(text: str) -> BilingualField:
            return BilingualField(source=text, target="", provider="pending", translated=False)

        return WorksheetDocument(
            content_id="",
            request_id=request_id,
            title=_field(title_text),
            instructions=_field(instructions_text),
            questions=questions,
            teacher_notes=_field(teacher_notes_text),
            metadata={
                "grade": grade,
                "section": section,
                "subject": subject,
                "topic": topic,
                "topic_source": topic_source,
                "topic_id": topic_id,
                "topic_input_language": topic_input_language,
                "nipun_outcome": nipun_outcome,
                "nipun_code": nipun_code,
                "nipun_statement": outcome_text,
                "source_language": source_language,
                "target_language": target_language,
                "worksheet_type": primary_type,
                "worksheet_types": sorted(types),
                "difficulty": diff,
                "question_count": question_count,
                "visual_support": visual_support,
                "bilingual_answers": bilingual_answers,
                "audio_cue": audio_cue,
            },
        )

    # -- Static text ------------------------------------------------------

    def _instructions(self, en: bool, wtype: str, cap: int) -> str:
        if en:
            return {
                "counting": "Look at the pictures. Count and circle the correct number.",
                "fill_blank": "Fill in the blanks to complete the number order.",
                "matching": "Match each item on the left with the correct item on the right.",
                "multiple_choice": "Read each question and tick the correct answer.",
                "writing": "Trace the numbers and write their names.",
                "reading": "Read the lines and answer the questions.",
                "practice": "Read each question carefully and write or tick the correct answer.",
            }[wtype]
        return {
            "counting": "चित्र देखो। गिनकर सही संख्या पर गोला लगाओ।",
            "fill_blank": "रिक्त स्थान भरो और संख्या क्रम पूरा करो।",
            "matching": "बाईं ओर के प्रत्येक चित्र/शब्द को दाईं ओर के सही उत्तर से मिलाओ।",
            "multiple_choice": "प्रत्येक प्रश्न पढ़ो और सही उत्तर पर निशान लगाओ।",
            "writing": "संख्याओं पर उँगली फेरो और उनके नाम लिखो।",
            "reading": "पंक्तियाँ पढ़ो और प्रश्नों के उत्तर दो।",
            "practice": "प्रत्येक प्रश्न ध्यान से पढ़ो और सही उत्तर लिखो या उस पर निशान लगाओ।",
        }[wtype]

    def _teacher_notes(self, en: bool, code: Optional[str], statement: Optional[str],
                       src: str, tgt: str) -> str:
        code_part = f" ({code})" if code else ""
        stmt_part = f" {statement}" if statement else ""
        if en:
            return f"NIPUN outcome{code_part}.{stmt_part} Language pair: {src} → {tgt}."
        return f"NIPUN outcome{code_part}।{stmt_part} भाषा युग्म: {src} → {tgt}।"

    def _pick_type(self, wtype: str, index: int) -> str:
        if wtype != "practice":
            return wtype
        cycle = ["counting", "fill_blank", "tens_ones", "multiple_choice"]
        return cycle[index % len(cycle)]

    def _visual(self, obj_hi: str, n: int, enabled: bool) -> Optional[str]:
        if not enabled:
            return None
        emoji = _OBJECT_EMOJI.get(obj_hi, "🔢")
        return " ".join([emoji] * max(1, min(n, 8)))

    # -- Question scaffolds -------------------------------------------------

    def _build_question(self, *, rng: random.Random, index: int, qtype: str,
                        cap: int, grade: int, objects: List[Dict[str, Any]],
                        en: bool, diff: str, visual_support: bool) -> WorksheetQuestionDoc:
        qid = f"q{index + 1}"
        obj = rng.choice(objects)
        obj_hi, obj_en = obj.get("name_hi", "आम"), obj.get("name_en", "mango")
        obj_word = obj_en if en else obj_hi

        if qtype == "counting":
            total = rng.randint(2, min(cap, 9 if grade <= 1 else cap))
            a = rng.randint(1, total - 1)
            b = total - a
            prompt = (
                f"{a} {obj_word} and {b} {obj_word}. How many {obj_word} in all?"
                if en else f"{a} {obj_word} और {b} {obj_word}। कुल कितने {obj_word}?"
            )
            values = _distractors(rng, total, cap)
            answer = total
            visual = self._visual(obj_hi, total, visual_support)
        elif qtype == "fill_blank":
            if diff == "easy":
                step = 1
            elif diff == "hard":
                step = rng.choice([2, 3])
            else:
                step = rng.choice([1, 2])
            start = rng.randint(0, max(0, cap - 4 * step))
            seq = [start + i * step for i in range(5)]
            blanks = [2] if diff == "easy" else [1, 3]
            shown = [str(v) if i not in blanks else "__" for i, v in enumerate(seq)]
            answer = seq[blanks[0]]
            prompt = (
                f"Fill in the blank: {', '.join(shown)}"
                if en else f"रिक्त स्थान भरो: {', '.join(shown)}"
            )
            values = _distractors(rng, answer, cap)
            visual = None
        elif qtype == "tens_ones":
            tens = rng.randint(1, 9 if cap >= 99 else max(1, cap // 10))
            ones = rng.randint(0, 9)
            answer = tens * 10 + ones
            if answer > cap:
                answer, ones = tens * 10, 0
            prompt = (
                f"What number is {tens} tens and {ones} ones?"
                if en else f"{tens} दहाई और {ones} इकाई मिलकर क्या संख्या बनेगी?"
            )
            values = _distractors(rng, answer, cap)
            visual = None
        elif qtype == "matching":
            n = rng.randint(11, min(cap, 99)) if cap >= 20 else rng.randint(2, cap)
            word = english_number_word(n) if en else hindi_number_word(n)
            prompt = (
                f"Match '{n}' with its name."
                if en else f"'{n}' को उसके नाम से मिलाओ।"
            )
            values_text = [word]
            pool = set()
            while len(pool) < 2:
                m = rng.randint(0, min(cap, 99))
                if m != n:
                    pool.add(english_number_word(m) if en else hindi_number_word(m))
            values_text.extend(sorted(pool))
            rng.shuffle(values_text)
            return WorksheetQuestionDoc(
                id=qid, number=index + 1, type="matching",
                prompt=BilingualField(source=prompt, target="", provider="pending", translated=False),
                options=[
                    {"option_id": chr(97 + i), "value": t,
                     "text": BilingualField(source=t, target="", provider="pending", translated=False).model_dump()}
                    for i, t in enumerate(values_text)
                ],
                answer={"option_id": chr(97 + values_text.index(word)), "value": word},
                hint=None,
                visual=self._visual(obj_hi, n, visual_support),
            )
        elif qtype == "writing":
            n = rng.randint(0, min(cap, 20))
            word = english_number_word(n) if en else hindi_number_word(n)
            prompt = (
                f"Write the name of number {n}:"
                if en else f"संख्या {n} का नाम लिखो:"
            )
            values = [n]
            answer = word
            visual = None
            return WorksheetQuestionDoc(
                id=qid, number=index + 1, type="writing",
                prompt=BilingualField(source=prompt, target="", provider="pending", translated=False),
                options=[{"option_id": "a", "value": word,
                           "text": BilingualField(source=word, target="", provider="pending", translated=False).model_dump()}],
                answer={"option_id": "a", "value": word},
                hint=None, visual=visual,
            )
        elif qtype == "reading":
            n = rng.randint(2, min(cap, 20))
            prompt = (
                f"There are {n} {obj_word} on the tree. One more falls. How many now?"
                if en else f"पेड़ पर {n} {obj_word} हैं। एक और गिर गया। अब कुल कितने?"
            )
            answer = n + 1
            values = _distractors(rng, answer, cap + 1)
            visual = self._visual(obj_hi, answer, visual_support)
        else:  # multiple_choice arithmetic honoring grade caps + difficulty
            if grade <= 1:
                hi = 5 if diff == "easy" else (9 if diff == "medium" else 9)
                a = rng.randint(0, hi)
                b = rng.randint(0, max(0, (10 if diff == "easy" else 18) - a))
                answer = a + b
                prompt = f"{a} + {b} = ?" if en else f"{a} + {b} = कितना?"
            else:
                a_hi = 20 if diff == "easy" else (50 if diff == "medium" else min(cap, 70))
                b_hi = 10 if diff == "easy" else 20
                a = rng.randint(2, min(cap, a_hi))
                b = rng.randint(1, min(max(1, cap - a), b_hi))
                answer = a + b
                prompt = (
                    f"Add: {a} + {b} = ?" if en else f"जोड़ो: {a} + {b} = कितना?"
                )
            values = _distractors(rng, answer, cap + 20)
            visual = None

        option_ids = [chr(97 + i) for i in range(len(values))]
        correct_idx = values.index(answer)
        hint = None
        if diff == "hard":
            hint = (
                "Count slowly one by one." if en else "एक-एक करके धीरे-धीरे गिनो।"
            )
        return WorksheetQuestionDoc(
            id=qid, number=index + 1, type=qtype,
            prompt=BilingualField(source=prompt, target="", provider="pending", translated=False),
            options=[
                {"option_id": oid, "value": v,
                 "text": BilingualField(source=str(v), target="", provider="pending", translated=False).model_dump()}
                for oid, v in zip(option_ids, values)
            ],
            answer={"option_id": option_ids[correct_idx], "value": answer},
            hint=(BilingualField(source=hint, target="", provider="pending", translated=False) if hint else None),
            visual=visual,
        )
