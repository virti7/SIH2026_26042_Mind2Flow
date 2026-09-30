import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:maatribhasha/core/auth/domain/repositories/auth_repository.dart';
import 'package:maatribhasha/core/auth/presentation/bloc/auth_bloc.dart';
import 'package:maatribhasha/core/auth/presentation/pages/login_screen.dart';
import 'package:maatribhasha/core/auth/presentation/pages/signup_screen.dart';

class FakeAuthRepository implements AuthRepository {
  bool rememberMeValue = false;
  AuthUser? loggedInUser;
  String? lastResolvedEmail;
  AuthSessionResult? nextSignInResult;
  AuthSessionResult? nextSignUpResult;
  AuthSessionResult? nextSendOtpResult;
  AuthSessionResult? nextVerifyOtpResult;

  @override
  AuthMode get authMode => AuthMode.dev;

  @override
  bool get isAuthenticated => loggedInUser != null;

  @override
  AuthUser? get currentUser => loggedInUser;

  @override
  String? get currentUserEmail => loggedInUser?.email;

  @override
  String? get currentUserId => loggedInUser?.id;

  @override
  Stream<bool> get authStateChanges => Stream.value(isAuthenticated);

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> getRememberMe() async => rememberMeValue;

  @override
  Future<void> setRememberMe(bool value) async {
    rememberMeValue = value;
  }

  @override
  Future<bool> checkUsernameAvailable(String username) async {
    return username != 'taken_teacher';
  }

  @override
  Future<bool> registerTeacherProfile({
    required String userId,
    required String username,
    required String name,
    required String email,
  }) async {
    return true;
  }

  @override
  Future<String?> currentAccessToken() async => loggedInUser != null ? 'fake_jwt' : null;

  @override
  Future<String?> getAccessToken() async => loggedInUser != null ? 'fake_jwt' : null;

  @override
  Future<String?> refreshToken() async => loggedInUser != null ? 'refreshed_jwt' : null;

  @override
  Future<AuthSessionResult> sendOtp({required String identifier}) async {
    if (nextSendOtpResult != null) return nextSendOtpResult!;
    if (identifier == 'unknown_teacher') {
      return const AuthSessionResult.failure('Teacher code not found. Please check your details.');
    }
    final email = identifier.contains('@') ? identifier : '$identifier@school.gov.in';
    return AuthSessionResult.success(
      user: AuthUser(
        id: 'u-temp',
        email: email,
        username: identifier,
        role: 'teacher',
        metadata: {'email_hint': '${email[0]}***@${email.split('@').last}'},
      ),
      accessToken: 'temp-token',
    );
  }

  @override
  Future<AuthSessionResult> verifyOtp({
    required String identifier,
    required String otp,
    bool rememberMe = false,
  }) async {
    rememberMeValue = rememberMe;
    if (nextVerifyOtpResult != null) return nextVerifyOtpResult!;
    if (otp == '000000') {
      return const AuthSessionResult.failure('Invalid OTP code. Please check and try again.');
    }
    if (otp == '999999') {
      return const AuthSessionResult.failure('OTP has expired. Please request a new code.');
    }
    final user = AuthUser(
      id: 'test-user-id',
      email: identifier.contains('@') ? identifier : '$identifier@school.gov.in',
      username: identifier,
      role: 'teacher',
    );
    loggedInUser = user;
    return AuthSessionResult.success(user: user, accessToken: 'fake_jwt_token');
  }

  @override
  Future<AuthSessionResult> signInWithEmail({
    required String email,
    required String password,
    bool rememberMe = false,
    String? schoolName,
  }) async {
    rememberMeValue = rememberMe;
    if (nextSignInResult != null) return nextSignInResult!;
    if (password == 'wrong_password') {
      return const AuthSessionResult.failure('Invalid login credentials.');
    }
    final user = AuthUser(
      id: 'test-user-id',
      email: email.contains('@') ? email : '$email@school.edu.in',
      username: email.contains('@') ? email.split('@').first : email,
      role: 'teacher',
    );
    loggedInUser = user;
    return AuthSessionResult.success(user: user, accessToken: 'fake_jwt_token');
  }

