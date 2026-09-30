import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:maatribhasha/core/database/app_database.dart';
import 'package:maatribhasha/core/network/connectivity_service.dart';
import 'package:maatribhasha/core/sync/remote_content_data_source.dart';
import 'package:maatribhasha/features/resources/presentation/bloc/content_generation_bloc.dart';

class MockTestConnectivityService implements ConnectivityService {
  bool online;
  bool backendReachable;

  MockTestConnectivityService({
    this.online = true,
    this.backendReachable = true,
  });

  @override
  Stream<bool> get connectivityStream => Stream.value(online);

  @override
  Future<bool> get isOnline async => online;

  @override
  Future<bool> checkBackendReachability({String? baseUrl, Duration? timeout}) async =>
      online && backendReachable;

  @override
  void simulateOnlineStatus(bool? override) {
    if (override != null) online = override;
  }
}

class MockTestRemoteContentDataSource implements RemoteContentDataSource {
  bool failRequest = false;
  bool failDownload = false;
  String targetLanguage = 'sat';

  @override
  Future<GenerationJobModel> requestGeneration(
    TeacherGenerationRequestModel request, {
    String? idempotencyKey,
  }) async {
    if (failRequest) {
      throw Exception('Server 500 Internal Error');
    }
    return GenerationJobModel(
      jobId: 'job_test_123',
      status: request.targetLanguage == 'sat' ? 'REVIEW_REQUIRED' : 'READY',
      contentId: 'GC-G1-NUM-032-01-bi-v1',
      contentType: request.contentType,
      grade: request.grade,
      targetLanguage: request.targetLanguage,
      reviewGates: request.targetLanguage == 'sat'
          ? {'santali': 'LANG_SAT_SCRIPT_UNCONFIRMED'}
          : null,
      content: {
        'content_id': 'GC-G1-NUM-032-01-bi-v1',
        'title': 'Numbers up to 100',
        'grade': request.grade,
        'subject': request.subject,
        'target_language': request.targetLanguage,
      },
      assets: {
        'pdf': 'worksheets/GC-G1-NUM-032-01-bi-v1.pdf',
      },
    );
  }

  @override
  Future<GenerationJobModel> getJobStatus(String jobId) async {
    return GenerationJobModel(
      jobId: jobId,
      status: 'READY',
      contentId: 'GC-G1-NUM-032-01-bi-v1',
      contentType: 'worksheet',
      grade: 1,
      targetLanguage: 'sat',
      content: {
        'content_id': 'GC-G1-NUM-032-01-bi-v1',
        'title': 'Numbers up to 100',
      },
    );
  }

  @override
  Future<GenerationJobModel> approveJob(
    String jobId, {
    String? santaliScriptConfirmed,
    String? notes,
  }) async {
    return const GenerationJobModel(
      jobId: 'job_test_123',
      status: 'READY',
      contentId: 'GC-G1-NUM-032-01-bi-v1',
      contentType: 'worksheet',
      grade: 1,
      targetLanguage: 'sat',
      content: {
        'content_id': 'GC-G1-NUM-032-01-bi-v1',
        'title': 'Numbers up to 100',
      },
      assets: {
        'pdf': 'worksheets/GC-G1-NUM-032-01-bi-v1.pdf',
      },
    );
  }

  @override
  Future<File> downloadAsset(String assetUrlOrPath, String localFileName) async {
    if (failDownload) {
      throw Exception('Network timeout downloading asset');
    }
    final dir = Directory.systemTemp;
    final file = File('${dir.path}/$localFileName');
    await file.writeAsString('Test asset payload');
    return file;
  }
}

