import 'dart:async';
import 'dart:convert';
import 'package:drift/drift.dart';
import '../database/account_scope.dart';
import '../database/app_database.dart';
import '../network/connectivity_service.dart';
import 'remote_data_source.dart';
import 'sync_status.dart';

class SyncManager {
  final AppDatabase db;
  final ConnectivityService connectivityService;
  final RemoteDataSource remoteDataSource;

  /// Resolves the authenticated Supabase user UUID. Only that account's
  /// queue is ever executed; other accounts' rows wait untouched.
  final String? Function()? currentUserIdProvider;

  /// Invoked after each operation syncs, with the server's per-operation
  /// result (may carry generation payloads). Never blocks the queue loop.
  final Future<void> Function(SyncQueueData op, Map<String, dynamic>? result)?
      onOperationResult;

  bool _isSyncing = false;
  DateTime? _lastSyncTime;
  StreamSubscription? _connectivitySub;

  final StreamController<SyncProgress> _progressController =
      StreamController<SyncProgress>.broadcast();

  SyncManager({
    required this.db,
    required this.connectivityService,
    required this.remoteDataSource,
    this.onOperationResult,
    this.currentUserIdProvider,
  }) {
    // Listen for network becoming available
    _connectivitySub = connectivityService.connectivityStream.listen((isOnline) {
      if (isOnline) {
        syncPendingOperations();
      }
    });

    // Seed initial progress
    _emitProgress(SyncProcessState.idle);
  }

  bool get isSyncing => _isSyncing;
  DateTime? get lastSyncTime => _lastSyncTime;
  Stream<SyncProgress> get progressStream => _progressController.stream;

  Future<void> _emitProgress(SyncProcessState state, {String? error}) async {
    final pending = await _ownedPendingCount(_currentOwner);
    _progressController.add(
      SyncProgress(
        pendingCount: pending,
        state: state,
        lastSyncTime: _lastSyncTime,
        errorMessage: error,
      ),
    );
  }

  /// Synchronizes all pending operations. Protected against concurrent runs.
  Future<int> syncPendingOperations() async {
    if (_isSyncing) {
      return 0; // Guard against concurrent sync invocations
    }
    _isSyncing = true;

    int processedCount = 0;
    String? lastError;

    try {
      final isOnline = await connectivityService.isOnline;
      if (!isOnline) {
        await _emitProgress(SyncProcessState.idle);
        return 0;
      }

      await _emitProgress(SyncProcessState.syncing);

      final ownerId = _currentOwner;
      final pendingOps = await _ownedPendingOperations(ownerId);

      for (final op in pendingOps) {
        try {
          await db.syncQueueDao.markSyncing(op.id);
          final result = await remoteDataSource.pushSyncOperationWithResult(op);
          await db.syncQueueDao.markSynced(op.id);

          // Update local entity sync status if applicable
          await _updateEntitySyncStatus(op.entityType, op.entityId, 'synced');
          processedCount++;

          final handler = onOperationResult;
          if (handler != null) {
            try {
              await handler(op, result);
            } catch (_) {
              // Result handling must never fail the synced queue entry.
            }
          }
        } catch (e) {
          lastError = e.toString();
          // FAILURE PRESERVATION: Local data is preserved, retry count incremented, error recorded.
          await db.syncQueueDao.markFailed(op.id, lastError);
        }
      }

      if (processedCount > 0 && lastError == null) {
        _lastSyncTime = DateTime.now();
      }
    } finally {
      _isSyncing = false;
      await _emitProgress(
        lastError != null ? SyncProcessState.error : SyncProcessState.idle,
        error: lastError,
      );
    }

    return processedCount;
  }

  String? get _currentOwner {
    try {
      final id = currentUserIdProvider?.call()?.trim();
      if (id == null || id.isEmpty) return null;
      return id;
    } catch (_) {
      return null;
    }
  }

  bool get _legacy => currentUserIdProvider == null;

  /// Only the current account's PENDING/FAILED rows. Unauthenticated sync
  /// is a no-op so account A's queue can never execute as account B.
  /// Legacy mode (no provider) syncs everything as before.
  Future<List<SyncQueueData>> _ownedPendingOperations(String? ownerId) async {
    if (ownerId == null && !_legacy) return const [];
    if (_legacy) return db.syncQueueDao.getPendingOperations(limit: 100);
    await ensureAccountIsolation(db);
    final all = await db.syncQueueDao.getPendingOperations(limit: 200);
    final owned = <SyncQueueData>[];
    for (final op in all) {
      var owner = '';
      try {
        final payload = jsonDecode(op.payload) as Map<String, dynamic>;
        owner = (payload['owner_user_id'] ?? payload['ownerUserId'] ?? '')
            .toString();
      } catch (_) {}
      if (owner.isEmpty) {
        try {
          final rows = await db.customSelect(
            'SELECT owner_user_id FROM sync_queue WHERE id = ? LIMIT 1',
            variables: [Variable.withString(op.id)],
          ).get();
          if (rows.isNotEmpty) {
            owner = (rows.first.data['owner_user_id'] ?? '').toString();
          }
        } catch (_) {}
      }
      if (owner == ownerId) owned.add(op);
    }
    return owned.take(100).toList();
  }

  Future<void> _updateEntitySyncStatus(
    String entityType,
    String entityId,
    String status,
  ) async {
    try {
      switch (entityType) {
        case 'lesson':
          await (db.update(db.lessons)..where((tbl) => tbl.id.equals(entityId))).write(
            LessonsCompanion(syncStatus: Value(status)),
          );
          break;
        case 'assessment_result':
          await (db.update(db.assessmentResults)..where((tbl) => tbl.id.equals(entityId))).write(
            AssessmentResultsCompanion(syncStatus: Value(status)),
          );
          break;
        case 'translation_feedback':
          await (db.update(db.translationFeedback)..where((tbl) => tbl.id.equals(entityId))).write(
            TranslationFeedbackCompanion(syncStatus: Value(status)),
          );
          break;
      }
    } catch (_) {
      // Best-effort local entity tag update
    }
  }

  Future<int> _ownedPendingCount(String? ownerId) async {
    if (ownerId == null && !_legacy) return 0;
    if (_legacy) {
      try {
        return await db.syncQueueDao.getPendingCount();
      } catch (_) {
        return 0;
      }
    }
    try {
      final rows = await db.customSelect(
        'SELECT COUNT(*) AS c FROM sync_queue WHERE owner_user_id = ? '
        'AND (status = ? OR status = ?)',
        variables: [
          Variable.withString(ownerId!),
          Variable.withString('PENDING'),
          Variable.withString('FAILED'),
        ],
      ).get();
      if (rows.isNotEmpty) return (rows.first.data['c'] as num?)?.toInt() ?? 0;
    } catch (_) {}
    return 0;
  }

  void dispose() {
    _connectivitySub?.cancel();
    _progressController.close();
  }
}
