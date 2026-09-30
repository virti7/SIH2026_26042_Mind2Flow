import 'package:flutter/foundation.dart';

/// Central API base URL configuration.
///
/// Resolution order:
/// 1. `--dart-define=BACKEND_URL=<url>` (ALWAYS wins when supplied):
///    - Production: `--dart-define=BACKEND_URL=https://api.example.com`
///    - Local physical device over USB (`adb reverse`): `--dart-define=BACKEND_URL=http://127.0.0.1:8000`
///    - Local Android emulator: `--dart-define=BACKEND_URL=http://10.0.2.2:8000`
/// 2. Local development default: `http://127.0.0.1:8000` on EVERY platform.
///
/// There is deliberately NO Android → 10.0.2.2 automatic mapping:
/// `Platform.isAndroid` (or `defaultTargetPlatform == android`) does NOT mean
/// "emulator". A physical phone reaches a PC backend through
/// `adb reverse tcp:8000 tcp:8000`, i.e. its own `http://127.0.0.1:8000`.
/// Emulator runs pass the explicit `10.0.2.2` define instead.
///
/// Credentials (Supabase anon/service keys, JWT secrets) are never stored here;
/// authentication tokens are attached per-request by the data sources.
class ApiConfig {
  ApiConfig._();

  /// Compile-time override. Pass with:
  /// `flutter run --dart-define=BACKEND_URL=https://api.example.com`
  static const String _envBackendUrl = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: '',
  );

  static String _platformDefault() {
    // Same local default on every platform (including Android): the physical
    // device over `adb reverse` and desktop/web simulators all reach the PC
    // backend at http://127.0.0.1:8000. The emulator-only alias 10.0.2.2 is
    // never selected automatically — pass it explicitly via BACKEND_URL.
    return 'http://127.0.0.1:8000';
  }

  /// Pure, unit-testable resolution: an explicit URL always wins (trailing
  /// slash stripped); otherwise the local default applies on all platforms.
  /// [explicitBackendUrl] defaults to the compiled `--dart-define=BACKEND_URL`.
  /// [platform] is accepted for documentation/regression purposes only: no
  /// platform (including Android) maps to the emulator alias automatically.
  static String resolveBaseUrl({
    String? explicitBackendUrl,
    TargetPlatform? platform,
  }) {
    final raw = (explicitBackendUrl ?? _envBackendUrl).trim();
    final resolved = raw.isEmpty ? _platformDefault() : raw;
    return resolved.endsWith('/')
        ? resolved.substring(0, resolved.length - 1)
        : resolved;
  }

  /// Resolved backend base URL without a trailing slash.
  static String get baseUrl => resolveBaseUrl();

  /// Safely joins a backend base URL and an endpoint path so callers never
  /// produce `http://host:8000//api/v1/health` (double slash) or
  /// `http://host:8000api/v1/health` (missing slash), even when the base
  /// carries a trailing slash (e.g. an explicit `--dart-define` value).
  static String joinPath(String base, String path) {
    final b = base.endsWith('/') ? base.substring(0, base.length - 1) : base;
    final p = path.startsWith('/') ? path : '/$path';
    return '$b$p';
  }

  /// Exact FastAPI health URL probed for reachability. The backend mounts
  /// the health router at both `/api/v1/health` (canonical) and `/health`
  /// (alias); the canonical path is probed first.
  /// See `backend/app/main.py` (`app.include_router(health_router, ...)`).
  static String healthUrl({String? baseUrlOverride}) =>
      joinPath(baseUrlOverride ?? baseUrl, '/api/v1/health');

  /// Alias health URL (probed only if the canonical path fails).
  static String healthUrlAlias({String? baseUrlOverride}) =>
      joinPath(baseUrlOverride ?? baseUrl, '/health');

  /// True when an explicit production URL was supplied via --dart-define.
  static bool get isExplicitlyConfigured => _envBackendUrl.trim().isNotEmpty;

  /// Short platform label for diagnostics (web, android, ios, ...).
  static String get platformLabel {
    if (kIsWeb) return 'web';
    return defaultTargetPlatform.name;
  }

  /// One-line, secret-free diagnostic snapshot, e.g.:
  /// `[ApiConfig] platform=android baseUrl=http://127.0.0.1:8000 explicit=false`
  ///
  /// Only the backend base URL is included; credentials and tokens are
  /// never printed here.
  static String describe() =>
      '[ApiConfig] platform=$platformLabel baseUrl=$baseUrl '
      'explicit=$isExplicitlyConfigured';

  /// Emits [describe] plus the physical-device checklist lines via
  /// `debugPrint` in debug builds only. In profile and release builds this
  /// is a no-op so no network details leak into logs. Never logs secrets
  /// (only the backend base URL, which carries no credentials).
  ///
  /// When a compile-time `BACKEND_URL` is present in a debug build, an extra
  /// warning line is printed so a stale/incorrect `--dart-define` used for an
  /// earlier production build cannot silently redirect local development
  /// traffic elsewhere unnoticed.
  static void logStartupDiagnostic() {
    if (!kDebugMode) return;
    debugPrint(describe());
    debugPrint('[ApiConfig] platform=$platformLabel');
    debugPrint('[ApiConfig] backendUrl=$baseUrl');
    debugPrint('[ApiConfig] explicitBackendUrl=$isExplicitlyConfigured');
    final raw = _envBackendUrl.trim();
    if (raw.isNotEmpty) {
      final looksLocal = raw.contains('10.0.2.2') ||
          raw.contains('127.0.0.1') ||
          raw.contains('localhost');
      if (!looksLocal && !raw.startsWith('https://')) {
        debugPrint(
          '[ApiConfig] WARNING: explicit BACKEND_URL does not look like a '
          'local dev server or https endpoint. If testing locally over USB '
          'with `adb reverse`, rebuild with '
          '--dart-define=BACKEND_URL=http://127.0.0.1:8000 '
          '(emulator: http://10.0.2.2:8000).',
        );
      }
    }
  }
}
