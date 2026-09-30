"""Mechanical mathematics checks for numeracy content units.

- Recomputes every answer from the item's `math` block and compares it with the answer key.
- Enforces blueprint limits (number_range, max_sum, max_minuend, max_number, max_total,
  group_size_range, steps, max_amount_rs, pattern_types) and the provisional prototype ranges:
    Grade 1: counting sets <= 20, numbers <= 20, sums <= 18, minuend <= 9
    Grade 2: numbers <= 99 (money amounts may reach the blueprint's max_amount_rs, i.e. Rs 100)
- Scans learner-facing text for numbers outside those limits.

Usage: python numeracy_validator.py <content.json>
"""
import json
import re
import sys

from common import Report, blueprint, iter_localized, load_json

GRADE_CAP = {1: 20, 2: 99}
G1_MAX_SUM, G1_MAX_MINUEND, G1_MAX_COUNT = 18, 9, 20
DENOMINATIONS = {1, 2, 5, 10, 20, 50, 100}
DIGIT_MAP = {ord(c): str(i) for i, c in enumerate("०१२३४५६७८९")}
DIGIT_MAP.update({ord(c): str(i) for i, c in enumerate("᱐᱑᱒᱓᱔᱕᱖᱗᱘᱙")})


def compute(math):
    """Return (expected_answer, numbers_involved) for a math block."""
    k = math["kind"]
    if k == "count":
        return math["count"], [math["count"]]
    if k == "compare":
        l, r = math["left"], math["right"]
        if l == r:
            ans = "equal"
        elif math["ask"] == "more":
            ans = "left" if l > r else "right"
        else:
            ans = "left" if l < r else "right"
        return ans, [l, r]
    if k == "numeral":
        return math["value"], [math["value"]]
    if k == "add":
        a, b = math["operands"]
        return a + b, [a, b, a + b]
    if k == "subtract":
        a, b = math["operands"]
        return a - b, [a, b, a - b]
    if k == "symbol":
        ops = math.get("operands")
        nums = list(ops) if ops else []
        if ops:
            nums.append(ops[0] + ops[1] if math["symbol"] == "+" else ops[0] - ops[1])
        return math["symbol"], nums
    if k == "choose_operation":
        a, b = math["operands"]
        res = a + b if math["operation"] == "+" else a - b
        return [math["operation"], res], [a, b, res]
    if k == "place_value":
        v = 10 * math["tens"] + math["ones"]
        return v, [v]
    if k == "skip_count":
        v = math["start"] + math["step"] * math["hops"]
        return v, [math["start"], v]
    if k == "repeated_addition":
        v = math["groups"] * math["group_size"]
        return v, [math["groups"], math["group_size"], v]
    if k == "money":
        return None, [math["target"]]  # any valid combination; checked separately
    if k == "pattern":
        u, shown = math["unit"], math["shown"]
        return u[len(shown) % len(u)], []
    return None, []  # non_numeric


def resolve_answer(item, entry):
    """Map an answer (possibly option ids) to machine values using option `value`s."""
    if entry is None:
        return None
    ans = entry["answer"]
    opts = {o["option_id"]: o for o in item.get("options", [])}

    def one(a):
        if isinstance(a, str) and a in opts and "value" in opts[a]:
            return opts[a]["value"]
        return a
    if isinstance(ans, list):
        return [one(a) for a in ans]
    return one(ans)


def text_numbers(s):
    return [int(m) for m in re.findall(r"\d+", s.translate(DIGIT_MAP))]


