"""Blueprint-conformance validator for generated content units (entry point).

Runs, in order:
  1. JSON parse + JSON Schema (generated_content.schema.json)
  2. Blueprint / curriculum checks (ids, grade, domain, content type, mode, counts, options,
     assets, answer key, constraints, exclusions, provisional flag, conflict refs, review gates)
  3. numeracy_validator (numeracy units)
  4. language_validator (all units)

Usage:
  python content_validator.py <file.json | directory> [--report report.json]
Exit code 0 = all units passed (warnings allowed), 1 = at least one error.
"""
import argparse
import glob
import json
import os
import re
import sys

from jsonschema import Draft202012Validator

import language_validator
import numeracy_validator
from common import (BLUEPRINT_PATH, MASTER_PATH, SCHEMA_PATH, VALIDATOR_VERSION, Report, blueprint,
                    expected_count, iter_localized, load_json, master, master_item, sha256)

ALLOWED_ITEM_TYPES = {
    "flashcard": {"card"},
    "worksheet": {"multiple_choice", "match", "fill_blank", "sequence", "sort", "write", "count_and_select", "open_response"},
    "interactive_activity": {"multiple_choice", "match", "fill_blank", "sequence", "sort", "count_and_select",
                             "listen_and_choose", "open_response"},
    "audio_activity": {"listen_and_choose", "listen_and_write", "open_response"},
}
# Exclusions from prototype_policy.generation_exclusions (keyword scan; case-insensitive).
EXCLUDED_TERMS = {
    "fractions": ["fraction", "quarter", "one-fourth", "three-fourth", "भिन्न", "चौथाई", "तिहाई"],
    "clock_calendar": ["clock", "o'clock", "calendar", "घड़ी", "बजे", "कैलेंडर", "तारीख"],
    "paragraph_writing": ["write a paragraph", "paragraph writing", "अनुच्छेद लिख"],
    "reading_speed": ["words per minute", "wpm", "timer", "stopwatch", "प्रति मिनट"],
    "multiplication_tables": ["multiplication table", "times table", "पहाड़ा", "पहाड़े"],
}
SOFT_TERMS = {"half": ["half", "आधा", "आधी"]}  # allowed only as vocabulary -> warning
SENT_SPLIT = re.compile(r"[।.!?᱾॥]+")

_schema_validator = None


def schema_validator():
    global _schema_validator
    if _schema_validator is None:
        _schema_validator = Draft202012Validator(load_json(SCHEMA_PATH))
    return _schema_validator


def dev_aksharas(word):
    """Approximate akshara count for a Devanagari word (independent vowels + consonants not joined by virama)."""
    n, prev_virama = 0, False
    for ch in word:
        cp = ord(ch)
        if 0x0904 <= cp <= 0x0914 or 0x0960 <= cp <= 0x0961:
            n += 1
        elif 0x0915 <= cp <= 0x0939 or 0x0958 <= cp <= 0x095F:
            if not prev_virama:
                n += 1
        prev_virama = cp == 0x094D
    return n


def parse_range(v):
    if isinstance(v, int):
        return v, v
    a, b = str(v).split("-")
    return int(a), int(b)


def words(s):
    return [w for w in re.split(r"\s+", SENT_SPLIT.sub(" ", s)) if w]


def item_asset_refs(item):
    refs = list(item.get("asset_refs", []))
    for o in item.get("options", []):
        refs += o.get("asset_refs", [])
    return refs


