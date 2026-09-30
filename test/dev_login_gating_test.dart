import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:maatribhasha/core/auth/data/repositories/supabase_auth_repository.dart';

/// Guards the production-login contract:
///
/// - Without Supabase build configuration (the APK case: no
///   SUPABASE_URL / SUPABASE_ANON_KEY defines), the repository sits in
///   offline mode.
/// - The normal Login button must NEVER fall through to the dev-token
///   endpoint automatically: no HTTP call may be issued and the failure
///   must read 'Supabase configuration is missing. Build with SUPABASE_URL
///   and SUPABASE_ANON_KEY.' — never a dev-login message and never an
///   internet-connection message (missing build config is not a network
///   problem).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late int httpCalls;
  late SupabaseAuthRepository repo;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    httpCalls = 0;
    final mockHttp = MockClient((http.Request request) async {
      httpCalls++;
      return http.Response('{}', 200);
    });
    repo = SupabaseAuthRepository(httpClient: mockHttp);
    await repo.initialize();
  });

  test('unconfigured build is not in Supabase mode', () {
    // Test builds carry no SUPABASE_URL/KEY defines, mirroring the APK
    // built without them.
    expect(repo.authMode.name, isNot('supabase'));
  });

  test('login attempts no dev-token call and reports connection error',
      () async {
    final result = await repo.signInWithEmail(
      email: 'teacher@school.edu.in',
      password: 'secret123',
    );
    expect(result.isSuccess, isFalse);
    expect(result.errorMessage,
        'Supabase configuration is missing. Build with SUPABASE_URL and SUPABASE_ANON_KEY.');
    expect(httpCalls, 0,
        reason: 'dev-login endpoint must never be called automatically');
  });

  test('signup attempts no dev-token call and reports connection error',
      () async {
    final result = await repo.signUpWithEmail(
      email: 'teacher@school.edu.in',
      password: 'secret123',
      data: {'name': 'Teacher'},
    );
    expect(result.isSuccess, isFalse);
    expect(result.errorMessage,
        'Supabase configuration is missing. Build with SUPABASE_URL and SUPABASE_ANON_KEY.');
    expect(httpCalls, 0,
        reason: 'dev-login endpoint must never be called automatically');
  });

  test('otp request attempts no dev-token call and reports connection error',
      () async {
    final result = await repo.sendOtp(identifier: 'teacher@school.edu.in');
    expect(result.isSuccess, isFalse);
    expect(result.errorMessage, 'Unable to connect to server');
    expect(httpCalls, 0,
        reason: 'dev-login endpoint must never be called automatically');
  });
}
