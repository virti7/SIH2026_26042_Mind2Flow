import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../api/authenticated_api_client.dart';
import '../config/api_config.dart';

class TeacherGenerationRequestModel {
  final String contentType; // 'worksheet' or 'flashcard'
  final int grade;
  final String section; // classroom section, e.g. 'A' / 'General'
  final String subject;
  final String? curriculumId;
  final String? outcomeCode;
  final String targetLanguage; // legacy singular: always == language2
  final String difficulty; // 'easy', 'medium', 'hard'
  final String? worksheetType; // legacy singular: first of worksheetTypes
  final List<String> worksheetTypes; // every selected type
  final int questionCount;
  final String? idempotencyKey;
  // Full teacher-selected parameters (sent to the server; never secrets).
  final String? requestId;
  final String topicSource; // 'curriculum' | 'custom' | 'image_catalog'
  final String? topicId;
  final String topicInputLanguage; // 'hi' | 'en'
  final String? topic;
  final String? nipunOutcome;
  final String sourceLanguage; // legacy singular: always == language1
  final String language1; // Worksheet Language 1 (internal code)
  final String language2; // Worksheet Language 2 (internal code)
  final bool visualSupport;
  final bool bilingualAnswers;
  final bool audioCue;
  final String? deviceId;
  final String? teacherId;
  final String origin; // 'online' | 'offline'
  final String? createdAt; // ISO-8601
  // Santali multilingual flashcard parameters (Hi/En/Sat only). Worksheet
  // callers leave these null; the server applies worksheet defaults.
  final String? languageMode; // hi_sat | en_sat | hi_en_sat
  final String? flashcardType; // vocabulary | object_identification | ...
  final int? cardCount; // 1-20
  final String? visualStyle; // illustrated | vector | photo_neutral
  final bool? pronunciation;
  final String? learningOutcome;
  final String? strand;

  const TeacherGenerationRequestModel({
    this.contentType = 'worksheet',
    this.grade = 1,
    this.section = 'General',
    this.subject = 'Mathematics',
    this.curriculumId,
    this.outcomeCode,
    this.targetLanguage = 'sat',
    this.difficulty = 'medium',
    this.worksheetType = 'practice',
    this.worksheetTypes = const ['practice'],
    this.questionCount = 10,
    this.idempotencyKey,
    this.requestId,
    this.topicSource = 'curriculum',
    this.topicId,
    this.topicInputLanguage = 'en',
    this.topic,
    this.nipunOutcome,
    this.sourceLanguage = 'hi',
    this.language1 = 'hi',
    this.language2 = 'sat',
    this.visualSupport = true,
    this.bilingualAnswers = true,
    this.audioCue = false,
    this.deviceId,
    this.teacherId,
    this.origin = 'online',
    this.createdAt,
    this.languageMode,
    this.flashcardType,
    this.cardCount,
    this.visualStyle,
    this.pronunciation,
    this.learningOutcome,
    this.strand,
  });

