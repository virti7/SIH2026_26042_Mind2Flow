import '../database/app_database.dart';
import '../enums/app_enums.dart';
import '../models/app_models.dart';
export 'http_remote_data_source.dart';

// ==============================================================================
// 1. FASTAPI & SUPABASE REMOTE DATA SOURCE ABSTRACTIONS
// ==============================================================================

/// Remote DataSource for teacher profiles and school assignment on FastAPI.
abstract class RemoteTeacherDataSource {
  Future<TeacherProfile> fetchTeacherProfile(String teacherId);
  Future<void> syncTeacherProfile(TeacherProfile profile);
}

/// Remote DataSource for curriculum, lessons, and delivery telemetry on FastAPI.
abstract class RemoteLessonDataSource {
  Future<List<LessonPlan>> fetchLessons({int? grade});
  Future<void> syncLesson(LessonPlan lesson);
  Future<void> syncLessonDeliveryProgress(String lessonId, int currentStep, bool isCompleted);
}

/// Remote DataSource for assessments, outcomes, and diagnosed gaps on FastAPI.
abstract class RemoteAssessmentDataSource {
  Future<List<AssessmentQuestionItem>> fetchQuestions(String outcomeCode);
  Future<void> syncAssessmentResult(AssessmentResultData result);
  Future<void> syncLearningGap(LearningGapData gap);
}

/// Remote DataSource for student roster and progress records on FastAPI.
abstract class RemoteProgressDataSource {
  Future<List<StudentRecord>> fetchStudents({int? grade});
  Future<void> syncStudentRecord(StudentRecord student);
}

/// Remote DataSource for NIPUN content packs hosted in Supabase Storage.
abstract class RemoteContentPackDataSource {
  Future<List<ContentPackInfo>> fetchAvailableContentPacks();
  Future<void> downloadContentPack(String packId);
}

/// Remote DataSource for MTB-MLE tribal language packs in Supabase Storage.
abstract class RemoteLanguagePackDataSource {
  Future<List<LanguagePackInfo>> fetchAvailableLanguagePacks();
  Future<void> downloadLanguagePack(String packId);
}

/// Central RemoteDataSource interface consumed by SyncManager to process queue operations.
abstract class RemoteDataSource {
  Future<void> pushSyncOperation(SyncQueueData item);

  /// Pushes one operation and returns the server's per-operation result when
  /// available (status, remote id, and optional `data` payload such as a
  /// completed worksheet generation). Defaults to the void push for
  /// implementations that do not surface results.
  Future<Map<String, dynamic>?> pushSyncOperationWithResult(SyncQueueData item) async {
    await pushSyncOperation(item);
    return null;
  }
}

// ==============================================================================
// 2. MOCK / BOUNDARY IMPLEMENTATION (Used when offline or for unit testing)
// ==============================================================================

