import 'package:drift/drift.dart';

/// Local metadata for a downloaded worksheet/resource.
///
/// NOTE: this table is managed with raw SQL (see `DownloadSchema` in
/// lib/core/sync/worksheet_download_store.dart and the v2 migration in
/// app_database.dart) so no build_runner codegen step is required. This
/// class is the canonical schema definition — keep both in sync.
///
/// One row per (owner, resource_id): re-downloading the same resource
/// updates the existing row instead of creating duplicates, and two teachers
/// downloading the same server resource each keep their own row and file.
/// The row is the single source of truth for the Downloads screen, filters,
/// details view and offline-open. Deleting a row removes local offline
/// availability only — the server resource is never touched.
@DataClassName('DownloadedResourceData')
class DownloadedResources extends Table {
  TextColumn get downloadId => text()();
  TextColumn get resourceId => text()();
  TextColumn get resourceType => text().withDefault(const Constant('worksheet'))();
  TextColumn get teacherId => text().withDefault(const Constant(''))();
  TextColumn get title => text().withDefault(const Constant(''))();
  TextColumn get fileName => text()();
  TextColumn get localFilePath => text()();
  DateTimeColumn get downloadedAt => dateTime()();
  DateTimeColumn get generatedAt => dateTime().nullable()();
  IntColumn get grade => integer().withDefault(const Constant(0))();
  TextColumn get section => text().withDefault(const Constant('General'))();
  TextColumn get subject => text().withDefault(const Constant(''))();
  TextColumn get topic => text().withDefault(const Constant(''))();
  TextColumn get topicSource => text().withDefault(const Constant('curriculum'))();
  TextColumn get topicInputLanguage => text().withDefault(const Constant('en'))();
  TextColumn get nipunOutcome => text().nullable()();
  TextColumn get language1 => text().withDefault(const Constant('hi'))();
  TextColumn get language2 => text().withDefault(const Constant('sat'))();
  // JSON-encoded list of selected worksheet types, e.g. ["practice","fill_blank"].
  TextColumn get worksheetTypes => text().withDefault(const Constant('["practice"]'))();
  IntColumn get questionCount => integer().withDefault(const Constant(0))();
  TextColumn get difficulty => text().withDefault(const Constant('medium'))();
  IntColumn get fileSize => integer().withDefault(const Constant(0))();
  TextColumn get format => text().withDefault(const Constant('pdf'))();
  TextColumn get generationRequestId => text().nullable()();
  IntColumn get version => integer().withDefault(const Constant(1))();
  BoolColumn get offlineAvailable => boolean().withDefault(const Constant(true))();
  DateTimeColumn get lastOpenedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {downloadId};

  // Account-scoped uniqueness: the same server resource downloaded by two
  // teachers yields one row PER OWNER, never a shared row. (Older raw-SQL
  // schemas used UNIQUE(resource_id); see DownloadedResourcesSchema below.)
  @override
  List<Set<Column>> get uniqueKeys => [
        {teacherId, resourceId},
      ];
}

/// Canonical raw-SQL schema for `downloaded_resources` (managed without
/// build_runner codegen). Single source of truth — `DownloadSchema` in
/// worksheet_download_store.dart and the drift migrations in
/// app_database.dart must use these constants, never inline copies.
class DownloadedResourcesSchema {
  static const String columns =
      'download_id, resource_id, resource_type, teacher_id, title, file_name, '
      'local_file_path, downloaded_at, generated_at, grade, section, subject, '
      'topic, topic_source, topic_input_language, nipun_outcome, language_1, '
      'language_2, worksheet_types, question_count, difficulty, file_size, '
      'format, generation_request_id, version, offline_available, '
      'last_opened_at, created_at, content_json';

