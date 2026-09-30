import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maatribhasha/core/database/app_database.dart';
import 'package:maatribhasha/core/enums/app_enums.dart';
import 'package:maatribhasha/core/network/connectivity_service.dart';
import 'package:maatribhasha/core/sync/remote_content_data_source.dart';
import 'package:maatribhasha/core/sync/worksheet_generation_sync.dart';
import 'package:maatribhasha/core/repositories/mock_repositories.dart';
import 'package:maatribhasha/features/resources/presentation/bloc/content_generation_bloc.dart';
import 'package:maatribhasha/features/resources/presentation/bloc/worksheet_bloc.dart';

class _Connectivity implements ConnectivityService {
  bool online;
  bool reachable;
  _Connectivity({this.online = true, this.reachable = true});

  @override
  Stream<bool> get connectivityStream => Stream.value(online);

  @override
  Future<bool> get isOnline async => online;

  @override
  Future<bool> checkBackendReachability({String? baseUrl, Duration? timeout}) async =>
      online && reachable;

  @override
  void simulateOnlineStatus(bool? override) {
    if (override != null) online = override;
  }
}

class _Remote implements RemoteContentDataSource {
  int requestCount = 0;
  TeacherGenerationRequestModel? lastRequest;
  String? lastIdempotency;
  bool failAuth = false;

