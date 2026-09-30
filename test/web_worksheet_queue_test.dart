import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:maatribhasha/core/database/app_database.dart';
import 'package:maatribhasha/core/enums/app_enums.dart';
import 'package:maatribhasha/core/network/connectivity_service.dart';
import 'package:maatribhasha/core/sync/remote_content_data_source.dart';
import 'package:maatribhasha/core/sync/worksheet_generation_queue.dart';
import 'package:maatribhasha/core/sync/worksheet_generation_sync.dart';
import 'package:maatribhasha/features/resources/presentation/bloc/content_generation_bloc.dart';

// ---------------------------------------------------------------------------
// Fakes (no SQLite, no network, no providers).
// ---------------------------------------------------------------------------

class FakeConnectivity implements ConnectivityService {
  bool online;
  bool reachable;
  FakeConnectivity({this.online = true, this.reachable = true});

  @override
  Stream<bool> get connectivityStream => Stream.value(online);

  @override
  Future<bool> get isOnline async => online;

  @override
  Future<bool> checkBackendReachability(
          {String? baseUrl, Duration? timeout}) async =>
      online && reachable;

  @override
  void simulateOnlineStatus(bool? override) {
    if (override != null) online = override;
  }
}

class FakeRemote implements RemoteContentDataSource {
  int requestCount = 0;
  bool failRequest = false;
  final Map<String, dynamic> readyContent;

  FakeRemote({Map<String, dynamic>? readyContent})
      : readyContent = readyContent ??
            {
              'content_id': 'WS-WEB-1',
              'title': 'Numbers up to 100',
              'title_hi': '100 तक की संख्याएं',
              'grade': 2,
              'subject': 'Mathematics',
              'curriculum_id': 'M2.1.4',
              'target_language': 'sat',
              'difficulty': 'medium',
              'content_type': 'worksheet',
              'questions': [
                {
                  'questionNumber': 1,
                  'promptHindi': 'प्रश्न एक?',
                  'promptTribal': '[sat] प्रश्न एक?',
                  'visualIllustration': '',
                  'options': ['1', '2'],
                  'answer': '1',
                }
              ],
            };

  @override
  Future<GenerationJobModel> requestGeneration(
    TeacherGenerationRequestModel request, {
    String? idempotencyKey,
  }) async {
    requestCount++;
    if (failRequest) throw const SocketException('unreachable');
    return GenerationJobModel(
      jobId: 'job_web_${request.requestId}',
      status: 'READY',
      contentId: 'WS-WEB-1',
      contentType: request.contentType,
      grade: request.grade,
      targetLanguage: request.targetLanguage,
      content: readyContent,
    );
  }

  @override
  Future<GenerationJobModel> getJobStatus(String jobId) async {
    if (failRequest) throw const SocketException('unreachable');
    return GenerationJobModel(
      jobId: jobId,
      status: 'READY',
      contentId: 'WS-WEB-1',
      contentType: 'worksheet',
      grade: 2,
      targetLanguage: 'sat',
      content: readyContent,
    );
  }

  @override
  Future<GenerationJobModel> approveJob(String jobId,
      {String? santaliScriptConfirmed, String? notes}) async {
    throw UnimplementedError();
  }

  @override
  Future<File> downloadAsset(String a, String b) async {
    throw UnsupportedError('web has no File downloads');
  }
}

class FailingQueue implements WorksheetGenerationQueueRepository {
  @override
  Future<String> enqueue(TeacherGenerationRequestModel request) async {
    throw const QueuePersistenceException();
  }

  @override
  Future<void> markCompleted(String requestId) async {}

  @override
  Future<void> markFailed(String requestId, String errorMessage) async {}

  @override
  Future<List<QueuedWorksheetEntry>> pendingEntries() async => [];

  @override
  Future<int> pendingCount() async => 0;
}