class MockRemoteDataSource
    implements
        RemoteDataSource,
        RemoteTeacherDataSource,
        RemoteLessonDataSource,
        RemoteAssessmentDataSource,
        RemoteProgressDataSource,
        RemoteContentPackDataSource,
        RemoteLanguagePackDataSource {
  final List<SyncQueueData> receivedOperations = [];
  final List<TeacherProfile> syncedTeachers = [];
  final List<LessonPlan> syncedLessons = [];
  final List<AssessmentResultData> syncedResults = [];
  final List<LearningGapData> syncedGaps = [];

  bool shouldFail = false;
  String failMessage = 'Simulated network timeout connecting to district server';

  @override
  Future<void> pushSyncOperation(SyncQueueData item) async {
    // Simulate network latency
    await Future.delayed(const Duration(milliseconds: 20));

    if (shouldFail) {
      throw Exception(failMessage);
    }

    receivedOperations.add(item);
  }

  @override
  Future<Map<String, dynamic>?> pushSyncOperationWithResult(
      SyncQueueData item) async {
    await pushSyncOperation(item);
    return null;
  }

  // --- RemoteTeacherDataSource ---
  @override
  Future<TeacherProfile> fetchTeacherProfile(String teacherId) async {
    if (shouldFail) throw Exception(failMessage);
    // Boundary mock carries no fictional identity: callers fall back to the
    // locally saved profile (or empty fields when none exists yet).
    return const TeacherProfile(
      id: 'teacher_primary',
      name: '',
      school: '',
      district: '',
      state: 'Jharkhand',
      classesTaught: [1, 2, 3],
      teachingLanguage: 'Hindi',
      supportedClassroomLanguages: [
        TribalLanguage.mundari,
        TribalLanguage.ho,
        TribalLanguage.santali,
      ],
      activeSessionLanguage: TribalLanguage.mundari,
    );
  }

  @override
  Future<void> syncTeacherProfile(TeacherProfile profile) async {
    if (shouldFail) throw Exception(failMessage);
    syncedTeachers.add(profile);
  }

  // --- RemoteLessonDataSource ---
  @override
  Future<List<LessonPlan>> fetchLessons({int? grade}) async {
    if (shouldFail) throw Exception(failMessage);
    return [];
  }

  @override
  Future<void> syncLesson(LessonPlan lesson) async {
    if (shouldFail) throw Exception(failMessage);
    syncedLessons.add(lesson);
  }

  @override
  Future<void> syncLessonDeliveryProgress(String lessonId, int currentStep, bool isCompleted) async {
    if (shouldFail) throw Exception(failMessage);
  }

  // --- RemoteAssessmentDataSource ---
  @override
  Future<List<AssessmentQuestionItem>> fetchQuestions(String outcomeCode) async {
    if (shouldFail) throw Exception(failMessage);
    return [];
  }

  @override
  Future<void> syncAssessmentResult(AssessmentResultData result) async {
    if (shouldFail) throw Exception(failMessage);
    syncedResults.add(result);
  }

  @override
  Future<void> syncLearningGap(LearningGapData gap) async {
    if (shouldFail) throw Exception(failMessage);
    syncedGaps.add(gap);
  }

  // --- RemoteProgressDataSource ---
  @override
  Future<List<StudentRecord>> fetchStudents({int? grade}) async {
    if (shouldFail) throw Exception(failMessage);
    return [];
  }

  @override
  Future<void> syncStudentRecord(StudentRecord student) async {
    if (shouldFail) throw Exception(failMessage);
  }

  // --- RemoteContentPackDataSource ---
  @override
  Future<List<ContentPackInfo>> fetchAvailableContentPacks() async {
    if (shouldFail) throw Exception(failMessage);
    return [];
  }

  @override
  Future<void> downloadContentPack(String packId) async {
    if (shouldFail) throw Exception(failMessage);
  }

  // --- RemoteLanguagePackDataSource ---
  @override
  Future<List<LanguagePackInfo>> fetchAvailableLanguagePacks() async {
    if (shouldFail) throw Exception(failMessage);
    return [];
  }

  @override
  Future<void> downloadLanguagePack(String packId) async {
    if (shouldFail) throw Exception(failMessage);
  }

  void reset() {
    receivedOperations.clear();
    syncedTeachers.clear();
    syncedLessons.clear();
    syncedResults.clear();
    syncedGaps.clear();
    shouldFail = false;
  }
}

/// Web placeholder for the native generic sync data source.
///
/// `MockRemoteDataSource` is restricted to tests and explicit mock mode: it
/// must never back production traffic. On web there is no native SyncManager
/// queue, so the generic sync data source is genuinely unavailable — browser
/// worksheet uploads go through the web worksheet sync adapter and classroom
/// sync through the offline repository instead. Throwing here (instead of
/// silently succeeding) guarantees no web flow can mistake "mock" for
/// "server".
class WebUnavailableRemoteDataSource implements RemoteDataSource {
  const WebUnavailableRemoteDataSource();

  @override
  Future<void> pushSyncOperation(SyncQueueData item) async {
    throw UnsupportedError('Native sync queue is not available on web.');
  }

  @override
  Future<Map<String, dynamic>?> pushSyncOperationWithResult(
      SyncQueueData item) async {
    throw UnsupportedError('Native sync queue is not available on web.');
  }
}
