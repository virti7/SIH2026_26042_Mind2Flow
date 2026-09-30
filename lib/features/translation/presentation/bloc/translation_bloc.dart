import 'dart:async';
import 'dart:math';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/asr/offline_asr_service.dart';
import '../../../../core/content/prototype_demo_translation.dart';
import '../../../../core/content/santali_audio_player.dart';
import '../../../../core/content/santali_phrase_bank.dart';
import '../../../../core/enums/app_enums.dart';
import '../../../../core/models/app_models.dart';
import '../../../../core/review/review_models.dart';
import '../../../../core/review/review_stores.dart';
import '../../../../core/repositories/app_repositories.dart';
import '../../../../core/translation/bidirectional_phrase_bank.dart';
import '../../../../core/translation/bidirectional_phrase_matcher.dart';

// EVENTS
abstract class TranslationEvent extends Equatable {
  const TranslationEvent();
  @override
  List<Object?> get props => [];
}

/// Live Translator direction (§23). Teacher → Students uses the Hindi ASR
/// model; Student → Teacher uses the Santali ASR model. Only one model is
/// ever loaded at a time (2 GB RAM target).
enum TranslatorDirection { teacherToStudent, studentToTeacher }

class InitTranslationSession extends TranslationEvent {}

class SwitchTargetLanguage extends TranslationEvent {
  final TribalLanguage language;
  const SwitchTargetLanguage(this.language);
  @override
  List<Object?> get props => [language];
}

class ToggleTeacherMicRecord extends TranslationEvent {}

/// ONE Translator action button tap (deterministic offline prototype).
///
/// Start/stop recording-style interaction (no ASR — UI/demo only):
/// * Idle + first tap → held for [TranslationBloc.translatorTapWindow].
///   A second tap inside the window is a DOUBLE tap (Santali → Hindi).
///   Otherwise the window elapses and Listening/Recording begins.
/// * Listening + tap → STOP: the Hindi → Santali flow runs (phrase_002).
///
/// A double tap therefore NEVER runs the Hindi → Santali flow, and the
/// normal start/stop sequence NEVER becomes a double-tap translation.
class TranslatorButtonTapped extends TranslationEvent {}

/// Internal: the double-tap window elapsed with no second tap, so the
/// pending first tap now enters Listening/Recording (no phrase shown yet).
class TranslatorTapWindowElapsed extends TranslationEvent {}

/// Operator switches the Live Translator direction. Releases the previous
/// ASR model (one model at a time) and resets both cards to waiting.
class SwitchTranslatorDirection extends TranslationEvent {
  final TranslatorDirection direction;
  const SwitchTranslatorDirection(this.direction);
  @override
  List<Object?> get props => [direction];
}

/// FINAL on-device ASR transcript. Only final results are ever dispatched —
/// there is intentionally no partial/interim event type, so intermediate
/// hypotheses can never trigger translation (§11).
class AsrFinalTranscript extends TranslationEvent {
  final String text;
  final int inferenceMs;
  final String languageId; // 'hi' | 'sat'
  const AsrFinalTranscript({
    required this.text,
    required this.inferenceMs,
    required this.languageId,
  });
  @override
  List<Object?> get props => [text, inferenceMs, languageId];
}

/// Final Hindi ASR result (typed input currently; later the real ASR final
/// transcript). Only FINAL results arrive here — never partial hypotheses.
class SendTeacherCustomUtterance extends TranslationEvent {
  final String text;
  const SendTeacherCustomUtterance(this.text);
  @override
  List<Object?> get props => [text];
}

class TriggerStudentResponseSimulation extends TranslationEvent {}

/// Replays the current local Santali prototype clip (speaker button).
/// Local asset only — never ASR, never the translation repository.
class ReplayLocalSantaliAudio extends TranslationEvent {}

/// Replays the current translator INPUT clip (input-card speaker button).
/// Immediate local playback — never a new latency, never ASR, never network.
class ReplayTranslatorInputAudio extends TranslationEvent {}

/// Sends a Quick Phrase Bank phrase to the Live Classroom Translator.
///
/// Carries the phrase's own pre-verified Hindi + Santali + local audio.
/// The Live Translator displays them directly — no translation is generated,
/// no phrase matching runs, no network/Sarvam/FastAPI is called.
class UsePhraseBankPhraseInLiveLesson extends TranslationEvent {
  final String phraseId;
  final String hindi;
  final String santaliOlChiki;
  final String santaliRoman;
  final String audioAsset;

  const UsePhraseBankPhraseInLiveLesson({
    required this.phraseId,
    required this.hindi,
    required this.santaliOlChiki,
    required this.santaliRoman,
    required this.audioAsset,
  });

  @override
  List<Object?> get props =>
      [phraseId, hindi, santaliOlChiki, santaliRoman, audioAsset];
}

class LoadQuickPhrases extends TranslationEvent {
  final String category;
  const LoadQuickPhrases({this.category = 'All'});
  @override
  List<Object?> get props => [category];
}

class SubmitTranslationFeedbackEvent extends TranslationEvent {
  final String original;
  final String translated;
  final String issueType;
  final String? comment;

  const SubmitTranslationFeedbackEvent({
    required this.original,
    required this.translated,
    required this.issueType,
    this.comment,
  });

  @override
  List<Object?> get props => [original, translated, issueType, comment];
}

// ---------------------------------------------------------------------------
// CONFIDENCE + UNDERSTANDING CHECK + REVIEW LOOP (offline demo)
// ---------------------------------------------------------------------------

/// Understanding Check answer (§5): the human validation layer. YES =
/// understood → continue teaching; NO = send to the local Reviewer Queue.
class UnderstandingCheckAnswered extends TranslationEvent {
  final bool understood;
  const UnderstandingCheckAnswered(this.understood);
  @override
  List<Object?> get props => [understood];
}

/// Teacher taps "Use Corrected Translation" on a correction notice (§13):
/// the corrected text replaces the current result and the phrase record is
/// refreshed from Translation Memory.
class ApplyCorrectionNotice extends TranslationEvent {
  final String reviewId;
  const ApplyCorrectionNotice(this.reviewId);
  @override
  List<Object?> get props => [reviewId];
}

/// Dismisses the correction notification card.
class DismissCorrectionNotice extends TranslationEvent {}

/// Manual refresh of Translation-Memory-derived corrections (e.g. when
/// returning from the Reviewer Portal).
class RefreshCorrectionsFromMemory extends TranslationEvent {}

// STATES
abstract class TranslationState extends Equatable {
  const TranslationState();
  @override
  List<Object?> get props => [];
}

class TranslationInitial extends TranslationState {}
class TranslationLoading extends TranslationState {}

/// Speech lifecycle: IDLE (!isRecording && !isProcessing) -> LISTENING
/// (isRecording) -> PROCESSING (isProcessing, after speech ends) -> READY.
class TranslationSessionActive extends TranslationState {
  final TribalLanguage targetLanguage;
  final bool isRecording;
  final bool isProcessing;
  final String currentInputHindi;
  final String currentTranslationResult;
  final List<TranslationMessage> conversationHistory;
  final List<QuickPhrase> quickPhrases;
  final String activeCategory;
  final bool isOfflineNmt;
  final int latencyMs;
  final bool feedbackSubmitted;

  /// Offline prototype demo (presentation mode). When [isLocalPrototype] is
  /// true, [currentTranslationResult] is the configured demo Santali text
  /// and [localAudioAsset] is the bundled clip that was auto-played
  /// (replayable via the speaker button, no network). The demo output is
  /// NEVER selected by matching the recognized Hindi sentence.
  final bool isLocalPrototype;
  final String? localAudioAsset;
  final String? localPhraseId;

  // --- Bidirectional offline ASR (§9–§23) ---------------------------------
  /// Active Live Translator direction.
  final TranslatorDirection direction;

  /// Last FINAL on-device ASR transcript (verbatim model output, unedited).
  final String asrTranscript;

  /// Measured on-device ASR inference time in ms (NOT the presentation delay).
  final int asrInferenceMs;

  /// True once the direction's ASR model initialized (reused afterwards).
  final bool asrModelLoaded;

  /// ONE random prototype response delay (1500–2150 ms) generated per
  /// successful match. Awaited exactly, then displayed exactly (§18–§19).
  final int generatedLatencyMs;

  /// Measured wait actually performed (must equal [generatedLatencyMs]).
  final int actualDelayMs;

  /// Second output line: Santali Roman (single tap) or Hindi Roman
  /// (double tap). Shown only after the latency delay.
  final String currentTranslationSecondary;

  /// Input-card second line: Hindi Roman (single tap) or Santali Roman
  /// (double tap). Shown immediately with the preselected input phrase.
  final String currentInputSecondary;

  /// Local bundled clip for the current translator INPUT (input-card speaker
  /// button). Null when the record carries no input audio.
  final String? inputAudioAsset;

