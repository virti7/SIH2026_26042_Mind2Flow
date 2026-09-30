import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/enums/app_enums.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/audio_play_button.dart';
import '../../../../core/widgets/badges.dart';
import '../../../../core/widgets/chips.dart';
import '../../../../core/widgets/custom_card.dart';
import '../../../../core/widgets/section_header.dart';
import '../bloc/assessment_bloc.dart';

// SCREEN 34: Assessment Builder — teacher creates a classroom assessment.
class AssessmentBuilderScreen extends StatefulWidget {
  const AssessmentBuilderScreen({super.key});

  @override
  State<AssessmentBuilderScreen> createState() => _AssessmentBuilderScreenState();
}

class _AssessmentBuilderScreenState extends State<AssessmentBuilderScreen> {
  int _grade = 2;
  String _subject = 'Mathematics';
  String _topic = 'Numbers up to 100';
  String _outcome = 'M2.1.4';
  String _assessmentType = 'Oral + observation';
  final Set<QuestionType> _qTypes = {QuestionType.oral, QuestionType.physical};
  int _count = 3;
  DifficultyLevel _difficulty = DifficultyLevel.medium;
  TribalLanguage _language = TribalLanguage.mundari;
  bool _visual = true;
  bool _oral = true;
  bool _worksheetStyle = false;

