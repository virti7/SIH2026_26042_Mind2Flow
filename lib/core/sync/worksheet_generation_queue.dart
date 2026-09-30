import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../database/app_database.dart';
import '../network/connectivity_service.dart';
import 'remote_content_data_source.dart';
import 'worksheet_generation_sync.dart';

/// Versioned browser-storage key for the web offline worksheet queue.
/// Bump the suffix if the stored schema ever changes.
const String kWebWorksheetQueueStorageKey = 'worksheet_generation_queue_v1';

/// Thrown when an offline worksheet request cannot be persisted on the
/// device. Carries only a teacher-safe message: technical details
/// (sqlite/drift/storage internals) must never reach the UI.
class QueuePersistenceException implements Exception {
  final String message;
  const QueuePersistenceException(
      [this.message = 'The worksheet request could not be saved on this device. Please try again.']);

  @override
  String toString() => message;
}

/// One queued worksheet-generation request plus its local lifecycle metadata.
/// Only the teacher's real generation request is persisted: never questions,
/// translations, previews, or progress values.
class QueuedWorksheetEntry {
  final TeacherGenerationRequestModel request;
  final DateTime createdAt;
  final String status;
  final int retryCount;
  final String? errorMessage;

  const QueuedWorksheetEntry({
    required this.request,
    required this.createdAt,
    this.status = WorksheetGenerationStatus.pendingGeneration,
    this.retryCount = 0,
    this.errorMessage,
  });

  String get requestId => request.requestId ?? '';

  Map<String, dynamic> toJson() => {
        'request': request.toJson(),
        'created_at': createdAt.toIso8601String(),
        'status': status,
        'retry_count': retryCount,
        if (errorMessage != null) 'error_message': errorMessage,
      };

  /// Returns null when [json] is malformed so callers can skip the row
  /// instead of crashing.
  static QueuedWorksheetEntry? tryFromJson(Map<String, dynamic> json) {
    try {
      final rawRequest = json['request'];
      if (rawRequest is! Map) return null;
      final request = TeacherGenerationRequestModel.fromJson(
        Map<String, dynamic>.from(rawRequest),
      );
      if ((request.requestId ?? '').isEmpty) return null;
      DateTime createdAt;
      try {
        createdAt = DateTime.parse(json['created_at'].toString());
      } catch (_) {
        createdAt = DateTime.now();
      }
      final retry = json['retry_count'];
      return QueuedWorksheetEntry(
        request: request,
        createdAt: createdAt,
        status: (json['status'] ?? WorksheetGenerationStatus.pendingGeneration)
            .toString(),
        retryCount: retry is num ? retry.toInt() : 0,
        errorMessage: json['error_message']?.toString(),
      );
    } catch (_) {
      return null;
    }
  }
}

/// Platform-neutral persistence for offline worksheet-generation requests.
///
/// - Native (Android/iOS/desktop): [NativeWorksheetGenerationQueue] backed by
///   Drift/SQLite + the existing sync queue (unchanged production path).
/// - Web: [WebWorksheetGenerationQueue] backed by SharedPreferences JSON.
///
/// The generation bloc depends only on this interface and never touches
/// SQLite or browser storage directly, so no `kIsWeb` checks leak into UI.
abstract class WorksheetGenerationQueueRepository {
  /// Stores [request] for later generation. Idempotent on `request_id`: a
  /// duplicate enqueue returns the existing id without creating a second
  /// row or regenerating the id. Throws [QueuePersistenceException] when
  /// persistence genuinely fails.
  Future<String> enqueue(TeacherGenerationRequestModel request);

  /// Pending (including retryable-failed) entries, oldest first.
  Future<List<QueuedWorksheetEntry>> pendingEntries();

  Future<int> pendingCount();

  /// Removes the entry after the server successfully generated the worksheet.
  Future<void> markCompleted(String requestId);

  /// Keeps the entry for retry with an incremented retry count.
  Future<void> markFailed(String requestId, String errorMessage);
}

