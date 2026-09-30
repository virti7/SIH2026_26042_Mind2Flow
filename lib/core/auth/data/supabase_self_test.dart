import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:maatribhasha/core/config/supabase_config.dart';

/// Result of the development-only Supabase auth self-test.
///
/// Read-only: performs a single unauthenticated `GET /auth/v1/health`
/// against the configured Supabase Auth endpoint. Never signs in, never
/// creates users, never modifies data, and never sends or logs credentials.
class SupabaseSelfTestResult {
  /// `Supabase.instance.client` is reachable (i.e. `Supabase.initialize`
  /// ran in this process).
  final bool clientInitialized;

  /// A real (non-placeholder) `SUPABASE_URL`/`SUPABASE_ANON_KEY` pair was
  /// compiled into this build.
  final bool urlConfigured;

  /// Hostname only — no secrets.
  final String urlHost;

  /// The public Auth health endpoint answered.
  final bool endpointReachable;

  /// HTTP status of the health probe, or null when unreachable.
  final int? endpointStatus;

  /// Whether a Supabase session already exists (informational only).
  final bool sessionPresent;

  /// Short, secret-free failure reason when [endpointReachable] is false.
  final String? error;

  const SupabaseSelfTestResult({
    required this.clientInitialized,
    required this.urlConfigured,
    required this.urlHost,
    required this.endpointReachable,
    this.endpointStatus,
    required this.sessionPresent,
    this.error,
  });
}

/// Development-only diagnostic probe for Supabase Auth reachability.
///
/// Use from debug builds at startup to answer "can this device talk to
/// Supabase Auth at all?" independently of login credentials, FastAPI,
/// and the offline SQLite/Drift stack.
class SupabaseAuthSelfTest {
  SupabaseAuthSelfTest._();

  static Future<SupabaseSelfTestResult> run({
    http.Client? httpClient,
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final configured = SupabaseConfig.isConfigured;
    final host = SupabaseConfig.urlHost;

    bool clientInitialized = false;
    bool sessionPresent = false;
    if (configured) {
      try {
        final client = Supabase.instance.client;
        clientInitialized = true;
        sessionPresent = client.auth.currentSession != null;
      } catch (_) {
        clientInitialized = false;
      }
    }

    if (!configured) {
      return SupabaseSelfTestResult(
        clientInitialized: clientInitialized,
        urlConfigured: false,
        urlHost: host,
        endpointReachable: false,
        sessionPresent: sessionPresent,
        error: 'config_missing',
      );
    }

    final client = httpClient ?? http.Client();
    final shouldClose = httpClient == null;
    try {
      final res = await client
          .get(Uri.parse('${SupabaseConfig.url}/auth/v1/health'))
          .timeout(timeout);
      return SupabaseSelfTestResult(
        clientInitialized: clientInitialized,
        urlConfigured: true,
        urlHost: host,
        endpointReachable: res.statusCode >= 200 && res.statusCode < 500,
        endpointStatus: res.statusCode,
        sessionPresent: sessionPresent,
      );
    } on TimeoutException {
      return SupabaseSelfTestResult(
        clientInitialized: clientInitialized,
        urlConfigured: true,
        urlHost: host,
        endpointReachable: false,
        sessionPresent: sessionPresent,
        error: 'timeout',
      );
    } catch (e) {
      final s = e.toString().toLowerCase();
      final cause = s.contains('tls') ||
              s.contains('ssl') ||
              s.contains('certificate') ||
              s.contains('handshake')
          ? 'tls_failure'
          : 'network_failure';
      return SupabaseSelfTestResult(
        clientInitialized: clientInitialized,
        urlConfigured: true,
        urlHost: host,
        endpointReachable: false,
        sessionPresent: sessionPresent,
        error: cause,
      );
    } finally {
      if (shouldClose) client.close();
    }
  }

  /// Runs [run] and emits secret-free `[AuthSelfTest]` lines in debug
  /// builds only. Fire-and-forget safe: never throws.
  static Future<void> logAtStartup() async {
    if (!kDebugMode) return;
    try {
      final r = await run();
      debugPrint(
        '[AuthSelfTest] clientInitialized=${r.clientInitialized} '
        'urlConfigured=${r.urlConfigured} urlHost=${r.urlHost} '
        'endpointReachable=${r.endpointReachable} '
        'endpointStatus=${r.endpointStatus} '
        'sessionPresent=${r.sessionPresent}'
        '${r.error != null ? ' error=${r.error}' : ''}',
      );
      if (!r.urlConfigured) {
        debugPrint(
            '[AuthSelfTest] ERROR: ${SupabaseConfig.missingConfigMessage}');
      } else if (!r.endpointReachable) {
        debugPrint(
          '[AuthSelfTest] Supabase Auth endpoint unreachable '
          '(cause=${r.error}). Check device internet/DNS for ${r.urlHost}.',
        );
      }
    } catch (e) {
      debugPrint('[AuthSelfTest] probe failed unexpectedly: ${e.runtimeType}');
    }
  }
}