  /// Deterministic tap Translator flow: '' (none), 'hi_to_sat' (single tap),
  /// or 'sat_to_hi' (double tap). Drives input/output card titles. No ASR,
  /// no recognized-speech text, no confidence score is ever shown.
  final String translatorFlow;

  /// Confidence score (0–100) of the CURRENT translation result, taken
  /// verbatim from the phrase JSON (deterministic — never random).
  /// 0 and [hasConfidence] == false when no result is present.
  final int currentConfidenceScore;

  /// Whether a confidence score exists for the current result.
  final bool hasConfidence;

  /// Whether the Understanding Check should be shown for the current
  /// result (shown after the result + confidence are visible).
  final bool showUnderstandingCheck;

  /// Human answer for the CURRENT interaction (null = not answered yet).
  final UnderstandingResponse? understandingResponse;

  /// Id of the Review Queue item created when the user answered NO, for
  /// the in-UI confirmation chip. Null while none was created.
  final String? enqueuedReviewId;

  /// Active "Translation corrected by language expert" card (§13).
  /// Null when there is no unconsumed notice.
  final CorrectionNotice? correctionNotice;

  /// Whether the CURRENT result came from Translation Memory (expert
  /// correction applied, §14) — surfaces "Expert Verified" in the UI.
  final bool currentFromTranslationMemory;

  /// Teacher-facing error for the current translation card, e.g.
  /// "Translation unavailable." / "Audio unavailable for this translation."
  /// / "Could not play Santali audio." Null when none.
  final String? translationError;

  const TranslationSessionActive({
    required this.targetLanguage,
    required this.isRecording,
    this.isProcessing = false,
    required this.currentInputHindi,
    required this.currentTranslationResult,
    required this.conversationHistory,
    required this.quickPhrases,
    this.activeCategory = 'All',
    this.isOfflineNmt = true,
    this.latencyMs = 0,
    this.feedbackSubmitted = false,
    this.isLocalPrototype = false,
    this.localAudioAsset,
    this.localPhraseId,
    this.translationError,
    this.direction = TranslatorDirection.teacherToStudent,
    this.asrTranscript = '',
    this.asrInferenceMs = 0,
    this.asrModelLoaded = false,
    this.generatedLatencyMs = 0,
    this.actualDelayMs = 0,
    this.currentTranslationSecondary = '',
    this.currentInputSecondary = '',
    this.inputAudioAsset,
    this.translatorFlow = '',
    this.currentConfidenceScore = 0,
    this.hasConfidence = false,
    this.showUnderstandingCheck = false,
    this.understandingResponse,
    this.enqueuedReviewId,
    this.correctionNotice,
    this.currentFromTranslationMemory = false,
  });

  TranslationSessionActive copyWith({
    TribalLanguage? targetLanguage,
    bool? isRecording,
    bool? isProcessing,
    String? currentInputHindi,
    String? currentTranslationResult,
    List<TranslationMessage>? conversationHistory,
    List<QuickPhrase>? quickPhrases,
    String? activeCategory,
    bool? isOfflineNmt,
    int? latencyMs,
    bool? feedbackSubmitted,
    bool? isLocalPrototype,
    String? localAudioAsset,
    String? localPhraseId,
    String? translationError,
    bool clearTranslationError = false,
    bool clearLocalAudio = false,
    TranslatorDirection? direction,
    String? asrTranscript,
    int? asrInferenceMs,
    bool? asrModelLoaded,
    int? generatedLatencyMs,
    int? actualDelayMs,
    String? currentTranslationSecondary,
    String? currentInputSecondary,
    String? inputAudioAsset,
    bool clearInputAudio = false,
    String? translatorFlow,
    int? currentConfidenceScore,
    bool? hasConfidence,
    bool clearConfidence = false,
    bool? showUnderstandingCheck,
    bool clearUnderstandingCheck = false,
    UnderstandingResponse? understandingResponse,
    bool clearUnderstandingResponse = false,
    String? enqueuedReviewId,
    bool clearEnqueuedReviewId = false,
    CorrectionNotice? correctionNotice,
    bool clearCorrectionNotice = false,
    bool? currentFromTranslationMemory,
  }) {
    return TranslationSessionActive(
      targetLanguage: targetLanguage ?? this.targetLanguage,
      isRecording: isRecording ?? this.isRecording,
      isProcessing: isProcessing ?? this.isProcessing,
      currentInputHindi: currentInputHindi ?? this.currentInputHindi,
      currentTranslationResult:
          currentTranslationResult ?? this.currentTranslationResult,
      conversationHistory: conversationHistory ?? this.conversationHistory,
      quickPhrases: quickPhrases ?? this.quickPhrases,
      activeCategory: activeCategory ?? this.activeCategory,
      isOfflineNmt: isOfflineNmt ?? this.isOfflineNmt,
      latencyMs: latencyMs ?? this.latencyMs,
      feedbackSubmitted: feedbackSubmitted ?? this.feedbackSubmitted,
      isLocalPrototype: isLocalPrototype ?? this.isLocalPrototype,
      localAudioAsset:
          clearLocalAudio ? null : (localAudioAsset ?? this.localAudioAsset),
      localPhraseId:
          clearLocalAudio ? null : (localPhraseId ?? this.localPhraseId),
      translationError: clearTranslationError
          ? null
          : (translationError ?? this.translationError),
      direction: direction ?? this.direction,
      asrTranscript: asrTranscript ?? this.asrTranscript,
      asrInferenceMs: asrInferenceMs ?? this.asrInferenceMs,
      asrModelLoaded: asrModelLoaded ?? this.asrModelLoaded,
      generatedLatencyMs: generatedLatencyMs ?? this.generatedLatencyMs,
      actualDelayMs: actualDelayMs ?? this.actualDelayMs,
      currentTranslationSecondary:
          currentTranslationSecondary ?? this.currentTranslationSecondary,
      currentInputSecondary:
          currentInputSecondary ?? this.currentInputSecondary,
      inputAudioAsset:
          clearInputAudio ? null : (inputAudioAsset ?? this.inputAudioAsset),
      translatorFlow: translatorFlow ?? this.translatorFlow,
      currentConfidenceScore:
          clearConfidence ? 0 : (currentConfidenceScore ?? this.currentConfidenceScore),
      hasConfidence: clearConfidence ? false : (hasConfidence ?? this.hasConfidence),
      showUnderstandingCheck: clearUnderstandingCheck
          ? false
          : (showUnderstandingCheck ?? this.showUnderstandingCheck),
      understandingResponse: clearUnderstandingResponse
          ? null
          : (understandingResponse ?? this.understandingResponse),
      enqueuedReviewId:
          clearEnqueuedReviewId ? null : (enqueuedReviewId ?? this.enqueuedReviewId),
      correctionNotice:
          clearCorrectionNotice ? null : (correctionNotice ?? this.correctionNotice),
      currentFromTranslationMemory:
          currentFromTranslationMemory ?? this.currentFromTranslationMemory,
    );
  }

  @override
  List<Object?> get props => [
        targetLanguage,
        isRecording,
        isProcessing,
        currentInputHindi,
        currentTranslationResult,
        conversationHistory,
        quickPhrases,
        activeCategory,
        isOfflineNmt,
        latencyMs,
        feedbackSubmitted,
        isLocalPrototype,
        localAudioAsset,
        localPhraseId,
        translationError,
        direction,
        asrTranscript,
        asrInferenceMs,
        asrModelLoaded,
        generatedLatencyMs,
        actualDelayMs,
        currentTranslationSecondary,
        currentInputSecondary,
        inputAudioAsset,
        translatorFlow,
        currentConfidenceScore,
        hasConfidence,
        showUnderstandingCheck,
        understandingResponse,
        enqueuedReviewId,
        correctionNotice,
        currentFromTranslationMemory,
      ];
}

// BLOC
class TranslationBloc extends Bloc<TranslationEvent, TranslationState> {
  final TranslationRepository translationRepository;

  /// Offline prototype demo config. When present and the target is Santali,
  /// final Hindi results use the ACTIVE demo scenario directly — no phrase
  /// matching, no network, no Sarvam. Null = legacy repository flow
  /// (keeps existing tests and non-demo builds unchanged).
  final PrototypeDemoTranslationRepository? demoTranslation;
  final SantaliAudioPlayer? santaliAudioPlayer;

  /// Real on-device ASR (MethodChannel → ONNX Runtime). Null in legacy/tests
  /// without ASR — then the mic reports "unavailable" instead of faking.
  final OfflineAsrService? asrService;

  /// Master bidirectional phrase bank (null = legacy demo/repository flow).
  final SantaliPhraseBankRepository? phraseBank;

  final BidirectionalPhraseMatcher matcher;

