import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../database/account_scope.dart';
import '../database/app_database.dart';
import '../enums/app_enums.dart';
import '../models/app_models.dart';
import 'remote_content_data_source.dart';

/// Server entity type for queued offline worksheet generation requests.
const String kWorksheetGenerationEntityType = 'worksheet_generation';

/// Local lifecycle for a generation request. Maps onto the sync queue row:
/// PENDING_GENERATION == PENDING, UPLOADING/SERVER_PROCESSING == SYNCING,
/// COMPLETED == SYNCED + SavedMaterial present, FAILED_RETRYABLE == FAILED.
class WorksheetGenerationStatus {
  static const pendingGeneration = 'PENDING_GENERATION';
  static const uploading = 'UPLOADING';
  static const serverProcessing = 'SERVER_PROCESSING';
  static const completed = 'COMPLETED';
  static const failedRetryable = 'FAILED_RETRYABLE';
}

String tribalLanguageToServerCode(TribalLanguage language) {
  switch (language) {
    case TribalLanguage.santali:
      return 'sat';
    case TribalLanguage.ho:
      return 'ho';
    case TribalLanguage.mundari:
      return 'unr';
    case TribalLanguage.all:
      throw ArgumentError('Select a single target mother tongue for generation.');
  }
}

/// Maps a worksheet-registry language code to the legacy TribalLanguage enum
/// (Ho/Mundari/Santali). Hindi/English have no TribalLanguage member, so they
/// map to Mundari only as a legacy fallback — callers should prefer
/// WorksheetLanguages.byCode for display.
TribalLanguage serverCodeToTribalLanguage(String code) {
  switch (code.toLowerCase()) {
    case 'sat':
    case 'sat-in':
    case 'santali':
      return TribalLanguage.santali;
    case 'ho':
      return TribalLanguage.ho;
    case 'unr':
    case 'mundari':
      return TribalLanguage.mundari;
    default:
      return TribalLanguage.mundari;
  }
}

String difficultyToServerCode(DifficultyLevel difficulty) {
  switch (difficulty) {
    case DifficultyLevel.easy:
      return 'easy';
    case DifficultyLevel.challenging:
      return 'hard';
    case DifficultyLevel.medium:
      return 'medium';
  }
}

String worksheetTypeToServerCode(WorksheetType type) {
  switch (type) {
    case WorksheetType.practice:
      return 'practice';
    case WorksheetType.matching:
      return 'matching';
    case WorksheetType.fillInTheBlanks:
      return 'fill_blank';
    case WorksheetType.multipleChoice:
      return 'multiple_choice';
    case WorksheetType.counting:
      return 'counting';
    case WorksheetType.writing:
      return 'writing';
    case WorksheetType.reading:
      return 'reading';
  }
}

/// Builds a full generation request from the teacher's on-screen selections.
/// No values are hardcoded: every field comes from the caller.
TeacherGenerationRequestModel buildWorksheetGenerationRequest({
  required int grade,
  String section = 'General',
  required String subject,
  required String topic,
  String topicSource = 'curriculum',
  String? topicId,
  String topicInputLanguage = 'en',
  String? nipunOutcome,
  String language1 = 'hi',
  String language2 = 'sat',
  // Legacy single-target callers (tests, older screens).
  TribalLanguage? targetLanguage,
  required DifficultyLevel difficulty,
  // Multi-select worksheet types (preferred).
  List<WorksheetType>? types,
  // Legacy single type.
  WorksheetType? type,
  required int questionCount,
  required bool visualSupport,
  required bool bilingualAnswers,
  required bool audioCue,
  String? deviceId,
  String? teacherId,
  String origin = 'online',
  String? requestId,
}) {
  final resolvedId = requestId ?? const Uuid().v4();
  var l1 = language1;
  var l2 = language2;
  if (targetLanguage != null) {
    l2 = tribalLanguageToServerCode(targetLanguage);
  }
  final selectedTypes = types ?? (type != null ? [type] : const [WorksheetType.practice]);
  final typeCodes = selectedTypes.map(worksheetTypeToServerCode).toList();
  final outcome = nipunOutcome ?? '';
  return TeacherGenerationRequestModel(
    contentType: 'worksheet',
    grade: grade,
    section: section,
    subject: subject,
    outcomeCode: outcome.isNotEmpty ? outcome : null,
    targetLanguage: l2,
    difficulty: difficultyToServerCode(difficulty),
    worksheetType: typeCodes.isNotEmpty ? typeCodes.first : 'practice',
    worksheetTypes: typeCodes.isNotEmpty ? typeCodes : const ['practice'],
    questionCount: questionCount,
    idempotencyKey: resolvedId,
    requestId: resolvedId,
    topicSource: topicSource,
    topicId: topicId,
    topicInputLanguage: topicInputLanguage,
    topic: topic,
    nipunOutcome: outcome.isNotEmpty ? outcome : null,
    sourceLanguage: l1,
    language1: l1,
    language2: l2,
    visualSupport: visualSupport,
    bilingualAnswers: bilingualAnswers,
    audioCue: audioCue,
    deviceId: deviceId,
    teacherId: teacherId,
    origin: origin,
    createdAt: DateTime.now().toIso8601String(),
  );
}

