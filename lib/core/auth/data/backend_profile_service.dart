import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:maatribhasha/core/config/api_config.dart';

/// Non-blocking notice shown when FastAPI cannot be reached AFTER a
/// successful Supabase authentication. The Supabase session stays valid.
const String kBackendOfflineNotice =
    'Server unavailable. You are signed in and can continue offline.';

/// Shown when authentication succeeded but no teacher profile exists yet
/// for the authenticated Supabase user id.
const String kProfileNeedsCompletionNotice =
    'Teacher profile needs to be completed.';

/// Outcome of the post-authentication backend reconciliation.
///
/// FastAPI is a separate cloud/backend layer used AFTER authentication.
/// A backend failure here must NEVER be converted into an authentication
/// failure, a sign-out, or a navigation back to Login.
class BackendProfileOutcome extends Object {
  /// Backend profile is available (GET /me 200, or created via
  /// register-teacher after a 404). No notice needed.
  final bool ok;

  /// Backend could not be reached (network/timeout/5xx). The teacher stays
  /// authenticated and can continue with local SQLite/Drift data.
  final bool backendUnavailable;

  /// Backend reachable but no teacher profile exists for the authenticated
  /// Supabase user id and creation did not succeed.
  final bool profileNeedsCompletion;

  /// Human-readable notice for [backendUnavailable]/[profileNeedsCompletion].
  final String? notice;

  /// Freshest server-side teacher identity seen during reconciliation
  /// (`teacher_name` / `school_name` from `/me` or `register-teacher`).
  /// Null when the backend was unreachable or returned no profile.
  final String? serverName;
  final String? serverSchoolName;

  const BackendProfileOutcome._({
    required this.ok,
    required this.backendUnavailable,
    required this.profileNeedsCompletion,
    this.notice,
    this.serverName,
    this.serverSchoolName,
  });

  const BackendProfileOutcome.ok({String? serverName, String? serverSchoolName})
      : this._(
          ok: true,
          backendUnavailable: false,
          profileNeedsCompletion: false,
          serverName: serverName,
          serverSchoolName: serverSchoolName,
        );

  const BackendProfileOutcome.unavailable([String? notice]) : this._(
    ok: false,
    backendUnavailable: true,
    profileNeedsCompletion: false,
    notice: notice ?? kBackendOfflineNotice,
  );

  const BackendProfileOutcome.missingProfile([String? notice]) : this._(
    ok: false,
    backendUnavailable: false,
    profileNeedsCompletion: true,
    notice: notice ?? kProfileNeedsCompletionNotice,
  );
}

/// Reconciles the server-side teacher profile AFTER Supabase authentication
/// has already succeeded.
///
/// Canonical identity is `auth.users.id` (the Supabase user id). The
/// username column remains optional and is never used for authentication.
///
/// Flow:
/// 1. `GET /api/v1/me` with the Supabase JWT.
/// 2. On 200 → ok.
/// 3. On 404 → create the profile once via `POST /api/v1/auth/register-teacher`
///    with the authenticated Supabase user id (upsert: no duplicate rows),
///    then accept the session regardless.
/// 4. On network failure / timeout / 5xx → [BackendProfileOutcome.unavailable].
///    The caller keeps the authenticated session and continues offline.
///
/// This service never touches username resolution (`check-username`,
/// `resolve-identifier`) or dev-token issuance.
class BackendProfileService {
  final http.Client _httpClient;
  final String _baseUrl;
  final Duration timeout;

  BackendProfileService({
    http.Client? httpClient,
    String? baseUrl,
    this.timeout = const Duration(seconds: 10),
  })  : _httpClient = httpClient ?? http.Client(),
        _baseUrl = (baseUrl ?? ApiConfig.baseUrl).replaceAll(
          RegExp(r'/$'),
          '',
        );

  /// Base URL actually used, for development-safe diagnostics (no secrets).
  String get baseUrl => _baseUrl;

