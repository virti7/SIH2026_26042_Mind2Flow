import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:maatribhasha/core/content/santali_audio_player.dart';
import 'package:maatribhasha/core/enums/app_enums.dart';
import 'package:maatribhasha/core/models/app_models.dart';
import 'package:maatribhasha/core/repositories/app_repositories.dart';
import 'package:maatribhasha/core/translation/bidirectional_phrase_bank.dart';
import 'package:maatribhasha/features/translation/presentation/bloc/translation_bloc.dart';

/// Deterministic offline Translator tests: ONE action button, single tap =
/// Hindi → Santali, double tap = Santali → Hindi. JSON bank + local audio
/// only — no ASR, no ONNX, no models, no network.
///
/// A few tests await the genuine 1500–2150 ms presentation delay to prove
/// the actual wait equals the generated value (no faked latency).

const _hindi = 'मुझे यह नहीं समझ रहा है';
const _hindiRoman = 'Mujhe yah nahin samajh raha hai';
const _olChiki = 'ᱤᱧ ᱱᱚᱣᱟ ᱵᱟᱝ ᱵᱩᱡᱷᱟᱹᱣ ᱮᱫᱟᱸ';
const _roman = 'Iñ nowa bang bujhaṛ edañ.';
const _santaliWav =
    'assets/prototype_content/translation/audio/santali/phrase_001.wav';
const _hindiWav =
    'assets/prototype_content/translation/audio/hindi/phrase_001.wav';

// phrase_002 (single tap: Hindi → Santali). Mirrors the shipped asset.
const _hindi2 = 'मैं तुम्हें समझाती हूँ';
const _hindiRoman2 = 'Main tumhe samjhati hu';
const _olChiki2 = 'ᱤᱧ ᱟᱢ ᱞᱟᱹᱜᱤᱛ ᱯᱟᱲᱦᱟᱣ ᱮᱫᱟᱸ';
const _roman2 = 'Iñ am lāgit paṛhaw edañ.';
const _santaliWav2 =
    'assets/prototype_content/translation/audio/santali/phrase_002.wav';
const _hindiWav2 =
    'assets/prototype_content/translation/audio/hindi/phrase_002.wav';

/// The bank is loaded DYNAMICALLY from decoded JSON — pairs are never
/// hardcoded in Dart. This seed mirrors the shipped asset.
List<Map<String, dynamic>> _seedItems() => [
      {
        'id': 'phrase_001',
        'hindi': _hindi,
        'hindiRoman': _hindiRoman,
        'hindiAudio': _hindiWav,
        'santaliOlChiki': _olChiki,
        'santaliRoman': _roman,
        'santaliAudio': _santaliWav,
        'category': 'classroom',
        'tags': [],
      },
      {
        'id': 'phrase_002',
        'hindi': _hindi2,
        'hindiRoman': _hindiRoman2,
        'hindiAudio': _hindiWav2,
        'santaliOlChiki': _olChiki2,
        'santaliRoman': _roman2,
        'santaliAudio': _santaliWav2,
        'category': 'classroom',
        'tags': [],
      },
    ];

BidirectionalPhraseBank _bank() =>
    BidirectionalPhraseBank(seedJson: _seedItems());

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

TranslationBloc _bloc({
  BidirectionalPhraseBank? bank,
  NoopSantaliAudioPlayer? player,
}) =>
    TranslationBloc(
      translationRepository: ThrowingTranslationRepository(),
      santaliAudioPlayer: player ?? NoopSantaliAudioPlayer(),
      bidirectionalBank: bank ?? _bank(),
      random: Random(7),
    );

Future<TranslationSessionActive> _init(TranslationBloc bloc) async {
  bloc.add(InitTranslationSession());
  final s =
      await bloc.stream.firstWhere((e) => e is TranslationSessionActive);
  return s as TranslationSessionActive;
}

Future<TranslationSessionActive> _waitFor(
  TranslationBloc bloc,
  bool Function(TranslationSessionActive) pred,
) async {
  final s = await bloc.stream
      .firstWhere((e) => e is TranslationSessionActive && pred(e));
  return s as TranslationSessionActive;
}

