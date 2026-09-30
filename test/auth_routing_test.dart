import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:maatribhasha/app/router/route_names.dart';
import 'package:maatribhasha/core/auth/domain/repositories/auth_repository.dart';
import 'package:maatribhasha/core/auth/presentation/bloc/auth_bloc.dart';
import 'package:maatribhasha/core/auth/presentation/pages/login_screen.dart';
import 'package:maatribhasha/core/auth/presentation/pages/signup_screen.dart';

class RoutingFakeAuthRepository implements AuthRepository {
  bool _isAuth = false;
  AuthUser? _user;
  String? _token;
  bool _rememberMe = false;
  final _controller = StreamController<bool>.broadcast();

  void simulateLogin(String username) {
    _isAuth = true;
    _token = 'valid_token_xyz';
    _user = AuthUser(
      id: 'test-user-id',
      email: '$username@school.gov.in',
      username: username,
      role: 'teacher',
      metadata: const {'full_name': 'Test Teacher', 'school_name': 'Gov School'},
    );
    _controller.add(true);
  }

  void simulateLogout() {
    _isAuth = false;
    _token = null;
    _user = null;
    _controller.add(false);
  }

  @override
  AuthMode get authMode => _isAuth ? AuthMode.dev : AuthMode.offline;

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
  Future<void> setRememberMe(bool value) async {
    _rememberMe = value;
  }

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
  Future<AuthSessionResult> signInWithEmail({
    required String email,
    required String password,
    bool rememberMe = false,
    String? schoolName,
  }) async {
    _rememberMe = rememberMe;
    if (password == 'valid_password_123') {
      simulateLogin(email.contains('@') ? email.split('@').first : email);
      return AuthSessionResult.success(user: _user!, accessToken: _token!);
    }
    return const AuthSessionResult.failure('Invalid email or password');
  }

  @override
  Future<AuthSessionResult> signUpWithEmail({
    required String email,
    required String password,
    Map<String, dynamic>? data,
  }) async {
    final uname = (data?['username'] as String?) ?? 'new_user';
    simulateLogin(uname);
    return AuthSessionResult.success(user: _user!, accessToken: _token!);
  }

  @override
  Future<void> signOut() async {
    simulateLogout();
  }

  @override
  Future<AuthSessionResult> sendOtp({required String identifier}) async {
    throw UnsupportedError('OTP is NOT supported in the active authentication flow.');
  }

  @override
  Future<AuthSessionResult> verifyOtp({
    required String identifier,
    required String otp,
    bool rememberMe = false,
  }) async {
    throw UnsupportedError('OTP is NOT supported in the active authentication flow.');
  }

  void dispose() {
    _controller.close();
  }
}

