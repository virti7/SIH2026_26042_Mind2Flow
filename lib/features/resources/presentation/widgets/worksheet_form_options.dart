import '../../../../core/database/app_database.dart';

/// One curriculum topic/skill selectable in the worksheet generator.
/// Carries official curriculum/NIPUN metadata (never invented).
class CurriculumTopic {
  final String id;
  final String code; // NIPUN code/outcome, e.g. M2.1.4
  final String title; // e.g. Numbers up to 100
  final String titleHi;
  final int grade;
  final String subject;
  final String domain;

  const CurriculumTopic({
    required this.id,
    required this.code,
    required this.title,
    this.titleHi = '',
    required this.grade,
    required this.subject,
    required this.domain,
  });
}

/// Dynamic option loaders for the worksheet generator form.
/// Everything comes from the on-device curriculum/classroom data
/// (Drift). Nothing is hardcoded except the last-resort fallbacks used
/// when the database has no rows yet (fresh install before provisioning).
class WorksheetFormOptions {
  WorksheetFormOptions._();

  /// Classes from the teacher's classrooms; falls back to 1-5.
  static Future<List<int>> loadClasses(AppDatabase db) async {
    try {
      final rows = await db.select(db.classrooms).get();
      final grades = rows.map((r) => r.grade).toSet().toList()..sort();
      if (grades.isNotEmpty) return grades;
    } catch (_) {}
    return const [1, 2, 3, 4, 5];
  }

  /// Sections for a class from classroom data; falls back to A/B/C/General.
  static Future<List<String>> loadSections(AppDatabase db, int grade) async {
    try {
      final rows = await (db.select(db.classrooms)
            ..where((t) => t.grade.equals(grade)))
          .get();
      final sections = rows
          .map((r) => r.section.trim())
          .where((s) => s.isNotEmpty)
          .toSet()
          .toList()
        ..sort();
      if (sections.isNotEmpty) {
        if (!sections.contains('General')) sections.add('General');
        return sections;
      }
    } catch (_) {}
    return const ['A', 'B', 'C', 'General'];
  }

  /// Subjects from curriculum data (activities + outcome domains mapped to
  /// subject names); falls back to the configured curriculum subjects.
  static Future<List<String>> loadSubjects(AppDatabase db) async {
    final found = <String>{};
    try {
      final activities = await db.curriculumDao.getActivities();
      for (final a in activities) {
        final s = a.subject.trim();
        if (s.isNotEmpty) found.add(s);
      }
    } catch (_) {}
    try {
      final outcomes = await db.curriculumDao.getOutcomes();
      for (final o in outcomes) {
        for (final s in subjectsForDomain(o.domain)) {
          found.add(s);
        }
      }
    } catch (_) {}
    if (found.isEmpty) {
      return const [
        'Mathematics',
        'Language',
        'Foundational Literacy',
        'Foundational Numeracy',
        'EVS',
      ];
    }
    const order = [
      'Mathematics',
      'Language',
      'Foundational Literacy',
      'Foundational Numeracy',
      'EVS',
    ];
    final sorted = found.toList()
      ..sort((a, b) {
        final ia = order.indexOf(a);
        final ib = order.indexOf(b);
        return (ia < 0 ? 99 : ia).compareTo(ib < 0 ? 99 : ib);
      });
    return sorted;
  }

  /// Curriculum topics for a class + subject from NIPUN outcomes.
  static Future<List<CurriculumTopic>> loadTopics(
    AppDatabase db,
    int grade,
    String subject,
  ) async {
    try {
      final outcomes = await db.curriculumDao.getOutcomes(grade: grade);
      final wanted = _domainsForSubject(subject);
      final topics = <CurriculumTopic>[];
      for (final o in outcomes) {
        if (wanted.isNotEmpty && !wanted.contains(o.domain)) continue;
        topics.add(CurriculumTopic(
          id: o.id,
          code: o.code,
          title: o.titleEn,
          titleHi: o.titleHi,
          grade: o.grade,
          subject: subject,
          domain: o.domain,
        ));
      }
      // If the subject filter removed everything, show all grade topics
      // rather than an empty list (subject coverage gaps in seed data).
      if (topics.isEmpty) {
        for (final o in outcomes) {
          topics.add(CurriculumTopic(
            id: o.id,
            code: o.code,
            title: o.titleEn,
            titleHi: o.titleHi,
            grade: o.grade,
            subject: subject,
            domain: o.domain,
          ));
        }
      }
      return topics;
    } catch (_) {
      return const [];
    }
  }

  /// Subject names that belong to a curriculum domain.
  static List<String> subjectsForDomain(String domain) {
    final d = domain.toLowerCase();
    if (d.contains('numeracy') || d.contains('math')) {
      return const ['Mathematics', 'Foundational Numeracy'];
    }
    if (d.contains('literacy') || d.contains('language')) {
      return const ['Language', 'Foundational Literacy'];
    }
    return const ['EVS'];
  }

  static List<String> _domainsForSubject(String subject) {
    final s = subject.toLowerCase();
    if (s.contains('math') || s.contains('numeracy')) {
      return const ['Foundational Numeracy'];
    }
    if (s.contains('lang') || s.contains('literacy')) {
      return const ['Foundational Literacy'];
    }
    return const [];
  }
}
