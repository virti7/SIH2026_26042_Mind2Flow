import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/auth/services/current_user_service.dart';
import '../../../../core/copilot/copilot_models.dart' show CopilotAnswerLanguage;
import '../../../../core/copilot/copilot_store.dart';
import '../../../../core/teacher_assist/teacher_question_engine.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/custom_card.dart';
import '../bloc/teacher_copilot_bloc.dart';

/// Teacher Co-Pilot page. Thin UI over the shared [TeacherQuestionEngine]
/// (via [TeacherCopilotBloc]): it only sends question + lesson context +
/// answer-language preference. All answers are predefined offline strings.
class TeacherCopilotScreen extends StatefulWidget {
  const TeacherCopilotScreen({super.key});

  @override
  State<TeacherCopilotScreen> createState() => _TeacherCopilotScreenState();
}

class _TeacherCopilotScreenState extends State<TeacherCopilotScreen> {
  final TextEditingController _queryController = TextEditingController();
  CopilotAnswerLanguage? _language;
  static const String _topicContext =
      'Class 2 Mathematics: Numbers up to 100';

  static const List<({String label, String query})> _quickQuestions = [
    (label: 'Worksheet कैसे बनाएं?', query: 'mujhe worksheet generate karni hai main kidhar jau'),
    (label: 'एक activity बताएं', query: 'ek activity batao'),
    (label: 'Flashcard बनाएं', query: 'mujhe flashcard banana hai'),
    (label: 'Assessment करें', query: 'assessment kaha hai'),
  ];

  @override
  void initState() {
    super.initState();
    _loadLanguage();
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  CopilotStore _store() {
    try {
      if (getIt.isRegistered<CopilotStore>()) return getIt<CopilotStore>();
    } catch (_) {}
    return CopilotStore(ownerIdProvider: () {
      try {
        if (getIt.isRegistered<CurrentUserService>()) {
          return getIt<CurrentUserService>().currentUserId;
        }
      } catch (_) {}
      return null;
    });
  }

  Future<void> _loadLanguage() async {
    final lang = await _store().getLanguage();
    if (!mounted) return;
    setState(() => _language = lang);
  }

  Future<void> _chooseLanguage(CopilotAnswerLanguage lang) async {
    await _store().setLanguage(lang);
    if (!mounted) return;
    setState(() => _language = lang);
    context.read<TeacherCopilotBloc>().add(SetCopilotLanguage(lang));
  }

  void _submitQuery(String q) {
    if (q.trim().isEmpty) return;
    context.read<TeacherCopilotBloc>().add(AskCopilotQuestion(
          query: q,
          topicContext: _topicContext,
          className: 'Class 2',
          subject: 'Mathematics',
          topic: 'Numbers up to 100',
        ));
    _queryController.clear();
  }

  void _openRoute(String route) {
    try {
      context.push(route);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Teacher Copilot',
      subtitle: 'Offline pedagogy assistant — no internet needed.',
      breadcrumb: 'Teach > Copilot',
      isScrollable: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.greenSurface,
              borderRadius: AppRadius.radiusMd,
              border: Border.all(color: AppColors.greenBorder),
            ),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome_rounded,
                    color: AppColors.primary, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Ask how to explain, simplify, or find worksheets, flashcards and assessments. Answers are stored on this device.',
                    style: AppTypography.bodySmall
                        .copyWith(color: AppColors.primaryDark),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (_language == null) ...[
            Text('Answer language / जवाब की भाषा',
                style: AppTypography.caption
                    .copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: SecondaryButton(
                    label: 'हिंदी',
                    onPressed: () =>
                        _chooseLanguage(CopilotAnswerLanguage.hindi),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SecondaryButton(
                    label: 'English',
                    onPressed: () =>
                        _chooseLanguage(CopilotAnswerLanguage.english),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ] else ...[
            Row(
              children: [
                Text('Answers in: ',
                    style: AppTypography.caption
                        .copyWith(fontWeight: FontWeight.w700)),
                Text(
                  _language == CopilotAnswerLanguage.hindi
                      ? 'हिंदी'
                      : 'English',
                  style: AppTypography.caption.copyWith(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => setState(() => _language = null),
                  child: const Text('Change'),
                ),
              ],
            ),
            const SizedBox(height: 4),
          ],
          Text('Quick questions',
              style: AppTypography.caption
                  .copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _quickQuestions
                .map((q) => ActionChip(
                      label: Text(q.label),
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: AppColors.cardBorder),
                      labelStyle: AppTypography.caption.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600),
                      onPressed: _language == null
                          ? null
                          : () => _submitQuery(q.query),
                    ))
                .toList(),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _queryController,
                  enabled: _language != null,
                  decoration: const InputDecoration(
                    hintText: 'e.g. "worksheet kaha hai"',
                  ),
                  onSubmitted: _submitQuery,
                ),
              ),
              const SizedBox(width: 8),
              PrimaryButton(
                label: 'Ask',
                icon: Icons.send_rounded,
                width: 90,
                onPressed: _language == null
                    ? null
                    : () => _submitQuery(_queryController.text),
              ),
            ],
          ),
          const SizedBox(height: 20),
          BlocBuilder<TeacherCopilotBloc, TeacherCopilotState>(
            builder: (context, state) {
              if (state is TeacherCopilotThinking) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Column(
                      children: [
                        CircularProgressIndicator(
                            color: AppColors.primary),
                        SizedBox(height: 12),
                        Text('Looking up offline guidance...'),
                      ],
                    ),
                  ),
                );
              }
              if (state is TeacherCopilotResponse) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Co-Pilot Answer',
                        style: AppTypography.sectionTitle),
                    const SizedBox(height: 8),
                    CustomCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(state.responseTitle,
                              style: AppTypography.cardTitle
                                  .copyWith(fontSize: 15)),
                          const SizedBox(height: 8),
                          Text(state.responseBody,
                              style: AppTypography.bodyMedium,
                              softWrap: true),
                          if (state.needsClarification &&
                              state.clarificationOptions.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            // Engine's predefined question: resource
                            // disambiguation, topic picker, or help choice.
                            Text(state.responseBody,
                                style: AppTypography.bodyMedium,
                                softWrap: true),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: state.clarificationOptions
                                  .map((o) => ActionChip(
                                        label: Text(o.label),
                                        onPressed: () => context
                                            .read<TeacherCopilotBloc>()
                                            .add(PickCopilotClarification(
                                                o.knowledgeItemId)),
                                      ))
                                  .toList(),
                            ),
                          ],
                          if (!state.needsClarification &&
                              (state.route ?? '').isNotEmpty) ...[
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: SecondaryButton(
                                label: (state.routeLabel ?? '').isEmpty
                                    ? 'Open'
                                    : state.routeLabel!,
                                icon: Icons.arrow_forward_rounded,
                                onPressed: () =>
                                    _openRoute(state.route!),
                              ),
                            ),
                          ],
                          if (state.isUnknown) ...[
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: state.followUpSuggestions
                                  .map((s) => ActionChip(
                                        label: Text(s),
                                        onPressed: () {
                                          final match = _quickQuestions
                                              .where((q) =>
                                                  q.label == s);
                                          if (match.isNotEmpty) {
                                            _submitQuery(
                                                match.first.query);
                                          }
                                        },
                                      ))
                                  .toList(),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                );
              }
              return CustomCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('How can Co-Pilot help you today?',
                        style: AppTypography.cardTitle),
                    const SizedBox(height: 6),
                    Text(
                      'Choose an answer language, tap a quick question or type your own. Works fully offline.',
                      style: AppTypography.bodySmall,
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