  /// Master bidirectional JSON phrase bank for the deterministic tap
  /// Translator (null = that path reports "unavailable"; legacy demo /
  /// repository flows keep working for older tests).
  final BidirectionalPhraseBank? bidirectionalBank;

  /// Local Reviewer Queue (§7). Null in legacy tests without the loop.
  final ReviewQueueStore? reviewQueue;

  /// Local Translation Memory (§12/§14). Null in legacy tests without it.
  final TranslationMemoryStore? translationMemory;

  /// Teacher-portal correction notices (§13). Null in legacy tests.
  final CorrectionNoticeStore? correctionNotices;

  /// Double-tap detection window: a second tap inside this window after the
  /// first turns the interaction into Santali → Hindi.
  static const Duration translatorTapWindow = Duration(milliseconds: 350);

  /// Pending single-tap window timer (null when no tap is being held).
  Timer? _tapTimer;

  /// Generation token for the tap Translator: every new tap bumps it, so a
  /// previous pending timer/result can never appear after a new interaction.
  int _translatorGen = 0;

  /// Generation captured when the first-tap hold starts. The window-elapsed
  /// handler enters Listening only when this still matches [_translatorGen],
  /// so a newer interaction (e.g. a double tap) can never be followed by a
  /// stale Listening state.
  int _tapHoldGen = 0;

  /// Random prototype response delay bounds (§18): 1500–2150 ms inclusive.
  /// Exactly ONE value is generated per successful match and awaited exactly.
  static const int prototypeDelayMinMs = 1500;
  static const int prototypeDelayMaxMs = 2150;

  /// Injectable randomness (tests seed determinism via subclasses if needed).
  final Random random;

  /// Fixed presentation delay for AUTOMATIC first playback after final ASR
  /// (manual replay is always immediate). Defaults to exactly 1970 ms.
  final Duration autoPlayDelay;

  /// Generation token: every new recording / final result / replay bumps it.
  /// A pending delayed auto-play starts only if its token is still current,
  /// so a new utterance during the wait cancels the old audio.
  int _demoGen = 0;

  TribalLanguage _activeLanguage = TribalLanguage.mundari;
  final List<TranslationMessage> _history = [
    TranslationMessage(
      id: 'init_1',
      isTeacher: true,
      speakerName: 'Teacher (Hindi)',
      originalText: 'नमस्ते बच्चों! सब अपनी किताब खोलो।',
      translatedText: 'जोहार होनको! सबिन आपन पुथी उगुइपे।',
      targetLanguage: TribalLanguage.mundari,
      timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      latencyMs: 110,
      isOfflineNmt: true,
    ),
    TranslationMessage(
      id: 'init_2',
      isTeacher: false,
      speakerName: 'Student (Mundari)',
      originalText: 'होनको काजी: "जोहार गुरुजी, बु उगुइकेदा।"',
      translatedText: 'नमस्ते गुरुजी, हमने अपनी पुस्तक खोल ली है।',
      targetLanguage: TribalLanguage.mundari,
      timestamp: DateTime.now().subtract(const Duration(minutes: 4)),
      latencyMs: 135,
      isOfflineNmt: true,
    ),
  ];