void main() {
  late AppDatabase db;
  late MockTestConnectivityService connectivity;
  late MockTestRemoteContentDataSource remote;
  late ContentGenerationBloc bloc;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    connectivity = MockTestConnectivityService();
    remote = MockTestRemoteContentDataSource();
    bloc = ContentGenerationBloc(
      remoteDataSource: remote,
      connectivityService: connectivity,
      database: db,
    );
  });

  tearDown(() async {
    await bloc.close();
    await db.close();
  });

  test('offline device queues request locally instead of failing', () async {
    connectivity.online = false;

    expectLater(
      bloc.stream,
      emitsInOrder([
        isA<ContentGenerationCheckingConnectivity>(),
        isA<ContentGenerationSubmitting>(),
        isA<ContentGenerationQueuedOffline>(),
      ]),
    );

    bloc.add(const StartContentGenerationEvent(
      request: TeacherGenerationRequestModel(),
    ));
  });

  test('backend unreachable queues request locally instead of failing', () async {
    connectivity.online = true;
    connectivity.backendReachable = false;

    expectLater(
      bloc.stream,
      emitsInOrder([
        isA<ContentGenerationCheckingConnectivity>(),
        isA<ContentGenerationSubmitting>(),
        isA<ContentGenerationQueuedOffline>(),
      ]),
    );

    bloc.add(const StartContentGenerationEvent(
      request: TeacherGenerationRequestModel(),
    ));
  });

  test('online teacher request with Santali enters review required state', () async {
    connectivity.online = true;
    connectivity.backendReachable = true;

    expectLater(
      bloc.stream,
      emitsInOrder([
        isA<ContentGenerationCheckingConnectivity>(),
        isA<ContentGenerationSubmitting>(),
        isA<ContentGenerationReviewRequired>().having(
          (s) => s.reviewGates.containsKey('santali'),
          'has santali gate',
          true,
        ),
      ]),
    );

    bloc.add(const StartContentGenerationEvent(
      request: TeacherGenerationRequestModel(targetLanguage: 'sat'),
    ));
  });

  test('approving review transitions to READY, downloads, and saves to SQLite', () async {
    connectivity.online = true;
    connectivity.backendReachable = true;

    expectLater(
      bloc.stream,
      emitsInOrder([
        isA<ContentGenerationInProgress>(),
        isA<ContentGenerationReady>(),
        isA<ContentGenerationDownloading>(),
        isA<ContentGenerationDownloading>(),
        isA<ContentGenerationSavedLocally>().having(
          (s) => s.savedMaterial.id,
          'material ID',
          'GC-G1-NUM-032-01-bi-v1',
        ),
      ]),
    );

    bloc.add(const ApproveContentReviewEvent(
      jobId: 'job_test_123',
      santaliScriptConfirmed: 'Olck',
    ));
  });

  test('saved material is persisted in SQLite and can be retrieved offline', () async {
    // Manually trigger download and save
    bloc.add(const DownloadAndSaveContentEvent(
      jobId: 'job_test_123',
      contentId: 'GC-G1-NUM-032-01-bi-v1',
      contentPayload: {
        'title': 'Offline Math Worksheet',
        'title_hi': 'ऑफलाइन गणित अभ्यास',
        'grade': 1,
        'subject': 'Mathematics',
        'target_language': 'sat',
      },
    ));

    await bloc.stream.firstWhere((s) => s is ContentGenerationSavedLocally);

    // Verify in database
    final saved = await db.resourceDao.getSavedMaterialById('GC-G1-NUM-032-01-bi-v1');
    expect(saved, isNotNull);
    expect(saved!.title, 'Offline Math Worksheet');
    expect(saved.type, 'worksheet');
  });

  test('generation failure handles error gracefully', () async {
    connectivity.online = true;
    connectivity.backendReachable = true;
    remote.failRequest = true;

    expectLater(
      bloc.stream,
      emitsInOrder([
        isA<ContentGenerationCheckingConnectivity>(),
        isA<ContentGenerationSubmitting>(),
        isA<ContentGenerationFailed>().having(
          (s) => s.isOfflineError,
          'isOfflineError',
          false,
        ),
      ]),
    );

    bloc.add(const StartContentGenerationEvent(
      request: TeacherGenerationRequestModel(),
    ));
  });
}
