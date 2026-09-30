import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:maatribhasha/core/asr/offline_asr_service.dart';
import 'package:maatribhasha/core/content/santali_audio_player.dart';
import 'package:maatribhasha/core/content/santali_phrase_bank.dart';
import 'package:maatribhasha/core/enums/app_enums.dart';
import 'package:maatribhasha/core/models/app_models.dart';
import 'package:maatribhasha/core/repositories/app_repositories.dart';
import 'package:maatribhasha/core/translation/bidirectional_phrase_matcher.dart';
import 'package:maatribhasha/features/translation/presentation/bloc/translation_bloc.dart';

/// Bidirectional OFFLINE ASR tests (§41): real flow with fakes at the
/// native boundary (FakeOfflineAsrService returns scripted FINAL results —
/// never partials), seeded phrase bank, throwing remote repository (any
/// network/remote call fails the test).
///
/// NOTE: a few tests await the genuine 1500–2150 ms presentation delay to
/// prove the actual wait equals the generated value (no faked latency).

const _santaliWav =
    'assets/prototype_content/translation/audio/santali/santali_sun_rises_east.wav';
const _hindiWav =
    'assets/prototype_content/translation/audio/hindi/hindi_sun_rises_east.wav';
const _olChikiSun = 'ᱪᱟᱱᱫᱚ ᱫᱚ ᱯᱩᱨᱩᱵᱽ ᱠᱷᱚᱱ ᱨᱟᱠᱟᱵᱽ ᱮᱫᱟᱭ';
const _hindiSun = 'सूरज पूरब से निकलता है।';

const _seedSun = SantaliPhrase(
  id: 'sun_rises_east',
  category: 'Literacy',
  hindi: _hindiSun,
  english: 'The sun rises in the east.',
  santaliOlChiki: _olChikiSun,
  santaliRoman: 'Cando do purub khon rakab edai',
  audio: _santaliWav,
  hindiAudio: _hindiWav,
  hindiVariants: ['सूरज पूर्व से निकलता है'],
  santaliVariants: ['cando do purub khon rakab edai'],
);

const _seedListen = SantaliPhrase(
  id: 'listen_carefully',
  category: 'Instructions',
  hindi: 'सब बच्चे ध्यान से सुनो।',
  english: 'Listen carefully, children.',
  santaliOlChiki: 'ᱡᱚᱛᱚ ᱜᱤᱫᱽᱨᱟᱹ ᱠᱚ, ᱢᱚᱱ ᱠᱟᱛᱮ ᱟᱸᱡᱚᱢ ᱢᱮ',
  santaliRoman: 'Joto gidra ko, mon kathe anjom me.',
  audio: 'assets/prototype_content/translation/audio/santali/santali_listen_carefully_children.wav',
);

/// Remote pipeline stand-in: throws on ANY call (offline proof).
class ThrowingTranslationRepository implements TranslationRepository {
  @override
  Future<TranslationMessage> translateUtterance({
    required String text,
    required TribalLanguage targetLanguage,
    required bool isTeacher,
    Map<String, String>? contextMeta,
  }) async =>
      throw StateError('remote pipeline must not be called offline');

  @override
  Future<List<QuickPhrase>> getQuickPhrases({String? category}) async => [];

  @override
  Future<void> submitFeedback({
    required String original,
    required String translated,
    required String issueType,
    String? comment,
  }) async {}
}

SantaliPhraseBankRepository _bank() => SantaliPhraseBankRepository(
      seedPhrases: const [_seedSun, _seedListen],
      availableAssetsOverride: const {_santaliWav, _hindiWav},
    );

TranslationBloc _bloc({
  FakeOfflineAsrService? asr,
  NoopSantaliAudioPlayer? player,
}) =>
    TranslationBloc(
      translationRepository: ThrowingTranslationRepository(),
      santaliAudioPlayer: player ?? NoopSantaliAudioPlayer(),
      asrService: asr ?? FakeOfflineAsrService(),
      phraseBank: _bank(),
      random: Random(7),
    );