/// Builds a Santali flashcard generation request (Hi/En/Sat only).
/// Every field comes from the teacher's on-screen selections.
TeacherGenerationRequestModel buildFlashcardGenerationRequest({
  required int grade,
  String section = 'General',
  required String subject,
  required String topic,
  String topicSource = 'curriculum',
  String? topicId,
  String topicInputLanguage = 'en',
  String? nipunOutcome,
  String? strand,
  String languageMode = 'hi_sat',
  String flashcardType = 'vocabulary',
  required int cardCount,
  required DifficultyLevel difficulty,
  String visualStyle = 'illustrated',
  bool pronunciation = false,
  String? deviceId,
  String? teacherId,
  String origin = 'online',
  String? requestId,
}) {
  final resolvedId = requestId ?? const Uuid().v4();
  final outcome = nipunOutcome ?? '';
  return TeacherGenerationRequestModel(
    contentType: 'flashcard',
    grade: grade,
    section: section,
    subject: subject,
    outcomeCode: outcome.isNotEmpty ? outcome : null,
    targetLanguage: 'sat',
    difficulty: difficultyToServerCode(difficulty),
    questionCount: cardCount,
    idempotencyKey: resolvedId,
    requestId: resolvedId,
    topicSource: topicSource,
    topicId: topicId,
    topicInputLanguage: topicInputLanguage,
    topic: topic,
    nipunOutcome: outcome.isNotEmpty ? outcome : null,
    sourceLanguage: 'hi',
    language1: 'hi',
    language2: 'sat',
    visualSupport: true,
    bilingualAnswers: true,
    audioCue: pronunciation,
    deviceId: deviceId,
    teacherId: teacherId,
    origin: origin,
    createdAt: DateTime.now().toIso8601String(),
    languageMode: languageMode,
    flashcardType: flashcardType,
    cardCount: cardCount,
    visualStyle: visualStyle,
    pronunciation: pronunciation,
    strand: strand,
  );
}

/// Stores an offline generation request in the sync queue (PENDING).
/// The row survives screen changes and app/device restarts. No remote
/// call is made here.
Future<String> queueWorksheetGenerationRequest(
  AppDatabase db,
  TeacherGenerationRequestModel request,
) async {
  final requestId = request.requestId ?? const Uuid().v4();
  final now = DateTime.now();
  await db.syncQueueDao.enqueue(
    SyncQueueCompanion(
      id: Value(requestId),
      entityType: const Value(kWorksheetGenerationEntityType),
      entityId: Value(requestId),
      operation: const Value('CREATE'),
      payload: Value(jsonEncode(request.toJson())),
      createdAt: Value(now),
      updatedAt: Value(now),
      status: const Value('PENDING'),
    ),
  );
  return requestId;
}

