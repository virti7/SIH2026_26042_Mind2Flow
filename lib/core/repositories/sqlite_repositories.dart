import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../database/account_scope.dart';
import '../database/app_database.dart';
import '../enums/app_enums.dart';
import '../models/app_models.dart';
import '../sync/sync_manager.dart';
import '../sync/worksheet_generation_sync.dart';
import 'app_repositories.dart';

const _uuid = Uuid();

/// Returns the authenticated owner or null. Shared by all Sqlite
/// repositories: unauthenticated access must yield empty account state.
String? _ownerOf(String? Function()? provider) {
  try {
    final id = provider?.call()?.trim();
    if (id == null || id.isEmpty) return null;
    return id;
  } catch (_) {
    return null;
  }
}

TribalLanguage _parseLanguage(String val) {
  switch (val.toLowerCase()) {
    case 'ho':
      return TribalLanguage.ho;
    case 'mundari':
    case 'mun':
      return TribalLanguage.mundari;
    case 'santali':
    case 'sat':
      return TribalLanguage.santali;
    default:
      return TribalLanguage.all;
  }
}

OutcomeStatus _parseStatus(String val) {
  switch (val.toLowerCase()) {
    case 'achieved':
      return OutcomeStatus.achieved;
    case 'needssupport':
    case 'needs_support':
      return OutcomeStatus.needsSupport;
    case 'developing':
    default:
      return OutcomeStatus.developing;
  }
}

QuestionType _parseQuestionType(String val) {
  switch (val.toLowerCase()) {
    case 'physical':
      return QuestionType.physical;
    case 'written':
      return QuestionType.written;
    case 'matching':
      return QuestionType.matching;
    case 'counting':
      return QuestionType.counting;
    case 'oral':
    default:
      return QuestionType.oral;
  }
}

DifficultyLevel _parseDifficulty(String val) {
  switch (val.toLowerCase()) {
    case 'challenging':
      return DifficultyLevel.challenging;
    case 'easy':
      return DifficultyLevel.easy;
    case 'medium':
    default:
      return DifficultyLevel.medium;
  }
}