def validate_unit(content, path="<memory>"):
    rep = Report("content_validator", content.get("content_id") if isinstance(content, dict) else None)
    # ---- 1. schema --------------------------------------------------------------------
    errs = sorted(schema_validator().iter_errors(content), key=lambda e: list(e.path))
    for e in errs:
        rep.error("SCHEMA", e.message[:300], "$." + ".".join(str(p) for p in e.path))
    if not isinstance(content, dict):
        return rep

    # ---- 2. blueprint & curriculum ---------------------------------------------------------
    bid = content.get("blueprint_id")
    bp = blueprint(bid)
    if bp is None:
        rep.error("BP_UNKNOWN", f"blueprint_id {bid!r} not in content_blueprint_v1.")
        return rep
    cid = content.get("curriculum_id")
    mi = master_item(cid)
    if cid != bp["curriculum_id"]:
        rep.error("CURRICULUM_MISMATCH", f"curriculum_id {cid!r} != blueprint's {bp['curriculum_id']!r}.")
    if mi is None:
        rep.error("CURRICULUM_UNKNOWN", f"curriculum_id {cid!r} not in curriculum_master_v1.")
    elif bp["grade"] not in mi["grade"]:
        rep.error("CURRICULUM_GRADE", "Blueprint grade not in curriculum item grades.")
    for f in ("grade", "domain", "content_type", "language_mode"):
        if content.get(f) != bp[f]:
            rep.error(f"BP_{f.upper()}", f"{f} {content.get(f)!r} != blueprint {bp[f]!r}.")
    cid_m = re.match(r"^GC-(G[12]-(?:LIT|NUM)-[0-9]{3}-[0-9]{2})-(bi|hi|sat)-v[0-9]+$", content.get("content_id", ""))
    if not cid_m or f"BP-{cid_m.group(1)}" != bid:
        rep.error("CONTENT_ID", "content_id does not match blueprint_id.")
    elif bp["language_mode"] == "bilingual" and cid_m.group(2) != "bi":
        rep.error("CONTENT_ID", "Bilingual units use the '-bi-' content_id suffix.")

    items = content.get("items", [])
    ids = [i.get("item_id") for i in items]
    if len(ids) != len(set(ids)):
        rep.error("ITEM_IDS", "Duplicate item_id values.")
    c = bp["generation_constraints"]

    # counts
    key, n = expected_count(bp)
    if key and len(items) != n:
        rep.error("COUNT", f"{len(items)} items; blueprint requires {key} = {n}.")
    # item types
    allowed = ALLOWED_ITEM_TYPES[bp["content_type"]]
    for it in items:
        if it.get("item_type") not in allowed:
            rep.error("ITEM_TYPE", f"item_type {it.get('item_type')!r} not allowed for {bp['content_type']}.", f"items[{it.get('item_id')}]")
    # options per question
    nopt = c.get("options_per_question") or c.get("picture_options")
    if nopt:
        for it in items:
            if it.get("item_type") in ("multiple_choice", "listen_and_choose", "count_and_select") and len(it.get("options", [])) != nopt:
                rep.error("OPTIONS_COUNT", f"{len(it.get('options', []))} options; blueprint requires {nopt}.", f"items[{it['item_id']}]")

    # assets
    assets = {a["asset_id"]: a for a in content.get("assets_required", [])}
    used = set(content.get("stimulus", {}).get("asset_refs", []))
    for it in items:
        refs = item_asset_refs(it)
        used |= set(refs)
        for r in refs:
            if r not in assets:
                rep.error("ASSET_UNDEFINED", f"asset_ref {r!r} not in assets_required.", f"items[{it['item_id']}]")
        types = {assets[r]["type"] for r in refs if r in assets}
        if (c.get("audio_required") or bp["content_type"] == "audio_activity") and "audio" not in types:
            rep.error("AUDIO_MISSING", "Item needs an audio asset.", f"items[{it['item_id']}]")
        if c.get("picture_per_card") and it.get("item_type") == "card" and "image" not in types:
            rep.error("IMAGE_MISSING", "Card needs a picture asset (picture_per_card).", f"items[{it['item_id']}]")
    for aid, a in assets.items():
        if aid not in used:
            rep.warn("ASSET_UNUSED", f"Asset {aid!r} is never referenced.")
        for fi in a.get("for_items", []):
            if fi not in ids and fi != "stimulus":
                rep.error("ASSET_FOR_ITEMS", f"Asset {aid!r} lists unknown item {fi!r}.")
    if c.get("visuals", True) and not any(a["type"] == "image" for a in assets.values()):
        rep.error("VISUALS_MISSING", "Blueprint requires visuals but no image asset is specified.")

    # answer key
    keys = {}
    for e in content.get("answer_key", []):
        if e["item_id"] in keys:
            rep.error("ANSWER_DUPLICATE", f"Duplicate answer for {e['item_id']!r}.")
        keys[e["item_id"]] = e
        if e["item_id"] not in ids:
            rep.error("ANSWER_UNKNOWN_ITEM", f"Answer for unknown item {e['item_id']!r}.")
    for it in items:
        iid = it["item_id"]
        if it.get("item_type") == "card":
            continue
        e = keys.get(iid)
        if e is None:
            rep.error("ANSWER_MISSING", "No answer_key entry.", f"items[{iid}]")
            continue
        opt_ids = [o["option_id"] for o in it.get("options", [])]
        ans = e["answer"]
        if it["item_type"] in ("multiple_choice", "listen_and_choose", "count_and_select") and opt_ids:
            if isinstance(ans, str) and ans not in opt_ids:
                rep.error("ANSWER_OPTION", f"Answer {ans!r} is not an option id.", f"items[{iid}]")
        if it["item_type"] == "sequence" and opt_ids:
            if not isinstance(ans, list) or sorted(ans) != sorted(opt_ids):
                rep.error("ANSWER_SEQUENCE", "Sequence answer must be an ordering of all option ids.", f"items[{iid}]")

    # provisional, conflicts, review gates
    if content.get("provisional") != bp["provisional"]:
        rep.error("PROVISIONAL_FLAG", f"provisional must be {bp['provisional']} (as in blueprint).")
    if sorted(content.get("conflict_refs", [])) != sorted(bp["conflict_refs"]):
        rep.error("CONFLICT_REFS", f"conflict_refs {content.get('conflict_refs')} must equal blueprint {bp['conflict_refs']}.")
    need = set(bp["review_gates"])
    if "hi" in content.get("languages", []):
        need.add("hindi_transcription")  # policy gate; bilingual numeracy blueprints omit it
    if "sat" not in content.get("languages", []):
        need.discard("santali_content")
    if bp["provisional"]:
        need.add("provisional_range")
    missing = need - set(content.get("review_gates", []))
    if missing:
        rep.error("REVIEW_GATES", f"Missing review gates: {sorted(missing)}.")

    # literacy text constraints
    langs = content.get("languages", [])
    if "story_sentences" in c:
        lo, hi_ = parse_range(c["story_sentences"])
        passage = content.get("stimulus", {}).get("passage", {})
        if not passage and bp["domain"] == "literacy" and "story_cards" not in c:
            rep.error("STORY_MISSING", "Blueprint requires a story; stimulus.passage is empty.")
        for l, s in passage.items():
            k = len([x for x in SENT_SPLIT.split(s) if x.strip()])
            if not lo <= k <= hi_:
                rep.error("STORY_LENGTH", f"{l} story has {k} sentences; blueprint requires {c['story_sentences']}.", "$.stimulus.passage")
    if "words_per_sentence" in c:
        lo, hi_ = parse_range(c["words_per_sentence"])
        for it in items:
            for l, s in it.get("prompt", {}).items():
                for sent in [x for x in SENT_SPLIT.split(s) if x.strip()]:
                    if not lo <= len(words(sent)) <= hi_:
                        rep.warn("SENTENCE_WORDS", f"{l} sentence has {len(words(sent))} words; blueprint {c['words_per_sentence']} (applies to the sentence to be read).", f"items[{it['item_id']}]")
    if "max_words_per_sentence" in c:
        for e in content.get("answer_key", []):
            if isinstance(e["answer"], dict):
                for l, s in e["answer"].items():
                    for sent in [x for x in SENT_SPLIT.split(s) if x.strip()]:
                        if len(words(sent)) > c["max_words_per_sentence"]:
                            rep.error("SENTENCE_TOO_LONG", f"{l} model answer has {len(words(sent))} words (> {c['max_words_per_sentence']}).", f"answer_key[{e['item_id']}]")
    if "word_length_aksharas" in c and "hi" in langs:
        lo, hi_ = parse_range(c["word_length_aksharas"])
        for e in content.get("answer_key", []):
            ans = e["answer"]
            texts = [ans["hi"]] if isinstance(ans, dict) and "hi" in ans else []
            it = next((i for i in items if i["item_id"] == e["item_id"]), None)
            if it and isinstance(ans, str):
                texts += [o.get("text", {}).get("hi", "") for o in it.get("options", []) if o["option_id"] == ans]
            for t in texts:
                for w in words(t):
                    k = dev_aksharas(w)
                    if k and not lo <= k <= hi_:
                        rep.warn("AKSHARA_LENGTH", f"Answer word {w!r} has ~{k} aksharas; blueprint {c['word_length_aksharas']} (heuristic count).", f"answer_key[{e['item_id']}]")
    if c.get("timed") is False or c.get("paragraph_writing") is False or c.get("tables_drill") is False:
        rep.note("CONSTRAINT_FLAGS", "Blueprint prohibits timed reading / paragraph writing / tables drill; enforced via exclusion scan.")

    # exclusions (keyword scan over learner text + asset briefs)
    blobs = [(p, s) for p, loc in iter_localized(content) for s in loc.values()]
    blobs += [(f"assets_required[{a['asset_id']}]", a.get("description_en", "")) for a in assets.values()]
    for p, s in blobs:
        low = s.lower()
        for area, terms in EXCLUDED_TERMS.items():
            for t in terms:
                if t in low:
                    rep.error("EXCLUDED_AREA", f"Mentions excluded area '{area}' ({t!r}).", p)
        for area, terms in SOFT_TERMS.items():
            for t in terms:
                if re.search(rf"(?<!\w){re.escape(t)}(?!\w)", low):
                    rep.warn("SOFT_EXCLUSION", f"Mentions '{t}': allowed only as everyday vocabulary, not a fraction lesson.", p)

    # ---- 3/4. sub-validators ----------------------------------------------------------------
    if bp["domain"] == "numeracy":
        rep.merge(numeracy_validator.validate(content, bp))
    rep.merge(language_validator.validate(content, bp))
    return rep


