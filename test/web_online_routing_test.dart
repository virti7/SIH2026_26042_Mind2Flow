import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:maatribhasha/core/config/api_config.dart';
import 'package:maatribhasha/core/database/app_database.dart';
import 'package:maatribhasha/core/enums/app_enums.dart';
import 'package:maatribhasha/core/network/connectivity_service.dart';
import 'package:maatribhasha/core/sync/browser_content_data_source.dart';
import 'package:maatribhasha/core/sync/worksheet_generation_queue.dart';
import 'package:maatribhasha/core/sync/worksheet_generation_sync.dart';
import 'package:maatribhasha/features/resources/presentation/bloc/content_generation_bloc.dart';

class _FakeConnectivity implements ConnectivityService {
  bool online;
  bool reachable;
  _FakeConnectivity({this.online = true, this.reachable = true});

  @override
  Stream<bool> get connectivityStream => Stream.value(online);

  @override
  Future<bool> get isOnline async => online;

  @override
  Future<bool> checkBackendReachability(
          {String? baseUrl, Duration? timeout}) async =>
      online && reachable;

  @override
  void simulateOnlineStatus(bool? override) {
    if (override != null) online = override;
  }
}

Map<String, dynamic> _readyJob(String base) => {
      'job_id': 'job_local_1',
      'status': 'READY',
      'content_id': 'WS-LOCAL-1',
      'content_type': 'worksheet',
      'grade': 2,
      'target_language': 'sat',
      'content': {
        'content_id': 'WS-LOCAL-1',
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
      },
    };

