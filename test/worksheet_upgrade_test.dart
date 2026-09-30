import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maatribhasha/core/constants/worksheet_languages.dart';
import 'package:maatribhasha/core/database/app_database.dart';
import 'package:maatribhasha/core/enums/app_enums.dart';
import 'package:maatribhasha/core/sync/remote_content_data_source.dart';
import 'package:maatribhasha/core/sync/worksheet_download_store.dart';
import 'package:maatribhasha/core/sync/worksheet_generation_sync.dart';
import 'package:maatribhasha/core/sync/worksheet_pdf_writer.dart';
import 'package:shared_preferences/shared_preferences.dart';

TeacherGenerationRequestModel _fullRequest() {
  return buildWorksheetGenerationRequest(
    grade: 2,
    section: 'A',
    subject: 'Mathematics',
    topic: 'Numbers up to 100',
    topicSource: 'curriculum',
    topicId: 'M2.1.4',
    topicInputLanguage: 'en',
    nipunOutcome: 'M2.1.4',
    language1: 'hi',
    language2: 'sat',
    difficulty: DifficultyLevel.medium,
    types: const [WorksheetType.practice, WorksheetType.fillInTheBlanks],
    questionCount: 10,
    visualSupport: true,
    bilingualAnswers: true,
    audioCue: false,
    deviceId: 'device_1',
    teacherId: 'teacher_1',
    origin: 'online',
  );
}

Map<String, dynamic> _payload() => {
      'content_id': 'WS-TEST-1',
      'request_id': 'req-1',
      'title': 'Numbers up to 100',
      'title_hi': 'Numbers up to 100',
      'title_source': 'Numbers up to 100 (source)',
      'title_target': 'Numbers up to 100 (target)',
      'grade': 2,
      'section': 'A',
      'subject': 'Mathematics',
      'topic': 'Numbers up to 100',
      'topic_source': 'curriculum',
      'nipun_outcome': 'M2.1.4',
      'source_language': 'hi',
      'target_language': 'sat',
      'language_1': 'hi',
      'language_2': 'sat',
      'difficulty': 'medium',
      'worksheet_type': 'practice',
      'worksheet_types': ['practice', 'fill_blank'],
      'question_count': 2,
      'visual_support': true,
      'bilingual_answers': true,
      'audio_cue': false,
      'questions': [
        {
          'questionNumber': 1,
          'promptHindi': 'Source prompt 1',
          'promptTribal': 'Target prompt 1',
          'prompt_source': 'Source prompt 1',
          'prompt_target': 'Target prompt 1',
          'options': ['1', '2'],
          'answer': '1',
          'visualIllustration': '',
          'type': 'practice',
        },
        {
          'questionNumber': 2,
          'promptHindi': 'Source prompt 2',
          'promptTribal': 'Target prompt 2',
          'prompt_source': 'Source prompt 2',
          'prompt_target': 'Target prompt 2',
          'options': ['3', '4'],
          'answer': '3',
          'visualIllustration': '',
          'type': 'fill_blank',
        },
      ],
    };

