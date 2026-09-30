"""MaatriBhasha Classroom Translator - fully local speech-to-speech.

Pipelines (all on 127.0.0.1:7871, no external API):
  TEACHER: Hindi speech   -> ONNX INT8 IndicConformer hi ASR
          -> IndicTrans2 hin_Deva -> sat_Olck -> Indic Parler-TTS (Arjun) -> WAV
  STUDENT: Santali speech -> ONNX INT8 IndicConformer sat ASR
          -> IndicTrans2 sat_Olck -> hin_Deva -> Indic Parler-TTS (Rohit) -> WAV

Models are lazy-loaded; model-load time is reported separately from inference
latency. Both Santali and Hindi are synthesized natively by Indic Parler-TTS,
so there is no cross-language voice fallback.
"""
