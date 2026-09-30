import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../repositories/app_repositories.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../services/account_session.dart';

// =====================================================================
// AUTH EVENTS
// =====================================================================

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

class AuthInitializeEvent extends AuthEvent {
  const AuthInitializeEvent();
}

class AuthSignInEvent extends AuthEvent {
  final String email;
  final String password;
  final bool rememberMe;

  const AuthSignInEvent({
    required this.email,
    required this.password,
    this.rememberMe = false,
  });

  @override
  List<Object?> get props => [email, password, rememberMe];
}

class AuthSignUpEvent extends AuthEvent {
  final String name;
  final String schoolName;
  final String username;
  final String email;
  final String password;
  final String role;
  final Map<String, dynamic>? metadata;

  const AuthSignUpEvent({
    this.name = '',
    this.schoolName = '',
    this.username = '',
    required this.email,
    required this.password,
    this.role = 'teacher',
    this.metadata,
  });

  @override
  List<Object?> get props =>
      [name, schoolName, username, email, password, role, metadata];
}

class AuthSendOtpEvent extends AuthEvent {
  final String identifier;
  final bool rememberMe;

  const AuthSendOtpEvent({
    required this.identifier,
    this.rememberMe = false,
  });

  @override
  List<Object?> get props => [identifier, rememberMe];
}

class AuthVerifyOtpEvent extends AuthEvent {
  final String identifier;
  final String otp;
  final bool rememberMe;

  const AuthVerifyOtpEvent({
    required this.identifier,
    required this.otp,
    this.rememberMe = false,
  });

  @override
  List<Object?> get props => [identifier, otp, rememberMe];
}

class AuthResetLoginEvent extends AuthEvent {
  const AuthResetLoginEvent();
}

// Event aliases for Part 9 specification compatibility
typedef AuthInitialize = AuthInitializeEvent;
typedef AuthLoginRequested = AuthSignInEvent;
typedef AuthSignupRequested = AuthSignUpEvent;
typedef AuthLogoutRequested = AuthSignOutEvent;
typedef AuthSessionChanged = AuthStatusChangedEvent;
typedef AuthSendOtpRequested = AuthSendOtpEvent;
typedef AuthVerifyOtpRequested = AuthVerifyOtpEvent;
typedef AuthResetLoginRequested = AuthResetLoginEvent;

class AuthSignOutEvent extends AuthEvent {
  const AuthSignOutEvent();
}

class AuthSessionRefreshedEvent extends AuthEvent {
  const AuthSessionRefreshedEvent();
}

class AuthStatusChangedEvent extends AuthEvent {
  final bool isAuthenticated;
  const AuthStatusChangedEvent(this.isAuthenticated);

  @override
  List<Object?> get props => [isAuthenticated];
}

// =====================================================================
// AUTH STATES
// =====================================================================

abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthOtpSentState extends AuthState {
  final String identifier;
  final String emailHint;
  final bool rememberMe;

  const AuthOtpSentState({
    required this.identifier,
    required this.emailHint,
    this.rememberMe = false,
  });

  @override
  List<Object?> get props => [identifier, emailHint, rememberMe];
}

class Authenticated extends AuthState {
  final AuthUser user;
  final String accessToken;

  /// Non-blocking backend notice attached AFTER a successful Supabase
  /// authentication (e.g. "Server unavailable. You are signed in and can
  /// continue offline."). Never an authentication failure: the session stays
  /// valid and routing treats this state as authenticated.
  final String? backendNotice;

  /// True when the merged teacher profile (server -> Supabase metadata ->
  /// local Drift) still lacks a teacher name or school name. Listeners route
  /// to the profile completion screen instead of Home.
  final bool profileNeedsCompletion;

  const Authenticated({
    required this.user,
    required this.accessToken,
    this.backendNotice,
    this.profileNeedsCompletion = false,
  });

  @override
  List<Object?> get props =>
      [user, accessToken, backendNotice, profileNeedsCompletion];
}

class Unauthenticated extends AuthState {
  final String? message;

  const Unauthenticated({this.message});

  @override
  List<Object?> get props => [message];
}

class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}

