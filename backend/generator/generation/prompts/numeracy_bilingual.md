---
prompt_id: numeracy_bilingual
version: 1.0.0
use_when: domain == "numeracy" (all numeracy blueprints are bilingual)
---

# Bilingual numeracy units

The mathematics is identical in both languages; only the words change.

## Rules

1. `languages` = `["hi", "sat"]`; both texts in every learner-facing field.
2. **Every item must include a `math` block** that states the quantities machine-readably. The validator recomputes every answer from it and rejects mismatches.

| Task | `math` block | Answer in `answer_key` |
|---|---|---|
| count objects | `{"kind":"count","count":7}` | `7` or the option id whose `value` is 7 |
| compare two groups | `{"kind":"compare","left":8,"right":5,"ask":"more"}` | `"left"`, `"right"` or `"equal"` (or option id with that `value`) |
| numeral card | `{"kind":"numeral","value":12}` | optional; back of card |
| add / subtract | `{"kind":"add","operands":[4,7]}` | `11` |
| word problem | `{"kind":"subtract","operands":[25,8],"word_problem":true}` | `17` |
| decide + or - | `{"kind":"choose_operation","operands":[12,5],"operation":"-"}` | `["-", 7]` |
| symbol card | `{"kind":"symbol","symbol":"+","operands":[2,3]}` | `"+"` |
| tens and ones | `{"kind":"place_value","tens":4,"ones":6}` | `46` |
| skip counting | `{"kind":"skip_count","start":0,"step":2,"hops":5}` | `10` (the landing number) |
| equal groups | `{"kind":"repeated_addition","groups":3,"group_size":4}` | `12` |
| money | `{"kind":"money","target":15,"available":[10,5,2,1]}` | list of notes/coins that sum to the target, e.g. `[10,5]` |
| pattern | `{"kind":"pattern","unit":["red","blue"],"shown":["red","blue","red"]}` | `"blue"` (next element) |
| shapes / positions / sorting | `{"kind":"non_numeric","topic":"shape"}` | option id or ordered/grouped list |

3. **Ranges (provisional prototype choices, not official policy):**
   - Grade 1: no number above 20 anywhere; counting sets at most 20; sums at most 18; subtract only from numbers up to 9; money up to Rs 20.
   - Grade 2: numbers 0-99 only; no 3-digit numbers except money amounts up to Rs 100 where the blueprint allows it; no multiplication tables - equal groups written as repeated addition, total at most `max_total`.
   - Always also respect the blueprint's own `number_range`, `max_sum`, `max_minuend`, `max_number`, `max_total`, `group_size_range`, `steps`, `max_amount_rs`.
4. Results are never negative. Choose numbers so each answer is a whole number inside the range.
5. Numbers in text may be written with Indo-Arabic digits (0-9). They must match the `math` block exactly.
6. Contexts: real objects children know (mangoes, leaves, bangles, marbles, chapatis, hens, school bags). Keep word problems to 1-2 short sentences.
7. Currency: use only real Indian denominations: coins 1, 2, 5, 10, 20 and notes 10, 20, 50, 100.
8. Images: describe the exact number of objects to draw in `description_en` (e.g., "7 mangoes in a basket, clearly countable, no overlap").
9. Multiple-choice options carry numeric `value`s; exactly one option equals the computed answer.