  /// Rebuilds a request from its [toJson] form (used by the offline
  /// worksheet-generation queues). Unknown/missing fields fall back to the
  /// same defaults as the const constructor. Never throws on malformed
  /// values: callers validate before persisting.
  factory TeacherGenerationRequestModel.fromJson(Map<String, dynamic> json) {
    bool flag(String key, bool fallback) {
      final v = json[key];
      if (v is bool) return v;
      if (v is num) return v != 0;
      if (v is String) {
        final s = v.trim().toLowerCase();
        if (s == 'true' || s == '1') return true;
        if (s == 'false' || s == '0') return false;
      }
      return fallback;
    }

    String? str(String key) {
      final v = json[key];
      if (v == null) return null;
      final s = v.toString();
      return s.isEmpty ? null : s;
    }

    int intVal(String key, int fallback) {
      final v = json[key];
      if (v is num) return v.toInt();
      return fallback;
    }

    List<String> strList(String key, List<String> fallback) {
      final v = json[key];
      if (v is List && v.isNotEmpty) {
        return v.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
      }
      final single = str(key == 'worksheet_types' ? 'worksheet_type' : key);
      if (single != null) return [single];
      return fallback;
    }

    final types = strList('worksheet_types', const ['practice']);
    final lang1 = str('language_1') ?? str('source_language') ?? 'hi';
    final lang2 = str('target_language') ?? 'sat';
    int? intOrNull(String key) {
      final v = json[key];
      if (v is num) return v.toInt();
      return null;
    }

    return TeacherGenerationRequestModel(
      contentType: str('content_type') ?? 'worksheet',
      grade: intVal('grade', 1),
      section: str('section') ?? 'General',
      subject: str('subject') ?? 'Mathematics',
      curriculumId: str('curriculum_id'),
      outcomeCode: str('outcome_code'),
      targetLanguage: lang2,
      difficulty: str('difficulty') ?? 'medium',
      worksheetType: types.isNotEmpty ? types.first : 'practice',
      worksheetTypes: types,
      questionCount: intVal('question_count', 10),
      idempotencyKey: str('idempotency_key'),
      requestId: str('request_id'),
      topicSource: str('topic_source') ?? 'curriculum',
      topicId: str('topic_id'),
      topicInputLanguage: str('topic_input_language') ?? 'en',
      topic: str('topic'),
      nipunOutcome: str('nipun_outcome'),
      sourceLanguage: lang1,
      language1: lang1,
      language2: lang2,
      visualSupport: flag('visual_support', flag('visual_illustrations', true)),
      bilingualAnswers:
          flag('bilingual_answers', flag('bilingual_answer_spaces', true)),
      audioCue: flag('audio_cue', flag('audio_pronunciation', false)),
      deviceId: str('device_id'),
      teacherId: str('teacher_id'),
      origin: str('origin') ?? 'online',
      createdAt: str('created_at'),
      languageMode: str('language_mode'),
      flashcardType: str('flashcard_type'),
      cardCount: intOrNull('card_count'),
      visualStyle: str('visual_style'),
      pronunciation: json['pronunciation'] is bool
          ? json['pronunciation'] as bool
          : null,
      learningOutcome: str('learning_outcome'),
      strand: str('strand'),
    );
  }

  Map<String, dynamic> toJson() => {        'content_type': contentType,
        'grade': grade,
        'section': section,
        'subject': subject,
        if (curriculumId != null) 'curriculum_id': curriculumId,
        if (outcomeCode != null) 'outcome_code': outcomeCode,
        'target_language': language2,
        'difficulty': difficulty,
        'worksheet_type': worksheetTypes.isNotEmpty ? worksheetTypes.first : (worksheetType ?? 'practice'),
        'worksheet_types': worksheetTypes,
        'question_count': questionCount,
        if (idempotencyKey != null) 'idempotency_key': idempotencyKey,
        if (requestId != null) 'request_id': requestId,
        if (teacherId != null) 'teacher_id': teacherId,
        if (deviceId != null) 'device_id': deviceId,
        'topic_source': topicSource,
        if (topicId != null) 'topic_id': topicId,
        'topic_input_language': topicInputLanguage,
        if (topic != null) 'topic': topic,
        'topic_text': topic,
        if (nipunOutcome != null) 'nipun_outcome': nipunOutcome,
        'source_language': language1,
        'language_1': language1,
        'language_2': language2,
        'visual_support': visualSupport,
        'visual_illustrations': visualSupport,
        'bilingual_answers': bilingualAnswers,
        'bilingual_answer_spaces': bilingualAnswers,
        'audio_cue': audioCue,
        'audio_pronunciation': audioCue,
        'origin': origin,
        if (createdAt != null) 'created_at': createdAt,
        if (contentType == 'flashcard') ...{
          if (languageMode != null) 'language_mode': languageMode,
          if (flashcardType != null) 'flashcard_type': flashcardType,
          if (cardCount != null) 'card_count': cardCount,
          if (visualStyle != null) 'visual_style': visualStyle,
          if (pronunciation != null) 'pronunciation': pronunciation,
          if (learningOutcome != null) 'learning_outcome': learningOutcome,
          if (strand != null) 'strand': strand,
        },
      };
}

class GenerationJobModel {
  final String jobId;
  final String status; // PENDING, GENERATING, VALIDATING, REVIEW_REQUIRED, APPROVED, READY, FAILED
  final String? contentId;
  final String contentType;
  final int grade;
  final String targetLanguage;
  final String? error;
  final Map<String, dynamic>? reviewGates;
  final Map<String, dynamic>? content;
  final Map<String, dynamic>? assets;

  const GenerationJobModel({
    required this.jobId,
    required this.status,
    this.contentId,
    required this.contentType,
    required this.grade,
    required this.targetLanguage,
    this.error,
    this.reviewGates,
    this.content,
    this.assets,
  });

