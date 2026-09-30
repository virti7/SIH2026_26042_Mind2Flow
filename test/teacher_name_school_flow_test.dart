import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:maatribhasha/app/di/injection.dart';
import 'package:maatribhasha/app/router/route_names.dart';
import 'package:maatribhasha/core/auth/data/backend_profile_service.dart';
import 'package:maatribhasha/core/auth/domain/repositories/auth_repository.dart';
import 'package:maatribhasha/core/auth/presentation/bloc/auth_bloc.dart';
import 'package:maatribhasha/core/auth/presentation/pages/signup_screen.dart';
import 'package:maatribhasha/core/domain/usecases/teacher_usecases.dart';
import 'package:maatribhasha/core/enums/app_enums.dart';
import 'package:maatribhasha/core/models/app_models.dart';
import 'package:maatribhasha/core/repositories/app_repositories.dart';
import 'package:maatribhasha/core/widgets/tablet_header.dart';
import 'package:maatribhasha/features/profile/presentation/bloc/teacher_profile_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Teacher Name + School Name flow (§19):
/// signup validation -> Supabase metadata -> server profile -> local Drift
/// -> reactive header, offline-capable, no fake names.
class _SchoolFakeAuthRepo implements AuthRepository {
  String scenario = 'success';
  Map<String, dynamic>? lastSignupData;
  bool _isAuth = false;
  AuthUser? _user;
  String? _token;
  final _controller = StreamController<bool>.broadcast();

  @override
  AuthMode get authMode => _isAuth ? AuthMode.supabase : AuthMode.offline;
  @override
  Stream<bool> get authStateChanges => _controller.stream;
  @override
  AuthUser? get currentUser => _user;
  @override
  String? get currentUserEmail => _user?.email;
  @override
  String? get currentUserId => _user?.id;
  @override
  bool get isAuthenticated => _isAuth;
  @override
  Future<String?> currentAccessToken() async => _token;
  @override
  Future<String?> getAccessToken() async => _token;
  @override
  Future<void> initialize() async {}
  @override
  Future<bool> getRememberMe() async => true;
  @override
  Future<void> setRememberMe(bool v) async {}
  @override
  Future<String?> refreshToken() async => _token;
  @override
  Future<bool> checkUsernameAvailable(String u) async => true;
  @override
  Future<bool> registerTeacherProfile({
    required String userId,
    required String username,
    required String name,
    required String email,
  }) async =>
      true;
  @override
  Future<AuthSessionResult> sendOtp({required String identifier}) async =>
      const AuthSessionResult.failure('nope');
  @override
  Future<AuthSessionResult> verifyOtp({
    required String identifier,
    required String otp,
    bool rememberMe = false,
  }) async =>
      const AuthSessionResult.failure('nope');

  AuthUser _makeUser(String email, {String? school}) => AuthUser(
        id: 'supabase-uid-7',
        email: email,
        role: 'teacher',
        metadata: {
          'name': 'Sunita Soren',
          if (school != null) 'school_name': school,
        },
      );

  @override
  Future<AuthSessionResult> signInWithEmail({
    required String email,
    required String password,
    bool rememberMe = false,
    String? schoolName,
  }) async {
    if (scenario == 'login_no_school') {
      _isAuth = true;
      _token = 'jwt';
      _user = const AuthUser(
        id: 'supabase-uid-7',
        email: 'old@school.edu.in',
        role: 'teacher',
        metadata: {'name': 'Old Teacher'},
      );
      _controller.add(true);
      return AuthSessionResult.success(user: _user, accessToken: _token);
    }
    _isAuth = true;
    _token = 'jwt';
    _user = _makeUser(email,
        school: scenario == 'login_with_school' ? 'GPS Bundu' : null);
    _controller.add(true);
    return AuthSessionResult.success(user: _user, accessToken: _token);
  }

  @override
  Future<AuthSessionResult> signUpWithEmail({
    required String email,
    required String password,
    Map<String, dynamic>? data,
  }) async {
    lastSignupData = data;
    _isAuth = true;
    _token = 'jwt-new';
    _user = AuthUser(
      id: 'supabase-uid-7',
      email: email,
      role: 'teacher',
      metadata: {
        'name': data?['name'] ?? '',
        'school_name': data?['school_name'] ?? '',
      },
    );
    _controller.add(true);
    return AuthSessionResult.success(user: _user, accessToken: _token);
  }

  @override
  Future<void> signOut() async {
    _isAuth = false;
    _user = null;
    _token = null;
    _controller.add(false);
  }

  void dispose() => _controller.close();
}