TeacherGenerationRequestModel teacherRequest() {
  return buildWorksheetGenerationRequest(
    grade: 2,
    subject: 'Mathematics',
    topic: 'Numbers up to 100',
    nipunOutcome: 'M2.1.4',
    targetLanguage: TribalLanguage.santali,
    difficulty: DifficultyLevel.medium,
    type: WorksheetType.practice,
    questionCount: 5,
    visualSupport: true,
    bilingualAnswers: true,
    audioCue: true,
    deviceId: 'tablet_web_001',
    teacherId: 'teacher_web_1',
    origin: 'offline',
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('WEB queue (SharedPreferences, no sqlite)', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    test('1. offline request saves without any SQLite involvement', () async {
      final queue = WebWorksheetGenerationQueue(prefs: prefs);
      final id = await queue.enqueue(teacherRequest());
      expect(id, isNotEmpty);
      expect(await queue.pendingCount(), 1);
    });

    test('2. request survives reload/reinitialization', () async {
      final first = WebWorksheetGenerationQueue(prefs: prefs);
      final id = await first.enqueue(teacherRequest());
      await prefs.reload();
      final second = WebWorksheetGenerationQueue(prefs: prefs);
      final pending = await second.pendingEntries();
      expect(pending.length, 1);
      expect(pending.single.requestId, id);
      expect(pending.single.request.topic, 'Numbers up to 100');
    });

    test('3. stored request contains all selected parameters', () async {
      final queue = WebWorksheetGenerationQueue(prefs: prefs);
      await queue.enqueue(teacherRequest());
      final raw = prefs.getString(kWebWorksheetQueueStorageKey)!;
      final stored = jsonDecode(raw) as Map<String, dynamic>;
      final entryJson =
          Map<String, dynamic>.from(stored.values.single as Map);
      final entry = QueuedWorksheetEntry.tryFromJson(entryJson)!;
      final r = entry.request;
      expect(r.requestId, isNotNull);
      expect(r.teacherId, 'teacher_web_1');
      expect(r.deviceId, 'tablet_web_001');
      expect(r.grade, 2);
      expect(r.subject, 'Mathematics');
      expect(r.topic, 'Numbers up to 100');
      expect(r.nipunOutcome, 'M2.1.4');
      expect(r.sourceLanguage, 'hi');
      expect(r.targetLanguage, 'sat');
      expect(r.worksheetType, 'practice');
      expect(r.questionCount, 5);
      expect(r.difficulty, 'medium');
      expect(r.visualSupport, isTrue);
      expect(r.bilingualAnswers, isTrue);
      expect(r.audioCue, isTrue);
      expect(entry.status, WorksheetGenerationStatus.pendingGeneration);
      expect(entry.retryCount, 0);
    });

    test('4. pending request can be loaded with metadata', () async {
      final queue = WebWorksheetGenerationQueue(prefs: prefs);
      await queue.enqueue(teacherRequest());
      final pending = await queue.pendingEntries();
      expect(pending.length, 1);
      expect(pending.single.createdAt.isBefore(DateTime.now().add(
            const Duration(seconds: 1),
          )), isTrue);
    });

    test('5+6. pending request syncs when online; success removes it',
        () async {
      final queue = WebWorksheetGenerationQueue(prefs: prefs);
      await queue.enqueue(teacherRequest());
      final remote = FakeRemote();
      CompletedWebWorksheet? done;
      final adapter = WebWorksheetSyncAdapter(
        queue: queue,
        remote: remote,
        connectivity: FakeConnectivity(online: true, reachable: true),
        onCompleted: (c) async => done = c,
      );
      final result = await adapter.syncPending();
      expect(result.attempted, isTrue);
      expect(result.completed, 1);
      expect(remote.requestCount, 1);
      expect(done, isNotNull);
      expect(done!.content['curriculum_id'], 'M2.1.4');
      expect(await queue.pendingCount(), 0);
    });

    test('7. failed sync keeps the request pending for retry', () async {
      final queue = WebWorksheetGenerationQueue(prefs: prefs);
      await queue.enqueue(teacherRequest());
      final remote = FakeRemote()..failRequest = true;
      final adapter = WebWorksheetSyncAdapter(
        queue: queue,
        remote: remote,
        connectivity: FakeConnectivity(online: true, reachable: true),
      );
      final result = await adapter.syncPending();
      expect(result.attempted, isTrue);
      expect(result.completed, 0);
      expect(result.remaining, 1);
      final pending = await queue.pendingEntries();
      expect(pending.single.status, WorksheetGenerationStatus.failedRetryable);
      expect(pending.single.retryCount, 1);
    });

    test('offline device never attempts upload', () async {
      final queue = WebWorksheetGenerationQueue(prefs: prefs);
      await queue.enqueue(teacherRequest());
      final remote = FakeRemote();
      final adapter = WebWorksheetSyncAdapter(
        queue: queue,
        remote: remote,
        connectivity: FakeConnectivity(online: false, reachable: false),
      );
      final result = await adapter.syncPending();
      expect(result.attempted, isFalse);
      expect(remote.requestCount, 0);
      expect(await queue.pendingCount(), 1);
    });

    test('8. duplicate request_id is not regenerated or duplicated',
        () async {
      final queue = WebWorksheetGenerationQueue(prefs: prefs);
      final req = teacherRequest();
      final first = await queue.enqueue(req);
      final second = await queue.enqueue(req);
      expect(second, first);
      expect(await queue.pendingCount(), 1);
    });

    test('malformed stored JSON never crashes the queue', () async {
      await prefs.setString(kWebWorksheetQueueStorageKey, '{broken json');
      final queue = WebWorksheetGenerationQueue(prefs: prefs);
      expect(await queue.pendingEntries(), isEmpty);
      // Queue still usable afterwards.
      await queue.enqueue(teacherRequest());
      expect(await queue.pendingCount(), 1);
    });
  });

  group('WEB bloc honesty (no false Saved-for-Later)', () {
    test('9. persistence failure surfaces Could-not-save, never saved',
        () async {
      final bloc = ContentGenerationBloc(
        remoteDataSource: FakeRemote(),
        connectivityService:
            FakeConnectivity(online: false, reachable: false),
        queueRepository: FailingQueue(),
        worksheetStore: MemoryGeneratedWorksheetStore(),
      );
      bloc.add(QueueOfflineGenerationEvent(request: teacherRequest()));
      final failed = await bloc.stream.firstWhere(
        (s) => s is ContentGenerationFailed,
      ) as ContentGenerationFailed;
      expect(failed.isPersistenceError, isTrue);
      expect(
        failed.errorMessage,
        'The worksheet request could not be saved on this device. Please try again.',
      );
      expect(failed.errorMessage.toLowerCase().contains('sqlite'), isFalse);
      expect(failed.errorMessage.toLowerCase().contains('sqlite3'), isFalse);
      await bloc.close();
    });

    test('web offline queue success emits QueuedOffline (saved truthfully)',
        () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final bloc = ContentGenerationBloc(
        remoteDataSource: FakeRemote(),
        connectivityService:
            FakeConnectivity(online: false, reachable: false),
        queueRepository: WebWorksheetGenerationQueue(prefs: prefs),
        worksheetStore: MemoryGeneratedWorksheetStore(),
      );
      bloc.add(QueueOfflineGenerationEvent(request: teacherRequest()));
      final queued = await bloc.stream.firstWhere(
        (s) => s is ContentGenerationQueuedOffline,
      ) as ContentGenerationQueuedOffline;
      expect(queued.requestId, isNotEmpty);
      await bloc.close();
    });

    test('memory store saves completed payloads without SQLite', () async {
      final store = MemoryGeneratedWorksheetStore();
      final saved = await store.saveCompletedWorksheet('WS-WEB-1', {
        'title': 'Numbers up to 100',
        'title_hi': '100 तक की संख्याएं',
        'grade': 2,
        'subject': 'Mathematics',
        'curriculum_id': 'M2.1.4',
        'target_language': 'sat',
        'difficulty': 'medium',
        'content_type': 'worksheet',
        'questions': [],
      });
      expect(saved.id, 'WS-WEB-1');
      expect(saved.outcomeCode, 'M2.1.4');
      expect(saved.language, 'sat');
    });
  });

  group('NATIVE queue (Drift/SQLite unchanged)', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    test('10. Drift/SQLite offline request still works', () async {
      final queue = NativeWorksheetGenerationQueue(db);
      final id = await queue.enqueue(teacherRequest());
      expect(id, isNotEmpty);
      final rows = await db.syncQueueDao.getPendingOperations();
      expect(rows.length, 1);
      expect(rows.single.entityType, kWorksheetGenerationEntityType);
      expect(rows.single.status, 'PENDING');
      final pending = await queue.pendingEntries();
      expect(pending.single.request.topic, 'Numbers up to 100');
      expect(
        pending.single.status,
        WorksheetGenerationStatus.pendingGeneration,
      );
    });

    test('11. legacy sync-queue write path is unchanged', () async {
      final id = await queueWorksheetGenerationRequest(db, teacherRequest());
      expect(await db.syncQueueDao.getPendingCount(), 1);
      final pending = await db.syncQueueDao.getPendingOperations();
      expect(pending.single.id, id);
      expect(pending.single.status, 'PENDING');
    });

    test('native failed entries stay retryable; completed ones clear',
        () async {
      final queue = NativeWorksheetGenerationQueue(db);
      final id = await queue.enqueue(teacherRequest());
      await queue.markFailed(id, 'Server unavailable.');
      var pending = await queue.pendingEntries();
      expect(
        pending.single.status,
        WorksheetGenerationStatus.failedRetryable,
      );
      expect(pending.single.retryCount, 1);
      await queue.markCompleted(id);
      expect(await queue.pendingCount(), 0);
    });

    test('12. native implementation is Drift-backed', () async {
      final queue = NativeWorksheetGenerationQueue(db);
      expect(queue.db, same(db));
      await queue.enqueue(teacherRequest());
      // Proof it went through Drift/SQLite: visible in the sync_queue table.
      final all = await db.syncQueueDao.getAllQueueItems();
      expect(all.length, 1);
    });
  });

  group('UI copy guards', () {
    test('13. generate button states are state-derived, not static', () async {
      final screen = File(
        'lib/features/resources/presentation/pages/resource_screens.dart',
      ).readAsStringSync();
      for (final label in [
        'Generate Bilingual Worksheet',
        'Sending Request...',
        'Generating Worksheet...',
        'Saved for Sync',
        'Retry Generation',
      ]) {
        expect(screen.contains(label), isTrue, reason: label);
      }
      expect(screen.contains('BlocBuilder<ContentGenerationBloc'), isTrue);
    });

    test('14. no sqlite internals exposed in teacher-facing UI', () async {
      final dialog = File(
        'lib/features/resources/presentation/widgets/generation_progress_dialog.dart',
      ).readAsStringSync();
      final screen = File(
        'lib/features/resources/presentation/pages/resource_screens.dart',
      ).readAsStringSync();
      final blocSrc = File(
        'lib/features/resources/presentation/bloc/content_generation_bloc.dart',
      ).readAsStringSync();
      for (final src in [dialog, screen]) {
        expect(src.toLowerCase().contains('sqlite'), isFalse);
        expect(src.toLowerCase().contains('sqlite3.js'), isFalse);
      }
      expect(
        blocSrc.contains('Could not save the offline request:'),
        isFalse,
        reason: 'raw-exception message must be gone',
      );
      expect(
        dialog.contains("Couldn't Save Request"),
        isTrue,
        reason: 'honest failure title',
      );
      expect(dialog.contains('Saved for Later'), isTrue);
    });

    test('15. no provider/debug text in teacher-facing UI', () async {
      final dialog = File(
        'lib/features/resources/presentation/widgets/generation_progress_dialog.dart',
      ).readAsStringSync();
      final screen = File(
        'lib/features/resources/presentation/pages/resource_screens.dart',
      ).readAsStringSync();
      for (final src in [dialog, screen]) {
        expect(src.toLowerCase().contains('sarvam'), isFalse);
        expect(src.contains('10-B'), isFalse);
      }
    });
  });
}
