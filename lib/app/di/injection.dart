import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/database/app_database.dart';
import '../../core/database/database_seeder.dart';
import '../../core/repositories/mock_repositories.dart';
import '../../core/domain/usecases/assessment_usecases.dart';
import '../../core/domain/usecases/lesson_usecases.dart';
import '../../core/domain/usecases/offline_sync_usecases.dart';
import '../../core/domain/usecases/resource_usecases.dart';
import '../../core/domain/usecases/student_usecases.dart';
import '../../core/domain/usecases/teacher_activity_usecases.dart';
import '../../core/domain/usecases/teacher_usecases.dart';
import '../../core/domain/usecases/translation_usecases.dart';
import '../../core/network/connectivity_service.dart';
import '../../core/repositories/app_repositories.dart';
import '../../core/repositories/sqlite_repositories.dart';
import '../../core/repositories/teacher_activity_repository.dart';
import '../../core/config/api_config.dart';
import '../../core/review/review_stores.dart';
import '../../features/translation/presentation/teacher_review/services/teacher_review_repository.dart';
import '../../core/sync/browser_content_data_source.dart';
import '../../core/sync/remote_data_source.dart';
import '../../core/sync/http_remote_data_source.dart';
import '../../core/sync/worksheet_download_store.dart';
import '../../core/sync/worksheet_generation_queue.dart';
import '../../core/sync/worksheet_generation_sync.dart';
import '../../core/sync/remote_content_data_source.dart';
import '../../core/sync/sync_manager.dart';
import '../../features/offline/presentation/bloc/sync_bloc.dart';
import '../../features/profile/presentation/bloc/teacher_profile_bloc.dart';
import '../../features/resources/presentation/bloc/content_generation_bloc.dart';

import '../../core/auth/data/repositories/supabase_auth_repository.dart';
import '../../core/auth/domain/repositories/auth_repository.dart';
import '../../core/auth/services/account_session.dart';
import '../../core/auth/services/current_user_service.dart';
import '../../core/api/authenticated_api_client.dart';
import '../../core/content/prototype_content_repository.dart';
import '../../core/content/prototype_demo_translation.dart';
import '../../core/content/prototype_local_content_data_source.dart';
import '../../core/content/prototype_teacher_guidance_repository.dart';
import '../../core/content/teacher_guidance_models.dart';
import '../../core/copilot/copilot_engine.dart';
import '../../core/copilot/copilot_store.dart';
import '../../core/teacher_assist/teacher_question_engine.dart';
import '../../core/content/santali_audio_player.dart';
import '../../core/content/santali_phrase_bank.dart';
import '../../core/asr/offline_asr_service.dart';
import '../../core/translation/bidirectional_phrase_bank.dart';
import '../../features/smartboard/data/smartboard_demo_repository.dart';
import '../../features/smartboard/data/smartboard_lesson_store.dart';
import '../../features/smartboard/data/smartboard_repository.dart';
import '../../core/database/account_scope.dart';
import '../../core/auth/presentation/bloc/auth_bloc.dart';
import '../../core/content/flashcard/flashcard_image_library.dart';
import '../../core/content/flashcard/flashcard_progress_store.dart';
import '../../core/content/flashcard/santali_flashcard_local_data_source.dart';
import '../../core/content/flashcard/santali_flashcard_repository.dart';
import '../../features/resources/presentation/bloc/santali_flashcard_bloc.dart';

final getIt = GetIt.instance;

