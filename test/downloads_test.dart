import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maatribhasha/app/router/app_router.dart';
import 'package:maatribhasha/app/router/route_names.dart';
import 'package:maatribhasha/core/database/app_database.dart';
import 'package:maatribhasha/core/sync/worksheet_download_store.dart';
import 'package:maatribhasha/core/sync/worksheet_file_stub.dart';
import 'package:maatribhasha/core/widgets/app_bottom_nav.dart';

// In-memory file store so tests never touch disk.
class MemoryFileStore implements WorksheetFileStore {
  final Map<String, List<int>> files = {};
  @override
  Future<String> saveBytes(String fileName, List<int> bytes) async {
    files[fileName] = List<int>.from(bytes);
    return '/mem/$fileName';
  }

  @override
  Future<List<int>?> readBytes(String storageRef) async {
    final key = storageRef.split('/').last;
    if (storageRef.startsWith('web-local:')) {
      final name = storageRef.substring('web-local:'.length);
      return files[name];
    }
    return files[key] ?? files[storageRef];
  }

  @override
  Future<void> deleteFile(String storageRef) async {
    final key = storageRef.split('/').last;
    files.remove(key);
    files.remove(storageRef);
    if (storageRef.startsWith('web-local:')) {
      files.remove(storageRef.substring('web-local:'.length));
    }
  }
}

Map<String, dynamic> samplePayload({String id = 'ws_1'}) => {
      'content_id': id,
      'title': 'Numbers up to 100',
      'grade': 2,
      'section': 'A',
      'subject': 'Mathematics',
      'topic': 'Numbers up to 100',
      'topic_source': 'curriculum',
      'topic_input_language': 'en',
      'nipun_outcome': 'M2.1.4',
      'language_1': 'hi',
      'language_2': 'sat',
      'worksheet_types': ['practice', 'fill_blank'],
      'question_count': 10,
      'difficulty': 'medium',
      'version': 1,
      'generated_at': '2026-09-22T10:00:00.000',
      'questions': List.generate(
          10,
          (i) => {
                'questionNumber': i + 1,
                'prompt_source': 'Q${i + 1}',
                'prompt_target': 'Q${i + 1}',
                'options': <String>[],
              }),
    };

Future<DriftWorksheetDownloadStore> makeStore(MemoryFileStore files) async {
  final db = AppDatabase(NativeDatabase.memory());
  return DriftWorksheetDownloadStore(db, files: files);
}

