import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:maatribhasha/core/auth/data/repositories/supabase_auth_repository.dart'
    show
        classifySupabaseAuthCause,
        sanitizeAuthLogMessage;
import 'package:maatribhasha/core/auth/data/supabase_self_test.dart';
import 'package:maatribhasha/core/config/supabase_config.dart';

/// Diagnostics for the Android-APK Supabase misconfiguration class of
/// failures: everything here is secret-free (hostnames and error causes
/// only — never keys, tokens, or passwords).
void main() {
  group('SupabaseConfig safe diagnostics', () {
    test('missing-config message is explicit (never an internet message)',
        () {
      expect(
        SupabaseConfig.missingConfigMessage,
        'Supabase configuration is missing. '
        'Build with SUPABASE_URL and SUPABASE_ANON_KEY.',
      );
      expect(SupabaseConfig.missingConfigMessage, isNot(contains('internet')));
    });

    test('describe() exposes only platform/configured/host (no secrets)',
        () {
      final snapshot = SupabaseConfig.describe();
      expect(snapshot, contains('[SupabaseConfig]'));
      expect(snapshot, contains('platform='));
      expect(snapshot, contains('configured='));
      expect(snapshot, contains('urlHost='));
      expect(snapshot, isNot(contains(SupabaseConfig.anonKey)));
      expect(snapshot.toLowerCase(), isNot(contains('eyjh')));
      expect(snapshot, isNot(contains('://')));
    });

    test('urlHost never contains scheme, path, or key material', () {
      final host = SupabaseConfig.urlHost;
      expect(host, isNot(contains('://')));
      expect(host, isNot(contains('/')));
      expect(host, isNot(contains(SupabaseConfig.anonKey)));
    });
  });

  group('auth failure classification (9 causes)', () {
    test('invalid credentials', () {
      expect(
        classifySupabaseAuthCause(
          const AuthException('Invalid login credentials', statusCode: '400'),
        ),
        'invalid_credentials',
      );
    });

    test('existing email', () {
      expect(
        classifySupabaseAuthCause(
          const AuthException('User already registered'),
        ),
        'email_exists',
      );
    });

    test('email confirmation required', () {
      expect(
        classifySupabaseAuthCause(
          const AuthException('Email not confirmed'),
        ),
        'email_not_confirmed',
      );
    });

    test('Supabase API HTTP error carries through with status', () {
      expect(
        classifySupabaseAuthCause(
          const AuthException('Internal error', statusCode: '500'),
        ),
        'http_error',
      );
    });

    test('timeout', () {
      expect(
        classifySupabaseAuthCause(
          TimeoutException('t', const Duration(seconds: 8)),
        ),
        'timeout',
      );
    });

    test('TLS failure distinguished from plain network failure', () {
      expect(
        classifySupabaseAuthCause(
          http.ClientException('TLS handshake failure'),
        ),
        'tls_failure',
      );
      expect(
        classifySupabaseAuthCause(
          http.ClientException('Connection refused'),
        ),
        'network_failure',
      );
    });

    test('unexpected exception', () {
      expect(classifySupabaseAuthCause(StateError('weird')), 'unexpected');
    });
  });

  group('log sanitizer', () {
    test('redacts JWTs, publishable keys, and passwords', () {
      const jwt =
          'eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxIn0.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c';
      final out = sanitizeAuthLogMessage(
        'failed $jwt sb_publishable_abc123 password=hunter2 done',
      );
      expect(out, isNot(contains(jwt)));
      expect(out, isNot(contains('sb_publishable_abc123')));
      expect(out, isNot(contains('hunter2')));
      expect(out, contains('[REDACTED_JWT]'));
      expect(out, contains('[REDACTED_KEY]'));
      expect(out, contains('password=[REDACTED]'));
    });

    test('truncates very long messages', () {
      final out = sanitizeAuthLogMessage('x' * 2000);
      expect(out.length, lessThan(2000));
      expect(out, contains('[truncated]'));
    });
  });

  group('SupabaseAuthSelfTest (dev-only, read-only)', () {
    test('unconfigured build reports config_missing without HTTP calls',
        () async {
      var httpCalls = 0;
      final mock = MockClient((request) async {
        httpCalls++;
        return http.Response('{"name":"GoTrue"}', 200);
      });
      final result = await SupabaseAuthSelfTest.run(httpClient: mock);
      expect(result.urlConfigured, isFalse);
      expect(result.error, 'config_missing');
      expect(result.endpointReachable, isFalse);
      expect(httpCalls, 0,
          reason: 'no probe without a configured project URL');
    });

    test('logAtStartup never throws on an unconfigured build', () async {
      await SupabaseAuthSelfTest.logAtStartup();
    });
  });
}
