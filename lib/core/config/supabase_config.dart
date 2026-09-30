import 'package:flutter/foundation.dart';

/// Central Supabase configuration for Flutter client authentication and storage.
///
/// Values can be supplied at build/run time with:
/// `--dart-define=SUPABASE_URL=https://your-project.supabase.co`
/// `--dart-define=SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...`
///
/// NOTE: Flutter NEVER holds the service-role key or JWT secret.
/// Only the public anonymous key is configured here.
class SupabaseConfig {
  SupabaseConfig._();

  static const String _envSupabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://your-project.supabase.co',
  );

  static const String _envSupabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.dummy_anon_key',
  );

  /// Resolved Supabase API URL.
  static String get url {
    final raw = _envSupabaseUrl.trim();
    return raw.endsWith('/') ? raw.substring(0, raw.length - 1) : raw;
  }

  /// Resolved public anonymous key.
  static String get anonKey => _envSupabaseAnonKey.trim();

  /// True when a real (non-placeholder) URL and key have been provided.
  static bool get isConfigured {
    final u = url.toLowerCase();
    return u.isNotEmpty &&
        !u.contains('example.supabase') &&
        !u.contains('your-project.supabase') &&
        anonKey.isNotEmpty &&
        !anonKey.contains('dummy');
  }

  /// Explicit developer error used when the APK was built without
  /// `--dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...`.
  /// This is a BUILD configuration problem — it must never be reported as
  /// an internet/connection problem.
  static const String missingConfigMessage =
      'Supabase configuration is missing. Build with SUPABASE_URL and SUPABASE_ANON_KEY.';

  /// Hostname only (no path, no query, and never any key material).
  /// Returns 'unconfigured' when the URL cannot be parsed.
  static String get urlHost {
    try {
      final host = Uri.parse(url).host.trim();
      return host.isEmpty ? 'unconfigured' : host;
    } catch (_) {
      return 'unconfigured';
    }
  }

  /// Short platform label for diagnostics (web, android, ios, ...).
  static String get platformLabel {
    if (kIsWeb) return 'web';
    return defaultTargetPlatform.name;
  }

  /// One-line, secret-free diagnostic snapshot, e.g.:
  /// `[SupabaseConfig] platform=android configured=true urlHost=xyz.supabase.co`
  ///
  /// Only the platform, the configured flag, and the URL hostname are
  /// included. The anon key, tokens, and passwords are never printed here.
  static String describe() =>
      '[SupabaseConfig] platform=$platformLabel '
      'configured=$isConfigured urlHost=$urlHost';

  /// Emits [describe] via `debugPrint` in debug builds only. In profile and
  /// release builds this is a no-op so no endpoint details leak into logs.
  static void logStartupDiagnostic() {
    if (!kDebugMode) return;
    debugPrint(describe());
    if (!isConfigured) {
      debugPrint('[SupabaseConfig] ERROR: $missingConfigMessage');
    }
  }
}