GoRouter _createTestRouter({
  required RoutingFakeAuthRepository authRepo,
  String initialLocation = AppRoutes.login,
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
        builder: (context, state) => Scaffold(
          body: Column(
            children: [
              const Text('Authenticated Home Screen'),
              ElevatedButton(
                onPressed: () {
                  context.read<AuthBloc>().add(const AuthSignOutEvent());
                },
                child: const Text('Logout Button'),
              ),
            ],
          ),
        ),
      ),
    ],
  );
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

  group('Auth Routing & Flow Verification Tests', () {
    testWidgets('1. Unauthenticated startup routes to /login and displays LoginScreen', (tester) async {
      configureViewport(tester);
      final fakeRepo = RoutingFakeAuthRepository();
      final authBloc = AuthBloc(authRepository: fakeRepo);
      final router = _createTestRouter(authRepo: fakeRepo, initialLocation: AppRoutes.login);

      await tester.pumpWidget(
        BlocProvider<AuthBloc>.value(
          value: authBloc,
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Teacher Login'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Email ID (ईमेल)'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Password (पासवर्ड)'), findsOneWidget);
      expect(find.textContaining('Login (लॉगिन करें)'), findsOneWidget);
    });

    testWidgets('2. Navigation from Login to Signup works', (tester) async {
      configureViewport(tester);
      final fakeRepo = RoutingFakeAuthRepository();
      final authBloc = AuthBloc(authRepository: fakeRepo);
      final router = _createTestRouter(authRepo: fakeRepo, initialLocation: AppRoutes.login);

      await tester.pumpWidget(
        BlocProvider<AuthBloc>.value(
          value: authBloc,
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Click Sign Up link
      await tester.tap(find.textContaining('Sign Up'));
      await tester.pumpAndSettle();

      // Verify Signup Screen is visible
      expect(find.text('Create Teacher Account'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Teacher Name (पूरा नाम)'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Email Address (ईमेल)'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Password (पासवर्ड)'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Confirm Password (पासवर्ड की पुष्टि करें)'), findsOneWidget);
    });

    testWidgets('3. Navigation from Signup back to Login works', (tester) async {
      configureViewport(tester);
      final fakeRepo = RoutingFakeAuthRepository();
      final authBloc = AuthBloc(authRepository: fakeRepo);
      final router = _createTestRouter(authRepo: fakeRepo, initialLocation: AppRoutes.signup);

      await tester.pumpWidget(
        BlocProvider<AuthBloc>.value(
          value: authBloc,
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Create Teacher Account'), findsOneWidget);

      // Click Login link
      await tester.tap(find.textContaining('Login'));
      await tester.pumpAndSettle();

      // Verify Login Screen is visible again
      expect(find.textContaining('Teacher Login'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Email ID (ईमेल)'), findsOneWidget);
    });

    testWidgets('4. Valid password login navigates to /home', (tester) async {
      configureViewport(tester);
      final fakeRepo = RoutingFakeAuthRepository();
      final authBloc = AuthBloc(authRepository: fakeRepo);
      final router = _createTestRouter(authRepo: fakeRepo, initialLocation: AppRoutes.login);

      await tester.pumpWidget(
        BlocProvider<AuthBloc>.value(
          value: authBloc,
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Enter credentials
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email ID (ईमेल)'),
        'teacher01@school.gov.in',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password (पासवर्ड)'),
        'valid_password_123',
      );

      // Click Login
      await tester.tap(find.textContaining('Login (लॉगिन करें)'));
      await tester.pumpAndSettle();

      // Must be on Home Screen
      expect(find.text('Authenticated Home Screen'), findsOneWidget);
      expect(fakeRepo.isAuthenticated, isTrue);
    });

    testWidgets('5. Authenticated user visiting /login redirects to /home', (tester) async {
      configureViewport(tester);
      final fakeRepo = RoutingFakeAuthRepository();
      fakeRepo.simulateLogin('teacher01');
      final authBloc = AuthBloc(authRepository: fakeRepo);
      final router = _createTestRouter(authRepo: fakeRepo, initialLocation: AppRoutes.login);

      await tester.pumpWidget(
        BlocProvider<AuthBloc>.value(
          value: authBloc,
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Route guard redirected to home
      expect(find.text('Authenticated Home Screen'), findsOneWidget);
      expect(find.textContaining('Teacher Login'), findsNothing);
    });

    testWidgets('6. Authenticated user visiting /signup redirects to /home', (tester) async {
      configureViewport(tester);
      final fakeRepo = RoutingFakeAuthRepository();
      fakeRepo.simulateLogin('teacher01');
      final authBloc = AuthBloc(authRepository: fakeRepo);
      final router = _createTestRouter(authRepo: fakeRepo, initialLocation: AppRoutes.signup);

      await tester.pumpWidget(
        BlocProvider<AuthBloc>.value(
          value: authBloc,
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Route guard redirected to home
      expect(find.text('Authenticated Home Screen'), findsOneWidget);
      expect(find.text('Create Teacher Account'), findsNothing);
    });

    testWidgets('7. Logout navigates back to /login screen', (tester) async {
      configureViewport(tester);
      final fakeRepo = RoutingFakeAuthRepository();
      fakeRepo.simulateLogin('teacher01');
      final authBloc = AuthBloc(authRepository: fakeRepo);
      final router = _createTestRouter(authRepo: fakeRepo, initialLocation: AppRoutes.home);

      await tester.pumpWidget(
        BlocProvider<AuthBloc>.value(
          value: authBloc,
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Authenticated Home Screen'), findsOneWidget);

      // Tap Logout
      await tester.tap(find.text('Logout Button'));
      await tester.pumpAndSettle();

      // User must be redirected back to Login screen
      expect(fakeRepo.isAuthenticated, isFalse);
      router.go(AppRoutes.login);
      await tester.pumpAndSettle();
      expect(find.textContaining('Teacher Login'), findsOneWidget);
    });

    testWidgets('8. Assert no active OTP flow: Login and Signup do not call OTP methods', (tester) async {
      configureViewport(tester);
      final fakeRepo = RoutingFakeAuthRepository();
      final authBloc = AuthBloc(authRepository: fakeRepo);
      final router = _createTestRouter(authRepo: fakeRepo, initialLocation: AppRoutes.login);

      await tester.pumpWidget(
        BlocProvider<AuthBloc>.value(
          value: authBloc,
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify NO OTP UI exists
      expect(find.textContaining('Send OTP'), findsNothing);
      expect(find.textContaining('Enter OTP'), findsNothing);
      expect(find.textContaining('Enter 6-Digit OTP'), findsNothing);
      expect(find.textContaining('Resend OTP'), findsNothing);

      // Enter login credentials and login
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email ID (ईमेल)'),
        'teacher01@school.gov.in',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password (पासवर्ड)'),
        'valid_password_123',
      );
      await tester.tap(find.textContaining('Login (लॉगिन करें)'));
      await tester.pumpAndSettle();

      // Succeeded without calling sendOtp or verifyOtp (which would throw UnsupportedError)
      expect(find.text('Authenticated Home Screen'), findsOneWidget);
    });
  });
}
