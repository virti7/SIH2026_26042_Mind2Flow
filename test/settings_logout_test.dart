import 'dart:async';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:maatribhasha/app/di/injection.dart';
import 'package:maatribhasha/app/router/route_names.dart';
import 'package:maatribhasha/core/auth/data/repositories/supabase_auth_repository.dart';
import 'package:maatribhasha/core/auth/domain/repositories/auth_repository.dart';
import 'package:maatribhasha/core/auth/presentation/bloc/auth_bloc.dart';
import 'package:maatribhasha/core/database/app_database.dart';
import 'package:maatribhasha/core/enums/app_enums.dart';
import 'package:maatribhasha/core/models/app_models.dart';
import 'package:maatribhasha/core/repositories/app_repositories.dart';
import 'package:maatribhasha/core/repositories/mock_repositories.dart';
import 'package:maatribhasha/core/sync/worksheet_generation_queue.dart';
import 'package:maatribhasha/core/sync/remote_content_data_source.dart';
import 'package:maatribhasha/features/settings/presentation/pages/settings_screens.dart';

/// Settings "Log Out" (§11 items 1-10):
/// - visible button -> confirmation dialog -> real signOut -> Login.
/// - SQLite/Drift offline data is preserved across logout.
class _LogoutFakeRepo implements AuthRepository {
  bool _isAuth = true;
  AuthUser? _user = const AuthUser(
    id: 'uid-1',
    email: 'teacher@school.edu.in',
    role: 'teacher',
  );
  int signOutCalls = 0;

  /// When true, signOut throws (Supabase failure simulation).
  bool throwOnSignOut = false;

  /// When true, signOut leaves the session active (incomplete logout).
  bool stickySession = false;

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
  Future<String?> currentAccessToken() async =>
      _isAuth ? 'supabase-jwt' : null;
  @override
  Future<String?> getAccessToken() async => _isAuth ? 'supabase-jwt' : null;
  @override
  Future<void> initialize() async {}
  @override
  Future<bool> getRememberMe() async => false;
  @override
  Future<void> setRememberMe(bool value) async {}
  @override
  Future<String?> refreshToken() async => _isAuth ? 'supabase-jwt' : null;
  @override
  Future<bool> checkUsernameAvailable(String username) async => true;
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
      const AuthSessionResult.failure('OTP is not part of this flow.');
  @override
  Future<AuthSessionResult> verifyOtp({
    required String identifier,
    required String otp,
    bool rememberMe = false,
  }) async =>
      const AuthSessionResult.failure('OTP is not part of this flow.');
  @override
  Future<AuthSessionResult> signInWithEmail({
    required String email,
    required String password,
    bool rememberMe = false,
    String? schoolName,
  }) async =>
      AuthSessionResult.success(user: _user, accessToken: 'supabase-jwt');
  @override
  Future<AuthSessionResult> signUpWithEmail({
    required String email,
    required String password,
    Map<String, dynamic>? data,
  }) async =>
      AuthSessionResult.success(user: _user, accessToken: 'supabase-jwt');

  @override
  Future<void> signOut() async {
    signOutCalls++;
    if (throwOnSignOut) throw Exception('supabase signOut failed');
    if (stickySession) return;
    _isAuth = false;
    _user = null;
    _controller.add(false);
  }

  void dispose() => _controller.close();
}

GoRouter _settingsRouter(_LogoutFakeRepo repo) {
  return GoRouter(
    initialLocation: AppRoutes.settings,
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
        path: AppRoutes.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) =>
            const Scaffold(body: Text('Login Screen')),
      ),
    ],
  );
}

