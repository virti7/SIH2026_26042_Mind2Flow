import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:maatribhasha/core/api/authenticated_api_client.dart';
import 'package:maatribhasha/core/auth/data/repositories/supabase_auth_repository.dart';
import 'package:maatribhasha/core/auth/domain/repositories/auth_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthUser;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Auth Startup Flow & Lifecycle Tests', () {
    test('1. Dev fallback startup: obtains dev JWT and sets AuthMode.dev', () async {
      final mockDevHttp = MockClient((request) async {
        if (request.url.path.contains('/api/v1/auth/dev-token')) {
          return http.Response(
            jsonEncode({
              'access_token': 'dev_teacher_jwt_token_xyz',
              'user_id': 'dev-teacher-001',
              'role': 'teacher',
            }),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      final repo = SupabaseAuthRepository(httpClient: mockDevHttp, autoDevLogin: true);
      await repo.initialize();

      expect(repo.authMode, AuthMode.dev);
      expect(repo.isAuthenticated, isTrue);
      expect(await repo.currentAccessToken(), 'dev_teacher_jwt_token_xyz');
      expect(await repo.getAccessToken(), 'dev_teacher_jwt_token_xyz');
      expect(repo.currentUser?.role, 'teacher');
    });

    test('2. Offline startup: when backend unreachable, sets AuthMode.offline and stays unauthenticated', () async {
      final failingHttp = MockClient((request) async {
        throw http.ClientException('Connection refused');
      });

      final repo = SupabaseAuthRepository(httpClient: failingHttp);
      await repo.initialize();

      expect(repo.authMode, AuthMode.offline);
      expect(repo.isAuthenticated, isFalse);
      expect(await repo.currentAccessToken(), isNull);
      expect(await repo.getAccessToken(), isNull);
    });

    test('3. Protected request with dev JWT attaches Authorization Bearer header', () async {
      final devHttp = MockClient((request) async {
        if (request.url.path.contains('/api/v1/auth/dev-token')) {
          return http.Response(
            jsonEncode({
              'access_token': 'valid_dev_jwt_999',
              'user_id': 'dev-teacher-001',
              'role': 'teacher',
            }),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      final repo = SupabaseAuthRepository(httpClient: devHttp, autoDevLogin: true);
      await repo.initialize();

      String? capturedAuthHeader;
      final mockApiServer = MockClient((request) async {
        capturedAuthHeader = request.headers['Authorization'];
        return http.Response(jsonEncode({'job_id': 'job-123'}), 202);
      });

      final client = AuthenticatedApiClient(
        authRepository: repo,
        client: mockApiServer,
      );

      final res = await client.post(
        Uri.parse('http://127.0.0.1:8000/api/v1/worksheets/generate'),
        body: {'topic': 'Numbers'},
      );

      expect(res.statusCode, 202);
      expect(capturedAuthHeader, 'Bearer valid_dev_jwt_999');
    });

    test('4. Unauthenticated request throws AuthenticationRequiredException before network transmission', () async {
      final failingHttp = MockClient((request) async {
        throw http.ClientException('Offline');
      });

      final repo = SupabaseAuthRepository(httpClient: failingHttp);
      await repo.initialize();
      expect(repo.authMode, AuthMode.offline);

      int networkRequestsSent = 0;
      final mockServer = MockClient((request) async {
        networkRequestsSent++;
        return http.Response('{}', 200);
      });

      final client = AuthenticatedApiClient(
        authRepository: repo,
        client: mockServer,
      );

      expect(
        () => client.post(
          Uri.parse('http://127.0.0.1:8000/api/v1/worksheets/generate'),
          body: {'topic': 'Numbers'},
        ),
        throwsA(isA<AuthenticationRequiredException>()),
      );
      expect(networkRequestsSent, 0);
    });

    test('5. 401 refresh in dev mode: re-fetches dev token and retries request once', () async {
      int devTokenCallCount = 0;
      final devHttp = MockClient((request) async {
        if (request.url.path.contains('/api/v1/auth/dev-token')) {
          devTokenCallCount++;
          return http.Response(
            jsonEncode({
              'access_token': 'dev_token_attempt_$devTokenCallCount',
              'user_id': 'dev-teacher-001',
              'role': 'teacher',
            }),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      final repo = SupabaseAuthRepository(httpClient: devHttp, autoDevLogin: true);
      await repo.initialize();
      expect(devTokenCallCount, 1);

      int apiCallCount = 0;
      final authHeadersSeen = <String?>[];
      final mockApiServer = MockClient((request) async {
        apiCallCount++;
        authHeadersSeen.add(request.headers['Authorization']);
        if (apiCallCount == 1) {
          return http.Response(jsonEncode({'detail': 'Token expired'}), 401);
        }
        return http.Response(jsonEncode({'status': 'retry_success'}), 200);
      });

      final client = AuthenticatedApiClient(
        authRepository: repo,
        client: mockApiServer,
      );

      final res = await client.post(
        Uri.parse('http://127.0.0.1:8000/api/v1/worksheets/generate'),
        body: {'topic': 'Addition'},
      );

      expect(res.statusCode, 200);
      expect(apiCallCount, 2);
      expect(devTokenCallCount, 2); // Initial + 1 refresh
      expect(authHeadersSeen[0], 'Bearer dev_token_attempt_1');
      expect(authHeadersSeen[1], 'Bearer dev_token_attempt_2');
    });

    test('6. No Supabase refresh call when Supabase is uninitialized', () async {
      // In dev or offline mode, refreshToken() must NEVER attempt client.auth.refreshSession()
      final failingHttp = MockClient((request) async {
        throw http.ClientException('Offline');
      });

      final repo = SupabaseAuthRepository(httpClient: failingHttp);
      await repo.initialize();
      expect(repo.authMode, AuthMode.offline);

      // Must return null without throwing "Bad state: Supabase has not been initialized."
      final refreshed = await repo.refreshToken();
      expect(refreshed, isNull);
    });
  });
}