  static const _domains = [
    'Oral language',
    'Decoding',
    'Reading/comprehension',
    'Writing',
    'Number sense',
    'Operations',
    'Shapes',
    'Measurement',
  ];
  final Set<String> _domainsSel = {'Number sense'};

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Assessment Builder',
      subtitle: 'Build a short teacher-led classroom check. No student devices needed.',
      breadcrumb: 'Assessment > Builder',
      isScrollable: true,
      bottomActionBar: Row(
        children: [
          Expanded(
            child: SecondaryButton(
              label: 'Preview',
              icon: Icons.visibility_outlined,
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(
                          'Preview: $_count questions • ${_qTypes.map((e) => e.label).join(', ')} • ${_language.displayName}')),
                );
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: PrimaryButton(
              label: 'Start Assessment',
              trailingIcon: Icons.play_arrow_rounded,
              onPressed: () {
                context
                    .read<AssessmentBloc>()
                    .add(const StartAssessmentEvent());
                context.push(AppRoutes.assessmentPlay);
              },
            ),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('1. Class & Subject', style: AppTypography.cardTitle.copyWith(fontSize: 14)),
                const SizedBox(height: 8),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final g in [1, 2, 3])
                    ChoiceChip(
                      label: Text('Class $g'),
                      selected: _grade == g,
                      selectedColor: AppColors.primary,
                      backgroundColor: Colors.white,
                      labelStyle: TextStyle(
                          color: _grade == g ? Colors.white : AppColors.textPrimary,
                          fontSize: 12),
                      onSelected: (v) {
                        if (v) setState(() => _grade = g);
                      },
                    ),
                  for (final s in ['Mathematics', 'Language'])
                    ChoiceChip(
                      label: Text(s),
                      selected: _subject == s,
                      selectedColor: AppColors.primary,
                      backgroundColor: Colors.white,
                      labelStyle: TextStyle(
                          color: _subject == s ? Colors.white : AppColors.textPrimary,
                          fontSize: 12),
                      onSelected: (v) {
                        if (v) setState(() => _subject = s);
                      },
                    ),
                ]),
              ],
            ),
          ),
          const SizedBox(height: 12),
          CustomCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('2. Topic & NIPUN outcome', style: AppTypography.cardTitle.copyWith(fontSize: 14)),
                const SizedBox(height: 8),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final t in ['Numbers up to 100', 'Counting to 50', 'Shapes around us', 'Story retelling'])
                    ChoiceChip(
                      label: Text(t, style: const TextStyle(fontSize: 12)),
                      selected: _topic == t,
                      selectedColor: AppColors.primary,
                      backgroundColor: Colors.white,
                      labelStyle: TextStyle(
                          color: _topic == t ? Colors.white : AppColors.textPrimary),
                      onSelected: (v) {
                        if (v) setState(() => _topic = t);
                      },
                    ),
                ]),
                const SizedBox(height: 8),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final o in ['M2.1.4', 'M2.1.2', 'L2.1.3', 'L2.2.1'])
                    ChoiceChip(
                      label: Text(o, style: const TextStyle(fontSize: 12)),
                      selected: _outcome == o,
                      selectedColor: AppColors.accentBlue,
                      backgroundColor: Colors.white,
                      labelStyle: TextStyle(
                          color: _outcome == o ? Colors.white : AppColors.textPrimary),
                      onSelected: (v) {
                        if (v) setState(() => _outcome = o);
                      },
                    ),
                ]),
              ],
            ),
          ),
          const SizedBox(height: 12),
          CustomCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('3. Assessment type', style: AppTypography.cardTitle.copyWith(fontSize: 14)),
                const SizedBox(height: 8),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final t in ['Oral + observation', 'Show image, child responds', 'Worksheet-style'])
                    ChoiceChip(
                      label: Text(t, style: const TextStyle(fontSize: 12)),
                      selected: _assessmentType == t,
                      selectedColor: AppColors.primary,
                      backgroundColor: Colors.white,
                      labelStyle: TextStyle(
                          color: _assessmentType == t ? Colors.white : AppColors.textPrimary),
                      onSelected: (v) {
                        if (v) setState(() => _assessmentType = t);
                      },
                    ),
                ]),
                const SizedBox(height: 12),
                Text('Question types (tap to toggle)', style: AppTypography.caption.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: QuestionType.values.map((q) {
                    final sel = _qTypes.contains(q);
                    return FilterChip(
                      label: Text(q.label, style: const TextStyle(fontSize: 12)),
                      selected: sel,
                      selectedColor: AppColors.primary,
                      backgroundColor: Colors.white,
                      labelStyle: TextStyle(
                          color: sel ? Colors.white : AppColors.textPrimary),
                      onSelected: (v) => setState(() {
                        if (v) {
                          _qTypes.add(q);
                        } else if (_qTypes.length > 1) {
                          _qTypes.remove(q);
                        }
                      }),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          CustomCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('4. Questions, difficulty & language',
                    style: AppTypography.cardTitle.copyWith(fontSize: 14)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                        child: Text('Number of questions',
                            style: AppTypography.bodySmall)),
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline_rounded),
                      onPressed: _count > 1
                          ? () => setState(() => _count--)
                          : null,
                    ),
                    Text('$_count',
                        style: AppTypography.cardTitle.copyWith(fontSize: 18)),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline_rounded),
                      onPressed: _count < 10
                          ? () => setState(() => _count++)
                          : null,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: DifficultyLevel.values.map((d) {
                    final sel = _difficulty == d;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ChoiceChip(
                          label: Center(
                              child: Text(d.label,
                                  style: const TextStyle(fontSize: 12))),
                          selected: sel,
                          selectedColor: AppColors.primary,
                          backgroundColor: Colors.white,
                          labelStyle: TextStyle(
                              color: sel
                                  ? Colors.white
                                  : AppColors.textPrimary),
                          onSelected: (v) {
                            if (v) setState(() => _difficulty = d);
                          },
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 10),
                Wrap(spacing: 8, children: [
                  LanguageChip(
                      language: TribalLanguage.mundari,
                      isSelected: _language == TribalLanguage.mundari,
                      onTap: () => setState(
                          () => _language = TribalLanguage.mundari)),
                  LanguageChip(
                      language: TribalLanguage.ho,
                      isSelected: _language == TribalLanguage.ho,
                      onTap: () =>
                          setState(() => _language = TribalLanguage.ho)),
                  LanguageChip(
                      language: TribalLanguage.santali,
                      isSelected: _language == TribalLanguage.santali,
                      onTap: () => setState(
                          () => _language = TribalLanguage.santali)),
                ]),
              ],
            ),
          ),
          const SizedBox(height: 12),
          CustomCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('5. Supports & domains', style: AppTypography.cardTitle.copyWith(fontSize: 14)),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Visual questions (show image on tablet)',
                      style: AppTypography.bodySmall),
                  value: _visual,
                  activeThumbColor: AppColors.primary,
                  onChanged: (v) => setState(() => _visual = v),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Oral questions (tablet plays audio)',
                      style: AppTypography.bodySmall),
                  value: _oral,
                  activeThumbColor: AppColors.primary,
                  onChanged: (v) => setState(() => _oral = v),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Worksheet-style questions',
                      style: AppTypography.bodySmall),
                  value: _worksheetStyle,
                  activeThumbColor: AppColors.primary,
                  onChanged: (v) => setState(() => _worksheetStyle = v),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _domains.map((d) {
                    final sel = _domainsSel.contains(d);
                    return FilterChip(
                      label: Text(d, style: const TextStyle(fontSize: 12)),
                      selected: sel,
                      selectedColor: AppColors.greenLight,
                      backgroundColor: Colors.white,
                      labelStyle: const TextStyle(
                          color: AppColors.primary, fontSize: 12),
                      onSelected: (v) => setState(() {
                        if (v) {
                          _domainsSel.add(d);
                        } else {
                          _domainsSel.remove(d);
                        }
                      }),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          CustomCard(
            color: AppColors.greenSurface,
            border: const BorderSide(color: AppColors.greenBorder),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Summary — tap Edit to change anything',
                    style: AppTypography.caption.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text(
                    'Class $_grade • $_subject • $_topic • $_outcome\n$_assessmentType • $_count questions • ${_difficulty.label} • ${_language.displayName}\nDomains: ${_domainsSel.join(', ')}',
                    style: AppTypography.bodySmall),
                const SizedBox(height: 8),
                const Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    OfflineBadge(),
                    NipunBadge(),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// SCREEN 35: Assessment Play — teacher conducts assessment on one tablet.
class AssessmentPlayScreen extends StatefulWidget {
  const AssessmentPlayScreen({super.key});

  @override
  State<AssessmentPlayScreen> createState() => _AssessmentPlayScreenState();
}

class _AssessmentPlayScreenState extends State<AssessmentPlayScreen> {
  @override
  void initState() {
    super.initState();
    context.read<AssessmentBloc>().add(const StartAssessmentEvent());
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AssessmentBloc, AssessmentState>(
      listener: (context, state) {
        if (state is AssessmentResultState) {
          context.push(AppRoutes.assessmentResult);
        }
      },
      builder: (context, state) {
        if (state is AssessmentLoading) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppColors.primary),
                  SizedBox(height: 12),
                  Text('Preparing classroom assessment...'),
                ],
              ),
            ),
          );
        }

        if (state is AssessmentActiveState) {
          final q = state.currentQuestion;
          final total = state.questions.length;
          final currentIdx = state.currentQuestionIndex;
          final selectedAns = state.selectedAnswers[currentIdx];

          return AppScaffold(
            title: 'Classroom Assessment',
            subtitle: 'Question ${currentIdx + 1} of $total • One teacher tablet • Children respond orally',
            breadcrumb: 'Assessment > Question ${currentIdx + 1}',
            isScrollable: true,
            bottomActionBar: Row(
              children: [
                Expanded(
                  child: PrimaryButton(
                    label: currentIdx < total - 1 ? 'Record & Next' : 'Finish & See Result',
                    trailingIcon: Icons.arrow_forward_rounded,
                    onPressed: selectedAns != -1
                        ? () {
                            context.read<AssessmentBloc>().add(NextAssessmentQuestionEvent());
                          }
                        : null,
                  ),
                ),
              ],
            ),
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: AppColors.greenLight, borderRadius: AppRadius.radiusPill),
                      child: Text('Outcome ${state.outcomeCode} • Class observation',
                          style: AppTypography.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: AppColors.accentBlueLight, borderRadius: AppRadius.radiusPill),
                      child: Text(q.type.label, style: AppTypography.caption.copyWith(color: AppColors.accentBlue, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: AppRadius.radiusPill,
                  child: LinearProgressIndicator(
                    value: (currentIdx + 1) / total,
                    minHeight: 6,
                    backgroundColor: AppColors.cardBorder,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 16),
                // How to conduct this question
                CustomCard(
                  color: AppColors.greenSurface,
                  border: const BorderSide(color: AppColors.greenBorder),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('HOW TO ASK (teacher only)',
                          style: AppTypography.caption.copyWith(
                              color: AppColors.primary, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      Text('1. Say the prompt aloud  •  2. Show the image / play audio  •  3. Child answers orally  •  4. Mark what you observed below.',
                          style: AppTypography.bodySmall),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                CustomCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Prompt for class (Hindi):', style: AppTypography.caption),
                      const SizedBox(height: 4),
                      Text(q.promptHindi, style: AppTypography.cardTitle.copyWith(fontSize: 16)),
                      const SizedBox(height: 10),
                      Text('Mother-tongue cue:', style: AppTypography.caption),
                      const SizedBox(height: 2),
                      Text(q.promptTribal, style: AppTypography.tribalVernacular.copyWith(fontSize: 14)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const AudioPlayButton(label: 'Play prompt'),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                  color: AppColors.surfaceSubtle,
                                  borderRadius: AppRadius.radiusMd,
                                  border: Border.all(color: AppColors.cardBorder)),
                              child: Text('🖼️ Image shown on tablet for this question',
                                  style: AppTypography.caption),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                CustomCard(
                  color: AppColors.greenSurface,
                  border: const BorderSide(color: AppColors.greenBorder),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.visibility_outlined, color: AppColors.primary, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'What to watch for: ${q.teacherObservationRubric}',
                          style: AppTypography.caption.copyWith(color: AppColors.primaryDark),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Text('Mark observed response:', style: AppTypography.sectionTitle),
                const SizedBox(height: 4),
                Text('Tap the option that matches what the child did or said.',
                    style: AppTypography.caption),
                const SizedBox(height: 10),
                ...q.choices.asMap().entries.map((entry) {
                  final optIdx = entry.key;
                  final optText = entry.value;
                  final isChosen = selectedAns == optIdx;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: InkWell(
                      onTap: () {
                        context.read<AssessmentBloc>().add(SelectAssessmentAnswerEvent(currentIdx, optIdx));
                      },
                      borderRadius: AppRadius.radiusLg,
                      child: CustomCard(
                        color: isChosen ? AppColors.greenSurface : Colors.white,
                        border: BorderSide(
                          color: isChosen ? AppColors.primary : AppColors.cardBorder,
                          width: isChosen ? 1.8 : 1,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        child: Row(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isChosen ? AppColors.primary : Colors.white,
                                border: Border.all(color: isChosen ? AppColors.primary : AppColors.border),
                              ),
                              child: isChosen
                                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                optText,
                                style: AppTypography.bodyMedium.copyWith(
                                  fontWeight: isChosen ? FontWeight.w600 : FontWeight.w400,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 8),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [OfflineBadge()],
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        }

        return const Scaffold(body: SizedBox.shrink());
      },
    );
  }
}

// SCREEN 36: Assessment Result — immediate session result, not stored.
class AssessmentResultScreen extends StatelessWidget {
  const AssessmentResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AssessmentBloc, AssessmentState>(
      builder: (context, state) {
        if (state is! AssessmentResultState) {
          return Scaffold(
            body: Center(
              child: PrimaryButton(
                label: 'Take Assessment',
                onPressed: () => context.push(AppRoutes.assessmentPlay),
              ),
            ),
          );
        }

        final res = state.result;
        final needsSupport = res.totalQuestions - res.correctCount;

        return AppScaffold(
          title: 'Assessment Result',
          subtitle: 'This-session classroom snapshot only — nothing is saved to a student profile.',
          breadcrumb: 'Assessment > Result',
          isScrollable: true,
          bottomActionBar: Row(
            children: [
              Expanded(
                child: SecondaryButton(
                  label: 'Gap Analysis',
                  onPressed: () => context.push(AppRoutes.learningGap),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: PrimaryButton(
                  label: 'Next: Remediation',
                  trailingIcon: Icons.healing_rounded,
                  onPressed: () {
                    context.read<AssessmentBloc>().add(OpenRemedialActivityEvent());
                    context.push(AppRoutes.remediation);
                  },
                ),
              ),
            ],
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Text('✅ Assessment completed',
                        style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary)),
                    const SizedBox(height: 10),
                    StatusChip(status: res.status),
                    const SizedBox(height: 12),
                    Text(
                      'Score: ${res.correctCount} / ${res.totalQuestions}',
                      style: AppTypography.screenTitle.copyWith(fontSize: 28),
                    ),
                    const SizedBox(height: 4),
                    Text('Attempted: ${res.totalQuestions} • Correct: ${res.correctCount} • Needs support: $needsSupport',
                        style: AppTypography.caption, textAlign: TextAlign.center),
                    const SizedBox(height: 8),
                    Text('Outcome: ${res.outcomeCode} — ${res.outcomeTitle}',
                        style: AppTypography.caption, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 8),
                    Text('Skill / outcome mapping:',
                        style: AppTypography.caption.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(res.unfinishedSkill,
                        style: AppTypography.bodySmall, textAlign: TextAlign.center),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SectionHeader(title: 'Immediate observations', titleHindi: 'तुरंत अवलोकन'),
              const SizedBox(height: 8),
              CustomCard(
                child: Text(
                    '• Children recognised small quantities quickly but hesitated above 50.\n• Tens/units grouping slipped when counting aloud in the mother tongue.\n• One more guided round with concrete objects should close the gap.',
                    style: AppTypography.bodySmall),
              ),
              const SizedBox(height: 16),
              SectionHeader(title: 'Areas needing reinforcement', titleHindi: 'पुनर्बलन क्षेत्र'),
              const SizedBox(height: 8),
              CustomCard(
                color: AppColors.accentOrangeLight,
                border: const BorderSide(color: AppColors.accentOrange),
                child: Text(
                    'Connecting quantity → numeral for 51–100. Re-teach tens-bundles before moving to the next outcome.',
                    style: AppTypography.bodySmall),
              ),
              const SizedBox(height: 16),
              CustomCard(
                color: AppColors.greenSurface,
                border: const BorderSide(color: AppColors.greenBorder),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.auto_awesome_rounded, color: AppColors.primary, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                            child: Text('Suggested next classroom action',
                                style: AppTypography.cardTitle.copyWith(fontSize: 14))),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(res.recommendedRemediation, style: AppTypography.bodyMedium),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
}

// SCREEN 37: Learning Gap Analysis — what needs re-teaching, in plain words.
class LearningGapAnalysisScreen extends StatelessWidget {
  const LearningGapAnalysisScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Learning Gap Analysis',
      subtitle: 'Plain-language diagnosis for this session — which concept needs re-teaching.',
      breadcrumb: 'Assessment > Gap Analysis',
      isScrollable: true,
      bottomActionBar: PrimaryButton(
        label: 'Open Recommended Activity',
        trailingIcon: Icons.healing_rounded,
        onPressed: () {
          context.read<AssessmentBloc>().add(OpenRemedialActivityEvent());
          context.push(AppRoutes.remediation);
        },
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Learning outcome', style: AppTypography.caption.copyWith(fontWeight: FontWeight.w700)),
                Text('M2.1.4: Numbers up to 100', style: AppTypography.cardTitle),
                const SizedBox(height: 12),
                Text('Skill checked', style: AppTypography.caption.copyWith(fontWeight: FontWeight.w700)),
                Text('Reading 2-digit numerals and matching them to object groups.',
                    style: AppTypography.bodySmall),
                const SizedBox(height: 12),
                Text('Observed difficulty', style: AppTypography.caption.copyWith(fontWeight: FontWeight.w700)),
                Text('“Recognises quantities but needs support connecting quantity to numeral.” Children counted loose seeds correctly yet pointed to the wrong numeral for 52 and 64.',
                    style: AppTypography.bodySmall),
              ],
            ),
          ),
          const SizedBox(height: 12),
          CustomCard(
            color: AppColors.accentAmberLight,
            border: const BorderSide(color: AppColors.accentAmber),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Possible reason', style: AppTypography.caption.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text('Tens-bundles were not visually separated, so “5 tens + 2” looked like “7 loose”. Mother-tongue tens-words (गेल, हिसि) are still new for some children.',
                    style: AppTypography.bodySmall),
              ],
            ),
          ),
          const SizedBox(height: 12),
          CustomCard(
            color: AppColors.greenSurface,
            border: const BorderSide(color: AppColors.greenBorder),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Recommended teaching approach',
                    style: AppTypography.cardTitle.copyWith(fontSize: 14, color: AppColors.primaryDark)),
                const SizedBox(height: 6),
                Text('Re-teach with concrete bundles: tie 10 seeds per leaf, chant tens-words in the mother tongue, then place the numeral card beside each bundle.',
                    style: AppTypography.bodySmall),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SectionHeader(title: 'Supporting material', titleHindi: 'सहायक सामग्री'),
          const SizedBox(height: 8),
          CustomCard(
            onTap: () {
              context.read<AssessmentBloc>().add(OpenRemedialActivityEvent());
              context.push(AppRoutes.remediation);
            },
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(color: AppColors.greenSurface, shape: BoxShape.circle),
                  child: const Icon(Icons.sports_esports_outlined, color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Mahua Seed Grouping (remedial round)',
                          style: AppTypography.cardTitle.copyWith(fontSize: 14)),
                      Text('15 min • Concrete • Hindi + Mundari',
                          style: AppTypography.caption),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textMuted),
              ],
            ),
          ),
          const SizedBox(height: 10),
          CustomCard(
            onTap: () => context.push(AppRoutes.flashcardGenerator),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: AppColors.accentBlue.withValues(alpha: 0.12),
                      borderRadius: AppRadius.radiusMd),
                  child: const Icon(Icons.style_outlined, color: AppColors.accentBlue, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Related visual: tens numeral cards',
                          style: AppTypography.cardTitle.copyWith(fontSize: 14)),
                      Text('Flashcards 30–70 • Offline • Printable',
                          style: AppTypography.caption),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textMuted),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// SCREEN 38: Remedial Activity Recommendation — next activity from live context.
class RemedialActivityScreen extends StatelessWidget {
  const RemedialActivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AssessmentBloc, AssessmentState>(
      builder: (context, state) {
        if (state is! RemediationActiveState) {
          return Scaffold(
            body: Center(
              child: PrimaryButton(
                label: 'Load Remediation',
                onPressed: () {
                  context.read<AssessmentBloc>().add(OpenRemedialActivityEvent());
                },
              ),
            ),
          );
        }

        final act = state.remedialActivity;

        return AppScaffold(
          title: 'Recommended Remedial Activity',
          subtitle: 'Chosen from the live lesson + assessment context. No history stored.',
          breadcrumb: 'Assessment > Remediation',
          isScrollable: true,
          bottomActionBar: PrimaryButton(
            label: 'Start Activity',
            trailingIcon: Icons.play_arrow_rounded,
            onPressed: () {
              context.read<AssessmentBloc>().add(StartReassessmentEvent());
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Remedial activity started on this tablet.')),
              );
            },
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomCard(
                color: AppColors.statusNeedsSupportBg,
                border: const BorderSide(color: AppColors.statusNeedsSupport),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('LEARNING GAP IT FIXES',
                        style: AppTypography.caption.copyWith(
                            color: AppColors.statusNeedsSupport,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(state.previousResult.unfinishedSkill,
                        style: AppTypography.bodySmall),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              CustomCard(
                color: AppColors.greenSurface,
                border: const BorderSide(color: AppColors.greenBorder),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('RECOMMENDED ACTIVITY',
                        style: AppTypography.caption.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(act.title, style: AppTypography.cardTitle),
                    Text(act.titleHi,
                        style: AppTypography.devanagariBody
                            .copyWith(color: AppColors.primary)),
                    const SizedBox(height: 10),
                    Wrap(spacing: 8, runSpacing: 6, children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: AppRadius.radiusPill,
                            border: Border.all(color: AppColors.greenBorder)),
                        child: Text('⏱ ${act.durationMinutes} mins',
                            style: AppTypography.caption.copyWith(fontWeight: FontWeight.w700)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: AppRadius.radiusPill,
                            border: Border.all(color: AppColors.greenBorder)),
                        child: Text(act.language.displayName,
                            style: AppTypography.caption.copyWith(fontWeight: FontWeight.w700)),
                      ),
                      const OfflineBadge(),
                    ]),
                    const SizedBox(height: 10),
                    Text('Why this activity?',
                        style: AppTypography.caption.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(
                        'It re-teaches the exact miss (tens vs units) with cheaper concrete material, in the same mother tongue the check used, and takes under 20 minutes — so you can re-assess in the same period.',
                        style: AppTypography.bodySmall),
                    const SizedBox(height: 8),
                    Text('Materials: ${act.materials}',
                        style: AppTypography.caption),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text('Teacher guidance steps:', style: AppTypography.sectionTitle),
              const SizedBox(height: 8),
              ...act.teacherSteps.asMap().entries.map((e) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${e.key + 1}. ',
                          style: AppTypography.cardTitle.copyWith(fontSize: 14)),
                      Expanded(child: Text(e.value, style: AppTypography.bodySmall)),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: SecondaryButton(
                      label: 'Short Re-Assessment',
                      icon: Icons.replay_rounded,
                      onPressed: () {
                        context.read<AssessmentBloc>().add(StartReassessmentEvent());
                        context.push(AppRoutes.reassessment);
                      },
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
}

// SCREEN 39: Re-Assessment — quick follow-up, then immediate result.
class ReassessmentScreen extends StatelessWidget {
  const ReassessmentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AssessmentBloc, AssessmentState>(
      builder: (context, state) {
        if (state is ReassessmentCompleteState) {
          final mastered = state.newStatus == OutcomeStatus.achieved;
          return AppScaffold(
            title: mastered ? 'Learning Loop Closed!' : 'Keep Teaching This Skill',
            subtitle: mastered
                ? 'Immediate session outcome — not saved to any student profile.'
                : 'No profile updated. Continue with the class and retry later.',
            breadcrumb: 'Assessment > Completed',
            isScrollable: true,
            bottomActionBar: PrimaryButton(
              label: 'Continue Teaching',
              trailingIcon: Icons.arrow_forward_rounded,
              onPressed: () => context.go(AppRoutes.teach),
            ),
            body: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                      color: mastered
                          ? AppColors.greenLight
                          : AppColors.statusDevelopingBg,
                      shape: BoxShape.circle),
                  child: Icon(
                      mastered
                          ? Icons.check_circle_rounded
                          : Icons.timelapse_rounded,
                      color: mastered
                          ? AppColors.statusAchieved
                          : AppColors.statusDeveloping,
                      size: 48),
                ),
                const SizedBox(height: 20),
                Text(
                    mastered ? 'Concept strengthened!' : 'Still developing — normal.',
                    style: AppTypography.screenTitle),
                const SizedBox(height: 6),
                Text('Outcome ${state.outcomeCode} • This session only',
                    style: AppTypography.bodyMedium),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    StatusChip(status: state.previousStatus),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Icon(Icons.arrow_forward_rounded,
                          size: 18, color: AppColors.primary),
                    ),
                    StatusChip(status: state.newStatus),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        }

        if (state is ReassessmentActiveState) {
          return AppScaffold(
            title: 'Short Re-Assessment',
            subtitle:
                '${state.questions.length} quick tasks • Previous skill: ${state.previousResult.outcomeCode} • Session only',
            breadcrumb: 'Assessment > Re-Assessment',
            isScrollable: true,
            bottomActionBar: Row(
              children: [
                Expanded(
                  child: SecondaryButton(
                    label: 'Still Needs Help',
                    onPressed: () {
                      context
                          .read<AssessmentBloc>()
                          .add(const SubmitReassessmentAnswerEvent(false));
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: PrimaryButton(
                    label: 'Mastered',
                    icon: Icons.check_circle_rounded,
                    onPressed: () {
                      context
                          .read<AssessmentBloc>()
                          .add(const SubmitReassessmentAnswerEvent(true));
                    },
                  ),
                ),
              ],
            ),
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomCard(
                  color: AppColors.greenSurface,
                  border: const BorderSide(color: AppColors.greenBorder),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('PREVIOUS SKILL BEING RE-CHECKED',
                          style: AppTypography.caption.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text(state.previousResult.unfinishedSkill,
                          style: AppTypography.bodySmall),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                ...state.questions.asMap().entries.map((e) {
                  final qi = e.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: CustomCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Task ${e.key + 1} • ${qi.type.label}',
                              style: AppTypography.caption.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary)),
                          const SizedBox(height: 6),
                          Text(qi.promptHindi,
                              style: AppTypography.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text(qi.promptTribal,
                              style: AppTypography.tribalVernacular
                                  .copyWith(fontSize: 13)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const AudioPlayButton(compact: true),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                    'Ask orally, show image, mark overall verdict below.',
                                    style: AppTypography.caption),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 8),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [OfflineBadge()],
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        }

        return AppScaffold(
          title: 'Targeted Re-Assessment',
          subtitle: 'Verify understanding after the remedial activity.',
          breadcrumb: 'Assessment > Re-Assessment',
          isScrollable: true,
          bottomActionBar: Row(
            children: [
              Expanded(
                child: SecondaryButton(
                  label: 'Still Needs Help',
                  onPressed: () {
                    context
                        .read<AssessmentBloc>()
                        .add(const SubmitReassessmentAnswerEvent(false));
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: PrimaryButton(
                  label: 'Mastered (Passed)',
                  icon: Icons.check_circle_rounded,
                  onPressed: () {
                    context
                        .read<AssessmentBloc>()
                        .add(const SubmitReassessmentAnswerEvent(true));
                  },
                ),
              ),
            ],
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Re-Check: counts to 50',
                        style: AppTypography.cardTitle),
                    const SizedBox(height: 8),
                    Text(
                      'Ask the class: "5 दहाई और 2 खुली तीलियां देखकर बताएं कि कुल कितनी तीलियां हुईं?"',
                      style: AppTypography.bodyMedium,
                    ),
                    const SizedBox(height: 6),
                    Text('Expected answer: 52 (मोड़े गेल बारिया)',
                        style: AppTypography.tribalVernacular),
                    const SizedBox(height: 8),
                    const Row(
                      children: [
                        AudioPlayButton(compact: true),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                              'Play the prompt, children answer orally, then mark the verdict.',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
