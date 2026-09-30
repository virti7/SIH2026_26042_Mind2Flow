import '../enums/app_enums.dart';

/// Central Domain Models for Maatribhasha

class TeacherProfile {
  final String id;
  final String name;
  final String school;
  final String district;
  final String state;
  final List<int> classesTaught;
  final String teachingLanguage;
  final List<TribalLanguage> supportedClassroomLanguages;
  final TribalLanguage activeSessionLanguage;

  const TeacherProfile({
    required this.id,
    required this.name,
    required this.school,
    required this.district,
    required this.state,
    required this.classesTaught,
    required this.teachingLanguage,
    required this.supportedClassroomLanguages,
    required this.activeSessionLanguage,
  });

  TeacherProfile copyWith({
    String? id,
    String? name,
    String? school,
    String? district,
    String? state,
    List<int>? classesTaught,
    String? teachingLanguage,
    List<TribalLanguage>? supportedClassroomLanguages,
    TribalLanguage? activeSessionLanguage,
  }) {
    return TeacherProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      school: school ?? this.school,
      district: district ?? this.district,
      state: state ?? this.state,
      classesTaught: classesTaught ?? this.classesTaught,
      teachingLanguage: teachingLanguage ?? this.teachingLanguage,
      supportedClassroomLanguages: supportedClassroomLanguages ?? this.supportedClassroomLanguages,
      activeSessionLanguage: activeSessionLanguage ?? this.activeSessionLanguage,
    );
  }
}

class NipunOutcome {
  final String id;
  final String code; // e.g. M2.1.4
  final int grade;
  final String domain; // e.g. Foundational Numeracy
  final String competency; // e.g. Numbers and Operations
  final String titleEn;
  final String titleHi;
  final String targetDescription;
  final OutcomeStatus defaultStatus;
  final String unfinishedSkill;

  const NipunOutcome({
    required this.id,
    required this.code,
    required this.grade,
    required this.domain,
    required this.competency,
    required this.titleEn,
    required this.titleHi,
    required this.targetDescription,
    required this.defaultStatus,
    required this.unfinishedSkill,
  });
}

class LessonPlan {
  final String id;
  final String title;
  final String titleHi;
  final String outcomeCode;
  final String outcomeTitle;
  final int grade;
  final String subject;
  final int durationMinutes;
  final String learningObjective;
  final String prerequisiteKnowledge;
  final String teacherMoves;
  final String activityOverview;
  final String assessmentStrategy;
  final String remediationOption;
  final Map<String, String> tribalVocabulary;
  final List<String> requiredMaterials;
  final List<LessonStep> steps;

  const LessonPlan({
    required this.id,
    required this.title,
    required this.titleHi,
    required this.outcomeCode,
    required this.outcomeTitle,
    required this.grade,
    required this.subject,
    required this.durationMinutes,
    required this.learningObjective,
    required this.prerequisiteKnowledge,
    required this.teacherMoves,
    required this.activityOverview,
    required this.assessmentStrategy,
    required this.remediationOption,
    required this.tribalVocabulary,
    required this.requiredMaterials,
    required this.steps,
  });
}

class LessonStep {
  final int stepNumber;
  final DeliveryStage stage;
  final String title;
  final String titleHi;
  final String scriptHindi;
  final String scriptTribal;
  final String teacherTip;
  final String localContextPrompt;

  const LessonStep({
    required this.stepNumber,
    required this.stage,
    required this.title,
    required this.titleHi,
    required this.scriptHindi,
    required this.scriptTribal,
    required this.teacherTip,
    required this.localContextPrompt,
  });
}

class LocalContextItem {
  final String id;
  final String category; // Local Objects, Stories, Environment, Mathematics, Language
  final String title;
  final String titleHi;
  final String description;
  final String culturalRelevance;
  final String tribalTerm;
  final TribalLanguage language;

