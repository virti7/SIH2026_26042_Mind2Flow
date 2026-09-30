import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthUser;
import 'package:maatribhasha/core/config/api_config.dart';
import 'package:maatribhasha/core/config/supabase_config.dart';
import 'package:maatribhasha/core/auth/data/backend_profile_service.dart';
import 'package:maatribhasha/core/auth/domain/repositories/auth_repository.dart';

/// Email + password is the only teacher login credential. Usernames are
/// never used to resolve an identity before authentication.
bool isValidEmail(String value) {
  final v = value.trim();
  if (v.isEmpty || v.length > 254 || v.contains(' ')) return false;
  final parts = v.split('@');
  if (parts.length != 2) return false;
  if (parts[0].isEmpty || parts[1].isEmpty) return false;
  if (!parts[1].contains('.')) return false;
  return true;
}

/// True for transport-level failures (no `dart:io` import so this file
/// keeps compiling for Flutter Web).
bool isNetworkError(Object e) {
  if (e is TimeoutException) return true;
  final s = e.toString().toLowerCase();
  return s.contains('socket') ||
      s.contains('failed to fetch') ||
      s.contains('clientexception') ||
      s.contains('connection refused') ||
      s.contains('connection reset') ||
      s.contains('connection closed') ||
      s.contains('network is unreachable') ||
      s.contains('host lookup') ||
      s.contains('failed host lookup');
}

/// Supabase AuthException messages that mean the credentials are wrong.
/// Anything else (e.g. "Email not confirmed") is passed through to its own
/// dedicated mapping below — never converted into "Invalid email".
bool isInvalidCredentialsMessage(String message) {
  final m = message.toLowerCase();
  return m.contains('invalid login credentials') ||
      m.contains('invalid email or password') ||
      m.contains('invalid password');
}

/// Supabase AuthException messages that mean the account exists but the
/// email address has not been confirmed yet.
bool isEmailNotConfirmedMessage(String message) {
  final m = message.toLowerCase();
  return m.contains('email not confirmed') ||
      m.contains('not confirmed') ||
      m.contains('email confirmation') ||
      (m.contains('confirm') && m.contains('email'));
}

/// Supabase AuthException messages that mean the email is already registered.
bool isEmailAlreadyRegisteredMessage(String message) {
  final m = message.toLowerCase();
  return m.contains('already registered') ||
      m.contains('already exists') ||
      m.contains('already in use') ||
      m.contains('user already exists');
}

/// Redacts anything resembling key/token material from a log message and
/// truncates it. Never returns passwords, keys, or tokens verbatim.
String sanitizeAuthLogMessage(String message) {
  var out = message
      .replaceAll(
        RegExp(r'eyJ[A-Za-z0-9_-]*\.[A-Za-z0-9_-]*\.[A-Za-z0-9_-]*'),
        '[REDACTED_JWT]',
      )
      .replaceAll(
        RegExp(r'sb_(publishable|secret)_[A-Za-z0-9_-]+'),
        '[REDACTED_KEY]',
      )
      .replaceAll(
        RegExp(r'password\s*[:=]\s*\S+', caseSensitive: false),
        'password=[REDACTED]',
      );
  return out.length > 500 ? '${out.substring(0, 500)}…[truncated]' : out;
}

/// Classifies a Supabase Auth failure for developer diagnostics:
/// config_missing, invalid_credentials, email_exists, email_not_confirmed,
/// network_failure, tls_failure, http_error, timeout, or unexpected.
String classifySupabaseAuthCause(Object e) {
  if (e is AuthException) {
    if (isInvalidCredentialsMessage(e.message)) return 'invalid_credentials';
    if (isEmailAlreadyRegisteredMessage(e.message)) return 'email_exists';
    if (isEmailNotConfirmedMessage(e.message)) return 'email_not_confirmed';
    return 'http_error';
  }
  if (e is TimeoutException) return 'timeout';
  final s = e.toString().toLowerCase();
  if (s.contains('tls') ||
      s.contains('ssl') ||
      s.contains('certificate') ||
      s.contains('handshake')) {
    return 'tls_failure';
  }
  if (isNetworkError(e)) return 'network_failure';
  return 'unexpected';
}