WorksheetType _parseWorksheetType(String val) {
  switch (val.toLowerCase()) {
    case 'matching':
      return WorksheetType.matching;
    case 'fillintheblanks':
      return WorksheetType.fillInTheBlanks;
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

PackStatus _parsePackStatus(String val) {
  switch (val.toLowerCase()) {
    case 'downloading':
      return PackStatus.downloading;
    case 'updateavailable':
      return PackStatus.updateAvailable;
    case 'available':
      return PackStatus.available;
    case 'installed':
    default:
      return PackStatus.installed;
  }
}

// ==========================================
// 1. TEACHER REPOSITORY (SQLite + SyncQueue)
// ==========================================
class SqliteTeacherRepository implements TeacherRepository {
  final AppDatabase db;

  /// Resolves the authenticated Supabase user UUID. Null/empty means
  /// unauthenticated: teacher-owned access fails safe (empty profile).
  final String? Function()? currentUserIdProvider;

  SqliteTeacherRepository({required this.db, this.currentUserIdProvider});

  /// Legacy mode (provider not wired, e.g. older unit tests): preserves
  /// pre-isolation global reads. Production ALWAYS wires a provider, so
  /// account isolation is enforced there. A wired provider resolving to
  /// null means signed out -> fail-safe empty state.
  bool get _legacy => currentUserIdProvider == null;

  String? get _ownerId {
    try {
      final id = currentUserIdProvider?.call()?.trim();
      if (id == null || id.isEmpty) return null;
      return id;
    } catch (_) {
      return null;
    }
  }

  TeacherProfile _emptyProfile(String id) {
    return TeacherProfile(
      id: id.isEmpty ? 'teacher_primary' : id,
      name: '',
      school: '',
      district: '',
      state: 'Jharkhand',
      classesTaught: const [1, 2, 3],
      teachingLanguage: 'Hindi',
      supportedClassroomLanguages: const [
        TribalLanguage.mundari,
        TribalLanguage.ho,
        TribalLanguage.santali,
      ],
      activeSessionLanguage: TribalLanguage.mundari,
    );
  }

  @override
  Future<TeacherProfile> getProfile() async {
    final ownerId = _ownerId;
    if (_legacy) return _legacyProfile();
    // Unauthenticated: never leak another account's row.
    if (ownerId == null) return _emptyProfile('');
    await ensureAccountIsolation(db);
    final row = await db.teacherDao.getProfileById(ownerId);
    if (row != null) {
      final List<dynamic> classesList = jsonDecode(row.classesTaughtJson);
      final List<dynamic> langsList = jsonDecode(row.supportedLanguagesJson);

      return TeacherProfile(
        id: row.id,
        name: row.name,
        school: row.school,
        district: row.district,
        state: row.state,
        classesTaught: classesList.map((e) => (e as num).toInt()).toList(),
        teachingLanguage: row.teachingLanguage,
        supportedClassroomLanguages: langsList.map((e) => _parseLanguage(e.toString())).toList(),
        activeSessionLanguage: _parseLanguage(row.activeSessionLanguage),
      );
    }

    // Brand-new account: empty state scoped to this user, never another
    // teacher's row.
    return _emptyProfile(ownerId);
  }

  /// Pre-isolation global read used only when no owner provider is wired
  /// (older unit tests). Production never takes this path.
  Future<TeacherProfile> _legacyProfile() async {
    final row = await db.teacherDao.getProfile();
    if (row != null) {
      final List<dynamic> classesList = jsonDecode(row.classesTaughtJson);
      final List<dynamic> langsList = jsonDecode(row.supportedLanguagesJson);
      return TeacherProfile(
        id: row.id,
        name: row.name,
        school: row.school,
        district: row.district,
        state: row.state,
        classesTaught: classesList.map((e) => (e as num).toInt()).toList(),
        teachingLanguage: row.teachingLanguage,
        supportedClassroomLanguages: langsList.map((e) => _parseLanguage(e.toString())).toList(),
        activeSessionLanguage: _parseLanguage(row.activeSessionLanguage),
      );
    }
    return _emptyProfile('');
  }

  @override
  Future<void> updateProfile(TeacherProfile profile) async {
    final ownerId = _ownerId;
    if (_legacy) return _legacyUpdate(profile);
    // Never persist profile data without an authenticated owner.
    if (!_legacy && ownerId == null) return;
    // The row PK IS the Supabase user UUID: one row per teacher account.
    final scoped = profile.id.trim().isEmpty
        ? profile.copyWith(id: ownerId)
        : profile.copyWith(id: ownerId);
    final now = DateTime.now();
    final payloadJson = jsonEncode({
      'id': scoped.id,
      'owner_user_id': ownerId,
      'name': scoped.name,
      'school': scoped.school,
      'district': scoped.district,
      'state': scoped.state,
      'classes_taught': scoped.classesTaught,
      'teaching_language': scoped.teachingLanguage,
      'supported_languages': scoped.supportedClassroomLanguages.map((l) => l.name).toList(),
      'active_session_language': scoped.activeSessionLanguage.name,
      'updated_at': now.toIso8601String(),
    });

    // Transactional write: entity + sync queue
    await db.transaction(() async {
      await db.teacherDao.insertOrUpdateProfile(
        TeachersCompanion(
          id: Value(scoped.id),
          name: Value(scoped.name),
          school: Value(scoped.school),
          district: Value(scoped.district),
          state: Value(scoped.state),
          classesTaughtJson: Value(jsonEncode(scoped.classesTaught)),
          teachingLanguage: Value(scoped.teachingLanguage),
          supportedLanguagesJson: Value(jsonEncode(scoped.supportedClassroomLanguages.map((l) => l.name).toList())),
          activeSessionLanguage: Value(scoped.activeSessionLanguage.name),
          updatedAt: Value(now),
        ),
      );

      await db.syncQueueDao.enqueue(
        SyncQueueCompanion(
          id: Value(_uuid.v4()),
          entityType: const Value('teacher_profile'),
          entityId: Value(scoped.id),
          operation: const Value('UPDATE'),
          payload: Value(payloadJson),
          createdAt: Value(now),
          updatedAt: Value(now),
          status: const Value('PENDING'),
        ),
      );
    });
    await ensureAccountIsolation(db);
    try {
      await db.customStatement(
        'UPDATE sync_queue SET owner_user_id = ? WHERE entity_id = ? AND entity_type = ?',
        [ownerId, scoped.id, 'teacher_profile'],
      );
    } catch (_) {}
  }

  Future<void> _legacyUpdate(TeacherProfile profile) async {
    final now = DateTime.now();
    final id = profile.id.trim().isEmpty ? 'teacher_primary' : profile.id;
    await db.transaction(() async {
      await db.teacherDao.insertOrUpdateProfile(
        TeachersCompanion(
          id: Value(id),
          name: Value(profile.name),
          school: Value(profile.school),
          district: Value(profile.district),
          state: Value(profile.state),
          classesTaughtJson: Value(jsonEncode(profile.classesTaught)),
          teachingLanguage: Value(profile.teachingLanguage),
          supportedLanguagesJson: Value(jsonEncode(profile.supportedClassroomLanguages.map((l) => l.name).toList())),
          activeSessionLanguage: Value(profile.activeSessionLanguage.name),
          updatedAt: Value(now),
        ),
      );
      await db.syncQueueDao.enqueue(
        SyncQueueCompanion(
          id: Value(_uuid.v4()),
          entityType: const Value('teacher_profile'),
          entityId: Value(id),
          operation: const Value('UPDATE'),
          payload: Value(jsonEncode({'id': id})),
          createdAt: Value(now),
          updatedAt: Value(now),
          status: const Value('PENDING'),
        ),
      );
    });
  }

  @override
  Future<List<TribalLanguage>> getSelectedLanguages() async {
    final p = await getProfile();
    return p.supportedClassroomLanguages;
  }

  @override
  Future<void> updateLanguages(List<TribalLanguage> languages) async {
    final p = await getProfile();
    await updateProfile(p.copyWith(supportedClassroomLanguages: languages));
  }
}

// ==========================================
// 2. LESSON REPOSITORY (SQLite + SyncQueue)
// ==========================================
class SqliteLessonRepository implements LessonRepository {
  final AppDatabase db;
  final String? Function()? currentUserIdProvider;

  SqliteLessonRepository({required this.db, this.currentUserIdProvider});

  bool get _legacy => currentUserIdProvider == null;

  @override
  Future<List<NipunOutcome>> getOutcomes({int? grade, String? domain}) async {
    final rows = await db.curriculumDao.getOutcomes(grade: grade, domain: domain);
    return rows.map((r) {
      return NipunOutcome(
        id: r.id,
        code: r.code,
        grade: r.grade,
        domain: r.domain,
        competency: r.competency,
        titleEn: r.titleEn,
        titleHi: r.titleHi,
        targetDescription: r.targetDescription,
        defaultStatus: _parseStatus(r.defaultStatus),
        unfinishedSkill: r.unfinishedSkill,
      );
    }).toList();
  }

  @override
  Future<NipunOutcome?> getOutcomeByCode(String code) async {
    final r = await db.curriculumDao.getOutcomeByCode(code);
    if (r == null) return null;
    return NipunOutcome(
      id: r.id,
      code: r.code,
      grade: r.grade,
      domain: r.domain,
      competency: r.competency,
      titleEn: r.titleEn,
      titleHi: r.titleHi,
      targetDescription: r.targetDescription,
      defaultStatus: _parseStatus(r.defaultStatus),
      unfinishedSkill: r.unfinishedSkill,
    );
  }

  @override
  Future<LessonPlan> getLessonPlanForOutcome(String outcomeCode) async {
    final r = await db.lessonDao.getLessonByOutcomeCode(outcomeCode);
    if (r != null) {
      final List<dynamic> rawSteps = jsonDecode(r.stepsJson);
      final steps = rawSteps.map((s) {
        DeliveryStage stage = DeliveryStage.explain;
        for (final ds in DeliveryStage.values) {
          if (ds.name == s['stage']) stage = ds;
        }
        return LessonStep(
          stepNumber: (s['stepNumber'] as num).toInt(),
          stage: stage,
          title: s['title'] ?? '',
          titleHi: s['titleHi'] ?? '',
          scriptHindi: s['scriptHindi'] ?? '',
          scriptTribal: s['scriptTribal'] ?? '',
          teacherTip: s['teacherTip'] ?? '',
          localContextPrompt: s['localContextPrompt'] ?? '',
        );
      }).toList();

      final Map<String, dynamic> rawVocab = jsonDecode(r.tribalVocabularyJson);
      final vocab = rawVocab.map((k, v) => MapEntry(k, v.toString()));
      final List<dynamic> rawMaterials = jsonDecode(r.requiredMaterialsJson);

      return LessonPlan(
        id: r.id,
        title: r.title,
        titleHi: r.titleHi,
        outcomeCode: r.outcomeCode,
        outcomeTitle: r.outcomeTitle,
        grade: r.grade,
        subject: r.subject,
        durationMinutes: r.durationMinutes,
        learningObjective: r.learningObjective,
        prerequisiteKnowledge: r.prerequisiteKnowledge,
        teacherMoves: r.teacherMoves,
        activityOverview: r.activityOverview,
        assessmentStrategy: r.assessmentStrategy,
        remediationOption: r.remediationOption,
        tribalVocabulary: vocab,
        requiredMaterials: rawMaterials.map((e) => e.toString()).toList(),
        steps: steps,
      );
    }

    // Default fallback
    final outcome = await getOutcomeByCode(outcomeCode);
    return LessonPlan(
      id: 'lp_${outcomeCode.replaceAll('.', '_').toLowerCase()}',
      title: outcome?.titleEn ?? 'Lesson for $outcomeCode',
      titleHi: outcome?.titleHi ?? outcomeCode,
      outcomeCode: outcomeCode,
      outcomeTitle: outcome?.targetDescription ?? 'Target description',
      grade: outcome?.grade ?? 2,
      subject: 'Mathematics',
      durationMinutes: 40,
      learningObjective: 'Foundational classroom mastery aligned to NIPUN FLN.',
      prerequisiteKnowledge: 'Oral numeracy familiarity.',
      teacherMoves: 'Model using local objects and bilingual prompts.',
      activityOverview: 'Hands-on small group activity.',
      assessmentStrategy: 'Formative observation check.',
      remediationOption: 'Concrete physical counter grouping.',
      tribalVocabulary: const {'Counting': 'Mundari: लेका | Ho: लेका | Santali: लेका'},
      requiredMaterials: const ['Counters', 'Slate', 'Chalk'],
      steps: const [
        LessonStep(
          stepNumber: 1,
          stage: DeliveryStage.explain,
          title: 'Oral Introduction',
          titleHi: 'मौखिक परिचय',
          scriptHindi: 'बच्चों! आज हम नया पाठ सीखेंगे।',
          scriptTribal: 'Mundari: होनको! तेहेंगे बु नावा पाठ बु सेचेड़ा।',
          teacherTip: 'Speak slowly and use mother tongue cue words.',
          localContextPrompt: 'Connect with local surroundings.',
        ),
      ],
    );
  }

  @override
  Future<List<LocalContextItem>> getLocalContextItems({String? category}) async {
    final rows = await db.curriculumDao.getLocalContextItems(category: category);
    return rows.map((r) {
      return LocalContextItem(
        id: r.id,
        category: r.category,
        title: r.title,
        titleHi: r.titleHi,
        description: r.description,
        culturalRelevance: r.culturalRelevance,
        tribalTerm: r.tribalTerm,
        language: _parseLanguage(r.language),
      );
    }).toList();
  }

  @override
  Future<List<ActivityItem>> getActivities({String? strand, int? grade, TribalLanguage? language}) async {
    final rows = await db.curriculumDao.getActivities(
      strand: strand,
      grade: grade,
      language: language?.name,
    );

    return rows.map((r) {
      final List<dynamic> tSteps = jsonDecode(r.teacherStepsJson);
      final List<dynamic> sSteps = jsonDecode(r.studentStepsJson);
      final List<dynamic> qs = jsonDecode(r.questionsJson);

      return ActivityItem(
        id: r.id,
        title: r.title,
        titleHi: r.titleHi,
        grade: r.grade,
        subject: r.subject,
        strandOrStage: r.strandOrStage,
        language: _parseLanguage(r.language),
        durationMinutes: r.durationMinutes,
        difficulty: _parseDifficulty(r.difficulty),
        materials: r.materials,
        teacherSteps: tSteps.map((e) => e.toString()).toList(),
        studentSteps: sSteps.map((e) => e.toString()).toList(),
        questions: qs.map((e) => e.toString()).toList(),
        expectedResponse: r.expectedResponse,
        audioPromptHindi: r.audioPromptHindi,
        audioPromptTribal: r.audioPromptTribal,
      );
    }).toList();
  }

  @override
  Future<ActivityItem?> getActivityById(String id) async {
    final r = await db.curriculumDao.getActivityById(id);
    if (r == null) return null;
    final List<dynamic> tSteps = jsonDecode(r.teacherStepsJson);
    final List<dynamic> sSteps = jsonDecode(r.studentStepsJson);
    final List<dynamic> qs = jsonDecode(r.questionsJson);

    return ActivityItem(
      id: r.id,
      title: r.title,
      titleHi: r.titleHi,
      grade: r.grade,
      subject: r.subject,
      strandOrStage: r.strandOrStage,
      language: _parseLanguage(r.language),
      durationMinutes: r.durationMinutes,
      difficulty: _parseDifficulty(r.difficulty),
      materials: r.materials,
      teacherSteps: tSteps.map((e) => e.toString()).toList(),
      studentSteps: sSteps.map((e) => e.toString()).toList(),
      questions: qs.map((e) => e.toString()).toList(),
      expectedResponse: r.expectedResponse,
      audioPromptHindi: r.audioPromptHindi,
      audioPromptTribal: r.audioPromptTribal,
    );
  }

  @override
  Future<LessonPlan> createLesson(LessonPlan plan) async {
    final ownerId = _ownerOf(currentUserIdProvider);
    if (!_legacy && ownerId == null) return plan;
    final now = DateTime.now();
    await db.transaction(() async {
      await db.lessonDao.insertOrUpdateLesson(
        LessonsCompanion(
          id: Value(plan.id),
          title: Value(plan.title),
          titleHi: Value(plan.titleHi),
          outcomeCode: Value(plan.outcomeCode),
          outcomeTitle: Value(plan.outcomeTitle),
          grade: Value(plan.grade),
          subject: Value(plan.subject),
          durationMinutes: Value(plan.durationMinutes),
          learningObjective: Value(plan.learningObjective),
          prerequisiteKnowledge: Value(plan.prerequisiteKnowledge),
          teacherMoves: Value(plan.teacherMoves),
          activityOverview: Value(plan.activityOverview),
          assessmentStrategy: Value(plan.assessmentStrategy),
          remediationOption: Value(plan.remediationOption),
          tribalVocabularyJson: Value(jsonEncode(plan.tribalVocabulary)),
          requiredMaterialsJson: Value(jsonEncode(plan.requiredMaterials)),
          stepsJson: Value(jsonEncode(plan.steps.map((s) => {
            'stepNumber': s.stepNumber,
            'stage': s.stage.name,
            'title': s.title,
            'titleHi': s.titleHi,
            'scriptHindi': s.scriptHindi,
            'scriptTribal': s.scriptTribal,
            'teacherTip': s.teacherTip,
            'localContextPrompt': s.localContextPrompt,
          }).toList())),
          createdAt: Value(now),
          updatedAt: Value(now),
          syncStatus: const Value('PENDING'),
        ),
      );

      await db.syncQueueDao.enqueue(
        SyncQueueCompanion(
          id: Value(_uuid.v4()),
          entityType: const Value('lesson'),
          entityId: Value(plan.id),
          operation: const Value('CREATE'),
          payload: Value(jsonEncode({'owner_user_id': ownerId, 'id': plan.id, 'title': plan.title, 'outcomeCode': plan.outcomeCode})),
          createdAt: Value(now),
          updatedAt: Value(now),
          status: const Value('PENDING'),
        ),
      );
    });
    await ensureAccountIsolation(db);
    await claimOwnership(db, entityType: 'lesson', entityId: plan.id, ownerId: ownerId);
    try {
      await db.customStatement(
        'UPDATE sync_queue SET owner_user_id = ? WHERE entity_type = ? AND entity_id = ?',
        [ownerId, 'lesson', plan.id],
      );
    } catch (_) {}
    return plan;
  }

  @override
  Future<LessonPlan> updateLesson(LessonPlan plan) async {
    final ownerId = _ownerOf(currentUserIdProvider);
    if (!_legacy && ownerId == null) return plan;
    // Ownership check: never modify another teacher's lesson. Legacy rows
    // with no claim at all are claimed by the first editor; rows claimed
    // by someone else are left untouched.
    await ensureAccountIsolation(db);
    final owned = await isOwnedBy(db, entityType: 'lesson', entityId: plan.id, ownerId: ownerId);
    if (!owned) {
      final anyone = await db.customSelect(
        'SELECT owner_user_id FROM account_owned_records WHERE entity_type = ? AND entity_id = ? LIMIT 1',
        variables: [
          Variable.withString('lesson'),
          Variable.withString(plan.id),
        ],
      ).get();
      if (anyone.isNotEmpty) return plan;
    }
    final now = DateTime.now();
    await db.transaction(() async {
      await db.lessonDao.insertOrUpdateLesson(
        LessonsCompanion(
          id: Value(plan.id),
          title: Value(plan.title),
          titleHi: Value(plan.titleHi),
          outcomeCode: Value(plan.outcomeCode),
          outcomeTitle: Value(plan.outcomeTitle),
          grade: Value(plan.grade),
          subject: Value(plan.subject),
          durationMinutes: Value(plan.durationMinutes),
          learningObjective: Value(plan.learningObjective),
          prerequisiteKnowledge: Value(plan.prerequisiteKnowledge),
          teacherMoves: Value(plan.teacherMoves),
          activityOverview: Value(plan.activityOverview),
          assessmentStrategy: Value(plan.assessmentStrategy),
          remediationOption: Value(plan.remediationOption),
          tribalVocabularyJson: Value(jsonEncode(plan.tribalVocabulary)),
          requiredMaterialsJson: Value(jsonEncode(plan.requiredMaterials)),
          stepsJson: Value(jsonEncode(plan.steps.map((s) => {
            'stepNumber': s.stepNumber,
            'stage': s.stage.name,
            'title': s.title,
            'titleHi': s.titleHi,
            'scriptHindi': s.scriptHindi,
            'scriptTribal': s.scriptTribal,
            'teacherTip': s.teacherTip,
            'localContextPrompt': s.localContextPrompt,
          }).toList())),
          updatedAt: Value(now),
          syncStatus: const Value('PENDING'),
        ),
      );

      await db.syncQueueDao.enqueue(
        SyncQueueCompanion(
          id: Value(_uuid.v4()),
          entityType: const Value('lesson'),
          entityId: Value(plan.id),
          operation: const Value('UPDATE'),
          payload: Value(jsonEncode({'owner_user_id': ownerId, 'id': plan.id, 'title': plan.title, 'outcomeCode': plan.outcomeCode})),
          createdAt: Value(now),
          updatedAt: Value(now),
          status: const Value('PENDING'),
        ),
      );
    });
    await claimOwnership(db, entityType: 'lesson', entityId: plan.id, ownerId: ownerId);
    try {
      await db.customStatement(
        'UPDATE sync_queue SET owner_user_id = ? WHERE entity_type = ? AND entity_id = ?',
        [ownerId, 'lesson', plan.id],
      );
    } catch (_) {}
    return plan;
  }

  /// Per-account progress key: avoids two teachers colliding on the same
  /// `lessonId` primary key.
  String _progressKey(String ownerId, String lessonId) => '$ownerId::$lessonId';

  @override
  Future<void> updateLessonDeliveryProgress(String lessonId, int currentStep, bool isCompleted) async {
    final ownerId = _ownerOf(currentUserIdProvider);
    if (!_legacy && ownerId == null) return;
    final now = DateTime.now();
    final key = _legacy ? lessonId : _progressKey(ownerId!, lessonId);
    await ensureAccountIsolation(db);
    await db.lessonDao.updateDeliveryProgress(
      LessonDeliveryProgressCompanion(
        lessonId: Value(key),
        currentStep: Value(currentStep),
        isCompleted: Value(isCompleted),
        startedAt: Value(now),
        completedAt: Value(isCompleted ? now : null),
      ),
    );
    await claimOwnership(db, entityType: 'lesson_progress', entityId: key, ownerId: ownerId);
  }

  @override
  Future<Map<String, dynamic>?> getLessonDeliveryProgress(String lessonId) async {
    final ownerId = _ownerOf(currentUserIdProvider);
    if (!_legacy && ownerId == null) return null;
    await ensureAccountIsolation(db);
    if (_legacy) {
      final row = await db.lessonDao.getDeliveryProgress(lessonId);
      if (row == null) return null;
      return {
        'lessonId': row.lessonId,
        'currentStep': row.currentStep,
        'isCompleted': row.isCompleted,
        'startedAt': row.startedAt,
        'completedAt': row.completedAt,
      };
    }
    final key = _progressKey(ownerId!, lessonId);
    final row = await db.lessonDao.getDeliveryProgress(key);
    if (row == null) return null;
    return {
      'lessonId': lessonId,
      'currentStep': row.currentStep,
      'isCompleted': row.isCompleted,
      'startedAt': row.startedAt,
      'completedAt': row.completedAt,
    };
  }
}

// ==========================================
// 3. RESOURCE REPOSITORY (SQLite + SyncQueue)
// ==========================================
class SqliteResourceRepository implements ResourceRepository {
  final AppDatabase db;
  final String? Function()? currentUserIdProvider;

  SqliteResourceRepository({required this.db, this.currentUserIdProvider});

  bool get _legacy => currentUserIdProvider == null;

  @override
  Future<QueuedWorksheetGeneration> generateWorksheet({
    required int grade,
    required String subject,
    required String outcomeCode,
    required TribalLanguage targetLanguage,
    required DifficultyLevel difficulty,
    required WorksheetType type,
    required int questionCount,
  }) async {
    // Honest offline-first flow: queue the teacher's real parameters for
    // server-side generation. Nothing is translated locally and nothing is
    // saved to Saved Materials until the server returns real content.
    final request = buildWorksheetGenerationRequest(
      grade: grade,
      subject: subject,
      topic: outcomeCode,
      nipunOutcome: outcomeCode,
      targetLanguage: targetLanguage,
      difficulty: difficulty,
      type: type,
      questionCount: questionCount,
      visualSupport: true,
      bilingualAnswers: true,
      audioCue: false,
      origin: 'offline',
    );
    final requestId = await queueWorksheetGenerationRequest(db, request);
    final now = DateTime.now();
    final scaffold = WorksheetItem(
      id: requestId,
      title: '$subject Worksheet ($outcomeCode)',
      titleHi: '$subject अभ्यास पत्रक ($outcomeCode)',
      grade: grade,
      subject: subject,
      outcomeCode: outcomeCode,
      targetLanguage: targetLanguage,
      difficulty: difficulty,
      type: type,
      questionCount: questionCount,
      questions: const [],
      createdAt: now,
    );
    return QueuedWorksheetGeneration(requestId: requestId, scaffold: scaffold);
  }

  @override
  Future<void> saveWorksheet(WorksheetItem item) async {
    final ownerId = _ownerOf(currentUserIdProvider);
    if (!_legacy && ownerId == null) return;
    final contentJson = jsonEncode({
      'id': item.id,
      'owner_user_id': ownerId,
      'title': item.title,
      'titleHi': item.titleHi,
      'grade': item.grade,
      'subject': item.subject,
      'outcomeCode': item.outcomeCode,
      'targetLanguage': item.targetLanguage.name,
      'difficulty': item.difficulty.name,
      'type': item.type.name,
      'questionCount': item.questionCount,
      'createdAt': item.createdAt.toIso8601String(),
      'questions': item.questions.map((q) => {
        'questionNumber': q.questionNumber,
        'promptHindi': q.promptHindi,
        'promptTribal': q.promptTribal,
        'visualIllustration': q.visualIllustration,
        'options': q.options,
        'answer': q.answer,
      }).toList(),
    });

    await db.transaction(() async {
      await db.resourceDao.insertSavedMaterial(
        SavedMaterialsCompanion(
          id: Value(item.id),
          type: const Value('worksheet'),
          title: Value(item.title),
          titleHi: Value(item.titleHi),
          grade: Value(item.grade),
          subject: Value(item.subject),
          outcomeCode: Value(item.outcomeCode),
          language: Value(item.targetLanguage.name),
          difficulty: Value(item.difficulty.name),
          contentJson: Value(contentJson),
          createdAt: Value(item.createdAt),
          isFavorite: const Value(true),
        ),
      );

      await db.syncQueueDao.enqueue(
        SyncQueueCompanion(
          id: Value(_uuid.v4()),
          entityType: const Value('saved_material'),
          entityId: Value(item.id),
          operation: const Value('CREATE'),
          payload: Value(jsonEncode({'owner_user_id': ownerId, 'id': item.id})),
          createdAt: Value(DateTime.now()),
          updatedAt: Value(DateTime.now()),
          status: const Value('PENDING'),
        ),
      );
    });
    await ensureAccountIsolation(db);
    await claimOwnership(db, entityType: 'saved_material', entityId: item.id, ownerId: ownerId);
    try {
      await db.customStatement(
        'UPDATE sync_queue SET owner_user_id = ? WHERE entity_type = ? AND entity_id = ?',
        [ownerId, 'saved_material', item.id],
      );
    } catch (_) {}
  }

  @override
  Future<List<WorksheetItem>> getSavedWorksheets() async {
    final ownerId = _ownerOf(currentUserIdProvider);
    if (!_legacy && ownerId == null) return [];
    await ensureAccountIsolation(db);
    final owned = await ownedEntityIds(db, entityType: 'saved_material', ownerId: ownerId);
    final rows = await db.resourceDao.getSavedMaterials(type: 'worksheet');
    // Account-scoped: only rows claimed by the current user are visible.
    // Legacy unclaimed rows stay hidden from every account. Legacy mode
    // (no provider wired) returns everything as before.
    final visible = _legacy ? rows : rows.where((r) => owned.contains(r.id)).toList();
    // No data yet means no worksheets: never invent a default worksheet.
    if (visible.isEmpty) {
      return [];
    }

    return visible.map((r) {
      final data = jsonDecode(r.contentJson);
      final rawQuestions = (data['questions'] as List<dynamic>?) ?? [];
      final questions = rawQuestions.map((q) {
        return WorksheetQuestion(
          questionNumber: (q['questionNumber'] as num).toInt(),
          promptHindi: q['promptHindi'] ?? '',
          promptTribal: q['promptTribal'] ?? '',
          visualIllustration: q['visualIllustration'] ?? '',
          options: (q['options'] as List<dynamic>).map((e) => e.toString()).toList(),
          answer: q['answer'] ?? '',
        );
      }).toList();

      return WorksheetItem(
        id: r.id,
        title: r.title,
        titleHi: r.titleHi,
        grade: r.grade,
        subject: r.subject,
        outcomeCode: r.outcomeCode,
        targetLanguage: _parseLanguage(r.language),
        difficulty: _parseDifficulty(r.difficulty),
        type: _parseWorksheetType(data['type'] ?? 'practice'),
        questionCount: (data['questionCount'] as num?)?.toInt() ?? questions.length,
        createdAt: r.createdAt,
        questions: questions,
      );
    }).toList();
  }

  @override
  Future<List<FlashcardItem>> getFlashcards({required String topic, required TribalLanguage language}) async {
    final saved = await getSavedFlashcards();
    final matching = saved.where((c) =>
      c.topic.toLowerCase() == topic.toLowerCase() &&
      c.language == language,
    ).toList();
    if (matching.isNotEmpty) {
      return matching;
    }

    return const [
      FlashcardItem(
        id: 'fc_1',
        topic: 'Numbers',
        hindiWord: 'एक (1)',
        tribalWord: 'मियाद (Mundari)',
        language: TribalLanguage.mundari,
        pronunciation: 'Mi-yaad',
        teacherPrompt: 'Show 1 single finger. Prompt child: "मियाद".',
        emojiOrIcon: '🍎',
        exampleSentence: 'मियाद सेब मेनाः (One apple is here).',
      ),
      FlashcardItem(
        id: 'fc_2',
        topic: 'Numbers',
        hindiWord: 'दो (2)',
        tribalWord: 'बारिया (Mundari)',
        language: TribalLanguage.mundari,
        pronunciation: 'Baa-ri-ya',
        teacherPrompt: 'Show 2 birds. Prompt child: "बारिया चेणे".',
        emojiOrIcon: '🐥 🐥',
        exampleSentence: 'बारिया चेणे उडौताना (Two birds are flying).',
      ),
      FlashcardItem(
        id: 'fc_3',
        topic: 'Numbers',
        hindiWord: 'तीन (3)',
        tribalWord: 'अपिया (Mundari)',
        language: TribalLanguage.mundari,
        pronunciation: 'A-pi-ya',
        teacherPrompt: 'Show 3 flowers. Prompt child: "अपिया बाहा".',
        emojiOrIcon: '🌸 🌸 🌸',
        exampleSentence: 'अपिया बाहा बिर रे (Three flowers in forest).',
      ),
      FlashcardItem(
        id: 'fc_4',
        topic: 'Numbers',
        hindiWord: 'चार (4)',
        tribalWord: 'उपून (Mundari)',
        language: TribalLanguage.mundari,
        pronunciation: 'U-poon',
        teacherPrompt: 'Show 4 trees.',
        emojiOrIcon: '🌲 🌲 🌲 🌲',
        exampleSentence: 'उपून दारु मेनाः (Four trees).',
      ),
      FlashcardItem(
        id: 'fc_5',
        topic: 'Numbers',
        hindiWord: 'पाँच (5)',
        tribalWord: 'मोड़े (Mundari)',
        language: TribalLanguage.mundari,
        pronunciation: 'Mo-re',
        teacherPrompt: 'Show whole hand with 5 fingers spread.',
        emojiOrIcon: '🖐️',
        exampleSentence: 'मोड़े ती काटी (Five fingers).',
      ),
    ];
  }

  @override
  Future<List<FlashcardItem>> getSavedFlashcards() async {
    final ownerId = _ownerOf(currentUserIdProvider);
    if (!_legacy && ownerId == null) return [];
    await ensureAccountIsolation(db);
    final owned = await ownedEntityIds(db, entityType: 'saved_material', ownerId: ownerId);
    // Flashcard sets the teacher generated or used, persisted via
    // saveFlashcardSet or online content generation.
    final rows = await db.resourceDao.getSavedMaterials(type: 'flashcard');
    final cards = <FlashcardItem>[];
    for (final row in (_legacy ? rows : rows.where((r) => owned.contains(r.id)))) {
      try {
        final data = jsonDecode(row.contentJson) as Map<String, dynamic>;
        final rawCards = (data['cards'] as List<dynamic>?) ?? (data['items'] as List<dynamic>?) ?? [];
        for (final c in rawCards) {
          final map = c as Map<String, dynamic>;
          final frontObj = map['front'];
          final backObj = map['back'];
          String hindiWord = '';
          String tribalWord = '';
          if (frontObj is Map) {
            hindiWord = (frontObj['hi'] ?? '').toString();
            tribalWord = (frontObj['sat'] ?? frontObj['ho'] ?? frontObj['unr'] ?? '').toString();
          } else {
            hindiWord = (map['hindiWord'] ?? map['front'] ?? '').toString();
            tribalWord = (map['tribalWord'] ?? map['back'] ?? '').toString();
          }
          if (backObj is Map) {
            if (hindiWord.isEmpty) hindiWord = (backObj['hi'] ?? '').toString();
            if (tribalWord.isEmpty) tribalWord = (backObj['sat'] ?? backObj['ho'] ?? backObj['unr'] ?? '').toString();
          }
          cards.add(FlashcardItem(
            id: (map['id'] ?? map['item_id'] ?? '').toString(),
            topic: (map['topic'] ?? data['topic'] ?? data['subject'] ?? 'Vocabulary').toString(),
            hindiWord: hindiWord.isNotEmpty ? hindiWord : (map['hindiWord'] ?? '').toString(),
            tribalWord: tribalWord.isNotEmpty ? tribalWord : (map['tribalWord'] ?? '').toString(),
            language: _parseLanguage((map['language'] ?? data['language'] ?? data['target_language'] ?? '').toString()),
            pronunciation: (map['pronunciation'] ?? '').toString(),
            teacherPrompt: (map['teacherPrompt'] ?? (map['prompt'] is Map ? map['prompt']['hi'] : map['prompt']) ?? '').toString(),
            emojiOrIcon: (map['emojiOrIcon'] ?? '🎴').toString(),
            exampleSentence: (map['exampleSentence'] ?? '').toString(),
          ));
        }
      } catch (_) {
        // Skip unreadable rows; never fabricate replacements.
      }
    }
    return cards;
  }

  @override
  Future<void> saveFlashcardSet({
    required String topic,
    required TribalLanguage language,
    required List<FlashcardItem> cards,
  }) async {
    final ownerId = _ownerOf(currentUserIdProvider);
    if (!_legacy && ownerId == null) return;
    // One row per owner+topic+language so two teachers never share a set.
    // Legacy mode (no provider) keeps the previous topic+language id shape.
    final safeOwner = (ownerId ?? '').replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    final setId = _legacy
        ? 'fcset_${topic.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_')}_${language.name}'
        : 'fcset_${safeOwner}_${topic.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_')}_${language.name}';
    final now = DateTime.now();
    final contentJson = jsonEncode({
      'id': setId,
      'owner_user_id': ownerId,
      'topic': topic,
      'language': language.name,
      'createdAt': now.toIso8601String(),
      'cards': cards
          .map((c) => {
                'id': c.id,
                'topic': c.topic,
                'hindiWord': c.hindiWord,
                'tribalWord': c.tribalWord,
                'language': c.language.name,
                'pronunciation': c.pronunciation,
                'teacherPrompt': c.teacherPrompt,
                'emojiOrIcon': c.emojiOrIcon,
                'exampleSentence': c.exampleSentence,
              })
          .toList(),
    });

    await db.transaction(() async {
      await db.resourceDao.insertSavedMaterial(
        SavedMaterialsCompanion(
          id: Value(setId),
          type: const Value('flashcard'),
          title: Value('$topic Flashcards'),
          titleHi: const Value(''),
          grade: const Value(0),
          subject: Value(topic),
          outcomeCode: const Value(''),
          language: Value(language.name),
          difficulty: const Value('easy'),
          contentJson: Value(contentJson),
          createdAt: Value(now),
          isFavorite: const Value(false),
        ),
      );

      await db.syncQueueDao.enqueue(
        SyncQueueCompanion(
          id: Value(_uuid.v4()),
          entityType: const Value('saved_material'),
          entityId: Value(setId),
          operation: const Value('CREATE'),
          payload: Value(jsonEncode({'owner_user_id': ownerId, 'id': setId})),
          createdAt: Value(now),
          updatedAt: Value(now),
          status: const Value('PENDING'),
        ),
      );
    });
    await ensureAccountIsolation(db);
    await claimOwnership(db, entityType: 'saved_material', entityId: setId, ownerId: ownerId);
    try {
      await db.customStatement(
        'UPDATE sync_queue SET owner_user_id = ? WHERE entity_type = ? AND entity_id = ?',
        [ownerId, 'saved_material', setId],
      );
    } catch (_) {}
  }

  @override
  Future<List<ActivityItem>> getSavedActivities() async {
    return SqliteLessonRepository(db: db, currentUserIdProvider: currentUserIdProvider).getActivities();
  }
}

