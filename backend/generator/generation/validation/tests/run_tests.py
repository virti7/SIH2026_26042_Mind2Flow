"""Self-tests for the validators: valid fixtures must pass; each mutation must raise the named error code.
Run: python generation/validation/tests/run_tests.py
"""
import copy
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.dirname(HERE))
from common import load_json  # noqa: E402
from content_validator import validate_unit  # noqa: E402

NUM = load_json(os.path.join(HERE, "fixtures", "valid_numeracy_bilingual.json"))
LIT = load_json(os.path.join(HERE, "fixtures", "valid_literacy_parallel_hi.json"))


def m(base, fn):
    d = copy.deepcopy(base)
    fn(d)
    return d


def setp(path, val):
    def f(d):
        o = d
        for k in path[:-1]:
            o = o[k]
        o[path[-1]] = val
    return f


CASES = [
    # (name, content, expected_error_code or None for pass)
    ("numeracy fixture passes", NUM, None),
    ("literacy parallel fixture passes", LIT, None),
    ("invalid schema: missing answer_key", m(NUM, lambda d: d.pop("answer_key")), "SCHEMA"),
    ("unknown blueprint", m(NUM, setp(["blueprint_id"], "BP-G1-NUM-999-01")), "BP_UNKNOWN"),
    ("wrong grade", m(NUM, setp(["grade"], 2)), "BP_GRADE"),
    ("wrong content type", m(NUM, setp(["content_type"], "flashcard")), "BP_CONTENT_TYPE"),
    ("wrong item count", m(NUM, lambda d: d["items"].pop()), "COUNT"),
    ("wrong answer key", m(NUM, lambda d: d["answer_key"].__setitem__(0, {"item_id": "q1", "answer": "a"})), "NUM_WRONG_ANSWER"),
    ("sum above 18 (G1)", m(NUM, lambda d: d["items"][0]["math"].update(operands=[12, 9])), "NUM_MAX_SUM"),
    ("number above 20 in G1 text", m(NUM, lambda d: d["items"][0]["prompt"].update(hi="25 आम और 7 आम।")), "NUM_TEXT_RANGE"),
    ("two correct options", m(NUM, lambda d: d["items"][0]["options"][0].update(value=11)), "NUM_OPTIONS"),
    ("missing math block", m(NUM, lambda d: d["items"][0].pop("math")), "NUM_MISSING_MATH"),
    ("provisional conflict dropped", m(NUM, setp(["conflict_refs"], [])), "CONFLICT_REFS"),
    ("provisional flag wrong", m(NUM, setp(["provisional"], False)), "PROVISIONAL_FLAG"),
    ("hindi gate missing", m(NUM, setp(["review_gates"], ["santali_content", "provisional_range"])), "REVIEW_GATES"),
    ("excluded area (clock)", m(NUM, lambda d: d["instructions"]["learner"].update(hi="घड़ी देखो और गिनो।")), "EXCLUDED_AREA"),
    ("missing santali text", m(NUM, lambda d: d["title"].pop("sat")), "LANG_MISSING_TEXT"),
    ("latin letters in santali", m(NUM, lambda d: d["title"].update(sat="milao")), "LANG_UNEXPECTED_LATIN"),
    ("devanagari in ol chiki santali", m(NUM, lambda d: d["title"].update(sat="मिलाओ")), "LANG_UNEXPECTED_SCRIPT"),
    ("bilingual missing a language", m(NUM, setp(["languages"], ["hi"])), "LANG_PAIR_INCOMPLETE"),
    ("parallel unit with two languages", m(LIT, lambda d: (d.__setitem__("languages", ["hi", "sat"]), d["scripts"].__setitem__("sat", "Olck"))), "LANG_PARALLEL"),
    ("parallel unit translated", m(LIT, setp(["generation_method"], "translated")), "SCHEMA"),
    ("audio asset missing", m(LIT, lambda d: d["items"][0].__setitem__("asset_refs", [])), "AUDIO_MISSING"),
    ("wrong options per question", m(LIT, lambda d: d["items"][0]["options"].pop()), "OPTIONS_COUNT"),
    ("answer not an option", m(LIT, lambda d: d["answer_key"].__setitem__(0, {"item_id": "q1", "answer": "z"})), "ANSWER_OPTION"),
    ("content_id language mismatch", m(LIT, setp(["content_id"], "GC-G1-LIT-015-01-sat-v1")), "LANG_CONTENT_ID"),
    ("latin in hindi", m(LIT, lambda d: d["items"][0]["prompt"].update(hi="mor")), "LANG_UNEXPECTED_LATIN"),
]


def main():
    failed = 0
    for name, content, code in CASES:
        rep = validate_unit(content)
        codes = {e["code"] for e in rep.errors}
        ok = rep.ok if code is None else code in codes
        failed += not ok
        print(f"{'ok  ' if ok else 'FAIL'}  {name}" + ("" if ok else f"   expected={code} got={sorted(codes)} {rep.errors[:3]}"))
    print(f"\n{len(CASES) - failed}/{len(CASES)} tests passed")
    sys.exit(1 if failed else 0)


if __name__ == "__main__":
    main()
