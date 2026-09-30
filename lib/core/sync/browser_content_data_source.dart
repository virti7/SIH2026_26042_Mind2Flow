import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../api/authenticated_api_client.dart';
import '../config/api_config.dart';
import 'remote_content_data_source.dart';

/// Browser-compatible [RemoteContentDataSource] for Flutter Web.
///
/// The `dart:io`-based [HttpRemoteContentDataSource] cannot run in a browser,
/// so web uses `package:http` (backed by the browser fetch API). Same
/// endpoints, same payloads, same job polling: online generation on web goes
/// straight to FastAPI, which in turn calls the configured translation
/// providers server-side. Flutter never calls translation providers directly.
class BrowserHttpRemoteContentDataSource implements RemoteContentDataSource {
  final String baseUrl;
  final String? authToken;
  final http.Client _client;
  final AuthenticatedApiClient? _apiClient;

  BrowserHttpRemoteContentDataSource({
    String? baseUrl,
    this.authToken,
    http.Client? client,
    AuthenticatedApiClient? apiClient,
  })  : baseUrl = baseUrl ?? ApiConfig.baseUrl,
        _client = client ?? http.Client(),
        _apiClient = apiClient;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (authToken != null) 'Authorization': 'Bearer $authToken',
      };

  @override
  Future<GenerationJobModel> requestGeneration(
    TeacherGenerationRequestModel request, {
    String? idempotencyKey,
  }) async {
    final String path;
    if (request.contentType == 'worksheet') {
      path = '/api/v1/worksheets/generate';
    } else if (request.contentType == 'flashcard') {
      path = '/api/v1/content/flashcards/generate';
    } else {
      path = '/api/v1/ai/teacher/generate';
    }

    final payload = request.toJson();
    if (idempotencyKey != null) {
      payload['idempotency_key'] = idempotencyKey;
    }

    if (kDebugMode) {
      debugPrint('[WebGenerate] POST platform=web base=$baseUrl path=$path');
    }

    final uri = Uri.parse('$baseUrl$path');

    if (_apiClient != null) {
      final meUri = Uri.parse('$baseUrl/api/v1/me');
      final meRes = await _apiClient.get(meUri);
      if (kDebugMode) {
        debugPrint('[WebGenerate] Pre-generation GET /api/v1/me -> HTTP ${meRes.statusCode}');
      }
      if (meRes.statusCode != 200) {
        throw ApiException(
          statusCode: meRes.statusCode,
          message: 'User authentication check failed (${meRes.statusCode})',
          body: meRes.body,
        );
      }

      final res = await _apiClient.post(uri, body: payload);
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return GenerationJobModel.fromJson(data);
    }

    final res = await _client.post(
      uri,
      headers: _headers,
      body: jsonEncode(payload),
    );

    if (kDebugMode) {
      debugPrint('[WebGenerate] POST $path -> HTTP ${res.statusCode}');
    }

    if (res.statusCode != 200 && res.statusCode != 202) {
      throw ApiException(
        statusCode: res.statusCode,
        message: 'Generation request rejected with HTTP ${res.statusCode}',
        body: res.body,
      );
    }

    return GenerationJobModel.fromJson(
      jsonDecode(res.body) as Map<String, dynamic>,
    );
  }

  @override
  Future<GenerationJobModel> getJobStatus(String jobId) async {
    final uri = Uri.parse('$baseUrl/api/v1/ai/jobs/$jobId');

    if (_apiClient != null) {
      final res = await _apiClient.get(uri);
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return GenerationJobModel.fromJson(data);
    }

    final res = await _client.get(
      uri,
      headers: _headers,
    );

    if (res.statusCode != 200) {
      throw ApiException(
        statusCode: res.statusCode,
        message: 'Failed to get job status HTTP ${res.statusCode}',
        body: res.body,
      );
    }

    return GenerationJobModel.fromJson(
      jsonDecode(res.body) as Map<String, dynamic>,
    );
  }

  @override
  Future<GenerationJobModel> approveJob(
    String jobId, {
    String? santaliScriptConfirmed,
    String? notes,
  }) async {
    final uri = Uri.parse('$baseUrl/api/v1/ai/jobs/$jobId/approve');

    final bodyPayload = {
      'santali_script_confirmed': santaliScriptConfirmed ?? 'Olck',
      if (notes != null) 'notes': notes,
    };

    if (_apiClient != null) {
      final res = await _apiClient.post(uri, body: bodyPayload);
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return GenerationJobModel.fromJson(data);
    }

    final res = await _client.post(
      uri,
      headers: _headers,
      body: jsonEncode(bodyPayload),
    );

    if (res.statusCode != 200) {
      throw ApiException(
        statusCode: res.statusCode,
        message: 'Failed to approve job HTTP ${res.statusCode}',
        body: res.body,
      );
    }

    return GenerationJobModel.fromJson(
      jsonDecode(res.body) as Map<String, dynamic>,
    );
  }

  @override
  Future<dynamic> downloadAsset(String assetUrlOrPath, String localFileName) {
    // Browser downloads use object URLs/anchors, not dart:io Files. The
    // generation flow treats this as optional and keeps the payload.
    throw UnsupportedError('Asset download is not supported on web.');
  }
}
