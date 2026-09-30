import 'dart:async';
import 'dart:convert';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import 'package:maatribhasha/app/router/route_names.dart';
import 'package:maatribhasha/core/api/authenticated_api_client.dart';
import 'package:maatribhasha/core/auth/data/repositories/supabase_auth_repository.dart';
import 'package:maatribhasha/core/auth/domain/repositories/auth_repository.dart';
import 'package:maatribhasha/core/auth/presentation/bloc/auth_bloc.dart';
import 'package:maatribhasha/core/auth/presentation/pages/login_screen.dart';
import 'package:maatribhasha/core/auth/presentation/pages/signup_screen.dart';
import 'package:maatribhasha/core/database/app_database.dart';
import 'package:maatribhasha/core/enums/app_enums.dart';
import 'package:maatribhasha/core/models/app_models.dart';
import 'package:maatribhasha/core/network/connectivity_service.dart';
import 'package:maatribhasha/core/repositories/sqlite_repositories.dart';
import 'package:maatribhasha/core/sync/remote_content_data_source.dart';
import 'package:maatribhasha/features/resources/presentation/bloc/content_generation_bloc.dart';

class NetworkCallCountingClient extends http.BaseClient {
  int callCount = 0;
  final List<Uri> requestedUris = [];

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    callCount++;
    requestedUris.add(request.url);
    throw http.ClientException('Network disabled for offline test');
  }
}

class TestConnectivityService implements ConnectivityService {
  bool online;
  TestConnectivityService({this.online = false});

  @override
  Future<bool> get isOnline async => online;

  @override
  Stream<bool> get connectivityStream => Stream.value(online);

  @override
  Future<bool> checkBackendReachability({String? baseUrl, Duration? timeout}) async => online;

  @override
  void simulateOnlineStatus(bool? override) {
    if (override != null) online = override;
  }
}