  @override
  Future<AuthSessionResult> signUpWithEmail({
    required String email,
    required String password,
    Map<String, dynamic>? data,
  }) async {
    if (nextSignUpResult != null) return nextSignUpResult!;
    final user = AuthUser(
      id: 'test-new-user-id',
      email: email,
      username: (data?['username'] as String?) ?? 'new_user',
      role: 'teacher',
    );
    return AuthSessionResult.success(user: user, accessToken: 'fake_jwt_token');
  }

  @override
  Future<void> signOut() async {
    loggedInUser = null;
    rememberMeValue = false;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  void configureViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  group('Teacher Authentication UX Tests', () {
    testWidgets('1. Login screen renders Email ID field, Password field, Remember Me, and Login button', (tester) async {
      configureViewport(tester);
      final fakeRepo = FakeAuthRepository();
      final authBloc = AuthBloc(authRepository: fakeRepo);

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<AuthBloc>.value(
            value: authBloc,
            child: const LoginScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Header & Labels
      expect(find.textContaining('शिक्षक लॉगिन'), findsOneWidget);
      expect(find.textContaining('Email ID'), findsOneWidget);
      expect(find.textContaining('Teacher Code'), findsNothing);
      expect(find.textContaining('Password (पासवर्ड)'), findsOneWidget);
      expect(find.text('Remember me'), findsOneWidget);
      expect(find.byType(Checkbox), findsOneWidget);
      expect(find.textContaining('Login (लॉगिन करें)'), findsOneWidget);
      expect(find.textContaining('Sign Up'), findsOneWidget);
      expect(find.textContaining('Continue Offline'), findsOneWidget);

      // Verify Password field has visibility toggle icon
      expect(find.byIcon(Icons.visibility_off), findsOneWidget);
    });

    testWidgets('2. Login screen validates empty email and empty password', (tester) async {
      configureViewport(tester);
      final fakeRepo = FakeAuthRepository();
      final authBloc = AuthBloc(authRepository: fakeRepo);

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<AuthBloc>.value(
            value: authBloc,
            child: const LoginScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Click Login without entering credentials
      await tester.tap(find.textContaining('Login (लॉगिन करें)'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter your email address.'), findsOneWidget);
      expect(find.text('Please enter your password.'), findsOneWidget);
    });

    testWidgets('3. Password visibility toggle works correctly', (tester) async {
      configureViewport(tester);
      final fakeRepo = FakeAuthRepository();
      final authBloc = AuthBloc(authRepository: fakeRepo);

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<AuthBloc>.value(
            value: authBloc,
            child: const LoginScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initially password is obscured so visibility_off icon is shown
      expect(find.byIcon(Icons.visibility_off), findsOneWidget);
      expect(find.byIcon(Icons.visibility), findsNothing);

      // Tap visibility toggle
      await tester.tap(find.byIcon(Icons.visibility_off));
      await tester.pumpAndSettle();

      // Now password is revealed so visibility icon is shown
      expect(find.byIcon(Icons.visibility), findsOneWidget);
      expect(find.byIcon(Icons.visibility_off), findsNothing);
    });

    testWidgets('4. Entering valid credentials submits AuthSignInEvent and logs in', (tester) async {
      configureViewport(tester);
      final fakeRepo = FakeAuthRepository();
      final authBloc = AuthBloc(authRepository: fakeRepo);

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<AuthBloc>.value(
            value: authBloc,
            child: const LoginScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Enter email
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email ID (ईमेल)'),
        'jh_teacher_01@school.gov.in',
      );
      // Enter password
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password (पासवर्ड)'),
        'valid_password_123',
      );
      // Toggle Remember Me
      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();

      // Tap Login
      await tester.tap(find.textContaining('Login (लॉगिन करें)'));
      await tester.pumpAndSettle();

      expect(authBloc.state, isA<Authenticated>());
      final auth = authBloc.state as Authenticated;
      expect(auth.user.username, 'jh_teacher_01');
      expect(fakeRepo.rememberMeValue, isTrue);
    });

    testWidgets('5. Sign Up screen renders all 4 required fields, buttons, and link', (tester) async {
      configureViewport(tester);
      final fakeRepo = FakeAuthRepository();
      final authBloc = AuthBloc(authRepository: fakeRepo);

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<AuthBloc>.value(
            value: authBloc,
            child: const SignUpScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Create Teacher Account'), findsOneWidget);
      expect(find.textContaining('Teacher Name'), findsOneWidget);
      expect(find.textContaining('Teacher Code'), findsNothing);
      expect(find.textContaining('Email Address'), findsOneWidget);
      expect(find.text('Password (पासवर्ड)'), findsOneWidget);
      expect(find.text('Confirm Password (पासवर्ड की पुष्टि करें)'), findsOneWidget);
      expect(find.textContaining('Create Account (खाता बनाएं)'), findsOneWidget);
      expect(find.textContaining('Login'), findsOneWidget);
    });

    testWidgets('6. Sign Up validates password mismatch and weak password', (tester) async {
      configureViewport(tester);
      final fakeRepo = FakeAuthRepository();
      final authBloc = AuthBloc(authRepository: fakeRepo);

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<AuthBloc>.value(
            value: authBloc,
            child: const SignUpScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Enter weak password
      await tester.enterText(find.widgetWithText(TextFormField, 'Teacher Name (पूरा नाम)'), 'Shri Soren');
      await tester.enterText(find.widgetWithText(TextFormField, 'Email Address (ईमेल)'), 'soren@school.gov.in');
      await tester.enterText(find.widgetWithText(TextFormField, 'Password (पासवर्ड)'), '123');
      await tester.enterText(find.widgetWithText(TextFormField, 'Confirm Password (पासवर्ड की पुष्टि करें)'), '123456');
      await tester.pumpAndSettle();

      await tester.tap(find.textContaining('Create Account (खाता बनाएं)'));
      await tester.pumpAndSettle();

      expect(find.text('Password must be at least 6 characters'), findsOneWidget);
      expect(find.text('Passwords do not match'), findsOneWidget);
    });

    testWidgets('7. Sign Up validates invalid email format', (tester) async {
      configureViewport(tester);
      final fakeRepo = FakeAuthRepository();
      final authBloc = AuthBloc(authRepository: fakeRepo);

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<AuthBloc>.value(
            value: authBloc,
            child: const SignUpScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextFormField, 'Teacher Name (पूरा नाम)'), 'Shri Soren');
      await tester.enterText(find.widgetWithText(TextFormField, 'Email Address (ईमेल)'), 'invalid-email');
      await tester.enterText(find.widgetWithText(TextFormField, 'Password (पासवर्ड)'), 'secret123');
      await tester.enterText(find.widgetWithText(TextFormField, 'Confirm Password (पासवर्ड की पुष्टि करें)'), 'secret123');
      await tester.pumpAndSettle();

      await tester.tap(find.textContaining('Create Account (खाता बनाएं)'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter a valid email address'), findsOneWidget);
    });

    test('8. AuthBloc session restoration with Remember Me = ON and OFF', () async {
      final fakeRepo = FakeAuthRepository();
      final authBloc = AuthBloc(authRepository: fakeRepo);

      // Scenario A: rememberMe = true and user logged in
      fakeRepo.rememberMeValue = true;
      fakeRepo.loggedInUser = const AuthUser(
        id: 'u-1',
        email: 't@school.in',
        username: 't01',
        role: 'teacher',
      );

      authBloc.add(const AuthInitializeEvent());
      await expectLater(
        authBloc.stream,
        emitsInOrder([
          isA<AuthLoading>(),
          isA<Authenticated>().having((s) => s.user.username, 'username', 't01'),
        ]),
      );

      // Scenario B: rememberMe = false
      final authBloc2 = AuthBloc(authRepository: fakeRepo);
      fakeRepo.rememberMeValue = false;
      // even if loggedInUser is present, initialize with rememberMe=false must sign out
      authBloc2.add(const AuthInitializeEvent());
      await expectLater(
        authBloc2.stream,
        emitsInOrder([
          isA<AuthLoading>(),
          isA<Unauthenticated>(),
        ]),
      );
      expect(fakeRepo.isAuthenticated, isFalse);
    });
  });
}