/// Minimal FastAPI stand-in: health, worksheet generation (202), job status.
Future<HttpServer> _startFakeBackend() async {
  final server =
      await HttpServer.bind(InternetAddress.loopbackIPv4, 0, shared: false);
  server.listen((HttpRequest req) async {
    try {
      final path = req.uri.path;
      if (req.method == 'GET' &&
          (path == '/api/v1/health' || path == '/health')) {
        req.response.statusCode = HttpStatus.ok;
        req.response.write(jsonEncode({'status': 'ok'}));
      } else if (req.method == 'POST' &&
          path == '/api/v1/worksheets/generate') {
        await utf8.decoder.bind(req).join(); // drain request body
        req.response.statusCode = HttpStatus.accepted;
        req.response.write(jsonEncode(
            _readyJob('http://127.0.0.1:${server.port}')));
      } else if (req.method == 'GET' &&
          path.startsWith('/api/v1/ai/jobs/')) {
        req.response.statusCode = HttpStatus.ok;
        req.response.write(jsonEncode(
            _readyJob('http://127.0.0.1:${server.port}')));
      } else {
        req.response.statusCode = HttpStatus.notFound;
        req.response.write('not found');
      }
    } catch (_) {
      req.response.statusCode = HttpStatus.internalServerError;
    } finally {
      await req.response.close();
    }
  });
  return server;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = null;

  group('WEB online routing (real HTTP, no mocks, no queue-first)', () {
    late HttpServer server;
    late String base;

    setUp(() async {
      server = await _startFakeBackend();
      base = 'http://127.0.0.1:${server.port}';
    });

    tearDown(() async {
      await server.close(force: true);
    });

    test('browser HTTP datasource POSTs generation and parses 202 job',
        () async {
      final ds = BrowserHttpRemoteContentDataSource(baseUrl: base);
      final job = await ds.requestGeneration(
        buildWorksheetGenerationRequest(
          grade: 2,
          subject: 'Mathematics',
          topic: 'Numbers up to 100',
          nipunOutcome: 'M2.1.4',
          targetLanguage: TribalLanguage.santali,
          difficulty: DifficultyLevel.medium,
          type: WorksheetType.practice,
          questionCount: 5,
          visualSupport: true,
          bilingualAnswers: true,
          audioCue: false,
          origin: 'online',
        ),
        idempotencyKey: 'web-online-1',
      );
      expect(job.isReady, isTrue);
      expect(job.contentId, 'WS-LOCAL-1');
      expect((job.content!['questions'] as List).length, 1);
    });

    test('browser HTTP datasource polls job status', () async {
      final ds = BrowserHttpRemoteContentDataSource(baseUrl: base);
      final job = await ds.getJobStatus('job_local_1');
      expect(job.isReady, isTrue);
    });

    test('browser datasource defaults to ApiConfig.baseUrl', () {
      expect(
        BrowserHttpRemoteContentDataSource().baseUrl,
        ApiConfig.baseUrl,
      );
    });

    test('real reachability probe: healthy backend is reachable', () async {
      final ok = await probeBackendReachability(
        client: http.Client(),
        candidateUrls: [base],
        timeout: const Duration(seconds: 5),
      );
      expect(ok, isTrue);
    });

    test('real reachability probe: closed port is unreachable', () async {
      final ok = await probeBackendReachability(
        client: http.Client(),
        candidateUrls: ['http://127.0.0.1:9'],
        timeout: const Duration(seconds: 5),
      );
      expect(ok, isFalse);
    });

    test('online + reachable generates immediately WITHOUT local queue',
        () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(() async => db.close());
      final ds = BrowserHttpRemoteContentDataSource(baseUrl: base);
      final bloc = ContentGenerationBloc(
        remoteDataSource: ds,
        connectivityService:
            _FakeConnectivity(online: true, reachable: true),
        database: db,
      );
      addTearDown(() async => bloc.close());

      final req = buildWorksheetGenerationRequest(
        grade: 2,
        subject: 'Mathematics',
        topic: 'Numbers up to 100',
        nipunOutcome: 'M2.1.4',
        targetLanguage: TribalLanguage.santali,
        difficulty: DifficultyLevel.medium,
        type: WorksheetType.practice,
        questionCount: 5,
        visualSupport: true,
        bilingualAnswers: true,
        audioCue: false,
        origin: 'online',
      );
      bloc.add(StartContentGenerationEvent(
        request: req,
        idempotencyKey: req.requestId,
      ));

      final saved = await bloc.stream.firstWhere(
        (s) => s is ContentGenerationSavedLocally,
      ) as ContentGenerationSavedLocally;
      expect(saved.savedMaterial.id, 'WS-LOCAL-1');
      // Proven: nothing was queued locally first.
      expect(await db.syncQueueDao.getPendingCount(), 0);
      final stored =
          await db.resourceDao.getSavedMaterialById('WS-LOCAL-1');
      expect(stored, isNotNull);
      expect(stored!.outcomeCode, 'M2.1.4');
    });

    test('online + backend unreachable falls back to the local queue',
        () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final queue = WebWorksheetGenerationQueue(prefs: prefs);
      final ds = BrowserHttpRemoteContentDataSource(
          baseUrl: 'http://127.0.0.1:9');
      final bloc = ContentGenerationBloc(
        remoteDataSource: ds,
        connectivityService:
            _FakeConnectivity(online: true, reachable: false),
        queueRepository: queue,
        worksheetStore: MemoryGeneratedWorksheetStore(),
      );
      addTearDown(() async => bloc.close());

      final req = buildWorksheetGenerationRequest(
        grade: 2,
        subject: 'Mathematics',
        topic: 'Numbers up to 100',
        nipunOutcome: 'M2.1.4',
        targetLanguage: TribalLanguage.santali,
        difficulty: DifficultyLevel.medium,
        type: WorksheetType.practice,
        questionCount: 5,
        visualSupport: true,
        bilingualAnswers: true,
        audioCue: false,
        origin: 'offline',
      );
      bloc.add(StartContentGenerationEvent(
        request: req,
        idempotencyKey: req.requestId,
      ));

      final queued = await bloc.stream.firstWhere(
        (s) => s is ContentGenerationQueuedOffline,
      ) as ContentGenerationQueuedOffline;
      expect(queued.requestId, isNotEmpty);
      expect(await queue.pendingCount(), 1);
    });
  });

  group('routing guards (no platform-based false offline)', () {
    test('web DI uses browser HTTP, never the mock content source',
        () async {
      final injection = File(
        'lib/app/di/injection.dart',
      ).readAsStringSync();
      expect(
        injection.contains('BrowserHttpRemoteContentDataSource'),
        isTrue,
      );
      expect(
        injection.contains('MockRemoteContentDataSource'),
        isFalse,
        reason: 'mock content source must not back production traffic',
      );
      expect(
        injection.contains('MockRemoteDataSource()'),
        isFalse,
        reason: 'mock sync source must be restricted to tests',
      );
    });

    test('no kIsWeb-gated offline/mock short-circuit in UI/bloc/queue',
        () async {
      for (final path in [
        'lib/features/resources/presentation/pages/resource_screens.dart',
        'lib/features/resources/presentation/bloc/content_generation_bloc.dart',
        'lib/core/sync/worksheet_generation_queue.dart',
      ]) {
        final src = File(path).readAsStringSync();
        // kIsWeb may appear only in safe diagnostics, never as a routing
        // condition into the offline queue or a mock data source.
        expect(src.contains('if (kIsWeb)'), isFalse, reason: path);
        expect(src.contains('MockRemote'), isFalse, reason: path);
      }
    });

    test('reachability uses browser-safe HTTP, not dart:io', () async {
      final src = File(
        'lib/core/network/connectivity_service.dart',
      ).readAsStringSync();
      expect(src.contains("import 'dart:io'"), isFalse);
      expect(src.contains('dart:io'), isFalse);
      expect(src.contains('package:http'), isTrue);
      expect(src.contains('probeBackendReachability'), isTrue);
    });
  });
}