  Future<BackendProfileOutcome> reconcileAfterAuth({
    required String accessToken,
    required String userId,
    required String email,
    required String name,
    String? username,
    String? schoolName,
  }) async {
    if (kDebugMode) {
      debugPrint('[Auth] Backend profile request started ${ApiConfig.describe()}');
    }
    final meBody = await _getMeBody(accessToken);
    if (meBody == null) {
      if (kDebugMode) {
        debugPrint('[Auth] Backend unavailable; keeping authenticated session');
      }
      return const BackendProfileOutcome.unavailable();
    }
    if (meBody['status'] == 200) {
      if (kDebugMode) {
        debugPrint('[Auth] Teacher profile loaded for authenticated user');
      }
      return BackendProfileOutcome.ok(
        serverName: _profileString(meBody['body'], 'teacher_name'),
        serverSchoolName: _profileString(meBody['body'], 'school_name'),
      );
    }
    if (meBody['status'] != 404) {
      // Any other status (401/403/5xx/...) is a backend-layer outcome, not
      // an authentication failure: keep the Supabase session and continue
      // offline.
      if (kDebugMode) {
        debugPrint('[Auth] Backend returned HTTP ${meBody['status']}; '
            'keeping authenticated session');
      }
      return const BackendProfileOutcome.unavailable();
    }
    // 404: self-heal once by provisioning the teacher profile for the
    // authenticated Supabase user id, then re-read /me to confirm.
    if (kDebugMode) {
      debugPrint('[Auth] Teacher profile provisioning started');
    }
    final provisionBody = await _registerTeacher(
      accessToken: accessToken,
      userId: userId,
      username: username,
      name: name.isNotEmpty ? name : email.split('@').first,
      schoolName: schoolName,
      email: email,
    );
    if (provisionBody == null) {
      if (kDebugMode) {
        debugPrint('[Auth] Teacher profile missing for authenticated user; '
            'keeping authenticated session');
      }
      return const BackendProfileOutcome.missingProfile();
    }
    final retryBody = await _getMeBody(accessToken);
    if (retryBody != null && retryBody['status'] == 200) {
      if (kDebugMode) {
        debugPrint('[Auth] Teacher profile provisioned and verified');
      }
      return BackendProfileOutcome.ok(
        serverName: _profileString(retryBody['body'], 'teacher_name'),
        serverSchoolName: _profileString(retryBody['body'], 'school_name'),
      );
    }
    if (retryBody == null) {
      if (kDebugMode) {
        debugPrint('[Auth] Backend unavailable; keeping authenticated session');
      }
      return const BackendProfileOutcome.unavailable();
    }
    if (kDebugMode) {
      debugPrint('[Auth] Teacher profile missing for authenticated user; '
          'keeping authenticated session');
    }
    return const BackendProfileOutcome.missingProfile();
  }

  /// Reads `GET /api/v1/me`: returns `{'status': int, 'body': decoded JSON?}`,
  /// or null when the backend could not be reached at all
  /// (network failure / timeout).
  Future<Map<String, dynamic>?> _getMeBody(String accessToken) async {
    try {
      final res = await _httpClient.get(
        Uri.parse('$_baseUrl/api/v1/me'),
        headers: {'Authorization': 'Bearer $accessToken'},
      ).timeout(timeout);
      dynamic body;
      try {
        body = jsonDecode(res.body);
      } catch (_) {
        body = null;
      }
      return {'status': res.statusCode, 'body': body};
    } on TimeoutException {
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Extracts a trimmed, non-empty profile string from a decoded `/me` or
  /// `register-teacher` body. Returns null when absent — never invents values.
  String? _profileString(dynamic body, String key) {
    if (body is Map<String, dynamic>) {
      final v = body[key];
      if (v is String && v.trim().isNotEmpty) return v.trim();
    }
    return null;
  }

  /// Provisions (server-side upsert keyed by the Supabase user id) the
  /// teacher profile for the authenticated user. The Supabase JWT is sent
  /// so the backend derives identity from the token — never from a forged
  /// client-supplied id. Returns the decoded response body on HTTP 200,
  /// null otherwise. Never throws and never logs tokens.
  Future<Map<String, dynamic>?> _registerTeacher({
    required String accessToken,
    required String userId,
    String? username,
    required String name,
    String? schoolName,
    required String email,
  }) async {
    try {
      final cleanUsername = (username ?? '').trim().toLowerCase();
      final cleanSchool = (schoolName ?? '').trim();
      final res = await _httpClient.post(
        Uri.parse('$_baseUrl/api/v1/auth/register-teacher'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({
          'user_id': userId.trim(),
          'username': cleanUsername.isEmpty ? null : cleanUsername,
          'name': name.trim(),
          'school_name': cleanSchool.isEmpty ? null : cleanSchool,
          'email': email.trim().toLowerCase(),
        }),
      ).timeout(timeout);
      if (kDebugMode) {
        debugPrint(
            '[Auth] Teacher profile provisioning finished status=${res.statusCode}');
      }
      if (res.statusCode != 200) return null;
      try {
        final body = jsonDecode(res.body);
        return body is Map<String, dynamic> ? body : <String, dynamic>{};
      } catch (_) {
        return <String, dynamic>{};
      }
    } catch (_) {
      return null;
    }
  }
}
