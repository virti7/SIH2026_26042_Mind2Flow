import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:maatribhasha/core/content/prototype_demo_translation.dart';
import 'package:maatribhasha/core/content/santali_audio_player.dart';
import 'package:maatribhasha/core/enums/app_enums.dart';
import 'package:maatribhasha/core/models/app_models.dart';
import 'package:maatribhasha/core/repositories/app_repositories.dart';
import 'package:maatribhasha/features/translation/presentation/bloc/translation_bloc.dart';

/// Live prototype timing under test:
/// FINAL ASR -> Hindi + Santali texts visible -> fixed 1970 ms wait ->
/// local WAV auto-plays. Manual replay is immediate. A new recording
/// during the wait cancels the pending auto-play. NO phrase matching.

const _demoAudio =
    'assets/prototype_content/translation/audio/santali/santali_sun_rises_east.wav';

const _demo = SantaliDemoScenario(
  id: 'sun_rises_east',
  hindi: 'सूरज पूरब से निकलता है।',
  santali: 'VERIFIED_SANTALI_SUN_EAST',
  audio: _demoAudio,
);

PrototypeDemoTranslationRepository demoRepoWithAssets(Set<String> assets) =>
    PrototypeDemoTranslationRepository(
      seedDemos: const [_demo],
      seedActiveId: 'sun_rises_east',
      availableAssetsOverride: assets,
    );

/// Remote pipeline stand-in. Throws on ANY call: the prototype path must
/// never reach it (no network, no Sarvam, no FastAPI).
class ThrowingTranslationRepository implements TranslationRepository {
  int translateCalls = 0;

  @override
  Future<TranslationMessage> translateUtterance({
    required String text,
    required TribalLanguage targetLanguage,
    required bool isTeacher,
    Map<String, String>? contextMeta,
  }) async {
    translateCalls++;
    throw StateError('remote pipeline must not be called in prototype mode');
  }

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
  Duration autoPlayDelay = Duration.zero,
  NoopSantaliAudioPlayer? player,
}) =>
    TranslationBloc(
      translationRepository: ThrowingTranslationRepository(),
      demoTranslation: demoRepoWithAssets({_demoAudio}),
      santaliAudioPlayer: player ?? NoopSantaliAudioPlayer(),
      autoPlayDelay: autoPlayDelay,
    );

Future<TranslationSessionActive> _activeSession(TranslationBloc bloc) async {
  bloc.add(InitTranslationSession());
  final state =
      await bloc.stream.firstWhere((s) => s is TranslationSessionActive);
  return state as TranslationSessionActive;
}

Future<TranslationSessionActive> _santaliWaiting(
  TranslationBloc bloc,
  TranslationSessionActive current,
) async {
  bloc.add(const SwitchTargetLanguage(TribalLanguage.santali));
  final state = await bloc.stream.firstWhere((s) =>
      s is TranslationSessionActive &&
      s != current &&
      s.targetLanguage == TribalLanguage.santali);
  return state as TranslationSessionActive;
}

/// Waits for the texts-visible state after a final result (audio may still
/// be pending its delay).
Future<TranslationSessionActive> _textsVisible(
  TranslationBloc bloc,
  String input,
) async {
  bloc.add(SendTeacherCustomUtterance(input));
  final state = await bloc.stream.firstWhere((s) =>
      s is TranslationSessionActive &&
      !(s as TranslationSessionActive).isProcessing &&
      (s as TranslationSessionActive).currentInputHindi == input &&
      (s as TranslationSessionActive).currentTranslationResult.isNotEmpty);
  return state as TranslationSessionActive;
}

