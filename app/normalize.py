"""Output normalization + source-content consistency checks.

normalize_translation_output   -> cosmetic-only cleanup (never removes words).
detect_suspicious_output       -> lightweight local quality check that decides
                                  whether a stricter retry is worthwhile.
"""

from __future__ import annotations

import re

_DOUBLE_SPACE = re.compile(r"[ \t]{2,}")
_REPEATED_PUNCT = re.compile(r"([.!?।॥,])\1+")
_QUOTES = ("'", '"', "\u2018", "\u2019", "\u201c", "\u201d")


def unwrap(value):
    """Repeatedly unwrap list/tuple/dict wrappers down to a plain string."""
    seen = 0
    while seen < 10:
        if isinstance(value, (list, tuple)):
            value = value[0] if value else ""
            seen += 1
            continue
        if isinstance(value, dict):
            value = (
                value.get("text")
                or value.get("translation")
                or value.get("translated_text")
                or value.get("target_text")
            )
            seen += 1
            continue
        break
    return value


def normalize_translation_output(value, src_lang=None, tgt_lang=None) -> str:
    """Cosmetic cleanup that preserves all legitimate translated content.

    Strips whitespace, drops accidental surrounding quotes, removes stray
    Python list formatting such as ``['...']``, and collapses repeated spaces /
    punctuation. It never deletes words, never truncates, and keeps Ol Chiki
    and Devanagari text intact.
    """
    text = unwrap(value)
    if text is None:
        return ""
    text = str(text)

    text = text.strip()
    if len(text) >= 2:
        for q in _QUOTES:
            if text.startswith(q) and text.endswith(q):
                text = text[1:-1].strip()
                break

    # Stray list/set braces that survived JSON string conversion.
    if text.startswith("['") and text.endswith("']"):
        text = text[2:-2].strip()
    elif text.startswith('["') and text.endswith('"]'):
        text = text[2:-2].strip()

    text = _DOUBLE_SPACE.sub(" ", text)
    text = _REPEATED_PUNCT.sub(r"\1", text)
    return text.strip()


def count_words(text: str) -> int:
    text = (text or "").strip()
    if not text:
        return 0
    return len(text.split())


# Unicode blocks for the two target scripts. Checked so a translation that
# leaks the wrong script (or the source script) is reported instead of being
# presented to the user as a clean result.
_SCRIPT_RANGES = {
    "devanagari": (0x0900, 0x097F),
    "olchiki": (0x1C50, 0x1C7F),
}
_SCRIPT_NAMES = {"hin_Deva": "devanagari", "sat_Olck": "olchiki"}


def script_profile(text: str) -> dict:
    """Count characters belonging to each known script in ``text``."""
    counts = {name: 0 for name in _SCRIPT_RANGES}
    letters = 0
    for ch in text:
        code = ord(ch)
        if not ch.isalpha():
            continue
        letters += 1
        for name, (lo, hi) in _SCRIPT_RANGES.items():
            if lo <= code <= hi:
                counts[name] += 1
                break
    return {"letters": letters, **counts}


def check_script_integrity(text: str, tgt_lang: str) -> dict:
    """Report whether ``text`` is actually written in the target script.

    Costs nothing at inference time. A wrong-script result is a real defect, so
    it is surfaced as a warning rather than hidden.
    """
    expected = _SCRIPT_NAMES.get(tgt_lang)
    profile = script_profile(text)
    if expected is None or profile["letters"] == 0:
        return {"expected": expected, "ok": True, **profile}
    expected_count = profile[expected]
    # Punctuation and digits are ignored; require the target script to dominate.
    ok = expected_count / float(profile["letters"]) >= 0.5
    return {"expected": expected, "ok": ok, **profile}


def detect_suspicious_output(src_text: str, out_text: str) -> dict:
    """Lightweight consistency check for short educational sentences.

    Reports whether the output is suspiciously longer than the source, and
    whether the trailing clause appears duplicated elsewhere in the sentence.
    No language-specific phrase blacklists are used.
    """
    src_n = count_words(src_text)
    out_n = count_words(out_text)
    ratio = (out_n / src_n) if src_n else 0.0

    flag = False
    reasons = []

    if out_n == 0:
        flag = True
        reasons.append("empty-output")
        return {"suspicious": flag, "reasons": reasons, "ratio": ratio}

    if src_n <= 8:
        threshold = 2.2 * src_n + 4
    else:
        threshold = 1.8 * src_n + 8
    if out_n > threshold:
        flag = True
        reasons.append(f"expansion-out>in-{out_n}>{round(threshold, 1)}")

    tokens = out_text.split()
    if len(tokens) >= 6:
        for k in (2, 3):
            if len(tokens) >= 2 * k and set(("-", ".", "।", ",")) != {t for t in tokens}:
                last_seq = " ".join(tokens[-k:])
                prefix = " ".join(tokens[: len(tokens) - k])
                if last_seq in prefix:
                    flag = True
                    reasons.append(f"repeated-trailing-clause-{k}")
                    break

    return {"suspicious": flag, "reasons": reasons, "ratio": round(ratio, 2)}


def pick_best_candidate(candidates):
    """Choose the candidate with the least quality risk, tie-broken by length.

    candidates: list of dicts with keys 'text', 'mode', 'suspicious',
                'reasons', 'ratio'.
    """
    def key(c):
        return (1 if c["suspicious"] else 0, c["ratio"], count_words(c["text"]))

    if not candidates:
        return None
    return min(candidates, key=key)