  static const String createTable = '''
CREATE TABLE IF NOT EXISTS downloaded_resources (
  download_id TEXT NOT NULL PRIMARY KEY,
  resource_id TEXT NOT NULL,
  resource_type TEXT NOT NULL DEFAULT 'worksheet',
  teacher_id TEXT NOT NULL DEFAULT '',
  title TEXT NOT NULL DEFAULT '',
  file_name TEXT NOT NULL,
  local_file_path TEXT NOT NULL,
  downloaded_at INTEGER NOT NULL,
  generated_at INTEGER,
  grade INTEGER NOT NULL DEFAULT 0,
  section TEXT NOT NULL DEFAULT 'General',
  subject TEXT NOT NULL DEFAULT '',
  topic TEXT NOT NULL DEFAULT '',
  topic_source TEXT NOT NULL DEFAULT 'curriculum',
  topic_input_language TEXT NOT NULL DEFAULT 'en',
  nipun_outcome TEXT,
  language_1 TEXT NOT NULL DEFAULT 'hi',
  language_2 TEXT NOT NULL DEFAULT 'sat',
  worksheet_types TEXT NOT NULL DEFAULT '["practice"]',
  question_count INTEGER NOT NULL DEFAULT 0,
  difficulty TEXT NOT NULL DEFAULT 'medium',
  file_size INTEGER NOT NULL DEFAULT 0,
  format TEXT NOT NULL DEFAULT 'pdf',
  generation_request_id TEXT,
  version INTEGER NOT NULL DEFAULT 1,
  offline_available INTEGER NOT NULL DEFAULT 1,
  last_opened_at INTEGER,
  created_at INTEGER NOT NULL,
  content_json TEXT,
  UNIQUE (teacher_id, resource_id)
)''';

  static const List<String> indexes = [
    'CREATE INDEX IF NOT EXISTS idx_downloads_teacher ON downloaded_resources (teacher_id)',
    'CREATE INDEX IF NOT EXISTS idx_downloads_resource ON downloaded_resources (resource_id)',
    'CREATE INDEX IF NOT EXISTS idx_downloads_owner_resource ON downloaded_resources (teacher_id, resource_id)',
    'CREATE INDEX IF NOT EXISTS idx_downloads_resource_type ON downloaded_resources (resource_type)',
    'CREATE INDEX IF NOT EXISTS idx_downloads_subject ON downloaded_resources (subject)',
    'CREATE INDEX IF NOT EXISTS idx_downloads_grade ON downloaded_resources (grade)',
    'CREATE INDEX IF NOT EXISTS idx_downloads_section ON downloaded_resources (section)',
    'CREATE INDEX IF NOT EXISTS idx_downloads_downloaded_at ON downloaded_resources (downloaded_at)',
  ];
}

/// Migrates a pre-existing `downloaded_resources` table (UNIQUE(resource_id))
/// to account-scoped uniqueness (UNIQUE(teacher_id, resource_id)).
///
/// - Idempotent: databases already on the new schema are untouched.
/// - Data-preserving: every row is copied, including legacy unowned rows
///   (teacher_id ''), which stay hidden from every account (never
///   reassigned to a new user).
/// - Offline-safe: pure local SQLite DDL, no network.
Future<void> migrateDownloadedResourcesToOwnerScoped(
  DatabaseConnectionUser db,
) async {
  try {
    await db.customStatement(
      "ALTER TABLE downloaded_resources ADD COLUMN resource_type TEXT NOT NULL DEFAULT 'worksheet'",
    );
  } catch (_) {}
  List<QueryRow> tables;
  try {
    tables = await db.customSelect(
      "SELECT sql FROM sqlite_master WHERE type = 'table' AND name = 'downloaded_resources'",
    ).get();
  } catch (_) {
    return;
  }
  if (tables.isEmpty) {
    try {
      await db.customStatement(DownloadedResourcesSchema.createTable);
      for (final idx in DownloadedResourcesSchema.indexes) {
        await db.customStatement(idx);
      }
    } catch (_) {}
    return;
  }
  final sql = (tables.first.data['sql'] ?? '').toString();
  if (sql.contains('UNIQUE (teacher_id, resource_id)')) return;
  // Old schema (global UNIQUE(resource_id)): rebuild with the new
  // constraint. A leftover partial rebuild table is dropped first; the
  // live table is only dropped after its rows are copied.
  try {
    await db.customStatement('DROP TABLE IF EXISTS downloaded_resources_new');
    await db.customStatement(
      DownloadedResourcesSchema.createTable
          .replaceFirst('downloaded_resources (', 'downloaded_resources_new (')
          .replaceFirst('CREATE TABLE IF NOT EXISTS', 'CREATE TABLE'),
    );
    await db.customStatement(
      'INSERT OR IGNORE INTO downloaded_resources_new (${DownloadedResourcesSchema.columns}) '
      'SELECT ${DownloadedResourcesSchema.columns} FROM downloaded_resources',
    );
    await db.customStatement('DROP TABLE downloaded_resources');
    await db.customStatement(
      'ALTER TABLE downloaded_resources_new RENAME TO downloaded_resources',
    );
    for (final idx in DownloadedResourcesSchema.indexes) {
      await db.customStatement(idx);
    }
  } catch (_) {}
}
