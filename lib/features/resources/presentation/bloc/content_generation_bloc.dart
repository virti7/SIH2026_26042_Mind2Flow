import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../app/di/injection.dart';
import '../../../../core/api/authenticated_api_client.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/enums/app_enums.dart';
import '../../../../core/models/app_models.dart';
import '../../../../core/network/connectivity_service.dart';
import '../../../../core/repositories/app_repositories.dart';
import '../../../../core/sync/remote_content_data_source.dart';
import '../../../../core/sync/worksheet_generation_queue.dart';


// =====================================================================
// EVENTS
// =====================================================================

abstract class ContentGenerationEvent extends Equatable {
  const ContentGenerationEvent();
  @override
  List<Object?> get props => [];
}

class CheckServerConnectivityEvent extends ContentGenerationEvent {
  const CheckServerConnectivityEvent();
}

class StartContentGenerationEvent extends ContentGenerationEvent {
  final TeacherGenerationRequestModel request;
  final String? idempotencyKey;

  const StartContentGenerationEvent({
    required this.request,
    this.idempotencyKey,
  });

  @override
  List<Object?> get props => [request, idempotencyKey];
}

class PollContentGenerationStatusEvent extends ContentGenerationEvent {
  final String jobId;
  const PollContentGenerationStatusEvent(this.jobId);
  @override
  List<Object?> get props => [jobId];
}

class ApproveContentReviewEvent extends ContentGenerationEvent {
  final String jobId;
  final String santaliScriptConfirmed;
  final String? notes;

  const ApproveContentReviewEvent({
    required this.jobId,
    this.santaliScriptConfirmed = 'Olck',
    this.notes,
  });

  @override
  List<Object?> get props => [jobId, santaliScriptConfirmed, notes];
}

class DownloadAndSaveContentEvent extends ContentGenerationEvent {
  final String jobId;
  final String contentId;
  final Map<String, dynamic> contentPayload;
  final Map<String, dynamic>? assets;

  const DownloadAndSaveContentEvent({
    required this.jobId,
    required this.contentId,
    required this.contentPayload,
    this.assets,
  });

  @override
  List<Object?> get props => [jobId, contentId, contentPayload, assets];
}

class ResetContentGenerationEvent extends ContentGenerationEvent {
  const ResetContentGenerationEvent();
}

/// Queues a generation request locally while offline. The request syncs later
/// via Sync Now.
class QueueOfflineGenerationEvent extends ContentGenerationEvent {
  final TeacherGenerationRequestModel request;

  const QueueOfflineGenerationEvent({required this.request});

  @override
  List<Object?> get props => [request];
}

// =====================================================================
// STATES
// =====================================================================

abstract class ContentGenerationState extends Equatable {
  const ContentGenerationState();
  @override
  List<Object?> get props => [];
}

class ContentGenerationInitial extends ContentGenerationState {}

class ContentGenerationCheckingConnectivity extends ContentGenerationState {}

class ContentGenerationSubmitting extends ContentGenerationState {}

class ContentGenerationInProgress extends ContentGenerationState {
  final String jobId;
  final String serverStatus; // PENDING, GENERATING, VALIDATING
  final String message;

  /// Teacher-facing stage title (Sending Request / Generating Worksheet /
  /// Translating Worksheet / Finishing Worksheet). Never provider internals.
  final String stageTitle;

  const ContentGenerationInProgress({
    required this.jobId,
    required this.serverStatus,
    required this.message,
    this.stageTitle = 'Generating Worksheet',
  });

  @override
  List<Object?> get props => [jobId, serverStatus, message, stageTitle];
}

/// The server job is still running after a generous wait. This is NOT a
/// failure: the teacher may keep waiting (same job, no duplicate) or leave
/// the screen; the server-side job is never cancelled by this state.
class ContentGenerationStillWaiting extends ContentGenerationState {
  final String jobId;