// =====================================================================
// AUTH BLOC (Strictly Bloc, NO Cubit)
// =====================================================================

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;

  /// Optional local profile store. When present, a successful Supabase
  /// authentication merges the freshest teacher name/school
  /// (server -> Supabase metadata -> existing local row) into Drift so the
  /// app header works offline. Never wiped: only name/school are filled in.
  final TeacherRepository? teacherRepository;
  StreamSubscription<bool>? _authSub;

  AuthBloc({required this.authRepository, this.teacherRepository})
      : super(AuthInitial()) {
    on<AuthInitializeEvent>(_onInitialize);
    on<AuthSignInEvent>(_onSignIn);
    on<AuthSignUpEvent>(_onSignUp);
    on<AuthSignOutEvent>(_onSignOut);
    on<AuthSessionRefreshedEvent>(_onSessionRefreshed);
    on<AuthStatusChangedEvent>(_onStatusChanged);
    on<AuthSendOtpEvent>(_onSendOtp);
    on<AuthVerifyOtpEvent>(_onVerifyOtp);
    on<AuthResetLoginEvent>(_onResetLogin);

    // Subscribe to external auth state changes
    _authSub = authRepository.authStateChanges.listen((isAuth) {
      add(AuthStatusChangedEvent(isAuth));
    });
  }

  Future<void> _onInitialize(
    AuthInitializeEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      await authRepository.initialize();
      final rememberMe = await authRepository.getRememberMe();
      if (authRepository.isAuthenticated) {
        if (!rememberMe) {
          // If remember me is false, sign out on restart so teacher lands on login
          await authRepository.signOut();
          emit(const Unauthenticated());
          return;
        }
        final token = await authRepository.getAccessToken() ??
            await authRepository.currentAccessToken() ??
            'offline-session';
        final user = authRepository.currentUser;
        if (user != null) {
          AccountSession.notifySignedIn(user.id);
          emit(Authenticated(user: user, accessToken: token));
          return;
        }
      }
      emit(const Unauthenticated());
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onSignIn(
    AuthSignInEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    // NOTE: no on-device school fallback from a previous account here.
    // getProfile() is account-scoped and unauthenticated at this point, so
    // it yields empty state rather than leaking account A's school into
    // account B's server provisioning.
    String? localSchool;
    try {
      final local = await teacherRepository?.getProfile();
      final trimmed = (local?.school ?? '').trim();
      if (trimmed.isNotEmpty) localSchool = trimmed;
    } catch (_) {}
    final result = await authRepository.signInWithEmail(
      email: event.email,
      password: event.password,
      rememberMe: event.rememberMe,
      schoolName: localSchool,
    );

    if (result.isSuccess && result.user != null && result.accessToken != null) {
      final needsCompletion = await _persistAuthProfile(result);
      // Notify account-scoped state to reload for the new owner.
      AccountSession.notifySignedIn(result.user!.id);
      emit(Authenticated(
        user: result.user!,
        accessToken: result.accessToken!,
        backendNotice: result.backendNotice,
        profileNeedsCompletion:
            needsCompletion || result.profileNeedsCompletion,
      ));
    } else {
      emit(AuthError(result.errorMessage ?? 'Authentication failed'));
    }
  }

  /// Merges the freshest teacher name/school into the CURRENT account's local
  /// Drift profile after a successful Supabase authentication. The row PK is
  /// the Supabase user UUID, so each account owns exactly one row.
  /// Precedence: server values from `/me`/`register-teacher` -> Supabase user
  /// metadata -> existing local row OF THIS ACCOUNT. Only fills in
  /// name/school; every other local column and all offline data
  /// (downloads, queue, activity) are preserved per-account.
  ///
  /// Returns true when the merged profile still lacks a name or school, so
  /// listeners can route to profile completion instead of Home.
  Future<bool> _persistAuthProfile(AuthSessionResult result) async {
    final repo = teacherRepository;
    final authUser = result.user;
    if (repo == null || authUser == null) return false;
    if (authUser.id.trim().isEmpty) return false;
    try {
      final local = await repo.getProfile();
      final meta = authUser.metadata;
      final metaName =
          (meta['full_name'] as String? ?? meta['name'] as String? ?? '')
              .trim();
      final metaSchool = (meta['school_name'] as String? ?? '').trim();
      final name = (result.serverName ?? '').trim().isNotEmpty
          ? result.serverName!.trim()
          : metaName.isNotEmpty
              ? metaName
              : local.name.trim();
      final school = (result.serverSchoolName ?? '').trim().isNotEmpty
          ? result.serverSchoolName!.trim()
          : metaSchool.isNotEmpty
              ? metaSchool
              : local.school.trim();
      // Force the row id to the authenticated user UUID. The scoped
      // repository writes/reads only this account's row.
      final scoped = local.copyWith(
        id: authUser.id,
        name: name.isNotEmpty ? name : local.name,
        school: school.isNotEmpty ? school : local.school,
      );
      if (scoped.name.trim() != local.name.trim() ||
          scoped.school.trim() != local.school.trim() ||
          local.id != authUser.id) {
        if (kDebugMode) {
          debugPrint('[Auth] Local teacher profile updated from auth data');
        }
        await repo.updateProfile(scoped);
      }
      return name.isEmpty || school.isEmpty;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[Auth] Local profile merge skipped: ${e.runtimeType}');
      }
      return false;
    }
  }

  Future<void> _onSignUp(
    AuthSignUpEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final trimmedSchool = event.schoolName.trim();
    final Map<String, dynamic> signupData = {
      'name': event.name,
      'username': event.username,
      'role': event.role,
      ...?event.metadata,
    };
    if (trimmedSchool.isNotEmpty) {
      signupData['school_name'] = trimmedSchool;
    } else {
      signupData.remove('school_name');
    }
    final result = await authRepository.signUpWithEmail(
      email: event.email,
      password: event.password,
      data: signupData,
    );

    if (result.isSuccess && result.user != null) {
      if (result.accessToken != null) {
        final needsCompletion = await _persistAuthProfile(result);
        AccountSession.notifySignedIn(result.user!.id);
        emit(Authenticated(
          user: result.user!,
          accessToken: result.accessToken!,
          backendNotice: result.backendNotice,
          profileNeedsCompletion:
              needsCompletion || result.profileNeedsCompletion,
        ));
      } else {
        // Signup succeeded but email confirmation is enabled: no session yet.
        emit(Unauthenticated(
          message: result.infoMessage ??
              'Account created. Please verify your email before signing in.',
        ));
      }
    } else {
      emit(AuthError(result.errorMessage ?? 'Registration failed'));
    }
  }

  Future<void> _onSignOut(
    AuthSignOutEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      // Terminates the Supabase session (supabase.auth.signOut) and clears
      // local session state. SQLite/Drift offline rows are KEPT on device
      // for later offline use but become inaccessible: repositories fail
      // safe without an authenticated owner, and AccountSession tells all
      // account-scoped BLoCs to drop cached state immediately.
      await authRepository.signOut();
      AccountSession.notifySignedOut();
    } catch (e) {
      // Never log session material: the runtime type is enough for diagnosis.
      if (kDebugMode) {
        debugPrint('[Auth] signOut failed: ${e.runtimeType}');
      }
      emit(const AuthError('Unable to log out. Please try again.'));
      return;
    }
    if (authRepository.isAuthenticated) {
      // The session is still active: do not pretend logout succeeded and do
      // not navigate away while authenticated.
      if (kDebugMode) {
        debugPrint('[Auth] signOut incomplete: session still active');
      }
      emit(const AuthError('Unable to log out. Please try again.'));
      return;
    }
    emit(const Unauthenticated());
  }

  Future<void> _onSessionRefreshed(
    AuthSessionRefreshedEvent event,
    Emitter<AuthState> emit,
  ) async {
    final token = await authRepository.refreshToken();
    final user = authRepository.currentUser;
    if (token != null && user != null) {
      emit(Authenticated(user: user, accessToken: token));
    } else {
      emit(const Unauthenticated(message: 'Your session has expired. Please sign in again.'));
    }
  }

  Future<void> _onStatusChanged(
    AuthStatusChangedEvent event,
    Emitter<AuthState> emit,
  ) async {
    if (event.isAuthenticated) {
      final token = await authRepository.getAccessToken() ??
          await authRepository.currentAccessToken() ??
          'offline-session';
      final user = authRepository.currentUser;
      if (user != null) {
        AccountSession.notifySignedIn(user.id);
        emit(Authenticated(user: user, accessToken: token));
        return;
      }
    }
    if (!authRepository.isAuthenticated && state is Authenticated) {
      AccountSession.notifySignedOut();
      emit(const Unauthenticated());
    }
  }

  Future<void> _onSendOtp(
    AuthSendOtpEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await authRepository.sendOtp(identifier: event.identifier);
    if (result.isSuccess) {
      final emailHint = (result.user?.metadata['email_hint'] as String?) ??
          (result.user?.email != null && result.user!.email.contains('@')
              ? '${result.user!.email[0]}***@${result.user!.email.split('@').last}'
              : 'your registered email');
      emit(AuthOtpSentState(
        identifier: event.identifier,
        emailHint: emailHint,
        rememberMe: event.rememberMe,
      ));
    } else {
      emit(AuthError(result.errorMessage ?? 'Failed to send OTP code.'));
    }
  }

  Future<void> _onVerifyOtp(
    AuthVerifyOtpEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await authRepository.verifyOtp(
      identifier: event.identifier,
      otp: event.otp,
      rememberMe: event.rememberMe,
    );

    if (result.isSuccess && result.user != null && result.accessToken != null) {
      AccountSession.notifySignedIn(result.user!.id);
      emit(Authenticated(
        user: result.user!,
        accessToken: result.accessToken!,
      ));
    } else {
      emit(AuthError(result.errorMessage ?? 'OTP verification failed.'));
    }
  }

  void _onResetLogin(
    AuthResetLoginEvent event,
    Emitter<AuthState> emit,
  ) {
    emit(AuthInitial());
  }

  @override
  Future<void> close() {
    _authSub?.cancel();
    return super.close();
  }
}