// ==========================================
// 4. ASSESSMENT REPOSITORY (SQLite + SyncQueue)
// ==========================================
class SqliteAssessmentRepository implements AssessmentRepository {
  final AppDatabase db;
  final String? Function()? currentUserIdProvider;

  SqliteAssessmentRepository({required this.db, this.currentUserIdProvider});

  bool get _legacy => currentUserIdProvider == null;

  @override
  Future<List<AssessmentQuestionItem>> getQuestionsForOutcome(String outcomeCode) async {
    final r = await db.assessmentDao.getQuestionsForOutcome(outcomeCode);
    if (r != null) {
      final List<dynamic> list = jsonDecode(r.questionsJson);
      return list.map((q) {
        return AssessmentQuestionItem(
          number: (q['number'] as num).toInt(),
          promptHindi: q['promptHindi'] ?? '',
          promptTribal: q['promptTribal'] ?? '',
          type: _parseQuestionType(q['type'] ?? 'oral'),
          choices: (q['choices'] as List<dynamic>).map((e) => e.toString()).toList(),
          correctIndex: (q['correctIndex'] as num).toInt(),
          teacherObservationRubric: q['teacherObservationRubric'] ?? '',
        );
      }).toList();
    }

    // Default 3 diagnostic questions
    return const [
      AssessmentQuestionItem(
        number: 1,
        promptHindi: 'मौखिक गणना: स्लेट पर बनी 7 मछलियों को देखकर मुण्डारी या संताली में गिनें।',
        promptTribal: 'Santali: सात चेत् को मेताक-आ? (मित, बार, पे, पोन, मोड़े, तुरूई, सांते)',
        type: QuestionType.oral,
        choices: ['सांते (7)', 'तुरूई (6)', 'इरल (8)'],
        correctIndex: 0,
        teacherObservationRubric: 'Observe if student counts accurately 1-by-1 without skipping.',
      ),
      AssessmentQuestionItem(
        number: 2,
        promptHindi: 'मूर्त प्रदर्शन: थाली में से 5 दहाई (50) और 4 खुली तीलियां अलग करें। कुल संख्या बताएं।',
        promptTribal: 'Mundari: 5 गेल आर 4 सुसुम लेकाकेते संख्या ओलापे।',
        type: QuestionType.physical,
        choices: ['54 (मोड़े गेल उपून)', '45 (उपून गेल मोड़े)', '50 (मोड़े गेल)'],
        correctIndex: 0,
        teacherObservationRubric: 'Check if student confuses tens and units position.',
      ),
      AssessmentQuestionItem(
        number: 3,
        promptHindi: 'लिखित पहचान: 68 में दहाई का अंक कौन-सा है?',
        promptTribal: 'Ho: 68 रे गेल स्थान रे चिमिन मेनाः?',
        type: QuestionType.written,
        choices: ['6', '8', '60'],
        correctIndex: 0,
        teacherObservationRubric: 'Verify child writes digit 6 representing 60.',
      ),
    ];
  }

