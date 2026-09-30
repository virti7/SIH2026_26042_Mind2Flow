import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../database/app_database.dart';
import '../content/flashcard/flashcard_image_library.dart';
import '../database/tables/downloaded_resources.dart';
import 'flashcard_image_pdf_writer.dart';
import 'flashcard_pdf_writer.dart';
import 'remote_content_data_source.dart';
import 'worksheet_file.dart';
import 'worksheet_pdf_writer.dart';

/// Local metadata for one downloaded worksheet/resource.
///
/// Mirrors the backend canonical worksheet plus local file facts. The row is
/// the single source of truth for the Downloads screen, filters, details and
/// offline-open. Deleting it removes local offline availability only — the
/// server resource is never touched.
class WorksheetDownload {
  final String downloadId;
  final String resourceId;
  final String resourceType;
  final String teacherId;
  final String title;
  final String fileName;
  final String localFilePath;
  final DateTime downloadedAt;
  final DateTime? generatedAt;
  final int grade;
  final String section;
  final String subject;
  final String topic;
  final String topicSource;
  final String topicInputLanguage;
  final String? nipunOutcome;
  final String language1;
  final String language2;
  final List<String> worksheetTypes;
  final int questionCount;
  final String difficulty;
  final int fileSize;
  final String format;
  final String? generationRequestId;
  final int version;
  final bool offlineAvailable;
  final DateTime? lastOpenedAt;
  final DateTime createdAt;
  // Full server content payload (for offline reading + local PDF fallback).
  final Map<String, dynamic>? contentJson;

  const WorksheetDownload({
    required this.downloadId,
    required this.resourceId,
    this.resourceType = 'worksheet',
    this.teacherId = '',
    this.title = '',
    required this.fileName,
    required this.localFilePath,
    required this.downloadedAt,
    this.generatedAt,
    this.grade = 0,
    this.section = 'General',
    this.subject = '',
    this.topic = '',
    this.topicSource = 'curriculum',
    this.topicInputLanguage = 'en',
    this.nipunOutcome,
    this.language1 = 'hi',
    this.language2 = 'sat',
    this.worksheetTypes = const ['practice'],
    this.questionCount = 0,
    this.difficulty = 'medium',
    this.fileSize = 0,
    this.format = 'pdf',
    this.generationRequestId,
    this.version = 1,
    this.offlineAvailable = true,
    this.lastOpenedAt,
    required this.createdAt,
    this.contentJson,
  });

  Map<String, dynamic> toMap() => {
        'download_id': downloadId,
        'resource_id': resourceId,
        'resource_type': resourceType,
        'teacher_id': teacherId,
        'title': title,
        'file_name': fileName,
        'local_file_path': localFilePath,
        'downloaded_at': downloadedAt.toIso8601String(),
        'generated_at': generatedAt?.toIso8601String(),
        'grade': grade,
        'section': section,
        'subject': subject,
        'topic': topic,
        'topic_source': topicSource,
        'topic_input_language': topicInputLanguage,
        'nipun_outcome': nipunOutcome,
        'language_1': language1,
        'language_2': language2,
        'worksheet_types': jsonEncode(worksheetTypes),
        'question_count': questionCount,
        'difficulty': difficulty,
        'file_size': fileSize,
        'format': format,
        'generation_request_id': generationRequestId,
        'version': version,
        'offline_available': offlineAvailable ? 1 : 0,
        'last_opened_at': lastOpenedAt?.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
        'content_json': contentJson == null ? null : jsonEncode(contentJson),
      };