  factory GenerationJobModel.fromJson(Map<String, dynamic> json) {
    return GenerationJobModel(
      jobId: json['job_id'] ?? '',
      status: json['status'] ?? 'PENDING',
      contentId: json['content_id'],
      contentType: json['content_type'] ?? 'worksheet',
      grade: (json['grade'] as num?)?.toInt() ?? 1,
      targetLanguage: json['target_language'] ?? 'sat',
      error: json['error'],
      reviewGates: json['review_gates'] as Map<String, dynamic>?,
      content: json['content'] as Map<String, dynamic>?,
      assets: json['assets'] as Map<String, dynamic>?,
    );
  }

  bool get isPendingOrRunning =>
      status == 'PENDING' || status == 'GENERATING' || status == 'VALIDATING';
  bool get isReviewRequired => status == 'REVIEW_REQUIRED';
  bool get isReady => status == 'READY';
  bool get isFailed => status == 'FAILED';
}

abstract class RemoteContentDataSource {
  Future<GenerationJobModel> requestGeneration(
    TeacherGenerationRequestModel request, {
    String? idempotencyKey,
  });

  Future<GenerationJobModel> getJobStatus(String jobId);

  Future<GenerationJobModel> approveJob(
    String jobId, {
    String? santaliScriptConfirmed,
    String? notes,
  });

  Future<dynamic> downloadAsset(String assetUrlOrPath, String localFileName);
}

class HttpRemoteContentDataSource implements RemoteContentDataSource {
  final String baseUrl;
  final String? authToken;
  final HttpClient _client;
  final dynamic _apiClient;

  HttpRemoteContentDataSource({
    String? baseUrl,
    this.authToken,
    HttpClient? client,
    dynamic apiClient,
  })  : baseUrl = baseUrl ?? ApiConfig.baseUrl,
        _client = client ?? HttpClient(),
        _apiClient = apiClient;