  TranslationBloc({
    required this.translationRepository,
    this.demoTranslation,
    this.santaliAudioPlayer,
    this.autoPlayDelay = const Duration(milliseconds: 1970),
    this.asrService,
    this.phraseBank,
    this.bidirectionalBank,
    this.reviewQueue,
    this.translationMemory,
    this.correctionNotices,
    BidirectionalPhraseMatcher? matcher,
    Random? random,
  })  : matcher = matcher ?? BidirectionalPhraseMatcher(),
        random = random ?? Random(),
        super(TranslationInitial()) {
    on<InitTranslationSession>((event, emit) async {
      emit(TranslationLoading());
      final phrases = await translationRepository.getQuickPhrases();
      // Initial card state: empty transcript, "Waiting for teacher..." is
      // rendered by the UI. No Santali output, no audio handle, no error —
      // nothing may play or fail before the first final ASR result.
      emit(TranslationSessionActive(
        targetLanguage: _activeLanguage,
        isRecording: false,
        currentInputHindi: '',
        currentTranslationResult: '',
        conversationHistory: List.from(_history),
        quickPhrases: phrases,
      ));
      // Startup: log missing demo audio (never crash) + preload the demo
      // clip so first playback starts instantly after final ASR.
      final demoRepo = demoTranslation;
      if (demoRepo != null) {
        try {
          final missing = await demoRepo.validateAssets();
          final demos = await demoRepo.allDemos();
          final playable = demos
              .map((d) => d.audio)
              .where((a) => !missing.contains(a))
              .toList();
          if (playable.isNotEmpty) {
            await santaliAudioPlayer?.preload(playable);
            debugPrint('[LocalSantaliPrototype] audioPreloaded=true '
                'count=${playable.length}');
          }
        } catch (e) {
          debugPrint('[LocalSantaliPrototype] initValidationFailed error=$e');
        }
      }
      // Preload active prototype phrase audio (Santali + Hindi clips) so
      // playback starts immediately after the presentation delay (§21).
      final bank = phraseBank;
      if (bank != null) {
        try {
          final phrases = await bank.load();
          final clips = <String>[];
          for (final p in phrases) {
            if (p.isLocalAudio) clips.add(p.audio);
            if (p.isLocalHindiAudio) clips.add(p.hindiAudio);
          }
          if (clips.isNotEmpty) {
            await santaliAudioPlayer?.preload(clips);
            debugPrint('[BidirectionalPrototype] audioPreloaded=true '
                'count=${clips.length}');
          }
        } catch (e) {
          debugPrint('[BidirectionalPrototype] preloadFailed error=$e');
        }
      }
      // Preload the deterministic tap-Translator clips (Santali + Hindi)
      // so playback starts immediately after the presentation delay.
      final tapBank = bidirectionalBank;
      if (tapBank != null) {
        try {
          final phrases = await tapBank.load();
          final clips = <String>[];
          for (final p in phrases) {
            if (p.hasSantaliAudio &&
                BidirectionalPhrase.isLocalAudio(p.santaliAudio)) {
              clips.add(p.santaliAudio);
            }
            if (p.hasHindiAudio &&
                BidirectionalPhrase.isLocalAudio(p.hindiAudio)) {
              clips.add(p.hindiAudio);
            }
          }
          if (clips.isNotEmpty) {
            await santaliAudioPlayer?.preload(clips);
            debugPrint('[BidirectionalTranslator] audioPreloaded=true '
                'count=${clips.length}');
          }
        } catch (e) {
          debugPrint('[BidirectionalTranslator] preloadFailed error=$e');
        }
      }
    });

    // The handler AWAITS the flow: bloc's emitter may only be used while
    // its handler is still running (an unawaited future would emit after
    // completion and trip an assertion in debug builds). Events are still
    // processed concurrently by default, so a new tap is never queued
    // behind an in-flight 1.5–2.15 s wait — it bumps [_translatorGen] and
    // supersedes the running flow immediately.
    on<TranslatorButtonTapped>((event, emit) async {
      if (state is! TranslationSessionActive) return;
      final current = state as TranslationSessionActive;
      
      // If currently recording, this is a STOP tap.
      // Determine which flow to run based on translatorFlow state.
      if (current.isRecording) {
        _translatorGen++;
        _tapTimer?.cancel();
        _tapTimer = null;
        // Best-effort stop; the winning flow restarts playback explicitly.
        unawaited(santaliAudioPlayer?.stop());
        
        // If this is a Santali → Hindi flow (started by double-tap),
        // run the Santali → Hindi translation (phrase_001).
        if (current.translatorFlow == 'sat_to_hi') {
          await _runTranslatorFlow(
              santaliToHindi: true, current: current, emit: emit);
        } else {
          // Otherwise it's a Hindi → Santali flow (single tap, phrase_002).
          await _runTranslatorFlow(
              santaliToHindi: false, current: current, emit: emit);
        }
        return;
      }
      
      // Any new tap cancels the previous pending translation: an old
      // result must never appear after a new interaction.
      _translatorGen++;
      final wasHeld = _tapTimer?.isActive ?? false;
      _tapTimer?.cancel();
      _tapTimer = null;
      // Best-effort stop; playback is restarted explicitly by the flow
      // that wins the latest generation.
      unawaited(santaliAudioPlayer?.stop());
      
      if (wasHeld) {
        // Idle + quick second tap = DOUBLE tap → Start SANTALI LISTENING.
        // Do NOT run the translation yet! Just enter listening state.
        // The translation will start on the NEXT tap (Tap 3).
        debugPrint('[BidirectionalTranslator] doubleTap detected, starting Santali listening');
        emit(current.copyWith(
          isRecording: true,
          isProcessing: false,
          currentInputHindi: '',
          currentInputSecondary: '',
          clearInputAudio: true,
          currentTranslationResult: '',
          currentTranslationSecondary: '',
          generatedLatencyMs: 0,
          actualDelayMs: 0,
          clearTranslationError: true,
          translatorFlow: 'sat_to_hi',
        ));
        return;
      }
      
      // Idle + first tap: clear any stale preparing/output/input state and
      // hold briefly so a possible second tap can still arrive. NOTHING is
      // shown yet — Listening begins only when the window elapses with no
      // second tap (so a double tap never flashes Listening first).
      emit(current.copyWith(
        isRecording: false,
        isProcessing: false,
        currentInputHindi: '',
        currentInputSecondary: '',
        clearInputAudio: true,
        currentTranslationResult: '',
        currentTranslationSecondary: '',
        generatedLatencyMs: 0,
        actualDelayMs: 0,
        clearTranslationError: true,
        translatorFlow: '',
      ));
      _tapHoldGen = _translatorGen;
      final holdGen = _tapHoldGen;
      _tapTimer = Timer(translatorTapWindow, () {
        _tapTimer = null;
        if (holdGen == _translatorGen) {
          add(TranslatorTapWindowElapsed());
        }
      });
      debugPrint('[BidirectionalTranslator] tapHeld windowMs='
          '${translatorTapWindow.inMilliseconds}');
    });

    on<TranslatorTapWindowElapsed>((event, emit) {
      if (state is! TranslationSessionActive) return;
      if (_tapHoldGen != _translatorGen) return;
      final current = state as TranslationSessionActive;
      // A newer interaction (double tap / stop tap) superseded the hold.
      if (current.isRecording || current.isProcessing) return;
      // Enter Listening/Recording for Hindi → Santali single tap flow.
      // No input phrase, no output, no latency — those appear only after stop.
      debugPrint('[BidirectionalTranslator] state=LISTENING (Hindi)');
      emit(current.copyWith(
        isRecording: true,
        isProcessing: false,
        currentInputHindi: '',
        currentInputSecondary: '',
        clearInputAudio: true,
        currentTranslationResult: '',
        currentTranslationSecondary: '',
        generatedLatencyMs: 0,
        actualDelayMs: 0,
        clearTranslationError: true,
        translatorFlow: 'hi_to_sat',
      ));
    });

    on<SwitchTranslatorDirection>((event, emit) async {
      // Direction switch releases the previous ASR model (one at a time),
      // stops audio, cancels pending output, resets both cards to waiting.
      _demoGen++;
      try {
        await santaliAudioPlayer?.stop();
      } catch (_) {}
      try {
        await asrService?.release();
      } catch (_) {}
      if (state is TranslationSessionActive) {
        final current = state as TranslationSessionActive;
        debugPrint('[OfflineASR] directionSwitched '
            'direction=${event.direction.name}');
        emit(current.copyWith(
          direction: event.direction,
          isRecording: false,
          isProcessing: false,
          currentInputHindi: '',
          currentTranslationResult: '',
          currentTranslationSecondary: '',
          asrTranscript: '',
          asrInferenceMs: 0,
          asrModelLoaded: false,
          generatedLatencyMs: 0,
          actualDelayMs: 0,
          isLocalPrototype: false,
          clearLocalAudio: true,
          clearTranslationError: true,
        ));
      }
    });

    on<AsrFinalTranscript>((event, emit) async {
      // ONLY final transcripts arrive here — no partial event type exists,
      // so intermediate hypotheses can never trigger translation (§11).
      if (state is! TranslationSessionActive) return;
      await _runBidirectional(
        text: event.text,
        inferenceMs: event.inferenceMs,
        languageId: event.languageId,
        current: state as TranslationSessionActive,
        emit: emit,
      );
    });

    on<SwitchTargetLanguage>((event, emit) async {
      _activeLanguage = event.language;
      // A language switch invalidates any pending delayed auto-play.
      _demoGen++;
      if (state is TranslationSessionActive) {
        final current = state as TranslationSessionActive;
        // Switching language is NOT a final ASR event: never run the demo
        // or play audio here. Santali resets to the waiting state; other
        // targets keep the legacy repository re-translation.
        if (_activeLanguage == TribalLanguage.santali) {
          try {
            await santaliAudioPlayer?.stop();
          } catch (_) {}
          emit(current.copyWith(
            targetLanguage: _activeLanguage,
            isRecording: false,
            isProcessing: false,
            currentInputHindi: '',
            currentTranslationResult: '',
            isLocalPrototype: false,
            clearLocalAudio: true,
            clearTranslationError: true,
          ));
          return;
        }
        final updatedMsg = await translationRepository.translateUtterance(
          text: current.currentInputHindi,
          targetLanguage: _activeLanguage,
          isTeacher: true,
        );
        emit(current.copyWith(
          targetLanguage: _activeLanguage,
          currentTranslationResult: updatedMsg.translatedText,
          isLocalPrototype: false,
          clearLocalAudio: true,
          clearTranslationError: true,
        ));
      }
    });

    on<ToggleTeacherMicRecord>((event, emit) async {
      if (state is TranslationSessionActive) {
        final current = state as TranslationSessionActive;
        final asr = asrService;
        final bank = phraseBank;
        // Real on-device ASR path (normal prototype path). The legacy
        // demo/repository flow below only runs when no ASR service + phrase
        // bank are wired (older tests / non-ASR builds).
        if (asr != null && bank != null) {
          await _handleMicTapRealAsr(current: current, emit: emit);
          return;
        }
        if (!current.isRecording) {
          // LISTENING. Cancel any pending delayed auto-play, stop any
          // previous clip, clear the previous result / error / audio
          // handle, then show Listening. Nothing plays while speaking.
          _demoGen++;
          try {
            await santaliAudioPlayer?.stop();
          } catch (_) {}
          debugPrint('[LocalSantaliPrototype] state=LISTENING');
          emit(current.copyWith(
            isRecording: true,
            isProcessing: false,
            currentInputHindi: current.currentInputHindi,
            currentTranslationResult: '',
            isLocalPrototype: false,
            clearLocalAudio: true,
            clearTranslationError: true,
          ));
        } else {
          // Speech ended -> final ASR result (LEGACY path: only when no
          // ASR service + phrase bank are wired, e.g. older unit tests).
          // The normal prototype path uses _handleMicTapRealAsr above with
          // real on-device inference — never a hardcoded string.
          const teacherUtterance = 'सूरज पूरब से निकलता है।';
          final handled = await _runPrototypeDemo(
            text: teacherUtterance,
            current: current,
            emit: emit,
          );
          if (handled) return;
          final result = await translationRepository.translateUtterance(
            text: teacherUtterance,
            targetLanguage: current.targetLanguage,
            isTeacher: true,
          );
          final newHistory = List<TranslationMessage>.from(current.conversationHistory)..add(result);
          emit(current.copyWith(
            isRecording: false,
            currentInputHindi: teacherUtterance,
            currentTranslationResult: result.translatedText,
            conversationHistory: newHistory,
            isLocalPrototype: false,
            clearLocalAudio: true,
            clearTranslationError: true,
          ));
        }
      }
    });

    on<SendTeacherCustomUtterance>((event, emit) async {
      if (state is TranslationSessionActive) {
        final current = state as TranslationSessionActive;
        final handled = await _runPrototypeDemo(
          text: event.text,
          current: current,
          emit: emit,
        );
        if (handled) return;
        final result = await translationRepository.translateUtterance(
          text: event.text,
          targetLanguage: current.targetLanguage,
          isTeacher: true,
        );
        final newHistory = List<TranslationMessage>.from(current.conversationHistory)..add(result);
        emit(current.copyWith(
          currentInputHindi: event.text,
          currentTranslationResult: result.translatedText,
          conversationHistory: newHistory,
          isLocalPrototype: false,
          clearLocalAudio: true,
          clearTranslationError: true,
        ));
      }
    });

    on<ReplayLocalSantaliAudio>((event, emit) async {
      if (state is TranslationSessionActive) {
        final current = state as TranslationSessionActive;
        final player = santaliAudioPlayer;
        if (player == null || current.localAudioAsset == null) return;
        try {
          // Manual replay: immediate local playback (never the 1.97 s
          // automatic delay) and it supersedes any pending auto-play.
          _demoGen++;
          await player.replay();
          emit(current.copyWith(clearTranslationError: true));
        } catch (e) {
          debugPrint('[LocalSantaliPrototype] replayFailed error=$e');
          emit(current.copyWith(
              translationError: 'Could not play Santali audio.'));
        }
      }
    });

    on<ReplayTranslatorInputAudio>((event, emit) async {
      if (state is TranslationSessionActive) {
        final current = state as TranslationSessionActive;
        final player = santaliAudioPlayer;
        final asset = current.inputAudioAsset;
        if (player == null || asset == null || asset.isEmpty) return;
        try {
          // Manual input replay: immediate local playback, never a new
          // presentation latency.
          await player.playAsset(asset);
          emit(current.copyWith(clearTranslationError: true));
        } catch (e) {
          debugPrint('[BidirectionalTranslator] inputReplayFailed '
              'asset=$asset error=$e');
          emit(current.copyWith(
              translationError: 'Could not play input audio.'));
        }
      }
    });

    on<UsePhraseBankPhraseInLiveLesson>((event, emit) async {
      if (state is TranslationSessionActive) {
        final current = state as TranslationSessionActive;
        // A new classroom broadcast supersedes any pending delayed auto-play
        // and stops any currently playing clip (no overlap).
        _demoGen++;
        try {
          await santaliAudioPlayer?.stop();
        } catch (_) {}
        _activeLanguage = TribalLanguage.santali;
        final ol = event.santaliOlChiki.trim();
        final roman = event.santaliRoman.trim();
        // Never fabricate: missing verified text stays visibly "Not provided".
        final display =
            ol.isNotEmpty ? ol : (roman.isNotEmpty ? roman : 'Not provided');
        final msg = TranslationMessage(
          id: 'phrase_${event.phraseId}_${DateTime.now().millisecondsSinceEpoch}',
          isTeacher: true,
          speakerName: 'Teacher (Hindi)',
          originalText: event.hindi,
          translatedText: display,
          targetLanguage: TribalLanguage.santali,
          timestamp: DateTime.now(),
          latencyMs: 0,
          isOfflineNmt: true,
        );
        final newHistory =
            List<TranslationMessage>.from(current.conversationHistory)
              ..add(msg);
        debugPrint('[SantaliPhraseBank] liveLesson phraseId=${event.phraseId} '
            'audio=${event.audioAsset}');
        emit(current.copyWith(
          targetLanguage: TribalLanguage.santali,
          isRecording: false,
          isProcessing: false,
          currentInputHindi: event.hindi,
          currentTranslationResult: display,
          conversationHistory: newHistory,
          isLocalPrototype: true,
          localAudioAsset: event.audioAsset,
          localPhraseId: event.phraseId,
          clearTranslationError: true,
        ));
        // Broadcast the phrase's OWN local clip immediately (manual teacher
        // action => immediate playback, never the automatic delay). Missing
        // / unplayable asset => texts stay visible, honest error shown.
        try {
          await santaliAudioPlayer?.playAsset(event.audioAsset);
        } catch (e) {
          debugPrint('[SantaliPhraseBank] liveLessonAudioFailed '
              'asset=${event.audioAsset} error=$e');
          if (state is TranslationSessionActive) {
            emit((state as TranslationSessionActive).copyWith(
                translationError: 'Audio unavailable for this phrase.'));
          }
        }
      }
    });

    on<TriggerStudentResponseSimulation>((event, emit) async {
      if (state is TranslationSessionActive) {
        final current = state as TranslationSessionActive;
        final studentMsg = await translationRepository.translateUtterance(
          text: 'Student speaks in ${_activeLanguage.displayName}',
          targetLanguage: current.targetLanguage,
          isTeacher: false,
        );
        final newHistory = List<TranslationMessage>.from(current.conversationHistory)..add(studentMsg);
        emit(current.copyWith(
          conversationHistory: newHistory,
        ));
      }
    });

    on<LoadQuickPhrases>((event, emit) async {
      if (state is TranslationSessionActive) {
        final current = state as TranslationSessionActive;
        final phrases = await translationRepository.getQuickPhrases(category: event.category);
        emit(current.copyWith(
          quickPhrases: phrases,
          activeCategory: event.category,
        ));
      }
    });

    on<SubmitTranslationFeedbackEvent>((event, emit) async {
      if (state is TranslationSessionActive) {
        final current = state as TranslationSessionActive;
        await translationRepository.submitFeedback(
          original: event.original,
          translated: event.translated,
          issueType: event.issueType,
          comment: event.comment,
        );
        emit(current.copyWith(feedbackSubmitted: true));
      }
    });

    // ==========================================================================
    // CONFIDENCE + UNDERSTANDING CHECK + REVIEW LOOP (offline demo)
    // ==========================================================================

    /// §5: human validation layer. YES = understood (continue teaching, no
    /// queue entry); NO = create a review item and send it to the local
    /// Reviewer Queue with priority derived from the phrase confidence.
    on<UnderstandingCheckAnswered>((event, emit) {
      if (state is! TranslationSessionActive) return;
      final current = state as TranslationSessionActive;
      if (!current.showUnderstandingCheck) return;
      final localPhraseId = current.localPhraseId;
      if (localPhraseId == null || localPhraseId.isEmpty) return;
      String? reviewId;
      if (!event.understood) {
        final queue = reviewQueue;
        if (queue != null) {
          final item = queue.enqueue(
            phraseId: localPhraseId,
            direction: current.translatorFlow == 'sat_to_hi'
                ? ReviewDirection.santaliToHindi
            : ReviewDirection.hindiToSantali,
            originalText: current.currentInputHindi,
            originalRoman: current.currentInputSecondary,
            translatedText: current.currentTranslationResult,
            translatedRoman: current.currentTranslationSecondary,
            confidenceScore: current.currentConfidenceScore,
            reason: current.translatorFlow == 'sat_to_hi'
                ? 'Teacher did not understand the translation'
                : 'Student did not understand the translation',
            audioAsset: current.inputAudioAsset,
          );
          reviewId = item.id;
        }
      }
      emit(current.copyWith(
        showUnderstandingCheck: false,
        understandingResponse: event.understood
            ? UnderstandingResponse.understood
            : UnderstandingResponse.notUnderstood,
        enqueuedReviewId: reviewId,
        clearEnqueuedReviewId: reviewId == null,
      ));
    });

    /// §13: teacher opens the corrected translation. The corrected text
    /// becomes the current result (flagged Expert Verified) and any pending
    /// queue entries for the phrase are resolved.
    on<ApplyCorrectionNotice>((event, emit) {
      if (state is! TranslationSessionActive) return;
      final current = state as TranslationSessionActive;
      final notices = correctionNotices;
      final memory = translationMemory;
      CorrectionNotice? notice;
      for (final n in (notices?.all ?? const <CorrectionNotice>[])) {
        if (n.reviewId == event.reviewId) {
          notice = n;
          break;
        }
      }
      final entry = memory?.correctionFor(notice?.phraseId ?? '');
      if (notice == null || entry == null) return;
      notices!.markConsumed(event.reviewId);
      reviewQueue?.resolvePendingForPhrase(entry.phraseId);
      emit(current.copyWith(
        currentTranslationResult: entry.correctedTranslation,
        currentConfidenceScore: current.currentConfidenceScore,
        hasConfidence: current.hasConfidence,
        currentFromTranslationMemory: true,
        correctionNotice: null,
        clearCorrectionNotice: true,
      ));
      debugPrint('[ReviewLoop] correctionApplied reviewId=${event.reviewId} '
          'phraseId=${entry.phraseId}');
    });

    /// Clears the correction card without applying it.
    on<DismissCorrectionNotice>((event, emit) {
      if (state is! TranslationSessionActive) return;
      final current = state as TranslationSessionActive;
      emit(current.copyWith(clearCorrectionNotice: true));
    });

    /// Pulls any Translation-Memory correction for the current phrase into
    /// the UI (e.g. when the teacher returns from the Reviewer Portal).
    on<RefreshCorrectionsFromMemory>((event, emit) {
      if (state is! TranslationSessionActive) return;
      final current = state as TranslationSessionActive;
      final memory = translationMemory;
      final localPhraseId = current.localPhraseId;
      final entry = (memory != null && localPhraseId != null && localPhraseId.isNotEmpty)
          ? memory.correctionFor(localPhraseId)
          : null;
      final notices = correctionNotices;
      final activeNotice = (notices != null && notices.unconsumed.isNotEmpty)
          ? notices.unconsumed.first
          : null;
      emit(current.copyWith(
        currentFromTranslationMemory: entry != null,
        correctionNotice: activeNotice,
        clearCorrectionNotice: activeNotice == null,
      ));
    });
  }

