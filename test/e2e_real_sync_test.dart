import 'dart:convert';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maatribhasha/core/database/app_database.dart';
import 'package:maatribhasha/core/network/connectivity_service.dart';
import 'package:maatribhasha/core/sync/http_remote_data_source.dart';
import 'package:maatribhasha/core/sync/sync_manager.dart';

class AlwaysOnlineConnectivity implements ConnectivityService {
  @override
  Stream<bool> get connectivityStream => const Stream.empty();

  @override
  Future<bool> get isOnline async => true;

  @override
  Future<bool> checkBackendReachability({String? baseUrl, Duration? timeout}) async => true;

  @override
  void simulateOnlineStatus(bool? override) {}
}

void main() {
  late AppDatabase db;
  late AlwaysOnlineConnectivity connectivity;
  late HttpRemoteDataSource remoteDataSource;
  late SyncManager syncManager;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    connectivity = AlwaysOnlineConnectivity();
    remoteDataSource = HttpRemoteDataSource(baseUrl: 'http://127.0.0.1:8000');
    syncManager = SyncManager(
      db: db,
      connectivityService: connectivity,
      remoteDataSource: remoteDataSource,
    );
  });

  tearDown(() async {
    syncManager.dispose();
    await db.close();
  });

  group('Real End-to-End Sync Lifecycle: Flutter -> SQLite -> SyncQueue -> FastAPI -> SQLite SYNCED', () {
    test('Strict E2E Record Lifecycle with Live FastAPI Backend', () async {
      final now = DateTime.now();
      final operationId = 'e2e_op_${now.millisecondsSinceEpoch}';
      final localResultId = 'e2e_res_${now.millisecondsSinceEpoch}';

      // -------------------------------------------------------------
      // PHASE 1: Offline Record Creation in Local Drift/SQLite
      // -------------------------------------------------------------
      // Insert offline assessment result
      await db.assessmentDao.insertAssessmentResult(
        AssessmentResultsCompanion(
          id: Value(localResultId),
          studentId: const Value('std_jharkhand_001'),
          studentName: const Value('Birsa Oraon'),
          outcomeCode: const Value('M2.1.4'),
          outcomeTitle: const Value('Numbers up to 100 (दहाई और इकाई)'),
          totalQuestions: const Value(5),
          correctCount: const Value(4),
          status: const Value('Achieved'),
          unfinishedSkill: const Value('None'),
          recommendedRemediation: const Value('None'),
          completedAt: Value(now),
          syncStatus: const Value('pending'),
        ),
      );

      // Verify offline state in SQLite
      final initialResults = await db.assessmentDao.getAllAssessmentResults();
      expect(initialResults.length, 1);
      expect(initialResults.first.syncStatus, 'pending');

      // -------------------------------------------------------------
      // PHASE 2: Enqueue into SQLite SyncQueue with PENDING status
      // -------------------------------------------------------------
      final payloadJson = jsonEncode({
        'id': localResultId,
        'student_id': 'std_jharkhand_001',
        'student_name': 'Birsa Oraon',
        'outcome_code': 'M2.1.4',
        'score': 4.0,
        'max_score': 5.0,
        'status': 'Achieved',
        'grade': 2,
        'subject': 'Mathematics',
        'completed_at': now.toIso8601String(),
      });

      await db.syncQueueDao.enqueue(
        SyncQueueCompanion(
          id: Value(operationId),
          entityType: const Value('assessment_result'),
          entityId: Value(localResultId),
          operation: const Value('CREATE'),
          payload: Value(payloadJson),
          createdAt: Value(now),
          updatedAt: Value(now),
          status: const Value('PENDING'),
        ),
      );

      final pendingCountBefore = await db.syncQueueDao.getPendingCount();
      expect(pendingCountBefore, 1);

      final queueBefore = await db.syncQueueDao.getAllQueueItems();
      expect(queueBefore.first.status, 'PENDING');
      expect(queueBefore.first.errorMessage, isNull);

      // -------------------------------------------------------------
      // PHASE 3: Execute SyncManager over HTTP to Live FastAPI
      // -------------------------------------------------------------
      final syncedCount = await syncManager.syncPendingOperations();
      expect(syncedCount, 1, reason: 'Expected exactly 1 operation to be synced over HTTP');

      // -------------------------------------------------------------
      // PHASE 4: Verify SQLite State Transition to SYNCED
      // -------------------------------------------------------------
      final pendingCountAfter = await db.syncQueueDao.getPendingCount();
      expect(pendingCountAfter, 0, reason: 'Pending queue count should be 0 after successful sync');

      final queueAfter = await db.syncQueueDao.getAllQueueItems();
      expect(queueAfter.length, 1);
      final syncedItem = queueAfter.first;
      expect(syncedItem.status, 'SYNCED', reason: 'SyncQueue entry must be transitioned to SYNCED');
      expect(syncedItem.errorMessage, isNull);
      expect(syncedItem.lastAttemptAt, isNotNull);

      // Verify Local Entity Status updated to 'synced'
      final resultsAfter = await db.assessmentDao.getAllAssessmentResults();
      expect(resultsAfter.first.syncStatus, 'synced',
          reason: 'AssessmentResult local syncStatus must be marked synced');

      // -------------------------------------------------------------
      // PHASE 5: Idempotency Verification (Repeat transmission)
      // -------------------------------------------------------------
      // Pushing the exact same operation_id again must succeed without error (DUPLICATE_IGNORED)
      await expectLater(
        remoteDataSource.pushSyncOperation(syncedItem),
        completes,
        reason: 'Repeated sync of same operation_id must succeed via backend idempotent ignore',
      );
    });
  });
}