  @override
  Future<GenerationJobModel> requestGeneration(
    TeacherGenerationRequestModel request, {
    String? idempotencyKey,
  }) async {
    requestCount++;
    lastRequest = request;
    lastIdempotency = idempotencyKey;
    if (failAuth) {
      throw HttpException('Generation request rejected with HTTP 401: Unauthorized', uri: Uri.parse('http://x'));
    }
    return GenerationJobModel(
      jobId: 'job_fix_verify',
      status: 'READY',
      contentId: 'WS-G2-MATH-M214-sat-fix',
      contentType: request.contentType,
      grade: request.grade,
      targetLanguage: request.targetLanguage,
      content: {
        'content_id': 'WS-G2-MATH-M214-sat-fix',
        'title': 'Numbers up to 100',
        'title_hi': '100 तक की संख्याएं',
        'grade': request.grade,
        'subject': request.subject,
        'curriculum_id': 'M2.1.4',
        'target_language': request.targetLanguage,
        'difficulty': request.difficulty,
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
  Future<GenerationJobModel> getJobStatus(String jobId) async {
    return GenerationJobModel(
      jobId: jobId,
      status: 'READY',
      contentId: 'WS-G2-MATH-M214-sat-fix',
      contentType: 'worksheet',
      grade: 2,
      targetLanguage: 'sat',
      content: {'content_id': 'WS-G2-MATH-M214-sat-fix', 'title': 'T'},
    );
  }

  @override
  Future<GenerationJobModel> approveJob(String jobId,
      {String? santaliScriptConfirmed, String? notes}) async {
    throw UnimplementedError();
  }

  @override
  Future<File> downloadAsset(String a, String b) async {
    final f = File('${Directory.systemTemp.path}/$b');
    await f.writeAsString('x');
    return f;
  }
}

TeacherGenerationRequestModel _teacherRequest() {
  return buildWorksheetGenerationRequest(
    grade: 2,
    subject: 'Mathematics',
    topic: 'Numbers up to 100',
    nipunOutcome: 'M2.1.4',
    targetLanguage: TribalLanguage.mundari,
    difficulty: DifficultyLevel.medium,
    type: WorksheetType.practice,
    questionCount: 5,
    visualSupport: true,
    bilingualAnswers: true,
    audioCue: true,
    deviceId: 'tablet_jharkhand_001',
    teacherId: 'teacher_1',
    origin: 'online',
  );
}

void main() {
  group('Fix verification: request carries teacher selections', () {
    test('1. selected values present incl ids', () {
      final req = _teacherRequest();
      expect(req.grade, 2);
      expect(req.subject, 'Mathematics');
      expect(req.topic, 'Numbers up to 100');
      expect(req.nipunOutcome, 'M2.1.4');
      expect(req.sourceLanguage, 'hi');
      expect(req.targetLanguage, 'unr');
      expect(req.worksheetType, 'practice');
      expect(req.questionCount, 5);
      expect(req.difficulty, 'medium');
      expect(req.visualSupport, isTrue);
      expect(req.bilingualAnswers, isTrue);
      expect(req.audioCue, isTrue);
      expect(req.requestId, isNotNull);
      expect(req.deviceId, 'tablet_jharkhand_001');
      expect(req.teacherId, 'teacher_1');
      final json = req.toJson();
      expect(json['teacher_id'], 'teacher_1');
      expect(json['device_id'], 'tablet_jharkhand_001');
      expect(json['request_id'], req.requestId);
    });

    test('language codes: ho/mundari custom, santali sat', () {
      expect(tribalLanguageToServerCode(TribalLanguage.ho), 'ho');
      expect(tribalLanguageToServerCode(TribalLanguage.mundari), 'unr');
      expect(tribalLanguageToServerCode(TribalLanguage.santali), 'sat');
    });

    test('payload exposes no provider secrets', () {
      final raw = jsonEncode(_teacherRequest().toJson()).toLowerCase();
      expect(raw.contains('sarvam'), isFalse);
      expect(raw.contains('api_key'), isFalse);
    });
  });

  group('Fix verification: online/offline bloc behavior', () {
    late AppDatabase db;
    setUp(() => db = AppDatabase(NativeDatabase.memory()));
    tearDown(() => db.close());

    test('2. online generate hits HTTP with selected values', () async {
      final remote = _Remote();
      final bloc = ContentGenerationBloc(
        remoteDataSource: remote,
        connectivityService: _Connectivity(online: true, reachable: true),
        database: db,
      );
      final req = _teacherRequest();
      bloc.add(StartContentGenerationEvent(request: req, idempotencyKey: req.requestId));
      await bloc.stream.firstWhere((s) => s is ContentGenerationSavedLocally);
      expect(remote.requestCount, 1);
      expect(remote.lastRequest!.topic, 'Numbers up to 100');
      expect(remote.lastIdempotency, req.requestId);
      await bloc.close();
    });

    test('3+4. offline generate queues PENDING and survives re-read', () async {
      final remote = _Remote();
      final bloc = ContentGenerationBloc(
        remoteDataSource: remote,
        connectivityService: _Connectivity(online: false, reachable: false),
        database: db,
      );
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
        bilingualAnswers: true,
        audioCue: false,
        origin: 'offline',
      );
      bloc.add(StartContentGenerationEvent(request: req, idempotencyKey: req.requestId));
      final queued = await bloc.stream.firstWhere((s) => s is ContentGenerationQueuedOffline);
      expect(remote.requestCount, 0);
      expect((queued as ContentGenerationQueuedOffline).requestId, isNotEmpty);
      expect(await db.syncQueueDao.getPendingCount(), 1);
      final pending = await db.syncQueueDao.getPendingOperations();
      expect(pending.single.entityType, kWorksheetGenerationEntityType);
      expect(pending.single.status, 'PENDING');
      // Restart-safe re-read.
      final reread = await db.syncQueueDao.getAllQueueItems();
      expect(reread.single.status, 'PENDING');
      await bloc.close();
    });

    test('9. backend unreachable queues instead of remote call', () async {
      final remote = _Remote();
      final bloc = ContentGenerationBloc(
        remoteDataSource: remote,
        connectivityService: _Connectivity(online: true, reachable: false),
        database: db,
      );
      final req = _teacherRequest();
      bloc.add(StartContentGenerationEvent(request: req, idempotencyKey: req.requestId));
      await bloc.stream.firstWhere((s) => s is ContentGenerationQueuedOffline);
      expect(remote.requestCount, 0);
      expect(await db.syncQueueDao.getPendingCount(), 1);
      await bloc.close();
    });

    test('6. completed server result stored locally', () async {
      final remote = _Remote();
      final bloc = ContentGenerationBloc(
        remoteDataSource: remote,
        connectivityService: _Connectivity(online: true, reachable: true),
        database: db,
      );
      final req = _teacherRequest();
      bloc.add(StartContentGenerationEvent(request: req, idempotencyKey: req.requestId));
      final saved = await bloc.stream.firstWhere((s) => s is ContentGenerationSavedLocally);
      final material = (saved as ContentGenerationSavedLocally).savedMaterial;
      final fromDb = await db.resourceDao.getSavedMaterialById(material.id);
      expect(fromDb, isNotNull);
      await bloc.close();
    });

    test('11. duplicate taps do not create duplicate jobs', () async {
      final remote = _Remote();
      final bloc = ContentGenerationBloc(
        remoteDataSource: remote,
        connectivityService: _Connectivity(online: true, reachable: true),
        database: db,
      );
      final req = _teacherRequest();
      bloc.add(StartContentGenerationEvent(request: req, idempotencyKey: req.requestId));
      bloc.add(StartContentGenerationEvent(request: req, idempotencyKey: req.requestId));
      await bloc.stream.firstWhere((s) => s is ContentGenerationSavedLocally);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(remote.requestCount, 1);
      await bloc.close();
    });

    test('auth error mapped to session message', () async {
      final remote = _Remote()..failAuth = true;
      final bloc = ContentGenerationBloc(
        remoteDataSource: remote,
        connectivityService: _Connectivity(online: true, reachable: true),
        database: db,
      );
      bloc.add(StartContentGenerationEvent(request: _teacherRequest()));
      final failed = await bloc.stream.firstWhere((s) => s is ContentGenerationFailed);
      expect((failed as ContentGenerationFailed).errorMessage.toLowerCase(), contains('session'));
      await bloc.close();
    });
  });

  group('Fix verification: preview + progress', () {
    late AppDatabase db;
    setUp(() => db = AppDatabase(NativeDatabase.memory()));
    tearDown(() => db.close());

    test('10. completed payload opens preview via WorksheetBloc', () async {
      final payload = {
        'content_id': 'WS-G2-MATH-M214-sat-fix',
        'title': 'Numbers up to 100',
        'title_hi': '100 तक की संख्याएं',
        'grade': 2,
        'subject': 'Mathematics',
        'curriculum_id': 'M2.1.4',
        'target_language': 'sat',
        'difficulty': 'medium',
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
      };
      final item = worksheetItemFromGenerationPayload(payload);
      expect(item.questions.length, 1);
      expect(item.questions.single.questionNumber, 1);
      // Feed into preview bloc the same way the dialog listener does.
      final wbloc = WorksheetBloc(resourceRepository: MockResourceRepository());
      wbloc.add(ShowGeneratedWorksheetEvent(item));
      final st = await wbloc.stream.firstWhere((s) => s is WorksheetGenerated);
      expect((st as WorksheetGenerated).worksheet.id, 'WS-G2-MATH-M214-sat-fix');
      await wbloc.close();
    });

    test('12. teacher progress derives worksheet_generated from storage', () async {
      await db.resourceDao.insertSavedMaterial(
        savedMaterialFromGenerationContent('WS-G2-MATH-M214-sat-fix', {
          'title': 'Numbers up to 100',
          'title_hi': '100 तक की संख्याएं',
          'grade': 2,
          'subject': 'Mathematics',
          'curriculum_id': 'M2.1.4',
          'target_language': 'sat',
          'difficulty': 'medium',
          'content_type': 'worksheet',
          'questions': [],
        }),
      );
      final materials = await db.resourceDao.getSavedMaterials(type: 'worksheet');
      expect(materials.length, 1);
      expect(materials.single.outcomeCode, 'M2.1.4');
      expect(materials.single.language, 'sat');
    });
  });

  group('Fix verification: production UI copy', () {
    test('7+8. no provider/model/debug text in teacher-facing UI', () async {
      final screen = File('lib/features/resources/presentation/pages/resource_screens.dart').readAsStringSync();
      final dialog = File('lib/features/resources/presentation/widgets/generation_progress_dialog.dart').readAsStringSync();
      final blocSrc = File('lib/features/resources/presentation/bloc/content_generation_bloc.dart').readAsStringSync();
      for (final src in [screen, dialog]) {
        expect(src.toLowerCase().contains('sarvam'), isFalse, reason: 'provider name in UI');
        expect(src.contains('10-B'), isFalse, reason: 'model label in UI');
        expect(src.toLowerCase().contains('token'), isFalse, reason: 'token label in UI');
      }
      // Button shows only the teacher-facing action.
      expect(screen.contains('Generate Bilingual Worksheet'), isTrue);
      expect(screen.contains('Generate Worksheet (Sarvam'), isFalse);
      // Bloc user-facing messages expose no provider internals.
      expect(blocSrc.contains('Sarvam-105B'), isFalse);
      // Banned red snackbar text is gone.
      expect(screen.contains('Generation requires an active internet connection to the server'), isFalse);
    });
  });
}