  @override
  Future<AssessmentResultData> submitAssessment({
    required String studentId,
    required String studentName,
    required String outcomeCode,
    required List<int> selectedAnswers,
  }) async {
    final ownerId = _ownerOf(currentUserIdProvider);
    final questions = await getQuestionsForOutcome(outcomeCode);
    int correct = 0;
    for (int i = 0; i < selectedAnswers.length && i < questions.length; i++) {
      if (selectedAnswers[i] == questions[i].correctIndex) {
        correct++;
      }
    }

    final OutcomeStatus status;
    if (correct >= 3) {
      status = OutcomeStatus.achieved;
    } else if (correct >= 2) {
      status = OutcomeStatus.developing;
    } else {
      status = OutcomeStatus.needsSupport;
    }

    final resultId = 'res_${DateTime.now().millisecondsSinceEpoch}';
    final now = DateTime.now();

    final unfinished = status == OutcomeStatus.achieved
        ? 'Outcome mastered successfully!'
        : 'Recognizing quantities above 50 and distinguishing tens/units.';
    final remediation = 'Activity: "Mahua Seed Bundles (दहाई-इकाई खेल)" with concrete 10-packs.';

    final result = AssessmentResultData(
      id: resultId,
      studentName: studentName,
      studentId: studentId,
      outcomeCode: outcomeCode,
      outcomeTitle: 'Numbers up to 100 (दहाई और इकाई)',
      totalQuestions: questions.length,
      correctCount: correct,
      status: status,
      unfinishedSkill: unfinished,
      recommendedRemediation: remediation,
      completedAt: now,
    );

    final payloadJson = jsonEncode({
      'id': result.id,
      'owner_user_id': ownerId,
      'student_id': result.studentId,
      'student_name': result.studentName,
      'outcome_code': result.outcomeCode,
      'outcome_title': result.outcomeTitle,
      'total_questions': result.totalQuestions,
      'correct_count': result.correctCount,
      'status': result.status.name,
      'unfinished_skill': result.unfinishedSkill,
      'recommended_remediation': result.recommendedRemediation,
      'completed_at': result.completedAt.toIso8601String(),
    });

    // Transactional write: save result + learning gap (if needs support) + sync queue
    // Unauthenticated writes are dropped: no owner, no record.
    // Legacy mode (no provider) writes globally as before.
    if (_legacy || ownerId != null) {
      await db.transaction(() async {
      await db.assessmentDao.insertAssessmentResult(
        AssessmentResultsCompanion(
          id: Value(result.id),
          studentId: Value(result.studentId),
          studentName: Value(result.studentName),
          outcomeCode: Value(result.outcomeCode),
          outcomeTitle: Value(result.outcomeTitle),
          totalQuestions: Value(result.totalQuestions),
          correctCount: Value(result.correctCount),
          status: Value(result.status.name),
          unfinishedSkill: Value(result.unfinishedSkill),
          recommendedRemediation: Value(result.recommendedRemediation),
          completedAt: Value(result.completedAt),
          syncStatus: const Value('pending'),
        ),
      );

      // If diagnosed with a learning gap, record it
      if (status != OutcomeStatus.achieved) {
        await db.studentDao.insertOrUpdateLearningGap(
          LearningGapsCompanion(
            id: Value('gap_${result.id}'),
            studentId: Value(result.studentId),
            outcomeCode: Value(result.outcomeCode),
            skill: Value(result.unfinishedSkill),
            rootCause: const Value('Linguistic confusion between tribal base-20 counting and decimal base-10.'),
            remediationUsed: Value(result.recommendedRemediation),
            status: const Value('Ongoing Intervention'),
            isResolved: const Value(false),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );
      }

      // Enqueue to SyncQueue
      await db.syncQueueDao.enqueue(
        SyncQueueCompanion(
          id: Value(_uuid.v4()),
          entityType: const Value('assessment_result'),
          entityId: Value(result.id),
          operation: const Value('CREATE'),
          payload: Value(payloadJson),
          createdAt: Value(now),
          updatedAt: Value(now),
          status: const Value('PENDING'),
        ),
      );
      });
      await ensureAccountIsolation(db);
      await claimOwnership(db, entityType: 'assessment_result', entityId: result.id, ownerId: ownerId);
      if (status != OutcomeStatus.achieved) {
        await claimOwnership(db, entityType: 'learning_gap', entityId: 'gap_${result.id}', ownerId: ownerId);
      }
      try {
        await db.customStatement(
          'UPDATE sync_queue SET owner_user_id = ? WHERE entity_type = ? AND entity_id = ?',
          [ownerId, 'assessment_result', result.id],
        );
      } catch (_) {}
    }

    return result;
  }

  @override
  Future<ActivityItem> getRemedialActivityForOutcome(String outcomeCode) async {
    final activity = await SqliteLessonRepository(db: db, currentUserIdProvider: currentUserIdProvider).getActivityById('rem_001');
    if (activity != null) return activity;

    return const ActivityItem(
      id: 'rem_001',
      title: 'Remedial: Mahua Seed 10-Bundles',
      titleHi: 'उपचारात्मक शिक्षण: महुआ बीज 10-बंडल खेल',
      grade: 2,
      subject: 'Mathematics',
      strandOrStage: 'Skills Teaching',
      language: TribalLanguage.mundari,
      durationMinutes: 15,
      difficulty: DifficultyLevel.easy,
      materials: '50 Mahua seeds, 5 small sal leaf bowls, chalk slate',
      teacherSteps: [
        'Sit directly with student in one-on-one session.',
        'Place 10 seeds in bowl 1. Say: "नेया 1 गेल (10) ताना।" Have student repeat.',
        'Add bowls one by one: 20 (हिसि), 30 (हिसि-गेल), 40 (बार-हिसि), 50 (बार-हिसि-गेल).',
        'Add 2 loose seeds: "अब कुल कितना हुआ? 52!"',
      ],
      studentSteps: [
        'Physically count seeds into each bowl.',
        'State total count in mother tongue and then write in Hindi on slate.',
      ],
      questions: [
        '5 बंडल में कितने बीज हैं? (5 गेल रे चिमिन जांग?)',
      ],
      expectedResponse: '50 बीज (हिसि-गेल / 50).',
      audioPromptHindi: 'प्रत्येक कटोरी में 10-10 बीज रखकर 50 तक गिनें।',
      audioPromptTribal: 'साकाम कटोरी रे गेल-गेल जांग दोहकेते 50 धाब लेकापे।',
    );
  }

  @override
  Future<AssessmentResultData> submitReassessment({
    required String studentId,
    required String outcomeCode,
    required bool passed,
  }) async {
    final ownerId = _ownerOf(currentUserIdProvider);
    final resultId = 'reass_${DateTime.now().millisecondsSinceEpoch}';
    final now = DateTime.now();

    // Ownership gate: never touch another teacher's student.
    // Legacy mode (no provider) behaves as before.
    if (!_legacy && ownerId != null) {
      await ensureAccountIsolation(db);
      if (!await isOwnedBy(db, entityType: 'student', entityId: studentId, ownerId: ownerId)) {
        throw StateError('Student belongs to a different teacher account.');
      }
    }
    final student = (!_legacy && ownerId == null)
        ? null
        : await db.studentDao.getStudentById(studentId);
    final studentName = student?.name ?? 'Learner';

    final result = AssessmentResultData(
      id: resultId,
      studentName: studentName,
      studentId: studentId,
      outcomeCode: outcomeCode,
      outcomeTitle: 'Numbers up to 100 (दहाई और इकाई)',
      totalQuestions: 2,
      correctCount: passed ? 2 : 1,
      status: passed ? OutcomeStatus.achieved : OutcomeStatus.developing,
      unfinishedSkill: passed ? 'None - Outcome Achieved' : 'Needs additional physical practice',
      recommendedRemediation: passed ? 'Proceed to Next NIPUN Outcome (M2.1.5)' : 'Repeat 10-bundle game',
      completedAt: now,
    );

    final payloadJson = jsonEncode({
      'id': result.id,
      'owner_user_id': ownerId,
      'student_id': result.studentId,
      'student_name': result.studentName,
      'outcome_code': result.outcomeCode,
      'outcome_title': result.outcomeTitle,
      'total_questions': result.totalQuestions,
      'correct_count': result.correctCount,
      'status': result.status.name,
      'unfinished_skill': result.unfinishedSkill,
      'recommended_remediation': result.recommendedRemediation,
      'completed_at': result.completedAt.toIso8601String(),
    });

    if (!_legacy && ownerId == null) return result;
    await db.transaction(() async {
      await db.assessmentDao.insertAssessmentResult(
        AssessmentResultsCompanion(
          id: Value(result.id),
          studentId: Value(result.studentId),
          studentName: Value(result.studentName),
          outcomeCode: Value(result.outcomeCode),
          outcomeTitle: Value(result.outcomeTitle),
          totalQuestions: Value(result.totalQuestions),
          correctCount: Value(result.correctCount),
          status: Value(result.status.name),
          unfinishedSkill: Value(result.unfinishedSkill),
          recommendedRemediation: Value(result.recommendedRemediation),
          completedAt: Value(result.completedAt),
          syncStatus: const Value('pending'),
        ),
      );

      // If passed, resolve learning gap
      if (passed) {
        final gaps = await db.studentDao.getLearningGapsByStudent(studentId);
        for (final g in gaps) {
          if (g.outcomeCode == outcomeCode && !g.isResolved) {
            await db.studentDao.insertOrUpdateLearningGap(
              LearningGapsCompanion(
                id: Value(g.id),
                studentId: Value(g.studentId),
                outcomeCode: Value(g.outcomeCode),
                skill: Value(g.skill),
                rootCause: Value(g.rootCause),
                remediationUsed: Value(g.remediationUsed),
                status: const Value('Resolved via Remediation'),
                isResolved: const Value(true),
                createdAt: Value(g.createdAt),
                updatedAt: Value(now),
              ),
            );
          }
        }
      }

      await db.syncQueueDao.enqueue(
        SyncQueueCompanion(
          id: Value(_uuid.v4()),
          entityType: const Value('assessment_result'),
          entityId: Value(result.id),
          operation: const Value('CREATE'),
          payload: Value(payloadJson),
          createdAt: Value(now),
          updatedAt: Value(now),
          status: const Value('PENDING'),
        ),
      );
    });
    await ensureAccountIsolation(db);
    await claimOwnership(db, entityType: 'assessment_result', entityId: result.id, ownerId: ownerId);
    try {
      await db.customStatement(
        'UPDATE sync_queue SET owner_user_id = ? WHERE entity_type = ? AND entity_id = ?',
        [ownerId, 'assessment_result', result.id],
      );
    } catch (_) {}

    return result;
  }
}

// ==========================================
// 5. STUDENT REPOSITORY (SQLite + SyncQueue)
// ==========================================
class SqliteStudentRepository implements StudentRepository {
  final AppDatabase db;
  final String? Function()? currentUserIdProvider;