  @override
  Future<GenerationJobModel> requestGeneration(
    TeacherGenerationRequestModel request, {
    String? idempotencyKey,
  }) async {
    final path = request.contentType == 'worksheet'
        ? '/api/v1/worksheets/generate'
        : (request.contentType == 'flashcard'
            ? '/api/v1/content/flashcards/generate'
            : '/api/v1/ai/teacher/generate');
    final uri = Uri.parse('$baseUrl$path');
    final payload = request.toJson();
    if (idempotencyKey != null) {
      payload['idempotency_key'] = idempotencyKey;
    }

    if (_apiClient != null) {
      final meUri = Uri.parse('$baseUrl/api/v1/me');
      final meRes = await _apiClient.get(meUri);
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

    final req = await _client.postUrl(uri);
    req.headers.set('Content-Type', 'application/json');
    if (authToken != null) {
      req.headers.set('Authorization', 'Bearer $authToken');
    }

    req.write(jsonEncode(payload));

    final res = await req.close();
    final body = await res.transform(utf8.decoder).join();

    if (res.statusCode != 200 && res.statusCode != 202) {
      throw HttpException(
        'Generation request rejected with HTTP ${res.statusCode}: $body',
        uri: uri,
      );
    }

    final data = jsonDecode(body) as Map<String, dynamic>;
    return GenerationJobModel.fromJson(data);
  }

  @override
  Future<GenerationJobModel> getJobStatus(String jobId) async {
    final uri = Uri.parse('$baseUrl/api/v1/ai/jobs/$jobId');

    if (_apiClient != null) {
      final res = await _apiClient.get(uri);
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return GenerationJobModel.fromJson(data);
    }

    final req = await _client.getUrl(uri);
    if (authToken != null) {
      req.headers.set('Authorization', 'Bearer $authToken');
    }

    final res = await req.close();
    final body = await res.transform(utf8.decoder).join();

    if (res.statusCode != 200) {
      throw HttpException(
        'Failed to get job status HTTP ${res.statusCode}: $body',
        uri: uri,
      );
    }

    final data = jsonDecode(body) as Map<String, dynamic>;
    return GenerationJobModel.fromJson(data);
  }

  @override
  Future<GenerationJobModel> approveJob(
    String jobId, {
    String? santaliScriptConfirmed,
    String? notes,
  }) async {
    final uri = Uri.parse('$baseUrl/api/v1/ai/jobs/$jobId/approve');

    if (_apiClient != null) {
      final res = await _apiClient.post(uri, body: {
        'santali_script_confirmed': santaliScriptConfirmed ?? 'Olck',
        if (notes != null) 'notes': notes,
      });
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return GenerationJobModel.fromJson(data);
    }

    final req = await _client.postUrl(uri);
    req.headers.set('Content-Type', 'application/json');
    if (authToken != null) {
      req.headers.set('Authorization', 'Bearer $authToken');
    }

    req.write(jsonEncode({
      'santali_script_confirmed': santaliScriptConfirmed ?? 'Olck',
      if (notes != null) 'notes': notes,
    }));

    final res = await req.close();
    final body = await res.transform(utf8.decoder).join();

    if (res.statusCode != 200) {
      throw HttpException(
        'Failed to approve job HTTP ${res.statusCode}: $body',
        uri: uri,
      );
    }

    final data = jsonDecode(body) as Map<String, dynamic>;
    return GenerationJobModel.fromJson(data);
  }

  @override
  Future<File> downloadAsset(String assetUrlOrPath, String localFileName) async {
    // Atomic download: write to temp file then rename
    final directory = await getApplicationDocumentsDirectory();
    final finalPath = '${directory.path}/$localFileName';
    final tempPath = '$finalPath.tmp';

    final tempFile = File(tempPath);
    if (tempFile.existsSync()) {
      tempFile.deleteSync();
    }

    // Determine download URL: full HTTP URLs pass through; canonical
    // worksheet download paths (worksheets/<id>/download) resolve under
    // /api/v1/; legacy storage asset paths resolve under /api/v1/storage/.
    final uri = assetUrlOrPath.startsWith('http')
        ? Uri.parse(assetUrlOrPath)
        : assetUrlOrPath.endsWith('/download')
            ? Uri.parse('$baseUrl/api/v1/$assetUrlOrPath')
            : Uri.parse('$baseUrl/api/v1/storage/$assetUrlOrPath');

    try {
      // Prefer the authenticated client (Supabase session) when available so
      // protected worksheet artifacts download with the teacher's session.
      final apiClient = _apiClient;
      if (apiClient != null) {
        final res = await apiClient.get(uri);
        final int status = res.statusCode as int;
        if (status != 200) {
          throw HttpException(
            'Asset download failed HTTP $status',
            uri: uri,
          );
        }
        final List<int> bodyBytes =
            List<int>.from(res.bodyBytes as List<int>);
        final sink = tempFile.openWrite();
        sink.add(bodyBytes);
        await sink.flush();
        await sink.close();
        return tempFile.renameSync(finalPath);
      }
      final req = await _client.getUrl(uri);
      if (authToken != null) {
        req.headers.set('Authorization', 'Bearer $authToken');
      }

      final res = await req.close();
      if (res.statusCode != 200) {
        throw HttpException(
          'Asset download failed HTTP ${res.statusCode}',
          uri: uri,
        );
      }

      final sink = tempFile.openWrite();
      await res.pipe(sink);
      await sink.flush();
      await sink.close();

      // Atomic rename
      final finalFile = tempFile.renameSync(finalPath);
      return finalFile;
    } catch (e) {
      if (tempFile.existsSync()) {
        try {
          tempFile.deleteSync();
        } catch (_) {}
      }
      rethrow;
    }
  }
}

class MockRemoteContentDataSource implements RemoteContentDataSource {
  // Demo stub only: never fabricate worksheet content or translations.
  // Server generation is required; connect the app to the backend.
  @override
  Future<GenerationJobModel> requestGeneration(
    TeacherGenerationRequestModel request, {
    String? idempotencyKey,
  }) async {
    return GenerationJobModel(
      jobId: 'mock_unavailable',
      status: 'FAILED',
      contentType: request.contentType,
      grade: request.grade,
      targetLanguage: request.targetLanguage,
      error: 'Server generation is unavailable in demo mode. '
          'Connect to the FastAPI backend to generate worksheets.',
    );
  }

  @override
  Future<GenerationJobModel> getJobStatus(String jobId) async {
    return GenerationJobModel(
      jobId: jobId,
      status: 'FAILED',
      contentType: 'worksheet',
      grade: 1,
      targetLanguage: 'sat',
      error: 'Server generation is unavailable in demo mode.',
    );
  }

  @override
  Future<GenerationJobModel> approveJob(
    String jobId, {
    String? santaliScriptConfirmed,
    String? notes,
  }) async {
    return GenerationJobModel(
      jobId: jobId,
      status: 'FAILED',
      contentType: 'worksheet',
      grade: 1,
      targetLanguage: 'sat',
      error: 'Server generation is unavailable in demo mode.',
    );
  }

  @override
  Future<File> downloadAsset(String assetUrlOrPath, String localFileName) async {
    final dir = Directory.systemTemp;
    final file = File('${dir.path}/$localFileName');
    await file.writeAsString('Mock asset content for $localFileName');
    return file;
  }
}
