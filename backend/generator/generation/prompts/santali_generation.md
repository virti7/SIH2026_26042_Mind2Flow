---
prompt_id: santali_generation
version: 1.0.0
use_when: "sat" is in the output languages (appended after the type-specific prompt)
status: script choice provisional - to be confirmed by a Santali-literate reviewer
---

# Santali (`sat`) rules

1. **Script.** Write Santali in **Ol Chiki** (`scripts.sat` = `"Olck"`) unless the call explicitly overrides it. The script is not yet confirmed for this prototype, so the reviewer may change it; do not mix scripts inside one string.
2. **No Hindi or English inside Santali strings.** Do not fall back to Devanagari or Latin letters in a `sat` string. Digits 0-9 are allowed for numbers; Ol Chiki digits are also acceptable if used consistently.
3. **Punctuation.** Use the Ol Chiki full stop `᱾` (mucaad) at sentence ends; `?` is acceptable for questions.
4. **Vocabulary.** Use everyday Santali words spoken by children. If you are unsure of a word, choose a simpler word you are sure of. If you are still unsure, say so in `generation_notes`, naming the item ids affected. Do not invent words.
5. **Not a copy of the Hindi.** In bilingual units the Santali must mean the same as the Hindi but read as natural Santali. In parallel units it must be written independently, using Santali sounds and words.
6. **Names and culture.** Santali names and settings are welcome (e.g., village haat, sal forest, Sohrai or Baha festivals), presented respectfully and not as stereotypes.
7. **Audio.** For audio assets with `language: "sat"`, `spoken_text.sat` is exactly what the voice artist will read.
8. **Review.** Always include `santali_content` in `review_gates`. Nothing in Santali is publishable before a Santali-literate reviewer approves it.