Future<TranslationSessionActive> _init(TranslationBloc bloc) async {
  bloc.add(InitTranslationSession());
  final s = await bloc.stream
      .firstWhere((e) => e is TranslationSessionActive);
  return s as TranslationSessionActive;
}

Future<TranslationSessionActive> _waitHistory(
  TranslationBloc bloc,
  String phraseId,
) =>
    _waitFor(bloc,
        (s) => s.conversationHistory.any((m) => m.id.startsWith('asr_$phraseId')));

/// Lets an in-flight handler finish its final emits before bloc.close().
Future<void> _settle() =>
    Future<void>.delayed(const Duration(milliseconds: 300));

Future<TranslationSessionActive> _waitFor(
  TranslationBloc bloc,
  bool Function(TranslationSessionActive) pred,
) async {
  final s = await bloc.stream
      .firstWhere((e) => e is TranslationSessionActive && pred(e));
  return s as TranslationSessionActive;
}

void main() {
  group('1-2. ASR model configuration', () {
    test('Hindi model config', () {
      expect(OfflineAsrLanguage.hindi.languageId, 'hi');
      expect(OfflineAsrLanguage.hindi.assetDir, 'hindi_asr');
      expect(OfflineAsrLanguage.hindi.direction, 'teacher_to_student');
    });

    test('Santali model config', () {
      expect(OfflineAsrLanguage.santali.languageId, 'sat');
      expect(OfflineAsrLanguage.santali.assetDir, 'santali_asr');
      expect(OfflineAsrLanguage.santali.direction, 'student_to_teacher');
    });

    test('direction maps to the correct model', () {
      expect(
          OfflineAsrLanguage.forDirection(
              TranslatorDirectionShim.teacherToStudent),
          OfflineAsrLanguage.hindi);
      expect(
          OfflineAsrLanguage.forDirection(
              TranslatorDirectionShim.studentToTeacher),
          OfflineAsrLanguage.santali);
    });
  });

  group('3-4. Model selection + load-once', () {
    test('teacher direction loads the Hindi model', () async {
      final asr = FakeOfflineAsrService();
      final bloc = _bloc(asr: asr);
      await _init(bloc);
      bloc.add(ToggleTeacherMicRecord());
      await _waitFor(bloc, (s) => s.isRecording);
      expect(asr.callLog, contains('ensureLoaded:hi'));
      await bloc.close();
    });

    test('student direction loads the Santali model', () async {
      final asr = FakeOfflineAsrService();
      final bloc = _bloc(asr: asr);
      await _init(bloc);
      bloc.add(const SwitchTranslatorDirection(
          TranslatorDirection.studentToTeacher));
      await _waitFor(
          bloc, (s) => s.direction == TranslatorDirection.studentToTeacher);
      bloc.add(ToggleTeacherMicRecord());
      await _waitFor(bloc, (s) => s.isRecording);
      expect(asr.callLog, contains('ensureLoaded:sat'));
      expect(asr.callLog, isNot(contains('ensureLoaded:hi')));
      await bloc.close();
    });

    test('loaded model flag persists across utterances', () async {
      final asr = FakeOfflineAsrService();
      final bloc = _bloc(asr: asr);
      await _init(bloc);
      asr.nextResult = const OfflineAsrResult(
          transcript: _hindiSun, inferenceMs: 400, modelLoaded: true);
      bloc.add(ToggleTeacherMicRecord());
      await _waitFor(bloc, (s) => s.isRecording);
      bloc.add(ToggleTeacherMicRecord());
      await _waitFor(
          bloc, (s) => s.currentTranslationResult.isNotEmpty);
      await _waitHistory(bloc, 'sun_rises_east');
      final loaded = (bloc.state as TranslationSessionActive).asrModelLoaded;
      expect(loaded, isTrue);
      await bloc.close();
    });
  });

  group('5-6. Final-only triggering', () {
    test('FINAL ASR triggers translation output', () async {
      final bloc = _bloc();
      await _init(bloc);
      bloc.add(const AsrFinalTranscript(
          text: _hindiSun, inferenceMs: 400, languageId: 'hi'));
      final out = await _waitFor(
          bloc, (s) => s.currentTranslationResult.isNotEmpty);
      expect(out.localPhraseId, 'sun_rises_east');
      await _waitHistory(bloc, 'sun_rises_east');
      await bloc.close();
    });

    test('LISTENING never shows translation (no partial path)', () async {
      final bloc = _bloc();
      await _init(bloc);
      bloc.add(ToggleTeacherMicRecord());
      final listening = await _waitFor(bloc, (s) => s.isRecording);
      expect(listening.currentTranslationResult, isEmpty);
      expect(listening.currentTranslationSecondary, isEmpty);
      await bloc.close();
    });

    test('second tap uses the REAL transcribed text, not a constant',
        () async {
      final asr = FakeOfflineAsrService();
      final bloc = _bloc(asr: asr);
      await _init(bloc);
      // Script an UNKNOWN sentence: a hardcoded prototype string could never
      // produce the "unavailable" branch, the real transcript does.
      asr.nextResult = const OfflineAsrResult(
          transcript: 'अज्ञात परीक्षण वाक्यांश',
          inferenceMs: 300,
          modelLoaded: true);
      bloc.add(ToggleTeacherMicRecord());
      await _waitFor(bloc, (s) => s.isRecording);
      bloc.add(ToggleTeacherMicRecord());
      final done = await _waitFor(
          bloc, (s) => !s.isRecording && !s.isProcessing);
      expect(done.asrTranscript, 'अज्ञात परीक्षण वाक्यांश');
      expect(done.translationError,
          'Translation unavailable for this prototype phrase.');
      await bloc.close();
    });
  });

  group('7-10. Phrase matching + audio mapping', () {
    test('Hindi exact match (teacher -> student)', () async {
      final m = BidirectionalPhraseMatcher();
      final hit = m.matchHindi(_hindiSun, const [_seedSun, _seedListen]);
      expect(hit?.phrase.id, 'sun_rises_east');
      expect(hit?.priority, 1);
    });

    test('Hindi variant match', () async {
      final m = BidirectionalPhraseMatcher();
      final hit =
          m.matchHindi('सूरज पूर्व से निकलता है।', const [_seedSun]);
      expect(hit?.phrase.id, 'sun_rises_east');
      expect(hit?.priority, 2);
    });

    test('Santali Ol Chiki exact match (student -> teacher)', () async {
      final m = BidirectionalPhraseMatcher();
      final hit = m.matchSantali(_olChikiSun, const [_seedSun, _seedListen]);
      expect(hit?.phrase.id, 'sun_rises_east');
      expect(hit?.priority, 1);
    });

    test('Santali Roman variant match', () async {
      final m = BidirectionalPhraseMatcher();
      final hit = m.matchSantali(
          'CANDO DO PURUB KHON RAKAB EDAI', const [_seedSun]);
      expect(hit?.phrase.id, 'sun_rises_east');
    });

    test('Hindi normalization: spaces + punctuation', () {
      expect(BidirectionalPhraseMatcher.normalizeHindi('  सूरज   पूरब से निकलता है। '),
          'सूरज पूरब से निकलता है');
    });

    test('Santali normalization preserves Ol Chiki, strips spaces', () {
      expect(BidirectionalPhraseMatcher.normalizeSantali('  $_olChikiSun  '),
          _olChikiSun);
    });

    test('teacher -> student plays the Santali clip', () async {
      final player = NoopSantaliAudioPlayer();
      final bloc = _bloc(player: player);
      await _init(bloc);
      bloc.add(const AsrFinalTranscript(
          text: _hindiSun, inferenceMs: 400, languageId: 'hi'));
      await _waitFor(
          bloc, (s) => s.currentTranslationResult.isNotEmpty);
      await _waitHistory(bloc, 'sun_rises_east');
      for (var i = 0; i < 100 && player.playLog.isEmpty; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
      expect(player.playLog, contains(_santaliWav));
      await bloc.close();
    });

    test('student -> teacher shows Hindi + English, plays Hindi clip',
        () async {
      final player = NoopSantaliAudioPlayer();
      final bloc = _bloc(player: player);
      await _init(bloc);
      bloc.add(const SwitchTranslatorDirection(
          TranslatorDirection.studentToTeacher));
      await _waitFor(
          bloc, (s) => s.direction == TranslatorDirection.studentToTeacher);
      bloc.add(const AsrFinalTranscript(
          text: _olChikiSun, inferenceMs: 450, languageId: 'sat'));
      final out = await _waitFor(
          bloc, (s) => s.currentTranslationResult.isNotEmpty);
      expect(out.currentTranslationResult, _hindiSun);
      expect(out.currentTranslationSecondary, 'The sun rises in the east.');
      await _waitHistory(bloc, 'sun_rises_east');
      for (var i = 0; i < 100 && player.playLog.isEmpty; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
      expect(player.playLog, contains(_hindiWav));
      await bloc.close();
    });
  });

  group('9. Unknown phrase', () {
    test('unknown phrase: no guess, no audio, honest message', () async {
      final player = NoopSantaliAudioPlayer();
      final bloc = _bloc(player: player);
      final before = await _init(bloc);
      final historyLen = before.conversationHistory.length;
      bloc.add(const AsrFinalTranscript(
          text: 'कल विद्यालय में अवकाश रहेगा',
          inferenceMs: 300,
          languageId: 'hi'));
      final done = await _waitFor(
          bloc, (s) => !s.isProcessing && s.asrTranscript.isNotEmpty);
      expect(done.translationError,
          'Translation unavailable for this prototype phrase.');
      expect(done.currentTranslationResult, isEmpty);
      expect(done.conversationHistory.length, historyLen);
      await Future<void>.delayed(const Duration(milliseconds: 300));
      expect(player.playLog, isEmpty);
      await bloc.close();
    });
  });

  group('11-13. Random delay honesty', () {
    test('generated delay is within 1500-2150 ms', () async {
      final bloc = _bloc();
      await _init(bloc);
      bloc.add(const AsrFinalTranscript(
          text: _hindiSun, inferenceMs: 400, languageId: 'hi'));
      final waiting = await _waitFor(
          bloc, (s) => s.generatedLatencyMs > 0);
      expect(waiting.generatedLatencyMs, inInclusiveRange(1500, 2150));
      // During the wait: translated text/audio must NOT appear yet.
      expect(waiting.currentTranslationResult, isEmpty);
      // Cancel the pending timer before closing (no emit-after-close).
      bloc.add(ToggleTeacherMicRecord());
      await _waitFor(bloc, (s) => s.isRecording);
      await bloc.close();
    });

    test('actual wait equals the generated value; pill shows the same value',
        () async {
      final bloc = _bloc();
      await _init(bloc);
      final sw = Stopwatch()..start();
      bloc.add(const AsrFinalTranscript(
          text: _hindiSun, inferenceMs: 400, languageId: 'hi'));
      final waiting = await _waitFor(
          bloc, (s) => s.generatedLatencyMs > 0);
      final generated = waiting.generatedLatencyMs;
      final out = await _waitFor(
          bloc,
          (s) =>
              s.currentTranslationResult.isNotEmpty &&
              !s.isProcessing);
      sw.stop();
      // Same single stored value before and after (never regenerated).
      expect(out.generatedLatencyMs, generated);
      // Real elapsed wait honors the generated value (200 ms scheduling slop).
      expect(sw.elapsedMilliseconds, greaterThanOrEqualTo(generated - 200));
      expect(out.actualDelayMs, greaterThanOrEqualTo(generated - 200));
      await _waitHistory(bloc, 'sun_rises_east');
      await bloc.close();
    });
  });

  group('14-18. Cancellation, offline, replay, direction, unload', () {
    test('new speech cancels pending output (no late audio)', () async {
      final player = NoopSantaliAudioPlayer();
      final bloc = _bloc(player: player);
      await _init(bloc);
      bloc.add(const AsrFinalTranscript(
          text: _hindiSun, inferenceMs: 400, languageId: 'hi'));
      await _waitFor(bloc, (s) => s.generatedLatencyMs > 0);
      // New speech while PROCESSING: cancels the timer, returns to LISTENING.
      bloc.add(ToggleTeacherMicRecord());
      final listening = await _waitFor(bloc, (s) => s.isRecording);
      expect(listening.isRecording, isTrue);
      await Future<void>.delayed(const Duration(milliseconds: 2500));
      expect(player.playLog, isEmpty);
      await bloc.close();
    });

    test('full cycle works with the remote pipeline throwing (offline)',
        () async {
      final bloc = _bloc();
      await _init(bloc);
      bloc.add(const AsrFinalTranscript(
          text: _hindiSun, inferenceMs: 400, languageId: 'hi'));
      final out = await _waitFor(
          bloc, (s) => s.currentTranslationResult.isNotEmpty);
      expect(out.currentTranslationResult, isNotEmpty);
      await _waitHistory(bloc, 'sun_rises_east');
      await bloc.close();
    });

    test('audio replay is immediate (no presentation delay)', () async {
      final player = NoopSantaliAudioPlayer();
      final bloc = _bloc(player: player);
      await _init(bloc);
      bloc.add(const AsrFinalTranscript(
          text: _hindiSun, inferenceMs: 400, languageId: 'hi'));
      await _waitFor(
          bloc, (s) => s.currentTranslationResult.isNotEmpty);
      await _waitHistory(bloc, 'sun_rises_east');
      for (var i = 0; i < 100 && player.playLog.isEmpty; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
      final plays = player.playLog.length;
      final sw = Stopwatch()..start();
      bloc.add(ReplayLocalSantaliAudio());
      for (var i = 0; i < 100 && player.playLog.length <= plays; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
      sw.stop();
      expect(player.playLog.length, greaterThan(plays));
      expect(sw.elapsedMilliseconds, lessThan(1500));
      await _settle();
      await bloc.close();
    });

    test('direction switch resets cards + model flag', () async {
      final bloc = _bloc();
      await _init(bloc);
      bloc.add(const AsrFinalTranscript(
          text: _hindiSun, inferenceMs: 400, languageId: 'hi'));
      await _waitFor(
          bloc, (s) => s.currentTranslationResult.isNotEmpty);
      bloc.add(const SwitchTranslatorDirection(
          TranslatorDirection.studentToTeacher));
      final switched = await _waitFor(
          bloc, (s) => s.direction == TranslatorDirection.studentToTeacher);
      expect(switched.currentTranslationResult, isEmpty);
      expect(switched.currentTranslationSecondary, isEmpty);
      expect(switched.asrTranscript, isEmpty);
      expect(switched.asrModelLoaded, isFalse);
      expect(switched.generatedLatencyMs, 0);
      await bloc.close();
    });

    test('mic label language follows direction (state-level)', () async {
      final bloc = _bloc();
      await _init(bloc);
      var s = bloc.state as TranslationSessionActive;
      expect(s.direction, TranslatorDirection.teacherToStudent);
      bloc.add(const SwitchTranslatorDirection(
          TranslatorDirection.studentToTeacher));
      s = await _waitFor(
          bloc, (s) => s.direction == TranslatorDirection.studentToTeacher);
      expect(s.direction, TranslatorDirection.studentToTeacher);
      await bloc.close();
    });
  });

  group('error strings (§32)', () {
    test('ASR error codes map to teacher-facing messages', () {
      expect(offlineAsrUserMessage('MODEL_UNAVAILABLE'),
          'Offline speech recognition is unavailable.');
      expect(offlineAsrUserMessage('MICROPHONE'),
          'Microphone access is required.');
      expect(
          offlineAsrUserMessage('NO_SPEECH'), 'No speech detected.');
      expect(offlineAsrUserMessage('ASR_FAILURE'),
          'Could not recognize the speech. Please try again.');
    });
  });
}
