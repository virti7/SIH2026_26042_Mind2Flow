# Santali Prototype Audio — PUT FILES HERE

Put verified Santali classroom audio clips in THIS folder:

`assets/prototype_content/translation/audio/santali/`

## Naming convention

- lowercase snake_case, no spaces or special characters
- stable filename = asset key used in the manifest
- formats: `.mp3` (preferred for APK size) or `.wav`

Example:

`open_math_book.mp3`

maps to (in `../phrases/santali_demo_phrases.json`):

```json
{
  "id": "open_math_book",
  "hindi": "अपनी गणित की किताब खोलो।",
  "santali": "VERIFIED SANTALI TEXT",
  "audio": "assets/prototype_content/translation/audio/santali/open_math_book.mp3",
  "topic": "Mathematics",
  "context": "Classroom instruction"
}
```

## Recording guidance (classroom-ready)

- Voice recording with clean speech, mono is fine.
- Reasonable bitrate — clear on a classroom speaker.
- Short clips: one Santali sentence per file.
- Audio must contain ONLY the Santali spoken sentence.
- Trim leading silence — it directly adds to perceived latency.
- No long trailing silence.

## After adding files

1. Fill the matching `"santali"` text in `santali_demo_phrases.json`.
2. Run `flutter pub get` and rebuild the APK.
3. No server, internet, Sarvam, FastAPI, or Supabase needed for these
   phrases — Hindi speech → local lookup → this audio file plays.