  @override
  Future<void> close() {
    _tapTimer?.cancel();
    _tapTimer = null;
    return super.close();
  }

  /// Deterministic tap Translator flow (NO ASR, NO ONNX, NO models,
  /// NO network, NO Sarvam, NO TTS — local JSON bank + bundled WAV only).
  ///
  /// [santaliToHindi] false (single tap): `phrase_002` Hindi input →
  /// "Preparing translation..." → wait the ONE generated latency →
  /// Santali Ol Chiki + Roman + local Santali audio.
  ///
  /// [santaliToHindi] true (double tap): `phrase_001` Santali input (local
  /// Santali clip does NOT play during double-tap; remains hidden until
  /// after the latency delay; playable via speaker/replay control after
  /// result is shown) → ONE generated latency → Hindi + Hindi Roman +
  /// local Hindi audio.
  ///
  /// Records are resolved data-driven via firstWhere on the loaded JSON
  /// (see [BidirectionalPhraseBank.hindiToSantali]/[santaliToHindi]) — no
  /// Hindi/Santali sentence is hardcoded in Dart. Translated text/audio
  /// appear ONLY after the exact generated delay, and only when this call
  /// still owns the latest [_translatorGen]. The displayed latency is the
  /// same stored value that was awaited.
  Future<void> _runTranslatorFlow({
    required bool santaliToHindi,
    required TranslationSessionActive current,
    required Emitter<TranslationState> emit,
  }) async {
    final bank = bidirectionalBank;
    final flow = santaliToHindi ? 'sat_to_hi' : 'hi_to_sat';
    _translatorGen++;
    final gen = _translatorGen;
    try {
      await santaliAudioPlayer?.stop();
    } catch (_) {}
    // A newer interaction superseded this flow while the old clip was
    // stopping: stale async work must never touch the UI again.
    if (gen != _translatorGen) {
      debugPrint('[BidirectionalTranslator] flow=$flow cancelled=true');
      return;
    }
    if (bank == null) {
      emit(current.copyWith(
        isRecording: false,
        isProcessing: false,
        translatorFlow: flow,
        translationError:
            'Translation unavailable for this prototype phrase.',
      ));
      return;
    }
    final phrases = await bank.load();
    if (gen != _translatorGen) return;
    // Data-driven resolution: single tap → phrase_002, double tap →
    // phrase_001. Missing IDs surface the unavailable message, never a
    // crash and never a guessed translation.
    final record = santaliToHindi
        ? bank.santaliToHindi(phrases)
        : bank.hindiToSantali(phrases);
    if (record == null) {
      final missingId = santaliToHindi
          ? BidirectionalPhraseBank.santaliToHindiId
          : BidirectionalPhraseBank.hindiToSantaliId;
      debugPrint('[BidirectionalTranslator] flow=$flow '
          'missingPhraseId=$missingId');
      emit(current.copyWith(
        isRecording: false,
        isProcessing: false,
        translatorFlow: flow,
        translationError:
            'Translation unavailable for this prototype phrase.',
      ));
      return;
    }
    debugPrint('[BidirectionalTranslator] flow=$flow '
        'phraseId=${record.id}');

    // Input state: the preselected JSON phrase (never recognized speech,
    // never a confidence score). Translation stays hidden until after the
    // delay.
    final inputDisplay =
        santaliToHindi ? record.santaliOlChiki : record.hindi;
    final inputSecondary =
        santaliToHindi ? record.santaliRoman : record.hindiRoman;
    final inputAudio =
        santaliToHindi ? record.santaliAudio : record.hindiAudio;
    emit(current.copyWith(
      isRecording: false,
      isProcessing: true,
      currentInputHindi: inputDisplay,
      currentInputSecondary: inputSecondary,
      inputAudioAsset: inputAudio.isNotEmpty ? inputAudio : null,
      clearInputAudio: inputAudio.isEmpty,
      asrTranscript: '',
      currentTranslationResult: '',
      currentTranslationSecondary: '',
      generatedLatencyMs: 0,
      actualDelayMs: 0,
      isLocalPrototype: false,
      clearLocalAudio: true,
      clearTranslationError: true,
      translatorFlow: flow,
      // Fresh interaction: previous loop signals never leak through.
      clearConfidence: true,
      showUnderstandingCheck: false,
      clearUnderstandingResponse: true,
      clearEnqueuedReviewId: true,
      currentFromTranslationMemory: false,
      clearCorrectionNotice: true,
    ));

    // Santali → Hindi: the local Santali clip does NOT play during the
    // initial double-tap. The input representation remains hidden until the
    // translation delay finishes. The existing local audio is available
    // through the existing speaker/replay control after the result is shown.

    // ONE random latency per interaction (1500–2150 ms inclusive), stored,
    // awaited exactly, displayed exactly.
    final latencyMs = random.nextInt(651) + 1500;
    final generatedMs = latencyMs;
    final tDelay0 = DateTime.now();
    emit(current.copyWith(
      isRecording: false,
      isProcessing: true,
      currentInputHindi: inputDisplay,
      currentInputSecondary: inputSecondary,
      inputAudioAsset: inputAudio.isNotEmpty ? inputAudio : null,
      clearInputAudio: inputAudio.isEmpty,
      asrTranscript: '',
      generatedLatencyMs: generatedMs,
      actualDelayMs: 0,
      translatorFlow: flow,
      clearTranslationError: true,
    ));
    debugPrint('[BidirectionalTranslator] flow=$flow phraseId=${record.id} '
        'generatedLatencyMs=$generatedMs');
    await Future.delayed(Duration(milliseconds: generatedMs));
    if (gen != _translatorGen) {
      debugPrint('[BidirectionalTranslator] flow=$flow phraseId=${record.id} '
          'pendingResultCancelled=true');
      return;
    }
    final actualMs = DateTime.now().difference(tDelay0).inMilliseconds;

    // §14 Translation Memory check: once a reviewer correction exists for
    // this phrase, every FUTURE translation uses the corrected text — the
    // original phrase-bank translation is superseded.
    final memoryEntry = translationMemory?.correctionFor(record.id);
    final fromMemory = memoryEntry != null;

    final String primary;
    final String secondary;
    final String audioAsset;
    if (santaliToHindi) {
      primary = memoryEntry?.correctedTranslation ?? record.hindi;
      secondary = record.hindiRoman;
      audioAsset = record.hindiAudio;
    } else {
      primary = memoryEntry?.correctedTranslation ??
          (record.santaliOlChiki.isNotEmpty
              ? record.santaliOlChiki
              : record.santaliRoman);
      secondary = record.santaliRoman;
      audioAsset = record.santaliAudio;
    }
    emit(current.copyWith(
      isRecording: false,
      isProcessing: false,
      currentInputHindi: inputDisplay,
      currentInputSecondary: inputSecondary,
      inputAudioAsset: inputAudio.isNotEmpty ? inputAudio : null,
      clearInputAudio: inputAudio.isEmpty,
      asrTranscript: '',
      currentTranslationResult: primary,
      currentTranslationSecondary: secondary,
      generatedLatencyMs: generatedMs,
      actualDelayMs: actualMs,
      latencyMs: actualMs,
      isLocalPrototype: true,
      localAudioAsset: audioAsset.isNotEmpty ? audioAsset : null,
      localPhraseId: record.id,
      clearTranslationError: true,
      // Never retain a previous phrase's clip when this one has none.
      clearLocalAudio: audioAsset.isEmpty,
      translatorFlow: flow,
      // §3 Confidence: exact value from the phrase JSON (deterministic).
      currentConfidenceScore: record.confidenceScore,
      hasConfidence: true,
      // §5 Understanding Check appears with the result + confidence.
      showUnderstandingCheck: true,
      clearUnderstandingResponse: true,
      clearEnqueuedReviewId: true,
      // §14 flag: this result came from an expert correction.
      currentFromTranslationMemory: fromMemory,
    ));

    var audioStarted = false;
    if (audioAsset.isNotEmpty) {
      try {
        await santaliAudioPlayer?.playAsset(audioAsset);
        audioStarted = true;
      } catch (e) {
        debugPrint('[BidirectionalTranslator] flow=$flow '
            'phraseId=${record.id} audioFailed error=$e');
        // Never surface a stale playback error on a newer interaction.
        if (gen == _translatorGen && state is TranslationSessionActive) {
          emit((state as TranslationSessionActive).copyWith(
              translationError: 'Could not play translated audio.'));
        }
      }
    } else if (state is TranslationSessionActive) {
      emit((state as TranslationSessionActive).copyWith(
          translationError: 'Could not play translated audio.'));
    }
    final audioStartMs = DateTime.now().difference(tDelay0).inMilliseconds;
    debugPrint('[BidirectionalTranslator] flow=$flow phraseId=${record.id} '
        'generatedLatencyMs=$generatedMs actualDelayMs=$actualMs '
        'audioStarted=$audioStarted audioStartMs=$audioStartMs');

    final msg = TranslationMessage(
      id: 'tap_${record.id}_${DateTime.now().millisecondsSinceEpoch}',
      isTeacher: !santaliToHindi,
      speakerName: santaliToHindi ? 'Student (Santali)' : 'Teacher (Hindi)',
      originalText: inputDisplay,
      translatedText:
          secondary.isNotEmpty ? '$primary\n$secondary' : primary,
      targetLanguage: current.targetLanguage,
      timestamp: DateTime.now(),
      latencyMs: actualMs,
      isOfflineNmt: true,
    );
    // Stale-request guard: a new interaction during playback means this
    // finished flow is superseded — it must not write into the new state.
    if (gen == _translatorGen && state is TranslationSessionActive) {
      final latest = state as TranslationSessionActive;
      final newHistory =
          List<TranslationMessage>.from(latest.conversationHistory)..add(msg);
      emit(latest.copyWith(conversationHistory: newHistory));
    }
  }