/// Debug-only typed Supabase Auth error log. Production UI messages are
/// unaffected. Never logs keys, tokens, or passwords.
void logSupabaseAuthError(String operation, Object error) {
  if (!kDebugMode) return;
  final statusCode = error is AuthException ? error.statusCode : null;
  debugPrint(
    '[Auth] errorType=${error.runtimeType} '
    'cause=${classifySupabaseAuthCause(error)} '
    'statusCode=${statusCode ?? 'n/a'} '
    'requestTarget=supabase-auth '
    'operation=$operation',
  );
  debugPrint(
    '[Auth] message=${sanitizeAuthLogMessage(error.toString())}',
  );
}

class SupabaseAuthRepository implements AuthRepository {
  SupabaseClient? _client;
  final http.Client _httpClient;
  BackendProfileService? _backendProfiles;
  final StreamController<bool> _authStateController =
      StreamController<bool>.broadcast();
  bool _isInitialized = false;

  AuthMode _authMode = AuthMode.offline;

  /// Last post-authentication backend reconciliation outcome. Null when no
  /// Supabase sign-in/sign-up has completed yet in this process.
  BackendProfileOutcome? _lastBackendOutcome;

  /// Non-blocking backend status from the latest authentication, if any.
  BackendProfileOutcome? get lastBackendOutcome => _lastBackendOutcome;

  // Local development / fallback session when Supabase is not configured
  String? _devAccessToken;
  AuthUser? _devUser;
  final bool _autoDevLogin;
  bool _rememberMeCached = false;

  static const String _rememberMeKey = 'auth_remember_me';
  static const String _provisionedUserKey = 'auth_provisioned_user';

  SupabaseAuthRepository({
    SupabaseClient? client,
    http.Client? httpClient,
    bool? autoDevLogin,
  // ignore: prefer_initializing_formals
  })  : _client = client,
        _httpClient = httpClient ?? http.Client(),
        _autoDevLogin = autoDevLogin ??
            const bool.fromEnvironment('DEV_AUTO_LOGIN', defaultValue: false);

  @override
  AuthMode get authMode => _authMode;

  /// Dev-token login is strictly opt-in: only when explicitly enabled via
  /// `DEV_AUTO_LOGIN` / `autoDevLogin`, and never in release builds.
  /// Production APKs therefore can never take the dev-login path
  /// automatically — the normal Login button always uses Supabase
  /// email + password when Supabase is configured, and reports a
  /// connection error otherwise.
  bool get _devLoginEnabled => _autoDevLogin && !kReleaseMode;

  SupabaseClient get client {
    if (_client != null) return _client!;
    try {
      return Supabase.instance.client;
    } catch (_) {
      throw StateError('Supabase has not been initialized.');
    }
  }

