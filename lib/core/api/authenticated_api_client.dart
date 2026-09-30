import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../auth/domain/repositories/auth_repository.dart';

/// Exception thrown when a protected request is initiated without an active authentication token.
class AuthenticationRequiredException implements Exception {
  final String message;
  const AuthenticationRequiredException([
    this.message = 'Authentication required. Please sign in or run in development mode to proceed.',
  ]);
  @override
  String toString() => message;
}

class ApiException implements Exception {
  final int statusCode;
  final String message;
  final String? body;

  const ApiException({required this.statusCode, required this.message, this.body});

  @override
  String toString() => message;
}

class UnauthorizedException extends ApiException {
  const UnauthorizedException([
    String message = 'Unauthorized. Please sign in again.',
    String? body,
  ]) : super(statusCode: 401, message: message, body: body);
}

/// Exception thrown when authentication credentials are completely invalid or expired
/// even after an automated token refresh attempt.
class SessionExpiredException extends UnauthorizedException {
  const SessionExpiredException([
    String message = 'Your session has expired. Please sign in again and retry.',
    String? body,
  ]) : super(message, body);
}

class NetworkException implements Exception {
  final String message;
  const NetworkException([this.message = 'Cannot reach the server. Check your connection.']);
  @override
  String toString() => message;
}

class ForbiddenException extends ApiException {
  const ForbiddenException([String message = 'You do not have permission to perform this action.', String? body])
      : super(statusCode: 403, message: message, body: body);
}

class BadRequestException extends ApiException {
  const BadRequestException([String message = 'Invalid request. Please verify your selections.', String? body])
      : super(statusCode: 400, message: message, body: body);
}

class ValidationException extends ApiException {
  const ValidationException([String message = 'Some generation options are invalid.', String? body])
      : super(statusCode: 422, message: message, body: body);
}

class RateLimitedException extends ApiException {
  const RateLimitedException([String message = 'Generation service is temporarily busy. Please try again.', String? body])
      : super(statusCode: 429, message: message, body: body);
}

class ServerException extends ApiException {
  const ServerException([String message = 'Generation service is temporarily unavailable.', int statusCode = 500, String? body])
      : super(statusCode: statusCode, message: message, body: body);
}

class AuthenticatedApiClient {
  final AuthRepository authRepository;
  final http.Client _client;

  AuthenticatedApiClient({
    required this.authRepository,
    http.Client? client,
  }) : _client = client ?? http.Client();

  /// Executes an HTTP request with automated token attachment and single-attempt 401 token refresh.
  Future<http.Response> request({
    required String method,
    required Uri uri,
    Map<String, String>? headers,
    Object? body,
    Duration timeout = const Duration(seconds: 45),
    bool requiresAuth = true,
  }) async {
    return _sendWithRetry(
      method: method.toUpperCase(),
      uri: uri,
      headers: headers ?? {},
      body: body,
      timeout: timeout,
      hasRetried: false,
      requiresAuth: requiresAuth,
    );
  }

