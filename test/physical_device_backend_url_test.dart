import 'dart:io';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:maatribhasha/core/config/api_config.dart';
import 'package:maatribhasha/core/database/app_database.dart';
import 'package:maatribhasha/core/network/connectivity_service.dart';
import 'package:maatribhasha/core/sync/remote_content_data_source.dart';
import 'package:maatribhasha/core/sync/worksheet_generation_queue.dart';
import 'package:maatribhasha/features/resources/presentation/bloc/content_generation_bloc.dart';

/// Physical-device backend URL selection:
/// `Platform.isAndroid`/`TargetPlatform.android` must NEVER imply the
/// emulator alias 10.0.2.2. Physical phones over `adb reverse` use
/// http://127.0.0.1:8000; the emulator alias is explicit-only.
void main() {
  group('ApiConfig resolution', () {
    test('default baseUrl is the physical-device loopback (no Android alias)',
        () {
      // Test builds carry no BACKEND_URL define, mirroring a plain build.
      expect(ApiConfig.isExplicitlyConfigured, isFalse);
      expect(ApiConfig.baseUrl, 'http://127.0.0.1:8000');
    });

    test('explicit BACKEND_URL always wins (production)', () {
      expect(
        ApiConfig.resolveBaseUrl(
            explicitBackendUrl: 'https://api.example.com'),
        'https://api.example.com',
      );
    });

    test('explicit emulator URL wins when supplied', () {
      expect(
        ApiConfig.resolveBaseUrl(explicitBackendUrl: 'http://10.0.2.2:8000'),
        'http://10.0.2.2:8000',
      );
    });

    test('explicit physical-device URL wins when supplied', () {
      expect(
        ApiConfig.resolveBaseUrl(explicitBackendUrl: 'http://127.0.0.1:8000/'),
        'http://127.0.0.1:8000',
      );
    });

    test('empty/blank explicit URL falls back to loopback default', () {
      expect(ApiConfig.resolveBaseUrl(explicitBackendUrl: ''),
          'http://127.0.0.1:8000');
      expect(ApiConfig.resolveBaseUrl(explicitBackendUrl: '   '),
          'http://127.0.0.1:8000');
    });

    test('Android platform does NOT map to 10.0.2.2 automatically', () {
      for (final platform in TargetPlatform.values) {
        expect(
          ApiConfig.resolveBaseUrl(explicitBackendUrl: '', platform: platform),
          'http://127.0.0.1:8000',
          reason: 'platform=$platform must not select the emulator alias',
        );
      }
    });
  });

  group('probeBackendReachability failover', () {
    test('falls over to the next candidate and succeeds', () async {
      final requested = <String>[];
      final client = MockClient((request) async {
        requested.add(request.url.host);
        if (request.url.host == '10.0.2.2') {
          throw http.ClientException('No route to host');
        }
        return http.Response('{"status":"ok"}', 200);
      });
      final ok = await probeBackendReachability(
        client: client,
        candidateUrls: ['http://10.0.2.2:8000', 'http://127.0.0.1:8000'],
        timeout: const Duration(seconds: 2),
      );
      expect(ok, isTrue);
      expect(requested, contains('127.0.0.1'));
    });

    test('all candidates failing reports unreachable', () async {
      final client = MockClient((request) async {
        throw http.ClientException('Connection refused');
      });
      final ok = await probeBackendReachability(
        client: client,
        candidateUrls: ['http://10.0.2.2:8000', 'http://127.0.0.1:8000'],
        timeout: const Duration(seconds: 2),
      );
      expect(ok, isFalse);
    });

    test('non-200 health responses do not count as reachable', () async {
      final client = MockClient((request) async {
        return http.Response('error', 500);
      });
      final ok = await probeBackendReachability(
        client: client,
        candidateUrls: ['http://127.0.0.1:8000'],
        timeout: const Duration(seconds: 2),
      );
      expect(ok, isFalse);
    });
  });

  group('worksheet generation online/offline branching', () {
    late AppDatabase db;
    late _CountingConnectivity connectivity;
    late _CountingRemoteContent remote;
    late NativeWorksheetGenerationQueue queue;
    late ContentGenerationBloc bloc;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      connectivity = _CountingConnectivity();
      remote = _CountingRemoteContent();
      queue = NativeWorksheetGenerationQueue(db);
      bloc = ContentGenerationBloc(
        remoteDataSource: remote,
        connectivityService: connectivity,
        database: db,
        queueRepository: queue,
        worksheetStore: NativeGeneratedWorksheetStore(db),
      );
    });

    tearDown(() async {
      await bloc.close();
      await db.close();
    });

    test('reachable backend reaches HTTP and does NOT queue', () async {
      connectivity.online = true;
      connectivity.backendReachable = true;

      bloc.add(StartContentGenerationEvent(
        request: const TeacherGenerationRequestModel(
          topic: 'physical-device-http-proof',
          targetLanguage: 'sat',
        ),
      ));

      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<ContentGenerationCheckingConnectivity>(),
          isA<ContentGenerationSubmitting>(),
          isA<ContentGenerationReviewRequired>(),
        ]),
      );
      expect(remote.requestGenerationCalls, 1);
      expect(await queue.pendingCount(), 0);
    });

    test('unreachable backend queues to SQLite and skips HTTP', () async {
      connectivity.online = true;
      connectivity.backendReachable = false;

      bloc.add(StartContentGenerationEvent(
        request: const TeacherGenerationRequestModel(
          topic: 'physical-device-queue-proof',
          targetLanguage: 'sat',
        ),
      ));

      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<ContentGenerationCheckingConnectivity>(),
          isA<ContentGenerationSubmitting>(),
          isA<ContentGenerationQueuedOffline>(),
        ]),
      );
      expect(remote.requestGenerationCalls, 0);
      expect(await queue.pendingCount(), 1);
    });
  });
}

class _CountingConnectivity implements ConnectivityService {
  bool online = true;
  bool backendReachable = true;

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

class _CountingRemoteContent implements RemoteContentDataSource {
  int requestGenerationCalls = 0;

  @override
  Future<GenerationJobModel> requestGeneration(
    TeacherGenerationRequestModel request, {
    String? idempotencyKey,
  }) async {
    requestGenerationCalls++;
    return GenerationJobModel(
      jobId: 'job_physical_1',
      status: 'REVIEW_REQUIRED',
      contentId: 'GC-G1-NUM-032-01-bi-v1',
      contentType: request.contentType,
      grade: request.grade,
      targetLanguage: request.targetLanguage,
      reviewGates: const {'santali': 'LANG_SAT_SCRIPT_UNCONFIRMED'},
      content: const {'content_id': 'GC-G1-NUM-032-01-bi-v1'},
    );
  }

  @override
  Future<GenerationJobModel> getJobStatus(String jobId) async {
    throw UnimplementedError();
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
  Future<File> downloadAsset(String assetUrlOrPath, String localFileName) async {
    throw UnimplementedError();
  }
}