  /// Real on-device ASR mic lifecycle (§10–§12, §25).
  ///
  /// First tap: lazily init the direction's model (once, then reused) and
  /// start native 16 kHz mono recording → LISTENING. Second tap: stop the
  /// mic, run inference, dispatch the FINAL transcript only. Partials never
  /// exist on this path. Tapping while PROCESSING cancels pending output
  /// and returns to LISTENING (new speech supersedes).
  Future<void> _handleMicTapRealAsr({
    required TranslationSessionActive current,
    required Emitter<TranslationState> emit,
  }) async {
    final asr = asrService!;
    final asrLang = current.direction == TranslatorDirection.studentToTeacher
        ? OfflineAsrLanguage.santali
        : OfflineAsrLanguage.hindi;

    if (current.isProcessing) {
      // New speech cancels pending output (§test 14): bump the generation
      // so the delayed timer can never fire afterwards.
      _demoGen++;
      final startErr = await asr.startRecording(asrLang);
      if (startErr != null) {
        emit(current.copyWith(
          isRecording: false,
          isProcessing: false,
          translationError: offlineAsrUserMessage(startErr),
        ));
        return;
      }
      try {
        await santaliAudioPlayer?.stop();
      } catch (_) {}
      debugPrint('[OfflineASR] direction=${asrLang.direction} '
          'language=${asrLang.languageId} state=LISTENING (cancelled pending)');
      emit(current.copyWith(
        isRecording: true,
        isProcessing: false,
        currentTranslationResult: '',
        currentTranslationSecondary: '',
        isLocalPrototype: false,
        clearLocalAudio: true,
        clearTranslationError: true,
      ));
      return;
    }

    if (!current.isRecording) {
      // LISTENING: stop previous audio, clear cards, lazy-load model once.
      _demoGen++;
      try {
        await santaliAudioPlayer?.stop();
      } catch (_) {}
      emit(current.copyWith(
        isRecording: false,
        isProcessing: true,
        currentTranslationResult: '',
        currentTranslationSecondary: '',
        isLocalPrototype: false,
        clearLocalAudio: true,
        clearTranslationError: true,
      ));
      final loadMs = await asr.ensureLoaded(asrLang);
      if (state is! TranslationSessionActive) return;
      final loading = state as TranslationSessionActive;
      if (loadMs < 0) {
        if (kDebugSimulatedAsr) {
          debugPrint('[OfflineASR] DEBUG fallback armed (no model)');
        } else {
          debugPrint('[OfflineASR] direction=${asrLang.direction} '
              'language=${asrLang.languageId} modelLoaded=false');
          emit(loading.copyWith(
            isRecording: false,
            isProcessing: false,
            translationError: offlineAsrUserMessage('MODEL_UNAVAILABLE'),
          ));
          return;
        }
      }
      final startErr = loadMs < 0 ? null : await asr.startRecording(asrLang);
      if (startErr != null) {
        emit(loading.copyWith(
          isRecording: false,
          isProcessing: false,
          asrModelLoaded: loadMs >= 0,
          translationError: offlineAsrUserMessage(startErr),
        ));
        return;
      }
      debugPrint('[OfflineASR] direction=${asrLang.direction} '
          'language=${asrLang.languageId} modelLoaded=${loadMs >= 0} '
          'state=LISTENING');
      emit(loading.copyWith(
        isRecording: true,
        isProcessing: false,
        asrModelLoaded: loadMs >= 0 ? true : loading.asrModelLoaded,
      ));
      return;
    }

    // Speech ended → stop mic, run inference, handle the FINAL transcript.
    emit(current.copyWith(isRecording: false, isProcessing: true));
    final result = await asr.stopAndTranscribe();
    if (state is! TranslationSessionActive) return;
    if (!result.isOk) {
      // DEBUG-only fallback: exercise the translation/latency UI without
      // models. Release builds always take the error branch instead.
      if (kDebugSimulatedAsr && result.errorCode == 'MODEL_UNAVAILABLE') {
        debugPrint('[OfflineASR] DEBUG simulated final transcript');
        add(AsrFinalTranscript(
            text: kDebugSimulatedTranscript,
            inferenceMs: 0,
            languageId: asrLang.languageId));
        return;
      }
      emit((state as TranslationSessionActive).copyWith(
        isRecording: false,
        isProcessing: false,
        translationError: offlineAsrUserMessage(result.errorCode),
      ));
      return;
    }
    add(AsrFinalTranscript(
        text: result.transcript,
        inferenceMs: result.inferenceMs,
        languageId: asrLang.languageId));
  }