  SqliteStudentRepository({required this.db, this.currentUserIdProvider});

  bool get _legacy => currentUserIdProvider == null;

  @override
  Future<List<StudentRecord>> getStudents({int? grade}) async {
    final ownerId = _ownerOf(currentUserIdProvider);
    if (!_legacy && ownerId == null) return [];
    await ensureAccountIsolation(db);
    final ownedStudents = _legacy
        ? null
        : await ownedEntityIds(db, entityType: 'student', ownerId: ownerId);
    final ownedResults = _legacy
        ? null
        : await ownedEntityIds(db, entityType: 'assessment_result', ownerId: ownerId);
    final ownedGaps = _legacy
        ? null
        : await ownedEntityIds(db, entityType: 'learning_gap', ownerId: ownerId);
    final allRows = await db.studentDao.getStudents(grade: grade);
    final rows = _legacy
        ? allRows
        : allRows.where((r) => ownedStudents!.contains(r.id)).toList();

    final List<StudentRecord> results = [];
    for (final r in rows) {
      final allAssessments =
          await db.assessmentDao.getAssessmentResultsForStudent(r.id);
      final assessments = _legacy
          ? allAssessments
          : allAssessments.where((a) => ownedResults!.contains(a.id)).toList();
      final allGaps = await db.studentDao.getLearningGapsByStudent(r.id);
      final gaps = _legacy
          ? allGaps
          : allGaps.where((g) => ownedGaps!.contains(g.id)).toList();

      final assessmentHistory = assessments.map((a) {
        return AssessmentResultData(
          id: a.id,
          studentName: a.studentName,
          studentId: a.studentId,
          outcomeCode: a.outcomeCode,
          outcomeTitle: a.outcomeTitle,
          totalQuestions: a.totalQuestions,
          correctCount: a.correctCount,
          status: _parseStatus(a.status),
          unfinishedSkill: a.unfinishedSkill,
          recommendedRemediation: a.recommendedRemediation,
          completedAt: a.completedAt,
        );
      }).toList();

      final identifiedGaps = gaps
          .where((g) => !g.isResolved)
          .map((g) => g.skill)
          .toList();

      results.add(StudentRecord(
        id: r.id,
        name: r.name,
        rollNumber: r.rollNumber,
        grade: r.grade,
        motherTongue: _parseLanguage(r.motherTongue),
        achievedOutcomes: r.achievedOutcomes,
        developingOutcomes: r.developingOutcomes,
        needsSupportOutcomes: r.needsSupportOutcomes,
        literacyProgress: r.literacyProgress,
        numeracyProgress: r.numeracyProgress,
        recentEvidence: r.recentEvidence,
        assessmentHistory: assessmentHistory,
        identifiedGaps: identifiedGaps,
      ));
    }

    return results;
  }

