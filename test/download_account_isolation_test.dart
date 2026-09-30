import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maatribhasha/core/database/account_scope.dart';
import 'package:maatribhasha/core/database/app_database.dart';
import 'package:maatribhasha/core/database/tables/downloaded_resources.dart';
import 'package:maatribhasha/core/sync/worksheet_download_store.dart';
import 'package:maatribhasha/core/sync/worksheet_file_stub.dart';
import 'package:maatribhasha/core/sync/worksheet_generation_sync.dart';

/// Multi-account download isolation (real-world bug: Account B could see
/// Account A's downloads / ready-to-download worksheets on the same phone).
///
/// Ownership key is ALWAYS the Supabase user UUID (never email/name/device).
class _MemoryFileStore implements WorksheetFileStore {
  final Map<String, List<int>> files = {};
  @override
  Future<String> saveBytes(String fileName, List<int> bytes) async {
    files[fileName] = List<int>.from(bytes);
    return '/mem/$fileName';
  }

  @override
  Future<List<int>?> readBytes(String storageRef) async =>
      files[storageRef.split('/').last] ?? files[storageRef];

  @override
  Future<void> deleteFile(String storageRef) async {
    files.remove(storageRef.split('/').last);
    files.remove(storageRef);
  }
}

Map<String, dynamic> _payload(String id) => {
      'content_id': id,
      'title': 'Worksheet $id',
      'grade': 2,
      'subject': 'Mathematics',
      'topic': 'Numbers',
      'language_1': 'hi',
      'language_2': 'sat',
      'worksheet_types': ['practice'],
      'question_count': 2,
      'difficulty': 'medium',
      'questions': [
        {'questionNumber': 1, 'prompt_source': 'Q1', 'prompt_target': 'Q1'},
        {'questionNumber': 2, 'prompt_source': 'Q2', 'prompt_target': 'Q2'},
      ],
    };

