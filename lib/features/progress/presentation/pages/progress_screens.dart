import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/enums/app_enums.dart';
import '../../../../core/models/app_models.dart';
import '../../../../core/models/teacher_activity.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/badges.dart';
import '../../../../core/widgets/custom_card.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../../core/widgets/section_header.dart';
import '../bloc/progress_bloc.dart';

String _formatActivityDate(DateTime value) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  final day = value.day.toString().padLeft(2, '0');
  final month = months[value.month - 1];
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '$day $month ${value.year}, $hour:$minute';
}

// SCREEN 49: Progress Home
class ProgressHomeScreen extends StatefulWidget {
  const ProgressHomeScreen({super.key});

  @override
  State<ProgressHomeScreen> createState() => _ProgressHomeScreenState();
}

class _ProgressHomeScreenState extends State<ProgressHomeScreen> {
  @override
  void initState() {
    super.initState();
    context.read<ProgressBloc>().add(LoadProgressDashboard());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProgressBloc, ProgressState>(
      builder: (context, state) {
        if (state is ProgressLoading) {
          return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppColors.primary)));
        }

        if (state is ProgressError) {
          return AppScaffold(
            title: 'My Teaching Progress',
            subtitle: 'Lessons taught, assessments and resources — all on this device.',
            breadcrumb: 'Teacher Progress',
            showBackButton: false,
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(state.message, style: AppTypography.bodyMedium, textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  PrimaryButton(
                    label: 'Retry',
                    onPressed: () => context.read<ProgressBloc>().add(LoadProgressDashboard()),
                  ),
                ],
              ),
            ),
          );
        }

        if (state is ProgressDashboardLoaded) {
          final summary = state.summary;
          return AppScaffold(
            title: 'My Teaching Progress',
            subtitle: 'Lessons taught, assessments and resources — all on this device.',
            breadcrumb: 'Teacher Progress',
            showBackButton: false,
            isScrollable: true,
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (summary.isEmpty)
                  const EmptyStateView(
                    icon: Icons.trending_up_rounded,
                    title: 'No teaching activity yet',
                    description:
                        'Your teaching activity will appear here once you start teaching.',
                  )
                else ...[
                  // Teacher activity summary — every count comes from local records.
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricTile(
                          icon: Icons.menu_book_rounded,
                          count: '${summary.lessonsTaught}',
                          label: 'Lessons taught',
                          sub: summary.classesTaught.isEmpty
                              ? 'This device'
                              : summary.classesTaught.join(' • '),
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildMetricTile(
                          icon: Icons.fact_check_outlined,
                          count: '${summary.assessmentsConducted}',
                          label: 'Assessments',
                          sub: 'Conducted offline',
                          color: AppColors.accentBlue,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildMetricTile(
                          icon: Icons.style_outlined,
                          count: '${summary.totalResources}',
                          label: 'Resources',
                          sub: 'Created & used',
                          color: AppColors.accentOrange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  CustomCard(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(9),
                          decoration: const BoxDecoration(
                            color: AppColors.accentPurpleLight,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.eco_rounded, color: AppColors.accentPurple, size: 22),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  summary.subjectsTaught.isEmpty
                                      ? 'Teaching focus: not recorded yet'
                                      : 'Teaching focus: ${summary.subjectsTaught.join(', ')}',
                                  style: AppTypography.cardTitle.copyWith(fontSize: 13)),
                              const SizedBox(height: 2),
                              Text(
                                  summary.pendingSyncCount > 0
                                      ? '${summary.pendingSyncCount} records waiting to sync'
                                      : 'Works offline • New activity syncs when you are online',
                                  style: AppTypography.caption),
                            ],
                          ),
                        ),
                        const OfflineBadge(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Recent teaching activity — teacher-only, from stored records.
                  const SectionHeader(title: 'Recent teaching activity'),
                  const SizedBox(height: 8),
                  if (summary.recentActivities.isEmpty)
                    const CustomCard(
                      child: Text('Your teaching activity will appear here once you start teaching.'),
                    )
                  else
                    for (final activity in summary.recentActivities)
                      _buildActivityRow(activity: activity),
                  const SizedBox(height: 20),

                  // Teaching focus from actual activity distribution.
                  const SectionHeader(title: 'Teaching focus'),
                  const SizedBox(height: 8),
                  if (summary.subjectCounts.isEmpty)
                    const CustomCard(
                      child: Text('Teach a lesson or generate a resource to see your focus.'),
                    )
                  else
                    CustomCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (final entry in summary.subjectCounts.entries)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _buildFocusBar(
                                entry.key,
                                entry.value,
                                _maxCount(summary.subjectCounts),
                                AppColors.accentPurple,
                              ),
                            ),
                          if (summary.languagesUsed.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Languages used: ${summary.languagesUsed.join(', ')}',
                              style: AppTypography.caption,
                            ),
                          ],
                          if (summary.outcomesTaught.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              'NIPUN outcomes taught: ${summary.outcomesTaught.join(', ')}',
                              style: AppTypography.caption,
                            ),
                          ],
                        ],
                      ),
                    ),
                  const SizedBox(height: 20),

                  // Resource usage — what the teacher actually created and used.
                  const SectionHeader(title: 'Resource usage'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildUsageTile(
                          icon: Icons.assignment_outlined,
                          count: '${summary.worksheetsGenerated}',
                          label: 'Worksheets generated',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildUsageTile(
                          icon: Icons.download_done_rounded,
                          count: '${summary.worksheetsDownloaded}',
                          label: 'Worksheets downloaded',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildUsageTile(
                          icon: Icons.style_outlined,
                          count: '${summary.flashcardSetsUsed}',
                          label: 'Flashcards used',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _buildUsageTile(
                          icon: Icons.style_rounded,
                          count: '${summary.flashcardsDownloaded}',
                          label: 'Flashcards downloaded',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildUsageTile(
                          icon: Icons.sports_esports_outlined,
                          count: '${summary.activitiesDownloaded}',
                          label: 'Activities downloaded',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildUsageTile(
                          icon: Icons.fact_check_outlined,
                          count: '${summary.assessmentsConducted}',
                          label: 'Assessments conducted',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: _buildUsageTile(
                        icon: Icons.menu_book_outlined,
                        count: '${summary.lessonsTaught}',
                        label: 'Lessons taught',
                      )),
                      const SizedBox(width: 10),
                      const Expanded(child: SizedBox.shrink()),
                      const SizedBox(width: 10),
                      const Expanded(child: SizedBox.shrink()),
                    ],
                  ),
                  if (summary.worksheetsGenerated == 0) ...[
                    const SizedBox(height: 10),
                    const CustomCard(child: Text('No bilingual worksheets generated yet.')),
                  ],
                  if (summary.flashcardSetsUsed == 0) ...[
                    const SizedBox(height: 10),
                    const CustomCard(child: Text('No flashcards generated yet.')),
                  ],
                  if (summary.assessmentsConducted == 0) ...[
                    const SizedBox(height: 10),
                    const CustomCard(child: Text('No assessments conducted yet.')),
                  ],
                  if (summary.lessonsTaught == 0) ...[
                    const SizedBox(height: 10),
                    const CustomCard(child: Text('No lessons taught yet.')),
                  ],
                ],
                const SizedBox(height: 24),
              ],
            ),
          );
        }

        return const Scaffold(body: SizedBox.shrink());
      },
    );
  }

  static int _maxCount(Map<String, int> counts) {
    var max = 0;
    for (final value in counts.values) {
      if (value > max) max = value;
    }
    return max == 0 ? 1 : max;
  }

  Widget _buildMetricTile({
    required IconData icon,
    required String count,
    required String label,
    required String sub,
    required Color color,
  }) {
    return CustomCard(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(count, style: AppTypography.screenTitle.copyWith(fontSize: 20)),
          Text(label, style: AppTypography.chipLabel.copyWith(fontSize: 10)),
          Text(sub, style: AppTypography.caption.copyWith(fontSize: 9, color: AppColors.textMuted)),
        ],
      ),
    );
  }

  Widget _buildActivityRow({required TeacherActivity activity}) {
    final (icon, color, bg) = switch (activity.type) {
      TeacherActivityType.lessonTaught => (Icons.menu_book_rounded, AppColors.primary, AppColors.pastelGreen),
      TeacherActivityType.assessmentConducted => (Icons.fact_check_outlined, AppColors.accentBlue, AppColors.pastelBlue),
      TeacherActivityType.worksheetGenerated => (Icons.assignment_outlined, AppColors.accentOrange, AppColors.pastelPeach),
      TeacherActivityType.worksheetDownloaded => (Icons.download_done_rounded, AppColors.primary, AppColors.pastelGreen),
      TeacherActivityType.flashcardsDownloaded => (Icons.style_rounded, AppColors.primary, AppColors.pastelGreen),
      TeacherActivityType.activityDownloaded => (Icons.sports_esports_outlined, AppColors.primary, AppColors.pastelGreen),
      TeacherActivityType.flashcardSetUsed => (Icons.style_outlined, AppColors.accentLavender, AppColors.pastelLavender),
      TeacherActivityType.translationSession => (Icons.translate_rounded, AppColors.primary, AppColors.pastelGreen),
    };
    final subtitle = activity.subtitle.isEmpty
        ? _formatActivityDate(activity.createdAt)
        : '${activity.subtitle} • ${_formatActivityDate(activity.createdAt)}';
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: CustomCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(activity.title, style: AppTypography.cardTitle.copyWith(fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppTypography.caption),
                ],
              ),
            ),
            Icon(
              activity.isSynced ? Icons.check_circle_rounded : Icons.cloud_upload_outlined,
              size: 18,
              color: activity.isSynced ? AppColors.statusAchieved : AppColors.accentOrange,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFocusBar(String title, int count, int maxCount, Color color) {
    final fraction = maxCount <= 0 ? 0.0 : (count / maxCount).clamp(0.0, 1.0).toDouble();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                title,
                style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text('$count', style: AppTypography.caption.copyWith(fontWeight: FontWeight.w700, color: color)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: AppRadius.radiusPill,
          child: LinearProgressIndicator(
            value: fraction,
            minHeight: 8,
            backgroundColor: AppColors.cardBorder,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildUsageTile({
    required IconData icon,
    required String count,
    required String label,
  }) {
    return CustomCard(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(height: 8),
          Text(count, style: AppTypography.screenTitle.copyWith(fontSize: 20)),
          Text(label, style: AppTypography.chipLabel.copyWith(fontSize: 10)),
        ],
      ),
    );
  }
}

// SCREEN 51: Student Learning Profile
class StudentLearningProfileScreen extends StatelessWidget {
  final String studentId;

  const StudentLearningProfileScreen({super.key, required this.studentId});

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
          title: '${student.name}\'s Profile',
          subtitle: 'Class ${student.grade} • Mother Tongue: ${student.motherTongue.displayName}',
          breadcrumb: 'Progress > ${student.name}',
          isScrollable: true,
          bottomActionBar: PrimaryButton(
            label: 'Run Remedial Activity for ${student.name}',
            icon: Icons.healing_rounded,
            onPressed: () => context.push(AppRoutes.remediation),
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Subject Mastery Bars (Screen 52 entry)
              CustomCard(
                onTap: () => context.push('/progress/student/${student.id}/subject'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Foundational Subject Mastery',
                            style: AppTypography.cardTitle.copyWith(fontSize: 15),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textMuted),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _buildProgressBar('Foundational Literacy (साक्षरता)', student.literacyProgress, AppColors.primary),
                    const SizedBox(height: 12),
                    _buildProgressBar('Foundational Numeracy (संख्या ज्ञान)', student.numeracyProgress, AppColors.accentBlue),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Active Gaps & Remediation Card (Screen 54 entry)
              CustomCard(
                onTap: () => context.push('/progress/student/${student.id}/gaps'),
                color: student.needsSupportOutcomes > 0 ? AppColors.statusNeedsSupportBg : AppColors.greenSurface,
                border: BorderSide(color: student.needsSupportOutcomes > 0 ? AppColors.statusNeedsSupport : AppColors.greenBorder),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          student.needsSupportOutcomes > 0 ? Icons.warning_amber_rounded : Icons.check_circle_rounded,
                          color: student.needsSupportOutcomes > 0 ? AppColors.statusNeedsSupport : AppColors.statusAchieved,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            student.needsSupportOutcomes > 0 ? 'Active Learning Gap (Tap for History)' : 'All Assessed Outcomes on Track',
                            style: AppTypography.cardTitle.copyWith(
                              fontSize: 14,
                              color: student.needsSupportOutcomes > 0 ? AppColors.statusNeedsSupport : AppColors.statusAchieved,
                            ),
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textMuted),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      student.needsSupportOutcomes > 0
                          ? (student.identifiedGaps.isNotEmpty
                              ? student.identifiedGaps.join('; ')
                              : student.recentEvidence)
                          : (student.assessmentHistory.isEmpty
                              ? 'No assessment records on this device yet.'
                              : 'Student is demonstrating consistent mastery across Class 2 foundational standards.'),
                      style: AppTypography.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Formative Assessment History (Screen 53 entry)
              SectionHeader(
                title: 'Assessment History & Evidence',
                titleHindi: 'मूल्यांकन प्रमाण',
                actionLabel: 'View All',
                onAction: () => context.push('/progress/student/${student.id}/assessments'),
              ),
              const SizedBox(height: 8),
              CustomCard(
                onTap: () => context.push('/progress/student/${student.id}/assessments'),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(color: AppColors.greenSurface, shape: BoxShape.circle),
                      child: const Icon(Icons.history_edu_rounded, color: AppColors.primary, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Outcome Evaluation Timeline', style: AppTypography.cardTitle.copyWith(fontSize: 14)),
                          const SizedBox(height: 2),
                          Text('Review recorded scores, questions and oral responses.', style: AppTypography.caption),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textMuted),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Recommended Next Lesson Box (Screen 55 entry)
              SectionHeader(
                title: 'Recommended Next Pedagogical Steps',
                titleHindi: 'अगले अनुशंसित पाठ',
                actionLabel: 'All Suggestions',
                onAction: () => context.push('/progress/student/${student.id}/recommendations'),
              ),
              const SizedBox(height: 8),
              CustomCard(
                onTap: () => context.push('/progress/student/${student.id}/recommendations'),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(color: AppColors.greenSurface, shape: BoxShape.circle),
                      child: const Icon(Icons.school_rounded, color: AppColors.primary, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Counting Quantities up to 50', style: AppTypography.cardTitle.copyWith(fontSize: 14)),
                          const SizedBox(height: 2),
                          Text('Reason: Learner is still developing quantity recognition above 50.', style: AppTypography.caption),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textMuted),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProgressBar(String title, double value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                title,
                style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text('${(value * 100).toInt()}%', style: AppTypography.caption.copyWith(fontWeight: FontWeight.w700, color: color)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: AppRadius.radiusPill,
          child: LinearProgressIndicator(
            value: value,
            minHeight: 8,
            backgroundColor: AppColors.cardBorder,
            color: color,
          ),
        ),
      ],
    );
  }
}
