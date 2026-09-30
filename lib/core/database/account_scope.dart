import 'dart:convert';
import 'package:drift/drift.dart';
import 'app_database.dart';

/// Account-scoped ownership enforced at the database layer.
///
/// The generated Drift schemas predate multi-account support and have no
/// `ownerUserId` columns, and regenerating codegen is not always available.
/// Instead every teacher-owned record claims ownership in a dedicated
/// mapping table created with raw SQL (no codegen required):
///
///   account_owned_records(entity_type, entity_id, owner_user_id)
///
/// plus `owner_user_id` on the raw-SQL `sync_queue` path where available.
/// Repositories MUST consult this table: rows without a claim for the
/// current user are invisible (safe default for legacy unowned data).
class AccountScope {
  static const String table = 'account_owned_records';

  /// `ownerIdProvider` returns the authenticated Supabase user UUID or null.
  final String? Function()? ownerIdProvider;

  const AccountScope({this.ownerIdProvider});

  String? get ownerId {
    try {
      final id = ownerIdProvider?.call()?.trim();
      if (id == null || id.isEmpty) return null;
      return id;
    } catch (_) {
      return null;
    }
  }

  /// Fails safe: null when unauthenticated. Callers must return empty
  /// account state instead of falling back to another user's data.
  String? requireOwnerId() => ownerId;
}

/// Creates the ownership mapping table + sync-queue owner column.
/// Idempotent; safe to call on every startup.
Future<void> ensureAccountIsolation(AppDatabase db) async {
  try {
    await db.customStatement(
      'CREATE TABLE IF NOT EXISTS account_owned_records ('
      'entity_type TEXT NOT NULL, '
      'entity_id TEXT NOT NULL, '
      'owner_user_id TEXT NOT NULL, '
      'created_at INTEGER NOT NULL, '
      'PRIMARY KEY (entity_type, entity_id))',
    );
  } catch (_) {}
  try {
    await db.customStatement(
      'CREATE INDEX IF NOT EXISTS idx_owned_records_owner '
      'ON account_owned_records (owner_user_id, entity_type)',
    );
  } catch (_) {}
  // Owner column for the sync queue (raw-SQL path; typed companions ignore
  // it, so reads/writes below use custom statements filtered by owner).
  try {
    await db.customStatement(
      'ALTER TABLE sync_queue ADD COLUMN owner_user_id TEXT NOT NULL DEFAULT \'\'',
    );
  } catch (_) {}
  try {
    await db.customStatement(
      'CREATE INDEX IF NOT EXISTS idx_sync_queue_owner '
      'ON sync_queue (owner_user_id, status)',
    );
  } catch (_) {}
  // Backfill: tag queue rows whose payload already carries an owner.
  try {
    final rows = await db
        .customSelect(
          'SELECT id, payload FROM sync_queue WHERE owner_user_id = \'\' OR owner_user_id IS NULL',
        )
        .get();
    for (final row in rows) {
      try {
        final payload = jsonDecode((row.data['payload'] ?? '{}').toString())
            as Map<String, dynamic>;
        final owner = (payload['owner_user_id'] ?? payload['ownerUserId'] ?? '')
            .toString()
            .trim();
        if (owner.isNotEmpty) {
          await db.customStatement(
            'UPDATE sync_queue SET owner_user_id = ? WHERE id = ?',
            [owner, row.data['id']],
          );
        }
      } catch (_) {}
    }
  } catch (_) {}
}

/// Claims ownership of a record for [ownerId]. No-op when blank.
Future<void> claimOwnership(
  AppDatabase db, {
  required String entityType,
  required String entityId,
  required String? ownerId,
}) async {
  final owner = (ownerId ?? '').trim();
  if (owner.isEmpty || entityId.trim().isEmpty) return;
  try {
    await db.customStatement(
      'INSERT INTO account_owned_records (entity_type, entity_id, owner_user_id, created_at) '
      'VALUES (?, ?, ?, ?) '
      'ON CONFLICT(entity_type, entity_id) DO UPDATE SET owner_user_id = excluded.owner_user_id',
      [entityType, entityId, owner, DateTime.now().millisecondsSinceEpoch],
    );
  } catch (_) {}
}

/// Returns the set of entity IDs owned by [ownerId] for [entityType].
Future<Set<String>> ownedEntityIds(
  AppDatabase db, {
  required String entityType,
  required String? ownerId,
}) async {
  final owner = (ownerId ?? '').trim();
  if (owner.isEmpty) return <String>{};
  try {
    final rows = await db
        .customSelect(
          'SELECT entity_id FROM account_owned_records WHERE entity_type = ? AND owner_user_id = ?',
          variables: [
            Variable.withString(entityType),
            Variable.withString(owner),
          ],
        )
        .get();
    return rows.map((r) => r.data['entity_id'].toString()).toSet();
  } catch (_) {
    return <String>{};
  }
}

/// True when [entityId] of [entityType] is owned by [ownerId].
Future<bool> isOwnedBy(
  AppDatabase db, {
  required String entityType,
  required String entityId,
  required String? ownerId,
}) async {
  final owner = (ownerId ?? '').trim();
  if (owner.isEmpty) return false;
  try {
    final rows = await db
        .customSelect(
          'SELECT owner_user_id FROM account_owned_records WHERE entity_type = ? AND entity_id = ? LIMIT 1',
          variables: [
            Variable.withString(entityType),
            Variable.withString(entityId),
          ],
        )
        .get();
    if (rows.isEmpty) return false;
    return rows.first.data['owner_user_id'].toString() == owner;
  } catch (_) {
    return false;
  }
}

/// Per-account SharedPreferences key namespacing.
String scopedPrefKey(String? ownerId, String key) {
  final owner = (ownerId ?? '').trim();
  if (owner.isEmpty) return 'unowned:$key';
  return '$owner:$key';
}

/// Per-account file sub-directory name. Sanitized to alphanumerics.
String scopedAccountDir(String? ownerId) {
  final owner = (ownerId ?? '').trim();
  if (owner.isEmpty) return 'unowned';
  final safe = owner.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
  return safe.isEmpty ? 'unowned' : safe;
}