Future<void> setupDependencyInjection({
  AppDatabase? db,
  ConnectivityService? connectivityService,
  RemoteDataSource? remoteDataSource,
  bool seed = true,
}) async {
  if (getIt.isRegistered<AppDatabase>()) {
    if (seed) {
      final seeder = DatabaseSeeder(getIt<AppDatabase>());
      await seeder.seedIfNeeded();
    }
    return;
  }

  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  // Network & Sync Layer (shared by all platforms)
  final connectivity = connectivityService ?? ConnectivityServiceImpl();
  getIt.registerSingleton<ConnectivityService>(
    connectivity,
    dispose: (s) {
      if (s is ConnectivityServiceImpl) {
        s.dispose();
      }
    },
  );

  // Production sync path on native platforms: real HTTP client against the
  // configured backend. Web has no native SyncManager queue: register an
  // explicitly-unavailable stub so no web flow can mistake a mock success
  // for a server round-trip. (Mock data sources stay restricted to tests
  // and explicit mock mode.) Web worksheet uploads use the browser HTTP
  // content data source below via the web worksheet sync adapter.
  // NOTE: this must never throw before the repositories are registered —
  // main.dart boots the app anyway on DI failure, which leaves GetIt empty.
  final RemoteDataSource remote = remoteDataSource ??
      (kIsWeb
          ? const WebUnavailableRemoteDataSource()
          : HttpRemoteDataSource(baseUrl: ApiConfig.baseUrl));
  getIt.registerSingleton<RemoteDataSource>(remote);

  // Auth & Authenticated API Client Layer
  final authRepo = SupabaseAuthRepository();
  try {
    await authRepo.initialize();
  } catch (e) {
    debugPrint('[DI] SupabaseAuth init warning: $e');
  }
  getIt.registerSingleton<AuthRepository>(authRepo);

  // Central account identity: Supabase session user UUID -> all
  // teacher-owned data. Repositories resolve the owner through this.
  final currentUserService = CurrentUserService(authRepo);
  getIt.registerSingleton<CurrentUserService>(currentUserService);
  String? resolveOwnerId() => currentUserService.currentUserId;

  final apiClient = AuthenticatedApiClient(authRepository: authRepo);
  getIt.registerSingleton<AuthenticatedApiClient>(apiClient);

  final remoteContent = kIsWeb
      ? BrowserHttpRemoteContentDataSource(apiClient: apiClient)
      : HttpRemoteContentDataSource(apiClient: apiClient);
  getIt.registerSingleton<RemoteContentDataSource>(remoteContent);

  // Chrome/web has no bundled sql.js (drift web) and no native SQLite:
  // use the in-memory mock repositories so the demo boots. Native
  // platforms keep the real Drift + SQLite stack.
  late final TeacherRepository teacherRepo;
  late final LessonRepository lessonRepo;
  late final ResourceRepository resourceRepo;
  late final AssessmentRepository assessmentRepo;
  late final StudentRepository studentRepo;
  late final TranslationRepository translationRepo;
  late final OfflineRepository offlineRepo;
  late final TeacherActivityRepository activityRepo;
  SyncManager? syncManager;

  if (kIsWeb) {
    teacherRepo = MockTeacherRepository(currentUserIdProvider: resolveOwnerId);
    lessonRepo = MockLessonRepository();
    resourceRepo = MockResourceRepository();
    assessmentRepo = MockAssessmentRepository();
    studentRepo = MockStudentRepository();
    translationRepo = MockTranslationRepository();
    offlineRepo = MockOfflineRepository();
    activityRepo = EmptyTeacherActivityRepository();

    // Web offline worksheet queue: browser-persistent SharedPreferences JSON.
    // Never touches Drift/SQLite, so offline Generate cannot hit sqlite3.js.
    // Browser storage may be unavailable: degrade to session memory instead
    // of crashing (persistence failures still surface honestly in the UI).
    SharedPreferences? webPrefs;
    try {
      webPrefs = await SharedPreferences.getInstance();
    } catch (_) {
      webPrefs = null;
    }
    final webQueue = WebWorksheetGenerationQueue(
        prefs: webPrefs, currentUserIdProvider: resolveOwnerId);
    getIt.registerSingleton<WorksheetGenerationQueueRepository>(webQueue);
    getIt.registerSingleton<GeneratedWorksheetStore>(
        MemoryGeneratedWorksheetStore());
    // Web downloads: browser-safe metadata + file store (no SQLite).
    getIt.registerSingleton<WorksheetDownloadStore>(
        PrefsWorksheetDownloadStore(
            prefs: webPrefs, currentUserIdProvider: resolveOwnerId));

    // Web "Sync Now" adapter: uploads pending worksheet_generation requests
    // via the browser HTTP data source. Completed server worksheets are
    // saved into the resource repository (Saved Materials) — queued-only
    // requests are never counted as generated.
    final webResourceRepo = resourceRepo;
    getIt.registerSingleton<WebWorksheetSyncAdapter>(
      WebWorksheetSyncAdapter(
        queue: webQueue,
        remote: remoteContent,
        connectivity: connectivity,
        onCompleted: (done) async {
          final item = worksheetItemFromGenerationPayload({
            ...done.content,
            'content_id': done.content['content_id'] ?? done.contentId,
          });
          if (item.questions.isEmpty) return;
          await webResourceRepo.saveWorksheet(item);
        },
      ),
    );
  } else {
    final database = db ?? AppDatabase();
    getIt.registerSingleton<AppDatabase>(database);
    // Account-isolation mapping table + sync_queue owner column.
    try {
      await ensureAccountIsolation(database);
    } catch (_) {}

    // Native offline worksheet queue: Drift/SQLite sync_queue (unchanged
    // production path: Drift -> SQLite -> SyncManager -> FastAPI).
    getIt.registerSingleton<WorksheetGenerationQueueRepository>(
        NativeWorksheetGenerationQueue(database,
            currentUserIdProvider: resolveOwnerId));
    getIt.registerSingleton<GeneratedWorksheetStore>(
        NativeGeneratedWorksheetStore(database,
            currentUserIdProvider: resolveOwnerId));
    // Native downloads: Drift/SQLite metadata + app-private files.
    getIt.registerSingleton<WorksheetDownloadStore>(
        DriftWorksheetDownloadStore(database,
            currentUserIdProvider: resolveOwnerId));

    // Completed worksheet generations land in SavedMaterials (and therefore
    // Saved Materials, Worksheet Preview, and teacher Progress) as soon as
    // their sync upload succeeds — no extra fetch step for inline results.
    final completion = WorksheetGenerationCompletion(
      db: database,
      contentDataSource: remoteContent,
    );
    final manager = SyncManager(
      db: database,
      connectivityService: connectivity,
      remoteDataSource: remote,
      currentUserIdProvider: resolveOwnerId,
      onOperationResult: (op, result) =>
          completion.completeFromSyncResult(op, result),
    );
    getIt.registerSingleton<SyncManager>(
      manager,
      dispose: (s) => s.dispose(),
    );
    syncManager = manager;

    // Clean Architecture Repositories backed by SQLite & Drift.
    // Every teacher-owned repository resolves its owner from the
    // authenticated Supabase session (CurrentUserService).
    teacherRepo = SqliteTeacherRepository(
        db: database, currentUserIdProvider: resolveOwnerId);
    lessonRepo = SqliteLessonRepository(
        db: database, currentUserIdProvider: resolveOwnerId);
    resourceRepo = SqliteResourceRepository(
        db: database, currentUserIdProvider: resolveOwnerId);
    assessmentRepo = SqliteAssessmentRepository(
        db: database, currentUserIdProvider: resolveOwnerId);
    studentRepo = SqliteStudentRepository(
        db: database, currentUserIdProvider: resolveOwnerId);
    translationRepo = SqliteTranslationRepository(
        db: database, currentUserIdProvider: resolveOwnerId);
    offlineRepo = SqliteOfflineRepository(
        db: database,
        syncManager: manager,
        currentUserIdProvider: resolveOwnerId);
    activityRepo = SqliteTeacherActivityRepository(
        db: database, currentUserIdProvider: resolveOwnerId);
  }

  getIt.registerLazySingleton<TeacherRepository>(() => teacherRepo);
  getIt.registerLazySingleton<TeacherActivityRepository>(() => activityRepo);
  getIt.registerLazySingleton<LessonRepository>(() => lessonRepo);
  getIt.registerLazySingleton<ResourceRepository>(() => resourceRepo);
  getIt.registerLazySingleton<AssessmentRepository>(() => assessmentRepo);
  getIt.registerLazySingleton<StudentRepository>(() => studentRepo);
  getIt.registerLazySingleton<TranslationRepository>(() => translationRepo);
  getIt.registerLazySingleton<OfflineRepository>(() => offlineRepo);

  // Clean Architecture Domain Layer: Use Cases
  // 1. Teacher Use Cases
  getIt.registerLazySingleton<GetTeacherProfileUseCase>(() => GetTeacherProfileUseCase(teacherRepo));
  getIt.registerLazySingleton<UpdateTeacherProfileUseCase>(() => UpdateTeacherProfileUseCase(teacherRepo));
  getIt.registerLazySingleton<GetClassroomLanguagesUseCase>(() => GetClassroomLanguagesUseCase(teacherRepo));
  getIt.registerLazySingleton<UpdateClassroomLanguagesUseCase>(() => UpdateClassroomLanguagesUseCase(teacherRepo));

  // 2. Lesson Use Cases
  getIt.registerLazySingleton<GetNipunOutcomesUseCase>(() => GetNipunOutcomesUseCase(lessonRepo));
  getIt.registerLazySingleton<GetLessonPlanUseCase>(() => GetLessonPlanUseCase(lessonRepo));
  getIt.registerLazySingleton<CreateLessonPlanUseCase>(() => CreateLessonPlanUseCase(lessonRepo));
  getIt.registerLazySingleton<UpdateLessonPlanUseCase>(() => UpdateLessonPlanUseCase(lessonRepo));
  getIt.registerLazySingleton<UpdateLessonDeliveryProgressUseCase>(() => UpdateLessonDeliveryProgressUseCase(lessonRepo));
  getIt.registerLazySingleton<GetLessonDeliveryProgressUseCase>(() => GetLessonDeliveryProgressUseCase(lessonRepo));
  getIt.registerLazySingleton<GetActivitiesUseCase>(() => GetActivitiesUseCase(lessonRepo));

  // 3. Assessment Use Cases
  getIt.registerLazySingleton<GetAssessmentQuestionsUseCase>(() => GetAssessmentQuestionsUseCase(assessmentRepo));
  getIt.registerLazySingleton<SubmitAssessmentUseCase>(() => SubmitAssessmentUseCase(assessmentRepo));
  getIt.registerLazySingleton<GetRemedialActivityUseCase>(() => GetRemedialActivityUseCase(assessmentRepo));
  getIt.registerLazySingleton<SubmitReassessmentUseCase>(() => SubmitReassessmentUseCase(assessmentRepo));

  // 4. Student Use Cases
  getIt.registerLazySingleton<GetStudentsUseCase>(() => GetStudentsUseCase(studentRepo));
  getIt.registerLazySingleton<GetStudentProfileUseCase>(() => GetStudentProfileUseCase(studentRepo));
  getIt.registerLazySingleton<UpdateStudentOutcomeStatusUseCase>(() => UpdateStudentOutcomeStatusUseCase(studentRepo));

  // 4b. Teacher Activity Use Cases (teacher-only progress)
  getIt.registerLazySingleton<GetTeacherActivitySummaryUseCase>(
      () => GetTeacherActivitySummaryUseCase(activityRepo));
  getIt.registerLazySingleton<GetRecentTeacherActivitiesUseCase>(
      () => GetRecentTeacherActivitiesUseCase(activityRepo));

  // 5. Resource Use Cases
  getIt.registerLazySingleton<GenerateWorksheetUseCase>(() => GenerateWorksheetUseCase(resourceRepo));
  getIt.registerLazySingleton<SaveWorksheetUseCase>(() => SaveWorksheetUseCase(resourceRepo));
  getIt.registerLazySingleton<GetSavedWorksheetsUseCase>(() => GetSavedWorksheetsUseCase(resourceRepo));
  getIt.registerLazySingleton<GetFlashcardsUseCase>(() => GetFlashcardsUseCase(resourceRepo));
  getIt.registerLazySingleton<GetSavedFlashcardsUseCase>(() => GetSavedFlashcardsUseCase(resourceRepo));

  // 6. Translation Use Cases
  getIt.registerLazySingleton<TranslateUtteranceUseCase>(() => TranslateUtteranceUseCase(translationRepo));
  getIt.registerLazySingleton<GetQuickPhrasesUseCase>(() => GetQuickPhrasesUseCase(translationRepo));
  getIt.registerLazySingleton<SubmitTranslationFeedbackUseCase>(() => SubmitTranslationFeedbackUseCase(translationRepo));

  // 7. Offline / Sync Use Cases
  getIt.registerLazySingleton<GetLanguagePacksUseCase>(() => GetLanguagePacksUseCase(offlineRepo));
  getIt.registerLazySingleton<DownloadLanguagePackUseCase>(() => DownloadLanguagePackUseCase(offlineRepo));
  getIt.registerLazySingleton<GetContentPacksUseCase>(() => GetContentPacksUseCase(offlineRepo));
  getIt.registerLazySingleton<TriggerSyncUseCase>(() => TriggerSyncUseCase(offlineRepo));
  getIt.registerLazySingleton<GetPendingSyncCountUseCase>(() => GetPendingSyncCountUseCase(offlineRepo));

  // Offline prototype content path (presentation demo): bundled assets only,
  // zero network. Production remote path (RemoteContentDataSource) untouched.
  getIt.registerLazySingleton<PrototypeLocalContentDataSource>(
      () => PrototypeLocalContentDataSource());
  getIt.registerLazySingleton<PrototypeContentRepository>(
      () => PrototypeContentRepository(
            local: getIt<PrototypeLocalContentDataSource>(),
            resources: getIt<ResourceRepository>(),
          ));

  // Santali Visual Flashcard Curriculum (Problem Statement 26042)
  getIt.registerLazySingleton<SantaliFlashcardLocalDataSource>(
      () => SantaliFlashcardLocalDataSource());
  getIt.registerLazySingleton<FlashcardProgressStore>(() {
    try {
      if (getIt.isRegistered<AppDatabase>()) {
        return SqliteFlashcardProgressStore(db: getIt<AppDatabase>());
      }
    } catch (_) {}
    return InMemoryFlashcardProgressStore();
  });
  getIt.registerLazySingleton<SantaliFlashcardRepository>(
      () => SantaliFlashcardRepositoryImpl(
            localDataSource: getIt<SantaliFlashcardLocalDataSource>(),
            progressStore: getIt<FlashcardProgressStore>(),
          ));
  getIt.registerFactory<SantaliFlashcardBloc>(
      () => SantaliFlashcardBloc(repository: getIt<SantaliFlashcardRepository>()));
  // Image-first flashcard generation (picture library; Sarvam only for
  // topics the library does not cover).
  getIt.registerLazySingleton<FlashcardImageLibrary>(() =>
      FlashcardImageLibrary(repository: getIt<SantaliFlashcardRepository>()));

  // Deterministic offline Teacher Guidance Q&A (presentation demo):
  // bundled teacher_guidance.json only, zero network. Production paths
  // untouched; per-teacher Q&A history stays owner-scoped in memory.
  getIt.registerLazySingleton<PrototypeTeacherGuidanceRepository>(
      () => PrototypeTeacherGuidanceRepository());
  getIt.registerLazySingleton<TeacherGuidanceHistoryStore>(
      () => TeacherGuidanceHistoryStore());

  // Offline Teacher Co-Pilot (deterministic rule engine, presentation demo):
  // bundled copilot/*.json only + existing guidance repository reuse, zero
  // network. Language preference is per-account (scoped SharedPreferences
  // key); conversation context is per-account in memory.
  getIt.registerLazySingleton<CopilotStore>(() => CopilotStore(
        ownerIdProvider: () {
          try {
            return getIt<CurrentUserService>().currentUserId;
          } catch (_) {
            return null;
          }
        },
      ));
  // ONE shared deterministic offline question engine used by BOTH the
  // Teacher Co-Pilot and the Teacher Guidance page (spec dynamic_keyword_
  // teacher_guidance_copilot). Screens only send question + lesson context
  // + answer-language preference. Knowledge files are shared/static;
  // language preference + conversation context stay per-account via
  // CopilotStore / TeacherGuidanceHistoryStore (cleared on logout).
  getIt.registerLazySingleton<TeacherQuestionEngine>(
      () => TeacherQuestionEngine());
  // Account isolation: on logout / account switch, drop in-memory Co-Pilot
  // follow-up context so Account B never sees Account A's conversation.
  // Persisted answer-language preference is per-account (scoped key) and
  // is kept. Knowledge files stay shared/static.
  try {
    // ignore: invalid_use_of_visible_for_testing_member
    if (getIt.isRegistered<CopilotStore>() ||
        true) {
      // Deferred lookup: the listener resolves stores lazily so DI order
      // never matters and tests without GetIt still boot.
      // ignore: unused_local_variable
      final sub = AccountSession.changes.listen((userId) {
        if (userId == null) {
          try {
            if (getIt.isRegistered<CopilotStore>()) {
              getIt<CopilotStore>().clearConversation();
            }
          } catch (_) {}
        }
      });
      void _keepAlive() => sub.toString();
      _keepAlive();
    }
  } catch (_) {}
  getIt.registerLazySingleton<CopilotEngine>(() => CopilotEngine(
        guidanceLookup: (query, lesson) async {
          try {
            final result =
                await getIt<PrototypeTeacherGuidanceRepository>()
                    .answerQuestion(
              query,
              context: TeacherGuidanceContext(
                className: lesson.className,
                subject: lesson.subject,
                topic: lesson.topic,
              ),
            );
            if (result.isUnknown ||
                result.needsClarification ||
                result.item == null) {
              return null;
            }
            return CopilotGuidanceAnswer(
              answerHindi: result.item!.answerHindi,
              answerEnglish: result.item!.answerEnglish,
              topic: result.item!.topic,
            );
          } catch (_) {
            return null;
          }
        },
      ));

  // Offline Santali classroom-audio prototype (presentation demo):
  // active demo scenario + local asset playback, zero network. No phrase
  // matching: the configured demo supplies the Santali output/audio
  // directly after final ASR. The online translation repository above
  // stays untouched.
  getIt.registerLazySingleton<PrototypeDemoTranslationRepository>(
      () => PrototypeDemoTranslationRepository());
  getIt.registerLazySingleton<SantaliAudioPlayer>(
      () => AudioplayersSantaliAudioPlayer());

  // Review system stores (§7–§14) — in-memory prototype stores
  getIt.registerLazySingleton<ReviewQueueStore>(() => ReviewQueueStore());
  getIt.registerLazySingleton<TranslationMemoryStore>(() => TranslationMemoryStore());
  getIt.registerLazySingleton<CorrectionNoticeStore>(() => CorrectionNoticeStore());

  // Teacher Review Portal repository
  getIt.registerLazySingleton<TeacherReviewRepository>(() => TeacherReviewRepository());

  // MASTER OFFLINE SANTALI PHRASE BANK (SIH presentation APK): single JSON  // file + local audio/santali/ folder, zero network. The Quick Phrase Bank
  // UI loads everything dynamically from this repository (cached in memory).
  // Shared static educational content — never account-specific. Teacher
  // favourites stay session-only in the UI, so account isolation holds.
  getIt.registerLazySingleton<SantaliPhraseBankRepository>(
      () => SantaliPhraseBankRepository());

  // OFFLINE ON-DEVICE ASR (MethodChannel -> ONNX Runtime CTC, zero network).
  // Lazy-loaded per direction by the TranslationBloc; one model at a time.
  // NOTE: retired from the Translator path — the deterministic offline
  // prototype (JSON bank + local audio) does not wire this service, so no
  // model inference is reachable from the app. Registration kept only so
  // older unit tests resolving it do not break.
  getIt.registerLazySingleton<OfflineAsrService>(() => OfflineAsrService());

  // MASTER BIDIRECTIONAL PHRASE BANK (deterministic offline Translator):
  // single JSON source of truth + local audio folders, zero network, no
  // ASR, no models. All Translator pairs come from this repository.
  getIt.registerLazySingleton<BidirectionalPhraseBank>(
      () => BidirectionalPhraseBank());

  // MAATRIBHASHA SMARTBOARD (classroom whiteboard prototype): deterministic
  // offline Hindi/English → Santali over the same bidirectional bank, plus
  // an in-memory current-lesson session store. Zero network; the Translator
  // and Review flows above stay untouched.
  getIt.registerLazySingleton<SmartBoardRepository>(
      () => SmartBoardRepository(bank: getIt<BidirectionalPhraseBank>()));
  getIt.registerLazySingleton<SmartBoardLessonStore>(
      () => SmartBoardLessonStore());
  // Static SmartBoard demo content (SIH prototype): fixed math example from
  // assets/prototype_content/smartboard/smartboard_demo.json. Offline only.
  getIt.registerLazySingleton<SmartBoardDemoRepository>(
      () => SmartBoardDemoRepository());

  // Presentation BLoCs
  getIt.registerFactory<TeacherProfileBloc>(() => TeacherProfileBloc(
        getTeacherProfileUseCase: getIt<GetTeacherProfileUseCase>(),
        updateTeacherProfileUseCase: getIt<UpdateTeacherProfileUseCase>(),
        updateClassroomLanguagesUseCase: getIt<UpdateClassroomLanguagesUseCase>(),
      ));

  getIt.registerFactory<SyncBloc>(() => SyncBloc(
        triggerSyncUseCase: getIt<TriggerSyncUseCase>(),
        syncManager: syncManager,
      ));

  getIt.registerFactory<ContentGenerationBloc>(() => ContentGenerationBloc(
        remoteDataSource: getIt<RemoteContentDataSource>(),
        connectivityService: getIt<ConnectivityService>(),
        // Never construct AppDatabase as a fallback: on web there is no
        // SQLite, and doing so is what produced the sqlite3.js crash.
        database: getIt.isRegistered<AppDatabase>() ? getIt<AppDatabase>() : null,
        queueRepository: getIt.isRegistered<WorksheetGenerationQueueRepository>()
            ? getIt<WorksheetGenerationQueueRepository>()
            : null,
        worksheetStore: getIt.isRegistered<GeneratedWorksheetStore>()
            ? getIt<GeneratedWorksheetStore>()
            : null,
      ));

  getIt.registerFactory<AuthBloc>(() => AuthBloc(
        authRepository: getIt<AuthRepository>(),
        teacherRepository: getIt<TeacherRepository>(),
      ));

  // Seed database if needed after all services are registered.
  // Skipped on web: no SQLite there, mocks already carry demo data.
  if (seed && !kIsWeb && getIt.isRegistered<AppDatabase>()) {
    final seeder = DatabaseSeeder(getIt<AppDatabase>());
    await seeder.seedIfNeeded();
  }
}