void main() {
  group('Generator form: selections flow into the request', () {
    test('1-2. class + section sent', () {
      final req = _fullRequest();
      expect(req.grade, 2);
      expect(req.section, 'A');
      final json = req.toJson();
      expect(json['grade'], 2);
      expect(json['section'], 'A');
    });

    test('3. curriculum topic carries id + NIPUN', () {
      final req = _fullRequest();
      expect(req.topicSource, 'curriculum');
      expect(req.topicId, 'M2.1.4');
      expect(req.topic, 'Numbers up to 100');
      expect(req.nipunOutcome, 'M2.1.4');
    });

    test('4-5. custom Hindi topic preserved exactly', () {
      final req = buildWorksheetGenerationRequest(
        grade: 2,
        section: 'A',
        subject: 'Mathematics',
        topic: 'दो अंकों की जोड़',
        topicSource: 'custom',
        topicInputLanguage: 'hi',
        difficulty: DifficultyLevel.medium,
        types: const [WorksheetType.practice],
        questionCount: 7,
        visualSupport: true,
        bilingualAnswers: true,
        audioCue: false,
      );
      expect(req.topic, 'दो अंकों की जोड़');
      expect(req.topicSource, 'custom');
      expect(req.topicInputLanguage, 'hi');
      expect(req.nipunOutcome, isNull);
      expect(req.toJson()['topic_text'], 'दो अंकों की जोड़');
    });

    test('custom English topic + input language persistence', () {
      final req = buildWorksheetGenerationRequest(
        grade: 2,
        subject: 'Mathematics',
        topic: 'Addition of two-digit numbers',
        topicSource: 'custom',
        topicInputLanguage: 'en',
        difficulty: DifficultyLevel.easy,
        types: const [WorksheetType.matching],
        questionCount: 5,
        visualSupport: false,
        bilingualAnswers: true,
        audioCue: false,
      );
      expect(req.topicInputLanguage, 'en');
      expect(req.toJson()['topic_input_language'], 'en');
    });

    test('7. five languages selectable', () {
      expect(WorksheetLanguages.all.length, 5);
      expect(
          WorksheetLanguages.all.map((l) => l.code).toSet(),
          {'hi', 'en', 'sat', 'ho', 'unr'});
      expect(WorksheetLanguages.byCode('sat-IN').displayName, 'Santali');
      expect(WorksheetLanguages.byCode('mundari').code, 'unr');
    });

    test('8. language-pair values sent, pair differs', () {
      for (final pair in [
        ['hi', 'sat'],
        ['en', 'sat'],
        ['ho', 'hi'],
        ['unr', 'hi'],
      ]) {
        final req = buildWorksheetGenerationRequest(
          grade: 2,
          subject: 'Mathematics',
          topic: 'T',
          language1: pair[0],
          language2: pair[1],
          difficulty: DifficultyLevel.medium,
          types: const [WorksheetType.practice],
          questionCount: 5,
          visualSupport: true,
          bilingualAnswers: true,
          audioCue: false,
        );
        expect(req.language1, pair[0]);
        expect(req.language2, pair[1]);
        expect(req.language1 == req.language2, isFalse);
        expect(req.toJson()['language_1'], pair[0]);
        expect(req.toJson()['language_2'], pair[1]);
      }
    });

    test('9. custom question count exact', () {
      for (final n in [5, 7, 10, 20]) {
        final req = buildWorksheetGenerationRequest(
          grade: 2,
          subject: 'Mathematics',
          topic: 'T',
          difficulty: DifficultyLevel.medium,
          types: const [WorksheetType.practice],
          questionCount: n,
          visualSupport: true,
          bilingualAnswers: true,
          audioCue: false,
        );
        expect(req.questionCount, n);
        expect(req.toJson()['question_count'], n);
      }
    });

    test('10. multi-select worksheet types all included', () {
      final req = _fullRequest();
      expect(req.worksheetTypes, ['practice', 'fill_blank']);
      expect(req.toJson()['worksheet_types'], ['practice', 'fill_blank']);
    });

    test('12. difficulty affects the request', () {
      TeacherGenerationRequestModel reqFor(DifficultyLevel d) =>
          buildWorksheetGenerationRequest(
            grade: 2,
            subject: 'Mathematics',
            topic: 'T',
            difficulty: d,
            types: const [WorksheetType.practice],
            questionCount: 5,
            visualSupport: true,
            bilingualAnswers: true,
            audioCue: false,
          );
      expect(reqFor(DifficultyLevel.easy).difficulty, 'easy');
      expect(reqFor(DifficultyLevel.medium).difficulty, 'medium');
      expect(reqFor(DifficultyLevel.challenging).difficulty, 'hard');
    });

    test('14. full request schema keys present', () {
      final json = _fullRequest().toJson();
      for (final key in [
        'request_id',
        'teacher_id',
        'device_id',
        'grade',
        'section',
        'subject',
        'topic_source',
        'topic_input_language',
        'topic',
        'topic_text',
        'nipun_outcome',
        'language_1',
        'language_2',
        'question_count',
        'worksheet_types',
        'difficulty',
        'visual_illustrations',
        'bilingual_answer_spaces',
        'audio_pronunciation',
        'created_at',
      ]) {
        expect(json.containsKey(key), isTrue, reason: 'missing $key');
      }
      final raw = jsonEncode(json).toLowerCase();
      expect(raw.contains('sarvam'), isFalse);
      expect(raw.contains('api_key'), isFalse);
    });

    test('request survives offline queue round-trip', () {
      final req = _fullRequest();
      final restored =
          TeacherGenerationRequestModel.fromJson(req.toJson());
      expect(restored.grade, 2);
      expect(restored.section, 'A');
      expect(restored.topicSource, 'curriculum');
      expect(restored.language1, 'hi');
      expect(restored.language2, 'sat');
      expect(restored.worksheetTypes, ['practice', 'fill_blank']);
      expect(restored.questionCount, 10);
    });
  });

  group('Download: real file + metadata', () {
    test('local PDF render produces real bytes with content', () {
      final bytes = renderWorksheetPdf(_payload());
      expect(bytes.length, greaterThan(500));
      // %PDF magic header
      expect(bytes.sublist(0, 4), [0x25, 0x50, 0x44, 0x46]);
      // Topic text embedded as UTF-16BE hex
      final hex = bytes
          .map((b) => b.toRadixString(16).padLeft(2, '0'))
          .join()
          .toUpperCase();
      final encoded = 'Numbers up to 100'
          .runes
          .map((r) => r.toRadixString(16).padLeft(4, '0').toUpperCase())
          .join();
      expect(hex.contains(encoded), isTrue);
    });

    test('buildDownloadRecord stores real metadata', () {
      final record = buildDownloadRecord(
        resourceId: 'WS-TEST-1',
        content: _payload(),
        fileName: 'WS-TEST-1.pdf',
        localFilePath: '/tmp/WS-TEST-1.pdf',
        fileBytes: [1, 2, 3],
      );
      expect(record.resourceId, 'WS-TEST-1');
      expect(record.grade, 2);
      expect(record.section, 'A');
      expect(record.subject, 'Mathematics');
      expect(record.topic, 'Numbers up to 100');
      expect(record.nipunOutcome, 'M2.1.4');
      expect(record.language1, 'hi');
      expect(record.language2, 'sat');
      expect(record.worksheetTypes, ['practice', 'fill_blank']);
      expect(record.questionCount, 2);
      expect(record.fileSize, 3);
      expect(record.format, 'pdf');
      expect(record.offlineAvailable, isTrue);
      expect(record.downloadedAt, isNotNull);
      // Round-trip through the stored map form.
      final restored = WorksheetDownload.tryFromMap(record.toMap());
      expect(restored, isNotNull);
      expect(restored!.resourceId, 'WS-TEST-1');
      expect(restored.worksheetTypes, ['practice', 'fill_blank']);
      expect(restored.contentJson!['title'], 'Numbers up to 100');
    });

    test('Prefs store: save/list/re-download/delete (duplicate protection)',
        () async {
      SharedPreferences.setMockInitialValues({});
      final store = PrefsWorksheetDownloadStore();
      final payload = _payload();
      final first = await store.saveDownload(
        resourceId: 'WS-TEST-1',
        title: 'Numbers up to 100',
        contentPayload: payload,
        fileBytes: renderWorksheetPdf(payload),
      );
      expect(first.localFilePath.startsWith('web-local:'), isTrue);
      var list = await store.listDownloads();
      expect(list.length, 1);

      // Re-download updates in place (no duplicate).
      await store.saveDownload(
        resourceId: 'WS-TEST-1',
        title: 'Numbers up to 100',
        contentPayload: payload,
        fileBytes: renderWorksheetPdf(payload),
      );
      list = await store.listDownloads();
      expect(list.length, 1);

      await store.markOpened('WS-TEST-1');
      final opened = await store.getByResourceId('WS-TEST-1');
      expect(opened!.lastOpenedAt, isNotNull);

      await store.rename('WS-TEST-1', 'Renamed');
      expect((await store.getByResourceId('WS-TEST-1'))!.title, 'Renamed');

      await store.deleteDownload('WS-TEST-1');
      expect(await store.listDownloads(), isEmpty);
    });

    test('Drift store: save/list/open/delete + file exists', () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(() async => db.close());
      final store = DriftWorksheetDownloadStore(db);
      final payload = _payload();
      final record = await store.saveDownload(
        resourceId: 'WS-TEST-1',
        title: 'Numbers up to 100',
        contentPayload: payload,
        fileBytes: renderWorksheetPdf(payload),
      );
      // Real file on disk.
      expect(record.localFilePath.endsWith('.pdf'), isTrue);
      final bytes = await readDownloadBytes(record);
      expect(bytes, isNotNull);
      expect(bytes!.sublist(0, 4), [0x25, 0x50, 0x44, 0x46]);

      // Duplicate protection.
      await store.saveDownload(
        resourceId: 'WS-TEST-1',
        title: 'Numbers up to 100',
        contentPayload: payload,
        fileBytes: renderWorksheetPdf(payload),
      );
      expect((await store.listDownloads()).length, 1);

      await store.markOpened('WS-TEST-1');
      await store.deleteDownload('WS-TEST-1');
      expect(await store.listDownloads(), isEmpty);
      // Local file removed.
      expect(await readDownloadBytes(record), isNull);
    });
  });
}