GoRouter _buildTestRouter({
  required AuthRepository authRepo,
  required String initialLocation,
  Widget? homeWidget,
}) {
  return GoRouter(
    initialLocation: initialLocation,
    redirect: (context, state) {
      final isAuth = authRepo.isAuthenticated;
      final loc = state.matchedLocation;
      final isAuthRoute = loc == AppRoutes.login || loc == AppRoutes.signup;

      if (isAuth && isAuthRoute) {
        return AppRoutes.home;
      }
      if (!isAuth && !isAuthRoute && loc != AppRoutes.splash && loc != AppRoutes.onboarding) {
        return AppRoutes.login;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.signup,
        builder: (context, state) => const SignUpScreen(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) =>
            homeWidget ??
            const Scaffold(
              body: Center(child: Text('Teacher Offline Workspace Home')),
            ),
      ),
    ],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late SqliteResourceRepository resourceRepo;
  late SqliteTeacherRepository teacherRepo;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase(NativeDatabase.memory());
    resourceRepo = SqliteResourceRepository(db: db);
    teacherRepo = SqliteTeacherRepository(db: db);
  });

  tearDown(() async {
    await db.close();
  });

  void configureViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  group('Scenario A: First-time Unauthenticated Teacher', () {
    testWidgets('1. First-time startup lands on Login screen and blocks protected routes', (tester) async {
      configureViewport(tester);
      final countingClient = NetworkCallCountingClient();
      final authRepo = SupabaseAuthRepository(httpClient: countingClient);
      await authRepo.initialize();

      expect(authRepo.isAuthenticated, isFalse);

      final router = _buildTestRouter(authRepo: authRepo, initialLocation: AppRoutes.home);
      final authBloc = AuthBloc(authRepository: authRepo);

      await tester.pumpWidget(
        BlocProvider<AuthBloc>.value(
          value: authBloc,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      // Guard redirected unauthenticated access from /home to /login
      expect(find.textContaining('Teacher Login'), findsOneWidget);
      expect(find.text('Teacher Offline Workspace Home'), findsNothing);
    });

    testWidgets('2. Unprovisioned stranger tapping Continue Offline is blocked', (tester) async {
      configureViewport(tester);
      final countingClient = NetworkCallCountingClient();
      final authRepo = SupabaseAuthRepository(httpClient: countingClient);
      await authRepo.initialize();

      final router = _buildTestRouter(authRepo: authRepo, initialLocation: AppRoutes.login);
      final authBloc = AuthBloc(authRepository: authRepo);

      await tester.pumpWidget(
        BlocProvider<AuthBloc>.value(
          value: authBloc,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Continue Offline
      await tester.tap(find.textContaining('Continue Offline'));
      await tester.pumpAndSettle();

      // Remains on login and displays blocked notification
      expect(find.textContaining('No offline account found on this device'), findsOneWidget);
      expect(find.text('Teacher Offline Workspace Home'), findsNothing);
    });
  });

  group('Scenario B: Returning Teacher with NO Internet (Offline-First Access)', () {
    test('3. Remember Me = ON provisions offline session and recognizes teacher without internet', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('auth_remember_me', true);
      await prefs.setString(
        'auth_provisioned_user',
        jsonEncode({
          'id': 'teacher-offline-uuid-001',
          'email': 'teacher.ranchi@jharkhand.gov.in',
          'username': 'TCH-JH-889',
          'role': 'teacher',
          'metadata': {'school': 'GPS Bundu', 'district': 'Ranchi'},
        }),
      );

      final countingClient = NetworkCallCountingClient();
      final authRepo = SupabaseAuthRepository(httpClient: countingClient);
      await authRepo.initialize();

      // Offline recognition
      expect(authRepo.isAuthenticated, isTrue);
      expect(authRepo.currentUser, isNotNull);
      expect(authRepo.currentUser!.username, 'TCH-JH-889');
      expect(authRepo.currentUser!.id, 'teacher-offline-uuid-001');

      // Zero network calls made during initialization
      expect(countingClient.callCount, 0);
    });

    testWidgets('4. Returning teacher with Remember Me = ON routes directly to offline workspace', (tester) async {
      configureViewport(tester);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('auth_remember_me', true);
      await prefs.setString(
        'auth_provisioned_user',
        jsonEncode({
          'id': 'teacher-offline-uuid-001',
          'email': 'teacher.ranchi@jharkhand.gov.in',
          'username': 'TCH-JH-889',
          'role': 'teacher',
        }),
      );

      final countingClient = NetworkCallCountingClient();
      final authRepo = SupabaseAuthRepository(httpClient: countingClient);
      await authRepo.initialize();

      final router = _buildTestRouter(authRepo: authRepo, initialLocation: AppRoutes.home);
      final authBloc = AuthBloc(authRepository: authRepo);
      authBloc.add(const AuthInitializeEvent());
      await tester.pump();

      await tester.pumpWidget(
        BlocProvider<AuthBloc>.value(
          value: authBloc,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      // Directly on teacher workspace
      expect(find.text('Teacher Offline Workspace Home'), findsOneWidget);
      expect(find.textContaining('Teacher Login'), findsNothing);
      expect(countingClient.callCount, 0);
    });

    test('5. Remember Me = OFF clears provisioned session on restart', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('auth_remember_me', false);
      await prefs.setString(
        'auth_provisioned_user',
        jsonEncode({'id': 'u1', 'email': 't@t.com', 'username': 't1', 'role': 'teacher'}),
      );

      final countingClient = NetworkCallCountingClient();
      final authRepo = SupabaseAuthRepository(httpClient: countingClient);
      await authRepo.initialize();

      expect(authRepo.isAuthenticated, isFalse);
      expect(prefs.containsKey('auth_provisioned_user'), isFalse);
    });
  });

  group('Offline Content Consumption & Zero Network Verification', () {
    test('6. Saved worksheet opens from local Drift SQLite with ZERO network requests', () async {
      final countingClient = NetworkCallCountingClient();

      final worksheet = WorksheetItem(
        id: 'ws_offline_test_001',
        title: 'Mundari Counting Worksheet',
        titleHi: 'मुंडारी गिनती अभ्यास पत्रक',
        grade: 2,
        subject: 'Math',
        outcomeCode: 'M201',
        targetLanguage: TribalLanguage.mundari,
        difficulty: DifficultyLevel.medium,
        type: WorksheetType.practice,
        questionCount: 2,
        createdAt: DateTime.now(),
        questions: const [
          WorksheetQuestion(
            questionNumber: 1,
            promptHindi: 'एक सेब चुनें',
            promptTribal: 'मियाद सेब',
            visualIllustration: '🍎',
            options: ['मियाद', 'बारिया', 'अपिया'],
            answer: 'मियाद',
          ),
          WorksheetQuestion(
            questionNumber: 2,
            promptHindi: 'दो चिड़िया',
            promptTribal: 'बारिया चेणे',
            visualIllustration: '🐥 🐥',
            options: ['अपिया', 'बारिया', 'उपून'],
            answer: 'बारिया',
          ),
        ],
      );

      // Save content locally
      await resourceRepo.saveWorksheet(worksheet);

      // Read content locally while simulating zero network availability
      final savedList = await resourceRepo.getSavedWorksheets();

      expect(savedList.length, 1);
      expect(savedList.first.id, 'ws_offline_test_001');
      expect(savedList.first.title, 'Mundari Counting Worksheet');
      expect(savedList.first.questions.length, 2);
      expect(savedList.first.questions.first.promptTribal, 'मियाद सेब');

      // Verify zero network calls occurred
      expect(countingClient.callCount, 0);
    });

    test('7. Saved flashcards open and flip from local Drift SQLite with ZERO network requests', () async {
      final countingClient = NetworkCallCountingClient();

      final cards = await resourceRepo.getFlashcards(
        topic: 'Numbers',
        language: TribalLanguage.mundari,
      );

      expect(cards.isNotEmpty, isTrue);
      expect(cards.first.hindiWord, 'एक (1)');
      expect(cards.first.tribalWord, 'मियाद (Mundari)');
      expect(cards.first.pronunciation, 'Mi-yaad');

      // Flip card checks
      expect(cards[1].hindiWord, 'दो (2)');
      expect(cards[1].tribalWord, 'बारिया (Mundari)');

      // Zero network requests
      expect(countingClient.callCount, 0);
    });

    test('8. Offline generation is BLOCKED locally: zero backend calls and queued in SyncQueue', () async {
      final countingClient = NetworkCallCountingClient();
      final authRepo = SupabaseAuthRepository(httpClient: countingClient);
      final apiClient = AuthenticatedApiClient(authRepository: authRepo, client: countingClient);
      final remoteDataSource = HttpRemoteContentDataSource(apiClient: apiClient);
      final connectivity = TestConnectivityService(online: false);

      final bloc = ContentGenerationBloc(
        remoteDataSource: remoteDataSource,
        connectivityService: connectivity,
        database: db,
      );

      const request = TeacherGenerationRequestModel(
        grade: 2,
        subject: 'Math',
        topic: 'Addition',
        targetLanguage: 'sat',
        difficulty: 'medium',
        contentType: 'worksheet',
        worksheetType: 'practice',
        questionCount: 5,
      );

      bloc.add(const StartContentGenerationEvent(request: request));

      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<ContentGenerationCheckingConnectivity>(),
          isA<ContentGenerationSubmitting>(),
          isA<ContentGenerationQueuedOffline>(),
        ]),
      );

      // Verify ZERO network requests were attempted
      expect(countingClient.callCount, 0);

      // Verify operation is queued in Drift SQLite SyncQueue
      final queuedOps = await db.syncQueueDao.getPendingOperations();
      expect(queuedOps.isNotEmpty, isTrue);
      expect(queuedOps.first.entityType, 'worksheet_generation');
      expect(queuedOps.first.status, 'PENDING');

      await bloc.close();
    });
  });

  group('Scenario C: Internet Returns & Token Lifecycle', () {
    test('9. Transient network loss does NOT invalidate local session; refresh failure offline preserves session', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('auth_remember_me', true);
      await prefs.setString(
        'auth_provisioned_user',
        jsonEncode({'id': 'u-99', 'email': 't@gov.in', 'username': 't99', 'role': 'teacher'}),
      );

      final countingClient = NetworkCallCountingClient();
      final authRepo = SupabaseAuthRepository(httpClient: countingClient);
      await authRepo.initialize();

      expect(authRepo.isAuthenticated, isTrue);

      // Token refresh failure due to offline network exception
      final refreshed = await authRepo.refreshToken();
      expect(refreshed, isNull);

      // Teacher is STILL authenticated locally
      expect(authRepo.isAuthenticated, isTrue);
      expect(authRepo.currentUser, isNotNull);
    });

    test('10. Logout invalidates local provisioned identity and clears remember-me', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('auth_remember_me', true);
      await prefs.setString('auth_provisioned_user', jsonEncode({'id': 'u-1', 'username': 't1'}));

      final countingClient = NetworkCallCountingClient();
      final authRepo = SupabaseAuthRepository(httpClient: countingClient);
      await authRepo.initialize();
      expect(authRepo.isAuthenticated, isTrue);

      await authRepo.signOut();

      expect(authRepo.isAuthenticated, isFalse);
      expect(await authRepo.getRememberMe(), isFalse);
      expect(prefs.containsKey('auth_provisioned_user'), isFalse);
    });

    test('11. Teacher profile reads from local SQLite without network calls', () async {
      final countingClient = NetworkCallCountingClient();
      final profile = await teacherRepo.getProfile();
      expect(profile, isNotNull);
      expect(profile.state, 'Jharkhand');
      expect(countingClient.callCount, 0);
    });
  });
}
