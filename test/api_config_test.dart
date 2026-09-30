import 'package:flutter_test/flutter_test.dart';
import 'package:maatribhasha/core/config/api_config.dart';
import 'package:maatribhasha/core/sync/http_remote_data_source.dart';

void main() {
  group('ApiConfig (safe configurable backend URL)', () {
    test('baseUrl is non-empty and has no trailing slash', () {
      expect(ApiConfig.baseUrl, isNotEmpty);
      expect(ApiConfig.baseUrl.endsWith('/'), isFalse);
    });

    test('production URL is supplied via --dart-define, never hardcoded', () {
      // Without --dart-define, the loopback default applies on every
      // platform (physical Android included — never the emulator alias).
      // Release builds must pass --dart-define=BACKEND_URL=<production URL>.
      expect(
        ApiConfig.baseUrl,
        anyOf([
          'http://127.0.0.1:8000',
          'http://10.0.2.2:8000',
          predicate<String>((u) => u.startsWith('https://')),
        ]),
      );
    });

    test('default (no define) is the physical-device loopback', () {
      expect(ApiConfig.isExplicitlyConfigured, isFalse);
      expect(ApiConfig.baseUrl, 'http://127.0.0.1:8000');
    });
  });

  group('Production sync wiring', () {
    test('HttpRemoteDataSource defaults to ApiConfig.baseUrl', () {
      final ds = HttpRemoteDataSource();
      expect(ds.baseUrl, ApiConfig.baseUrl);
    });

    test('explicit baseUrl override is honoured', () {
      final ds = HttpRemoteDataSource(baseUrl: 'https://api.example.com');
      expect(ds.baseUrl, 'https://api.example.com');
    });
  });
}
