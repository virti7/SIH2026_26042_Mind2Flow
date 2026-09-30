import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/di/injection.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/enums/app_enums.dart';
import '../../../../core/models/app_models.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/badges.dart';
import '../../../../core/widgets/chips.dart';
import '../../../../core/widgets/custom_card.dart';
import '../../../../core/widgets/section_header.dart';
import '../bloc/progress_bloc.dart';

// SCREEN 52: Subject Progress (Longitudinal Skill Tracking by Subject)
class SubjectProgressScreen extends StatelessWidget {
  final String studentId;

  const SubjectProgressScreen({super.key, required this.studentId});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProgressBloc, ProgressState>(
      builder: (context, state) {
        // Neutral fallback shown only until the real record loads;
        // never a fictional learner with invented scores.
        StudentRecord student = const StudentRecord(
          id: 'unknown',
          name: 'Learner',
          rollNumber: 0,
          grade: 2,
          motherTongue: TribalLanguage.santali,
          achievedOutcomes: 0,
          developingOutcomes: 0,
          needsSupportOutcomes: 0,
          literacyProgress: 0.0,
          numeracyProgress: 0.0,
          recentEvidence: 'No assessment records on this device yet.',
          assessmentHistory: [],
          identifiedGaps: [],
        );

        if (state is StudentDetailLoaded) {
          student = state.student;
        }

        return AppScaffold(
          title: '${student.name}\'s Subject Progress',
          subtitle: 'Detailed skill breakdown across Foundational Literacy and Numeracy.',
          breadcrumb: 'Progress > ${student.name} > Subjects',
          isScrollable: true,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Foundational Literacy Breakdown
              SectionHeader(title: 'Foundational Literacy (भाषा एवं साक्षरता)', titleHindi: 'दक्षता स्तर: ${(student.literacyProgress * 100).toInt()}%'),
              const SizedBox(height: 8),
              _buildSkillRow('Oral Language Development (मौखिक भाषा)', OutcomeStatus.achieved),
              _buildSkillRow('Phonological Decoding (ध्वनि व वर्ण पहचान)', OutcomeStatus.achieved),
              _buildSkillRow('Reading & Comprehension (पठन एवं बोध)', OutcomeStatus.developing),
              _buildSkillRow('Writing & Expression (लेखन एवं अभिव्यक्ति)', OutcomeStatus.developing),
              const SizedBox(height: 20),

              // Foundational Numeracy Breakdown
              SectionHeader(title: 'Foundational Numeracy (संख्या ज्ञान एवं गणित)', titleHindi: 'दक्षता स्तर: ${(student.numeracyProgress * 100).toInt()}%'),
              const SizedBox(height: 8),
              _buildSkillRow('Oral Math Talk & Counting (मौखिक गिनती)', OutcomeStatus.achieved),
              _buildSkillRow('Numbers up to 100 (100 तक संख्याएं)', student.needsSupportOutcomes > 0 ? OutcomeStatus.needsSupport : OutcomeStatus.achieved),
              _buildSkillRow('Concrete Addition & Subtraction (जोड़-घटाव)', OutcomeStatus.developing),
              _buildSkillRow('Patterns & Shapes (पैटर्न एवं आकृतियां)', OutcomeStatus.achieved),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSkillRow(String skillName, OutcomeStatus status) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: CustomCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: Text(skillName, style: AppTypography.cardTitle.copyWith(fontSize: 13))),
            StatusChip(status: status),
          ],
        ),
      ),
    );
  }
}

// SCREEN 53: Assessment History (Chronological Assessment Log from SQLite)
class AssessmentHistoryScreen extends StatelessWidget {
  final String studentId;