  static WorksheetDownload? tryFromMap(Map<String, dynamic> m) {
    try {
      List<String> types = const ['practice'];
      final rawTypes = m['worksheet_types'];
      if (rawTypes is List) {
        types = rawTypes.map((e) => e.toString()).toList();
      } else if (rawTypes is String && rawTypes.isNotEmpty) {
        try {
          final decoded = jsonDecode(rawTypes);
          if (decoded is List) {
            types = decoded.map((e) => e.toString()).toList();
          }
        } catch (_) {
          types = [rawTypes];
        }
      }
      DateTime? dt(dynamic v) {
        if (v == null) return null;
        if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
        return DateTime.tryParse(v.toString());
      }

      Map<String, dynamic>? content;
      final rawContent = m['content_json'];
      if (rawContent is Map) {
        content = Map<String, dynamic>.from(rawContent);
      } else if (rawContent is String && rawContent.isNotEmpty) {
        try {
          final decoded = jsonDecode(rawContent);
          if (decoded is Map) content = Map<String, dynamic>.from(decoded);
        } catch (_) {}
      }
      int intVal(dynamic v, int fallback) =>
          v is num ? v.toInt() : int.tryParse(v.toString()) ?? fallback;
      return WorksheetDownload(
        downloadId: m['download_id'].toString(),
        resourceId: m['resource_id'].toString(),
        resourceType: (m['resource_type'] ?? 'worksheet').toString(),
        teacherId: (m['teacher_id'] ?? '').toString(),
        title: (m['title'] ?? '').toString(),
        fileName: (m['file_name'] ?? '').toString(),
        localFilePath: (m['local_file_path'] ?? '').toString(),
        downloadedAt: dt(m['downloaded_at']) ?? DateTime.now(),
        generatedAt: dt(m['generated_at']),
        grade: intVal(m['grade'], 0),
        section: (m['section'] ?? 'General').toString(),
        subject: (m['subject'] ?? '').toString(),
        topic: (m['topic'] ?? '').toString(),
        topicSource: (m['topic_source'] ?? 'curriculum').toString(),
        topicInputLanguage: (m['topic_input_language'] ?? 'en').toString(),
        nipunOutcome: m['nipun_outcome']?.toString(),
        language1: (m['language_1'] ?? 'hi').toString(),
        language2: (m['language_2'] ?? 'sat').toString(),
        worksheetTypes: types,
        questionCount: intVal(m['question_count'], 0),
        difficulty: (m['difficulty'] ?? 'medium').toString(),
        fileSize: intVal(m['file_size'], 0),
        format: (m['format'] ?? 'pdf').toString(),
        generationRequestId: m['generation_request_id']?.toString(),
        version: intVal(m['version'], 1),
        offlineAvailable: m['offline_available'] == 1 || m['offline_available'] == true,
        lastOpenedAt: dt(m['last_opened_at']),
        createdAt: dt(m['created_at']) ?? DateTime.now(),
        contentJson: content,
      );
    } catch (_) {
      return null;
    }
  }
}

/// Platform-neutral persistence for downloaded worksheets.
///
/// - Native: Drift/SQLite `downloaded_resources` table managed with raw SQL
///   (no build_runner codegen required) + real files in app documents.
/// - Web (no AppDatabase registered): SharedPreferences JSON + browser-safe
///   file store.
///
/// Re-downloading the same resource updates the existing row/file in place
/// (duplicate protection by resource_id).
abstract class WorksheetDownloadStore {
  Future<WorksheetDownload> saveDownload({
    required String resourceId,
    required String title,
    required Map<String, dynamic> contentPayload,
    required List<int> fileBytes,
    String format = 'pdf',
    String resourceType = 'worksheet',
    String? teacherId,
    String? generationRequestId,
  });

  Future<List<WorksheetDownload>> listDownloads();
  Future<WorksheetDownload?> getByResourceId(String resourceId);
  Future<void> markOpened(String resourceId);
  Future<void> rename(String resourceId, String newTitle);
  Future<void> deleteDownload(String resourceId);
  Future<void> setOfflineAvailable(String resourceId, bool available);
}

/// Raw-SQL schema (canonical definition lives in
/// lib/core/database/tables/downloaded_resources.dart as
/// [DownloadedResourcesSchema], including the account-scoped
/// UNIQUE(teacher_id, resource_id) constraint). Managed without codegen so
/// no build_runner step is required.
class DownloadSchema {
  static String get createTable => DownloadedResourcesSchema.createTable;

  static List<String> get indexes => DownloadedResourcesSchema.indexes;
}

int _epochMs(DateTime? dt) => dt?.millisecondsSinceEpoch ?? 0;

