import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// DEBUG-ONLY development fallback for the "second tap" path.
///
/// false (default, and the only acceptable value for the Android prototype):
/// the mic path ALWAYS uses real on-device ASR. When model artifacts are
/// absent the teacher sees "Offline speech recognition is unavailable."
/// — never a fabricated transcript.
///
/// true (local development only): allows a clearly-marked simulated final
/// transcript so the translation/latency UI can be exercised without models.
const bool kDebugSimulatedAsr = false;

/// DEBUG-only simulated transcript. Never used when [kDebugSimulatedAsr]
/// is false. Kept in one place so it can never leak into release logic.
const String kDebugSimulatedTranscript = 'सूरज पूरब से निकलता है।';

/// ASR language configuration. CTC path first; RNNT is not implemented on
/// device. One model is loaded at a time (2 GB RAM target).
enum OfflineAsrLanguage {
  hindi('hi', 'hindi_asr', 'teacher_to_student'),
  santali('sat', 'santali_asr', 'student_to_teacher');

  final String languageId;
  final String assetDir;
  final String direction;

  const OfflineAsrLanguage(this.languageId, this.assetDir, this.direction);

  static OfflineAsrLanguage forDirection(TranslatorDirectionShim direction) =>
      direction == TranslatorDirectionShim.studentToTeacher
          ? OfflineAsrLanguage.santali
          : OfflineAsrLanguage.hindi;
}

/// Minimal direction mirror so the ASR layer does not depend on the bloc.
/// The bloc maps its own direction enum onto this one.
enum TranslatorDirectionShim { teacherToStudent, studentToTeacher }

/// Final ASR outcome. Only FINAL transcripts exist — there is intentionally
/// no partial/interim type: partial hypotheses must never reach translation.
class OfflineAsrResult {
  final String transcript;
  final int inferenceMs;
  final bool modelLoaded;
  final String? errorCode; // MODEL_UNAVAILABLE | MICROPHONE | NO_SPEECH | ASR_FAILURE

  const OfflineAsrResult({
    required this.transcript,
    required this.inferenceMs,
    required this.modelLoaded,
    this.errorCode,
  });

  bool get isOk => errorCode == null && transcript.trim().isNotEmpty;
}

/// Teacher-facing strings for ASR error codes (§32). No stack traces shown.
String offlineAsrUserMessage(String? errorCode) {
  switch (errorCode) {
    case 'MODEL_UNAVAILABLE':
      return 'Offline speech recognition is unavailable.';
    case 'MICROPHONE':
      return 'Microphone access is required.';
    case 'NO_SPEECH':
      return 'No speech detected.';
    case 'ASR_FAILURE':
      return 'Could not recognize the speech. Please try again.';
    default:
      return 'Could not recognize the speech. Please try again.';
  }
}

/// Flutter side of the `maatribhasha/offline_asr` MethodChannel.
///
/// Lifecycle: [ensureLoaded] once per language (reused across utterances),
/// [startRecording] on mic tap, [stopAndTranscribe] on stop tap. Switching
/// direction releases the previous model first (never both loaded).
class OfflineAsrService {
  static const MethodChannel _channel =
      MethodChannel('maatribhasha/offline_asr');

  OfflineAsrLanguage? _loaded;
  OfflineAsrLanguage? _recording;

  OfflineAsrLanguage? get loadedLanguage => _loaded;
  bool get isRecording => _recording != null;

  /// Lazily loads the model for [language]; reuses it when already loaded.
  /// Returns load time in ms, or -1 when the model is unavailable.
  Future<int> ensureLoaded(OfflineAsrLanguage language) async {
    if (_loaded == language) {
      debugPrint('[OfflineASR] direction=${language.direction} '
          'language=${language.languageId} modelLoaded=true (reused)');
      return 0;
    }
    try {
      final res = await _channel.invokeMapMethod<String, dynamic>(
        'initModel',
        {'language': language.languageId},
      );
      final ok = res?['ok'] == true;
      final loadMs = (res?['loadMs'] as num?)?.toInt() ?? -1;
      if (ok) {
        // One model at a time: native side released the previous one.
        _loaded = language;
        debugPrint('[OfflineASR] direction=${language.direction} '
            'language=${language.languageId} modelLoaded=true loadMs=$loadMs');
        return loadMs;
      }
      debugPrint('[OfflineASR] direction=${language.direction} '
          'language=${language.languageId} modelLoaded=false');
      return -1;
    } on MissingPluginException {
      // Non-Android (tests, desktop): no native runtime present.
      debugPrint('[OfflineASR] direction=${language.direction} '
          'language=${language.languageId} modelLoaded=false (no native host)');
      return -1;
    } catch (e) {
      debugPrint('[OfflineASR] ensureLoaded failed: $e');
      return -1;
    }
  }