  const ContentGenerationStillWaiting({required this.jobId});

  @override
  List<Object?> get props => [jobId];
}

class ContentGenerationReviewRequired extends ContentGenerationState {
  final String jobId;
  final String contentId;
  final Map<String, dynamic> reviewGates;
  final Map<String, dynamic> rawContent;

  const ContentGenerationReviewRequired({
    required this.jobId,
    required this.contentId,
    required this.reviewGates,
    required this.rawContent,
  });

  @override
  List<Object?> get props => [jobId, contentId, reviewGates, rawContent];
}

class ContentGenerationReady extends ContentGenerationState {
  final String jobId;
  final String contentId;
  final Map<String, dynamic> contentPayload;
  final Map<String, dynamic>? assets;

  const ContentGenerationReady({
    required this.jobId,
    required this.contentId,
    required this.contentPayload,
    this.assets,
  });

  @override
  List<Object?> get props => [jobId, contentId, contentPayload, assets];
}

class ContentGenerationDownloading extends ContentGenerationState {
  final String jobId;
  final String contentId;
  final double progress;

  const ContentGenerationDownloading({
    required this.jobId,
    required this.contentId,
    this.progress = 0.5,
  });

  @override
  List<Object?> get props => [jobId, contentId, progress];
}

class ContentGenerationSavedLocally extends ContentGenerationState {
  final SavedMaterialData savedMaterial;
  final String? localFilePath;

  /// Server asset references (e.g. canonical PDF path) for Download.
  final Map<String, dynamic>? assets;

  const ContentGenerationSavedLocally({
    required this.savedMaterial,
    this.localFilePath,
    this.assets,
  });

  @override
  List<Object?> get props => [savedMaterial, localFilePath, assets];
}

class ContentGenerationFailed extends ContentGenerationState {
  final String errorMessage;
  final bool isOfflineError;

  /// True only when the request could NOT be persisted on this device.
  /// The UI must then show "Couldn't Save Request" and must NOT claim the
  /// request was saved.
  final bool isPersistenceError;

  /// Server job that failed (if any). Retry reuses the same logical request
  /// as a new attempt; an in-flight job is resumed, never duplicated.
  final String? jobId;

  /// Whether offering "Retry Generation" is meaningful (false only when
  /// there is nothing to retry, e.g. nothing was ever submitted).
  final bool canRetry;

  const ContentGenerationFailed({
    required this.errorMessage,
    this.isOfflineError = false,
    this.isPersistenceError = false,
    this.jobId,
    this.canRetry = true,
  });

  @override
  List<Object?> get props =>
      [errorMessage, isOfflineError, isPersistenceError, jobId, canRetry];
}

/// Resumes polling an in-flight server job after a "Still generating" pause.
/// Never creates a second job.
class ResumeWaitingPollEvent extends ContentGenerationEvent {
  final String jobId;
  const ResumeWaitingPollEvent(this.jobId);
  @override
  List<Object?> get props => [jobId];
}

/// Offline request stored as PENDING_GENERATION in the local sync queue.
class ContentGenerationQueuedOffline extends ContentGenerationState {
  final String requestId;

  const ContentGenerationQueuedOffline({required this.requestId});

  @override
  List<Object?> get props => [requestId];
}

// =====================================================================
// BLOC IMPLEMENTATION (Strictly BLoC, NO CUBIT)
// =====================================================================

