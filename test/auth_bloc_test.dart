import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:maatribhasha/core/api/authenticated_api_client.dart';
import 'package:maatribhasha/core/auth/domain/repositories/auth_repository.dart';
import 'package:maatribhasha/core/auth/presentation/bloc/auth_bloc.dart';

class MockAuthRepository implements AuthRepository {
  bool _isAuthenticated = false;
  String? _token;
  AuthUser? _user;
  final _controller = StreamController<bool>.broadcast();
  int refreshCallCount = 0;
  int signOutCallCount = 0;

  /// When true, refreshToken() simulates a dead Supabase session (null).
  bool failRefresh = false;

  void setAuthenticated({required String token, required AuthUser user}) {
    _isAuthenticated = true;
    _token = token;
    _user = user;
    _controller.add(true);
  }

  void setUnauthenticated() {
    _isAuthenticated = false;
    _token = null;
    _user = null;
    _controller.add(false);
  }

  @override
  Stream<bool> get authStateChanges => _controller.stream;

  @override
  AuthUser? get currentUser => _user;

  @override
  String? get currentUserEmail => _user?.email;

  @override
  String? get currentUserId => _user?.id;

  @override
  AuthMode get authMode => _isAuthenticated ? AuthMode.dev : AuthMode.offline;

  @override
  Future<String?> currentAccessToken() async => _token;

  @override
  Future<String?> getAccessToken() async => _token;

  @override
  Future<void> initialize() async {}

  @override
  bool get isAuthenticated => _isAuthenticated;

  @override
  Future<String?> refreshToken() async {
    refreshCallCount++;
    if (failRefresh) return null;
    if (_isAuthenticated) {
      _token = 'refreshed_token_$refreshCallCount';
      return _token;
    }
    return null;
  }

  bool _rememberMe = true;

  @override
  Future<bool> getRememberMe() async => _rememberMe;

  @override
  Future<void> setRememberMe(bool value) async {
    _rememberMe = value;
  }

  @override
  Future<bool> checkUsernameAvailable(String username) async => true;

  @override
  Future<bool> registerTeacherProfile({
    required String userId,
    required String username,
    required String name,
    required String email,
  }) async => true;

  @override
  Future<AuthSessionResult> signInWithEmail({
    required String email,
    required String password,
    bool rememberMe = false,
    String? schoolName,
  }) async {
    _rememberMe = rememberMe;
    if (email == 'teacher@test.com' && password == 'password123') {
      _isAuthenticated = true;
      _token = 'valid_mock_jwt';
      _user = const AuthUser(
        id: 'usr-1',
        email: 'teacher@test.com',
        role: 'teacher',
      );
      _controller.add(true);
      return AuthSessionResult.success(user: _user, accessToken: _token);
    }
    return const AuthSessionResult.failure('Invalid email or password');
  }

  @override
  Future<AuthSessionResult> signUpWithEmail({
    required String email,
    required String password,
    Map<String, dynamic>? data,
  }) async {
    _isAuthenticated = true;
    _token = 'new_user_token';
    _user = AuthUser(
      id: 'usr-2',
      email: email,
      role: 'teacher',
    );
    _controller.add(true);
    return AuthSessionResult.success(user: _user, accessToken: _token);
  }

  @override
  Future<AuthSessionResult> sendOtp({required String identifier}) async {
    if (identifier == 'unknown') {
      return const AuthSessionResult.failure('Teacher code not found. Please check your details.');
    }
    return AuthSessionResult.success(
      user: AuthUser(
        id: 'usr-1',
        email: identifier.contains('@') ? identifier : '$identifier@test.com',
        username: identifier,
        role: 'teacher',
        metadata: const {'email_hint': 't***@test.com'},
      ),
      accessToken: 'otp-sent',
    );
  }

