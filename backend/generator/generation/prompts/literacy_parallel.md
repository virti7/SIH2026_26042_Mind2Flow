---
prompt_id: literacy_parallel
version: 1.0.0
use_when: domain == "literacy" AND language_mode == "parallel_monolingual"
blueprints: BP-G1-LIT-011-01, BP-G1-LIT-015-01, BP-G1-LIT-016-01, BP-G1-LIT-020-01, BP-G1-LIT-021-01, BP-G1-LIT-010-01, BP-G1-LIT-031-01, BP-G2-LIT-009-01, BP-G2-LIT-014-01, BP-G2-LIT-026-01, BP-G2-LIT-013-01
extra_placeholder: TARGET_LANGUAGE (hi or sat)
---

# Parallel monolingual literacy units (script- and sound-specific skills)

These units teach letters, sounds, blending, rhyme, decoding, sight words, punctuation and dictation.
They depend on one language's sounds and script, so each language gets its **own independent unit**.

**Target language for this call: `{{TARGET_LANGUAGE}}`**

## Rules

1. `languages` = `["{{TARGET_LANGUAGE}}"]`. Every learner-facing field contains only `{{TARGET_LANGUAGE}}`.
2. `generation_method` = `native`. **Never translate** from the other language. Choose words, rhymes and letters that exist and are common in `{{TARGET_LANGUAGE}}` itself. The Hindi and Santali units for the same blueprint are expected to differ.
3. `content_id` ends in `-{{TARGET_LANGUAGE}}-v1`.
4. Use only very common, concrete, picturable words a 6-7-year-old already knows orally.
5. Blueprint limits matter here:
   - `word_length_aksharas` / `words_per_sentence`: count syllable units (aksharas for Devanagari) or words exactly.
   - `script_unit`: basic letters only for "basic akshara"; conjuncts only for "conjunct akshara".
   - `only_known_aksharas`: words should use only common basic letters without rare conjuncts.
   - `timed: false`: no timers, no speed targets, no words-per-minute.
6. Audio items (`listen_and_choose`, `listen_and_write`, rhyme or blend tasks): each item needs an audio asset with the exact `spoken_text`. For blending, `spoken_text` gives the separated sounds (e.g., `क - म - ल`), and the answer is the whole word.
7. Rhyme and same-first-sound items: exactly one option shares the target rhyme or first sound; distractors must clearly not.
8. Punctuation items (Grade 2): use only full stop / `।` and question mark, as named in `marks`.
9. For Hindi, the Devanagari full stop is `।` (purna viram).

## Item types to use

- flashcard: `card` (front: letter or word + picture reference; back: the sound or an example word)
- worksheet: `match`, `multiple_choice`, `fill_blank`
- interactive_activity: `listen_and_choose`, `multiple_choice`
- audio_activity: `listen_and_choose`, `listen_and_write`
