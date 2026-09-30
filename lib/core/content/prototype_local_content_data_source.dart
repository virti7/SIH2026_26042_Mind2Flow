import 'dart:convert';

import 'package:flutter/services.dart';

import '../enums/app_enums.dart';
import '../models/app_models.dart';
import 'prototype_manifests.dart';

/// Offline-first bundled prototype content reader.
///
/// Reads ONLY from the Flutter asset bundle
/// (`assets/prototype_content/...`). Never touches FastAPI, Supabase,
/// Sarvam, or any network client — safe with airplane mode ON, Wi-Fi OFF,
/// backend stopped.
///
/// Catalog = SHARED curriculum content. Per-teacher state (downloads,
/// saved flags, progress) stays in the existing account-scoped Drift
/// stores; this class never writes teacher state.
class PrototypeLocalContentDataSource {
  final AssetBundle bundle;

  PrototypeLocalContentDataSource({AssetBundle? bundle})
      : bundle = bundle ?? rootBundle;

  static const _worksheetDir =
      'assets/prototype_content/worksheets/manifests/';
  static const _flashcardDir =
      'assets/prototype_content/flashcards/manifests/';
  static const _assessmentDir =
      'assets/prototype_content/assessments/manifests/';

  Future<List<String>> _manifestPaths(String dir) async {
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(bundle);
      return manifest
          .listAssets()
          .where((p) => p.startsWith(dir) && p.endsWith('.json'))
          .where((p) => !p.endsWith('.example.json'))
          .toList()
        ..sort();
    } catch (_) {
      return const [];
    }
  }

  Future<Map<String, dynamic>?> _readJson(String path) async {
    try {
      final raw = await bundle.loadString(path);
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
      return null;
    } catch (_) {
      return null;
    }
  }

  /// All bundled worksheet manifests (empty until the teacher adds files).
  Future<List<PrototypeWorksheetManifest>> getPrototypeWorksheets() async {
    final paths = await _manifestPaths(_worksheetDir);
    final out = <PrototypeWorksheetManifest>[];
    for (final p in paths) {
      final json = await _readJson(p);
      if (json == null) continue;
      try {
        final m = PrototypeWorksheetManifest.fromJson(json);
        if (m.isValid) out.add(m);
      } catch (_) {}
    }
    return out;
  }

  /// All bundled flashcard set manifests.
  Future<List<PrototypeFlashcardSetManifest>>
      getPrototypeFlashcardSets() async {
    final paths = await _manifestPaths(_flashcardDir);
    final out = <PrototypeFlashcardSetManifest>[];
    for (final p in paths) {
      final json = await _readJson(p);
      if (json == null) continue;
      try {
        final m = PrototypeFlashcardSetManifest.fromJson(json);
        if (m.isValid) out.add(m);
      } catch (_) {}
    }
    return out;
  }

  /// All bundled assessment manifests.
  Future<List<PrototypeAssessmentManifest>> getPrototypeAssessments() async {
    final paths = await _manifestPaths(_assessmentDir);
    final out = <PrototypeAssessmentManifest>[];
    for (final p in paths) {
      final json = await _readJson(p);
      if (json == null) continue;
      try {
        final m = PrototypeAssessmentManifest.fromJson(json);
        if (m.isValid) out.add(m);
      } catch (_) {}
    }
    return out;
  }

  /// Demo resolver: Class 2 → Mathematics → Numbers up to 100 →
  /// Bilingual Worksheet. Returns the matching bundled manifest, or null
  /// when the teacher has not added the file yet (no fake content).
  Future<PrototypeWorksheetManifest?> findWorksheetManifest({
    required String className,
    required String subject,
    required String topic,
  }) async {
    final all = await getPrototypeWorksheets();
    final norm = (String s) => s.trim().toLowerCase();
    for (final m in all) {
      if (norm(m.className) == norm(className) &&
          norm(m.subject) == norm(subject) &&
          norm(m.topic) == norm(topic)) {
        return m;
      }
    }
    // Loose fallback: same class+subject when topic wording differs.
    for (final m in all) {
      if (norm(m.className) == norm(className) &&
          norm(m.subject) == norm(subject)) {
        return m;
      }
    }
    return null;
  }

  /// Converts a worksheet manifest into the EXISTING [WorksheetItem] model
  /// so the current preview / save / download UI is reused unchanged.
  ///
  /// Questions live in the manifest's optional `questions` array when the
  /// teacher provides them; otherwise the item carries the real metadata
  /// with an empty question list and the preview shows the bundled PDF
  /// asset path (never fabricated questions).
  WorksheetItem worksheetItemFromManifest(
    PrototypeWorksheetManifest manifest, {
    Map<String, dynamic>? manifestJson,
  }) {
    final rawQuestions =
        (manifestJson?['questions'] as List?) ?? const [];
    final questions = <WorksheetQuestion>[];
    for (var i = 0; i < rawQuestions.length; i++) {
      final e = rawQuestions[i];
      if (e is! Map) continue;
      final q = Map<String, dynamic>.from(e);
      questions.add(WorksheetQuestion(
        questionNumber: (q['number'] as num?)?.toInt() ?? (i + 1),
        promptHindi: (q['promptHindi'] ?? '').toString(),
        promptTribal: (q['promptTribal'] ?? '').toString(),
        visualIllustration: (q['image'] ?? '').toString(),
        options: ((q['options'] as List?) ?? const [])
            .map((o) => o.toString())
            .toList(),
        answer: (q['answer'] ?? '').toString(),
      ));
    }
    final grade =
        int.tryParse(manifest.className.replaceAll(RegExp(r'[^0-9]'), '')) ??
            2;
    return WorksheetItem(
      id: manifest.id,
      title: manifest.title,
      titleHi: manifest.topic,
      grade: grade,
      subject: manifest.subject,
      outcomeCode: manifest.id,
      targetLanguage: TribalLanguage.santali,
      difficulty: DifficultyLevel.medium,
      type: WorksheetType.practice,
      questionCount: questions.length,
      questions: questions,
      createdAt: DateTime.now(),
    );
  }

  /// Download payload for a prototype worksheet. Reuses the same keys the
  /// existing `downloadWorksheet()` + preview pipeline expects, with the
  /// bundled PDF referenced under `assets['pdf']` so Downloads can open
  /// the local file offline.
  Map<String, dynamic> downloadPayloadForWorksheet(
    PrototypeWorksheetManifest manifest, {
    Map<String, dynamic>? manifestJson,
  }) {
    final item =
        worksheetItemFromManifest(manifest, manifestJson: manifestJson);
    return {
      'content_id': manifest.id,
      'request_id': manifest.id,
      'title': manifest.title,
      'title_hi': manifest.topic,
      'grade': item.grade,
      'section': 'General',
      'subject': manifest.subject,
      'topic': manifest.topic,
      'topic_source': 'prototype',
      'curriculum_id': manifest.id,
      'nipun_outcome': manifest.id,
      'source_language': 'hi',
      'target_language': 'sat',
      'language_1': 'hi',
      'language_2': 'sat',
      'difficulty': 'medium',
      'content_type': 'worksheet',
      'prototype': true,
      'prototype_asset': manifest.asset,
      'question_count': item.questions.length,
      'questions': item.questions
          .map((q) => {
                'questionNumber': q.questionNumber,
                'promptHindi': q.promptHindi,
                'promptTribal': q.promptTribal,
                'options': q.options,
                'answer': q.answer,
              })
          .toList(),
    };
  }
}
