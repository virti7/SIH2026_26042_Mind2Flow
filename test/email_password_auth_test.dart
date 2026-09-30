import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:maatribhasha/core/auth/data/repositories/supabase_auth_repository.dart'
    show isValidEmail, isNetworkError, isInvalidCredentialsMessage;
import 'package:maatribhasha/core/auth/domain/repositories/auth_repository.dart';
import 'package:maatribhasha/core/auth/presentation/bloc/auth_bloc.dart';

/// Scripted fake implementing the email + password contract that
/// SupabaseAuthRepository guarantees:
/// - invalid credentials -> 'Invalid email or password'
/// - transport failure   -> 'Unable to connect to authentication service. Check your internet connection.'
/// - backend down        -> success + backendUnavailable notice
///   ("Server unavailable. You are signed in and can continue offline.")
/// - missing profile     -> success + profileNeedsCompletion notice
///   ("Teacher profile needs to be completed.")
/// FastAPI outcomes NEVER fail the Supabase authentication.
class EmailFakeAuthRepository implements AuthRepository {
  bool _isAuth = false;
  AuthUser? _user;
  String? _token;
  bool _rememberMe = false;
  final _controller = StreamController<bool>.broadcast();

  /// Controls the next sign-in outcome.
  String signInScenario = 'success';

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
  Future<void> setRememberMe(bool value) async => _rememberMe = value;
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
  }) async => true;

  @override
  Future<AuthSessionResult> sendOtp({required String identifier}) async {
    if (!isValidEmail(identifier)) {
      return const AuthSessionResult.failure(
          'Please enter a valid email address.');
    }
    return AuthSessionResult.success(
      user: AuthUser(id: '', email: identifier, role: 'teacher'),
      accessToken: 'otp-sent',
    );
  }

  @override
  Future<AuthSessionResult> verifyOtp({
    required String identifier,
    required String otp,
    bool rememberMe = false,
  }) async =>
      const AuthSessionResult.failure('Invalid OTP code.');

  @override
  Future<AuthSessionResult> signInWithEmail({
    required String email,
    required String password,
    bool rememberMe = false,
    String? schoolName,
  }) async {
    if (!isValidEmail(email)) {
      return const AuthSessionResult.failure(
          'Please enter a valid email address.');
    }
    switch (signInScenario) {
      case 'wrong_password':
        return const AuthSessionResult.failure('Invalid email or password');
      case 'timeout':
        return const AuthSessionResult.failure(
          'Unable to connect to authentication service. Check your internet connection.',
        );
      case 'backend_down':
        _isAuth = true;
        _rememberMe = rememberMe;
        _token = 'supabase-jwt';
        _user = AuthUser(id: 'uid-1', email: email, role: 'teacher');
        _controller.add(true);
        return AuthSessionResult.success(
          user: _user,
          accessToken: _token,
          backendUnavailable: true,
          backendNotice:
              'Server unavailable. You are signed in and can continue offline.',
        );
      case 'missing_profile':
        _isAuth = true;
        _rememberMe = rememberMe;
        _token = 'supabase-jwt';
        _user = AuthUser(id: 'uid-1', email: email, role: 'teacher');
        _controller.add(true);
        return AuthSessionResult.success(
          user: _user,
          accessToken: _token,
          backendNotice: 'Teacher profile needs to be completed.',
          profileNeedsCompletion: true,
        );
      default:
        _isAuth = true;
        _rememberMe = rememberMe;
        _token = 'supabase-jwt';
        _user = AuthUser(id: 'uid-1', email: email, role: 'teacher');
        _controller.add(true);
        return AuthSessionResult.success(user: _user, accessToken: _token);
    }
  }

  @override
  Future<AuthSessionResult> signUpWithEmail({
    required String email,
    required String password,
    Map<String, dynamic>? data,
  }) async {
    if (!isValidEmail(email)) {
      return const AuthSessionResult.failure(
          'Please enter a valid email address.');
    }
    _isAuth = true;
    _token = 'new-jwt';
    _user = AuthUser(
      id: 'uid-new',
      email: email,
      role: 'teacher',
      metadata: {'name': data?['name'] ?? 'Teacher'},
    );
    _controller.add(true);
    return AuthSessionResult.success(user: _user, accessToken: _token);
  }

  @override
  Future<void> signOut() async {
    _isAuth = false;
    _user = null;
    _token = null;
    _rememberMe = false;
    _controller.add(false);
  }
}