Future<void> _waitHistory(TranslationBloc bloc) async {
  await _waitFor(bloc,
      (s) => s.conversationHistory.any((m) => m.id.startsWith('tap_')));
}

void main() {
  group('master JSON bank (shipped asset)', () {
    test('exact JSON path exists and holds phrase_001', () {
      const path =
          'assets/prototype_content/translation/bidirectional_phrase_bank.json';
      final file = File(path);
      expect(file.existsSync(), isTrue,
          reason: 'missing master bank at $path');
      final decoded = jsonDecode(file.readAsStringSync());
      expect(decoded, isA<List>());
      final items = (decoded as List)
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      expect(items, isNotEmpty);
      final first = items.firstWhere((e) => e['id'] == 'phrase_001');
      expect(first['hindi'], _hindi);
      expect(first['santaliOlChiki'], _olChiki);
      expect(first['santaliRoman'], _roman);
      expect((first['hindiAudio'] as String).startsWith('assets/'), isTrue);
      expect((first['santaliAudio'] as String).startsWith('assets/'), isTrue);
      expect(first['hindiAudio'], isNot(contains('://')));
      expect(first['santaliAudio'], isNot(contains('://')));
    });
  });

  group('data model (dynamic JSON, never hardcoded)', () {
    test('BidirectionalPhrase parses all schema fields', () {
      final p =
          BidirectionalPhrase.fromJson(Map<String, dynamic>.from(_seedItems().first));
      expect(p.id, 'phrase_001');
      expect(p.hindi, _hindi);
      expect(p.hindiRoman, isNotEmpty);
      expect(p.hindiAudio, _hindiWav);
      expect(p.santaliOlChiki, _olChiki);
      expect(p.santaliRoman, _roman);
      expect(p.santaliAudio, _santaliWav);
      expect(p.category, 'classroom');
      expect(p.isValid, isTrue);
    });

    test('bank loads records dynamically and selects phrase_001', () async {
      final bank = _bank();
      final phrases = await bank.load();
      expect(phrases.map((p) => p.id), contains('phrase_001'));
      expect(bank.selected(phrases)?.id, 'phrase_001');
    });

    test('tap mapping is data-driven: single→phrase_002, double→phrase_001',
        () async {
      final bank = _bank();
      final phrases = await bank.load();
      // Resolved via firstWhere on the loaded JSON — never hardcoded
      // sentences in Dart.
      final hindiToSantali =
          phrases.firstWhere((p) => p.id == 'phrase_002');
      final santaliToHindi =
          phrases.firstWhere((p) => p.id == 'phrase_001');
      expect(hindiToSantali.hindi, _hindi2);
      expect(santaliToHindi.hindi, _hindi);
      expect(bank.hindiToSantali(phrases)?.id, 'phrase_002');
      expect(bank.santaliToHindi(phrases)?.id, 'phrase_001');
    });

    test('invalid records are skipped, never crash', () async {
      final bank = BidirectionalPhraseBank(seedJson: [
        {'id': '', 'hindi': '', 'santaliOlChiki': ''},
        ..._seedItems(),
      ]);
      final phrases = await bank.load();
      expect(phrases.length, 2);
      expect(phrases.map((p) => p.id),
          containsAll(['phrase_001', 'phrase_002']));
    });
  });

  group('start/stop recording = Hindi → Santali', () {
    test('first tap holds: nothing fires before the double-tap window',
        () async {
      final bloc = _bloc();
      await _init(bloc);
      bloc.add(TranslatorButtonTapped());
      await Future<void>.delayed(const Duration(milliseconds: 200));
      final s = bloc.state as TranslationSessionActive;
      // Still Idle: no Listening, no input phrase, no output, no latency.
      expect(s.isRecording, isFalse);
      expect(s.isProcessing, isFalse);
      expect(s.currentInputHindi, isEmpty);
      expect(s.currentTranslationResult, isEmpty);
      expect(s.generatedLatencyMs, 0);
      // Window elapses with no second tap → Listening begins (no phrases).
      final listening = await _waitFor(bloc, (e) => e.isRecording);
      expect(listening.currentInputHindi, isEmpty);
      expect(listening.currentTranslationResult, isEmpty);
      expect(listening.generatedLatencyMs, 0);
      await bloc.close();
    });

    test('Listening shows no Hindi phrase, no output, no latency', () async {
      final bloc = _bloc();
      await _init(bloc);
      bloc.add(TranslatorButtonTapped());
      final listening = await _waitFor(bloc, (e) => e.isRecording);
      expect(listening.isProcessing, isFalse);
      expect(listening.currentInputHindi, isEmpty);
      expect(listening.currentInputSecondary, isEmpty);
      expect(listening.currentTranslationResult, isEmpty);
      expect(listening.currentTranslationSecondary, isEmpty);
      expect(listening.generatedLatencyMs, 0);
      expect(listening.translationError, isNull);
      await bloc.close();
    });

    test('stop tap reveals input, then Santali + audio after exact delay',
        () async {
      final player = NoopSantaliAudioPlayer();
      final bloc = _bloc(player: player);
      await _init(bloc);
      // FIRST tap → Listening.
      bloc.add(TranslatorButtonTapped());
      await _waitFor(bloc, (e) => e.isRecording);
      // STOP tap → Preparing: phrase_002 Hindi input visible, Santali
      // hidden, latency hidden.
      final sw = Stopwatch()..start();
      bloc.add(TranslatorButtonTapped());
      final preparing = await _waitFor(
          bloc, (s) => s.isProcessing && s.translatorFlow == 'hi_to_sat');
      expect(preparing.isRecording, isFalse);
      expect(preparing.currentInputHindi, _hindi2);
      expect(preparing.currentInputSecondary, _hindiRoman2);
      expect(preparing.currentTranslationResult, isEmpty);
      final out = await _waitFor(bloc,
          (s) => s.currentTranslationResult.isNotEmpty && !s.isProcessing);
      sw.stop();
      expect(out.currentTranslationResult, _olChiki2);
      expect(out.currentTranslationSecondary, _roman2);
      expect(out.translatorFlow, 'hi_to_sat');
      // ONE generated value, awaited exactly, displayed exactly.
      expect(out.generatedLatencyMs, inInclusiveRange(1500, 2150));
      expect(out.actualDelayMs, greaterThanOrEqualTo(out.generatedLatencyMs - 200));
      expect(sw.elapsedMilliseconds,
          greaterThanOrEqualTo(out.generatedLatencyMs - 200));
      // Local Santali audio started (Noop records the asset path).
      for (var i = 0; i < 100 && player.playLog.isEmpty; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
      expect(player.playLog, contains(_santaliWav2));
      await _waitHistory(bloc);
      await bloc.close();
    });

    test('missing phrase_002 shows unavailable, never crashes', () async {
      final bank = BidirectionalPhraseBank(seedJson: [
        {
          'id': 'phrase_001',
          'hindi': _hindi,
          'hindiRoman': _hindiRoman,
          'hindiAudio': _hindiWav,
          'santaliOlChiki': _olChiki,
          'santaliRoman': _roman,
          'santaliAudio': _santaliWav,
          'category': 'classroom',
          'tags': [],
        },
      ]);
      final bloc = _bloc(bank: bank);
      await _init(bloc);
      bloc.add(TranslatorButtonTapped());
      await _waitFor(bloc, (e) => e.isRecording);
      bloc.add(TranslatorButtonTapped());
      final done = await _waitFor(
          bloc, (s) => !s.isProcessing && s.translationError != null);
      expect(done.translationError,
          'Translation unavailable for this prototype phrase.');
      expect(done.currentTranslationResult, isEmpty);
      await bloc.close();
    });
  });

  group('double tap = Santali → Hindi', () {
    test('double tap plays input first, then reveals Hindi + Hindi audio',
        () async {
      final player = NoopSantaliAudioPlayer();
      final bloc = _bloc(player: player);
      await _init(bloc);
      bloc.add(TranslatorButtonTapped());
      await Future<void>.delayed(const Duration(milliseconds: 100));
      bloc.add(TranslatorButtonTapped());
      // Both taps land inside the 350 ms window: the flow must be
      // sat_to_hi directly. If Listening had fired, the second tap would
      // have been a STOP tap (hi_to_sat) instead — the flow assertion
      // below proves the double tap was not split into start+stop.
      final preparing = await _waitFor(bloc,
          (s) => s.isProcessing && s.translatorFlow == 'sat_to_hi');
      expect(preparing.isRecording, isFalse);
      expect(preparing.currentInputHindi, _olChiki);
      expect(preparing.currentInputSecondary, _roman);
      // Output + latency hidden while preparing.
      expect(preparing.currentTranslationResult, isEmpty);
      final out = await _waitFor(bloc,
          (s) => s.currentTranslationResult.isNotEmpty && !s.isProcessing);
      expect(out.translatorFlow, 'sat_to_hi');
      expect(out.currentTranslationResult, _hindi);
      // Hindi Roman output line (input Santali stays on the input card).
      expect(out.currentTranslationSecondary, _hindiRoman);
      expect(out.generatedLatencyMs, inInclusiveRange(1500, 2150));
      for (var i = 0; i < 100 && player.playLog.length < 2; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
      // Input Santali clip played FIRST, Hindi clip after the delay.
      expect(player.playLog.first, _santaliWav);
      expect(player.playLog, contains(_hindiWav));
      await _waitHistory(bloc);
      await bloc.close();
    });
  });

  group('cancel + edge behavior', () {
    test('new interaction cancels the pending one (old output never appears)',
        () async {
      final player = NoopSantaliAudioPlayer();
      final bloc = _bloc(player: player);
      await _init(bloc);
      // Start a Hindi → Santali flow (listening, then stop → preparing).
      bloc.add(TranslatorButtonTapped());
      await _waitFor(bloc, (e) => e.isRecording);
      bloc.add(TranslatorButtonTapped());
      await _waitFor(bloc,
          (s) => s.isProcessing && s.translatorFlow == 'hi_to_sat');
      // New interaction mid-wait: quick double tap → Santali → Hindi wins.
      bloc.add(TranslatorButtonTapped());
      await Future<void>.delayed(const Duration(milliseconds: 100));
      bloc.add(TranslatorButtonTapped());
      final out = await _waitFor(bloc,
          (s) => s.currentTranslationResult.isNotEmpty && !s.isProcessing);
      expect(out.translatorFlow, 'sat_to_hi');
      expect(out.currentTranslationResult, _hindi);
      await _waitHistory(bloc);
      await Future<void>.delayed(const Duration(milliseconds: 300));
      // The cancelled Hindi → Santali flow never played its output clip.
      expect(player.playLog.where((a) => a == _santaliWav2), isEmpty);
      // The winning flow played its input clip first, then Hindi output.
      expect(player.playLog.first, _santaliWav);
      expect(player.playLog, contains(_hindiWav));
      await bloc.close();
    });

    test('empty bank shows the unavailable message, guesses nothing',
        () async {
      final bloc = _bloc(bank: BidirectionalPhraseBank(seedJson: const []));
      final before = await _init(bloc);
      final historyLen = before.conversationHistory.length;
      bloc.add(TranslatorButtonTapped());
      await _waitFor(bloc, (e) => e.isRecording);
      bloc.add(TranslatorButtonTapped());
      final done = await _waitFor(
          bloc, (s) => !s.isProcessing && s.translationError != null);
      expect(done.translationError,
          'Translation unavailable for this prototype phrase.');
      expect(done.currentTranslationResult, isEmpty);
      expect(done.conversationHistory.length, historyLen);
      await bloc.close();
    });

    test('replay is immediate (no presentation delay)', () async {
      final player = NoopSantaliAudioPlayer();
      final bloc = _bloc(player: player);
      await _init(bloc);
      bloc.add(TranslatorButtonTapped());
      await _waitFor(bloc, (e) => e.isRecording);
      bloc.add(TranslatorButtonTapped());
      await _waitFor(
          bloc, (s) => s.currentTranslationResult.isNotEmpty);
      await _waitHistory(bloc);
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
      await Future<void>.delayed(const Duration(milliseconds: 300));
      await bloc.close();
    });
  });
}
