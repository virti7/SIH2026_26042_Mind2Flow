import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/sync_queue.dart';

part 'sync_queue_dao.g.dart';

@DriftAccessor(tables: [SyncQueue])
class SyncQueueDao extends DatabaseAccessor<AppDatabase> with _$SyncQueueDaoMixin {
  SyncQueueDao(super.db);

  Future<void> enqueue(SyncQueueCompanion entry) {
    return into(syncQueue).insertOnConflictUpdate(entry);
  }

  Future<List<SyncQueueData>> getPendingOperations({int limit = 100}) {
    return (select(syncQueue)
          ..where((tbl) => tbl.status.equals('PENDING') | tbl.status.equals('FAILED'))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)])
          ..limit(limit))
        .get();
  }

  Future<void> markSyncing(String id) {
    return (update(syncQueue)..where((tbl) => tbl.id.equals(id))).write(
      SyncQueueCompanion(
        status: const Value('SYNCING'),
        lastAttemptAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> markSynced(String id) {
    return (update(syncQueue)..where((tbl) => tbl.id.equals(id))).write(
      SyncQueueCompanion(
        status: const Value('SYNCED'),
        updatedAt: Value(DateTime.now()),
        lastAttemptAt: Value(DateTime.now()),
        errorMessage: const Value(null),
      ),
    );
  }

  Future<void> markFailed(String id, String error) async {
    final item = await (select(syncQueue)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
    final currentRetries = item?.retryCount ?? 0;

    await (update(syncQueue)..where((tbl) => tbl.id.equals(id))).write(
      SyncQueueCompanion(
        status: const Value('FAILED'),
        retryCount: Value(currentRetries + 1),
        lastAttemptAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
        errorMessage: Value(error),
      ),
    );
  }

  Future<int> getPendingCount() async {
    final countExp = syncQueue.id.count();
    final query = selectOnly(syncQueue)
      ..addColumns([countExp])
      ..where(syncQueue.status.equals('PENDING') | syncQueue.status.equals('FAILED'));
    final result = await query.getSingle();
    return result.read(countExp) ?? 0;
  }

  Stream<int> streamPendingCount() {
    final countExp = syncQueue.id.count();
    final query = selectOnly(syncQueue)
      ..addColumns([countExp])
      ..where(syncQueue.status.equals('PENDING') | syncQueue.status.equals('FAILED'));
    return query.map((row) => row.read(countExp) ?? 0).watchSingle();
  }

  Future<List<SyncQueueData>> getAllQueueItems() {
    return (select(syncQueue)..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).get();
  }

  Stream<List<SyncQueueData>> watchAllQueueItems() {
    return (select(syncQueue)..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).watch();
  }

  Future<void> clearSynced() {
    return (delete(syncQueue)..where((tbl) => tbl.status.equals('SYNCED'))).go();
  }
}
