import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:maatribhasha/app/router/route_names.dart';
import 'package:maatribhasha/core/auth/data/backend_profile_service.dart';
import 'package:maatribhasha/core/auth/data/repositories/supabase_auth_repository.dart'
    show
        isInvalidCredentialsMessage,
        isEmailNotConfirmedMessage,
        isEmailAlreadyRegisteredMessage;
import 'package:maatribhasha/core/auth/domain/repositories/auth_repository.dart';
import 'package:maatribhasha/core/auth/presentation/bloc/auth_bloc.dart';

/// BACKEND SEPARATION (§16 items 10-20):
/// Supabase Auth owns authentication. FastAPI is a separate cloud layer
/// used AFTER authentication and must never block login, sign the user
/// out, or route back to Login.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('BackendProfileService: /api/v1/me reconciliation', () {
    test('10. /me success after authentication yields ok', () async {
      String? authHeader;
      final client = MockClient((request) async {
        expect(request.url.path, '/api/v1/me');
        authHeader = request.headers['Authorization'];
        return http.Response(jsonEncode({'user_id': 'uid-1'}), 200);
      });
      final service = BackendProfileService(
        httpClient: client,
        baseUrl: 'http://127.0.0.1:8000',
      );
      final outcome = await service.reconcileAfterAuth(
        accessToken: 'supabase-jwt',
        userId: 'uid-1',
        email: 'teacher@school.edu.in',
        name: 'Teacher',
      );
      expect(outcome.ok, isTrue);
      expect(outcome.backendUnavailable, isFalse);
      expect(outcome.profileNeedsCompletion, isFalse);
      expect(outcome.notice, isNull);
      expect(authHeader, 'Bearer supabase-jwt');
    });

    test('15/16. /me 404 provisions once by Supabase user id, then /me 200',
        () async {
      final paths = <String>[];
      Map<String, dynamic>? registerBody;
      String? registerAuthHeader;
      var meCalls = 0;
      final client = MockClient((request) async {
        paths.add(request.url.path);
        if (request.url.path == '/api/v1/me') {
          meCalls++;
          // First read misses; the retry after provisioning hits.
          return http.Response(
            meCalls == 1 ? 'Not found' : jsonEncode({'user_id': 'uid-1'}),
            meCalls == 1 ? 404 : 200,
          );
        }
        if (request.url.path == '/api/v1/auth/register-teacher') {
          registerBody = jsonDecode(request.body) as Map<String, dynamic>;
          registerAuthHeader = request.headers['Authorization'];
          return http.Response(jsonEncode({'user_id': 'uid-1'}), 200);
        }
        return http.Response('Not Found', 404);
      });
      final service = BackendProfileService(
        httpClient: client,
        baseUrl: 'http://127.0.0.1:8000',
      );
      final outcome = await service.reconcileAfterAuth(
        accessToken: 'supabase-jwt',
        userId: 'uid-1',
        email: 'teacher@school.edu.in',
        name: 'Sunita Soren',
      );
      expect(outcome.ok, isTrue);
      // Canonical identity is auth.users.id — never a fake id — and the
      // Supabase JWT travels with the provisioning call.
      expect(registerBody!['user_id'], 'uid-1');
      expect(registerBody!['email'], 'teacher@school.edu.in');
      expect(registerBody!['name'], 'Sunita Soren');
      expect(registerAuthHeader, 'Bearer supabase-jwt');
      // No duplicate rows: exactly one creation attempt, then a /me retry.
      expect(
        paths.where((p) => p == '/api/v1/auth/register-teacher'),
        hasLength(1),
      );
      expect(
        paths.where((p) => p == '/api/v1/me'),
        hasLength(2),
      );
    });

    test('provisioned but /me retry still 404 marks profile completion',
        () async {
      final client = MockClient((request) async {
        if (request.url.path == '/api/v1/me') {
          return http.Response('Not found', 404);
        }
        if (request.url.path == '/api/v1/auth/register-teacher') {
          return http.Response(jsonEncode({'user_id': 'uid-1'}), 200);
        }
        return http.Response('Not Found', 404);
      });
      final service = BackendProfileService(
        httpClient: client,
        baseUrl: 'http://127.0.0.1:8000',
      );
      final outcome = await service.reconcileAfterAuth(
        accessToken: 'supabase-jwt',
        userId: 'uid-1',
        email: 'teacher@school.edu.in',
        name: 'Teacher',
      );
      expect(outcome.ok, isFalse);
      expect(outcome.profileNeedsCompletion, isTrue);
      expect(outcome.notice, 'Teacher profile needs to be completed.');
    });

    test('17. /me 404 + failed creation marks profile completion (keeps session)',
        () async {
      final client = MockClient((request) async {
        if (request.url.path == '/api/v1/me') {
          return http.Response('Not found', 404);
        }
        return http.Response('Server error', 500);
      });
      final service = BackendProfileService(
        httpClient: client,
        baseUrl: 'http://127.0.0.1:8000',
      );
      final outcome = await service.reconcileAfterAuth(
        accessToken: 'supabase-jwt',
        userId: 'uid-1',
        email: 'teacher@school.edu.in',
        name: 'Teacher',
      );
      expect(outcome.ok, isFalse);
      expect(outcome.profileNeedsCompletion, isTrue);
      expect(outcome.backendUnavailable, isFalse);
      expect(outcome.notice, 'Teacher profile needs to be completed.');
    });

    test('10/14. backend timeout yields unavailable with offline notice',
        () async {
      final client = MockClient((request) async {
        throw http.ClientException('Connection refused');
      });
      final service = BackendProfileService(
        httpClient: client,
        baseUrl: 'http://127.0.0.1:8000',
        timeout: const Duration(milliseconds: 50),
      );
      final outcome = await service.reconcileAfterAuth(
        accessToken: 'supabase-jwt',
        userId: 'uid-1',
        email: 'teacher@school.edu.in',
        name: 'Teacher',
      );
      expect(outcome.ok, isFalse);
      expect(outcome.backendUnavailable, isTrue);
      expect(
        outcome.notice,
        'Server unavailable. You are signed in and can continue offline.',
      );
    });

    test('12. /me 500 does not fail auth; reports backend unavailable',
        () async {
      final client = MockClient((request) async {
        return http.Response('Internal error', 500);
      });
      final service = BackendProfileService(
        httpClient: client,
        baseUrl: 'http://127.0.0.1:8000',
      );
      final outcome = await service.reconcileAfterAuth(
        accessToken: 'supabase-jwt',
        userId: 'uid-1',
        email: 'teacher@school.edu.in',
        name: 'Teacher',
      );
      expect(outcome.backendUnavailable, isTrue);
      expect(outcome.notice, contains('continue offline'));
    });

    test('username/dev endpoints are never touched during reconciliation',
        () async {
      final paths = <String>[];
      final client = MockClient((request) async {
        paths.add(request.url.path);
        return http.Response('Unavailable', 503);
      });
      final service = BackendProfileService(
        httpClient: client,
        baseUrl: 'http://127.0.0.1:8000',
      );
      await service.reconcileAfterAuth(
        accessToken: 'supabase-jwt',
        userId: 'uid-1',
        email: 'teacher@school.edu.in',
        name: 'Teacher',
      );
      for (final p in paths) {
        expect(p, isNot(contains('check-username')));
        expect(p, isNot(contains('resolve-identifier')));
        expect(p, isNot(contains('dev-token')));
      }
    });
  });

  group('error classification (auth vs backend failures)', () {
    test('wrong credentials stay "Invalid email or password"', () {
      expect(isInvalidCredentialsMessage('Invalid login credentials'), isTrue);
      expect(isInvalidCredentialsMessage('Email not confirmed'), isFalse);
    });

    test('email confirmation maps to verify-email message, not invalid login',
        () {
      expect(isEmailNotConfirmedMessage('Email not confirmed'), isTrue);
      expect(
        isInvalidCredentialsMessage('Email not confirmed'),
        isFalse,
        reason: 'confirmation state must never read as wrong password',
      );
    });

    test('existing email maps to already-exists message', () {
      expect(isEmailAlreadyRegisteredMessage('User already registered'), isTrue);
      expect(
          isEmailAlreadyRegisteredMessage(
              'An account with this email already exists'),
          isTrue);
      expect(isEmailAlreadyRegisteredMessage('Invalid login credentials'),
          isFalse);
    });
  });

  group('bloc: backend outcomes never become auth failures', () {
    test('11/13. success + backend down emits Authenticated with notice',
        () async {
      final repo = _SeparationFakeRepo()..scenario = 'backend_down';
      final bloc = AuthBloc(authRepository: repo);
      bloc.add(const AuthSignInEvent(
          email: 'teacher@school.edu.in', password: 'secret123'));
      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<AuthLoading>(),
          isA<Authenticated>().having(
            (s) => s.backendNotice,
            'backendNotice',
            'Server unavailable. You are signed in and can continue offline.',
          ),
        ]),
      );
      expect(repo.isAuthenticated, isTrue);
      await bloc.close();
    });

    test('7. signup without session asks for email verification', () async {
      final repo = _SeparationFakeRepo()..scenario = 'confirm_email';
      final bloc = AuthBloc(authRepository: repo);
      bloc.add(const AuthSignUpEvent(
        name: 'Sunita Soren',
        email: 'sunita@school.edu.in',
        password: 'secret123',
      ));
      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<AuthLoading>(),
          isA<Unauthenticated>().having(
            (s) => s.message,
            'message',
            'Account created. Please verify your email before signing in.',
          ),
        ]),
      );
      await bloc.close();
    });

    test('6. existing email signup reports already-exists', () async {
      final repo = _SeparationFakeRepo()..scenario = 'existing_email';
      final bloc = AuthBloc(authRepository: repo);
      bloc.add(const AuthSignUpEvent(
        name: 'Teacher',
        email: 'teacher@school.edu.in',
        password: 'secret123',
      ));
      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<AuthLoading>(),
          isA<AuthError>().having((s) => s.message, 'message',
              'An account with this email already exists.'),
        ]),
      );
      await bloc.close();
    });

    test('8/9. logout clears session and emits Unauthenticated', () async {
      final repo = _SeparationFakeRepo()..scenario = 'success';
      var bloc = AuthBloc(authRepository: repo);
      bloc.add(const AuthSignInEvent(
          email: 'teacher@school.edu.in', password: 'secret123'));
      await expectLater(
        bloc.stream,
        emitsInOrder([isA<AuthLoading>(), isA<Authenticated>()]),
      );
      await bloc.close();

      bloc = AuthBloc(authRepository: repo);
      bloc.add(const AuthSignOutEvent());
      await expectLater(
        bloc.stream,
        emitsInOrder([isA<AuthLoading>(), isA<Unauthenticated>()]),
      );
      expect(repo.isAuthenticated, isFalse);
      expect(repo.signOutCalls, 1);
      await bloc.close();
    });
  });

  group('routing on Supabase session (18/19/20)', () {
    testWidgets('20. valid session + unavailable backend still shows Home',
        (tester) async {
      final repo = _SeparationFakeRepo()..scenario = 'backend_down';
      // Authenticate first (backend down, session valid).
      final setupBloc = AuthBloc(authRepository: repo);
      setupBloc.add(const AuthSignInEvent(
          email: 'teacher@school.edu.in', password: 'secret123'));
      await expectLater(
        setupBloc.stream,
        emitsInOrder([isA<AuthLoading>(), isA<Authenticated>()]),
      );
      await setupBloc.close();
      expect(repo.isAuthenticated, isTrue);

      final authBloc = AuthBloc(authRepository: repo);
      final router = _routerFor(repo);
      await tester.pumpWidget(
        BlocProvider<AuthBloc>.value(
          value: authBloc,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Separation Home'), findsOneWidget);
      expect(find.textContaining('Teacher Login'), findsNothing);
    });

    testWidgets('19. no session shows Login', (tester) async {
      final repo = _SeparationFakeRepo();
      final authBloc = AuthBloc(authRepository: repo);
      final router = _routerFor(repo, initial: AppRoutes.login);
      await tester.pumpWidget(
        BlocProvider<AuthBloc>.value(
          value: authBloc,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Teacher Login'), findsOneWidget);
    });
  });
}

class _SeparationFakeRepo implements AuthRepository {
  String scenario = 'success';
  bool _isAuth = false;
  AuthUser? _user;
  String? _token;
  bool _rememberMe = false;
  int signOutCalls = 0;
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
  Future<bool> getRememberMe() async => _rememberMe;
  @override
  Future<void> setRememberMe(bool v) async => _rememberMe = v;
  @override
  Future<String?> refreshToken() async => _token;
  @override
  Future<bool> checkUsernameAvailable(String username) async => true;
  @override
  Future<bool> registerTeacherProfile({
    required String userId,
    required String username,
    required String name,
    required String email,
  }) async {
    // Canonical identity must be the Supabase user id — never a fake id.
    expect(userId, isNotEmpty);
    expect(userId, isNot('dev-teacher-001'));
    return true;
  }

  @override
  Future<AuthSessionResult> sendOtp({required String identifier}) async =>
      const AuthSessionResult.failure('OTP is not part of this flow.');

  @override
  Future<AuthSessionResult> verifyOtp({
    required String identifier,
    required String otp,
    bool rememberMe = false,
  }) async =>
      const AuthSessionResult.failure('OTP is not part of this flow.');

  void _authenticate(String email) {
    _isAuth = true;
    _token = 'supabase-jwt';
    _user = AuthUser(id: 'supabase-uid-1', email: email, role: 'teacher');
    _controller.add(true);
  }

  @override
  Future<AuthSessionResult> signInWithEmail({
    required String email,
    required String password,
    bool rememberMe = false,
    String? schoolName,
  }) async {
    if (scenario == 'wrong_password') {
      return const AuthSessionResult.failure('Invalid email or password');
    }
    _authenticate(email);
    _rememberMe = rememberMe;
    if (scenario == 'backend_down') {
      return AuthSessionResult.success(
        user: _user,
        accessToken: _token,
        backendUnavailable: true,
        backendNotice:
            'Server unavailable. You are signed in and can continue offline.',
      );
    }
    return AuthSessionResult.success(user: _user, accessToken: _token);
  }

  @override
  Future<AuthSessionResult> signUpWithEmail({
    required String email,
    required String password,
    Map<String, dynamic>? data,
  }) async {
    if (scenario == 'existing_email') {
      return const AuthSessionResult.failure(
        'An account with this email already exists.',
      );
    }
    final user = AuthUser(
      id: 'supabase-uid-new',
      email: email,
      role: 'teacher',
      metadata: {'name': data?['name'] ?? 'Teacher'},
    );
    if (scenario == 'confirm_email') {
      return AuthSessionResult.success(
        user: user,
        accessToken: null,
        infoMessage:
            'Account created. Please verify your email before signing in.',
      );
    }
    _authenticate(email);
    return AuthSessionResult.success(user: _user, accessToken: _token);
  }

  @override
  Future<void> signOut() async {
    signOutCalls++;
    _isAuth = false;
    _user = null;
    _token = null;
    _rememberMe = false;
    _controller.add(false);
  }
}

GoRouter _routerFor(_SeparationFakeRepo repo, {String initial = AppRoutes.login}) {
  return GoRouter(
    initialLocation: initial,
    redirect: (context, state) {
      final isAuth = repo.isAuthenticated;
      final loc = state.matchedLocation;
      final isAuthRoute = loc == AppRoutes.login || loc == AppRoutes.signup;
      if (isAuth && isAuthRoute) return AppRoutes.home;
      if (!isAuth &&
          !isAuthRoute &&
          loc != AppRoutes.splash &&
          loc != AppRoutes.onboarding) {
        return AppRoutes.login;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const Scaffold(
          body: Text('Teacher Login'),
        ),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const Scaffold(
          body: Text('Separation Home'),
        ),
      ),
    ],
  );
}