  Future<String?> _fetchDevToken(String email) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/api/v1/auth/dev-token');
      final res = await _httpClient.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': 'dev-teacher-001',
          'email': email,
          'role': 'teacher',
        }),
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final token = data['access_token'] as String?;
        if (token != null && token.isNotEmpty) {
          _devAccessToken = token;
          _devUser = AuthUser(
            id: 'dev-teacher-001',
            email: email,
            username: email.contains('@') ? email.split('@').first : email,
            role: 'teacher',
            metadata: const {'role': 'teacher'},
          );
          _authStateController.add(true);
          return token;
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[SupabaseAuth] Dev token fetch skipped/failed: $e');
      }
    }
    return null;
  }

  @override
  Future<void> initialize() async {
    if (_isInitialized) return;

    _rememberMeCached = await getRememberMe();

    // Load locally provisioned user identity if remembered (for offline-first access)
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_rememberMeCached) {
        final userJson = prefs.getString(_provisionedUserKey);
        if (userJson != null) {
          final map = jsonDecode(userJson) as Map<String, dynamic>;
          _devUser = AuthUser(
            id: map['id'] ?? '',
            email: map['email'] ?? '',
            username: map['username'] ?? '',
            role: map['role'] ?? 'teacher',
            metadata: (map['metadata'] as Map<String, dynamic>?) ?? {},
          );
        }
      } else {
        await prefs.remove(_provisionedUserKey);
      }
    } catch (_) {}

    if (SupabaseConfig.isConfigured) {
      try {
        if (_client == null) {
          try {
            _client = Supabase.instance.client;
          } catch (_) {
            debugPrint('[Auth] Supabase initialization started');
            await Supabase.initialize(
              url: SupabaseConfig.url,
              anonKey: SupabaseConfig.anonKey,
              debug: kDebugMode,
            );
            _client = Supabase.instance.client;
            debugPrint('[Auth] Supabase initialization successful');
          }
        }

        _authMode = AuthMode.supabase;
        debugPrint('[Auth] mode=supabase');

        if (!_rememberMeCached && _client!.auth.currentSession != null) {
          try {
            await _client!.auth.signOut();
          } catch (_) {}
        }

        _client!.auth.onAuthStateChange.listen((data) {
          final hasValidSession = data.session != null &&
              (!data.session!.isExpired || _rememberMeCached);
          _authStateController.add(hasValidSession);
        });

        final currentValid = _client!.auth.currentSession != null &&
            (!_client!.auth.currentSession!.isExpired || _rememberMeCached);
        if (currentValid) {
          debugPrint('[Auth] Session restored');
        } else {
          debugPrint('[Auth] No Supabase session to restore');
        }
        _authStateController.add(currentValid);
        _isInitialized = true;
        return;
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[SupabaseAuth] Initialization warning: $e');
        }
      }
    }

    // Development auto-login mode: only activate when explicitly requested via
    // DEV_AUTO_LOGIN environment define or autoDevLogin: true in test fixtures.
    // Default is FALSE so unauthenticated teachers land on the visible Login screen.
    if (_autoDevLogin && !kReleaseMode) {
      final token = await _fetchDevToken('teacher@test.com');
      if (token != null && token.isNotEmpty) {
        _authMode = AuthMode.dev;
        debugPrint('[Auth] mode=dev (autoDevLogin)');
        _isInitialized = true;
        return;
      }
    }

    // Offline mode: if teacher was previously provisioned with Remember Me = ON,
    // preserve their offline workspace session. Otherwise unauthenticated.
    if (_rememberMeCached && _devUser != null) {
      _authMode = AuthMode.offline;
      debugPrint('[Auth] mode=offline (provisioned returning teacher)');
      _authStateController.add(true);
      _isInitialized = true;
      return;
    }

    // Completely offline mode: unauthenticated, generation disabled
    _authMode = AuthMode.offline;
    _devAccessToken = null;
    _devUser = null;
    debugPrint('[Auth] mode=offline (unauthenticated)');
    _authStateController.add(false);
    _isInitialized = true;
  }

  @override
  bool get isAuthenticated {
    if (_authMode == AuthMode.dev) {
      if (_devAccessToken != null && _devAccessToken!.isNotEmpty) return true;
      return _rememberMeCached && _devUser != null;
    }
    if (_authMode == AuthMode.supabase && _client != null) {
      try {
        final session = _client!.auth.currentSession;
        if (session != null) {
          return !session.isExpired || _rememberMeCached;
        }
        return _rememberMeCached && (_client!.auth.currentUser != null || _devUser != null);
      } catch (_) {
        return _rememberMeCached && _devUser != null;
      }
    }
    if (_authMode == AuthMode.offline) {
      return _rememberMeCached && _devUser != null;
    }
    return false;
  }

  @override
  String? get currentUserId => currentUser?.id;

  @override
  String? get currentUserEmail => currentUser?.email;

  @override
  AuthUser? get currentUser {
    if (_authMode == AuthMode.dev || _authMode == AuthMode.offline) {
      return _devUser;
    }
    if (_authMode == AuthMode.supabase && _client != null) {
      try {
        final user = _client!.auth.currentUser;
        if (user != null) {
          final metadata = user.userMetadata ?? {};
          final role = (metadata['role'] as String?) ?? 'teacher';
          final username = (metadata['username'] as String?) ?? '';
          return AuthUser(
            id: user.id,
            email: user.email ?? '',
            username: username,
            role: role,
            metadata: metadata,
          );
        }
        return _devUser;
      } catch (_) {
        return _devUser;
      }
    }
    return _devUser;
  }

  @override
  Stream<bool> get authStateChanges => _authStateController.stream;

  @override
  Future<String?> currentAccessToken() async {
    if (_authMode == AuthMode.dev) {
      return _devAccessToken;
    }
    if (_authMode == AuthMode.supabase && _client != null) {
      try {
        final session = _client!.auth.currentSession;
        if (session != null && !session.isExpired) {
          return session.accessToken;
        }
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  @override
  Future<String?> getAccessToken() async {
    if (_authMode == AuthMode.dev) {
      if (_devAccessToken != null && _devAccessToken!.isNotEmpty) {
        return _devAccessToken;
      }
      return await _fetchDevToken('teacher@test.com');
    }
    if (_authMode == AuthMode.supabase && _client != null) {
      try {
        final session = _client!.auth.currentSession;
        if (session == null) return null;
        if (session.isExpired) {
          return await refreshToken();
        }
        return session.accessToken;
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  @override
  Future<String?> refreshToken() async {
    if (_authMode == AuthMode.supabase && _client != null) {
      try {
        final response = await _client!.auth.refreshSession();
        final newSession = response.session;
        if (newSession != null) {
          _authStateController.add(true);
          return newSession.accessToken;
        }
        _authStateController.add(false);
        return null;
      } on AuthException catch (e) {
        if (kDebugMode) {
          debugPrint('[SupabaseAuth] Token refresh auth rejection: $e');
        }
        _authStateController.add(false);
        return null;
      } catch (e) {
        // Network or offline error: keep local session intact, do NOT log out offline teacher
        if (kDebugMode) {
          debugPrint('[SupabaseAuth] Token refresh network/offline error: $e');
        }
        return null;
      }
    }

    if (_authMode == AuthMode.dev) {
      final email = _devUser?.email ?? 'teacher@test.com';
      return await _fetchDevToken(email);
    }

    // Offline / uninitialized: do NOT attempt Supabase refresh
    return null;
  }

  @override
  Future<bool> getRememberMe() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_rememberMeKey) ?? false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> setRememberMe(bool value) async {
    _rememberMeCached = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_rememberMeKey, value);
      if (!value) {
        await prefs.remove(_provisionedUserKey);
      }
    } catch (_) {}
  }

  /// Legacy profile-field helper kept for backward compatibility.
  /// Username is an OPTIONAL teacher profile field and is NEVER part of the
  /// email + password authentication path (login/signup never call this).
  @override
  Future<bool> checkUsernameAvailable(String username) async {
    final trimmed = username.trim().toLowerCase();
    if (trimmed.isEmpty) return false;
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/api/v1/auth/check-username');
      final res = await _httpClient.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': trimmed}),
      ).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        return data['available'] == true;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[SupabaseAuth] checkUsername error: $e');
      }
    }
    return true; // Fallback so offline/unreachable doesn't block registration
  }

  @override
  Future<bool> registerTeacherProfile({
    required String userId,
    required String username,
    required String name,
    required String email,
  }) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/api/v1/auth/register-teacher');
      final cleanUsername = username.trim().toLowerCase();
      final res = await _httpClient.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId.trim(),
          // username stays nullable server-side; omit when not provided.
          'username': cleanUsername.isEmpty ? null : cleanUsername,
          'name': name.trim(),
          'email': email.trim().toLowerCase(),
        }),
      ).timeout(const Duration(seconds: 10));
      return res.statusCode == 200;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[SupabaseAuth] registerTeacherProfile error: $e');
      }
      return false;
    }
  }

  String _obscureEmail(String email) {
    if (!email.contains('@')) return email;
    final parts = email.split('@');
    final user = parts[0];
    final domain = parts[1];
    if (user.length <= 2) {
      return '${user[0]}***@$domain';
    }
    return '${user[0]}***${user[user.length - 1]}@$domain';
  }

  @override
  Future<AuthSessionResult> sendOtp({required String identifier}) async {
    final targetEmail = identifier.trim().toLowerCase();
    if (!isValidEmail(targetEmail)) {
      return const AuthSessionResult.failure(
          'Please enter a valid email address.');
    }

    final emailHint = _obscureEmail(targetEmail);

    if (_authMode != AuthMode.supabase) {
      if (!_devLoginEnabled) {
        return const AuthSessionResult.failure('Unable to connect to server');
      }
      return AuthSessionResult.success(
        user: AuthUser(
          id: 'dev-teacher-001',
          email: targetEmail,
          username: targetEmail.split('@').first,
          role: 'teacher',
          metadata: {'email_hint': emailHint},
        ),
        accessToken: 'dev-otp-sent',
      );
    }

    try {
      await client.auth.signInWithOtp(
        email: targetEmail,
        shouldCreateUser: false,
      );
      return AuthSessionResult.success(
        user: AuthUser(
          id: '',
          email: targetEmail,
          username: targetEmail.split('@').first,
          role: 'teacher',
          metadata: {'email_hint': emailHint},
        ),
        accessToken: 'otp-sent',
      );
    } on AuthException catch (e) {
      if (isInvalidCredentialsMessage(e.message)) {
        return const AuthSessionResult.failure('Invalid email or password');
      }
      return AuthSessionResult.failure(e.message);
    } catch (e) {
      if (isNetworkError(e)) {
        return const AuthSessionResult.failure('Unable to connect to server');
      }
      return const AuthSessionResult.failure(
        'Unable to connect. Please check your internet connection.',
      );
    }
  }

  @override
  Future<AuthSessionResult> verifyOtp({
    required String identifier,
    required String otp,
    bool rememberMe = false,
  }) async {
    final trimmedOtp = otp.trim();
    if (trimmedOtp.isEmpty) {
      return const AuthSessionResult.failure('Please enter the OTP code.');
    }

    final targetEmail = identifier.trim().toLowerCase();
    if (!isValidEmail(targetEmail)) {
      return const AuthSessionResult.failure(
          'Please enter a valid email address.');
    }

    if (_authMode != AuthMode.supabase) {
      if (!_devLoginEnabled) {
        return const AuthSessionResult.failure('Unable to connect to server');
      }
      if (trimmedOtp == 'invalid') {
        return const AuthSessionResult.failure('Invalid OTP code. Please check and try again.');
      }
      if (trimmedOtp == 'expired') {
        return const AuthSessionResult.failure('OTP has expired. Please request a new code.');
      }
      final token = await _fetchDevToken(targetEmail);
      if (token != null && _devUser != null) {
        _authMode = AuthMode.dev;
        await setRememberMe(rememberMe);
        return AuthSessionResult.success(
          user: _devUser!,
          accessToken: token,
        );
      }
      return const AuthSessionResult.failure('Unable to connect to server');
    }

    try {
      final res = await client.auth.verifyOTP(
        email: targetEmail,
        token: trimmedOtp,
        type: OtpType.email,
      );
      final session = res.session;
      final user = res.user;

      if (session == null || user == null) {
        return const AuthSessionResult.failure(
          'Verification failed: no active session returned.',
        );
      }

      final metadata = user.userMetadata ?? {};
      final resolvedUsername = (metadata['username'] as String?) ??
          (user.email?.split('@').first ?? '');

      final authUser = AuthUser(
        id: user.id,
        email: user.email ?? targetEmail,
        username: resolvedUsername,
        role: (metadata['role'] as String?) ?? 'teacher',
        metadata: metadata,
      );

      await setRememberMe(rememberMe);
      _authStateController.add(true);
      return AuthSessionResult.success(
        user: authUser,
        accessToken: session.accessToken,
      );
    } on AuthException catch (e) {
      final msg = e.message.toLowerCase();
      if (msg.contains('expired')) {
        return const AuthSessionResult.failure('OTP has expired. Please request a new code.');
      } else if (msg.contains('invalid') || msg.contains('token')) {
        return const AuthSessionResult.failure('Invalid OTP code. Please check and try again.');
      }
      return AuthSessionResult.failure(e.message);
    } catch (e) {
      return const AuthSessionResult.failure(
        'Unable to connect. Please check your internet connection.',
      );
    }
  }

  /// Email + password login.
  ///
  /// Flow: `Supabase signInWithPassword` → authenticated. No username
  /// resolution, no `/auth/check-username`, no teachers lookup before
  /// authentication, and no FastAPI prerequisite for login success.
  ///
  /// AFTER Supabase reports success, the FastAPI backend profile is
  /// reconciled on a strictly non-blocking basis (see
  /// [BackendProfileService]): a backend failure keeps the authenticated
  /// Supabase session and only attaches an offline notice.
  @override
  Future<AuthSessionResult> signInWithEmail({
    required String email,
    required String password,
    bool rememberMe = false,
    String? schoolName,
  }) async {
    final effectiveEmail = email.trim().toLowerCase();
    if (!isValidEmail(effectiveEmail)) {
      return const AuthSessionResult.failure(
          'Please enter a valid email address.');
    }
    if (kDebugMode) {
      debugPrint('[Auth] Supabase sign-in started for ${_obscureEmail(effectiveEmail)}');
    }

    // Not in Supabase mode (build has no Supabase URL/key, or client
    // init failed): the normal Login button must never fall back to a
    // dev-login endpoint in production. Dev login runs only when the
    // dev-only flag explicitly enables it.
    if (_authMode != AuthMode.supabase) {
      if (!_devLoginEnabled) {
        // Missing build configuration is a developer/build error, not an
        // internet problem: surface it explicitly so logcat/APK diagnosis
        // does not chase the device network.
        if (!SupabaseConfig.isConfigured) {
          if (kDebugMode) {
            debugPrint(
              '[Auth] errorType=SupabaseConfig cause=config_missing '
              'statusCode=n/a requestTarget=supabase-auth operation=signIn',
            );
          }
          return const AuthSessionResult.failure(
            SupabaseConfig.missingConfigMessage,
          );
        }
        return const AuthSessionResult.failure(
          'Unable to connect to authentication service. Check your internet connection.',
        );
      }
      final token = await _fetchDevToken(effectiveEmail);
      if (token != null && _devUser != null) {
        _authMode = AuthMode.dev;
        await setRememberMe(rememberMe);
        if (rememberMe) {
          try {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString(_provisionedUserKey, jsonEncode({
              'id': _devUser!.id,
              'email': _devUser!.email,
              'username': _devUser!.username,
              'role': _devUser!.role,
              'metadata': _devUser!.metadata,
            }));
          } catch (_) {}
        }
        return AuthSessionResult.success(
          user: _devUser!,
          accessToken: token,
        );
      }
      return const AuthSessionResult.failure(
        'Unable to connect to authentication service. Check your internet connection.',
      );
    }
    try {
      final res = await client.auth
          .signInWithPassword(
            email: effectiveEmail,
            password: password,
          )
          .timeout(const Duration(seconds: 15));
      final session = res.session;
      final user = res.user;

      if (session == null || user == null) {
        return const AuthSessionResult.failure(
          'Sign in failed: no active session returned.',
        );
      }
      if (kDebugMode) {
        debugPrint('[Auth] Supabase sign-in successful');
      }

      // Non-blocking backend reconciliation with the authenticated
      // Supabase user id. Never fails the login. The school name falls back
      // to the on-device value (e.g. completed locally) so older accounts
      // propagate it to the server profile when it is missing there.
      final metaSchool =
          (user.userMetadata?['school_name'] as String?)?.trim() ?? '';
      final fallbackSchool = (schoolName ?? '').trim();
      final backendOutcome = await _reconcileBackend(
        accessToken: session.accessToken,
        userId: user.id,
        email: user.email ?? effectiveEmail,
        name: (user.userMetadata?['name'] as String?) ??
            (user.userMetadata?['full_name'] as String?) ??
            '',
        username: user.userMetadata?['username'] as String?,
        schoolName:
            metaSchool.isNotEmpty ? metaSchool : fallbackSchool,
      );

      final metadata = user.userMetadata ?? {};
      final resolvedUsername = (metadata['username'] as String?) ??
          (user.email?.split('@').first ?? '');
      final authUser = AuthUser(
        id: user.id,
        email: user.email ?? effectiveEmail,
        username: resolvedUsername,
        role: (metadata['role'] as String?) ?? 'teacher',
        metadata: metadata,
      );

      await setRememberMe(rememberMe);
      if (rememberMe) {
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_provisionedUserKey, jsonEncode({
            'id': authUser.id,
            'email': authUser.email,
            'username': authUser.username,
            'role': authUser.role,
            'metadata': authUser.metadata,
          }));
        } catch (_) {}
      }
      _authStateController.add(true);
      return AuthSessionResult.success(
        user: authUser,
        accessToken: session.accessToken,
        backendUnavailable: backendOutcome.backendUnavailable,
        backendNotice: backendOutcome.notice,
        profileNeedsCompletion: backendOutcome.profileNeedsCompletion,
        serverName: backendOutcome.serverName,
        serverSchoolName: backendOutcome.serverSchoolName,
      );
    } on AuthException catch (e) {
      if (isInvalidCredentialsMessage(e.message)) {
        return const AuthSessionResult.failure('Invalid email or password');
      }
      if (isEmailNotConfirmedMessage(e.message)) {
        return const AuthSessionResult.failure(
          'Please verify your email before signing in.',
        );
      }
      return AuthSessionResult.failure(e.message);
    } catch (e) {
      logSupabaseAuthError('signIn', e);
      if (isNetworkError(e)) {
        return const AuthSessionResult.failure(
          'Unable to connect to authentication service. Check your internet connection.',
        );
      }
      return const AuthSessionResult.failure(
        'Sign in failed. Please try again.',
      );
    }
  }

  /// Best-effort post-authentication backend reconciliation. Never throws:
  /// any unexpected error degrades to "backend unavailable" so the
  /// authenticated Supabase session is always preserved.
  Future<BackendProfileOutcome> _reconcileBackend({
    required String accessToken,
    required String userId,
    required String email,
    required String name,
    String? username,
    String? schoolName,
  }) async {
    try {
      _backendProfiles ??= BackendProfileService(httpClient: _httpClient);
      final outcome = await _backendProfiles!.reconcileAfterAuth(
        accessToken: accessToken,
        userId: userId,
        email: email,
        name: name,
        username: username,
        schoolName: schoolName,
      );
      _lastBackendOutcome = outcome;
      return outcome;
    } catch (_) {
      const fallback = BackendProfileOutcome.unavailable();
      _lastBackendOutcome = fallback;
      return fallback;
    }
  }

  @override
  Future<AuthSessionResult> signUpWithEmail({
    required String email,
    required String password,
    Map<String, dynamic>? data,
  }) async {
    if (!isValidEmail(email.trim())) {
      return const AuthSessionResult.failure(
          'Please enter a valid email address.');
    }
    final name = (data?['name'] as String?)?.trim();
    final resolvedName =
        (name != null && name.isNotEmpty) ? name : 'Teacher';
    // username is optional and never required for authentication.
    final username = (data?['username'] as String?)?.trim() ?? '';
    final schoolName = (data?['school_name'] as String?)?.trim() ?? '';

    final sanitizedData = {
      'name': resolvedName,
      'full_name': resolvedName,
      ...?data,
      'role': 'teacher', // Enforce default teacher role
    };
    if (schoolName.isNotEmpty) {
      sanitizedData['school_name'] = schoolName;
    } else {
      sanitizedData.remove('school_name');
    }
    if (username.isNotEmpty) {
      sanitizedData['username'] = username;
    } else {
      sanitizedData.remove('username');
    }

    if (_authMode != AuthMode.supabase) {
      if (!_devLoginEnabled) {
        if (!SupabaseConfig.isConfigured) {
          if (kDebugMode) {
            debugPrint(
              '[Auth] errorType=SupabaseConfig cause=config_missing '
              'statusCode=n/a requestTarget=supabase-auth operation=signUp',
            );
          }
          return const AuthSessionResult.failure(
            SupabaseConfig.missingConfigMessage,
          );
        }
        return const AuthSessionResult.failure(
          'Unable to connect to authentication service. Check your internet connection.',
        );
      }
      final token = await _fetchDevToken(email.trim());
      final authUser = AuthUser(
        id: 'dev-teacher-001',
        email: email,
        username: username,
        role: 'teacher',
        metadata: sanitizedData,
      );
      if (token != null) {
        _authMode = AuthMode.dev;
      }
      await registerTeacherProfile(
        userId: 'dev-teacher-001',
        username: username,
        name: resolvedName,
        email: email.trim(),
      );
      return AuthSessionResult.success(
        user: authUser,
        accessToken: token,
      );
    }
    if (kDebugMode) {
      debugPrint('[Auth] Supabase sign-up started for ${_obscureEmail(email.trim().toLowerCase())}');
    }
    try {
      final res = await client.auth.signUp(
        email: email.trim(),
        password: password,
        data: sanitizedData,
      );
      final user = res.user;
      final session = res.session;

      if (user == null) {
        return const AuthSessionResult.failure('Registration failed.');
      }
      if (kDebugMode) {
        debugPrint('[Auth] Supabase sign-up successful');
      }

      final authUser = AuthUser(
        id: user.id,
        email: user.email ?? email,
        username: username,
        role: 'teacher',
        metadata: sanitizedData,
      );

      // Email confirmation enabled: Supabase returns a user but no session.
      // Authentication itself succeeded; the teacher signs in after verifying.
      if (session == null) {
        if (kDebugMode) {
          debugPrint('[Auth] Sign-up email confirmation required');
        }
        return AuthSessionResult.success(
          user: authUser,
          accessToken: null,
          infoMessage:
              'Account created. Please verify your email before signing in.',
        );
      }

      // Link the teacher profile to the authenticated Supabase user id on a
      // strictly non-blocking basis: backend failure never fails the signup.
      if (kDebugMode) {
        debugPrint('[Auth] Teacher profile linking started');
      }
      final backendOutcome = await _reconcileBackend(
        accessToken: session.accessToken,
        userId: user.id,
        username: username,
        name: resolvedName,
        schoolName: schoolName,
        email: user.email ?? email,
      );

      _authStateController.add(true);
      return AuthSessionResult.success(
        user: authUser,
        accessToken: session.accessToken,
        backendUnavailable: backendOutcome.backendUnavailable,
        backendNotice: backendOutcome.notice,
        profileNeedsCompletion: backendOutcome.profileNeedsCompletion,
        serverName: backendOutcome.serverName,
        serverSchoolName: backendOutcome.serverSchoolName,
      );
    } on AuthException catch (e) {
      if (isEmailAlreadyRegisteredMessage(e.message)) {
        return const AuthSessionResult.failure(
          'An account with this email already exists.',
        );
      }
      if (isInvalidCredentialsMessage(e.message)) {
        return const AuthSessionResult.failure('Invalid email or password');
      }
      return AuthSessionResult.failure(e.message);
    } catch (e) {
      logSupabaseAuthError('signUp', e);
      if (isNetworkError(e)) {
        return const AuthSessionResult.failure(
          'Unable to connect to authentication service. Check your internet connection.',
        );
      }
      return const AuthSessionResult.failure('Registration error. Please try again.');
    }
  }

  @override
  Future<void> signOut() async {
    if (kDebugMode) {
      debugPrint('[Auth] Logout started');
    }
    _lastBackendOutcome = null;
    _devAccessToken = null;
    _devUser = null;
    _rememberMeCached = false;
    await setRememberMe(false);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_provisionedUserKey);
    } catch (_) {}
    if (_authMode == AuthMode.supabase && _client != null) {
      try {
        await _client!.auth.signOut();
      } catch (_) {}
    }
    _authStateController.add(false);
  }
}
