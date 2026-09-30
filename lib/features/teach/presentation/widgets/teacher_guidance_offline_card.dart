import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/content/prototype_content_repository.dart';
import '../../../../core/widgets/custom_card.dart';

/// "Teacher Guidance & Offline Support" — compact teacher-support panel for
/// the Teach home screen.
///
/// Architecture flow represented:
/// ```text
/// Class / Subject / Topic (NIPUN Outcome)
///   -> step-by-step guidance, examples, classroom activities
///   -> auto-generated offline flashcards, visuals, assessments (NIPUN-aligned)
/// ```
///
/// * Reads ONLY bundled/local prototype content for the materials summary —
///   never touches FastAPI, Supabase, or Sarvam, so the card and its targets
///   open with Wi-Fi/mobile data OFF.
/// * "Get Teaching Guidance" opens the deterministic offline Q&A screen
///   ([AppRoutes.teacherGuidance]) with the live class/subject context;
///   other tiles reuse existing routes ([AppRoutes.downloads],
///   [AppRoutes.lessonPlanner]).
/// * Compact + responsive: two-column action row on tablet widths (>= 560),
///   stacked full-width actions on narrow phones. No fixed heights, every
///   label wraps or ellipsizes — no RenderFlex overflow.
class TeacherGuidanceOfflineCard extends StatefulWidget {
  /// Currently selected class (1-5). Drives the lesson-context line.
  final int selectedGrade;

  /// Currently selected subject label from [TeachBloc] (e.g. Mathematics).
  final String selectedSubject;

  /// Number of real NIPUN outcomes loaded for the class. Shown as-is;
  /// never fabricated.
  final int outcomeCount;

  /// Optional repository override (tests). Defaults to the registered
  /// [PrototypeContentRepository] when available, else null (generic copy).
  final PrototypeContentRepository? prototypeRepository;

  const TeacherGuidanceOfflineCard({
    super.key,
    required this.selectedGrade,
    required this.selectedSubject,
    this.outcomeCount = 0,
    this.prototypeRepository,
  });

  @override
  State<TeacherGuidanceOfflineCard> createState() =>
      _TeacherGuidanceOfflineCardState();
}

class _TeacherGuidanceOfflineCardState
    extends State<TeacherGuidanceOfflineCard> {
  Future<({int flashcards, int visuals, int assessments})?>? _countsFuture;

  @override
  void initState() {
    super.initState();
    _countsFuture = _loadOfflineCounts();
  }

  @override
  void didUpdateWidget(TeacherGuidanceOfflineCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedGrade != widget.selectedGrade ||
        oldWidget.selectedSubject != widget.selectedSubject ||
        oldWidget.prototypeRepository != widget.prototypeRepository) {
      _countsFuture = _loadOfflineCounts();
    }
  }

  PrototypeContentRepository? _resolveRepository() {
    if (widget.prototypeRepository != null) return widget.prototypeRepository;
    if (getIt.isRegistered<PrototypeContentRepository>()) {
      try {
        return getIt<PrototypeContentRepository>();
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  static String _norm(String s) => s.trim().toLowerCase();

  /// Loose subject match so 'Mathematics' matches 'Math'/'Maths' manifests
  /// and vice versa without inventing curriculum data.
  static bool _subjectMatches(String manifestSubject, String selected) {
    final m = _norm(manifestSubject);
    final s = _norm(selected);
    if (m.isEmpty || s.isEmpty) return false;
    if (m == s) return true;
    // Compare first 4 letters to tolerate Math/Mathematics, EVS variants.
    final a = m.length >= 4 ? m.substring(0, 4) : m;
    final b = s.length >= 4 ? s.substring(0, 4) : s;
    return a == b;
  }

  static bool _classMatches(String className, int grade) {
    final digits = className.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return true; // Untagged bundle content: keep visible.
    return (int.tryParse(digits) ?? grade) == grade;
  }

  /// Counts bundled offline materials for the active class/subject.
  /// Returns null when the catalog cannot be read (caller shows generic
  /// copy instead of fake counts). Never throws.
  Future<({int flashcards, int visuals, int assessments})?>
      _loadOfflineCounts() async {
    final repo = _resolveRepository();
    if (repo == null) return null;
    try {
      final sets = await repo.getPrototypeFlashcardSets();
      final assessments = await repo.getPrototypeAssessments();
      final worksheets = await repo.getPrototypeWorksheets();
      int flashcards = 0, visuals = 0, assess = 0;
      for (final s in sets) {
        if (_classMatches(s.className, widget.selectedGrade) &&
            _subjectMatches(s.subject, widget.selectedSubject)) {
          flashcards += s.cardCount > 0 ? s.cardCount : 1;
        }
      }
      for (final a in assessments) {
        if (_classMatches(a.className, widget.selectedGrade) &&
            _subjectMatches(a.subject, widget.selectedSubject)) {
          assess += 1;
        }
      }
      for (final w in worksheets) {
        if (_classMatches(w.className, widget.selectedGrade) &&
            _subjectMatches(w.subject, widget.selectedSubject)) {
          visuals += 1;
        }
      }
      return (flashcards: flashcards, visuals: visuals, assessments: assess);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      key: const Key('teacherGuidanceCard'),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Title + offline indicator.
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  'Teacher Guidance & Offline Support',
                  style: AppTypography.cardTitle.copyWith(fontSize: 14),
                  softWrap: true,
                ),
              ),
              const SizedBox(width: 8),
              const _OfflineReadyPill(),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            'Plan, teach and create classroom resources offline.',
            style: AppTypography.caption.copyWith(fontSize: 11),
            softWrap: true,
          ),
          const SizedBox(height: 10),

          // Lesson context (active Class / Subject + real outcome count).
          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.backgroundSoft,
              borderRadius: AppRadius.radiusMd,
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Row(
              children: [
                const Icon(Icons.school_outlined,
                    size: 16, color: AppColors.primaryDark),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.outcomeCount > 0
                        ? 'Class ${widget.selectedGrade} \u2022 ${widget.selectedSubject} \u2022 ${widget.outcomeCount} NIPUN outcomes'
                        : 'Class ${widget.selectedGrade} \u2022 ${widget.selectedSubject}',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                    softWrap: true,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'NIPUN-aligned',
                  style: AppTypography.captionSmall.copyWith(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Two guidance/material actions: side-by-side on tablet, stacked
          // full-width on narrow phones.
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 560;
              final guidanceTile = _GuidanceActionTile(
                key: const Key('getTeachingGuidanceButton'),
                icon: Icons.menu_book_outlined,
                iconColor: AppColors.primary,
                title: 'Get Teaching Guidance',
                subtitle: 'Steps \u2022 Examples \u2022 Activities',
                semanticLabel:
                    'Get step-by-step teaching guidance with examples and classroom activities',
                onTap: () => context.push(
                  AppRoutes.teacherGuidance,
                  extra: {
                    'className': 'Class ${widget.selectedGrade}',
                    'subject': widget.selectedSubject,
                  },
                ),
              );
              final materialsTile = _OfflineMaterialsTile(
                key: const Key('offlineMaterialsButton'),
                countsFuture: _countsFuture,
                onTap: () => context.push(AppRoutes.downloads),
              );
              if (wide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: guidanceTile),
                    const SizedBox(width: 8),
                    Expanded(child: materialsTile),
                  ],
                );
              }
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  guidanceTile,
                  const SizedBox(height: 8),
                  materialsTile,
                ],
              );
            },
          ),
          const SizedBox(height: 10),

          // Primary: continue the guided lesson (existing planner flow —
          // class/subject context is preserved via TeachBloc).
          SizedBox(
            width: double.infinity,
            child: _ContinueLessonButton(
              onPressed: () => context.push(AppRoutes.lessonPlanner),
            ),
          ),
        ],
      ),
    );
  }
}