/// Shared SavedMaterials mapping for server-generated worksheets.
/// Used by both ContentGenerationBloc and the post-sync completion step.
SavedMaterialsCompanion savedMaterialFromGenerationContent(
  String contentId,
  Map<String, dynamic> payload,
) {
  final title = (payload['title'] ?? 'Generated Worksheet').toString();
  final titleHi = (payload['title_hi'] ?? title).toString();
  final grade = (payload['grade'] as num?)?.toInt() ?? 1;
  final subject = (payload['subject'] ?? 'Mathematics').toString();
  final outcomeCode = (payload['curriculum_id'] ?? payload['nipun_outcome'] ?? '').toString();
  final language = (payload['target_language'] ?? 'sat').toString();
  final difficulty = (payload['difficulty'] ?? 'medium').toString();
  final contentType = (payload['content_type'] ?? 'worksheet').toString();
  return SavedMaterialsCompanion(
    id: Value(contentId),
    type: Value(contentType),
    title: Value(title),
    titleHi: Value(titleHi),
    grade: Value(grade),
    subject: Value(subject),
    outcomeCode: Value(outcomeCode),
    language: Value(language),
    difficulty: Value(difficulty),
    contentJson: Value(jsonEncode(payload)),
    createdAt: Value(DateTime.now()),
    isFavorite: const Value(true),
  );
}

/// Completes synced worksheet generations: persists each completed server
/// result into SavedMaterials (idempotent) so it appears in Saved Materials,
/// Worksheet Preview, and teacher Progress. Returns saved content ids.
class WorksheetGenerationCompletion {  final AppDatabase db;
  final RemoteContentDataSource contentDataSource;

  WorksheetGenerationCompletion({
    required this.db,
    required this.contentDataSource,
  });

  /// Resolves the authenticated owner for a synced queue operation: the
  /// `owner_user_id` column first, then the queued payload's owner fields.
  /// Never trusts email/name/device values — Supabase user UUID only.
  Future<String?> _ownerForOp(SyncQueueData op) async {
    try {
      final rows = await db.customSelect(
        'SELECT owner_user_id FROM sync_queue WHERE id = ? LIMIT 1',
        variables: [Variable.withString(op.id)],
      ).get();
      if (rows.isNotEmpty) {
        final col = (rows.first.data['owner_user_id'] ?? '').toString().trim();
        if (col.isNotEmpty) return col;
      }
    } catch (_) {}
    try {
      final payload = jsonDecode(op.payload);
      if (payload is Map) {
        final map = Map<String, dynamic>.from(payload);
        // The queued request embeds owner_user_id at enqueue time; teacher_id
        // is accepted only as a legacy fallback for rows written before the
        // owner column existed (both carry the Supabase UUID, never email).
        final owner = (map['owner_user_id'] ?? map['ownerUserId'] ?? map['teacher_id'] ?? '')
            .toString()
            .trim();
        if (owner.isNotEmpty) return owner;
      }
    } catch (_) {}
    return null;
  }

  Future<List<String>> completeFromSyncResult(
    SyncQueueData op,
    Map<String, dynamic>? result,
  ) async {
    if (op.entityType != kWorksheetGenerationEntityType) return const [];
    final data = result?['data'] as Map<String, dynamic>?;
    if (data == null) return const [];
    final content = data['content'] as Map<String, dynamic>?;
    final contentId = (data['content_id'] ?? data['request_id'])?.toString();
    if (content == null || contentId == null || contentId.isEmpty) {
      return const [];
    }
    final existing = await db.resourceDao.getSavedMaterialById(contentId);
    if (existing == null) {
      await db.resourceDao.insertSavedMaterial(
        savedMaterialFromGenerationContent(contentId, content),
      );
    }
    // Claim ownership so the completed worksheet is visible to the teacher
    // who queued it (and invisible to other accounts). Without this claim,
    // sync-completed rows stay unowned: hidden from scoped repository reads
    // yet exposed through unscoped DAO reads.
    await claimOwnership(
      db,
      entityType: 'saved_material',
      entityId: contentId,
      ownerId: await _ownerForOp(op),
    );
    return [contentId];
  }