/// Native implementation: Drift/SQLite `sync_queue` rows with
/// `entity_type == worksheet_generation`. This is the unchanged Android
/// production path (Drift -> SQLite -> sync_queue -> SyncManager -> HTTP).
class NativeWorksheetGenerationQueue
    implements WorksheetGenerationQueueRepository {
  final AppDatabase db;
  final String? Function()? currentUserIdProvider;

  NativeWorksheetGenerationQueue(this.db, {this.currentUserIdProvider});

  String? get _ownerId {
    try {
      final id = currentUserIdProvider?.call()?.trim();
      if (id == null || id.isEmpty) return null;
      return id;
    } catch (_) {
      return null;
    }
  }

  bool get _legacy => currentUserIdProvider == null;

  @override
  Future<String> enqueue(TeacherGenerationRequestModel request) async {
    final ownerId = _ownerId;
    if (!_legacy && ownerId == null) throw const QueuePersistenceException(
        'Sign in required to queue worksheet generation.');
    final requestId = request.requestId ?? const Uuid().v4();
    try {
      final existing = await (db.select(db.syncQueue)
            ..where((t) => t.id.equals(requestId)))
          .getSingleOrNull();
      if (existing != null) return requestId;
      final now = DateTime.now();
      final effective = request.requestId == null
          ? TeacherGenerationRequestModel.fromJson({
              ...request.toJson(),
              'request_id': requestId,
              'idempotency_key': request.idempotencyKey ?? requestId,
              'teacher_id': (request.toJson()['teacher_id'] ?? ownerId).toString(),
              'owner_user_id': ownerId,
            })
          : TeacherGenerationRequestModel.fromJson({
              ...request.toJson(),
              'owner_user_id': ownerId,
            });
      await db.syncQueueDao.enqueue(
        SyncQueueCompanion(
          id: Value(requestId),
          entityType: const Value(kWorksheetGenerationEntityType),
          entityId: Value(requestId),
          operation: const Value('CREATE'),
          payload: Value(jsonEncode(effective.toJson())),
          createdAt: Value(now),
          updatedAt: Value(now),
          status: const Value('PENDING'),
        ),
      );
      try {
        await db.customStatement(
          'UPDATE sync_queue SET owner_user_id = ? WHERE id = ?',
          [ownerId, requestId],
        );
      } catch (_) {}
      return requestId;
    } catch (_) {
      throw const QueuePersistenceException();
    }
  }

  @override
  Future<List<QueuedWorksheetEntry>> pendingEntries() async {
    final ownerId = _ownerId;
    if (!_legacy && ownerId == null) return const [];
    final rows = await (db.select(db.syncQueue)
          ..where((t) =>
              t.entityType.equals(kWorksheetGenerationEntityType) &
              (t.status.equals('PENDING') | t.status.equals('FAILED')))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
    final entries = <QueuedWorksheetEntry>[];
    for (final row in rows) {
      try {
        final payload = jsonDecode(row.payload);
        if (payload is! Map) continue;
        final map = Map<String, dynamic>.from(payload);
        // Owner gate: payload owner wins; fall back to sync_queue column.
        var owner = (map['owner_user_id'] ?? map['ownerUserId'] ?? map['teacher_id'] ?? '').toString();
        if (owner.isEmpty) {
          try {
            final col = await db.customSelect(
              'SELECT owner_user_id FROM sync_queue WHERE id = ? LIMIT 1',
              variables: [Variable.withString(row.id)],
            ).get();
            if (col.isNotEmpty) {
              owner = (col.first.data['owner_user_id'] ?? '').toString();
            }
          } catch (_) {}
        }
        // Legacy rows with no owner stay hidden from every account
        // (scoped mode). Legacy mode (no provider) returns everything.
        if (!_legacy && owner != ownerId) continue;
        final request = TeacherGenerationRequestModel.fromJson(
          Map<String, dynamic>.from(payload),
        );
        entries.add(QueuedWorksheetEntry(
          request: request,
          createdAt: row.createdAt,
          status: row.status == 'FAILED'
              ? WorksheetGenerationStatus.failedRetryable
              : WorksheetGenerationStatus.pendingGeneration,
          retryCount: row.retryCount,
          errorMessage: row.errorMessage,
        ));
      } catch (_) {
        // Skip unreadable rows; never crash the queue read.
      }
    }
    return entries;
  }

  @override
  Future<int> pendingCount() async {
    return (await pendingEntries()).length;
  }

  @override
  Future<void> markCompleted(String requestId) async {
    if (_legacy) {
      await db.syncQueueDao.markSynced(requestId);
      return;
    }
    final ownerId = _ownerId;
    if (ownerId == null) return;
    // Verify ownership before mutating another account's queue entry.
    final entries = await pendingEntries();
    if (!entries.any((e) => e.requestId == requestId)) return;
    await db.syncQueueDao.markSynced(requestId);
  }

  @override
  Future<void> markFailed(String requestId, String errorMessage) async {
    if (_legacy) {
      await db.syncQueueDao.markFailed(requestId, errorMessage);
      return;
    }
    final ownerId = _ownerId;
    if (ownerId == null) return;
    final entries = await pendingEntries();
    if (!entries.any((e) => e.requestId == requestId)) return;
    await db.syncQueueDao.markFailed(requestId, errorMessage);
  }
}

/// Web implementation: browser-persistent JSON in SharedPreferences under a
/// versioned key. Survives widget rebuilds, route changes, browser refresh,
/// and app restart. Never touches Drift/SQLite, FastAPI, or any translation
/// provider: it only stores the teacher's request until sync.
class WebWorksheetGenerationQueue
    implements WorksheetGenerationQueueRepository {
  final SharedPreferences? prefs;
  final String? Function()? currentUserIdProvider;

  /// When [prefs] is null (browser storage unavailable) the queue degrades
  /// to a session in-memory map instead of crashing. Session-only entries
  /// are still never fabricated into worksheets.
  WebWorksheetGenerationQueue({this.prefs, this.currentUserIdProvider});

  String get _storageKey {
    if (currentUserIdProvider == null) return kWebWorksheetQueueStorageKey;
    var owner = 'unowned';
    try {
      final id = currentUserIdProvider?.call()?.trim();
      if (id != null && id.isNotEmpty) owner = id;
    } catch (_) {}
    return '${kWebWorksheetQueueStorageKey}:$owner';
  }

  final Map<String, Map<String, dynamic>> _memoryFallbackByOwner = {};

  Map<String, dynamic> get _memoryFallback {
    var owner = 'unowned';
    try {
      final id = currentUserIdProvider?.call()?.trim();
      if (id != null && id.isNotEmpty) owner = id;
    } catch (_) {}
    return _memoryFallbackByOwner.putIfAbsent(owner, () => {});
  }

  Future<Map<String, dynamic>> _readAll() async {
    final p = prefs;
    if (p == null) return Map<String, dynamic>.from(_memoryFallback);
    try {
      final raw = p.getString(_storageKey);
      if (raw == null || raw.isEmpty) return {};
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return {};
      return Map<String, dynamic>.from(decoded);
    } catch (_) {
      // Malformed stored JSON: start clean rather than crashing.
      return {};
    }
  }

  Future<void> _writeAll(Map<String, dynamic> map) async {
    final p = prefs;
    if (p == null) {
      _memoryFallback
        ..clear()
        ..addAll(map);
      return;
    }
    try {
      final ok =
          await p.setString(_storageKey, jsonEncode(map));
      if (!ok) throw const QueuePersistenceException();
    } catch (e) {
      if (e is QueuePersistenceException) rethrow;
      throw const QueuePersistenceException();
    }
  }

  @override
  Future<String> enqueue(TeacherGenerationRequestModel request) async {
    final requestId = request.requestId ?? const Uuid().v4();
    final effective = request.requestId == null
        ? TeacherGenerationRequestModel.fromJson({
            ...request.toJson(),
            'request_id': requestId,
            'idempotency_key': request.idempotencyKey ?? requestId,
          })
        : request;
    final all = await _readAll();
    // Duplicate request_id: keep the original, never regenerate or duplicate.
    if (all.containsKey(requestId)) return requestId;
    all[requestId] = QueuedWorksheetEntry(
      request: effective,
      createdAt: DateTime.now(),
    ).toJson();
    await _writeAll(all);
    return requestId;
  }

  @override
  Future<List<QueuedWorksheetEntry>> pendingEntries() async {
    final all = await _readAll();
    final entries = <QueuedWorksheetEntry>[];
    for (final value in all.values) {
      if (value is! Map) continue;
      final entry = QueuedWorksheetEntry.tryFromJson(
        Map<String, dynamic>.from(value),
      );
      if (entry == null) continue;
      if (entry.status == WorksheetGenerationStatus.completed) continue;
      entries.add(entry);
    }
    entries.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return entries;
  }

  @override
  Future<int> pendingCount() async => (await pendingEntries()).length;

  @override
  Future<void> markCompleted(String requestId) async {
    final all = await _readAll();
    all.remove(requestId);
    await _writeAll(all);
  }

  @override
  Future<void> markFailed(String requestId, String errorMessage) async {
    final all = await _readAll();
    final raw = all[requestId];
    if (raw is! Map) return;
    final entry = QueuedWorksheetEntry.tryFromJson(
      Map<String, dynamic>.from(raw),
    );
    if (entry == null) return;
    all[requestId] = QueuedWorksheetEntry(
      request: entry.request,
      createdAt: entry.createdAt,
      status: WorksheetGenerationStatus.failedRetryable,
      retryCount: entry.retryCount + 1,
      errorMessage: errorMessage,
    ).toJson();
    await _writeAll(all);
  }
}

/// Persists a successfully server-generated worksheet for preview without
/// exposing SQLite to callers. Native saves into SavedMaterials (which feeds
/// Saved Materials, Worksheet Preview, and teacher Progress); the memory
/// store keeps the completed payload for the session (used on web, where
/// there is no on-device database).
abstract class GeneratedWorksheetStore {
  Future<SavedMaterialData> saveCompletedWorksheet(
    String contentId,
    Map<String, dynamic> payload,
  );
}

class NativeGeneratedWorksheetStore implements GeneratedWorksheetStore {
  final AppDatabase db;
  final String? Function()? currentUserIdProvider;
  NativeGeneratedWorksheetStore(this.db, {this.currentUserIdProvider});

  @override
  Future<SavedMaterialData> saveCompletedWorksheet(
    String contentId,
    Map<String, dynamic> payload,
  ) async {
    await db.resourceDao.insertSavedMaterial(
      savedMaterialFromGenerationContent(contentId, payload),
    );
    final saved = await db.resourceDao.getSavedMaterialById(contentId);
    if (saved == null) {
      throw const QueuePersistenceException(
        'The generated worksheet could not be saved on this device.',
      );
    }
    try {
      String? owner;
      try {
        owner = currentUserIdProvider?.call()?.trim();
      } catch (_) {}
      owner ??= (payload['owner_user_id'] ?? payload['teacher_id'] ?? '').toString();
      if (owner != null && owner.isNotEmpty) {
        await db.customStatement(
          'CREATE TABLE IF NOT EXISTS account_owned_records (entity_type TEXT NOT NULL, entity_id TEXT NOT NULL, owner_user_id TEXT NOT NULL, created_at INTEGER NOT NULL, PRIMARY KEY (entity_type, entity_id))',
        );
        await db.customStatement(
          'INSERT INTO account_owned_records (entity_type, entity_id, owner_user_id, created_at) VALUES (?, ?, ?, ?) '
          'ON CONFLICT(entity_type, entity_id) DO UPDATE SET owner_user_id = excluded.owner_user_id',
          ['saved_material', contentId, owner, DateTime.now().millisecondsSinceEpoch],
        );
      }
    } catch (_) {}
    return saved;
  }
}

class MemoryGeneratedWorksheetStore implements GeneratedWorksheetStore {
  final Map<String, SavedMaterialData> _cache = {};

  @override
  Future<SavedMaterialData> saveCompletedWorksheet(
    String contentId,
    Map<String, dynamic> payload,
  ) async {
    // Reuse the shared SavedMaterials mapping so web previews carry exactly
    // the same fields (no duplicated mapping logic, no fake content).
    final companion = savedMaterialFromGenerationContent(contentId, payload);
    final data = SavedMaterialData(
      id: companion.id.value,
      type: companion.type.value,
      title: companion.title.value,
      titleHi: companion.titleHi.value,
      grade: companion.grade.value,
      subject: companion.subject.value,
      outcomeCode: companion.outcomeCode.value,
      language: companion.language.value,
      difficulty: companion.difficulty.value,
      contentJson: companion.contentJson.value,
      createdAt: companion.createdAt.value,
      isFavorite: companion.isFavorite.value,
    );
    _cache[contentId] = data;
    return data;
  }

  SavedMaterialData? cached(String contentId) => _cache[contentId];
}

/// A single worksheet completed by the server during a web sync.
class CompletedWebWorksheet {
  final String requestId;
  final String contentId;
  final Map<String, dynamic> content;

  const CompletedWebWorksheet({
    required this.requestId,
    required this.contentId,
    required this.content,
  });
}

/// Outcome of one web "Sync Now" run. [attempted] is false when the device
/// is offline or the backend is unreachable: the queue is left untouched.
class WebWorksheetSyncResult {
  final bool attempted;
  final int completed;
  final int failed;
  final int remaining;
  final List<CompletedWebWorksheet> items;

  const WebWorksheetSyncResult({
    required this.attempted,
    this.completed = 0,
    this.failed = 0,
    this.remaining = 0,
    this.items = const [],
  });
}

/// Web "Sync Now" adapter (option B): uploads pending
/// `worksheet_generation` requests through the queue abstraction using the
/// injected remote content data source. Not a second sync system: it handles
/// only worksheet-generation entries, while the native SyncManager path is
/// untouched.
class WebWorksheetSyncAdapter {
  final WorksheetGenerationQueueRepository queue;
  final RemoteContentDataSource remote;
  final ConnectivityService connectivity;

  /// Called for each server-completed worksheet so the app can persist it
  /// in its own repositories (e.g. web Saved Materials). Never blocks the
  /// queue loop.
  final Future<void> Function(CompletedWebWorksheet completed)? onCompleted;

  static const int maxPollAttempts = 15;

  WebWorksheetSyncAdapter({
    required this.queue,
    required this.remote,
    required this.connectivity,
    this.onCompleted,
  });

  Future<WebWorksheetSyncResult> syncPending() async {
    final online = await connectivity.isOnline;
    if (!online) {
      return WebWorksheetSyncResult(
        attempted: false,
        remaining: await _safeCount(),
      );
    }
    final reachable = await connectivity.checkBackendReachability();
    if (!reachable) {
      return WebWorksheetSyncResult(
        attempted: false,
        remaining: await _safeCount(),
      );
    }

    int completed = 0;
    int failed = 0;
    final items = <CompletedWebWorksheet>[];
    final pending = await queue.pendingEntries();
    for (final entry in pending) {
      final requestId = entry.requestId;
      if (requestId.isEmpty) continue;
      try {
        final job = await remote.requestGeneration(
          entry.request,
          idempotencyKey: requestId,
        );
        final ready = await _awaitReady(job.jobId);
        if (ready == null || ready.content == null) {
          await queue.markFailed(requestId, 'Server generation pending.');
          failed++;
          continue;
        }
        // Never accept (or save) an empty worksheet: no fake previews.
        final questions = ready.content!['questions'];
        if (questions is! List || questions.isEmpty) {
          await queue.markFailed(
            requestId,
            'Server returned an empty worksheet.',
          );
          failed++;
          continue;
        }
        final contentId = ready.contentId ?? requestId;
        await queue.markCompleted(requestId);
        final done = CompletedWebWorksheet(
          requestId: requestId,
          contentId: contentId,
          content: ready.content!,
        );
        items.add(done);
        completed++;
        final cb = onCompleted;
        if (cb != null) {
          try {
            await cb(done);
          } catch (_) {
            // Completion callbacks must never fail the synced queue entry.
          }
        }
      } catch (_) {
        // Network/server failure: keep the request pending for retry.
        try {
          await queue.markFailed(requestId, 'Server unavailable.');
        } catch (_) {
          // Storage failure here must not crash the sync loop either.
        }
        failed++;
      }
    }
    return WebWorksheetSyncResult(
      attempted: true,
      completed: completed,
      failed: failed,
      remaining: await _safeCount(),
      items: items,
    );
  }

  Future<int> _safeCount() async {
    try {
      return await queue.pendingCount();
    } catch (_) {
      return 0;
    }
  }

  /// Polls a generation job until READY/REVIEW_REQUIRED (content present) or
  /// FAILED/timeout. Returns null when the job did not complete in time.
  Future<GenerationJobModel?> _awaitReady(String jobId) async {
    GenerationJobModel job = GenerationJobModel(
      jobId: jobId,
      status: 'PENDING',
      contentType: 'worksheet',
      grade: 1,
      targetLanguage: 'sat',
    );
    for (var i = 0; i < maxPollAttempts; i++) {
      try {
        job = await remote.getJobStatus(jobId);
      } catch (_) {
        return null;
      }
      if (job.isFailed) return null;
      if ((job.isReady || job.isReviewRequired) && job.content != null) {
        return job;
      }
      await Future.delayed(const Duration(seconds: 2));
    }
    return null;
  }
}
