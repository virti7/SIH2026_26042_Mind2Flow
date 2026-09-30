"""Language-alias resolution for the translation API.

Accepted aliases
----------------
Hindi:    hi, hin, hindi, hin_Deva
Santali:  sat, santali, sat_Olck  (Ol Chiki script)

Internally everything is mapped to the exact IndicTrans2 / FLORES-200 tags:
    hindi   -> hin_Deva
    santali -> sat_Olck
The target language is never guessed: it must be settable, or it defaults to
the explicit opposite of the source.
"""

from __future__ import annotations

from .config import HINDI_TAG, SANTALI_TAG

ALIASES = {
    "hi": HINDI_TAG,
    "hin": HINDI_TAG,
    "hindi": HINDI_TAG,
    "hin_deva": HINDI_TAG,
    "sat": SANTALI_TAG,
    "santali": SANTALI_TAG,
    "sat_olck": SANTALI_TAG,
}

DISPLAY = {
    HINDI_TAG: "Hindi",
    SANTALI_TAG: "Santali (Ol Chiki)",
}

_DIRECTION_LABEL = {
    (HINDI_TAG, SANTALI_TAG): "Hindi \u2192 Santali",
    (SANTALI_TAG, HINDI_TAG): "Santali \u2192 Hindi",
}


class LanguageError(ValueError):
    pass


def canonicalize(alias: str | None) -> str | None:
    """Return the canonical IndicTrans2 tag for an alias, or None if unset."""
    if alias is None:
        return None
    key = str(alias).strip().lower()
    if not key:
        return None
    tag = ALIASES.get(key)
    if tag is None:
        raise LanguageError(
            f"Unsupported language alias: {alias!r}. "
            f"Use one of: {sorted(ALIASES)}"
        )
    return tag


def resolve_src_tgt(src_lang: str | None, tgt_lang: str | None = None) -> tuple[str, str]:
    """Resolve (src_tag, tgt_tag). Target defaults to the opposite of source."""
    src = canonicalize(src_lang)
    if src is None:
        raise LanguageError("A source language (src_lang) is required.")
    tgt = canonicalize(tgt_lang)
    if tgt is None:
        tgt = SANTALI_TAG if src == HINDI_TAG else HINDI_TAG
    if src == tgt:
        raise LanguageError("Source and target languages must differ.")
    return src, tgt


def direction_label(src_tag: str, tgt_tag: str) -> str:
    return _DIRECTION_LABEL.get((src_tag, tgt_tag), f"{src_tag} -> {tgt_tag}")


def display_name(tag: str) -> str:
    return DISPLAY.get(tag, tag)