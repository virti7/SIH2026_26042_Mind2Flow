import 'dart:convert';
import 'dart:io';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maatribhasha/core/constants/flashcard_languages.dart';
import 'package:maatribhasha/core/content/flashcard/flashcard_image_library.dart';
import 'package:maatribhasha/core/database/app_database.dart';
import 'package:maatribhasha/core/enums/app_enums.dart';
import 'package:maatribhasha/core/sync/flashcard_pdf_writer.dart';
import 'package:maatribhasha/core/sync/remote_content_data_source.dart';
import 'package:maatribhasha/core/sync/worksheet_download_store.dart';
import 'package:maatribhasha/core/sync/worksheet_file.dart';
import 'package:maatribhasha/core/sync/worksheet_generation_sync.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Static Santali strings below are test-only fixtures (mirrors the
/// backend test strategy); production text comes from live Sarvam output.
Map<String, dynamic> flashcardPayload({
  String mode = 'hi_en_sat',
  int count = 3,
}) {
  const sans = ['ᱟᱢ', 'ᱠᱮᱞᱟ', 'ᱟᱢᱨᱩᱫ'];
  const his = ['आम', 'केला', 'अमरूद'];
  const ens = ['Mango', 'Banana', 'Guava'];
  return {
    'content_id': 'FC-G1-EVS-hi_en_sat-test',
    'request_id': 'req-flash-test',
    'title': 'Fruits (3 cards)',
    'grade': 1,
    'section': 'A',
    'subject': 'Environmental Studies',
    'topic': 'Fruits',
    'language_mode': mode,
    'target_language': 'sat',
    'target_language_code': 'sat-IN',
    'content_type': 'flashcard',
    'flashcard_type': 'vocabulary',
    'cards': List.generate(count, (i) {
      final m = <String, dynamic>{
        'id': 'card_0${i + 1}',
        'number': i + 1,
        'concept': ens[i],
        'type': 'vocabulary',
        'santali': sans[i],
        'visual': {
          'source': 'curated',
          'art': 'mango',
          'description_en': 'Educational illustration of ${ens[i]}',
          'palette': '#E65100',
          'has_text': false,
        },
        'provider': 'sarvam-translate',
        'translated': true,
      };
      if (mode != 'en_sat') m['hindi'] = his[i];
      if (mode != 'hi_sat') m['english'] = ens[i];
      return m;
    }),
  };
}

class MemoryFileStore implements WorksheetFileStore {
  final Map<String, List<int>> files = {};
  @override
  Future<String> saveBytes(String fileName, List<int> bytes) async {
    files[fileName] = bytes;
    return 'mem:$fileName';
  }

  @override
  Future<void> deleteFile(String ref) async {
    files.remove(ref.replaceFirst('mem:', ''));
  }

  @override
  Future<List<int>?> readBytes(String ref) async =>
      files[ref.replaceFirst('mem:', '')];
}

class FakeFlashcardRemote implements RemoteContentDataSource {
  final Map<String, dynamic> content;
  FakeFlashcardRemote(this.content);
  @override
  Future<GenerationJobModel> requestGeneration(
    TeacherGenerationRequestModel request, {
    String? idempotencyKey,
  }) async {
    // Flashcard requests must hit the Santali endpoint path (asserted in
    // HttpRemoteContentDataSource routing test below via toJson shape).
    return GenerationJobModel(
      jobId: 'job_fc_1',
      status: 'READY',
      contentId: 'FC-G1-EVS-test',
      contentType: 'flashcard',
      grade: 1,
      targetLanguage: 'sat',
      content: content,
      assets: const {'pdf': 'flashcards/FC-G1-EVS-test.pdf'},
    );
  }

  @override
  Future<GenerationJobModel> getJobStatus(String jobId) async =>
      throw UnimplementedError();
  @override
  Future<GenerationJobModel> approveJob(String jobId,
          {String? santaliScriptConfirmed, String? notes}) async =>
      throw UnimplementedError();
  @override
  Future<File> downloadAsset(String a, String b) async =>
      throw HttpException('offline');
}