  /// Fetches a server job and saves it locally (used after sync when only a
  /// job id is known). Idempotent: existing materials are never duplicated.
  Future<String?> completeFromJob(String jobId, {String? ownerId}) async {
    final job = await contentDataSource.getJobStatus(jobId);
    final content = job.content;
    final contentId = job.contentId;
    if (content == null || contentId == null || contentId.isEmpty) return null;
    if (!job.isReady && !job.isReviewRequired) return null;
    final existing = await db.resourceDao.getSavedMaterialById(contentId);
    if (existing == null) {
      await db.resourceDao.insertSavedMaterial(
        savedMaterialFromGenerationContent(contentId, content),
      );
    }
    await claimOwnership(
      db,
      entityType: 'saved_material',
      entityId: contentId,
      ownerId: ownerId,
    );
    return contentId;
  }
}

WorksheetType _parseWorksheetTypeCode(String raw) {
  switch (raw.toLowerCase()) {
    case 'matching':
      return WorksheetType.matching;
    case 'fill_blank':
    case 'fillintheblanks':
      return WorksheetType.fillInTheBlanks;
    case 'multiple_choice':
    case 'multiplechoice':
      return WorksheetType.multipleChoice;
    case 'counting':
      return WorksheetType.counting;
    case 'writing':
      return WorksheetType.writing;
    case 'reading':
      return WorksheetType.reading;
    case 'practice':
    default:
      return WorksheetType.practice;
  }
}

DifficultyLevel _parseDifficultyCode(String raw) {
  switch (raw.toLowerCase()) {
    case 'easy':
      return DifficultyLevel.easy;
    case 'hard':
    case 'challenging':
      return DifficultyLevel.challenging;
    case 'medium':
    default:
      return DifficultyLevel.medium;
  }
}

/// Builds a WorksheetItem for preview from a server-generated payload.
/// Used to feed the existing Worksheet Preview screen after online
/// generation or post-sync completion.
WorksheetItem worksheetItemFromGenerationPayload(Map<String, dynamic> payload) {
  final rawQuestions = (payload['questions'] as List?) ?? [];
  final questions = rawQuestions.map((q) {
    final m = (q as Map).cast<String, dynamic>();
    final opts = (m['options'] as List? ?? []).map((e) => e.toString()).toList();
    return WorksheetQuestion(
      questionNumber: (m['questionNumber'] as num?)?.toInt() ?? 0,
      promptHindi: (m['promptHindi'] ?? '').toString(),
      promptTribal: (m['promptTribal'] ?? '').toString(),
      visualIllustration: (m['visualIllustration'] ?? '').toString(),
      options: opts,
      answer: (m['answer'] ?? '').toString(),
    );
  }).toList();
  // Drop placeholder rows without prompts (never preview empty questions).
  final visible = questions.where((q) => q.promptHindi.isNotEmpty).toList();
  final rawTypes = payload['worksheet_types'];
  String rawType = 'practice';
  if (rawTypes is List && rawTypes.isNotEmpty) {
    rawType = rawTypes.first.toString();
  } else if (payload['worksheet_type'] != null) {
    rawType = payload['worksheet_type'].toString();
  } else if (payload['content_type'] != null) {
    rawType = payload['content_type'].toString();
  }
  return WorksheetItem(
    id: (payload['content_id'] ?? '').toString(),
    title: (payload['title'] ?? 'Generated Worksheet').toString(),
    titleHi: (payload['title_hi'] ?? payload['title'] ?? '').toString(),
    grade: (payload['grade'] as num?)?.toInt() ?? 1,
    subject: (payload['subject'] ?? 'Mathematics').toString(),
    outcomeCode: (payload['curriculum_id'] ?? payload['nipun_outcome'] ?? '').toString(),
    targetLanguage: serverCodeToTribalLanguage(
      ((payload['target_language'] ?? payload['language_2']) ?? 'sat').toString(),
    ),
    difficulty: _parseDifficultyCode((payload['difficulty'] ?? 'medium').toString()),
    type: _parseWorksheetTypeCode(rawType),
    questionCount: visible.length,
    questions: visible,
    createdAt: DateTime.now(),
  );
}