Future<void> _waitForPlays(NoopSantaliAudioPlayer p, int n) async {
  for (var i = 0; i < 150 && p.playLog.length < n; i++) {
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
}

void main() {
  group('Prototype demo config', () {
    test('config points at the exact bundled wav file', () {
      final file = File(
          'assets/prototype_content/translation/santali_demo_translation.json');
      expect(file.existsSync(), isTrue);
      final decoded =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      final demos = decoded['demos'] as List;
      expect(demos, isNotEmpty);
      final first = demos.first as Map<String, dynamic>;
      expect(first['audio'], _demoAudio);
      final audio = first['audio'] as String;
      expect(audio.startsWith('assets/'), isTrue);
      expect(audio.contains('http'), isFalse);
      expect(audio.contains(':\\'), isFalse);
    });

    test('production auto-play delay defaults to exactly 1970 ms', () {
      final bloc = TranslationBloc(
        translationRepository: ThrowingTranslationRepository(),
      );
      expect(bloc.autoPlayDelay, const Duration(milliseconds: 1970));
      bloc.close();
    });
  });

  group('Live prototype speech lifecycle', () {
    test('initial state: silent, empty, no error, no latency value',
        () async {
      final player = NoopSantaliAudioPlayer();
      final bloc = _bloc(player: player);
      final session = await _activeSession(bloc);
      await _santaliWaiting(bloc, session);

      expect(player.playLog, isEmpty);
      final current = bloc.state as TranslationSessionActive;
      expect(current.currentInputHindi, isEmpty);
      expect(current.currentTranslationResult, isEmpty);
      expect(current.translationError, isNull);
      expect(current.localAudioAsset, isNull);
      expect(current.latencyMs, 0);
      await bloc.close();
    });

    test('start listening: clears previous, stops audio, stays silent',
        () async {
      final player = NoopSantaliAudioPlayer();
      final bloc = _bloc(player: player);
      var session = await _activeSession(bloc);
      session = await _santaliWaiting(bloc, session);
      await _textsVisible(bloc, 'earlier utterance');
      await _waitForPlays(player, 1);
      expect(player.playLog.length, 1);

      bloc.add(ToggleTeacherMicRecord());
      final listening = await bloc.stream.firstWhere((s) =>
          s is TranslationSessionActive &&
          (s as TranslationSessionActive).isRecording);
      final active = listening as TranslationSessionActive;
      expect(active.currentTranslationResult, isEmpty);
      expect(active.translationError, isNull);
      expect(active.localAudioAsset, isNull);
      expect(player.stopCount, greaterThanOrEqualTo(1));
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(player.playLog.length, 1);
      await bloc.close();
    });

    test('texts appear at final ASR; audio follows the delay, not before',
        () async {
      final player = NoopSantaliAudioPlayer();
      final bloc = _bloc(
          player: player,
          autoPlayDelay: const Duration(milliseconds: 400));
      var session = await _activeSession(bloc);
      session = await _santaliWaiting(bloc, session);

      bloc.add(const SendTeacherCustomUtterance('final words'));
      final texts = await bloc.stream.firstWhere((s) =>
          s is TranslationSessionActive &&
          !(s as TranslationSessionActive).isProcessing &&
          (s as TranslationSessionActive).currentInputHindi ==
              'final words' &&
          (s as TranslationSessionActive).currentTranslationResult.isNotEmpty);
      final active = texts as TranslationSessionActive;
      expect(active.currentTranslationResult, 'VERIFIED_SANTALI_SUN_EAST');
      // Audio must NOT have started yet (delay pending).
      expect(player.playLog, isEmpty);
      // After ~400 ms the same configured clip auto-plays.
      await _waitForPlays(player, 1);
      expect(player.playLog, [_demoAudio]);
      await bloc.close();
    });

    test('no phrase matching: any input yields the configured demo',
        () async {
      final player = NoopSantaliAudioPlayer();
      final bloc = _bloc(player: player);
      var session = await _activeSession(bloc);
      session = await _santaliWaiting(bloc, session);

      for (final input in ['completely unrelated sentence', '12345']) {
        final ready = await _textsVisible(bloc, input);
        expect(ready.currentTranslationResult, 'VERIFIED_SANTALI_SUN_EAST');
        expect(ready.localAudioAsset, _demoAudio);
      }
      await _waitForPlays(player, 2);
      expect(player.playLog, [_demoAudio, _demoAudio]);
      await bloc.close();
    });

    test('manual replay is immediate (no 1.97 s wait)', () async {
      final player = NoopSantaliAudioPlayer();
      final remote = ThrowingTranslationRepository();
      final bloc = TranslationBloc(
        translationRepository: remote,
        demoTranslation: demoRepoWithAssets({_demoAudio}),
        santaliAudioPlayer: player,
        autoPlayDelay: const Duration(milliseconds: 400),
      );
      var session = await _activeSession(bloc);
      session = await _santaliWaiting(bloc, session);
      await _textsVisible(bloc, 'speak');
      await _waitForPlays(player, 1);

      final t0 = DateTime.now();
      bloc.add(ReplayLocalSantaliAudio());
      await _waitForPlays(player, 2);
      final elapsed = DateTime.now().difference(t0);
      // Immediate replay: far below the automatic 400 ms test delay.
      expect(elapsed, lessThan(const Duration(milliseconds: 400)));
      expect(player.playLog[1], _demoAudio);
      expect(remote.translateCalls, 0);
      await bloc.close();
    });

    test('new recording during the wait cancels pending audio', () async {
      final player = NoopSantaliAudioPlayer();
      final bloc = _bloc(
          player: player,
          autoPlayDelay: const Duration(milliseconds: 500));
      var session = await _activeSession(bloc);
      session = await _santaliWaiting(bloc, session);

      // Sentence A final -> texts visible, timer running, no audio yet.
      await _textsVisible(bloc, 'sentence A');
      expect(player.playLog, isEmpty);
      // Sentence B starts before A's timer expires -> A must never play.
      bloc.add(ToggleTeacherMicRecord());
      await bloc.stream.firstWhere((s) =>
          s is TranslationSessionActive &&
          (s as TranslationSessionActive).isRecording);
      await Future<void>.delayed(const Duration(milliseconds: 700));
      expect(player.playLog, isEmpty,
          reason: 'cancelled pending audio must never start');
      // Stopping (sentence B final) schedules exactly one playback.
      bloc.add(ToggleTeacherMicRecord());
      await _waitForPlays(player, 1);
      expect(player.playLog, [_demoAudio]);
      await bloc.close();
    });

    test('offline works; latency honestly measured', () async {
      final remote = ThrowingTranslationRepository();
      final bloc = TranslationBloc(
        translationRepository: remote,
        demoTranslation: demoRepoWithAssets({_demoAudio}),
        santaliAudioPlayer: NoopSantaliAudioPlayer(),
      );
      var session = await _activeSession(bloc);
      session = await _santaliWaiting(bloc, session);
      // No connectivity object exists on this path: airplane mode safe.
      final ready = await _textsVisible(bloc, 'offline check');
      expect(ready.isLocalPrototype, isTrue);
      expect(remote.translateCalls, 0);
      expect(ready.latencyMs, greaterThanOrEqualTo(0));
      await bloc.close();
    });

    test('missing asset errors safely without playback', () async {
      final player = NoopSantaliAudioPlayer();
      final bloc = TranslationBloc(
        translationRepository: ThrowingTranslationRepository(),
        demoTranslation: demoRepoWithAssets(const {}),
        santaliAudioPlayer: player,
      );
      var session = await _activeSession(bloc);
      session = await _santaliWaiting(bloc, session);
      expect((bloc.state as TranslationSessionActive).translationError, isNull);

      final ready = await _textsVisible(bloc, 'hello');
      // Texts still shown; asset problem reported; nothing played; no crash.
      expect(ready.currentTranslationResult, 'VERIFIED_SANTALI_SUN_EAST');
      expect(player.playLog, isEmpty);
      // The missing-asset message arrives (same or follow-up emission).
      for (var i = 0;
          i < 20 &&
              (bloc.state as TranslationSessionActive).translationError ==
                  null;
          i++) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
      expect(
          (bloc.state as TranslationSessionActive).translationError,
          anyOf('Audio unavailable for this translation.',
              'Could not play Santali audio.'));
      await bloc.close();
    });

    test('missing translation data is safe', () async {
      final bloc = TranslationBloc(
        translationRepository: ThrowingTranslationRepository(),
        demoTranslation: PrototypeDemoTranslationRepository(
            seedDemos: const [], availableAssetsOverride: const {}),
        santaliAudioPlayer: NoopSantaliAudioPlayer(),
      );
      var session = await _activeSession(bloc);
      session = await _santaliWaiting(bloc, session);
      bloc.add(const SendTeacherCustomUtterance('hello'));
      final ready = await bloc.stream.firstWhere((s) =>
          s is TranslationSessionActive &&
          (s as TranslationSessionActive).translationError != null);
      expect((ready as TranslationSessionActive).translationError,
          'Translation unavailable.');
      await bloc.close();
    });
  });
}