/// Builds a [WorksheetDownload] record from a real server payload + bytes.
/// All metadata comes from the payload; nothing is invented.
WorksheetDownload buildDownloadRecord({
  required String resourceId,
  required Map<String, dynamic> content,
  required String fileName,
  required String localFilePath,
  required List<int> fileBytes,
  String format = 'pdf',
  String resourceType = 'worksheet',
  String? teacherId,
  String? generationRequestId,
  String? existingDownloadId,
  DateTime? existingCreatedAt,
}) {
  List<String> types = const ['practice'];
  final rawTypes = content['worksheet_types'];
  if (rawTypes is List && rawTypes.isNotEmpty) {
    types = rawTypes.map((e) => e.toString()).toList();
  } else if (content['worksheet_type'] != null) {
    types = [content['worksheet_type'].toString()];
  }
  final meta = content['metadata'] is Map
      ? Map<String, dynamic>.from(content['metadata'] as Map)
      : <String, dynamic>{};
  DateTime? generatedAt;
  final rawGen = content['generated_at'] ?? meta['generated_at'];
  if (rawGen != null) generatedAt = DateTime.tryParse(rawGen.toString());
  final now = DateTime.now();
  final resolvedType = (content['resource_type'] ?? content['content_type'] ?? resourceType).toString();
  return WorksheetDownload(
    downloadId: existingDownloadId ?? const Uuid().v4(),
    resourceId: resourceId,
    resourceType: resolvedType.isEmpty ? 'worksheet' : resolvedType,
    teacherId: teacherId ?? '',
    title: (content['title'] ?? 'Worksheet').toString(),
    fileName: fileName,
    localFilePath: localFilePath,
    downloadedAt: now,
    generatedAt: generatedAt,
    grade: (content['grade'] as num?)?.toInt() ?? 0,
    section: (content['section'] ?? meta['section'] ?? 'General').toString(),
    subject: (content['subject'] ?? '').toString(),
    topic: (content['topic'] ?? '').toString(),
    topicSource: (content['topic_source'] ?? 'curriculum').toString(),
    topicInputLanguage: (content['topic_input_language'] ?? 'en').toString(),
    nipunOutcome: (content['nipun_outcome'] ?? content['curriculum_id'])?.toString(),
    language1: (content['language_1'] ?? content['source_language'] ?? 'hi').toString(),
    language2: (content['language_2'] ?? content['target_language'] ?? 'sat').toString(),
    worksheetTypes: types,
    questionCount: (content['question_count'] as num?)?.toInt() ??
        ((content['questions'] as List?)?.length ?? 0),
    difficulty: (content['difficulty'] ?? 'medium').toString(),
    fileSize: fileBytes.length,
    format: format,
    generationRequestId:
        generationRequestId ?? content['request_id']?.toString(),
    version: (content['version'] as num?)?.toInt() ?? 1,
    offlineAvailable: true,
    createdAt: existingCreatedAt ?? now,
    contentJson: content,
  );
}