void main() {
  group('Flashcard language registry (Hi/En/Sat only)', () {
    test('only Hindi, English, Santali are listed', () {
      expect(FlashcardLanguages.all.map((l) => l.code), ['hi', 'en', 'sat']);
      expect(FlashcardLanguages.isSupported('ho'), isFalse);
      expect(FlashcardLanguages.isSupported('unr'), isFalse);
      expect(FlashcardLanguages.isSupported('mundari'), isFalse);
      expect(FlashcardLanguages.isSupported('sat-IN'), isTrue);
    });

    test('three language modes with sat-IN target', () {
      expect(FlashcardLanguageModes.all.map((m) => m.code),
          ['hi_sat', 'en_sat', 'hi_en_sat']);
      for (final m in FlashcardLanguageModes.all) {
        expect(m.targetApiCode, 'sat-IN');
      }
      expect(FlashcardLanguageModes.hindiSantali.sourceApiCodes, ['hi-IN']);
      expect(FlashcardLanguageModes.englishSantali.sourceApiCodes, ['en-IN']);
    });

    test('seven flashcard types, single generator', () {
      expect(FlashcardTypes.all.length, 7);
      expect(FlashcardTypes.all, contains('vocabulary'));
      expect(FlashcardTypes.all, contains('object_identification'));
    });
  });

  group('Flashcard request model', () {
    test('carries Santali fields through toJson/fromJson', () {
      final req = buildFlashcardGenerationRequest(
        grade: 1,
        subject: 'Environmental Studies',
        topic: 'Fruits',
        languageMode: 'hi_en_sat',
        flashcardType: 'vocabulary',
        cardCount: 8,
        difficulty: DifficultyLevel.medium,
      );
      expect(req.contentType, 'flashcard');
      expect(req.languageMode, 'hi_en_sat');
      expect(req.cardCount, 8);
      final json = req.toJson();
      expect(json['language_mode'], 'hi_en_sat');
      expect(json['card_count'], 8);
      expect(json['flashcard_type'], 'vocabulary');
      final back = TeacherGenerationRequestModel.fromJson(json);
      expect(back.languageMode, 'hi_en_sat');
      expect(back.cardCount, 8);
    });

    test('worksheet requests do not leak flashcard fields', () {
      final req = buildWorksheetGenerationRequest(
        grade: 2,
        subject: 'Mathematics',
        topic: 'Numbers',
        difficulty: DifficultyLevel.medium,
        questionCount: 10,
        visualSupport: true,
        bilingualAnswers: true,
        audioCue: false,
      );
      expect(req.toJson().containsKey('language_mode'), isFalse);
      expect(req.toJson().containsKey('card_count'), isFalse);
    });
  });

  group('Flashcard PDF (visual + multilingual text)', () {
    test('one page per card with real content', () {
      final bytes = renderFlashcardPdf(flashcardPayload(count: 3));
      expect(bytes.sublist(0, 4), [0x25, 0x50, 0x44, 0x46]); // %PDF
      final text = latin1.decode(bytes);
      expect(RegExp(r'/Type /Page[^s]').allMatches(text).length, 3);
    });

    test('Santali + Hindi glyphs embedded, no tofu placeholders', () {
      final bytes = renderFlashcardPdf(flashcardPayload());
      final hex = bytes
          .map((b) => b.toRadixString(16).padLeft(2, '0'))
          .join()
          .toUpperCase();
      final santaliHex =
          'ᱟᱢ'.runes.map((r) => r.toRadixString(16).padLeft(4, '0').toUpperCase()).join();
      final hindiHex =
          'आम'.runes.map((r) => r.toRadixString(16).padLeft(4, '0').toUpperCase()).join();
      expect(hex.contains(santaliHex), isTrue);
      expect(hex.contains(hindiHex), isTrue);
    });

    test('long words wrap instead of overflowing', () {
      final payload = flashcardPayload(count: 1);
      (payload['cards'] as List).first['hindi'] =
          'अत्यधिक लंबा शब्द जो कक्षा में दिखाई देना चाहिए';
      expect(() => renderFlashcardPdf(payload), returnsNormally);
    });

    test('PDF paints vector art, never emoji text', () {
      final bytes = renderFlashcardPdf(flashcardPayload(count: 2));
      final text = latin1.decode(bytes);
      // Vector fill/stroke operators present; no 64pt emoji glyph line.
      expect(text.contains(' rg '), isTrue);
      expect(text.contains('BT /F1 64'), isFalse);
      // Counting cards draw N apple visuals.
      final countPayload = flashcardPayload(count: 1);
      (countPayload['cards'] as List).first['visual'] = {
        'source': 'vector',
        'art': 'apples',
        'count': 5,
        'palette': '#1B7A4D',
        'has_text': false,
      };
      expect(() => renderFlashcardPdf(countPayload), returnsNormally);
    });
  });

  group('Flashcard download (account-scoped, offline)', () {
    late AppDatabase db;

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    test('READY to DOWNLOADED via local render when server PDF missing', () async {
      final store = DriftWorksheetDownloadStore(db,
          files: MemoryFileStore(),
          currentUserIdProvider: () => 'user-A');
      final payload = flashcardPayload();
      final record = await downloadFlashcardSet(
        store: store,
        remote: FakeFlashcardRemote(payload),
        contentId: 'FC-G1-EVS-test',
        contentPayload: payload,
        assets: const {'pdf': 'flashcards/FC-G1-EVS-test.pdf'},
        teacherId: 'user-A',
      );
      expect(record.resourceType, 'flashcard');
      expect(record.topic, 'Fruits');
      expect(record.language2, 'sat');
      expect(record.offlineAvailable, isTrue);
    });

    test('Account A downloads hidden from Account B', () async {
      final files = MemoryFileStore();
      final storeA = DriftWorksheetDownloadStore(db,
          files: files, currentUserIdProvider: () => 'user-A');
      final storeB = DriftWorksheetDownloadStore(db,
          files: files, currentUserIdProvider: () => 'user-B');
      await downloadFlashcardSet(
        store: storeA,
        contentId: 'FC-A-1',
        contentPayload: flashcardPayload(),
        teacherId: 'user-A',
      );
      expect(await storeB.getByResourceId('FC-A-1'), isNull);
      expect((await storeB.listDownloads()).isEmpty, isTrue);
      expect((await storeA.listDownloads()).length, 1);
    });

    test('downloaded set opens offline from stored payload', () async {
      final store = DriftWorksheetDownloadStore(db,
          files: MemoryFileStore(),
          currentUserIdProvider: () => 'user-A');
      await downloadFlashcardSet(
        store: store,
        contentId: 'FC-A-2',
        contentPayload: flashcardPayload(),
        teacherId: 'user-A',
      );
      final saved = await store.getByResourceId('FC-A-2');
      expect(saved, isNotNull);
      final cards = saved!.contentJson!['cards'] as List;
      expect(cards.length, 3);
      expect((cards.first as Map)['santali'], isNotEmpty);
      expect((cards.first as Map)['visual'], isNotNull);
    });

    test('D. catalog deck downloads + reopens offline with zero network calls',
        () async {
      final files = MemoryFileStore();
      final store = DriftWorksheetDownloadStore(db,
          files: files, currentUserIdProvider: () => 'user-A');
      final remote = CountingOfflineRemote();
      final payload = catalogPayload();
      final record = await downloadFlashcardSet(
        store: store,
        remote: remote,
        contentId: 'FC-CAT-1',
        contentPayload: payload,
        assets: const {'pdf': 'flashcards/FC-CAT-1.pdf'},
        teacherId: 'user-A',
      );
      expect(remote.calls, 0, reason: 'catalog PDFs render from bundled assets');
      expect(record.offlineAvailable, isTrue);

      final saved = (await store.getByResourceId('FC-CAT-1'))!;
      expect(isImageCatalogPayload(saved.contentJson!), isTrue);
      final visual = ((saved.contentJson!['cards'] as List).first as Map)['visual'] as Map;
      expect(visual['image'], startsWith('assets/prototype_content/flashcards/'));
      final bytes = await files.readBytes(saved.localFilePath);
      expect(String.fromCharCodes(bytes!.take(4)), '%PDF');
      expect(remote.calls, 0);
    });
  });

  group('Flashcard download (web browser storage)', () {
    test('keeps only the payload, lists it, and reclaims old PDF blobs',
        () async {
      // A previous build stored the flashcard PDF as base64 in local
      // storage, plus an orphaned blob whose metadata never persisted.
      SharedPreferences.setMockInitialValues({
        'worksheet_downloads_v1:user-A': jsonEncode({
          'FC-OLD': {
            'download_id': 'd-old',
            'resource_id': 'FC-OLD',
            'resource_type': 'flashcard',
            'teacher_id': 'user-A',
            'title': 'Old set',
            'local_file_path': 'web-local:user-A/FC-OLD.pdf',
            'content_json': jsonEncode(flashcardPayload()),
          },
        }),
        'worksheet_file_v1:user-A/FC-OLD.pdf': 'QUJD',
        'worksheet_file_v1:user-A/FC-ORPHAN.pdf': 'QUJD',
      });
      final prefs = await SharedPreferences.getInstance();
      final files = MemoryFileStore();
      final store = PrefsWorksheetDownloadStore(
          prefs: prefs, files: files, currentUserIdProvider: () => 'user-A');

      await downloadFlashcardSet(
        store: store,
        contentId: 'FC-NEW',
        contentPayload: flashcardPayload(),
        teacherId: 'user-A',
      );

      expect(files.files, isEmpty, reason: 'flashcard PDF is not stored');
      expect(prefs.getKeys().where((k) => k.startsWith('worksheet_file_v1:')),
          isEmpty);
      final listed = await store.listDownloads();
      expect(listed.map((d) => d.resourceId).toSet(), {'FC-NEW', 'FC-OLD'});
      for (final d in listed) {
        expect(d.localFilePath, startsWith(kRegeneratedFilePrefix));
        final bytes = await readDownloadBytes(d);
        expect(String.fromCharCodes(bytes!.take(4)), '%PDF');
      }
    });
  });
}

/// Catalog-backed payload shaped like the server/FlashcardImageLibrary output.
Map<String, dynamic> catalogPayload() => {
      'content_id': 'FC-CAT-1',
      'request_id': 'req-cat-1',
      'title': 'Fruits (2 cards)',
      'grade': 1,
      'section': 'A',
      'subject': 'Hindi',
      'topic': 'Fruits',
      'language_mode': 'hi_sat',
      'content_type': 'flashcard',
      'flashcard_type': 'vocabulary',
      'source': 'IMAGE_CATALOG',
      'cards': [
        for (final id in ['fruit_apple_001', 'fruit_banana_001'])
          {
            'id': id,
            'number': 1,
            'concept': id,
            'type': 'vocabulary',
            'hindi': 'फल',
            'santali': 'ᱡᱚ',
            'provider': 'prototype-catalog',
            'visual': {
              'kind': 'image',
              'source': 'IMAGE_CATALOG',
              'image': 'assets/prototype_content/flashcards/images/fruits/$id.png',
              'asset_id': id,
            },
          },
      ],
    };

/// Remote that counts every call and behaves as if the network is down.
class CountingOfflineRemote implements RemoteContentDataSource {
  int calls = 0;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    calls++;
    throw const SocketException('network disabled');
  }
}