  @override
  Future<StudentRecord?> getStudentById(String id) async {
    final ownerId = _ownerOf(currentUserIdProvider);
    if (!_legacy && ownerId == null) return null;
    await ensureAccountIsolation(db);
    if (!_legacy &&
        !await isOwnedBy(db, entityType: 'student', entityId: id, ownerId: ownerId)) {
      return null;
    }
    final r = await db.studentDao.getStudentById(id);
    if (r == null) return null;

    final ownedResults = _legacy
        ? null
        : await ownedEntityIds(db, entityType: 'assessment_result', ownerId: ownerId);
    final ownedGaps = _legacy
        ? null
        : await ownedEntityIds(db, entityType: 'learning_gap', ownerId: ownerId);
    final allAssessments =
        await db.assessmentDao.getAssessmentResultsForStudent(r.id);
    final assessments = _legacy
        ? allAssessments
        : allAssessments.where((a) => ownedResults!.contains(a.id)).toList();
    final allGaps = await db.studentDao.getLearningGapsByStudent(r.id);
    final gaps = _legacy
        ? allGaps
        : allGaps.where((g) => ownedGaps!.contains(g.id)).toList();

    final assessmentHistory = assessments.map((a) {
      return AssessmentResultData(
        id: a.id,
        studentName: a.studentName,
        studentId: a.studentId,
        outcomeCode: a.outcomeCode,
        outcomeTitle: a.outcomeTitle,
        totalQuestions: a.totalQuestions,
        correctCount: a.correctCount,
        status: _parseStatus(a.status),
        unfinishedSkill: a.unfinishedSkill,
        recommendedRemediation: a.recommendedRemediation,
        completedAt: a.completedAt,
      );
    }).toList();

    final identifiedGaps = gaps
        .where((g) => !g.isResolved)
        .map((g) => g.skill)
        .toList();

    return StudentRecord(
      id: r.id,
      name: r.name,
      rollNumber: r.rollNumber,
      grade: r.grade,
      motherTongue: _parseLanguage(r.motherTongue),
      achievedOutcomes: r.achievedOutcomes,
      developingOutcomes: r.developingOutcomes,
      needsSupportOutcomes: r.needsSupportOutcomes,
      literacyProgress: r.literacyProgress,
      numeracyProgress: r.numeracyProgress,
      recentEvidence: r.recentEvidence,
      assessmentHistory: assessmentHistory,
      identifiedGaps: identifiedGaps,
    );
  }

