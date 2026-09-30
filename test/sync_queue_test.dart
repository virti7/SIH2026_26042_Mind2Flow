import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maatribhasha/core/database/app_database.dart';
import 'package:maatribhasha/core/network/connectivity_service.dart';
import 'package:maatribhasha/core/sync/remote_data_source.dart';
import 'package:maatribhasha/core/sync/sync_manager.dart';

class MockTestConnectivity implements ConnectivityService {
  bool _online;
  MockTestConnectivity(this._online);

  @override
  Stream<bool> get connectivityStream => const Stream.empty();

  @override
  Future<bool> get isOnline async => _online;

  @override
  Future<bool> checkBackendReachability({String? baseUrl, Duration? timeout}) async => _online;

  @override
  void simulateOnlineStatus(bool? override) {
    if (override != null) _online = override;
  }
}

void main() {
  late AppDatabase db;
  late MockTestConnectivity connectivity;
  late MockRemoteDataSource remoteDataSource;
  late SyncManager syncManager;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    connectivity = MockTestConnectivity(true);
    remoteDataSource = MockRemoteDataSource();
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

  group('Sync Queue & SyncManager Lifecycle Tests', () {
    test('1. Offline enqueue: record created with PENDING status', () async {
      final now = DateTime.now();
      await db.syncQueueDao.enqueue(
        SyncQueueCompanion(
          id: const Value('sync_test_01'),
          entityType: const Value('assessment_result'),
          entityId: const Value('res_101'),
          operation: const Value('CREATE'),
          payload: const Value('{"student": "Birsa", "score": 3}'),
          createdAt: Value(now),
          updatedAt: Value(now),
          status: const Value('PENDING'),
        ),
      );

      final pending = await db.syncQueueDao.getPendingOperations();
      expect(pending.length, 1);
      expect(pending.first.id, 'sync_test_01');
      expect(pending.first.status, 'PENDING');
      expect(pending.first.retryCount, 0);
    });

    test('2. Online sync success: pending operations synchronized and marked SYNCED', () async {
      final now = DateTime.now();
      await db.syncQueueDao.enqueue(
        SyncQueueCompanion(
          id: const Value('sync_test_02'),
          entityType: const Value('teacher_profile'),
          entityId: const Value('t_001'),
          operation: const Value('UPDATE'),
          payload: const Value('{"name": "Test Teacher"}'),
          createdAt: Value(now),
          updatedAt: Value(now),
          status: const Value('PENDING'),
        ),
      );

      expect(await db.syncQueueDao.getPendingCount(), 1);

      // Perform sync
      final syncedCount = await syncManager.syncPendingOperations();
      expect(syncedCount, 1);

      // Verify item marked SYNCED
      final allItems = await db.syncQueueDao.getAllQueueItems();
      final item = allItems.firstWhere((i) => i.id == 'sync_test_02');
      expect(item.status, 'SYNCED');
      expect(item.lastAttemptAt, isNotNull);
      expect(await db.syncQueueDao.getPendingCount(), 0);
    });

    test('3. Sync failure: records remain intact in SQLite, status set to FAILED, retry count incremented', () async {
      final now = DateTime.now();
      await db.syncQueueDao.enqueue(
        SyncQueueCompanion(
          id: const Value('sync_test_03'),
          entityType: const Value('saved_material'),
          entityId: const Value('mat_202'),
          operation: const Value('CREATE'),
          payload: const Value('{"title": "Worksheet 1"}'),
          createdAt: Value(now),
          updatedAt: Value(now),
          status: const Value('PENDING'),
        ),
      );

      // Configure mock remote to simulate district server outage / 503
      remoteDataSource.shouldFail = true;

      // Attempt sync
      final syncedCount = await syncManager.syncPendingOperations();
      expect(syncedCount, 0); // 0 succeeded

      // Verify item was NOT lost or deleted! Status must be FAILED, retry count incremented
      final items = await db.syncQueueDao.getAllQueueItems();
      final failedItem = items.firstWhere((i) => i.id == 'sync_test_03');
      expect(failedItem.status, 'FAILED');
      expect(failedItem.retryCount, 1);
      expect(failedItem.errorMessage, contains('Simulated'));

      // Pending count should still count FAILED items so they get retried
      expect(await db.syncQueueDao.getPendingCount(), 1);
    });

    test('4. Retry recovery: failed records transition to SYNCED when backend returns', () async {
      final now = DateTime.now();
      await db.syncQueueDao.enqueue(
        SyncQueueCompanion(
          id: const Value('sync_test_04'),
          entityType: const Value('lesson'),
          entityId: const Value('lp_404'),
          operation: const Value('CREATE'),
          payload: const Value('{"outcomeCode": "M2.1.4"}'),
          createdAt: Value(now),
          updatedAt: Value(now),
          status: const Value('FAILED'),
          retryCount: const Value(1),
          errorMessage: const Value('Network timeout'),
        ),
      );

      // Server is back online and accepting requests
      remoteDataSource.shouldFail = false;

      // Retry sync
      final syncedCount = await syncManager.syncPendingOperations();
      expect(syncedCount, 1);

      final items = await db.syncQueueDao.getAllQueueItems();
      final syncedItem = items.firstWhere((i) => i.id == 'sync_test_04');
      expect(syncedItem.status, 'SYNCED');
      expect(syncedItem.errorMessage, isNull);
    });

    test('5. Concurrency protection: concurrent sync calls do not conflict', () async {
      final now = DateTime.now();
      await db.syncQueueDao.enqueue(
        SyncQueueCompanion(
          id: const Value('sync_test_05'),
          entityType: const Value('assessment_result'),
          entityId: const Value('res_505'),
          operation: const Value('CREATE'),
          payload: const Value('{"score": 4}'),
          createdAt: Value(now),
          updatedAt: Value(now),
          status: const Value('PENDING'),
        ),
      );

      // Launch 3 simultaneous sync triggers
      final future1 = syncManager.syncPendingOperations();
      final future2 = syncManager.syncPendingOperations();
      final future3 = syncManager.syncPendingOperations();

      final results = await Future.wait([future1, future2, future3]);

      // Exactly one execution processes the queue, others return 0 due to concurrency guard
      final totalProcessed = results.reduce((a, b) => a + b);
      expect(totalProcessed, 1);
    });
  });
}