class ContentGenerationBloc
    extends Bloc<ContentGenerationEvent, ContentGenerationState> {
  final RemoteContentDataSource remoteDataSource;
  final ConnectivityService connectivityService;

  /// Kept for backward compatibility (existing callers/tests pass it).
  /// Queueing and completed-worksheet persistence go through [_queue] and
  /// [_store], which are Drift-backed on native and SharedPreferences/
  /// memory-backed on web, so this bloc never touches SQLite directly.
  final AppDatabase? database;
  final WorksheetGenerationQueueRepository _queue;
  final GeneratedWorksheetStore _store;
  final Set<String> _inflightKeys = {};
  final Map<String, DateTime> _recentKeys = {};
  static const Duration _dedupeWindow = Duration(seconds: 10);

  ContentGenerationBloc({
    required this.remoteDataSource,
    required this.connectivityService,
    this.database,
    WorksheetGenerationQueueRepository? queueRepository,
    GeneratedWorksheetStore? worksheetStore,
  })  : _queue = queueRepository ??
            (database != null
                ? NativeWorksheetGenerationQueue(database)
                : throw StateError(
                    'ContentGenerationBloc needs a queueRepository or database.')),
        _store = worksheetStore ??
            (database != null
                ? NativeGeneratedWorksheetStore(database)
                : throw StateError(
                    'ContentGenerationBloc needs a worksheetStore or database.')),
        super(ContentGenerationInitial()) {
    on<CheckServerConnectivityEvent>(_onCheckConnectivity);
    on<StartContentGenerationEvent>(_onStartGeneration);
    on<QueueOfflineGenerationEvent>(_onQueueOffline);
    on<PollContentGenerationStatusEvent>(_onPollStatus);
    on<ResumeWaitingPollEvent>(
        (event, emit) => _pollJobUntilTerminal(event.jobId, emit));
    on<ApproveContentReviewEvent>(_onApproveReview);
    on<DownloadAndSaveContentEvent>(_onDownloadAndSave);
    on<ResetContentGenerationEvent>((event, emit) => emit(ContentGenerationInitial()));
  }

  Future<void> _onQueueOffline(
    QueueOfflineGenerationEvent event,
    Emitter<ContentGenerationState> emit,
  ) async {
    emit(ContentGenerationSubmitting());
    try {
      final requestId = await _queue.enqueue(event.request);
      emit(ContentGenerationQueuedOffline(requestId: requestId));
    } on QueuePersistenceException catch (e) {
      // Honest failure: persistence did NOT succeed, so the UI must not
      // claim the request was saved.
      emit(ContentGenerationFailed(
        errorMessage: e.message,
        isOfflineError: true,
        isPersistenceError: true,
      ));
    } catch (_) {
      emit(const ContentGenerationFailed(
        errorMessage:
            'The worksheet request could not be saved on this device. Please try again.',
        isOfflineError: true,
        isPersistenceError: true,
      ));
    }
  }

  Future<void> _onCheckConnectivity(
    CheckServerConnectivityEvent event,
    Emitter<ContentGenerationState> emit,
  ) async {
    emit(ContentGenerationCheckingConnectivity());
    final isOnline = await connectivityService.isOnline;
    if (!isOnline) {
      emit(const ContentGenerationFailed(
        errorMessage: 'You are offline. The worksheet request will be saved and generated after you reconnect.',
        isOfflineError: true,
      ));
      return;
    }

    final isBackendReachable = await connectivityService.checkBackendReachability();
    if (!isBackendReachable) {
      emit(const ContentGenerationFailed(
        errorMessage: 'Server is currently unavailable. Your worksheet request has been saved and will be generated when you reconnect.',
        isOfflineError: true,
      ));
      return;
    }

    emit(ContentGenerationInitial());
  }

  Future<void> _onStartGeneration(
    StartContentGenerationEvent event,
    Emitter<ContentGenerationState> emit,
  ) async {
    final dedupeKey =
        event.idempotencyKey ?? event.request.requestId ?? event.request.topic ?? '';
    final now = DateTime.now();
    _recentKeys.removeWhere((_, ts) => now.difference(ts) > _dedupeWindow);
    if (dedupeKey.isNotEmpty &&
        (_inflightKeys.contains(dedupeKey) || _recentKeys.containsKey(dedupeKey))) {
      // Duplicate tap while the same request is in flight or just
      // completed: ignore so no duplicate job is created.
      return;
    }
    if (dedupeKey.isNotEmpty) {
      _inflightKeys.add(dedupeKey);
      _recentKeys[dedupeKey] = now;
    }
    try {
      // 1. Verify device and backend connectivity
      emit(ContentGenerationCheckingConnectivity());
      final isOnline = await connectivityService.isOnline;
      if (!isOnline) {
        // Device offline: queue locally instead of failing.
        await _queueInsteadOfFailing(event.request, emit);
        return;
      }

      final isBackendReachable = await connectivityService.checkBackendReachability();
      if (!isBackendReachable) {
        // Online but backend unreachable: queue locally instead of losing it.
        await _queueInsteadOfFailing(event.request, emit);
        return;
      }

      // 2. Submit generation request (HTTP 202 + job_id).
      emit(ContentGenerationSubmitting());
      try {
        final job = await remoteDataSource.requestGeneration(
          event.request,
          idempotencyKey: event.idempotencyKey,
        );

        if (job.isPendingOrRunning) {
          // Job accepted server-side: poll the existing job endpoint until
          // it reaches a terminal state. No second job is ever created here.
          _emitStageProgress(job, emit, 0);
          await _pollJobUntilTerminal(job.jobId, emit);
        } else {
          _handleJobTransition(job, emit);
        }
      } catch (e) {
        // No job was created: the teacher may retry (new attempt, same
        // logical request via a fresh idempotency key from the screen).
        emit(ContentGenerationFailed(
          errorMessage: _teacherFriendlyError(e),
        ));
      }
    } finally {
      if (dedupeKey.isNotEmpty) _inflightKeys.remove(dedupeKey);
    }
  }

  Future<void> _queueInsteadOfFailing(
    TeacherGenerationRequestModel request,
    Emitter<ContentGenerationState> emit,
  ) async {
    try {
      emit(ContentGenerationSubmitting());
      final requestId = await _queue.enqueue(request);
      emit(ContentGenerationQueuedOffline(requestId: requestId));
    } on QueuePersistenceException catch (e) {
      emit(ContentGenerationFailed(
        errorMessage: e.message,
        isOfflineError: true,
        isPersistenceError: true,
      ));
    } catch (_) {
      emit(const ContentGenerationFailed(
        errorMessage:
            'The worksheet request could not be saved on this device. Please try again.',
        isOfflineError: true,
        isPersistenceError: true,
      ));
    }
  }

  String _teacherFriendlyError(Object e) {
    if (e is UnauthorizedException) {
      return e.message;
    }
    if (e is AuthenticationRequiredException) {
      return 'Authentication required. Please sign in to proceed.';
    }
    if (e is SessionExpiredException) {
      return e.message;
    }
    if (e is ForbiddenException) {
      return 'You do not have permission to perform this action.';
    }
    if (e is ValidationException || e is BadRequestException) {
      return 'Some generation options are invalid.';
    }
    if (e is RateLimitedException) {
      return 'Generation service is temporarily busy. Please try again.';
    }
    if (e is ServerException) {
      return 'Generation service is temporarily unavailable.';
    }
    if (e is NetworkException) {
      return 'Cannot reach the server. Check your connection.';
    }
    if (e is ApiException) {
      if (e.statusCode == 401) {
        return e.message.isNotEmpty ? e.message : 'Authentication required. Please sign in again.';
      }
      if (e.statusCode == 403) {
        return 'You do not have permission to perform this action.';
      }
      if (e.statusCode == 422 || e.statusCode == 400) {
        return 'Some generation options are invalid.';
      }
      if (e.statusCode == 429) {
        return 'Generation service is temporarily busy. Please try again.';
      }
      if (e.statusCode >= 500) {
        return 'Generation service is temporarily unavailable.';
      }
    }

    final raw = e.toString();
    final lower = raw.toLowerCase();
    // Storage/driver internals must never leak into teacher-facing copy.
    if (lower.contains('sqlite') ||
        lower.contains('drift') ||
        lower.contains('indexeddb') ||
        lower.contains('sqlite3')) {
      return 'Worksheet generation failed. Please try again.';
    }
    if (lower.contains('401') || lower.contains('session expired') || lower.contains('unauthorized')) {
      return 'Your session has expired. Please sign in again and retry.';
    }
    if (lower.contains('403') || lower.contains('forbidden')) {
      return 'You do not have permission to perform this action.';
    }
    if (lower.contains('422') || lower.contains('validation')) {
      return 'Some generation options are invalid.';
    }
    if (lower.contains('429') || lower.contains('busy') || lower.contains('rate limit')) {
      return 'Generation service is temporarily busy. Please try again.';
    }
    if (lower.contains('500') || lower.contains('502') || lower.contains('503') || lower.contains('unavailable')) {
      return 'Generation service is temporarily unavailable.';
    }
    if (lower.contains('not configured') ||
        lower.contains('unsupported language') ||
        lower.contains('translation for this language')) {
      return 'The selected language is not currently configured for generation. Please choose another language.';
    }
    if (lower.contains('socket') || lower.contains('timeout') || lower.contains('connection') || lower.contains('network')) {
      return 'Cannot reach the server. Check your connection.';
    }
    return 'Worksheet generation failed. Please try again.';
  }

  Future<void> _onPollStatus(
    PollContentGenerationStatusEvent event,
    Emitter<ContentGenerationState> emit,
  ) async {
    try {
      final job = await remoteDataSource.getJobStatus(event.jobId);
      _handleJobTransition(job, emit);
    } catch (e) {
      emit(ContentGenerationFailed(
        errorMessage: _teacherFriendlyError(e),
      ));
    }
  }

  Future<void> _onApproveReview(
    ApproveContentReviewEvent event,
    Emitter<ContentGenerationState> emit,
  ) async {
    emit(ContentGenerationInProgress(
      jobId: event.jobId,
      serverStatus: 'VALIDATING',
      message: 'Confirming script review and preparing artifact...',
    ));

    try {
      final job = await remoteDataSource.approveJob(
        event.jobId,
        santaliScriptConfirmed: event.santaliScriptConfirmed,
        notes: event.notes,
      );
      _handleJobTransition(job, emit);
    } catch (e) {
      emit(ContentGenerationFailed(
        errorMessage: _teacherFriendlyError(e),
      ));
    }
  }

  /// Poll interval / budget for an accepted server job. Gentle on the
  /// server (~2s cadence, ~90s budget); expiry is reported as "still
  /// generating", never as a failure.
  static const Duration _pollInterval = Duration(seconds: 2);
  static const int _maxPollAttempts = 45;

  /// Polls GET /api/v1/ai/jobs/{jobId} until READY / REVIEW_REQUIRED /
  /// FAILED, or until the wait budget is spent (-> StillWaiting). Never
  /// creates a job; transient poll errors are tolerated, not fatal.
  Future<void> _pollJobUntilTerminal(
    String jobId,
    Emitter<ContentGenerationState> emit,
  ) async {
    for (var attempt = 0; attempt < _maxPollAttempts; attempt++) {
      await Future.delayed(_pollInterval);
      if (emit.isDone) return;
      GenerationJobModel job;
      try {
        job = await remoteDataSource.getJobStatus(jobId);
      } catch (_) {
        continue;
      }
      if (job.isReady || job.isFailed || job.isReviewRequired) {
        _handleJobTransition(job, emit);
        return;
      }
      _emitStageProgress(job, emit, attempt + 1);
    }
    emit(ContentGenerationStillWaiting(jobId: jobId));
  }

  /// Honest state-based progress: maps the real server statuses onto the
  /// teacher-facing stages. No percentages (the server exposes none).
  /// Heuristic detail: the pipeline builds, then translates, then
  /// validates. VALIDATING is explicit; a prolonged GENERATING phase means
  /// the translation leg is running, so the stage copy reflects that.
  void _emitStageProgress(
    GenerationJobModel job,
    Emitter<ContentGenerationState> emit,
    int pollCount,
  ) {
    switch (job.status) {
      case 'PENDING':
        emit(ContentGenerationInProgress(
          jobId: job.jobId,
          serverStatus: job.status,
          stageTitle: 'Sending Request...',
          message: 'Your request is queued on the server...',
        ));
      case 'VALIDATING':
        emit(ContentGenerationInProgress(
          jobId: job.jobId,
          serverStatus: job.status,
          stageTitle: 'Finishing Worksheet',
          message: 'Checking questions and formatting...',
        ));
      case 'GENERATING':
      default:
        // past ~15s of GENERATING the translation leg is running.
        final translating = pollCount >= 7;
        emit(ContentGenerationInProgress(
          jobId: job.jobId,
          serverStatus: job.status,
          stageTitle: translating ? 'Translating Worksheet' : 'Generating Worksheet',
          message: translating
              ? 'Preparing the selected mother tongue...'
              : 'Preparing your NIPUN-aligned worksheet...',
        ));
    }
  }

  void _handleJobTransition(
    GenerationJobModel job,
    Emitter<ContentGenerationState> emit,
  ) {
    if (job.isFailed) {
      emit(ContentGenerationFailed(
        errorMessage: _teacherFriendlyError(job.error ?? 'Generation failed'),
        jobId: job.jobId,
      ));
      return;
    }

    if (job.isReviewRequired) {
      emit(ContentGenerationReviewRequired(
        jobId: job.jobId,
        contentId: job.contentId ?? 'unknown',
        reviewGates: job.reviewGates ?? {},
        rawContent: job.content ?? {},
      ));
      return;
    }

    if (job.isReady) {
      final contentId = job.contentId ?? 'gen_${DateTime.now().millisecondsSinceEpoch}';
      emit(ContentGenerationReady(
        jobId: job.jobId,
        contentId: contentId,
        contentPayload: job.content ?? {},
        assets: job.assets,
      ));
      // Trigger automatic atomic download and local persistence
      add(DownloadAndSaveContentEvent(
        jobId: job.jobId,
        contentId: contentId,
        contentPayload: job.content ?? {},
        assets: job.assets,
      ));
      return;
    }

    // Still in progress (e.g. single manual poll): same honest mapping.
    _emitStageProgress(job, emit, 0);
  }

  Future<void> _onDownloadAndSave(
    DownloadAndSaveContentEvent event,
    Emitter<ContentGenerationState> emit,
  ) async {
    emit(ContentGenerationDownloading(
      jobId: event.jobId,
      contentId: event.contentId,
      progress: 0.2,
    ));

    String? localFilePath;

    // 1. Download asset if present
    final pdfAsset = event.assets?['pdf'] as String?;
    final imageAsset = event.assets?['image'] as String?;
    final targetAsset = pdfAsset ?? imageAsset;

    if (targetAsset != null && targetAsset.isNotEmpty) {
      try {
        final fileName = '${event.contentId}${pdfAsset != null ? ".pdf" : ".png"}';
        final file = await remoteDataSource.downloadAsset(targetAsset, fileName);
        localFilePath = file.path;
      } catch (e) {
        // Asset download failed; log and keep local payload
      }
    }

    emit(ContentGenerationDownloading(
      jobId: event.jobId,
      contentId: event.contentId,
      progress: 0.8,
    ));

    // Persist the completed server worksheet through the platform store
    // (native: SavedMaterials via SQLite; web: in-memory for preview).
    // A merely queued request is never recorded here, so teacher Progress
    // only counts worksheets the server actually generated.
    final payload = event.contentPayload;

    SavedMaterialData savedMaterial;
    try {
      savedMaterial = await _store.saveCompletedWorksheet(
        event.contentId,
        payload,
      );
    } catch (_) {
      emit(const ContentGenerationFailed(
        errorMessage:
            'The generated content could not be saved on this device. Please try again.',
        isPersistenceError: true,
      ));
      return;
    }

    // If flashcard content, also register with the active ResourceRepository
    if (payload['content_type'] == 'flashcard') {
      try {
        if (getIt.isRegistered<ResourceRepository>()) {
          final repo = getIt<ResourceRepository>();
          final rawCards = (payload['items'] as List<dynamic>?) ?? (payload['cards'] as List<dynamic>?) ?? [];
          final String topic = (payload['topic'] ?? payload['curriculum_id'] ?? 'Numbers').toString();
          final String langStr = (payload['target_language'] ?? 'sat').toString();
          final TribalLanguage targetLang = langStr == 'sat'
              ? TribalLanguage.santali
              : (langStr == 'ho' ? TribalLanguage.ho : TribalLanguage.mundari);

          final List<FlashcardItem> parsedCards = [];
          for (var i = 0; i < rawCards.length; i++) {
            final item = rawCards[i];
            if (item is! Map) continue;
            // Santali multilingual shape: {hindi, english, santali, ...}.
            if (item['santali'] != null) {
              final hiWord = (item['hindi'] ?? '').toString();
              final enWord = (item['english'] ?? '').toString();
              final satWord = (item['santali'] ?? '').toString();
              final visual = item['visual'];
              final glyph =
                  visual is Map ? (visual['glyph'] ?? '🎴').toString() : '🎴';
              parsedCards.add(FlashcardItem(
                id: (item['id'] ?? 'fc_$i').toString(),
                topic: topic,
                hindiWord: hiWord.isNotEmpty ? hiWord : enWord,
                tribalWord: satWord.isNotEmpty ? satWord : 'ᱢᱤᱫ',
                language: targetLang,
                pronunciation: '',
                teacherPrompt: enWord,
                emojiOrIcon: glyph,
                exampleSentence: '',
              ));
              continue;
            }
            final front = item['front'];
            final back = item['back'];
            String hiWord = '';
            String tribalWord = '';
            if (front is Map) {
              hiWord = (front['hi'] ?? '').toString();
              tribalWord = (front['sat'] ?? front['ho'] ?? front['unr'] ?? '').toString();
            } else {
              hiWord = (item['front'] ?? item['hindiWord'] ?? '').toString();
              tribalWord = (item['back'] ?? item['tribalWord'] ?? '').toString();
            }
            String teacherPrompt = '';
            if (back is Map) {
              teacherPrompt = (back['hi'] ?? '').toString();
              if (tribalWord.isEmpty) {
                tribalWord = (back['sat'] ?? back['ho'] ?? back['unr'] ?? '').toString();
              }
            } else if (item['prompt'] != null) {
              teacherPrompt = item['prompt'].toString();
            }
            parsedCards.add(FlashcardItem(
              id: (item['item_id'] ?? 'fc_$i').toString(),
              topic: topic,
              hindiWord: hiWord.isNotEmpty ? hiWord : 'एक',
              tribalWord: tribalWord.isNotEmpty ? tribalWord : 'ᱢᱤᱫ',
              language: targetLang,
              pronunciation: '',
              teacherPrompt: teacherPrompt,
              emojiOrIcon: '🎴',
              exampleSentence: '',
            ));
          }
          if (parsedCards.isNotEmpty) {
            await repo.saveFlashcardSet(
              topic: topic,
              language: targetLang,
              cards: parsedCards,
            );
          }
        }
      } catch (_) {
        // Best effort saving into repository
      }
    }

    emit(ContentGenerationSavedLocally(
      savedMaterial: savedMaterial,
      localFilePath: localFilePath,
      assets: event.assets,
    ));
  }
}