/// Downloads a generated worksheet: fetches the server PDF artifact when
/// reachable, otherwise renders the REAL content payload to PDF locally, then
/// saves bytes + metadata. Returns the stored record.
///
/// Never fabricates content: [contentPayload] must be a server-generated
/// (or sync-completed) worksheet with non-empty questions.
Future<WorksheetDownload> downloadWorksheet({
  required WorksheetDownloadStore store,
  RemoteContentDataSource? remote,
  required String contentId,
  required Map<String, dynamic> contentPayload,
  Map<String, dynamic>? assets,
  String? teacherId,
  String resourceType = 'worksheet',
}) async {
  final questions = contentPayload['questions'];
  if (questions is! List || questions.isEmpty) {
    throw StateError('No worksheet content to download.');
  }
  List<int>? bytes;
  // 1. Prefer the canonical server PDF artifact.
  Future<List<int>?> tryRemote(String asset, String fileName) async {
    if (remote == null || asset.isEmpty) return null;
    try {
      final file = await remote.downloadAsset(asset, fileName);
      final raw = await (file as dynamic).readAsBytes() as List<int>;
      // Accept only real PDF bytes (magic header %PDF); anything else
      // (mock/proxy text, error pages) falls through to local rendering.
      if (raw.length > 5 &&
          raw[0] == 0x25 &&
          raw[1] == 0x50 &&
          raw[2] == 0x44 &&
          raw[3] == 0x46) {
        return raw;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  final pdfAsset = assets?['pdf']?.toString() ?? '';
  bytes = await tryRemote(pdfAsset, '$contentId.pdf');
  // 1b. Canonical FastAPI download endpoint (same backend, stable URL).
  bytes ??= await tryRemote(
      'worksheets/$contentId/download', '$contentId.pdf');
  // 2. Local fallback: render the REAL payload to PDF on-device (offline-safe).
  bytes ??= renderWorksheetPdf(contentPayload);

  // Delegate persistence (file + metadata, idempotent by resource id) to the
  // store so bytes are written exactly once.
  await store.saveDownload(
    resourceId: contentId,
    title: (contentPayload['title'] ?? 'Worksheet').toString(),
    contentPayload: contentPayload,
    fileBytes: bytes,
    resourceType: resourceType,
    teacherId: teacherId,
    generationRequestId: contentPayload['request_id']?.toString(),
  );
  final saved = await store.getByResourceId(contentId);
  if (saved == null) throw StateError('Download could not be saved.');
  return saved;
}

/// Drift-backed store (native + any platform with AppDatabase registered).
/// Account-scoped: every query filters by the authenticated teacher's
/// Supabase user UUID ([teacher_id] column). Unauthenticated access yields
/// no records; legacy rows with blank teacher_id stay hidden.
class DriftWorksheetDownloadStore implements WorksheetDownloadStore {
  final AppDatabase db;
  final WorksheetFileStore files;
  final String? Function()? currentUserIdProvider;
  bool _ready = false;

  DriftWorksheetDownloadStore(this.db,
      {WorksheetFileStore? files, this.currentUserIdProvider})
      : files = files ?? createPlatformFileStore();

  String? get _ownerId {
    try {
      final id = currentUserIdProvider?.call()?.trim();
      if (id == null || id.isEmpty) return null;
      return id;
    } catch (_) {
      return null;
    }
  }

  /// Legacy mode (no provider wired, e.g. older unit tests): global
  /// behavior as before. Production always wires a provider.
  bool get _legacy => currentUserIdProvider == null;

  Future<void> _ensureReady() async {
    if (_ready) return;
    await db.customStatement(DownloadSchema.createTable);
    for (final idx in DownloadSchema.indexes) {
      await db.customStatement(idx);
    }
    // Migrate pre-existing installs from global UNIQUE(resource_id) to
    // account-scoped UNIQUE(teacher_id, resource_id). Idempotent.
    try {
      await migrateDownloadedResourcesToOwnerScoped(db);
    } catch (_) {}
    _ready = true;
  }

  @override
  Future<WorksheetDownload> saveDownload({
    required String resourceId,
    required String title,
    required Map<String, dynamic> contentPayload,
    required List<int> fileBytes,
    String format = 'pdf',
    String resourceType = 'worksheet',
    String? teacherId,
    String? generationRequestId,
  }) async {
    await _ensureReady();
    // resource_type column may not exist on databases created before v3:
    // add it idempotently before any insert.
    try {
      await db.customStatement(
          "ALTER TABLE downloaded_resources ADD COLUMN resource_type TEXT NOT NULL DEFAULT 'worksheet'");
    } catch (_) {}
    try {
      await db.customStatement(
          'CREATE INDEX IF NOT EXISTS idx_downloads_resource_type ON downloaded_resources (resource_type)');
    } catch (_) {}
    final fileName = '$resourceId.$format';
    final ownerId = _ownerId;
    // Downloads require an authenticated owner; never attribute to ''.
    // Legacy mode (no provider) keeps the previous global behavior.
    final String? effectiveTeacherId;
    if ((teacherId ?? '').trim().isNotEmpty) {
      effectiveTeacherId = teacherId!.trim();
    } else if (_legacy) {
      effectiveTeacherId = ownerId ?? '';
    } else {
      effectiveTeacherId = ownerId;
    }
    if (!_legacy &&
        (effectiveTeacherId == null || effectiveTeacherId.isEmpty)) {
      throw StateError('Download requires an authenticated teacher account.');
    }
    // Owner-scoped lookup: another teacher's row for the same server
    // resource is invisible here, so each account keeps its own download
    // row AND its own account-scoped file (`<owner>/<file>`). Only this
    // account's previous file is ever replaced/deleted.
    final existing = _legacy
        ? await _getByResourceIdUnchecked(resourceId)
        : await _getOwnByResourceId(resourceId, effectiveTeacherId ?? '');
    if (existing != null && existing.localFilePath != 'web-local:$fileName') {
      try {
        await files.deleteFile(existing.localFilePath);
      } catch (_) {}
    }
    final localRef = await files.saveBytes(
        _legacy ? fileName : '$effectiveTeacherId/$fileName', fileBytes);
    final record = buildDownloadRecord(
      resourceId: resourceId,
      content: { ...contentPayload, 'title': title.isNotEmpty ? title : (contentPayload['title'] ?? 'Worksheet'), 'resource_type': (contentPayload['resource_type'] ?? resourceType).toString() },
      fileName: fileName,
      localFilePath: localRef,
      fileBytes: fileBytes,
      format: format,
      resourceType: resourceType,
      teacherId: effectiveTeacherId,
      generationRequestId: generationRequestId,
      existingDownloadId: existing?.downloadId,
      existingCreatedAt: existing?.createdAt,
    );
    final m = record.toMap();
    final cols = m.keys.join(', ');
    final placeholders = List.filled(m.keys.length, '?').join(', ');
    await db.customStatement(
      'INSERT INTO downloaded_resources ($cols) VALUES ($placeholders) '
      'ON CONFLICT(teacher_id, resource_id) DO UPDATE SET '
      'teacher_id=excluded.teacher_id, '
      'resource_type=excluded.resource_type, '
      'title=excluded.title, file_name=excluded.file_name, '
      'local_file_path=excluded.local_file_path, downloaded_at=excluded.downloaded_at, '
      'generated_at=excluded.generated_at, grade=excluded.grade, section=excluded.section, '
      'subject=excluded.subject, topic=excluded.topic, topic_source=excluded.topic_source, '
      'topic_input_language=excluded.topic_input_language, nipun_outcome=excluded.nipun_outcome, '
      'language_1=excluded.language_1, language_2=excluded.language_2, '
      'worksheet_types=excluded.worksheet_types, question_count=excluded.question_count, '
      'difficulty=excluded.difficulty, file_size=excluded.file_size, format=excluded.format, '
      'generation_request_id=excluded.generation_request_id, version=excluded.version, '
      'offline_available=1, content_json=excluded.content_json',
      _args(m),
    );
    return (await getByResourceId(resourceId))!;
  }

  List<dynamic> _args(Map<String, dynamic> m) => [
        m['download_id'],
        m['resource_id'],
        m['resource_type'],
        m['teacher_id'],
        m['title'],
        m['file_name'],
        m['local_file_path'],
        _epochMs(DateTime.parse(m['downloaded_at'].toString())),
        m['generated_at'] == null ? null : _epochMs(DateTime.tryParse(m['generated_at'].toString())),
        m['grade'],
        m['section'],
        m['subject'],
        m['topic'],
        m['topic_source'],
        m['topic_input_language'],
        m['nipun_outcome'],
        m['language_1'],
        m['language_2'],
        m['worksheet_types'],
        m['question_count'],
        m['difficulty'],
        m['file_size'],
        m['format'],
        m['generation_request_id'],
        m['version'],
        1,
        m['last_opened_at'] == null ? null : _epochMs(DateTime.tryParse(m['last_opened_at'].toString())),
        _epochMs(DateTime.parse(m['created_at'].toString())),
        m['content_json'],
      ];

  WorksheetDownload? _rowToDownload(QueryRow row) {
    final d = row.data;
    return WorksheetDownload.tryFromMap({
      'download_id': d['download_id'],
      'resource_id': d['resource_id'],
      'resource_type': d.containsKey('resource_type') ? d['resource_type'] : 'worksheet',
      'teacher_id': d['teacher_id'],
      'title': d['title'],
      'file_name': d['file_name'],
      'local_file_path': d['local_file_path'],
      'downloaded_at': DateTime.fromMillisecondsSinceEpoch((d['downloaded_at'] as num).toInt()),
      'generated_at': d['generated_at'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch((d['generated_at'] as num).toInt()),
      'grade': d['grade'],
      'section': d['section'],
      'subject': d['subject'],
      'topic': d['topic'],
      'topic_source': d['topic_source'],
      'topic_input_language': d['topic_input_language'],
      'nipun_outcome': d['nipun_outcome'],
      'language_1': d['language_1'],
      'language_2': d['language_2'],
      'worksheet_types': d['worksheet_types'],
      'question_count': d['question_count'],
      'difficulty': d['difficulty'],
      'file_size': d['file_size'],
      'format': d['format'],
      'generation_request_id': d['generation_request_id'],
      'version': d['version'],
      'offline_available': d['offline_available'],
      'last_opened_at': d['last_opened_at'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch((d['last_opened_at'] as num).toInt()),
      'created_at': DateTime.fromMillisecondsSinceEpoch((d['created_at'] as num).toInt()),
      'content_json': d['content_json'],
    });
  }

  @override
  Future<List<WorksheetDownload>> listDownloads() async {
    await _ensureReady();
    if (_legacy) {
      final rows = await db.customSelect(
        'SELECT * FROM downloaded_resources ORDER BY downloaded_at DESC',
      ).get();
      return rows.map(_rowToDownload).whereType<WorksheetDownload>().toList();
    }
    final ownerId = _ownerId;
    if (ownerId == null) return [];
    final rows = await db.customSelect(
      'SELECT * FROM downloaded_resources WHERE teacher_id = ? ORDER BY downloaded_at DESC',
      variables: [Variable.withString(ownerId)],
    ).get();
    return rows.map(_rowToDownload).whereType<WorksheetDownload>().toList();
  }

  @override
  Future<WorksheetDownload?> getByResourceId(String resourceId) async {
    await _ensureReady();
    if (_legacy) return _getByResourceIdUnchecked(resourceId);
    final ownerId = _ownerId;
    if (ownerId == null) return null;
    // Owner-scoped read: another teacher's row for the same server
    // resource is invisible (composite UNIQUE(teacher_id, resource_id)).
    return _getOwnByResourceId(resourceId, ownerId);
  }

  /// Owner-scoped single-row read used by save (previous-file cleanup) and
  /// get. Never returns another teacher's row.
  Future<WorksheetDownload?> _getOwnByResourceId(
    String resourceId,
    String ownerId,
  ) async {
    await _ensureReady();
    final rows = await db.customSelect(
      'SELECT * FROM downloaded_resources WHERE resource_id = ? AND teacher_id = ? LIMIT 1',
      variables: [Variable.withString(resourceId), Variable.withString(ownerId)],
    ).get();
    if (rows.isEmpty) return null;
    return _rowToDownload(rows.first);
  }

  /// Ownership-safe variant used internally before the owner is known.
  Future<WorksheetDownload?> _getByResourceIdUnchecked(String resourceId) async {
    await _ensureReady();
    final rows = await db.customSelect(
      'SELECT * FROM downloaded_resources WHERE resource_id = ? LIMIT 1',
      variables: [Variable.withString(resourceId)],
    ).get();
    if (rows.isEmpty) return null;
    return _rowToDownload(rows.first);
  }

  @override
  Future<void> markOpened(String resourceId) async {
    await _ensureReady();
    if (_legacy) {
      await db.customStatement(
        'UPDATE downloaded_resources SET last_opened_at = ? WHERE resource_id = ?',
        [DateTime.now().millisecondsSinceEpoch, resourceId],
      );
      return;
    }
    final ownerId = _ownerId;
    if (ownerId == null) return;
    await db.customStatement(
      'UPDATE downloaded_resources SET last_opened_at = ? WHERE resource_id = ? AND teacher_id = ?',
      [DateTime.now().millisecondsSinceEpoch, resourceId, ownerId],
    );
  }

  @override
  Future<void> rename(String resourceId, String newTitle) async {
    await _ensureReady();
    if (_legacy) {
      await db.customStatement(
        'UPDATE downloaded_resources SET title = ? WHERE resource_id = ?',
        [newTitle, resourceId],
      );
      return;
    }
    final ownerId = _ownerId;
    if (ownerId == null) return;
    await db.customStatement(
      'UPDATE downloaded_resources SET title = ? WHERE resource_id = ? AND teacher_id = ?',
      [newTitle, resourceId, ownerId],
    );
  }

  @override
  Future<void> deleteDownload(String resourceId) async {
    final existing = await getByResourceId(resourceId);
    if (existing != null) {
      try {
        await files.deleteFile(existing.localFilePath);
      } catch (_) {}
    }
    await _ensureReady();
    if (_legacy) {
      await db.customStatement(
        'DELETE FROM downloaded_resources WHERE resource_id = ?',
        [resourceId],
      );
      return;
    }
    final ownerId = _ownerId;
    if (ownerId == null) return;
    await db.customStatement(
      'DELETE FROM downloaded_resources WHERE resource_id = ? AND teacher_id = ?',
      [resourceId, ownerId],
    );
  }

  @override
  Future<void> setOfflineAvailable(String resourceId, bool available) async {
    await _ensureReady();
    if (_legacy) {
      await db.customStatement(
        'UPDATE downloaded_resources SET offline_available = ? WHERE resource_id = ?',
        [available ? 1 : 0, resourceId],
      );
      return;
    }
    final ownerId = _ownerId;
    if (ownerId == null) return;
    await db.customStatement(
      'UPDATE downloaded_resources SET offline_available = ? WHERE resource_id = ? AND teacher_id = ?',
      [available ? 1 : 0, resourceId, ownerId],
    );
  }
}

/// SharedPreferences-backed store (web, where AppDatabase is not registered).
/// Account-scoped via per-teacher storage keys.
class PrefsWorksheetDownloadStore implements WorksheetDownloadStore {
  static const String _legacyKey = 'worksheet_downloads_v1';
  static const String _keyPrefix = 'worksheet_downloads_v1:';
  SharedPreferences? prefs;
  final WorksheetFileStore files;
  final String? Function()? currentUserIdProvider;
  final Map<String, Map<String, dynamic>> _memoryByOwner = {};
  String? _loadedOwner;
  Future<void>? _init;

  bool get _legacy => currentUserIdProvider == null;

  Map<String, dynamic> get _memory => _memoryByOwner.putIfAbsent(
      _legacy ? 'legacy' : (_ownerId ?? 'unowned'), () => {});

  PrefsWorksheetDownloadStore(
      {this.prefs, WorksheetFileStore? files, this.currentUserIdProvider})
      : files = files ?? createPlatformFileStore();

  String? get _ownerId {
    try {
      final id = currentUserIdProvider?.call()?.trim();
      if (id == null || id.isEmpty) return null;
      return id;
    } catch (_) {
      return null;
    }
  }

  String get _key =>
      _legacy ? _legacyKey : '$_keyPrefix${_ownerId ?? 'unowned'}';

  Future<void> _ensureLoaded() async {
    final owner = _legacy ? 'legacy' : (_ownerId ?? 'unowned');
    if (_init != null && _loadedOwner == owner) {
      await _init;
      return;
    }
    _loadedOwner = owner;
    // Per-owner memory (never mix accounts in the degraded no-prefs path).
    _init = (() async {
      if (prefs == null) {
        try {
          prefs = await SharedPreferences.getInstance();
        } catch (_) {}
      }
      final p = prefs;
      if (p != null && _memory.isEmpty) {
        try {
          final raw = p.getString(_key);
          if (raw != null && raw.isNotEmpty) {
            final decoded = jsonDecode(raw);
            if (decoded is Map) {
              _memory.addAll(Map<String, dynamic>.from(decoded));
            }
          }
        } catch (_) {}
      }
    })();
    await _init;
    await _reclaimStorage();
  }

  bool _reclaimed = false;

  /// Browser local storage holds ~5 MB per origin. Picture-flashcard PDFs
  /// (bundled PNGs, ~1 MB+ each as base64) used to be stored there, which
  /// filled the quota so later download metadata silently failed to
  /// persist. Flashcard PDFs are rebuilt from the saved payload on demand,
  /// so drop their stored blobs, plus any blob no download record points
  /// to. Runs once per store instance.
  Future<void> _reclaimStorage() async {
    if (_reclaimed) return;
    _reclaimed = true;
    final p = prefs;
    if (p == null) return;
    try {
      final referenced = <String>{};
      for (final key in p.getKeys()) {
        if (key != _legacyKey && !key.startsWith(_keyPrefix)) continue;
        final raw = p.getString(key);
        if (raw == null || raw.isEmpty) continue;
        final decoded = jsonDecode(raw);
        if (decoded is! Map) continue;
        var changed = false;
        for (final entry in decoded.entries.toList()) {
          final v = entry.value;
          if (v is! Map) continue;
          final ref = (v['local_file_path'] ?? '').toString();
          if (!ref.startsWith(_webLocalPrefix)) continue;
          if (v['resource_type'] == 'flashcard') {
            final m = Map<String, dynamic>.from(v);
            m['local_file_path'] =
                '$kRegeneratedFilePrefix${ref.substring(_webLocalPrefix.length)}';
            decoded[entry.key] = m;
            changed = true;
          } else {
            referenced.add(ref.substring(_webLocalPrefix.length));
          }
        }
        if (changed) {
          await p.setString(key, jsonEncode(decoded));
          if (key == _key) {
            _memory
              ..clear()
              ..addAll(Map<String, dynamic>.from(decoded));
          }
        }
      }
      for (final key in p.getKeys().toList()) {
        if (!key.startsWith(_webFilePrefix)) continue;
        if (referenced.contains(key.substring(_webFilePrefix.length))) continue;
        await p.remove(key);
      }
    } catch (_) {}
  }

  static const String _webLocalPrefix = 'web-local:';
  static const String _webFilePrefix = 'worksheet_file_v1:';

  Future<Map<String, dynamic>> _readAll() async {
    await _ensureLoaded();
    return Map<String, dynamic>.from(_memory);
  }

  Future<void> _writeAll(Map<String, dynamic> map) async {
    await _ensureLoaded();
    _memory
      ..clear()
      ..addAll(map);
    final p = prefs;
    if (p == null) return;
    try {
      await p.setString(_key, jsonEncode(map));
    } catch (_) {}
  }

  @override
  Future<WorksheetDownload> saveDownload({
    required String resourceId,
    required String title,
    required Map<String, dynamic> contentPayload,
    required List<int> fileBytes,
    String format = 'pdf',
    String resourceType = 'worksheet',
    String? teacherId,
    String?     generationRequestId,
  }) async {
    final ownerId = _ownerId;
    if (!_legacy && ownerId == null) {
      throw StateError('Download requires an authenticated teacher account.');
    }
    final effectiveTeacherId = (teacherId ?? '').trim().isNotEmpty
        ? teacherId!.trim()
        : (_legacy ? (ownerId ?? '') : ownerId!);
    final all = await _readAll();
    final prevRaw = all[resourceId];
    WorksheetDownload? prev;
    if (prevRaw is Map) {
      prev = WorksheetDownload.tryFromMap(Map<String, dynamic>.from(prevRaw));
    }
    if (!_legacy &&
        prev != null &&
        prev.teacherId.isNotEmpty &&
        prev.teacherId != effectiveTeacherId) {
      throw StateError('Download belongs to a different teacher account.');
    }
    if (prev != null) {
      try {
        await files.deleteFile(prev.localFilePath);
      } catch (_) {}
    }
    final fileName = '$resourceId.$format';
    final storedName = _legacy ? fileName : '$effectiveTeacherId/$fileName';
    // Flashcard PDFs are rebuilt from the saved payload, so only the
    // (small) payload is kept in browser storage — see [_reclaimStorage].
    final localRef = isRegenerableFlashcard(resourceType, contentPayload)
        ? '$kRegeneratedFilePrefix$storedName'
        : await files.saveBytes(storedName, fileBytes);
    final record = buildDownloadRecord(
      resourceId: resourceId,
      content: { ...contentPayload, 'title': title.isNotEmpty ? title : (contentPayload['title'] ?? 'Resource'), 'resource_type': (contentPayload['resource_type'] ?? resourceType).toString() },
      fileName: fileName,
      localFilePath: localRef,
      fileBytes: fileBytes,
      format: format,
      resourceType: resourceType,
      teacherId: effectiveTeacherId,
      generationRequestId: generationRequestId,
      existingDownloadId: prev?.downloadId,
      existingCreatedAt: prev?.createdAt,
    );
    all[resourceId] = record.toMap();
    await _writeAll(all);
    return record;
  }

  @override
  Future<List<WorksheetDownload>> listDownloads() async {
    final ownerId = _ownerId;
    if (!_legacy && ownerId == null) return [];
    final all = await _readAll();
    final items = <WorksheetDownload>[];
    for (final v in all.values) {
      if (v is! Map) continue;
      final d = WorksheetDownload.tryFromMap(Map<String, dynamic>.from(v));
      if (d == null) continue;
      // Legacy rows with blank teacher_id stay hidden from every account.
      if (!_legacy && d.teacherId != ownerId) continue;
      items.add(d);
    }
    items.sort((a, b) => b.downloadedAt.compareTo(a.downloadedAt));
    return items;
  }

  @override
  Future<WorksheetDownload?> getByResourceId(String resourceId) async {
    final ownerId = _ownerId;
    if (!_legacy && ownerId == null) return null;
    final all = await _readAll();
    final raw = all[resourceId];
    if (raw is! Map) return null;
    final d = WorksheetDownload.tryFromMap(Map<String, dynamic>.from(raw));
    if (d == null) return null;
    if (!_legacy && d.teacherId != ownerId) return null;
    return d;
  }

  @override
  Future<void> markOpened(String resourceId) async {
    final all = await _readAll();
    final raw = all[resourceId];
    if (raw is! Map) return;
    final m = Map<String, dynamic>.from(raw);
    m['last_opened_at'] = DateTime.now().toIso8601String();
    all[resourceId] = m;
    await _writeAll(all);
  }

  @override
  Future<void> rename(String resourceId, String newTitle) async {
    final all = await _readAll();
    final raw = all[resourceId];
    if (raw is! Map) return;
    final m = Map<String, dynamic>.from(raw);
    m['title'] = newTitle;
    all[resourceId] = m;
    await _writeAll(all);
  }

  @override
  Future<void> deleteDownload(String resourceId) async {
    final all = await _readAll();
    final raw = all[resourceId];
    if (raw is Map) {
      final d = WorksheetDownload.tryFromMap(Map<String, dynamic>.from(raw));
      if (d != null) {
        try {
          await files.deleteFile(d.localFilePath);
        } catch (_) {}
      }
    }
    all.remove(resourceId);
    await _writeAll(all);
  }

  @override
  Future<void> setOfflineAvailable(String resourceId, bool available) async {
    final all = await _readAll();
    final raw = all[resourceId];
    if (raw is! Map) return;
    final m = Map<String, dynamic>.from(raw);
    m['offline_available'] = available ? 1 : 0;
    all[resourceId] = m;
    await _writeAll(all);
  }
}

/// Resolves the download store. Pass the registered [AppDatabase] on native
/// (Drift/SQLite metadata); omit it on web for the SharedPreferences-backed
/// store. Kept free of service-locator imports so core never depends on DI.
Future<WorksheetDownloadStore> resolveDownloadStore(
    {AppDatabase? database}) async {
  if (database != null) {
    return DriftWorksheetDownloadStore(database);
  }
  SharedPreferences? prefs;
  try {
    prefs = await SharedPreferences.getInstance();
  } catch (_) {
    prefs = null;
  }
  return PrefsWorksheetDownloadStore(prefs: prefs);
}

/// Storage reference for a download whose file is not stored but rebuilt
/// from its saved payload (flashcard sets on web).
const String kRegeneratedFilePrefix = 'regenerated:';

/// True for flashcard downloads whose PDF can be rebuilt offline from the
/// payload alone (cards + bundled pictures / text).
bool isRegenerableFlashcard(String resourceType, Map<String, dynamic>? content) {
  final type = (content?['resource_type'] ?? resourceType).toString();
  final cards = content?['cards'];
  return type == 'flashcard' && cards is List && cards.isNotEmpty;
}

/// Reads the locally stored file bytes for a download (offline-safe).
/// Flashcard sets fall back to re-rendering the PDF from the saved payload.
/// Returns null when the file is missing — callers then offer re-download.
Future<List<int>?> readDownloadBytes(WorksheetDownload download) async {
  List<int>? bytes;
  if (!download.localFilePath.startsWith(kRegeneratedFilePrefix)) {
    try {
      bytes = await createPlatformFileStore().readBytes(download.localFilePath);
    } catch (_) {
      bytes = null;
    }
  }
  if ((bytes == null || bytes.isEmpty) &&
      isRegenerableFlashcard(download.resourceType, download.contentJson)) {
    try {
      final payload = download.contentJson!;
      bytes = isImageCatalogPayload(payload)
          ? await renderImageLibraryFlashcardPdf(payload)
          : renderFlashcardPdf(payload);
    } catch (_) {
      bytes = null;
    }
  }
  return bytes;
}