  @override
  Future<void> updateOutcomeStatus(String studentId, String outcomeCode, OutcomeStatus newStatus) async {
    final ownerId = _ownerOf(currentUserIdProvider);
    if (!_legacy && ownerId == null) return;
    await ensureAccountIsolation(db);
    if (!_legacy &&
        !await isOwnedBy(db, entityType: 'student', entityId: studentId, ownerId: ownerId)) {
      return;
    }
    final s = await db.studentDao.getStudentById(studentId);
    if (s != null) {
      final now = DateTime.now();
      final achieved = newStatus == OutcomeStatus.achieved ? s.achievedOutcomes + 1 : s.achievedOutcomes;
      final needsSupport = newStatus == OutcomeStatus.achieved && s.needsSupportOutcomes > 0
          ? s.needsSupportOutcomes - 1
          : s.needsSupportOutcomes;
      final numProg = newStatus == OutcomeStatus.achieved ? 0.88 : s.numeracyProgress;

      await db.studentDao.insertOrUpdateStudent(
        StudentsCompanion(
          id: Value(s.id),
          name: Value(s.name),
          rollNumber: Value(s.rollNumber),
          grade: Value(s.grade),
          motherTongue: Value(s.motherTongue),
          achievedOutcomes: Value(achieved),
          developingOutcomes: Value(s.developingOutcomes),
          needsSupportOutcomes: Value(needsSupport),
          literacyProgress: Value(s.literacyProgress),
          numeracyProgress: Value(numProg),
          recentEvidence: Value(newStatus == OutcomeStatus.achieved
              ? 'Outcome $outcomeCode achieved via remedial practice.'
              : s.recentEvidence),
          identifiedGapsJson: Value(newStatus == OutcomeStatus.achieved ? '[]' : s.identifiedGapsJson),
          createdAt: Value(s.createdAt),
          updatedAt: Value(now),
        ),
      );
    }
  }
}

// ==========================================
// 6. TRANSLATION REPOSITORY (SQLite + SyncQueue)
// ==========================================
class SqliteTranslationRepository implements TranslationRepository {
  final AppDatabase db;
  final String? Function()? currentUserIdProvider;