  const LocalContextItem({
    required this.id,
    required this.category,
    required this.title,
    required this.titleHi,
    required this.description,
    required this.culturalRelevance,
    required this.tribalTerm,
    required this.language,
  });
}

class ActivityItem {
  final String id;
  final String title;
  final String titleHi;
  final int grade;
  final String subject;
  final String strandOrStage;
  final TribalLanguage language;
  final int durationMinutes;
  final DifficultyLevel difficulty;
  final String materials;
  final List<String> teacherSteps;
  final List<String> studentSteps;
  final List<String> questions;
  final String expectedResponse;
  final String audioPromptHindi;
  final String audioPromptTribal;

  const ActivityItem({
    required this.id,
    required this.title,
    required this.titleHi,
    required this.grade,
    required this.subject,
    required this.strandOrStage,
    required this.language,
    required this.durationMinutes,
    required this.difficulty,
    required this.materials,
    required this.teacherSteps,
    required this.studentSteps,
    required this.questions,
    required this.expectedResponse,
    required this.audioPromptHindi,
    required this.audioPromptTribal,
  });
}

class WorksheetQuestion {
  final int questionNumber;
  final String promptHindi;
  final String promptTribal;
  final String visualIllustration;
  final List<String> options;
  final String answer;

  const WorksheetQuestion({
    required this.questionNumber,
    required this.promptHindi,
    required this.promptTribal,
    required this.visualIllustration,
    required this.options,
    required this.answer,
  });
}

class WorksheetItem {
  final String id;
  final String title;
  final String titleHi;
  final int grade;
  final String subject;
  final String outcomeCode;
  final TribalLanguage targetLanguage;
  final DifficultyLevel difficulty;
  final WorksheetType type;
  final int questionCount;
  final List<WorksheetQuestion> questions;
  final DateTime createdAt;

  const WorksheetItem({
    required this.id,
    required this.title,
    required this.titleHi,
    required this.grade,
    required this.subject,
    required this.outcomeCode,
    required this.targetLanguage,
    required this.difficulty,
    required this.type,
    required this.questionCount,
    required this.questions,
    required this.createdAt,
  });
}

class FlashcardItem {
  final String id;
  final String topic;
  final String hindiWord;
  final String tribalWord;
  final TribalLanguage language;
  final String pronunciation;
  final String teacherPrompt;
  final String emojiOrIcon;
  final String exampleSentence;

  const FlashcardItem({
    required this.id,
    required this.topic,
    required this.hindiWord,
    required this.tribalWord,
    required this.language,
    required this.pronunciation,
    required this.teacherPrompt,
    required this.emojiOrIcon,
    required this.exampleSentence,
  });
}

class AssessmentQuestionItem {
  final int number;
  final String promptHindi;
  final String promptTribal;
  final QuestionType type;
  final List<String> choices;
  final int correctIndex;
  final String teacherObservationRubric;

  const AssessmentQuestionItem({
    required this.number,
    required this.promptHindi,
    required this.promptTribal,
    required this.type,
    required this.choices,
    required this.correctIndex,
    required this.teacherObservationRubric,
  });
}

class AssessmentResultData {
  final String id;
  final String studentName;
  final String studentId;
  final String outcomeCode;
  final String outcomeTitle;
  final int totalQuestions;
  final int correctCount;
  final OutcomeStatus status;
  final String unfinishedSkill;
  final String recommendedRemediation;
  final DateTime completedAt;

  const AssessmentResultData({
    required this.id,
    required this.studentName,
    required this.studentId,
    required this.outcomeCode,
    required this.outcomeTitle,
    required this.totalQuestions,
    required this.correctCount,
    required this.status,
    required this.unfinishedSkill,
    required this.recommendedRemediation,
    required this.completedAt,
  });
}

