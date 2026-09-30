# MaatriBhasha — Offline Prototype Content

Deterministic, fully OFFLINE prototype content for presentations.
No FastAPI, Supabase, Sarvam, internet, or remote server is required
to VIEW files placed here. They are bundled into the APK via
`pubspec.yaml` (`assets/prototype_content/`) and read with
`PrototypeLocalContentDataSource` (no network calls).

## WHERE TO PUT WHAT

### Worksheets — final bilingual PDFs
`assets/prototype_content/worksheets/pdf/`
Example: `class2_math_numbers.pdf`
→ Put the final bilingual worksheet PDF here.

### Worksheet manifests — metadata describing each worksheet
`assets/prototype_content/worksheets/manifests/`
Example: `class2_math_numbers.json`
→ One JSON per worksheet (see "Worksheet manifest format" below).
→ The `asset` field points at the PDF above.

### Flashcard images — actual educational images
`assets/prototype_content/flashcards/images/`
Example: `santali_mango_tree.png`
→ PNG/JPG/WebP used by flashcard sets.

### Flashcard set definitions / JSON payloads
`assets/prototype_content/flashcards/sets/`
Example: `class2_santali_animals.json`
→ Card list (Hindi text, Santali text, image reference).

### Flashcard set manifests — metadata for each set
`assets/prototype_content/flashcards/manifests/`
Example: `class2_santali_animals.manifest.json`
→ Points at the set JSON + cover image.

### Assessment question images
`assets/prototype_content/assessments/images/`
Example: `class2_math_q3_beads.png`
→ Images referenced by assessment questions.

### Assessment manifests — question/set metadata
`assets/prototype_content/assessments/manifests/`
Example: `class2_math_numbers_assessment.json`
→ Questions, options, correct answers, optional image refs.

### Shared images — cross-resource images
`assets/prototype_content/shared/images/`
Example: `nipun_banner.png`

### Shared icons
`assets/prototype_content/shared/icons/`
Example: `mic_classroom.png`

### Shared fonts — Hindi/Santali rendering
`assets/prototype_content/shared/fonts/`
Example: `NotoSansDevanagari-Regular.ttf`
→ Register in `pubspec.yaml` `fonts:` section when you add one.

## Manifest formats (schemas, not content)

Dart schema: `lib/core/content/prototype_manifests.dart`
Loader: `lib/core/content/prototype_local_content_data_source.dart`
(`getPrototypeWorksheets()`, `getPrototypeFlashcardSets()`,
`getPrototypeAssessments()` — asset-bundle only, zero network.)

### Worksheet manifest format
```json
{
  "id": "class2_math_numbers",
  "title": "Numbers up to 100",
  "className": "Class 2",
  "subject": "Mathematics",
  "topic": "Numbers up to 100",
  "languages": ["Hindi", "Santali"],
  "type": "bilingual_worksheet",
  "asset": "assets/prototype_content/worksheets/pdf/class2_math_numbers.pdf"
}
```

### Flashcard set manifest format
```json
{
  "setId": "class2_santali_animals",
  "title": "Animals",
  "className": "Class 2",
  "subject": "Hindi",
  "topic": "Animals",
  "languagePair": ["Hindi", "Santali"],
  "cardCount": 12,
  "coverImage": "assets/prototype_content/flashcards/images/santali_mango_tree.png",
  "setFile": "assets/prototype_content/flashcards/sets/class2_santali_animals.json"
}
```

### Assessment manifest format
```json
{
  "assessmentId": "class2_math_numbers_check",
  "className": "Class 2",
  "subject": "Mathematics",
  "topic": "Numbers up to 100",
  "language": "Hindi + Santali",
  "questions": [
    {
      "number": 1,
      "promptHindi": "...",
      "promptTribal": "...",
      "type": "mcq",
      "image": "assets/prototype_content/assessments/images/class2_math_q3_beads.png",
      "options": ["...", "..."],
      "correctIndex": 0
    }
  ]
}
```

## Notes
- Catalog files here are SHARED curriculum content.
- Teacher download records / saved state / progress stay
  account-scoped (existing `downloaded_resources` +
  `SavedMaterials` ownership) — see
  `PrototypeContentRepository` docs.
- Do NOT commit service-role keys, JWT secrets, or server URLs here.
- After adding files, run `flutter pub get` (asset re-index) and
  rebuild — no server restart needed.