def validate_file(path):
    try:
        content = load_json(path)
    except (json.JSONDecodeError, UnicodeDecodeError) as e:
        rep = Report("content_validator")
        rep.error("INVALID_JSON", str(e))
        return rep
    return validate_unit(content, path)


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("target", help="content JSON file or directory")
    ap.add_argument("--report", help="write combined report JSON here")
    a = ap.parse_args()
    files = sorted(glob.glob(os.path.join(a.target, "**", "GC-*.json"), recursive=True)) if os.path.isdir(a.target) else [a.target]
    master()  # fail fast if master missing
    results = []
    for f in files:
        r = validate_file(f)
        d = r.to_dict()
        d["file"] = os.path.relpath(f)
        results.append(d)
        status = "PASS" if r.ok else "FAIL"
        print(f"{status}  {d['file']}  errors={len(r.errors)} warnings={len(r.warnings)}")
        for e in r.errors:
            print(f"   ERROR {e['code']}: {e['message']}  [{e.get('where') or ''}]")
    summary = {"validator_version": VALIDATOR_VERSION, "curriculum_master_sha256": sha256(MASTER_PATH),
               "blueprint_sha256": sha256(BLUEPRINT_PATH), "schema_sha256": sha256(SCHEMA_PATH),
               "files": len(results), "passed": sum(r["passed"] for r in results), "results": results}
    if a.report:
        with open(a.report, "w", encoding="utf-8") as fh:
            json.dump(summary, fh, ensure_ascii=False, indent=2)
    print(f"\n{summary['passed']}/{summary['files']} passed")
    sys.exit(0 if summary["passed"] == summary["files"] else 1)


if __name__ == "__main__":
    main()