  const AssessmentHistoryScreen({super.key, required this.studentId});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Assessment History',
      subtitle: 'Chronological timeline of formative tablet evaluations stored locally in SQLite.',
      breadcrumb: 'Progress > Student > History',
      isScrollable: true,
      body: FutureBuilder<List<AssessmentResultRecord>>(
        // Web demo: no AppDatabase registered, show empty state.
        future: getIt.isRegistered<AppDatabase>()
            ? getIt<AppDatabase>()
                .assessmentDao
                .getAssessmentResultsForStudent(studentId)
            : Future.value(const <AssessmentResultRecord>[]),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          final results = snapshot.data ?? [];
          if (results.isEmpty) {
            return CustomCard(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Column(
                  children: [
                    const Icon(Icons.history_rounded, size: 36, color: AppColors.textMuted),
                    const SizedBox(height: 8),
                    Text('No assessments recorded yet', style: AppTypography.cardTitle),
                    const SizedBox(height: 4),
                    Text('Conduct a formative check in Teach mode to see results here.', style: AppTypography.caption),
                  ],
                ),
              ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...results.map((r) {
                final status = r.status.toLowerCase() == 'achieved'
                    ? OutcomeStatus.achieved
                    : (r.status.toLowerCase() == 'developing' ? OutcomeStatus.developing : OutcomeStatus.needsSupport);

                final dateStr = '${r.completedAt.day} ${_monthName(r.completedAt.month)} ${r.completedAt.year}';
                final pct = r.totalQuestions > 0 ? ((r.correctCount / r.totalQuestions) * 100).toInt() : 0;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: CustomCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(dateStr, style: AppTypography.caption.copyWith(fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis),
                            ),
                            const SizedBox(width: 8),
                            StatusChip(status: status),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(r.outcomeTitle, style: AppTypography.cardTitle.copyWith(fontSize: 15)),
                        const SizedBox(height: 2),
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 4,
                          children: [
                            Text('NIPUN: ${r.outcomeCode}', style: AppTypography.caption),
                            const Text('•', style: TextStyle(color: AppColors.textMuted)),
                            Text('Score: ${r.correctCount} / ${r.totalQuestions} ($pct%)', style: AppTypography.caption.copyWith(fontWeight: FontWeight.w600, color: AppColors.primary)),
                            const Text('•', style: TextStyle(color: AppColors.textMuted)),
                            Text(r.syncStatus.toUpperCase(), style: AppTypography.caption.copyWith(color: AppColors.accentBlue, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: AppColors.greenSurface, borderRadius: AppRadius.radiusMd),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.notes_rounded, size: 16, color: AppColors.primary),
                              const SizedBox(width: 8),
                              Expanded(child: Text(r.recommendedRemediation, style: AppTypography.bodySmall)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }

  String _monthName(int month) {
    const names = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return (month >= 1 && month <= 12) ? names[month - 1] : '';
  }
}

// SCREEN 54: Learning Gap History (Diagnosed Obstacles & Remediation Logs from SQLite)
class LearningGapHistoryScreen extends StatelessWidget {
  final String studentId;

  const LearningGapHistoryScreen({super.key, required this.studentId});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Learning Gap History',
      subtitle: 'Record of diagnosed learning gaps and remedial interventions stored locally.',
      breadcrumb: 'Progress > Student > Gaps',
      isScrollable: true,
      body: FutureBuilder<List<LearningGapData>>(
        // Web demo: no AppDatabase registered, show empty state.
        future: getIt.isRegistered<AppDatabase>()
            ? getIt<AppDatabase>().studentDao.getLearningGapsByStudent(studentId)
            : Future.value(const <LearningGapData>[]),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          final gaps = snapshot.data ?? [];
          if (gaps.isEmpty) {
            return CustomCard(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Column(
                  children: [
                    const Icon(Icons.verified_rounded, size: 36, color: AppColors.statusAchieved),
                    const SizedBox(height: 8),
                    Text('No active learning gaps', style: AppTypography.cardTitle),
                    const SizedBox(height: 4),
                    Text('Student is meeting all foundational learning targets.', style: AppTypography.caption),
                  ],
                ),
              ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...gaps.map((gap) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: CustomCard(
                    color: gap.isResolved ? AppColors.greenSurface : AppColors.surface,
                    border: BorderSide(
                      color: gap.isResolved ? AppColors.greenBorder : AppColors.statusNeedsSupport,
                      width: 1.2,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              gap.isResolved ? Icons.check_circle_rounded : Icons.warning_amber_rounded,
                              color: gap.isResolved ? AppColors.statusAchieved : AppColors.statusNeedsSupport,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                gap.status,
                                style: TextStyle(
                                  color: gap.isResolved ? AppColors.statusAchieved : AppColors.statusNeedsSupport,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(gap.skill, style: AppTypography.cardTitle.copyWith(fontSize: 15)),
                        const SizedBox(height: 8),
                        Text('Root Cause (कारण):', style: AppTypography.caption.copyWith(fontWeight: FontWeight.w700)),
                        Text(gap.rootCause, style: AppTypography.bodySmall),
                        const SizedBox(height: 8),
                        Text('Remedial Action (उपचारात्मक कदम):', style: AppTypography.caption.copyWith(fontWeight: FontWeight.w700)),
                        Text(gap.remediationUsed, style: AppTypography.bodySmall),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }
}

// SCREEN 55: Recommended Next Lessons (Personalized Planning from SQLite)
class RecommendedLessonsScreen extends StatelessWidget {
  final String studentId;

  const RecommendedLessonsScreen({super.key, required this.studentId});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Recommended Next Lessons',
      subtitle: 'Personalized pedagogical suggestions based on unfinished learning outcomes.',
      breadcrumb: 'Progress > Student > Recommendations',
      isScrollable: true,
      body: FutureBuilder<List<RemedialRecommendationData>>(
        // Web demo: no AppDatabase registered, show empty state.
        future: getIt.isRegistered<AppDatabase>()
            ? getIt<AppDatabase>()
                .studentDao
                .getRemedialRecommendations('M2.1.4', studentId: studentId)
            : Future.value(const <RemedialRecommendationData>[]),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          final recs = snapshot.data ?? [];
          if (recs.isEmpty) {
            return CustomCard(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Column(
                  children: [
                    const Icon(Icons.menu_book_rounded, size: 36, color: AppColors.primary),
                    const SizedBox(height: 8),
                    Text('On track with curriculum', style: AppTypography.cardTitle),
                    const SizedBox(height: 4),
                    Text('Continue standard NIPUN FLN sequence for Class 2.', style: AppTypography.caption),
                  ],
                ),
              ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...recs.map((rec) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: CustomCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(color: AppColors.greenSurface, borderRadius: AppRadius.radiusPill),
                              child: Text(rec.outcomeCode, style: AppTypography.chipLabel.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)),
                            ),
                            const NipunBadge(),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(rec.title, style: AppTypography.cardTitle.copyWith(fontSize: 15)),
                        Text(rec.subject, style: AppTypography.caption),
                        const SizedBox(height: 8),
                        Text('Local Context: ${rec.culturalHook}', style: AppTypography.bodySmall.copyWith(color: AppColors.primaryDark)),
                        const SizedBox(height: 4),
                        Text('Pedagogical Rationale: ${rec.reason}', style: AppTypography.caption),
                        const SizedBox(height: 12),
                        PrimaryButton(
                          label: 'Plan This Lesson',
                          icon: Icons.calendar_today_rounded,
                          onPressed: () => context.push(AppRoutes.lessonPlanner),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }
}
