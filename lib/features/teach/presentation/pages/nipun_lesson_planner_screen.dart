import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/enums/app_enums.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/chips.dart';
import '../../../../core/widgets/custom_card.dart';
import '../bloc/lesson_delivery_bloc.dart';

class NipunLessonPlannerScreen extends StatefulWidget {
  const NipunLessonPlannerScreen({super.key});

  @override
  State<NipunLessonPlannerScreen> createState() => _NipunLessonPlannerScreenState();
}

class _NipunLessonPlannerScreenState extends State<NipunLessonPlannerScreen> {
  @override
  void initState() {
    super.initState();
    context.read<LessonPlannerBloc>().add(const LoadLessonPlan('M2.1.4'));
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LessonPlannerBloc, LessonPlannerState>(
      builder: (context, state) {
        if (state is LessonPlannerLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
          );
        }

        if (state is LessonPlannerLoaded) {
          final plan = state.plan;
          return AppScaffold(
            title: 'NIPUN Lesson Planner',
            subtitle: 'Actionable lesson plan with ready-to-teach bilingual pedagogical moves.',
            breadcrumb: 'Teach > Planner > ${plan.outcomeCode}',
            isScrollable: true,
            bottomActionBar: Row(
              children: [
                Expanded(
                  child: SecondaryButton(
                    label: 'Lesson Script',
                    icon: Icons.description_outlined,
                    onPressed: () => context.push('/teach/lesson/${plan.id}'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: PrimaryButton(
                    label: 'Start Delivery',
                    icon: Icons.play_arrow_rounded,
                    onPressed: () {
                      context.read<LessonDeliveryBloc>().add(StartLessonDelivery(plan));
                      context.push('/teach/lesson/${plan.id}/delivery');
                    },
                  ),
                ),
              ],
            ),
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Outcome Header Card
                CustomCard(
                  color: AppColors.greenSurface,
                  border: const BorderSide(color: AppColors.greenBorder),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'NIPUN OUTCOME: ${plan.outcomeCode}',
                              style: AppTypography.caption.copyWith(fontWeight: FontWeight.w700, color: AppColors.primary),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.access_time_rounded, size: 14, color: AppColors.textSecondary),
                              const SizedBox(width: 4),
                              Text('${plan.durationMinutes} mins', style: AppTypography.caption),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(plan.title, style: AppTypography.cardTitle),
                      Text(plan.titleHi, style: AppTypography.devanagariBody.copyWith(color: AppColors.primary)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Language Selector
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    Text('Active Language:', style: AppTypography.bodySmall),
                    LanguageChip(
                      language: TribalLanguage.mundari,
                      isSelected: state.selectedLanguage == TribalLanguage.mundari,
                      onTap: () => context.read<LessonPlannerBloc>().add(const ChangeTribalLanguage(TribalLanguage.mundari)),
                    ),
                    LanguageChip(
                      language: TribalLanguage.ho,
                      isSelected: state.selectedLanguage == TribalLanguage.ho,
                      onTap: () => context.read<LessonPlannerBloc>().add(const ChangeTribalLanguage(TribalLanguage.ho)),
                    ),
                    LanguageChip(
                      language: TribalLanguage.santali,
                      isSelected: state.selectedLanguage == TribalLanguage.santali,
                      onTap: () => context.read<LessonPlannerBloc>().add(const ChangeTribalLanguage(TribalLanguage.santali)),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Learning Objective
                _buildSectionCard(
                  icon: Icons.flag_outlined,
                  title: 'Learning Objective (अधिगम उद्देश्य)',
                  content: plan.learningObjective,
                ),
                const SizedBox(height: 12),

                // Prerequisite Knowledge
                _buildSectionCard(
                  icon: Icons.history_edu_outlined,
                  title: 'Prerequisite Knowledge (पूर्व ज्ञान)',
                  content: plan.prerequisiteKnowledge,
                ),
                const SizedBox(height: 12),

                // Teacher Pedagogical Moves
                _buildSectionCard(
                  icon: Icons.psychology_outlined,
                  title: 'Teacher Pedagogical Moves (शिक्षक की भूमिका)',
                  content: plan.teacherMoves,
                ),
                const SizedBox(height: 12),

                // Activity & Manipulatives
                _buildSectionCard(
                  icon: Icons.extension_outlined,
                  title: 'Classroom Activity & Local Manipulatives',
                  content: plan.activityOverview,
                ),
                const SizedBox(height: 12),

                // Formative Assessment Strategy
                _buildSectionCard(
                  icon: Icons.checklist_rounded,
                  title: 'Assessment Strategy (जांच विधि)',
                  content: plan.assessmentStrategy,
                ),
                const SizedBox(height: 12),

                // Remediation Option
                _buildSectionCard(
                  icon: Icons.healing_outlined,
                  title: 'Remediation Option (उपचारात्मक योजना)',
                  content: plan.remediationOption,
                ),
                const SizedBox(height: 20),

                // Key Tribal Vocabulary Table
                Text('Multilingual Key Vocabulary (शब्दावली)', style: AppTypography.sectionTitle),
                const SizedBox(height: 8),
                CustomCard(
                  child: Column(
                    children: plan.tribalVocabulary.entries.map((e) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 100,
                              child: Text(e.key, style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600)),
                            ),
                            Expanded(
                              child: Text(e.value, style: AppTypography.caption.copyWith(color: AppColors.primary)),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          );
        }

        return const Scaffold(body: SizedBox.shrink());
      },
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    required String content,
  }) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(title, style: AppTypography.cardTitle.copyWith(fontSize: 14), overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(content, style: AppTypography.bodyMedium),
        ],
      ),
    );
  }
}
