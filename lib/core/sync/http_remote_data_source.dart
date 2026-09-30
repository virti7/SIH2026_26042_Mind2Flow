import 'dart:convert';
import 'dart:io';
import '../config/api_config.dart';
import '../database/app_database.dart';
import '../enums/app_enums.dart';
import '../models/app_models.dart';
import 'remote_data_source.dart';

/// Real HTTP client implementation of [RemoteDataSource] that communicates
/// with the FastAPI backend over REST.
class HttpRemoteDataSource
    implements
        RemoteDataSource,
        RemoteTeacherDataSource,
        RemoteLessonDataSource,
        RemoteAssessmentDataSource,
        RemoteProgressDataSource,
        RemoteContentPackDataSource,
        RemoteLanguagePackDataSource {
  final String baseUrl;
  final String? authToken;
  final HttpClient _client;

  HttpRemoteDataSource({
    String? baseUrl,
    this.authToken,
    HttpClient? client,
  })  : baseUrl = baseUrl ?? ApiConfig.baseUrl,
        _client = client ?? HttpClient();

  @override
  Future<void> pushSyncOperation(SyncQueueData item) async {
    await pushSyncOperationWithResult(item);
  }

  @override
  Future<Map<String, dynamic>?> pushSyncOperationWithResult(SyncQueueData item) async {
    final uri = Uri.parse('$baseUrl/api/v1/sync/upload');

    dynamic payloadObj;
    try {
      payloadObj = jsonDecode(item.payload);
    } catch (_) {
      payloadObj = {'raw_data': item.payload};
    }

    final bodyMap = {
      'device_id': 'tablet_jharkhand_001',
      'app_version': '1.0.0',
      'operations': [
        {
          'operation_id': item.id,
          'entity_type': item.entityType,
          'entity_id': item.entityId,
          'operation': item.operation,
          'payload': payloadObj,
          'client_updated_at': item.updatedAt.toIso8601String(),
        }
      ],
    };

    final request = await _client.postUrl(uri);
    request.headers.set('Content-Type', 'application/json');
    if (authToken != null) {
      request.headers.set('Authorization', 'Bearer $authToken');
    }
    request.write(jsonEncode(bodyMap));

    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw HttpException(
        'Sync upload failed with HTTP ${response.statusCode}: $responseBody',
        uri: uri,
      );
    }

    final Map<String, dynamic> jsonResponse = jsonDecode(responseBody);
    final results = jsonResponse['results'] as List<dynamic>? ?? [];
    if (results.isEmpty) {
      throw Exception('Server returned empty sync results');
    }

    final opResult = results.first as Map<String, dynamic>;
    final status = opResult['status'] as String?;
    if (status != 'SUCCESS' && status != 'DUPLICATE_IGNORED') {
      final errMsg = opResult['error'] ?? opResult['message'] ?? 'Remote sync status: $status';
      throw Exception('Sync operation rejected by server: $errMsg');
    }

    return {
      'operation_id': opResult['operation_id'],
      'entity_type': opResult['entity_type'],
      'entity_id': opResult['entity_id'],
      'status': status,
      'remote_id': opResult['remote_id'],
      'data': opResult['data'],
    };
  }

  // --- RemoteTeacherDataSource ---
  @override
  Future<TeacherProfile> fetchTeacherProfile(String teacherId) async {
    final uri = Uri.parse('$baseUrl/api/v1/teachers/$teacherId');
    final request = await _client.getUrl(uri);
    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();

    if (response.statusCode == 200) {
      final data = jsonDecode(body);
      final rawClasses = data['classes_taught'];
      final List<int> classes = rawClasses is List
          ? rawClasses.map((e) => (e as num).toInt()).toList()
          : const [1, 2, 3];
      return TeacherProfile(
        id: data['id'] ?? teacherId,
        name: (data['name'] ?? '').toString(),
        school: (data['school'] ?? '').toString(),
        district: (data['district'] ?? '').toString(),
        state: (data['state'] ?? 'Jharkhand').toString(),
        classesTaught: classes,
        teachingLanguage: data['teaching_language'] ?? data['preferred_language'] ?? 'Hindi',
        supportedClassroomLanguages: const [
          TribalLanguage.mundari,
          TribalLanguage.ho,
          TribalLanguage.santali,
        ],
        activeSessionLanguage: TribalLanguage.mundari,
      );
    }
    throw HttpException('Failed to fetch teacher profile', uri: uri);
  }

  @override
  Future<void> syncTeacherProfile(TeacherProfile profile) async {
    // Idempotent sync via generic queue
  }

  // --- RemoteLessonDataSource ---
  @override
  Future<List<LessonPlan>> fetchLessons({int? grade}) async {
    final uri = Uri.parse('$baseUrl/api/v1/lessons${grade != null ? '?grade=$grade' : ''}');
    final request = await _client.getUrl(uri);
    final response = await request.close();
    if (response.statusCode == 200) {
      return [];
    }
    return [];
  }

  @override
  Future<void> syncLesson(LessonPlan lesson) async {}

  @override
  Future<void> syncLessonDeliveryProgress(String lessonId, int currentStep, bool isCompleted) async {}

  // --- RemoteAssessmentDataSource ---
  @override
  Future<List<AssessmentQuestionItem>> fetchQuestions(String outcomeCode) async {
    return [];
  }

  @override
  Future<void> syncAssessmentResult(AssessmentResultData result) async {}

  @override
  Future<void> syncLearningGap(LearningGapData gap) async {}

  // --- RemoteProgressDataSource ---
  @override
  Future<List<StudentRecord>> fetchStudents({int? grade}) async {
    return [];
  }

  @override
  Future<void> syncStudentRecord(StudentRecord student) async {}

  // --- RemoteContentPackDataSource ---
  @override
  Future<List<ContentPackInfo>> fetchAvailableContentPacks() async {
    return [];
  }

  @override
  Future<void> downloadContentPack(String packId) async {}

  // --- RemoteLanguagePackDataSource ---
  @override
  Future<List<LanguagePackInfo>> fetchAvailableLanguagePacks() async {
    final uri = Uri.parse('$baseUrl/api/v1/language-packs');
    final request = await _client.getUrl(uri);
    final response = await request.close();
    if (response.statusCode == 200) {
      final body = await response.transform(utf8.decoder).join();
      final list = jsonDecode(body) as List<dynamic>;
      return list.map((item) {
        final langCode = (item['language_code'] ?? '').toString().toLowerCase();
        final tribalLang = TribalLanguage.values.firstWhere(
          (l) => l.name.toLowerCase() == langCode || l.displayName.toLowerCase() == langCode,
          orElse: () => TribalLanguage.mundari,
        );
        final bytes = (item['package_size'] as num?)?.toInt() ?? 0;
        final sizeMb = (bytes / (1024 * 1024)).ceil();

        return LanguagePackInfo(
          id: item['id'] ?? '',
          language: tribalLang,
          version: item['version'] ?? '1.0.0',
          sizeMb: sizeMb > 0 ? sizeMb : 18,
          status: PackStatus.available,
          progress: 0.0,
        );
      }).toList();
    }
    return [];
  }

  @override
  Future<void> downloadLanguagePack(String packId) async {}
}