  Future<http.Response> _sendWithRetry({
    required String method,
    required Uri uri,
    required Map<String, String> headers,
    required Object? body,
    required Duration timeout,
    required bool hasRetried,
    required bool requiresAuth,
  }) async {
    final mergedHeaders = Map<String, String>.from(headers);
    if (!mergedHeaders.containsKey('Content-Type')) {
      mergedHeaders['Content-Type'] = 'application/json';
    }

    final token = await authRepository.currentAccessToken() ??
        await authRepository.getAccessToken();

    if (kDebugMode) {
      debugPrint(
        '[AuthDiag] auth_mode=${authRepository.authMode.name} '
        'authenticated=${authRepository.isAuthenticated} '
        'user_id=${authRepository.currentUserId} '
        'token_present=${token != null && token.isNotEmpty}',
      );
      debugPrint(
        '[AuthenticatedApiClient] $method $uri auth_header_present=${token != null && token.isNotEmpty}',
      );
    }

    if (requiresAuth) {
      if (token == null || token.trim().isEmpty) {
        throw const AuthenticationRequiredException();
      }
      mergedHeaders['Authorization'] = 'Bearer $token';
    } else {
      if (token != null && token.trim().isNotEmpty) {
        mergedHeaders['Authorization'] = 'Bearer $token';
      }
    }

    http.Response response;
    try {
      final req = http.Request(method, uri);
      req.headers.addAll(mergedHeaders);

      if (body != null) {
        if (body is String) {
          req.body = body;
        } else if (body is List<int>) {
          req.bodyBytes = body;
        } else {
          req.body = jsonEncode(body);
        }
      }

      final streamedRes = await _client.send(req).timeout(timeout);
      response = await http.Response.fromStream(streamedRes);

      if (kDebugMode) {
        debugPrint(
          '[AuthenticatedApiClient] $method $uri -> HTTP ${response.statusCode}',
        );
      }
    } on TimeoutException {
      throw const NetworkException('Request timed out. Please check your connection.');
    } catch (e) {
      if (e is Exception && (e.toString().contains('Socket') || e.toString().contains('Failed to fetch') || e.toString().contains('ClientException'))) {
        throw const NetworkException('Cannot reach the server. Check your connection.');
      }
      rethrow;
    }

    // Handle 401 Unauthorized: Refresh session once and retry exactly once
    if (response.statusCode == 401) {
      String detail = '';
      try {
        final json = jsonDecode(response.body);
        if (json is Map) {
          detail = json['detail']?.toString() ?? json['message']?.toString() ?? '';
        }
      } catch (_) {}

      if (kDebugMode) {
        debugPrint(
          '[AuthenticatedApiClient] 401 received for $method $uri. Server detail: $detail',
        );
      }

      if (!hasRetried) {
        if (kDebugMode) {
          debugPrint('[AuthenticatedApiClient] Attempting token refresh...');
        }
        final newToken = await authRepository.refreshToken();
        if (newToken != null && newToken.isNotEmpty) {
          // Retry exactly once with refreshed token
          return _sendWithRetry(
            method: method,
            uri: uri,
            headers: headers,
            body: body,
            timeout: timeout,
            hasRetried: true,
            requiresAuth: requiresAuth,
          );
        }
        // Supabase session itself is dead (refresh failed): sign out so the
        // router returns to Login. This is an AUTH failure, not a backend one.
        await authRepository.signOut();
        throw SessionExpiredException(
          detail.isNotEmpty ? detail : 'Your session has expired. Please sign in again and retry.',
          response.body,
        );
      }

      // The retried request with a freshly refreshed Supabase token still got
      // 401: the backend rejected a valid session (backend-layer outcome).
      // Keep the authenticated Supabase session — do NOT sign out — and
      // report the backend rejection as-is.
      if (kDebugMode) {
        debugPrint(
          '[AuthenticatedApiClient] Backend rejected refreshed session; '
          'keeping authenticated session',
        );
      }
      throw UnauthorizedException(detail.isNotEmpty ? detail : 'Unauthorized request (401).', response.body);
    }

    // Map non-2xx status codes accurately
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response;
    }

    _handleNonSuccessStatus(response);
    return response;
  }

  void _handleNonSuccessStatus(http.Response res) {
    String detail = '';
    try {
      final json = jsonDecode(res.body);
      if (json is Map) {
        detail = json['detail']?.toString() ?? json['message']?.toString() ?? '';
      }
    } catch (_) {}

    switch (res.statusCode) {
      case 400:
        throw BadRequestException(detail.isNotEmpty ? detail : 'Invalid request.');
      case 401:
        throw UnauthorizedException(detail.isNotEmpty ? detail : 'Unauthorized request.', res.body);
      case 403:
        throw ForbiddenException(detail.isNotEmpty ? detail : 'You do not have permission to perform this action.');
      case 404:
        throw ApiException(statusCode: 404, message: detail.isNotEmpty ? detail : 'Resource not found.', body: res.body);
      case 422:
        throw ValidationException(detail.isNotEmpty ? detail : 'Some generation options are invalid.');
      case 429:
        throw RateLimitedException(detail.isNotEmpty ? detail : 'Generation service is temporarily busy. Please try again.');
      default:
        if (res.statusCode >= 500) {
          throw ServerException(detail.isNotEmpty ? detail : 'Generation service is temporarily unavailable.');
        }
        throw ApiException(statusCode: res.statusCode, message: detail.isNotEmpty ? detail : 'Request failed with status ${res.statusCode}.', body: res.body);
    }
  }

  Future<http.Response> get(Uri uri, {Map<String, String>? headers, bool requiresAuth = true}) =>
      request(method: 'GET', uri: uri, headers: headers, requiresAuth: requiresAuth);

  Future<http.Response> post(Uri uri, {Map<String, String>? headers, Object? body, bool requiresAuth = true}) =>
      request(method: 'POST', uri: uri, headers: headers, body: body, requiresAuth: requiresAuth);

  Future<http.Response> put(Uri uri, {Map<String, String>? headers, Object? body, bool requiresAuth = true}) =>
      request(method: 'PUT', uri: uri, headers: headers, body: body, requiresAuth: requiresAuth);

  Future<http.Response> delete(Uri uri, {Map<String, String>? headers, bool requiresAuth = true}) =>
      request(method: 'DELETE', uri: uri, headers: headers, requiresAuth: requiresAuth);
}