  /// FINAL ASR → phrase match → ONE random delay → output + audio (§13–§19).
  ///
  /// Translated text/audio appear ONLY after the exact generated delay.
  /// Unknown phrases show "Translation unavailable…" — never guessed.
  Future<void> _runBidirectional({
    required String text,
    required int inferenceMs,
    required String languageId,
    required TranslationSessionActive current,
    required Emitter<TranslationState> emit,
  }) async {
    final bank = phraseBank;
    if (bank == null) return;
    final fromStudent = current.direction == TranslatorDirection.studentToTeacher;

    // PROCESSING: transcript visible, translation hidden until after delay.
    emit(current.copyWith(
      isRecording: false,
      isProcessing: true,
      currentInputHindi: fromStudent ? current.currentInputHindi : text,
      asrTranscript: text,
      asrInferenceMs: inferenceMs,
      asrModelLoaded: true,
      currentTranslationResult: '',
      currentTranslationSecondary: '',
      clearTranslationError: true,
    ));

    final tMatch0 = DateTime.now();
    final phrases = await bank.load();
    BidirectionalMatch? match;
    if (fromStudent) {
      match = matcher.matchSantali(text, phrases);
    } else {
      match = matcher.matchHindi(text, phrases);
    }
    final matchMs =
        DateTime.now().difference(tMatch0).inMilliseconds;
    if (match == null) {
      debugPrint('[BidirectionalPrototype] matchedPhrase=none '
          'matchMs=$matchMs');
      emit(current.copyWith(
        isRecording: false,
        isProcessing: false,
        currentInputHindi: fromStudent ? current.currentInputHindi : text,
        asrTranscript: text,
        asrInferenceMs: inferenceMs,
        asrModelLoaded: true,
        translationError:
            'Translation unavailable for this prototype phrase.',
      ));
      return;
    }

    final phrase = match.phrase;
    debugPrint('[BidirectionalPrototype] matchedPhrase=${phrase.id} '
        'priority=${match.priority} matchMs=$matchMs');

    // ONE random presentation delay per successful match (§18). Stored,
    // awaited exactly, and displayed exactly — never regenerated for UI.
    _demoGen++;
    final gen = _demoGen;
    final generatedMs = prototypeDelayMinMs +
        random.nextInt(prototypeDelayMaxMs - prototypeDelayMinMs + 1);
    final tDelay0 = DateTime.now();
    emit(current.copyWith(
      isRecording: false,
      isProcessing: true,
      currentInputHindi: fromStudent ? current.currentInputHindi : text,
      asrTranscript: text,
      asrInferenceMs: inferenceMs,
      asrModelLoaded: true,
      generatedLatencyMs: generatedMs,
      actualDelayMs: 0,
      clearTranslationError: true,
    ));
    await Future.delayed(Duration(milliseconds: generatedMs));
    if (gen != _demoGen) {
      debugPrint('[BidirectionalPrototype] matchedPhrase=${phrase.id} '
          'pendingPlaybackCancelled=true');
      return;
    }
    final actualMs = DateTime.now().difference(tDelay0).inMilliseconds;

    // Output AFTER the exact delay (§18): never before, never unrelated audio.
    final String primary;
    final String secondary;
    final String audioAsset;
    if (fromStudent) {
      primary = phrase.hindi;
      secondary = phrase.english;
      audioAsset = phrase.hindiAudio;
    } else {
      primary = phrase.santaliOlChiki.isNotEmpty
          ? phrase.santaliOlChiki
          : phrase.santaliRoman;
      secondary = phrase.santaliRoman;
      audioAsset = phrase.audio;
    }
    emit(current.copyWith(
      isRecording: false,
      isProcessing: false,
      currentInputHindi: fromStudent ? current.currentInputHindi : text,
      asrTranscript: text,
      asrInferenceMs: inferenceMs,
      asrModelLoaded: true,
      currentTranslationResult: primary,
      currentTranslationSecondary: secondary,
      generatedLatencyMs: generatedMs,
      actualDelayMs: actualMs,
      latencyMs: actualMs,
      isLocalPrototype: true,
      localAudioAsset: audioAsset.isNotEmpty ? audioAsset : null,
      localPhraseId: phrase.id,
      clearTranslationError: true,
      // Never retain a previous phrase's clip when this one has none —
      // otherwise replay would play unrelated audio (§17).
      clearLocalAudio: audioAsset.isEmpty,
    ));

    var audioStarted = false;
    if (audioAsset.isNotEmpty) {
      try {
        await santaliAudioPlayer?.playAsset(audioAsset);
        audioStarted = true;
      } catch (e) {
        debugPrint('[BidirectionalPrototype] matchedPhrase=${phrase.id} '
            'audioFailed error=$e');
        if (state is TranslationSessionActive) {
          emit((state as TranslationSessionActive).copyWith(
              translationError: 'Could not play translated audio.'));
        }
      }
    } else {
      if (state is TranslationSessionActive) {
        emit((state as TranslationSessionActive).copyWith(
            translationError: 'Could not play translated audio.'));
      }
    }
    final audioStartMs =
        DateTime.now().difference(tDelay0).inMilliseconds;
    debugPrint('[BidirectionalPrototype] matchedPhrase=${phrase.id} '
        'generatedLatencyMs=$generatedMs actualDelayMs=$actualMs '
        'audioStarted=$audioStarted audioStartMs=$audioStartMs');

    final msg = TranslationMessage(
      id: 'asr_${phrase.id}_${DateTime.now().millisecondsSinceEpoch}',
      isTeacher: !fromStudent,
      speakerName: fromStudent ? 'Student (Santali)' : 'Teacher (Hindi)',
      originalText: text,
      translatedText:
          secondary.isNotEmpty ? '$primary\n$secondary' : primary,
      targetLanguage: current.targetLanguage,
      timestamp: DateTime.now(),
      latencyMs: actualMs,
      isOfflineNmt: true,
    );
    if (state is TranslationSessionActive) {
      final latest = state as TranslationSessionActive;
      final newHistory =
          List<TranslationMessage>.from(latest.conversationHistory)..add(msg);
      emit(latest.copyWith(conversationHistory: newHistory));
    }
  }