void main() {
  const ownerA = 'user-uuid-A';
  const ownerB = 'user-uuid-B';

  group('downloaded_resources account isolation', () {
    test('B sees none of A downloads; unauthenticated sees nothing',
        () async {
      final files = _MemoryFileStore();
      final db = AppDatabase(NativeDatabase.memory());
      String? currentOwner = ownerA;
      final store = DriftWorksheetDownloadStore(db,
          files: files, currentUserIdProvider: () => currentOwner);

      await store.saveDownload(
        resourceId: 'ws_a1',
        title: 'A worksheet',
        contentPayload: _payload('ws_a1'),
        fileBytes: const [1, 2, 3],
      );

      expect((await store.listDownloads()).length, 1);
      expect(await store.getByResourceId('ws_a1'), isNotNull);

      currentOwner = ownerB;
      expect(await store.listDownloads(), isEmpty);
      expect(await store.getByResourceId('ws_a1'), isNull);

      currentOwner = null;
      expect(await store.listDownloads(), isEmpty);
      expect(await store.getByResourceId('ws_a1'), isNull);

      await db.close();
    });

    test('same server resource yields one row PER OWNER, files isolated',
        () async {
      final files = _MemoryFileStore();
      final db = AppDatabase(NativeDatabase.memory());
      String? currentOwner = ownerA;
      final store = DriftWorksheetDownloadStore(db,
          files: files, currentUserIdProvider: () => currentOwner);

      await store.saveDownload(
        resourceId: 'shared_ws',
        title: 'A copy',
        contentPayload: _payload('shared_ws'),
        fileBytes: const [1],
      );
      final aPath =
          (await store.getByResourceId('shared_ws'))!.localFilePath;
      expect(aPath, contains(ownerA));

      // B downloads the same server resource: separate row + separate file.
      currentOwner = ownerB;
      await store.saveDownload(
        resourceId: 'shared_ws',
        title: 'B copy',
        contentPayload: _payload('shared_ws'),
        fileBytes: const [2],
      );
      final bRec = (await store.getByResourceId('shared_ws'))!;
      expect(bRec.localFilePath, contains(ownerB));
      expect(bRec.localFilePath, isNot(aPath));
      expect((await store.listDownloads()).length, 1);

      // A re-downloads: only A's row/file changes, B untouched.
      currentOwner = ownerA;
      await store.saveDownload(
        resourceId: 'shared_ws',
        title: 'A copy v2',
        contentPayload: _payload('shared_ws'),
        fileBytes: const [3],
      );
      currentOwner = ownerB;
      final bAfter = (await store.getByResourceId('shared_ws'))!;
      expect(bAfter.title, 'B copy');
      expect(await files.readBytes(bAfter.localFilePath), [2]);

      // B deletes: A's row and file survive.
      await store.deleteDownload('shared_ws');
      currentOwner = ownerA;
      expect(await store.getByResourceId('shared_ws'), isNotNull);

      await db.close();
    });

    test('legacy unowned rows stay hidden from every account', () async {
      final files = _MemoryFileStore();
      final db = AppDatabase(NativeDatabase.memory());
      // Legacy (provider-less) store: pre-isolation global behavior.
      final legacy =
          DriftWorksheetDownloadStore(db, files: files);
      await legacy.saveDownload(
        resourceId: 'ws_legacy',
        title: 'Old',
        contentPayload: _payload('ws_legacy'),
        fileBytes: const [9],
      );

      String? currentOwner = ownerA;
      final scoped = DriftWorksheetDownloadStore(db,
          files: files, currentUserIdProvider: () => currentOwner);
      expect(await scoped.listDownloads(), isEmpty);
      currentOwner = ownerB;
      expect(await scoped.listDownloads(), isEmpty);

      await db.close();
    });

    test('owner-scoped migration is idempotent and preserves rows',
        () async {
      final files = _MemoryFileStore();
      final db = AppDatabase(NativeDatabase.memory());
      String? currentOwner = ownerA;
      final store = DriftWorksheetDownloadStore(db,
          files: files, currentUserIdProvider: () => currentOwner);
      await store.saveDownload(
        resourceId: 'ws_m1',
        title: 'M',
        contentPayload: _payload('ws_m1'),
        fileBytes: const [4],
      );
      await migrateDownloadedResourcesToOwnerScoped(db);
      await migrateDownloadedResourcesToOwnerScoped(db);
      expect((await store.listDownloads()).length, 1);
      currentOwner = ownerB;
      expect(await store.listDownloads(), isEmpty);

      await db.close();
    });
  });

  group('saved_materials ownership for Ready-to-download', () {
    test('Ready candidates are owner-filtered; unclaimed hidden', () async {
      final db = AppDatabase(NativeDatabase.memory());
      await ensureAccountIsolation(db);

      await db.resourceDao.insertSavedMaterial(
        savedMaterialFromGenerationContent('gc_a', _payload('gc_a')),
      );
      await claimOwnership(
          db, entityType: 'saved_material', entityId: 'gc_a', ownerId: ownerA);
      await db.resourceDao.insertSavedMaterial(
        savedMaterialFromGenerationContent('gc_legacy', _payload('gc_legacy')),
      );

      final ownedA = await ownedEntityIds(db,
          entityType: 'saved_material', ownerId: ownerA);
      final rowsA = await db.resourceDao
          .getOwnedSavedMaterials(type: 'worksheet', ownedIds: ownedA);
      expect(rowsA.map((r) => r.id), ['gc_a']);

      final ownedB = await ownedEntityIds(db,
          entityType: 'saved_material', ownerId: ownerB);
      final rowsB = await db.resourceDao
          .getOwnedSavedMaterials(type: 'worksheet', ownedIds: ownedB);
      expect(rowsB, isEmpty);

      // Single-row gate for preview fallback.
      expect(
          await db.resourceDao.getOwnedSavedMaterialById('gc_a', ownedA),
          isNotNull);
      expect(
          await db.resourceDao.getOwnedSavedMaterialById('gc_a', ownedB),
          isNull);

      await db.close();
    });
  });
}
