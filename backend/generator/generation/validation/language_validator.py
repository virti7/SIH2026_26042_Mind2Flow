"""Language and script checks for generated content units.

Checks:
  - language codes present match `languages` and the blueprint's language mode
  - bilingual: every learner-facing field has hi AND sat; parallel: exactly the one target language
  - no empty strings
  - every letter belongs to the declared script (hi = Devanagari; sat = declared script, default Ol Chiki)
  - unexpected Latin / Devanagari / other-script letters
  - identical hi/sat text (possible untranslated copy)
  - audio assets: language present and spoken_text in that language
  - Santali script still unconfirmed -> warning on every unit containing sat

Usage: python language_validator.py <content.json>
"""
import json
import re
import sys
import unicodedata

from common import LANGS, Report, blueprint, iter_localized, load_json

SCRIPT_RANGES = {
    "Deva": [(0x0900, 0x097F), (0xA8E0, 0xA8FF)],
    "Olck": [(0x1C50, 0x1C7F)],
    "Beng": [(0x0980, 0x09FF)],
    "Orya": [(0x0B00, 0x0B7F)],
    "Latn": [(0x0041, 0x005A), (0x0061, 0x007A), (0x00C0, 0x024F)],
}
SCRIPT_NAME = {"Deva": "Devanagari", "Olck": "Ol Chiki", "Beng": "Bengali", "Orya": "Odia", "Latn": "Latin"}


def script_of(ch):
    cp = ord(ch)
    for s, ranges in SCRIPT_RANGES.items():
        if any(a <= cp <= b for a, b in ranges):
            return s
    return None


def is_letterlike(ch):
    return unicodedata.category(ch)[0] in ("L", "M")


def check_string(s, lang, declared, rep, where):
    if not s.strip():
        rep.error("LANG_EMPTY", f"Empty {lang} text.", where)
        return
    bad = {}
    for ch in s:
        cat = unicodedata.category(ch)
        sc = script_of(ch)
        if cat == "Nd":  # digits
            if sc not in (None, "Latn", declared):
                rep.warn("LANG_DIGIT_SCRIPT", f"{lang} text uses {SCRIPT_NAME.get(sc, sc)} digits.", where)
            continue
        if not is_letterlike(ch):
            continue
        if sc != declared:
            bad.setdefault(sc or "other", []).append(ch)
    for sc, chars in bad.items():
        sample = "".join(dict.fromkeys(chars))[:10]
        code = "LANG_UNEXPECTED_LATIN" if sc == "Latn" else "LANG_UNEXPECTED_SCRIPT"
        rep.error(code, f"{lang} text contains {SCRIPT_NAME.get(sc, sc)} letters ({sample!r}); declared script is {SCRIPT_NAME[declared]}.", where)


def validate(content, bp=None):
    rep = Report("language_validator", content.get("content_id"))
    bp = bp or blueprint(content.get("blueprint_id"))
    langs = content.get("languages", [])
    scripts = content.get("scripts", {})
    mode = content.get("language_mode")

    # ---- declared languages vs mode / blueprint ---------------------------------------
    if bp:
        if mode != bp["language_mode"]:
            rep.error("LANG_MODE", f"language_mode {mode!r} differs from blueprint {bp['language_mode']!r}.")
        pair = set(bp["language_pair"])
        if bp["language_mode"] == "bilingual" and set(langs) != pair:
            rep.error("LANG_PAIR_INCOMPLETE", f"Bilingual unit must contain {sorted(pair)}; has {langs}.")
        if bp["language_mode"] == "parallel_monolingual":
            if len(langs) != 1 or langs[0] not in pair:
                rep.error("LANG_PARALLEL", f"Parallel unit must contain exactly one of {sorted(pair)}; has {langs}.")
            else:
                m = re.search(r"-(bi|hi|sat)-v[0-9]+$", content.get("content_id", ""))
                if not m or m.group(1) != langs[0]:
                    rep.error("LANG_CONTENT_ID", "content_id language suffix does not match `languages`.")
    if mode == "parallel_monolingual" and content.get("generation_method") != "native":
        rep.error("LANG_TRANSLATED_PARALLEL", "Parallel units must be generated natively, not translated.")
    if mode == "bilingual" and content.get("generation_method") == "translated":
        rep.warn("LANG_TRANSLATED", "Unit was produced by translation; Santali needs extra reviewer attention.")

    for l in langs:
        if l not in scripts:
            rep.error("LANG_NO_SCRIPT", f"No script declared for {l}.")
    if "hi" in scripts and scripts["hi"] != "Deva":
        rep.error("LANG_HI_SCRIPT", "Hindi must be Devanagari.")
    if "sat" in langs:
        rep.warn("LANG_SAT_SCRIPT_UNCONFIRMED", f"Santali script '{scripts.get('sat')}' is provisional; must be confirmed by a Santali-literate reviewer.")
        if scripts.get("sat") == "Deva":
            rep.warn("LANG_SAT_DEVA", "Santali written in Devanagari: Hindi words can slip in undetected; reviewer must check closely.")

    # ---- every learner-facing language object -----------------------------------------
    for path, loc in iter_localized(content):
        single = path.endswith(".spoken_text")  # audio text is in the asset's one language
        missing = [] if single else [l for l in langs if l not in loc]
        extra = [l for l in loc if l not in langs]
        if missing:
            rep.error("LANG_MISSING_TEXT", f"Missing {missing} text.", path)
        if extra:
            rep.error("LANG_EXTRA_TEXT", f"Unexpected language(s) {extra} for this unit.", path)
        for l, s in loc.items():
            if l in scripts:
                check_string(s, l, scripts[l], rep, path)
        if mode == "bilingual" and "hi" in loc and "sat" in loc:
            a, b = loc["hi"].strip(), loc["sat"].strip()
            if a == b and any(is_letterlike(ch) for ch in a):
                rep.warn("LANG_IDENTICAL", "hi and sat text are identical (possible untranslated copy).", path)

    # ---- audio assets --------------------------------------------------------------------
    for a in content.get("assets_required", []):
        if a.get("type") != "audio":
            continue
        where = f"assets_required[{a['asset_id']}]"
        l = a.get("language")
        if l not in langs:
            rep.error("LANG_AUDIO_LANG", f"Audio asset language {l!r} not in unit languages {langs}.", where)
        st = a.get("spoken_text", {})
        if l not in st:
            rep.error("LANG_AUDIO_TEXT", f"Audio asset has no spoken_text for {l!r}.", where)
        if set(st) - {l}:
            rep.warn("LANG_AUDIO_EXTRA", "spoken_text contains languages other than the asset's language.", where)
    return rep


if __name__ == "__main__":
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    r = validate(load_json(sys.argv[1]))
    print(json.dumps(r.to_dict(), ensure_ascii=False, indent=2))
    sys.exit(0 if r.ok else 1)
