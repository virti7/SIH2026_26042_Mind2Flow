# test_audio — real 16 kHz mono PCM WAV recordings go here (not fakes)

Required files (create with a microphone + ffmpeg, see ../asr_test/README_ASR_TEST.md):

- `hindi_sun_rises_east_16khz.wav` — Hindi speaker says: सूरज पूरब से निकलता है।
- `santali_sun_rises_east_16khz.wav` — Santali speaker says the corresponding sentence.

Format contract: WAV, 16000 Hz, 1 channel, PCM (`pcm_s16le`).

Examples:

```bash
ffmpeg -i hindi_original.wav -ar 16000 -ac 1 -c:a pcm_s16le hindi_sun_rises_east_16khz.wav
ffmpeg -i santali_original.wav -ar 16000 -ac 1 -c:a pcm_s16le santali_sun_rises_east_16khz.wav
```

Never overwrite originals — converted copies only.