def validate(content, bp=None):
    rep = Report("numeracy_validator", content.get("content_id"))
    bp = bp or blueprint(content.get("blueprint_id"))
    if bp is None:
        rep.error("NUM_NO_BLUEPRINT", "Blueprint not found; numeracy checks skipped.")
        return rep
    if bp["domain"] != "numeracy":
        rep.note("NUM_SKIPPED", "Not a numeracy blueprint.")
        return rep
    g = bp["grade"]
    c = bp["generation_constraints"]
    cap = GRADE_CAP[g]
    money_cap = c.get("max_amount_rs")
    lo, hi = c.get("number_range", [0, cap])
    keys = {e["item_id"]: e for e in content.get("answer_key", [])}

    for item in content.get("items", []):
        iid = item["item_id"]
        where = f"items[{iid}]"
        math = item.get("math")
        if math is None:
            rep.error("NUM_MISSING_MATH", "Numeracy item has no `math` block; answer cannot be verified.", where)
            continue
        kind = math["kind"]
        expected, nums = compute(math)

        # ---- ranges -----------------------------------------------------------
        is_money = kind == "money"
        for n in nums:
            if n < 0:
                rep.error("NUM_NEGATIVE", f"Negative value {n}.", where)
            limit = money_cap if (is_money and money_cap) else cap
            if n > limit:
                rep.error("NUM_GRADE_CAP", f"Value {n} exceeds Grade {g} cap {limit}.", where)
            if g == 2 and n >= 100 and not is_money:
                rep.error("NUM_THREE_DIGIT", f"3-digit number {n} in Grade 2 (policy X_G2_NUMBER_RANGE).", where)
        if kind in ("count", "numeral", "compare", "place_value", "skip_count", "choose_operation") or (kind in ("add", "subtract") and "number_range" in c):
            for n in nums:
                if not lo <= n <= hi:
                    rep.error("NUM_RANGE", f"Value {n} outside blueprint number_range [{lo}, {hi}].", where)
        if g == 1 and kind == "count" and math["count"] > G1_MAX_COUNT:
            rep.error("NUM_G1_COUNT", f"Grade 1 counting set of {math['count']} (> {G1_MAX_COUNT}, policy X_G1_COUNT_RANGE).", where)
        if kind == "add" or (kind == "choose_operation" and math["operation"] == "+"):
            s = sum(math["operands"])
            max_sum = c.get("max_sum", G1_MAX_SUM if g == 1 else None)
            if max_sum is not None and s > max_sum:
                rep.error("NUM_MAX_SUM", f"Sum {s} exceeds {max_sum}.", where)
        if kind == "subtract" or (kind == "choose_operation" and math["operation"] == "-"):
            a, b = math["operands"]
            max_min = c.get("max_minuend", G1_MAX_MINUEND if g == 1 else None)
            if max_min is not None and a > max_min:
                rep.error("NUM_MAX_MINUEND", f"Minuend {a} exceeds {max_min}.", where)
            if b > a:
                rep.error("NUM_NEGATIVE", f"{a} - {b} is negative.", where)
        if kind == "symbol" and "max_number" in c:
            for n in nums:
                if n > c["max_number"]:
                    rep.error("NUM_MAX_NUMBER", f"Value {n} exceeds max_number {c['max_number']}.", where)
            if "symbols" in c and math["symbol"] not in c["symbols"]:
                rep.error("NUM_SYMBOL", f"Symbol {math['symbol']} not in blueprint symbols.", where)
        if kind == "repeated_addition":
            if "max_total" in c and expected > c["max_total"]:
                rep.error("NUM_MAX_TOTAL", f"Total {expected} exceeds max_total {c['max_total']}.", where)
            gl, gh = c.get("group_size_range", [1, 99])
            if not gl <= math["group_size"] <= gh:
                rep.error("NUM_GROUP_SIZE", f"Group size {math['group_size']} outside [{gl}, {gh}].", where)
        if kind == "skip_count" and "steps" in c and math["step"] not in c["steps"]:
            rep.error("NUM_STEP", f"Step {math['step']} not in blueprint steps {c['steps']}.", where)
        if kind == "money":
            if money_cap and math["target"] > money_cap:
                rep.error("NUM_MONEY_CAP", f"Amount Rs {math['target']} exceeds Rs {money_cap}.", where)
            if math["target"] > 99:
                rep.note("NUM_MONEY_100", f"Money amount Rs {math['target']} allowed by blueprint max_amount_rs (exception to the Grade 2 two-digit rule).", where)
        if kind == "pattern":
            u, shown = math["unit"], math["shown"]
            types = c.get("pattern_types")
            if types and {2: "AB", 3: "ABC"}.get(len(u)) not in types:
                rep.error("NUM_PATTERN_TYPE", f"Pattern unit length {len(u)} not allowed ({types}).", where)
            if len(set(u)) != len(u):
                rep.error("NUM_PATTERN_UNIT", "Pattern unit elements must be distinct.", where)
            if any(shown[i] != u[i % len(u)] for i in range(len(shown))):
                rep.error("NUM_PATTERN_SHOWN", "Shown sequence does not repeat the unit.", where)

        # ---- answer key -------------------------------------------------------
        entry = keys.get(iid)
        if item["item_type"] == "card" and entry is None:
            continue
        if entry is None:
            rep.error("NUM_NO_ANSWER", "No answer_key entry.", where)
            continue
        got = resolve_answer(item, entry)
        if kind == "money":
            combo = got if isinstance(got, list) else None
            avail = set(math["available"])
            if not combo or not all(isinstance(x, int) for x in combo):
                rep.error("NUM_MONEY_ANSWER", "Money answer must be a list of denominations.", where)
            else:
                if sum(combo) != math["target"]:
                    rep.error("NUM_WRONG_ANSWER", f"Denominations {combo} sum to {sum(combo)}, not {math['target']}.", where)
                if not set(combo) <= avail or not set(combo) <= DENOMINATIONS:
                    rep.error("NUM_MONEY_DENOM", f"Answer uses denominations not available: {combo}.", where)
        elif kind == "non_numeric":
            pass
        elif got != expected:
            rep.error("NUM_WRONG_ANSWER", f"Answer key {got!r} but computed {expected!r}.", where)

        # ---- options ----------------------------------------------------------
        opts = item.get("options", [])
        valued = [o for o in opts if "value" in o]
        if valued and kind not in ("money", "non_numeric") and not isinstance(expected, list):
            hits = [o["option_id"] for o in valued if o["value"] == expected]
            if len(hits) != 1:
                rep.error("NUM_OPTIONS", f"{len(hits)} options have the correct value {expected!r}; need exactly 1.", where)
            for o in valued:
                if isinstance(o["value"], (int, float)) and o["value"] > (money_cap if is_money and money_cap else cap):
                    rep.error("NUM_OPTION_RANGE", f"Option value {o['value']} exceeds the Grade {g} cap.", where)

    # ---- numbers written in learner-facing text ----------------------------------
    text_cap = max(cap, money_cap or 0)
    for path, loc in iter_localized(content):
        for lang, s in loc.items():
            for n in text_numbers(s):
                if n > text_cap:
                    rep.error("NUM_TEXT_RANGE", f"Number {n} in {lang} text exceeds Grade {g} cap {text_cap}.", path)
                elif g == 2 and n >= 100 and not money_cap:
                    rep.error("NUM_THREE_DIGIT", f"3-digit number {n} in Grade 2 text.", path)
    return rep


if __name__ == "__main__":
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    r = validate(load_json(sys.argv[1]))
    print(json.dumps(r.to_dict(), ensure_ascii=False, indent=2))
    sys.exit(0 if r.ok else 1)
