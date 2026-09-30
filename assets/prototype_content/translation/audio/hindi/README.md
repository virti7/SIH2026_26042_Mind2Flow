# Hindi classroom audio (Student → Teacher playback)

Local bundled WAV clips played after a successful Santali→Hindi phrase
match. Zero network use.

## Required clip (prototype phrase `sun_rises_east`)

- `hindi_sun_rises_east.wav` — Hindi speaker says: सूरज पूरब से निकलता है।
  (16 kHz mono PCM WAV preferred; any `audioplayers`-decodable WAV works.)

Referenced by `santali_phrase_bank.json` → `hindiAudio`:
`assets/prototype_content/translation/audio/hindi/hindi_sun_rises_east.wav`

Until the real recording lands here, Student → Teacher shows the Hindi +
English texts with "Could not play translated audio." — the texts are never
blocked by a missing clip, and no unrelated audio is ever substituted.

Record or convert (originals stay untouched):

```bash
ffmpeg -i hindi_original.wav -ar 16000 -ac 1 -c:a pcm_s16le hindi_sun_rises_east.wav
```