  SqliteTranslationRepository({required this.db, this.currentUserIdProvider});

  bool get _legacy => currentUserIdProvider == null;

  @override
  Future<TranslationMessage> translateUtterance({
    required String text,
    required TribalLanguage targetLanguage,
    required bool isTeacher,
    Map<String, String>? contextMeta,
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));

    String translated;
    if (isTeacher) {
      if (text.contains('किताब') || text.contains('पुस्तक')) {
        translated = targetLanguage == TribalLanguage.santali
            ? 'आपेआक् पुथी झिज्पे (Open your books)'
            : 'सबिन होनको आपन-आपन पुथी उगुइपे';
      } else if (text.contains('गिन') || text.contains('संख्या')) {
        translated = targetLanguage == TribalLanguage.ho
            ? 'नेया जांग सुकूँते लेकापे (Count carefully)'
            : 'गेल-गेल लेका केते नेलपे';
      } else {
        translated = targetLanguage == TribalLanguage.santali
            ? 'सान्ते गिदराको ध्यान ते आंजोमपे (Listen attentively in Santali)'
            : 'सबिन होनको आंजोमपे (Children listen)';
      }
    } else {
      translated = 'गुरुजी, मुझे यह सवाल समझ नहीं आ रहा है। कृपया दोबारा बताएं।';
    }

    final msg = TranslationMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      isTeacher: isTeacher,
      speakerName: isTeacher ? 'Teacher (Hindi)' : 'Student (${targetLanguage.displayName})',
      originalText: text,
      translatedText: translated,
      targetLanguage: targetLanguage,
      timestamp: DateTime.now(),
      latencyMs: 120,
      isOfflineNmt: true,
    );

    // Persist to local SQLite translation history (account-scoped).
    // Legacy mode (no provider) persists globally as before.
    final historyOwner = _ownerOf(currentUserIdProvider);
    if (_legacy || historyOwner != null) {
      await db.translationDao.insertMessage(
        TranslationHistoryCompanion(
          id: Value(msg.id),
          isTeacher: Value(msg.isTeacher),
          speakerName: Value(msg.speakerName),
          originalText: Value(msg.originalText),
          translatedText: Value(msg.translatedText),
          targetLanguage: Value(msg.targetLanguage.name),
          latencyMs: Value(msg.latencyMs),
          isOfflineNmt: Value(msg.isOfflineNmt),
          timestamp: Value(msg.timestamp),
        ),
      );
      await ensureAccountIsolation(db);
      await claimOwnership(db, entityType: 'translation_history', entityId: msg.id, ownerId: historyOwner);
    }

    return msg;
  }

  @override
  Future<List<QuickPhrase>> getQuickPhrases({String? category}) async {
    final rows = await db.translationDao.getQuickPhrases(category: category);
    return rows.map((r) {
      return QuickPhrase(
        id: r.id,
        category: r.category,
        hindi: r.hindi,
        ho: r.ho,
        mundari: r.mundari,
        santali: r.santali,
      );
    }).toList();
  }

  @override
  Future<void> submitFeedback({
    required String original,
    required String translated,
    required String issueType,
    String? comment,
  }) async {
    final ownerId = _ownerOf(currentUserIdProvider);
    if (!_legacy && ownerId == null) return;
    final fbId = 'fb_${DateTime.now().millisecondsSinceEpoch}';
    final now = DateTime.now();

    final payloadJson = jsonEncode({
      'id': fbId,
      'owner_user_id': ownerId,
      'original': original,
      'translated': translated,
      'issue_type': issueType,
      'comment': comment,
      'timestamp': now.toIso8601String(),
    });

    await db.transaction(() async {
      await db.translationDao.insertFeedback(
        TranslationFeedbackCompanion(
          id: Value(fbId),
          original: Value(original),
          translated: Value(translated),
          issueType: Value(issueType),
          comment: Value(comment),
          timestamp: Value(now),
          syncStatus: const Value('pending'),
        ),
      );

      await db.syncQueueDao.enqueue(
        SyncQueueCompanion(
          id: Value(_uuid.v4()),
          entityType: const Value('translation_feedback'),
          entityId: Value(fbId),
          operation: const Value('CREATE'),
          payload: Value(payloadJson),
          createdAt: Value(now),
          updatedAt: Value(now),
          status: const Value('PENDING'),
        ),
      );
    });
    await ensureAccountIsolation(db);
    await claimOwnership(db, entityType: 'translation_feedback', entityId: fbId, ownerId: ownerId);
    try {
      await db.customStatement(
        'UPDATE sync_queue SET owner_user_id = ? WHERE entity_type = ? AND entity_id = ?',
        [ownerId, 'translation_feedback', fbId],
      );
    } catch (_) {}
  }
}

// ==========================================
// 7. OFFLINE REPOSITORY (SQLite + SyncManager)
// ==========================================
class SqliteOfflineRepository implements OfflineRepository {
  final AppDatabase db;
  final SyncManager syncManager;
  final String? Function()? currentUserIdProvider;

  bool get _legacy => currentUserIdProvider == null;

  SqliteOfflineRepository(
      {required this.db, required this.syncManager, this.currentUserIdProvider});

  @override
  Future<List<LanguagePackInfo>> getLanguagePacks() async {
    final rows = await db.offlineDao.getLanguagePacks();
    return rows.map((r) {
      return LanguagePackInfo(
        id: r.id,
        language: _parseLanguage(r.language),
        sizeMb: r.sizeMb,
        version: r.version,
        status: _parsePackStatus(r.status),
        progress: r.progress,
      );
    }).toList();
  }

  @override
  Future<void> downloadLanguagePack(String id) async {
    await db.offlineDao.insertOrUpdateLanguagePack(
      LanguagePacksCompanion(
        id: Value(id),
        status: const Value('installed'),
        progress: const Value(1.0),
        version: const Value('Installed'),
      ),
    );
  }

  @override
  Future<List<ContentPackInfo>> getContentPacks() async {
    final rows = await db.offlineDao.getContentPacks();
    return rows.map((r) {
      return ContentPackInfo(
        id: r.id,
        title: r.title,
        description: r.description,
        sizeMb: r.sizeMb,
        isInstalled: r.isInstalled,
      );
    }).toList();
  }

  @override
  Future<void> syncClassroomData() async {
    await syncManager.syncPendingOperations();
  }

  @override
  Future<int> getPendingSyncCount() async {
    // Account-scoped: only the current teacher's queue counts.
    // Legacy mode (no provider) counts globally as before.
    final ownerId = _ownerOf(currentUserIdProvider);
    if (ownerId == null) {
      if (_legacy) return db.syncQueueDao.getPendingCount();
      return 0;
    }
    try {
      final rows = await db.customSelect(
        'SELECT COUNT(*) AS c FROM sync_queue WHERE owner_user_id = ? '
        'AND (status = ? OR status = ?)',
        variables: [
          Variable.withString(ownerId),
          Variable.withString('PENDING'),
          Variable.withString('FAILED'),
        ],
      ).get();
      if (rows.isNotEmpty) return (rows.first.data['c'] as num?)?.toInt() ?? 0;
    } catch (_) {}
    return 0;
  }

  @override
  Future<SyncStatusState> getSyncStatus() async {
    if (syncManager.isSyncing) return SyncStatusState.syncing;
    final pending = await getPendingSyncCount();
    return pending > 0 ? SyncStatusState.pendingUpload : SyncStatusState.synced;
  }

  @override
  Future<DateTime?> getLastSyncTime() async {
    return syncManager.lastSyncTime;
  }
}
