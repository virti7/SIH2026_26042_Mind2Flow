import '../enums/app_enums.dart';
import '../models/app_models.dart';

abstract class TeacherRepository {
  Future<TeacherProfile> getProfile();
  Future<void> updateProfile(TeacherProfile profile);
  Future<List<TribalLanguage>> getSelectedLanguages();
  Future<void> updateLanguages(List<TribalLanguage> languages);
}

abstract class LessonRepository {
  Future<List<NipunOutcome>> getOutcomes({int? grade, String? domain});
  Future<NipunOutcome?> getOutcomeByCode(String code);
  Future<LessonPlan> getLessonPlanForOutcome(String outcomeCode);
  Future<List<LocalContextItem>> getLocalContextItems({String? category});
  Future<List<ActivityItem>> getActivities({String? strand, int? grade, TribalLanguage? language});
  Future<ActivityItem?> getActivityById(String id);
  Future<LessonPlan> createLesson(LessonPlan plan);
  Future<LessonPlan> updateLesson(LessonPlan plan);
  Future<void> updateLessonDeliveryProgress(String lessonId, int currentStep, bool isCompleted);
  Future<Map<String, dynamic>?> getLessonDeliveryProgress(String lessonId);
}

/// A worksheet generation request stored for server-side generation.
/// The scaffold carries the teacher's real parameters; target-language
/// content arrives from the server (never fabricated locally).
class QueuedWorksheetGeneration {
  final String requestId;
  final WorksheetItem scaffold;

  const QueuedWorksheetGeneration({
    required this.requestId,
    required this.scaffold,
  });
}

abstract class ResourceRepository {
  /// Queues a worksheet generation request for server-side generation and
  /// returns the queued scaffold. Offline-safe: the request persists in the
  /// sync queue until Sync Now uploads it. Never invents translations.
  Future<QueuedWorksheetGeneration> generateWorksheet({
    required int grade,
    required String subject,
    required String outcomeCode,
    required TribalLanguage targetLanguage,
    required DifficultyLevel difficulty,
    required WorksheetType type,
    required int questionCount,
  });
  Future<List<FlashcardItem>> getFlashcards({required String topic, required TribalLanguage language});
  Future<List<WorksheetItem>> getSavedWorksheets();
  Future<List<FlashcardItem>> getSavedFlashcards();
  Future<List<ActivityItem>> getSavedActivities();
  Future<void> saveWorksheet(WorksheetItem item);
  Future<void> saveFlashcardSet({
    required String topic,
    required TribalLanguage language,
    required List<FlashcardItem> cards,
  });
}

abstract class AssessmentRepository {
  Future<List<AssessmentQuestionItem>> getQuestionsForOutcome(String outcomeCode);
  Future<AssessmentResultData> submitAssessment({
    required String studentId,
    required String studentName,
    required String outcomeCode,
    required List<int> selectedAnswers,
  });
  Future<ActivityItem> getRemedialActivityForOutcome(String outcomeCode);
  Future<AssessmentResultData> submitReassessment({
    required String studentId,
    required String outcomeCode,
    required bool passed,
  });
}

abstract class StudentRepository {
  Future<List<StudentRecord>> getStudents({int? grade});
  Future<StudentRecord?> getStudentById(String id);
  Future<void> updateOutcomeStatus(String studentId, String outcomeCode, OutcomeStatus newStatus);
}

abstract class TranslationRepository {
  Future<TranslationMessage> translateUtterance({
    required String text,
    required TribalLanguage targetLanguage,
    required bool isTeacher,
    Map<String, String>? contextMeta,
  });
  Future<List<QuickPhrase>> getQuickPhrases({String? category});
  Future<void> submitFeedback({
    required String original,
    required String translated,
    required String issueType,
    String? comment,
  });
}

abstract class OfflineRepository {
  Future<List<LanguagePackInfo>> getLanguagePacks();
  Future<void> downloadLanguagePack(String id);
  Future<List<ContentPackInfo>> getContentPacks();
  Future<void> syncClassroomData();
  Future<int> getPendingSyncCount();
  Future<SyncStatusState> getSyncStatus();
  Future<DateTime?> getLastSyncTime();
}