  /// Prototype demo flow for a FINAL Hindi result (speech already ended).
  ///
  /// SPEAK -> STOP -> FINAL ASR -> show Hindi -> show configured Santali ->
  /// play configured local audio. The recognized sentence is displayed
  /// as-is; the Santali output/audio ALWAYS come from the active demo
  /// scenario — the text is never matched, compared, or classified.
  ///
  /// Missing demo data -> "Translation unavailable." Missing/unplayable
  /// audio -> texts shown + "Audio unavailable for this translation."
  /// Nothing here touches the network. Returns true when handled.
  Future<bool> _runPrototypeDemo({
    required String text,
    required TranslationSessionActive current,
    required Emitter<TranslationState> emit,
  }) async {
    final demoRepo = demoTranslation;
    // Demo path serves Santali only; every other target and every build
    // without the config keeps the legacy repository flow.
    if (demoRepo == null || current.targetLanguage != TribalLanguage.santali) {
      return false;
    }
    // PROCESSING (speech has ended; no audio plays before this point).
    emit(current.copyWith(
      isRecording: false,
      isProcessing: true,
      currentInputHindi: text,
    ));
    final t0 = Stopwatch()..start(); // t0 = final ASR result available.
    debugPrint('[LocalSantaliPrototype] state=FINAL_ASR');
    final demo = await demoRepo.activeDemo();
    final localTranslationReadyMs = t0.elapsedMilliseconds;
    if (demo == null || !demo.hasVerifiedText) {
      debugPrint('[LocalSantaliPrototype] demoMissing '
          'localTranslationReadyMs=$localTranslationReadyMs');
      emit(current.copyWith(
        isRecording: false,
        isProcessing: false,
        currentInputHindi: text,
        targetLanguage: _activeLanguage,
        isLocalPrototype: false,
        clearLocalAudio: true,
        translationError: 'Translation unavailable.',
      ));
      return true;
    }
    final audioOk = await demoRepo.audioExists(demo);
    if (!audioOk) {
      debugPrint('[LocalSantaliPrototype] demoId=${demo.id} '
          'missingAsset=${demo.audio} '
          'localTranslationReadyMs=$localTranslationReadyMs');
      emit(current.copyWith(
        isRecording: false,
        isProcessing: false,
        currentInputHindi: text,
        currentTranslationResult: demo.santali,
        targetLanguage: _activeLanguage,
        isLocalPrototype: true,
        localAudioAsset: demo.audio,
        localPhraseId: demo.id,
        translationError: 'Audio unavailable for this translation.',
      ));
      return true;
    }
    try {
      // Texts first: Hindi transcript + configured Santali are visible
      // during the presentation wait; automatic audio has NOT started.
      _demoGen++;
      final gen = _demoGen;
      final finalAsrReceived = DateTime.now();
      debugPrint('[LocalSantaliPrototype] demoId=${demo.id} '
          'finalAsrReceived=$finalAsrReceived');
      emit(current.copyWith(
        isRecording: false,
        isProcessing: false,
        currentInputHindi: text,
        currentTranslationResult: demo.santali,
        targetLanguage: _activeLanguage,
        isLocalPrototype: true,
        localAudioAsset: demo.audio,
        localPhraseId: demo.id,
        latencyMs: 0,
        clearTranslationError: true,
      ));
      // Fixed presentation wait: starts ONLY at final ASR, never at
      // mic-tap / partials / screen open.
      final delayMs = autoPlayDelay.inMilliseconds;
      debugPrint('[LocalSantaliPrototype] demoId=${demo.id} '
          'scheduledAudioDelayMs=$delayMs');
      await Future.delayed(autoPlayDelay);
      if (gen != _demoGen) {
        // A new recording / result / replay superseded this timer: the old
        // audio must never start afterwards.
        debugPrint('[LocalSantaliPrototype] demoId=${demo.id} '
            'pendingPlaybackCancelled=true');
        return true;
      }
      // Automatic broadcast (previous clip stops inside playAsset, so two
      // clips can never overlap).
      debugPrint('[LocalSantaliPrototype] '
          'audioAsset=${demo.audio}');
      await santaliAudioPlayer?.playAsset(demo.audio);
    } catch (e) {
      // Real playback failure only: this branch runs solely because an
      // actual play attempt threw — never before speech ends.
      debugPrint('[LocalSantaliPrototype] demoId=${demo.id} '
          'autoPlayFailed error=$e');
      emit(current.copyWith(
        isRecording: false,
        isProcessing: false,
        currentInputHindi: text,
        currentTranslationResult: demo.santali,
        targetLanguage: _activeLanguage,
        isLocalPrototype: true,
        localAudioAsset: demo.audio,
        localPhraseId: demo.id,
        translationError: 'Could not play Santali audio.',
      ));
      return true;
    }
    final audioPlaybackStartMs = t0.elapsedMilliseconds;
    // Honest measurement (includes the fixed presentation wait by design).
    final actualFinalAsrToPlaybackMs = audioPlaybackStartMs;
    debugPrint('[LocalSantaliPrototype] demoId=${demo.id} '
        'playbackStarted=true '
        'actualFinalAsrToPlaybackMs=$actualFinalAsrToPlaybackMs');
    if (actualFinalAsrToPlaybackMs >
        autoPlayDelay.inMilliseconds + 1000) {
      debugPrint('[LocalSantaliPrototype] WARNING latency target '
          'exceeded (actualFinalAsrToPlaybackMs=$actualFinalAsrToPlaybackMs)');
    }
    final msg = TranslationMessage(
      id: 'demo_${demo.id}_${DateTime.now().millisecondsSinceEpoch}',
      isTeacher: true,
      speakerName: 'Teacher (Hindi)',
      originalText: text,
      translatedText: demo.santali,
      targetLanguage: TribalLanguage.santali,
      timestamp: DateTime.now(),
      latencyMs: actualFinalAsrToPlaybackMs,
      isOfflineNmt: true,
    );
    final newHistory =
        List<TranslationMessage>.from(current.conversationHistory)..add(msg);
    emit(current.copyWith(
      isRecording: false,
      isProcessing: false,
      currentInputHindi: text,
      currentTranslationResult: demo.santali,
      conversationHistory: newHistory,
      latencyMs: actualFinalAsrToPlaybackMs,
      targetLanguage: _activeLanguage,
      isLocalPrototype: true,
      localAudioAsset: demo.audio,
      localPhraseId: demo.id,
      clearTranslationError: true,
    ));
    return true;
  }
}