/// Small subtle "Offline Ready" indicator — local resources available.
class _OfflineReadyPill extends StatelessWidget {
  const _OfflineReadyPill();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Teacher resources are available locally, offline ready',
      child: Container(
        key: const Key('offlineReadyIndicator'),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.greenLight,
          borderRadius: AppRadius.radiusPill,
          border: Border.all(color: AppColors.greenBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              'Offline Ready',
              style: AppTypography.captionSmall.copyWith(
                color: AppColors.primaryDark,
                fontWeight: FontWeight.w700,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact secondary action tile (icon + two-line label, full tap area).
class _GuidanceActionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String semanticLabel;
  final VoidCallback onTap;

  const _GuidanceActionTile({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.semanticLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: Material(
        color: Colors.white,
        borderRadius: AppRadius.radiusMd,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.radiusMd,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: AppRadius.radiusMd,
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: iconColor, size: 18),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: AppTypography.cardTitleSmall.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                        softWrap: true,
                      ),
                      const SizedBox(height: 1),
                      Text(
                        subtitle,
                        style: AppTypography.captionSmall,
                        softWrap: true,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded,
                    size: 10, color: AppColors.textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Offline materials tile. Shows REAL bundled counts for the active
/// class/subject, "No offline materials yet" when the local catalog is
/// empty, and generic copy while loading / when no repository is
/// available. Never shows fake counts.
class _OfflineMaterialsTile extends StatelessWidget {
  final Future<({int flashcards, int visuals, int assessments})?>?
      countsFuture;
  final VoidCallback onTap;

  const _OfflineMaterialsTile({
    super.key,
    required this.countsFuture,
    required this.onTap,
  });

  String _labelFor(
      ({int flashcards, int visuals, int assessments})? counts) {
    if (counts == null) return 'Flashcards \u2022 Visuals \u2022 Assessments';
    final total = counts.flashcards + counts.visuals + counts.assessments;
    if (total == 0) return 'No offline materials yet';
    final parts = <String>[];
    if (counts.flashcards > 0) {
      parts.add('${counts.flashcards} flashcards');
    }
    if (counts.visuals > 0) parts.add('${counts.visuals} visuals');
    if (counts.assessments > 0) {
      parts.add('${counts.assessments} assessments');
    }
    return parts.join(' \u2022 ');
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<
        ({int flashcards, int visuals, int assessments})?>(
      future: countsFuture,
      builder: (context, snapshot) {
        final subtitle = snapshot.connectionState == ConnectionState.waiting
            ? 'Flashcards \u2022 Visuals \u2022 Assessments'
            : _labelFor(snapshot.data);
        return _GuidanceActionTile(
          icon: Icons.style_outlined,
          iconColor: AppColors.accentOrange,
          title: 'Offline Materials',
          subtitle: subtitle,
          semanticLabel:
              'Open offline materials: flashcards, visuals and assessments, $subtitle',
          onTap: onTap,
        );
      },
    );
  }
}

/// Compact primary action (44px, wraps label) — visually strongest element.
class _ContinueLessonButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _ContinueLessonButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Continue lesson: open the guided lesson',
      child: Material(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          key: const Key('continueLessonButton'),
          onTap: onPressed,
          borderRadius: BorderRadius.circular(999),
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.center,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.play_arrow_rounded,
                    size: 18, color: Colors.white),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'Continue Lesson',
                    style: AppTypography.buttonText
                        .copyWith(fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
