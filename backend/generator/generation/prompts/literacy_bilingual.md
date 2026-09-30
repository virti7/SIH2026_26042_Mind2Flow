---
prompt_id: literacy_bilingual
version: 1.0.0
use_when: domain == "literacy" AND language_mode == "bilingual"
blueprints: BP-G1-LIT-001-01, BP-G1-LIT-006-01, BP-G1-LIT-028-01, BP-G2-LIT-001-01, BP-G2-LIT-024-01, BP-G2-LIT-029-01
---

# Bilingual literacy units (meaning-level skills)

These units practise meaning: story comprehension, sequencing, vocabulary meaning, picture-sentence writing.
The same content appears in both Hindi and Santali.

## Rules

1. `languages` = `["hi", "sat"]`. Every learner-facing field has both `hi` and `sat`, and they must say the same thing.
2. Write the Hindi and the Santali each so they read naturally in that language. Do not translate word-for-word; keep names, objects and events identical across both.
3. `generation_method`: `native` if you wrote each language directly; `translated` if one was derived from the other. Be honest - translated Santali gets extra review.
4. Characters and settings should be familiar to children in Jharkhand-region villages and towns (e.g., fields, sal trees, weekly haat, school, family). Use common names from both communities; avoid stereotypes.
5. Put a shared story in `stimulus.passage`. Respect `story_sentences` (count sentences ending in `।`, `.`, `?`, `!` or `᱾`).
6. Questions follow `question_types` when given (e.g., character / sequence / author intent). At Grade 1 use picture options; at Grade 2 short text options.
7. `sequence` items: the answer is the ordered list of option ids.
8. `write` items (Grade 2 picture-sequence sentences): model answers in the answer key must respect `max_words_per_sentence`. Never ask for a paragraph.
9. Vocabulary meaning items: the unfamiliar word appears in a sentence with a picture cue; options are short meanings.

## Item types to use

- worksheet: `multiple_choice`, `sequence`, `write`, `match`
- interactive_activity: `sequence`, `multiple_choice`, `match`
- flashcard: `card` (front: picture + word; back: word in a short example sentence)