  Future<void> release() async {
    _recording = null;
    _loaded = null;
    try {
      await _channel.invokeMethod('releaseModel');
    } catch (_) {}
  }

  /// Releases the currently loaded model when switching direction, so both
  /// models are never resident simultaneously on the 2 GB device.
  Future<void> releaseIfLoaded(OfflineAsrLanguage language) async {
    if (_loaded == language) return;
    if (_loaded != null) {
      await release();
      debugPrint('[OfflineASR] released previous model for direction switch');
    }
  }

  Future<String?> startRecording(OfflineAsrLanguage language) async {
    try {
      final res = await _channel.invokeMapMethod<String, dynamic>(
        'startRecording',
        {'language': language.languageId},
      );
      if (res?['ok'] == true) {
        _recording = language;
        debugPrint('[OfflineASR] direction=${language.direction} '
            'language=${language.languageId} state=LISTENING');
        return null;
      }
      return res?['error']?.toString() ?? 'MICROPHONE';
    } on MissingPluginException {
      return 'MODEL_UNAVAILABLE';
    } catch (e) {
      debugPrint('[OfflineASR] startRecording failed: $e');
      return 'MICROPHONE';
    }
  }

  /// Stops the mic and runs inference. Returns the FINAL transcript only.
  Future<OfflineAsrResult> stopAndTranscribe() async {
    final lang = _recording;
    _recording = null;
    if (lang == null) {
      return const OfflineAsrResult(
          transcript: '', inferenceMs: 0, modelLoaded: false,
          errorCode: 'NO_SPEECH');
    }
    try {
      final res = await _channel.invokeMapMethod<String, dynamic>(
          'stopAndTranscribe', {});
      final error = res?['error']?.toString();
      if (error != null) {
        debugPrint('[OfflineASR] direction=${lang.direction} '
            'language=${lang.languageId} error=$error');
        return OfflineAsrResult(
            transcript: '', inferenceMs: 0,
            modelLoaded: _loaded == lang, errorCode: error);
      }
      final text = (res?['transcript'] ?? '').toString();
      final ms = (res?['inferenceMs'] as num?)?.toInt() ?? 0;
      debugPrint('[OfflineASR] direction=${lang.direction} '
          'language=${lang.languageId} inferenceMs=$ms transcript=$text');
      return OfflineAsrResult(
          transcript: text, inferenceMs: ms, modelLoaded: true);
    } on MissingPluginException {
      return const OfflineAsrResult(
          transcript: '', inferenceMs: 0, modelLoaded: false,
          errorCode: 'MODEL_UNAVAILABLE');
    } catch (e) {
      debugPrint('[OfflineASR] stopAndTranscribe failed: $e');
      return const OfflineAsrResult(
          transcript: '', inferenceMs: 0, modelLoaded: false,
          errorCode: 'ASR_FAILURE');
    }
  }
}

/// In-memory fake for widget/unit tests (records calls, returns scripted
/// FINAL results — never partials).
class FakeOfflineAsrService extends OfflineAsrService {
  final Map<OfflineAsrLanguage, bool> available;
  OfflineAsrResult? nextResult;
  String? nextStartError;
  final List<String> callLog = [];

  FakeOfflineAsrService({
    this.available = const {
      OfflineAsrLanguage.hindi: true,
      OfflineAsrLanguage.santali: true,
    },
  });

  @override
  Future<int> ensureLoaded(OfflineAsrLanguage language) async {
    callLog.add('ensureLoaded:${language.languageId}');
    return available[language] == true ? 120 : -1;
  }

  @override
  Future<String?> startRecording(OfflineAsrLanguage language) async {
    callLog.add('startRecording:${language.languageId}');
    return nextStartError;
  }

  @override
  Future<OfflineAsrResult> stopAndTranscribe() async {
    callLog.add('stopAndTranscribe');
    return nextResult ??
        const OfflineAsrResult(transcript: '', inferenceMs: 0,
            modelLoaded: true, errorCode: 'NO_SPEECH');
  }
}