class StudentRecord {
  final String id;
  final String name;
  final int rollNumber;
  final int grade;
  final TribalLanguage motherTongue;
  final int achievedOutcomes;
  final int developingOutcomes;
  final int needsSupportOutcomes;
  final double literacyProgress;
  final double numeracyProgress;
  final String recentEvidence;
  final List<AssessmentResultData> assessmentHistory;
  final List<String> identifiedGaps;

  const StudentRecord({
    required this.id,
    required this.name,
    required this.rollNumber,
    required this.grade,
    required this.motherTongue,
    required this.achievedOutcomes,
    required this.developingOutcomes,
    required this.needsSupportOutcomes,
    required this.literacyProgress,
    required this.numeracyProgress,
    required this.recentEvidence,
    required this.assessmentHistory,
    required this.identifiedGaps,
  });

  StudentRecord copyWith({
    String? id,
    String? name,
    int? rollNumber,
    int? grade,
    TribalLanguage? motherTongue,
    int? achievedOutcomes,
    int? developingOutcomes,
    int? needsSupportOutcomes,
    double? literacyProgress,
    double? numeracyProgress,
    String? recentEvidence,
    List<AssessmentResultData>? assessmentHistory,
    List<String>? identifiedGaps,
  }) {
    return StudentRecord(
      id: id ?? this.id,
      name: name ?? this.name,
      rollNumber: rollNumber ?? this.rollNumber,
      grade: grade ?? this.grade,
      motherTongue: motherTongue ?? this.motherTongue,
      achievedOutcomes: achievedOutcomes ?? this.achievedOutcomes,
      developingOutcomes: developingOutcomes ?? this.developingOutcomes,
      needsSupportOutcomes: needsSupportOutcomes ?? this.needsSupportOutcomes,
      literacyProgress: literacyProgress ?? this.literacyProgress,
      numeracyProgress: numeracyProgress ?? this.numeracyProgress,
      recentEvidence: recentEvidence ?? this.recentEvidence,
      assessmentHistory: assessmentHistory ?? this.assessmentHistory,
      identifiedGaps: identifiedGaps ?? this.identifiedGaps,
    );
  }
}

class TranslationMessage {
  final String id;
  final bool isTeacher;
  final String speakerName;
  final String originalText;
  final String translatedText;
  final TribalLanguage targetLanguage;
  final DateTime timestamp;
  final int latencyMs;
  final bool isOfflineNmt;

  const TranslationMessage({
    required this.id,
    required this.isTeacher,
    required this.speakerName,
    required this.originalText,
    required this.translatedText,
    required this.targetLanguage,
    required this.timestamp,
    required this.latencyMs,
    required this.isOfflineNmt,
  });
}

class QuickPhrase {
  final String id;
  final String category;
  final String hindi;
  final String ho;
  final String mundari;
  final String santali;

  const QuickPhrase({
    required this.id,
    required this.category,
    required this.hindi,
    required this.ho,
    required this.mundari,
    required this.santali,
  });
}

class LanguagePackInfo {
  final String id;
  final TribalLanguage language;
  final int sizeMb;
  final String version;
  final PackStatus status;
  final double progress;

  const LanguagePackInfo({
    required this.id,
    required this.language,
    required this.sizeMb,
    required this.version,
    required this.status,
    required this.progress,
  });

  LanguagePackInfo copyWith({
    String? id,
    TribalLanguage? language,
    int? sizeMb,
    String? version,
    PackStatus? status,
    double? progress,
  }) {
    return LanguagePackInfo(
      id: id ?? this.id,
      language: language ?? this.language,
      sizeMb: sizeMb ?? this.sizeMb,
      version: version ?? this.version,
      status: status ?? this.status,
      progress: progress ?? this.progress,
    );
  }
}

class ContentPackInfo {
  final String id;
  final String title;
  final String description;
  final int sizeMb;
  final bool isInstalled;

  const ContentPackInfo({
    required this.id,
    required this.title,
    required this.description,
    required this.sizeMb,
    required this.isInstalled,
  });
}