class _MemoryTeacherRepo implements TeacherRepository {
  TeacherProfile profile = const TeacherProfile(
    id: 'teacher_primary',
    name: '',
    school: '',
    district: '',
    state: 'Jharkhand',
    classesTaught: [1, 2, 3],
    teachingLanguage: 'Hindi',
    supportedClassroomLanguages: [],
    activeSessionLanguage: TribalLanguage.mundari,
  );

  @override
  Future<TeacherProfile> getProfile() async => profile;

  @override
  Future<void> updateProfile(TeacherProfile p) async => profile = p;

  @override
  Future<List<TribalLanguage>> getSelectedLanguages() async =>
      profile.supportedClassroomLanguages;

  @override
  Future<void> updateLanguages(List<TribalLanguage> l) async {
    profile = profile.copyWith(supportedClassroomLanguages: l);
  }
}

TeacherProfileBloc _profileBloc(_MemoryTeacherRepo repo) => TeacherProfileBloc(
      getTeacherProfileUseCase: GetTeacherProfileUseCase(repo),
      updateTeacherProfileUseCase: UpdateTeacherProfileUseCase(repo),
      updateClassroomLanguagesUseCase: UpdateClassroomLanguagesUseCase(repo),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  void wideViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  void tallViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  group('signup validation', () {
    testWidgets('1/2. name and school are required', (tester) async {
      tallViewport(tester);
      final repo = _SchoolFakeAuthRepo();
      final bloc = AuthBloc(authRepository: repo);
      addTearDown(bloc.close);
      addTearDown(repo.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<AuthBloc>.value(
            value: bloc,
            child: const SignUpScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
          find.widgetWithText(TextFormField, 'School Name (स्कूल का नाम)'),
          findsOneWidget);

      await tester.enterText(
          find.widgetWithText(TextFormField, 'Email Address (ईमेल)'),
          'a@school.edu.in');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Password (पासवर्ड)'),
          'secret123');
      await tester.enterText(
          find.widgetWithText(
              TextFormField, 'Confirm Password (पासवर्ड की पुष्टि करें)'),
          'secret123');
      await tester.tap(find.textContaining('Create Account (खाता बनाएं)'));
      await tester.pumpAndSettle();

      expect(find.text('Teacher name is required.'), findsOneWidget);
      expect(find.text('School name is required.'), findsOneWidget);
      expect(repo.isAuthenticated, isFalse);
    });

    testWidgets('3/5. invalid email and mismatch rejected', (tester) async {
      tallViewport(tester);
      final repo = _SchoolFakeAuthRepo();
      final bloc = AuthBloc(authRepository: repo);
      addTearDown(bloc.close);
      addTearDown(repo.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<AuthBloc>.value(
            value: bloc,
            child: const SignUpScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
          find.widgetWithText(TextFormField, 'Teacher Name (पूरा नाम)'),
          'Sunita Soren');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'School Name (स्कूल का नाम)'),
          'GPS Bundu');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Email Address (ईमेल)'),
          'not-an-email');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Password (पासवर्ड)'),
          'secret123');
      await tester.enterText(
          find.widgetWithText(
              TextFormField, 'Confirm Password (पासवर्ड की पुष्टि करें)'),
          'different');
      await tester.tap(find.textContaining('Create Account (खाता बनाएं)'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter a valid email address'), findsOneWidget);
      expect(find.text('Passwords do not match'), findsOneWidget);
      expect(repo.isAuthenticated, isFalse);
    });

    testWidgets('spaces-only school name rejected', (tester) async {
      tallViewport(tester);
      final repo = _SchoolFakeAuthRepo();
      final bloc = AuthBloc(authRepository: repo);
      addTearDown(bloc.close);
      addTearDown(repo.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<AuthBloc>.value(
            value: bloc,
            child: const SignUpScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
          find.widgetWithText(TextFormField, 'School Name (स्कूल का नाम)'),
          '   ');
      await tester.tap(find.textContaining('Create Account (खाता बनाएं)'));
      await tester.pumpAndSettle();

      expect(find.text('School name is required.'), findsOneWidget);
      expect(repo.isAuthenticated, isFalse);
    });
  });

  group('signup data flow', () {
    testWidgets('6. successful signup passes school_name and lands Home',
        (tester) async {
      tallViewport(tester);
      final repo = _SchoolFakeAuthRepo();
      final teacherRepo = _MemoryTeacherRepo();
      final bloc =
          AuthBloc(authRepository: repo, teacherRepository: teacherRepo);
      final profileBloc = _profileBloc(teacherRepo);
      addTearDown(bloc.close);
      addTearDown(profileBloc.close);
      addTearDown(repo.dispose);

      final router = GoRouter(
        initialLocation: AppRoutes.signup,
        routes: [
          GoRoute(
            path: AppRoutes.signup,
            builder: (context, state) => MultiBlocProvider(
              providers: [
                BlocProvider<AuthBloc>.value(value: bloc),
                BlocProvider<TeacherProfileBloc>.value(value: profileBloc),
              ],
              child: const SignUpScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.home,
            builder: (context, state) =>
                const Scaffold(body: Text('Home Screen')),
          ),
          GoRoute(
            path: AppRoutes.teacherSetup,
            builder: (context, state) =>
                const Scaffold(body: Text('Setup Screen')),
          ),
        ],
      );
      await tester
          .pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      await tester.enterText(
          find.widgetWithText(TextFormField, 'Teacher Name (पूरा नाम)'),
          'Sunita Soren');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'School Name (स्कूल का नाम)'),
          'GPS Bundu');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Email Address (ईमेल)'),
          'sunita@school.edu.in');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Password (पासवर्ड)'),
          'secret123');
      await tester.enterText(
          find.widgetWithText(
              TextFormField, 'Confirm Password (पासवर्ड की पुष्टि करें)'),
          'secret123');
      await tester.tap(find.textContaining('Create Account (खाता बनाएं)'));
      await tester.pumpAndSettle();

      expect(repo.lastSignupData?['school_name'], 'GPS Bundu');
      expect(repo.lastSignupData?['name'], 'Sunita Soren');
      expect(repo.lastSignupData?['role'], 'teacher');
      // 9. persisted locally from the auth data.
      expect(teacherRepo.profile.name, 'Sunita Soren');
      expect(teacherRepo.profile.school, 'GPS Bundu');
      expect(find.text('Home Screen'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    test('11. login without school flags profile completion', () async {
      final repo = _SchoolFakeAuthRepo()..scenario = 'login_no_school';
      final teacherRepo = _MemoryTeacherRepo();
      final bloc =
          AuthBloc(authRepository: repo, teacherRepository: teacherRepo);
      bloc.add(const AuthSignInEvent(
          email: 'old@school.edu.in', password: 'secret123'));
      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<AuthLoading>(),
          isA<Authenticated>().having(
              (s) => s.profileNeedsCompletion, 'completion', isTrue),
        ]),
      );
      await bloc.close();
      repo.dispose();
    });

    test('login with school is complete', () async {
      final repo = _SchoolFakeAuthRepo()..scenario = 'login_with_school';
      final teacherRepo = _MemoryTeacherRepo();
      final bloc =
          AuthBloc(authRepository: repo, teacherRepository: teacherRepo);
      bloc.add(const AuthSignInEvent(
          email: 'a@school.edu.in', password: 'secret123'));
      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<AuthLoading>(),
          isA<Authenticated>().having(
              (s) => s.profileNeedsCompletion, 'completion', isFalse),
        ]),
      );
      expect(teacherRepo.profile.school, 'GPS Bundu');
      await bloc.close();
      repo.dispose();
    });
  });

  group('server profile plumbing', () {
    test('provisioning sends school_name with the Supabase user id', () async {
      Map<String, dynamic>? registerBody;
      String? registerAuth;
      var meCalls = 0;
      final client = MockClient((request) async {
        if (request.url.path == '/api/v1/me') {
          meCalls++;
          return http.Response(
            meCalls == 1
                ? 'nf'
                : jsonEncode({'user_id': 'uid-7'}),
            meCalls == 1 ? 404 : 200,
          );
        }
        if (request.url.path == '/api/v1/auth/register-teacher') {
          registerBody = jsonDecode(request.body) as Map<String, dynamic>;
          registerAuth = request.headers['Authorization'];
          return http.Response(jsonEncode({'user_id': 'uid-7'}), 200);
        }
        return http.Response('nf', 404);
      });
      final service = BackendProfileService(
        httpClient: client,
        baseUrl: 'http://127.0.0.1:8000',
      );
      final outcome = await service.reconcileAfterAuth(
        accessToken: 'jwt',
        userId: 'uid-7',
        email: 's@school.edu.in',
        name: 'Sunita Soren',
        schoolName: 'GPS Bundu',
      );
      expect(outcome.ok, isTrue);
      expect(registerBody!['user_id'], 'uid-7');
      expect(registerBody!['school_name'], 'GPS Bundu');
      expect(registerBody!['name'], 'Sunita Soren');
      expect(registerAuth, 'Bearer jwt');
    });

    test('8. /me school_name reaches the outcome', () async {
      final client = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'user_id': 'uid-7',
            'teacher_name': 'Sunita Soren',
            'school_name': 'GPS Bundu',
          }),
          200,
        );
      });
      final service = BackendProfileService(
        httpClient: client,
        baseUrl: 'http://127.0.0.1:8000',
      );
      final outcome = await service.reconcileAfterAuth(
        accessToken: 'jwt',
        userId: 'uid-7',
        email: 's@school.edu.in',
        name: 'Sunita Soren',
        schoolName: 'GPS Bundu',
      );
      expect(outcome.ok, isTrue);
      expect(outcome.serverSchoolName, 'GPS Bundu');
    });

    test('7. correct Supabase user id used in provisioning', () async {
      String? seenUserId;
      var meCalls = 0;
      final client = MockClient((request) async {
        if (request.url.path == '/api/v1/me') {
          meCalls++;
          return http.Response(
            meCalls == 1
                ? 'nf'
                : jsonEncode({'user_id': 'supabase-uid-7'}),
            meCalls == 1 ? 404 : 200,
          );
        }
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        seenUserId = body['user_id'] as String?;
        expect(body['school_name'], 'GPS Bundu');
        return http.Response(jsonEncode({'user_id': 'supabase-uid-7'}), 200);
      });
      final service = BackendProfileService(
        httpClient: client,
        baseUrl: 'http://127.0.0.1:8000',
      );
      final outcome = await service.reconcileAfterAuth(
        accessToken: 'jwt',
        userId: 'supabase-uid-7',
        email: 's@school.edu.in',
        name: 'Sunita Soren',
        schoolName: 'GPS Bundu',
      );
      expect(outcome.ok, isTrue);
      expect(seenUserId, 'supabase-uid-7');
    });
  });

  group('header', () {
    testWidgets('13/14. shows actual name and school', (tester) async {
      wideViewport(tester);
      final teacherRepo = _MemoryTeacherRepo()
        ..profile = teacherRepoSeed('Sunita Soren', 'GPS Bundu');
      final profileBloc = _profileBloc(teacherRepo);
      profileBloc.add(LoadTeacherProfile());
      if (!getIt.isRegistered<TeacherRepository>()) {
        getIt.registerSingleton<TeacherRepository>(teacherRepo);
      }
      addTearDown(() async {
        await profileBloc.close();
        if (getIt.isRegistered<TeacherRepository>()) {
          await getIt.unregister<TeacherRepository>();
        }
      });
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<TeacherProfileBloc>.value(
            value: profileBloc,
            child: const Scaffold(body: TabletHeader()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sunita Soren'), findsOneWidget);
      expect(find.text('GPS Bundu'), findsOneWidget);
      expect(find.text('Sita'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('15. long names truncate without overflow', (tester) async {
      wideViewport(tester);
      final teacherRepo = _MemoryTeacherRepo()
        ..profile = teacherRepoSeed(
          'A Very Long Teacher Name That Keeps Going',
          'Government Primary School, Very Long Village Name, Block XYZ',
        );
      final profileBloc = _profileBloc(teacherRepo);
      profileBloc.add(LoadTeacherProfile());
      if (!getIt.isRegistered<TeacherRepository>()) {
        getIt.registerSingleton<TeacherRepository>(teacherRepo);
      }
      addTearDown(() async {
        await profileBloc.close();
        if (getIt.isRegistered<TeacherRepository>()) {
          await getIt.unregister<TeacherRepository>();
        }
      });
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<TeacherProfileBloc>.value(
            value: profileBloc,
            child: const Scaffold(body: TabletHeader()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.textContaining('Government Primary School'),
          findsOneWidget);
    });

    testWidgets('16/17. header updates after change; works offline from Drift',
        (tester) async {
      wideViewport(tester);
      final teacherRepo = _MemoryTeacherRepo()
        ..profile = teacherRepoSeed('Sunita Soren', 'GPS Bundu');
      final profileBloc = _profileBloc(teacherRepo);
      if (!getIt.isRegistered<TeacherRepository>()) {
        getIt.registerSingleton<TeacherRepository>(teacherRepo);
      }
      addTearDown(() async {
        await profileBloc.close();
        if (getIt.isRegistered<TeacherRepository>()) {
          await getIt.unregister<TeacherRepository>();
        }
      });
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<TeacherProfileBloc>.value(
            value: profileBloc,
            child: const Scaffold(body: TabletHeader()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Offline path (bloc untouched): local Drift values show.
      expect(find.text('Sunita Soren'), findsOneWidget);

      // Update path: central state refreshes the header immediately.
      profileBloc.add(UpdateTeacherProfileEvent(
        teacherRepoSeed('Birsa Munda', 'GMS Khunti'),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Birsa Munda'), findsOneWidget);
      expect(find.text('GMS Khunti'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

TeacherProfile teacherRepoSeed(String name, String school) => TeacherProfile(
      id: 'teacher_primary',
      name: name,
      school: school,
      district: 'Khunti',
      state: 'Jharkhand',
      classesTaught: const [1, 2, 3],
      teachingLanguage: 'Hindi',
      supportedClassroomLanguages: const [],
      activeSessionLanguage: TribalLanguage.mundari,
    );