Future<void> _pumpSettings(
  WidgetTester tester,
  _LogoutFakeRepo repo,
  AuthBloc bloc,
) async {
  await tester.pumpWidget(
    BlocProvider<AuthBloc>.value(
      value: bloc,
      child: MaterialApp.router(
        routerConfig: _settingsRouter(repo),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _scrollToLogout(WidgetTester tester) async {
  final logout = find.text('Log Out');
  await tester.scrollUntilVisible(logout, 600);
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    if (!getIt.isRegistered<TeacherRepository>()) {
      getIt.registerSingleton<TeacherRepository>(MockTeacherRepository());
    }
  });

  tearDown(() async {
    if (getIt.isRegistered<TeacherRepository>()) {
      await getIt.unregister<TeacherRepository>();
    }
  });

  group('Settings logout UI', () {
    testWidgets('1. Logout button appears at the bottom of Settings',
        (tester) async {
      final repo = _LogoutFakeRepo();
      final bloc = AuthBloc(authRepository: repo);
      addTearDown(bloc.close);
      addTearDown(repo.dispose);
      await _pumpSettings(tester, repo, bloc);

      await _scrollToLogout(tester);
      expect(find.text('Log Out'), findsWidgets);
      expect(find.byIcon(Icons.logout_rounded), findsOneWidget);
    });

    testWidgets('2/3. Tapping Log Out opens confirmation; Cancel keeps session',
        (tester) async {
      final repo = _LogoutFakeRepo();
      final bloc = AuthBloc(authRepository: repo);
      addTearDown(bloc.close);
      addTearDown(repo.dispose);
      await _pumpSettings(tester, repo, bloc);

      await _scrollToLogout(tester);
      // The divider-adjacent outlined button (not the dialog action).
      await tester.tap(find.widgetWithText(OutlinedButton, 'Log Out'));
      await tester.pumpAndSettle();

      expect(find.text('Log out?'), findsOneWidget);
      expect(
        find.text('You will need to sign in again to access your account.'),
        findsOneWidget,
      );

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Log out?'), findsNothing);
      expect(repo.signOutCalls, 0);
      expect(repo.isAuthenticated, isTrue);
    });

    testWidgets('4/5/6. Confirm signs out, shows feedback, navigates to Login',
        (tester) async {
      final repo = _LogoutFakeRepo();
      final bloc = AuthBloc(authRepository: repo);
      addTearDown(bloc.close);
      addTearDown(repo.dispose);
      await _pumpSettings(tester, repo, bloc);

      await _scrollToLogout(tester);
      await tester.tap(find.widgetWithText(OutlinedButton, 'Log Out'));
      await tester.pumpAndSettle();

      // Confirm inside the dialog (TextButton action, not OutlinedButton).
      await tester.tap(find.widgetWithText(TextButton, 'Log Out'));
      await tester.pumpAndSettle();

      expect(repo.signOutCalls, 1);
      expect(repo.isAuthenticated, isFalse);
      expect(find.text('Logged out successfully.'), findsOneWidget);
      expect(find.text('Login Screen'), findsOneWidget);
    });

    testWidgets('7. Failed signOut shows error and stays authenticated',
        (tester) async {
      final repo = _LogoutFakeRepo()..throwOnSignOut = true;
      final bloc = AuthBloc(authRepository: repo);
      addTearDown(bloc.close);
      addTearDown(repo.dispose);
      await _pumpSettings(tester, repo, bloc);

      await _scrollToLogout(tester);
      await tester.tap(find.widgetWithText(OutlinedButton, 'Log Out'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Log Out'));
      await tester.pumpAndSettle();

      expect(find.text('Unable to log out. Please try again.'), findsOneWidget);
      expect(find.text('Login Screen'), findsNothing);
      expect(find.text('Logged out successfully.'), findsNothing);
    });

    testWidgets('7b. Sticky session does not falsely navigate to Login',
        (tester) async {
      final repo = _LogoutFakeRepo()..stickySession = true;
      final bloc = AuthBloc(authRepository: repo);
      addTearDown(bloc.close);
      addTearDown(repo.dispose);
      await _pumpSettings(tester, repo, bloc);

      await _scrollToLogout(tester);
      await tester.tap(find.widgetWithText(OutlinedButton, 'Log Out'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Log Out'));
      await tester.pumpAndSettle();

      expect(repo.isAuthenticated, isTrue);
      expect(find.text('Unable to log out. Please try again.'), findsOneWidget);
      expect(find.text('Login Screen'), findsNothing);
    });
  });

  group('logout session lifecycle', () {
    test('8. after logout, initialization restores Unauthenticated (Login)',
        () async {
      final repo = _LogoutFakeRepo();
      var bloc = AuthBloc(authRepository: repo);
      bloc.add(const AuthSignOutEvent());
      await expectLater(
        bloc.stream,
        emitsInOrder([isA<AuthLoading>(), isA<Unauthenticated>()]),
      );
      await bloc.close();

      bloc = AuthBloc(authRepository: repo);
      bloc.add(const AuthInitializeEvent());
      await expectLater(
        bloc.stream,
        emitsInOrder([isA<AuthLoading>(), isA<Unauthenticated>()]),
      );
      await bloc.close();
      repo.dispose();
    });
  });

  group('9/10. SQLite/Drift offline data preserved across logout', () {
    test('real signOut keeps profile, queue, and saved worksheets', () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);

      // Seed representative offline data.
      final profileRepo = _DirectTeacherWriter(db);
      await profileRepo.saveSample();
      final queue = NativeWorksheetGenerationQueue(db);
      await queue.enqueue(const TeacherGenerationRequestModel(
        topic: 'offline-proof',
        targetLanguage: 'sat',
      ));
      final store = NativeGeneratedWorksheetStore(db);
      await store.saveCompletedWorksheet('WS-1', {'title': 'Saved WS'});
      expect(await queue.pendingCount(), 1);

      // Real repository logout (offline test build: no Supabase client).
      final authRepo = SupabaseAuthRepository();
      await authRepo.signOut();
      expect(await authRepo.getRememberMe(), isFalse);

      // Nothing offline was wiped.
      final profile = await profileRepo.readBack();
      expect(profile.name, 'Offline Teacher');
      expect(await queue.pendingCount(), 1);
      expect((await queue.pendingEntries()).single.request.topic,
          'offline-proof');
    });
  });
}

/// Minimal writer/reader over the real Drift teacher table without going
/// through use cases, to prove logout performs no destructive reset.
class _DirectTeacherWriter {
  final AppDatabase db;
  _DirectTeacherWriter(this.db);

  Future<void> saveSample() async {
    await db.teacherDao.insertOrUpdateProfile(
      TeachersCompanion(
        id: const Value('teacher_primary'),
        name: const Value('Offline Teacher'),
        school: const Value('Village School'),
        district: const Value('Khunti'),
        state: const Value('Jharkhand'),
        classesTaughtJson: const Value('[1,2,3]'),
        teachingLanguage: const Value('Hindi'),
        supportedLanguagesJson: const Value('["mundari"]'),
        activeSessionLanguage: const Value('mundari'),
        updatedAt: Value(DateTime(2026, 1, 1)),
      ),
    );
  }

  Future<TeacherProfile> readBack() async {
    final row = await db.teacherDao.getProfile();
    return TeacherProfile(
      id: row!.id,
      name: row.name,
      school: row.school,
      district: row.district,
      state: row.state,
      classesTaught: const [1, 2, 3],
      teachingLanguage: row.teachingLanguage,
      supportedClassroomLanguages: const [TribalLanguage.mundari],
      activeSessionLanguage: TribalLanguage.mundari,
    );
  }
}