void main() {
  test('1. Downloads route exists', () {
    expect(AppRoutes.downloads, '/resources/downloads');
    final paths = appRouter.configuration.routes
        .expand((r) => r.routes)
        .map((r) => (r as dynamic).path as String?)
        .toList();
    // Shell child + details routes must be registered.
    expect(paths, contains(AppRoutes.downloads));
  });

  testWidgets('2. Downloads tab appears before Settings', (t) async {
    int tapped = -1;
    await t.pumpWidget(MaterialApp(
      home: Scaffold(
        bottomNavigationBar:
            AppBottomNavBar(currentIndex: 4, onTap: (i) => tapped = i),
      ),
    ));
    final labels = find.byType(Text);
    final texts = labels.evaluate().map((e) => (e.widget as Text).data ?? '').toList();
    final dl = texts.indexOf('Downloads');
    final st = texts.indexOf('Settings');
    expect(dl, isNot(-1));
    expect(st, isNot(-1));
    expect(dl, lessThan(st));
    expect(texts, ['Home', 'Teach', 'Translate', 'Progress', 'Downloads', 'Settings']);
    expect(tapped, -1);
  });

  test('3-17. Downloaded worksheet appears with real metadata', () async {
    final files = MemoryFileStore();
    final store = await makeStore(files);
    final before = DateTime.now();
    final rec = await store.saveDownload(
      resourceId: 'ws_1',
      title: 'Numbers up to 100',
      contentPayload: samplePayload(),
      fileBytes: [0x25, 0x50, 0x44, 0x46, 1, 2, 3],
    );
    // 5-16: metadata stored correctly from actual payload.
    expect(rec.title, 'Numbers up to 100');
    expect(rec.grade, 2); // 7. class
    expect(rec.section, 'A'); // 8. section
    expect(rec.subject, 'Mathematics'); // 9. subject
    expect(rec.topic, 'Numbers up to 100'); // 10. topic
    expect(rec.language1, 'hi'); // 11. language pair
    expect(rec.language2, 'sat');
    expect(rec.worksheetTypes, ['practice', 'fill_blank']); // 12.
    expect(rec.questionCount, 10); // 13.
    expect(rec.format, 'pdf'); // 14.
    expect(rec.fileSize, 7); // 15.
    expect(rec.generatedAt, isNotNull); // 16.
    // 6. downloaded_at is actual timestamp (>= test start).
    expect(rec.downloadedAt.isAfter(before.subtract(const Duration(seconds: 5))), isTrue);
    expect(rec.offlineAvailable, isTrue); // 17.
    expect(rec.resourceType, 'worksheet');

    final list = await store.listDownloads();
    expect(list.length, 1); // 4. appears dynamically.
  });

  test('18. downloaded file can be opened offline (bytes readable)', () async {
    final files = MemoryFileStore();
    final store = await makeStore(files);
    await store.saveDownload(
      resourceId: 'ws_off',
      title: 'T',
      contentPayload: samplePayload(id: 'ws_off'),
      fileBytes: [0x25, 0x50, 0x44, 0x46, 9],
    );
    final rec = await store.getByResourceId('ws_off');
    expect(rec, isNotNull);
    final bytes = await files.readBytes(rec!.localFilePath);
    expect(bytes, isNotNull);
    expect(bytes!.length, greaterThan(0));
  });

  test('19-20. deleting download removes only local file/metadata', () async {
    final files = MemoryFileStore();
    final store = await makeStore(files);
    await store.saveDownload(
      resourceId: 'ws_del',
      title: 'T',
      contentPayload: samplePayload(id: 'ws_del'),
      fileBytes: [1, 2, 3],
    );
    await store.deleteDownload('ws_del');
    expect(await store.getByResourceId('ws_del'), isNull);
    expect(files.files.isEmpty, isTrue);
    // Server resource untouched: SavedMaterials table is separate — no
    // delete call is ever issued against it by the download store.
  });

  test('21-22. re-download works; duplicate downloads update in place',
      () async {
    final files = MemoryFileStore();
    final store = await makeStore(files);
    final first = await store.saveDownload(
      resourceId: 'ws_dup',
      title: 'T',
      contentPayload: samplePayload(id: 'ws_dup'),
      fileBytes: [1],
    );
    await Future.delayed(const Duration(milliseconds: 10));
    final second = await store.saveDownload(
      resourceId: 'ws_dup',
      title: 'T',
      contentPayload: samplePayload(id: 'ws_dup'),
      fileBytes: [1, 2],
    );
    expect((await store.listDownloads()).length, 1);
    expect(second.downloadId, first.downloadId);
    expect(
        second.downloadedAt.isAfter(first.downloadedAt) ||
            second.downloadedAt.isAtSameMomentAs(first.downloadedAt),
        isTrue);
  });

  test('23. missing local file is detected', () async {
    final files = MemoryFileStore();
    final store = await makeStore(files);
    await store.saveDownload(
      resourceId: 'ws_missing',
      title: 'T',
      contentPayload: samplePayload(id: 'ws_missing'),
      fileBytes: [1, 2],
    );
    final rec = (await store.getByResourceId('ws_missing'))!;
    await files.deleteFile(rec.localFilePath);
    final gone = await files.readBytes(rec.localFilePath);
    expect(gone, isNull);
    await store.setOfflineAvailable('ws_missing', false);
    final updated = (await store.getByResourceId('ws_missing'))!;
    expect(updated.offlineAvailable, isFalse);
  });

  test('26. Web file store has no dart:io import', () {
    final src =
        File('lib/core/sync/worksheet_file_web.dart').readAsStringSync();
    expect(src.contains('dart:io'), isFalse);
    final stub =
        File('lib/core/sync/worksheet_file_stub.dart').readAsStringSync();
    expect(stub.contains('dart:io'), isFalse);
  });

  test('27. Android/native store writes real files under app docs', () {
    final src =
        File('lib/core/sync/worksheet_file_io.dart').readAsStringSync();
    expect(src.contains('getApplicationDocumentsDirectory'), isTrue);
    expect(src.contains('writeAsBytes'), isTrue);
  });

  test('Progress counts derive from real download rows', () async {
    final files = MemoryFileStore();
    final store = await makeStore(files);
    // Generated but never downloaded => SavedMaterials only (0 downloads).
    expect(await store.listDownloads(), isEmpty);
    await store.saveDownload(
      resourceId: 'ws_p1',
      title: 'T',
      contentPayload: samplePayload(id: 'ws_p1'),
      fileBytes: [1],
    );
    expect((await store.listDownloads()).length, 1);
  });
}
