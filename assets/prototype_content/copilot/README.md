# Offline Teacher Co-Pilot — content guide

Deterministic, rule-based, fully offline. No LLM, no network, no FastAPI /
Supabase / Sarvam. Edit the JSON files below to add questions, keywords,
answers and navigation rules — no Dart changes needed.

## Files

| File | Purpose |
| --- | --- |
| `teacher_copilot_knowledge.json` | Intent items: `keywords` + `romanHindiKeywords` + bilingual answers + `route`. |
| `navigation_intents.json` | Intent → existing `AppRoutes` route registry. Every route MUST exist in `lib/app/router/route_names.dart`. |
| `quick_questions.json` | Chips shown in the chat panel. `query` goes through the SAME rule engine. |

## Add a new question

1. Find the matching item in `teacher_copilot_knowledge.json`.
2. Append the teacher's phrasing (Roman Hindi as typed) to `romanHindiKeywords`,
   and the normalized English/Hindi form to `keywords`.
3. Keep `answerHindi` / `answerEnglish` pre-authored — never generated.
4. `route` must be a real route from `navigation_intents.json`.

## Add a new navigation target

1. Confirm the route exists in `lib/app/router/route_names.dart`.
2. Add the intent entry to `navigation_intents.json`.
3. Add a knowledge item pointing at that route.

## Teaching answers (TEACHER_GUIDANCE)

The `teacher_guidance` item has empty answers on purpose: the Co-Pilot
reuses `assets/prototype_content/teacher_guidance/teacher_guidance.json`
via `PrototypeTeacherGuidanceRepository`. Add teaching content THERE,
and only add Roman-Hindi trigger phrases HERE.

## Engine

`lib/core/copilot/copilot_engine.dart` — normalization, Roman-Hindi variant
dictionary, deterministic scoring (exact +5 / keyword +2 / roman +2 /
topic +3 / subject +2 / continuity +2, threshold 4.0), follow-up handling
(`haan kholo` reuses last route), clarification on near-ties, fixed
unknown fallback. Pure Dart, zero network imports.