  @override
  Future<AuthSessionResult> verifyOtp({
    required String identifier,
    required String otp,
    bool rememberMe = false,
  }) async {
    _rememberMe = rememberMe;
    if (otp == '123456') {
      _isAuthenticated = true;
      _token = 'valid_otp_jwt';
      _user = AuthUser(
        id: 'usr-1',
        email: identifier.contains('@') ? identifier : '$identifier@test.com',
        username: identifier,
        role: 'teacher',
      );
      _controller.add(true);
      return AuthSessionResult.success(user: _user, accessToken: _token);
    }
    if (otp == '999999') {
      return const AuthSessionResult.failure('OTP has expired. Please request a new code.');
    }
    return const AuthSessionResult.failure('Invalid OTP code. Please check and try again.');
  }

  @override
  Future<void> signOut() async {
    signOutCallCount++;
    setUnauthenticated();
  }

  void dispose() {
    _controller.close();
  }
}

void main() {
  group('AuthBloc Unit Tests', () {
    late MockAuthRepository authRepo;
    late AuthBloc authBloc;

    setUp(() {
      authRepo = MockAuthRepository();
      authBloc = AuthBloc(authRepository: authRepo);
    });

    tearDown(() {
      authBloc.close();
      authRepo.dispose();
    });

    test('Initial state is AuthInitial', () {
      expect(authBloc.state, isA<AuthInitial>());
    });

    test('AuthInitializeEvent emits Unauthenticated when no session exists', () async {
      authRepo.setUnauthenticated();
      authBloc.add(const AuthInitializeEvent());

      await expectLater(
        authBloc.stream,
        emitsInOrder([
          isA<AuthLoading>(),
          isA<Unauthenticated>(),
        ]),
      );
    });

    test('AuthInitializeEvent emits Authenticated when valid session exists', () async {
      authRepo.setAuthenticated(
        token: 'active_token',
        user: const AuthUser(id: 'u1', email: 'test@sih.gov.in'),
      );
      authBloc.add(const AuthInitializeEvent());

      await expectLater(
        authBloc.stream,
        emitsInOrder([
          isA<AuthLoading>(),
          predicate<AuthState>((s) =>
              s is Authenticated &&
              s.user.email == 'test@sih.gov.in' &&
              s.accessToken == 'active_token'),
        ]),
      );
    });

    test('AuthSignInEvent emits Authenticated on valid credentials', () async {
      authBloc.add(const AuthSignInEvent(
        email: 'teacher@test.com',
        password: 'password123',
      ));

      await expectLater(
        authBloc.stream,
        emitsInOrder([
          isA<AuthLoading>(),
          predicate<AuthState>((s) =>
              s is Authenticated &&
              s.user.email == 'teacher@test.com' &&
              s.accessToken == 'valid_mock_jwt'),
        ]),
      );
    });

    test('AuthSignInEvent emits AuthError on invalid credentials', () async {
      authBloc.add(const AuthSignInEvent(
        email: 'wrong@test.com',
        password: 'wrongpassword',
      ));

      await expectLater(
        authBloc.stream,
        emitsInOrder([
          isA<AuthLoading>(),
          predicate<AuthState>((s) =>
              s is AuthError && s.message.contains('Invalid email')),
        ]),
      );
    });
    test('AuthSendOtpEvent emits AuthOtpSentState on valid teacher code', () async {
      authBloc.add(const AuthSendOtpEvent(
        identifier: 'jh_teacher_01',
        rememberMe: true,
      ));

      await expectLater(
        authBloc.stream,
        emitsInOrder([
          isA<AuthLoading>(),
          predicate<AuthState>((s) =>
              s is AuthOtpSentState &&
              s.identifier == 'jh_teacher_01' &&
              s.emailHint.contains('t***@') &&
              s.rememberMe == true),
        ]),
      );
    });

    test('AuthSendOtpEvent emits AuthError on unknown teacher code', () async {
      authBloc.add(const AuthSendOtpEvent(
        identifier: 'unknown',
      ));

      await expectLater(
        authBloc.stream,
        emitsInOrder([
          isA<AuthLoading>(),
          predicate<AuthState>((s) =>
              s is AuthError && s.message.contains('Teacher code not found')),
        ]),
      );
    });

    test('AuthVerifyOtpEvent emits Authenticated on valid OTP', () async {
      authBloc.add(const AuthVerifyOtpEvent(
        identifier: 'jh_teacher_01',
        otp: '123456',
        rememberMe: true,
      ));

      await expectLater(
        authBloc.stream,
        emitsInOrder([
          isA<AuthLoading>(),
          predicate<AuthState>((s) =>
              s is Authenticated &&
              s.user.username == 'jh_teacher_01' &&
              s.accessToken == 'valid_otp_jwt'),
        ]),
      );
    });

    test('AuthVerifyOtpEvent emits AuthError on invalid or expired OTP', () async {
      authBloc.add(const AuthVerifyOtpEvent(
        identifier: 'jh_teacher_01',
        otp: '999999',
      ));

      await expectLater(
        authBloc.stream,
        emitsInOrder([
          isA<AuthLoading>(),
          predicate<AuthState>((s) =>
              s is AuthError && s.message.contains('expired')),
        ]),
      );
    });

    test('AuthResetLoginEvent resets state to AuthInitial', () async {
      authBloc.add(const AuthResetLoginEvent());
      await expectLater(
        authBloc.stream,
        emitsInOrder([
          isA<AuthInitial>(),
        ]),
      );
    });

    test('AuthSignOutEvent emits Unauthenticated', () async {
      authRepo.setAuthenticated(
        token: 'token',
        user: const AuthUser(id: 'u1', email: 'teacher@test.com'),
      );
      authBloc.add(const AuthSignOutEvent());

      await expectLater(
        authBloc.stream,
        emitsInOrder([
          isA<AuthLoading>(),
          isA<Unauthenticated>(),
        ]),
      );
      expect(authRepo.signOutCallCount, 1);
    });

    test('AuthSessionRefreshedEvent preserves authenticated state if token valid', () async {
      authRepo.setAuthenticated(
        token: 'old_token',
        user: const AuthUser(id: 'u1', email: 'teacher@test.com'),
      );
      authBloc.add(const AuthSessionRefreshedEvent());

      await expectLater(
        authBloc.stream,
        emitsInOrder([
          predicate<AuthState>((s) =>
              s is Authenticated && s.accessToken == 'refreshed_token_1'),
        ]),
      );
      expect(authRepo.refreshCallCount, 1);
    });
  });

  group('AuthenticatedApiClient Unit Tests', () {
    late MockAuthRepository authRepo;

    setUp(() {
      authRepo = MockAuthRepository();
    });

    tearDown(() {
      authRepo.dispose();
    });

    test('Throws AuthenticationRequiredException when unauthenticated without sending request', () async {
      authRepo.setUnauthenticated();

      int requestsSent = 0;
      final mockHttpClient = MockClient((request) async {
        requestsSent++;
        return http.Response(jsonEncode({'status': 'ok'}), 200);
      });

      final client = AuthenticatedApiClient(
        authRepository: authRepo,
        client: mockHttpClient,
      );

      expect(
        () => client.get(Uri.parse('https://api.test/api/v1/worksheets/generate')),
        throwsA(isA<AuthenticationRequiredException>()),
      );
      expect(requestsSent, 0);
    });

    test('Attaches Authorization header with Bearer token', () async {
      authRepo.setAuthenticated(
        token: 'my_access_token',
        user: const AuthUser(id: 'u1', email: 'test@sih.gov.in'),
      );

      String? capturedHeader;
      final mockHttpClient = MockClient((request) async {
        capturedHeader = request.headers['Authorization'];
        return http.Response(jsonEncode({'status': 'ok'}), 200);
      });

      final client = AuthenticatedApiClient(
        authRepository: authRepo,
        client: mockHttpClient,
      );

      final res = await client.get(Uri.parse('https://api.test/api/v1/me'));
      expect(res.statusCode, 200);
      expect(capturedHeader, 'Bearer my_access_token');
    });

    test('401 response refreshes token and retries request exactly once', () async {
      authRepo.setAuthenticated(
        token: 'expired_token',
        user: const AuthUser(id: 'u1', email: 'test@sih.gov.in'),
      );

      int requestCount = 0;
      final headersSeen = <String?>[];

      final mockHttpClient = MockClient((request) async {
        requestCount++;
        headersSeen.add(request.headers['Authorization']);
        if (requestCount == 1) {
          // First attempt returns 401
          return http.Response(jsonEncode({'detail': 'Token expired'}), 401);
        }
        // Second attempt with refreshed token succeeds
        return http.Response(jsonEncode({'status': 'refreshed_success'}), 200);
      });

      final client = AuthenticatedApiClient(
        authRepository: authRepo,
        client: mockHttpClient,
      );

      final res = await client.get(Uri.parse('https://api.test/api/v1/me'));
      expect(res.statusCode, 200);
      expect(requestCount, 2);
      expect(headersSeen[0], 'Bearer expired_token');
      expect(headersSeen[1], 'Bearer refreshed_token_1');
      expect(authRepo.refreshCallCount, 1);
      expect(authRepo.signOutCallCount, 0);
    });

    test('Repeated 401 after successful refresh keeps session and throws UnauthorizedException', () async {
      // Backend rejected a freshly refreshed Supabase token: backend-layer
      // outcome, NOT an auth failure. The session must be preserved.
      authRepo.setAuthenticated(
        token: 'stale_token',
        user: const AuthUser(id: 'u1', email: 'test@sih.gov.in'),
      );

      int requestCount = 0;
      final mockHttpClient = MockClient((request) async {
        requestCount++;
        return http.Response(jsonEncode({'detail': 'Still Unauthorized'}), 401);
      });

      final client = AuthenticatedApiClient(
        authRepository: authRepo,
        client: mockHttpClient,
      );

      expect(
        () => client.get(Uri.parse('https://api.test/api/v1/me')),
        throwsA(isA<UnauthorizedException>()),
      );

      // Give event loop time to process
      await Future.delayed(const Duration(milliseconds: 50));
      expect(requestCount, 2); // exactly 1 retry
      expect(authRepo.signOutCallCount, 0);
      expect(authRepo.isAuthenticated, isTrue);
    });

    test('401 with failed Supabase refresh triggers signOut and throws SessionExpiredException', () async {
      authRepo.setAuthenticated(
        token: 'stale_token',
        user: const AuthUser(id: 'u1', email: 'test@sih.gov.in'),
      );
      authRepo.failRefresh = true;

      int requestCount = 0;
      final mockHttpClient = MockClient((request) async {
        requestCount++;
        return http.Response(jsonEncode({'detail': 'Token expired'}), 401);
      });

      final client = AuthenticatedApiClient(
        authRepository: authRepo,
        client: mockHttpClient,
      );

      expect(
        () => client.get(Uri.parse('https://api.test/api/v1/me')),
        throwsA(isA<SessionExpiredException>()),
      );

      await Future.delayed(const Duration(milliseconds: 50));
      expect(requestCount, 1); // no retry without a refreshed token
      expect(authRepo.signOutCallCount, 1);
    });

    test('Non-401 HTTP errors throw ApiException with exact status code without retrying', () async {
      authRepo.setAuthenticated(
        token: 'token',
        user: const AuthUser(id: 'u1', email: 'test@sih.gov.in'),
      );

      for (final code in [400, 403, 404, 422, 429, 500]) {
        int requestCount = 0;
        final mockHttpClient = MockClient((request) async {
          requestCount++;
          return http.Response(jsonEncode({'detail': 'Error $code'}), code);
        });

        final client = AuthenticatedApiClient(
          authRepository: authRepo,
          client: mockHttpClient,
        );

        try {
          await client.get(Uri.parse('https://api.test/api/v1/error'));
          fail('Should have thrown ApiException');
        } catch (e) {
          expect(e, isA<ApiException>());
          final apiEx = e as ApiException;
          expect(apiEx.statusCode, code);
        }

        expect(requestCount, 1); // No retry for non-401
      }
      expect(authRepo.signOutCallCount, 0); // Never signed out on 400/403/422/etc.
    });
  });
}
