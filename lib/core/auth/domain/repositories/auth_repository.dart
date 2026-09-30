import 'package:equatable/equatable.dart';

class AuthUser extends Equatable {
  final String id;
  final String email;
  final String username;
  final String role;
  final Map<String, dynamic> metadata;

  const AuthUser({
    required this.id,
    required this.email,
    this.username = '',
    this.role = 'teacher',
    this.metadata = const {},
  });

  @override
  List<Object?> get props => [id, email, username, role, metadata];
}

class AuthSessionResult extends Equatable {
  final AuthUser? user;
  final String? accessToken;
  final String? errorMessage;
  final bool isSuccess;

  /// True when Supabase authentication succeeded but the FastAPI backend
  /// could not be reached afterwards. The Supabase session stays valid and
  /// the teacher can continue offline. Never treated as an auth failure.
  final bool backendUnavailable;

  /// Non-blocking notice for [backendUnavailable] (or profile completion),
  /// e.g. "Server unavailable. You are signed in and can continue offline."
  final String? backendNotice;

  /// True when authentication succeeded but no teacher profile exists yet
  /// for the authenticated Supabase user id.
  final bool profileNeedsCompletion;

  /// Informational message for successful results without a session
  /// (e.g. signup with email confirmation enabled).
  final String? infoMessage;

  /// Freshest server-side teacher identity observed during the
  /// post-authentication reconciliation (`teacher_name` / `school_name`
  /// from `/me` or `register-teacher`). Null when the backend was
  /// unreachable or returned no profile.
  final String? serverName;
  final String? serverSchoolName;

  const AuthSessionResult.success({
    required this.user,
    required this.accessToken,
    this.backendUnavailable = false,
    this.backendNotice,
    this.profileNeedsCompletion = false,
    this.infoMessage,
    this.serverName,
    this.serverSchoolName,
  })  : isSuccess = true,
        errorMessage = null;

  const AuthSessionResult.failure(this.errorMessage)
      : isSuccess = false,
        user = null,
        accessToken = null,
        backendUnavailable = false,
        backendNotice = null,
        profileNeedsCompletion = false,
        infoMessage = null,
        serverName = null,
        serverSchoolName = null;

  @override
  List<Object?> get props => [
        user,
        accessToken,
        errorMessage,
        isSuccess,
        backendUnavailable,
        backendNotice,
        profileNeedsCompletion,
        infoMessage,
        serverName,
        serverSchoolName,
      ];
}

/// Authentication runtime mode
enum AuthMode {
  supabase,
  dev,
  offline,
}

abstract class AuthRepository {
  Future<void> initialize();

  AuthMode get authMode;

  Future<AuthSessionResult> sendOtp({
    required String identifier,
  });

  Future<AuthSessionResult> verifyOtp({
    required String identifier,
    required String otp,
    bool rememberMe = false,
  });

  Future<AuthSessionResult> signInWithEmail({
    required String email,
    required String password,
    bool rememberMe = false,
    // Optional local fallback (e.g. school name completed on-device) sent
    // with profile provisioning when the server profile is missing.
    // Never an authentication credential; may be omitted by fakes.
    String? schoolName,
  });

  Future<AuthSessionResult> signUpWithEmail({
    required String email,
    required String password,
    Map<String, dynamic>? data,
  });

  Future<void> signOut();

  /// Returns the current active session or dev access token.
  Future<String?> currentAccessToken();

  Future<String?> getAccessToken();

  Future<String?> refreshToken();

  Stream<bool> get authStateChanges;

  bool get isAuthenticated;

  String? get currentUserId;

  String? get currentUserEmail;

  AuthUser? get currentUser;

  Future<bool> getRememberMe();

  Future<void> setRememberMe(bool value);

  /// Legacy helper: username is an optional teacher profile field and is
  /// NEVER part of the email + password authentication path.
  Future<bool> checkUsernameAvailable(String username);

  /// Links the teacher profile to the canonical Supabase identity
  /// (`auth.users.id` passed as [userId]). Server-side upsert: never
  /// creates duplicate rows for the same user id.
  Future<bool> registerTeacherProfile({
    required String userId,
    required String username,
    required String name,
    required String email,
  });
}
