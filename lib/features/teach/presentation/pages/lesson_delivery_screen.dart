import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/audio_play_button.dart';
import '../../../../core/widgets/custom_card.dart';
import '../bloc/lesson_delivery_bloc.dart';

class LessonDeliveryScreen extends StatelessWidget {
  final String lessonId;

  const LessonDeliveryScreen({super.key, this.lessonId = 'lp_m2_1_4'});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LessonDeliveryBloc, LessonDeliveryState>(
      builder: (context, state) {
        if (state is! LessonDeliveryActive) {
          return AppScaffold(
            title: 'Lesson Delivery Mode',
            subtitle: 'Pedagogical delivery flow: Explain ➔ Demonstrate ➔ Ask ➔ Activity ➔ Practice ➔ Check',
            breadcrumb: 'Delivery Mode',
            body: Center(
              child: PrimaryButton(
                label: 'Initialize Delivery Mode',
                onPressed: () => context.pop(),
              ),
            ),
          );
        }

        final step = state.currentStep;
        final isLast = state.currentStageIndex == state.plan.steps.length - 1;

        return AppScaffold(
          title: 'Lesson Delivery: Step ${step.stepNumber}/6',
          subtitle: '${step.title} (${step.titleHi})',
          breadcrumb: 'Delivery > Step ${step.stepNumber}: ${step.stage.title}',
          isScrollable: true,
          bottomActionBar: Row(
            children: [
              if (state.currentStageIndex > 0) ...[
                SecondaryButton(
                  label: 'Previous',
                  onPressed: () => context.read<LessonDeliveryBloc>().add(PrevDeliveryStage()),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: PrimaryButton(
                  label: isLast ? 'Start Assessment Check' : 'Next Stage (${step.stepNumber + 1}/6)',
                  trailingIcon: isLast ? Icons.check_circle_outline_rounded : Icons.arrow_forward_rounded,
                  onPressed: () {
                    if (isLast) {
                      context.push(AppRoutes.assessmentPlay);
                    } else {
                      context.read<LessonDeliveryBloc>().add(NextDeliveryStage());
                    }
                  },
                ),
              ),
            ],
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 6-Stage Progress Indicator
              _buildStageStepper(context, state),
              const SizedBox(height: 16),

              // Teacher Script Card (Hindi)
              CustomCard(
                color: Colors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.record_voice_over_rounded, size: 18, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Text('Teacher Script (हिंदी)', style: AppTypography.cardTitle.copyWith(fontSize: 14)),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: AppColors.greenLight, borderRadius: AppRadius.radiusPill),
                          child: Text('Step ${step.stepNumber}: ${step.stage.title}', style: AppTypography.caption.copyWith(color: AppColors.primary)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      step.scriptHindi,
                      style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w500, height: 1.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Multilingual Vernacular Prompt (Tribal Audio & Text)
              CustomCard(
                color: AppColors.greenSurface,
                border: const BorderSide(color: AppColors.greenBorder),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.translate_rounded, size: 18, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Text('Tribal Mother-Tongue Cue', style: AppTypography.cardTitle.copyWith(fontSize: 14, color: AppColors.primaryDark)),
                          ],
                        ),
                        const AudioPlayButton(label: 'Pronounce'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      step.scriptTribal,
                      style: AppTypography.tribalVernacular.copyWith(fontSize: 15),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Teacher Tip & Pedagogy Note
              CustomCard(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.lightbulb_outline_rounded, color: AppColors.accentAmber, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Pedagogical Tip', style: AppTypography.cardTitle.copyWith(fontSize: 13)),
                          const SizedBox(height: 2),
                          Text(step.teacherTip, style: AppTypography.bodySmall),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Local Jharkhand Context Prompt
              CustomCard(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.nature_people_outlined, color: AppColors.primary, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Verified Local Context', style: AppTypography.cardTitle.copyWith(fontSize: 13)),
                          const SizedBox(height: 2),
                          Text(step.localContextPrompt, style: AppTypography.bodySmall),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Quick Assistance Shortcuts (Copilot & Translator)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                      label: const Text('Ask Copilot'),
                      onPressed: () => context.push(AppRoutes.teacherCopilot),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.mic_rounded, size: 18),
                      label: const Text('Live Translator'),
                      onPressed: () => context.push(AppRoutes.translate),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStageStepper(BuildContext context, LessonDeliveryActive state) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: state.plan.steps.map((s) {
          final isCurrent = s.stepNumber - 1 == state.currentStageIndex;
          final isDone = s.stepNumber - 1 < state.currentStageIndex;

          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: InkWell(
              onTap: () {
                context.read<LessonDeliveryBloc>().add(JumpToDeliveryStage(s.stepNumber - 1));
              },
              borderRadius: AppRadius.radiusPill,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isCurrent
                      ? AppColors.primary
                      : (isDone ? AppColors.greenLight : Colors.white),
                  borderRadius: AppRadius.radiusPill,
                  border: Border.all(
                    color: isCurrent ? AppColors.primary : AppColors.cardBorder,
                  ),
                ),
                child: Row(
                  children: [
                    if (isDone)
                      const Icon(Icons.check_rounded, size: 14, color: AppColors.primary)
                    else
                      Text(
                        '${s.stepNumber}.',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isCurrent ? Colors.white : AppColors.textSecondary,
                        ),
                      ),
                    const SizedBox(width: 4),
                    Text(
                      s.stage.title,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                        color: isCurrent
                            ? Colors.white
                            : (isDone ? AppColors.primary : AppColors.textPrimary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class LessonDetailScreen extends StatelessWidget {
  final String lessonId;

  const LessonDetailScreen({super.key, this.lessonId = 'lp_m2_1_4'});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Lesson Script Detail',
      subtitle: 'Complete teacher script, vocabulary, and local materials required for Class 2.',
      breadcrumb: 'Teach > Lesson Detail',
      isScrollable: true,
      bottomActionBar: PrimaryButton(
        label: 'Start Lesson Delivery Mode',
        icon: Icons.play_arrow_rounded,
        onPressed: () => context.push('/teach/lesson/$lessonId/delivery'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Numbers up to 100: Place Value & Bundles', style: AppTypography.cardTitle),
                const SizedBox(height: 2),
                Text('संख्याएँ 1 से 100: दहाई-इकाई बंडल और गिनती', style: AppTypography.caption.copyWith(color: AppColors.primary)),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                Text('Required Classroom Materials:', style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                const Text('• 100 Mahua or tamarind seeds in leaf plates\n• Bamboo twigs tied with string in 10-packs\n• Student slates and chalk\n• Bilingual Number Flashcards'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
