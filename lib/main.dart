import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app/app.dart';
import 'app/di/injection.dart';
import 'core/auth/data/supabase_self_test.dart';
import 'core/config/api_config.dart';
import 'core/config/supabase_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Development-only startup diagnostic. Prints the compiled backend URL
  // actually used by this build (no secrets). Check `adb logcat` for:
  //   [ApiConfig] platform=android baseUrl=... explicit=...
  ApiConfig.logStartupDiagnostic();
  SupabaseConfig.logStartupDiagnostic();

  // SystemChrome is mobile-only. On web it can throw / hang and
  // prevent runApp from ever running -> blank white screen.
  if (!kIsWeb) {
    try {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } catch (e) {
      debugPrint('Orientation lock skipped: $e');
    }
  }

  // Initialize Supabase Auth client if credentials were provided via --dart-define
  if (SupabaseConfig.isConfigured) {
    if (kDebugMode) {
      debugPrint('[Auth] Supabase initialization started');
    }
    try {
      await Supabase.initialize(
        url: SupabaseConfig.url,
        anonKey: SupabaseConfig.anonKey,
        debug: kDebugMode,
      );
      if (kDebugMode) {
        debugPrint('[Auth] Supabase initialization successful');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[Auth] Supabase initialization failed: ${e.runtimeType} '
          '(see [AuthSelfTest] lines for endpoint reachability)',
        );
      }
    }
    // Development-only, read-only reachability probe: no sign-in, no data
    // changes, no credentials sent or logged.
    if (kDebugMode) {
      unawaited(SupabaseAuthSelfTest.logAtStartup());
    }
  } else {
    if (kDebugMode) {
      debugPrint('[Auth] ERROR: ${SupabaseConfig.missingConfigMessage}');
    }
  }

  // Never let DI/DB init prevent the app from painting.
  // On web, drift IndexedDB open + seeding can fail first-run.
  try {
    await setupDependencyInjection();
  } catch (e, st) {
    debugPrint('DI init failed, starting anyway: $e');
    debugPrint('$st');
  }

  runApp(const MaatribhashaApp());
}
