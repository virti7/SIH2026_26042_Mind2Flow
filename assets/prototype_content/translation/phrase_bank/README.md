# Master Offline Santali Phrase Bank

Single source of truth for the Quick Phrase Bank:

- Master JSON: `assets/prototype_content/translation/phrase_bank/santali_phrase_bank.json`
- Audio folder: `assets/prototype_content/translation/audio/santali/`

Fully offline. No Sarvam, no FastAPI, no Supabase, no remote audio, no network.

## How to add a new phrase (only 2 steps, no Dart changes)

STEP 1 — Put the audio file inside:

```
assets/prototype_content/translation/audio/santali/
```

Keep the filename simple, e.g. `new_phrase.wav`.

STEP 2 — Add ONE record to `santali_phrase_bank.json`:

```json
{
  "id": "new_phrase",
  "category": "Instructions",
  "hindi": "Hindi sentence",
  "santaliOlChiki": "Verified Ol Chiki text",
  "santaliRoman": "Verified Roman text",
  "audio": "assets/prototype_content/translation/audio/santali/new_phrase.wav",
  "tags": ["instruction"]
}
```

STEP 3 — Rebuild (`flutter pub get` / rebuild if required).
The phrase appears automatically in Quick Phrase Bank.

## Rules

1. Edit `santali_phrase_bank.json` to add/edit phrases.
2. Put corresponding audio files in `audio/santali/`.
3. Keep audio filenames simple (`phrase_001.wav` or `open_book.wav`).
4. The JSON `audio` path must EXACTLY match the file (including extension).
5. Use UTF-8 JSON.
6. `santaliOlChiki` must be the verified Ol Chiki text, copied exactly.
   Never transliterate, convert, or normalize it.
7. `santaliRoman` must be the verified Roman representation.
   Never generate it automatically.
8. Do NOT add remote URLs (`http`, Firebase, Supabase, CDN). Local assets only.
9. Do NOT duplicate a phrase `id`. Every `id` must be unique.
10. Do NOT use fake translations. If verified Santali text is not available
    yet, leave the field as `""` — the app shows "Not provided" and never
    calls an API to fill it.

## Complete example record

```json
{
  "id": "open_book_page_5",
  "category": "Instructions",
  "hindi": "अपनी पुस्तक पृष्ठ संख्या 5 पर खोलें।",
  "santaliOlChiki": "PASTE_VERIFIED_OL_CHIKI_TEXT",
  "santaliRoman": "PASTE_VERIFIED_ROMAN_TEXT",
  "audio": "assets/prototype_content/translation/audio/santali/open_book_page_5.wav",
  "tags": ["book", "page", "instruction", "classroom"]
}
```

## Architecture

```
santali_phrase_bank.json + audio/santali/
        ↓
SantaliPhraseBankRepository (lib/core/content/santali_phrase_bank.dart)
        ↓
Quick Phrase Bank screen
        ↓
Speaker / Repeat / Use in Live Lesson
```