void main() {
  group('email validation', () {
    test('accepts well-formed emails', () {
      expect(isValidEmail('teacher@school.edu.in'), isTrue);
      expect(isValidEmail('  Teacher@School.GOV.IN  '), isTrue);
    });

    test('rejects invalid emails', () {
      expect(isValidEmail(''), isFalse);
      expect(isValidEmail('teacher01'), isFalse);
      expect(isValidEmail('teacher@school'), isFalse);
      expect(isValidEmail('teacher @school.in'), isFalse);
      expect(isValidEmail('@school.in'), isFalse);
    });
  });

  group('error classification', () {
    test('supabase invalid-credential messages map to invalid credentials', () {
      expect(isInvalidCredentialsMessage('Invalid login credentials'), isTrue);
      expect(isInvalidCredentialsMessage('Invalid email or password'), isTrue);
      expect(isInvalidCredentialsMessage('Email not confirmed'), isFalse);
    });

    test('transport failures map to network errors', () {
      expect(isNetworkError(TimeoutException('x', const Duration(seconds: 4))), isTrue);
      expect(isNetworkError(Exception('SocketException: Connection refused')), isTrue);
      expect(isNetworkError(Exception('ClientException: Failed to fetch')), isTrue);
      expect(isNetworkError(Exception('some other bug')), isFalse);
    });
  });

  group('email + password login flow', () {
    test('successful login emits Authenticated', () async {
      final repo = EmailFakeAuthRepository();
      final bloc = AuthBloc(authRepository: repo);
      bloc.add(const AuthSignInEvent(
          email: 'teacher@school.edu.in', password: 'secret123'));
      await expectLater(
        bloc.stream,
        emitsInOrder([isA<AuthLoading>(), isA<Authenticated>()]),
      );
      await bloc.close();
    });

    test('wrong password emits "Invalid email or password"', () async {
      final repo = EmailFakeAuthRepository()..signInScenario = 'wrong_password';
      final bloc = AuthBloc(authRepository: repo);
      bloc.add(const AuthSignInEvent(
          email: 'teacher@school.edu.in', password: 'nope'));
      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<AuthLoading>(),
          isA<AuthError>().having(
              (s) => s.message, 'message', 'Invalid email or password'),
        ]),
      );
      await bloc.close();
    });

    test('invalid email never reports username problems', () async {
      final repo = EmailFakeAuthRepository();
      final bloc = AuthBloc(authRepository: repo);
      bloc.add(const AuthSignInEvent(email: 'teacher01', password: 'secret123'));
      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<AuthLoading>(),
          isA<AuthError>().having((s) => s.message, 'message',
              allOf(contains('valid email'), isNot(contains('sername')))),
        ]),
      );
      await bloc.close();
    });

    test('network timeout emits authentication-service connection error', () async {
      final repo = EmailFakeAuthRepository()..signInScenario = 'timeout';
      final bloc = AuthBloc(authRepository: repo);
      bloc.add(const AuthSignInEvent(
          email: 'teacher@school.edu.in', password: 'secret123'));
      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<AuthLoading>(),
          isA<AuthError>().having((s) => s.message, 'message',
              allOf(contains('Unable to connect'), isNot(contains('sername')))),
        ]),
      );
      await bloc.close();
    });

    test('backend outage still authenticates with offline notice', () async {
      final repo = EmailFakeAuthRepository()..signInScenario = 'backend_down';
      final bloc = AuthBloc(authRepository: repo);
      bloc.add(const AuthSignInEvent(
          email: 'teacher@school.edu.in', password: 'secret123'));
      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<AuthLoading>(),
          isA<Authenticated>()
              .having((s) => s.user.email, 'email', 'teacher@school.edu.in')
              .having((s) => s.backendNotice, 'backendNotice',
                  'Server unavailable. You are signed in and can continue offline.'),
        ]),
      );
      expect(repo.isAuthenticated, isTrue);
      await bloc.close();
    });

    test('missing teacher profile still authenticates with completion notice', () async {
      final repo = EmailFakeAuthRepository()
        ..signInScenario = 'missing_profile';
      final bloc = AuthBloc(authRepository: repo);
      bloc.add(const AuthSignInEvent(
          email: 'teacher@school.edu.in', password: 'secret123'));
      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<AuthLoading>(),
          isA<Authenticated>().having((s) => s.backendNotice,
              'backendNotice', 'Teacher profile needs to be completed.'),
        ]),
      );
      expect(repo.isAuthenticated, isTrue);
      await bloc.close();
    });

    test('registration with name/email/password authenticates', () async {
      final repo = EmailFakeAuthRepository();
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
          isA<Authenticated>().having(
              (s) => s.user.email, 'email', 'sunita@school.edu.in'),
        ]),
      );
      await bloc.close();
    });

    test('session restoration honors remember-me', () async {
      final repo = EmailFakeAuthRepository();
      // Log in with rememberMe ON, then re-initialize: session restored.
      var bloc = AuthBloc(authRepository: repo);
      bloc.add(const AuthSignInEvent(
        email: 'teacher@school.edu.in',
        password: 'secret123',
        rememberMe: true,
      ));
      await expectLater(
        bloc.stream,
        emitsInOrder([isA<AuthLoading>(), isA<Authenticated>()]),
      );
      await bloc.close();

      bloc = AuthBloc(authRepository: repo);
      bloc.add(const AuthInitializeEvent());
      await expectLater(
        bloc.stream,
        emitsInOrder([isA<AuthLoading>(), isA<Authenticated>()]),
      );
      await bloc.close();

      // rememberMe OFF signs out on restart.
      await repo.setRememberMe(false);
      bloc = AuthBloc(authRepository: repo);
      bloc.add(const AuthInitializeEvent());
      await expectLater(
        bloc.stream,
        emitsInOrder([isA<AuthLoading>(), isA<Unauthenticated>()]),
      );
      await bloc.close();
    });
  });
}
