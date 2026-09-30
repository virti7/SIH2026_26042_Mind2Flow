import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maatribhasha/core/database/app_database.dart';
import 'package:maatribhasha/core/enums/app_enums.dart';
import 'package:maatribhasha/core/sync/remote_content_data_source.dart';
import 'package:maatribhasha/core/sync/remote_data_source.dart';
import 'package:maatribhasha/core/sync/worksheet_generation_sync.dart';

class FakeContentSource implements RemoteContentDataSource {
  int fetchCount = 0;

  @override
  Future<GenerationJobModel> requestGeneration(
    TeacherGenerationRequestModel request, {
    String? idempotencyKey,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<GenerationJobModel> getJobStatus(String jobId) async {
    fetchCount++;
    return GenerationJobModel(
      jobId: jobId,
      status: 'READY',
      contentId: 'WS-G2-MATH-M214-sat-test',
      contentType: 'worksheet',
      grade: 2,
      targetLanguage: 'sat',
      content: {
        'content_id': 'WS-G2-MATH-M214-sat-test',
        'title': 'Numbers up to 100 (100 तक की संख्याएं)',
        'title_hi': '100 तक की संख्याएं',
        'grade': 2,
        'subject': 'Mathematics',
        'curriculum_id': 'M2.1.4',
        'target_language': 'sat',
        'difficulty': 'easy',
        'content_type': 'worksheet',
        'questions': [
          {
            'questionNumber': 1,
            'promptHindi': 'प्रश्न एक?',
            'promptTribal': '[sat] प्रश्न एक?',
            'visualIllustration': '',
            'options': ['1', '2'],
            'answer': '1',
          }
        ],
      },
    );
  }

  @override
  Future<GenerationJobModel> approveJob(
    String jobId, {
    String? santaliScriptConfirmed,
    String? notes,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<File> downloadAsset(String a, String b) async {
    throw UnimplementedError();
  }
}

void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('Worksheet request building (teacher selections, no hardcoding)', () {
    test('maps language, difficulty, type, and options', () {
      final req = buildWorksheetGenerationRequest(
        grade: 2,
        subject: 'Mathematics',
        topic: 'Numbers up to 100',
        nipunOutcome: 'M2.1.4',
        targetLanguage: TribalLanguage.santali,
        difficulty: DifficultyLevel.easy,
        type: WorksheetType.matching,
        questionCount: 10,
        visualSupport: true,
        bilingualAnswers: false,
        audioCue: true,
      );
      expect(req.grade, 2);
      expect(req.topic, 'Numbers up to 100');
      expect(req.nipunOutcome, 'M2.1.4');
      expect(req.targetLanguage, 'sat');
      expect(req.difficulty, 'easy');
      expect(req.worksheetType, 'matching');
      expect(req.questionCount, 10);
      expect(req.visualSupport, isTrue);
      expect(req.bilingualAnswers, isFalse);
      expect(req.audioCue, isTrue);
      expect(req.requestId, isNotNull);
      expect(req.idempotencyKey, req.requestId);

      final json = req.toJson();
      expect(json['target_language'], 'sat');
      expect(json['source_language'], 'hi');
      expect(json['origin'], 'online');
      expect(json['question_count'], 10);
    });

    test('tribal language codes: ho and mundari', () {
      expect(tribalLanguageToServerCode(TribalLanguage.ho), 'ho');
      expect(tribalLanguageToServerCode(TribalLanguage.mundari), 'unr');
      expect(serverCodeToTribalLanguage('unr'), TribalLanguage.mundari);
    });

    test('challenging maps to hard; no Sarvam keys in payload', () {
      final req = buildWorksheetGenerationRequest(
        grade: 2,
        subject: 'Mathematics',
        topic: 'T',
        nipunOutcome: 'M2.1.4',
        targetLanguage: TribalLanguage.ho,
        difficulty: DifficultyLevel.challenging,
        type: WorksheetType.practice,
        questionCount: 5,
        visualSupport: false,
        bilingualAnswers: true,
        audioCue: false,
      );
      expect(req.difficulty, 'hard');
      final raw = jsonEncode(req.toJson()).toLowerCase();
      expect(raw.contains('sarvam'), isFalse);
      expect(raw.contains('service_role'), isFalse);
      expect(raw.contains('api_key'), isFalse);
    });
  });

  group('Offline queue persistence', () {
    test('request stored as PENDING with full parameters', () async {
      final req = buildWorksheetGenerationRequest(
        grade: 2,
        subject: 'Mathematics',
        topic: 'Numbers up to 100',
        nipunOutcome: 'M2.1.4',
        targetLanguage: TribalLanguage.santali,
        difficulty: DifficultyLevel.easy,
        type: WorksheetType.practice,
        questionCount: 10,
        visualSupport: true,
        bilingualAnswers: true,
        audioCue: false,
        origin: 'offline',
      );
      final requestId = await queueWorksheetGenerationRequest(db, req);

      expect(await db.syncQueueDao.getPendingCount(), 1);
      final pending = await db.syncQueueDao.getPendingOperations();
      expect(pending.single.id, requestId);
      expect(pending.single.entityType, kWorksheetGenerationEntityType);
      expect(pending.single.status, 'PENDING');

      final stored = jsonDecode(pending.single.payload) as Map<String, dynamic>;
      expect(stored['topic'], 'Numbers up to 100');
      expect(stored['nipun_outcome'], 'M2.1.4');
      expect(stored['question_count'], 10);
      expect(stored['request_id'], requestId);
    });

    test('queued request survives a fresh read (restart-safe SQLite row)', () async {
      final req = buildWorksheetGenerationRequest(
        grade: 2,
        subject: 'Mathematics',
        topic: 'T',
        nipunOutcome: 'M2.1.4',
        targetLanguage: TribalLanguage.ho,
        difficulty: DifficultyLevel.medium,
        type: WorksheetType.counting,
        questionCount: 5,
        visualSupport: false,
        bilingualAnswers: true,
        audioCue: false,
        origin: 'offline',
      );
      await queueWorksheetGenerationRequest(db, req);
      final all = await db.syncQueueDao.getAllQueueItems();
      expect(all.length, 1);
      expect(all.single.status, 'PENDING');
    });
  });

  group('Post-sync completion', () {
    test('completed result saved once; replay does not duplicate', () async {
      final completion = WorksheetGenerationCompletion(
        db: db,
        contentDataSource: FakeContentSource(),
      );
      final now = DateTime.now();
      final op = SyncQueueData(
        id: 'op-1',
        entityType: kWorksheetGenerationEntityType,
        entityId: 'req-1',
        operation: 'CREATE',
        payload: '{}',
        createdAt: now,
        updatedAt: now,
        retryCount: 0,
        lastAttemptAt: null,
        status: 'SYNCING',
        errorMessage: null,
      );
      final result = {
        'status': 'SUCCESS',
        'data': {
          'content_id': 'WS-G2-MATH-M214-sat-test',
          'status': 'READY',
          'content': (await FakeContentSource()
                  .getJobStatus('job-1'))
              .content,
        },
      };

      final first = await completion.completeFromSyncResult(op, result);
      expect(first, ['WS-G2-MATH-M214-sat-test']);
      final second = await completion.completeFromSyncResult(op, result);
      expect(second, ['WS-G2-MATH-M214-sat-test']);

      final materials = await db.resourceDao.getSavedMaterials(type: 'worksheet');
      expect(materials.length, 1);
      expect(materials.single.language, 'sat');
      expect(materials.single.outcomeCode, 'M2.1.4');
    });

    test('completeFromJob fetches and saves; null content is ignored', () async {
      final completion = WorksheetGenerationCompletion(
        db: db,
        contentDataSource: FakeContentSource(),
      );
      final saved = await completion.completeFromJob('job-1');
      expect(saved, 'WS-G2-MATH-M214-sat-test');
      expect(await db.resourceDao.getSavedMaterialsCount(), 1);
    });
  });

  group('Preview mapping', () {
    test('server payload maps to preview item without empty questions', () async {
      final content =
          (await FakeContentSource().getJobStatus('job-1')).content!;
      final item = worksheetItemFromGenerationPayload(content);
      expect(item.questions.length, 1);
      expect(item.questions.single.promptHindi, 'प्रश्न एक?');
      expect(item.questions.single.promptTribal, '[sat] प्रश्न एक?');
      expect(item.outcomeCode, 'M2.1.4');
      expect(item.targetLanguage, TribalLanguage.santali);
    });
  });

  group('Sync plumbing', () {
    test('mock remote WithResult default returns null without throwing', () async {
      final remote = MockRemoteDataSource();
      final now = DateTime.now();
      final op = SyncQueueData(
        id: 'op-x',
        entityType: 'lesson',
        entityId: 'e',
        operation: 'CREATE',
        payload: '{}',
        createdAt: now,
        updatedAt: now,
        retryCount: 0,
        lastAttemptAt: null,
        status: 'PENDING',
        errorMessage: null,
      );
      await expectLater(remote.pushSyncOperationWithResult(op), completion(isNull));
    });
  });
}
