import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/auth/services/current_user_service.dart';
import '../../../../core/content/prototype_teacher_guidance_repository.dart';
import '../../../../core/content/teacher_guidance_models.dart';
import '../../../../core/copilot/copilot_models.dart'
    show CopilotAnswerLanguage, CopilotConversationContext;
import '../../../../core/copilot/copilot_store.dart';
import '../../../../core/teacher_assist/teacher_question_engine.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/custom_card.dart';
import '../bloc/teach_bloc.dart';

/// Offline Teacher Guidance Q&A screen (deterministic prototype).
///
/// Flow: teacher question -> SHARED [TeacherQuestionEngine] (same engine as
/// the Teacher Co-Pilot) -> predefined Hindi + English answers + optional
/// local route. No FastAPI, Supabase, Sarvam, LLM, or internet at any point.
class TeacherGuidanceScreen extends StatefulWidget {
  /// Lesson context from the Teach flow (may be partial or empty).
  final TeacherGuidanceContext initialContext;

  /// Engine override (tests). Defaults to a local [TeacherQuestionEngine].
  final TeacherQuestionEngine? engine;

  /// Legacy repository override (older tests). When provided, questions are
  /// answered through it and converted to the shared result shape so the UI
  /// stays identical.
  final PrototypeTeacherGuidanceRepository? repository;

  /// History store override (tests). Defaults to a shared local instance.
  final TeacherGuidanceHistoryStore? historyStore;

  const TeacherGuidanceScreen({
    super.key,
    this.initialContext = const TeacherGuidanceContext(),
    this.engine,
    this.repository,
    this.historyStore,
  });

  @override
  State<TeacherGuidanceScreen> createState() => _TeacherGuidanceScreenState();
}

class _TeacherGuidanceScreenState extends State<TeacherGuidanceScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _asking = false;
  String? _askedQuestion;
  QuestionResult? _result;
  // Topic picked from the engine's topic picker while choosing help.
  String? _pickedTopic;
  late final TeacherQuestionEngine _engine;

  @override
  void initState() {
    super.initState();
    _engine = widget.engine ?? TeacherQuestionEngine();
    _warm();
  }

  Future<void> _warm() async {
    try {
      await _engine.loadItems();
    } catch (_) {}
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  TeacherGuidanceContext _guidanceContext(BuildContext context) {
    if (!widget.initialContext.isEmpty) return widget.initialContext;
    try {
      final state = context.read<TeachBloc>().state;
      if (state is TeachLoaded) {
        return TeacherGuidanceContext(
          className: 'Class ${state.selectedGrade}',
          subject: state.selectedSubject,
        );
      }
    } catch (_) {}
    return const TeacherGuidanceContext();
  }

  LessonContext _lessonContext(BuildContext context) {
    // Pass through the REAL page context only. Never fabricate a topic
    // here: the shared engine must ask the teacher when no explicit topic
    // exists (page context only filters topic options).
    final c = _guidanceContext(context);
    return LessonContext(
      className: c.className,
      subject: c.subject,
      topic: c.topic,
    );
  }

  /// Dynamic quick questions: same shared engine, but the query text is
  /// built from the live Class/Subject/Topic so "Give me an activity"
  /// resolves to the current topic's activity entry.
  List<({String label, String query})> _quickQuestions(
      TeacherGuidanceContext ctx) {
    final topic = (ctx.topic ?? '').trim();
    final hasTopic = topic.isNotEmpty;
    return [
      (
        label: 'How should I teach this?',
        query: hasTopic ? 'How should I teach $topic?' : 'How should I teach this?',
      ),
      (
        label: 'Give me an activity',
        query: hasTopic ? '$topic ke liye ek activity batao' : 'ek activity batao',
      ),
      (
        label: 'Give me an example',
        query: hasTopic ? 'Give me an example for $topic' : 'Give me an example',
      ),
      (
        label: 'How can I simplify this?',
        query: hasTopic ? '$topic ko simple kaise samjhau' : 'ye kaise samjhau',
      ),
      (
        label: 'How should I assess it?',
        query: hasTopic ? '$topic ka assessment kaise karu' : 'How should I assess it?',
      ),
    ];
  }

  Future<AnswerLanguage> _answerLanguage() async {
    try {
      if (getIt.isRegistered<CopilotStore>()) {
        final lang = await getIt<CopilotStore>().getLanguage();
        if (lang == CopilotAnswerLanguage.english) {
          return AnswerLanguage.english;
        }
      }
    } catch (_) {}
    return AnswerLanguage.hindi;
  }

  ConversationContext _conversation() {
    try {
      if (getIt.isRegistered<CopilotStore>()) {
        final c = getIt<CopilotStore>().conversation();
        return ConversationContext(
          lastIntent: c.lastIntent,
          lastTopic: c.lastTopic,
          lastRoute: c.lastRoute,
          lastItemId: c.lastItemId,
        );
      }
    } catch (_) {}
    return ConversationContext.empty;
  }

  /// Persists the engine's conversation context so follow-ups ("iske
  /// liye...") resolve to the explicitly established topic. Never stores
  /// the page topic: the engine only puts explicit topics here.
  void _saveConversation(ConversationContext c) {
    try {
      if (getIt.isRegistered<CopilotStore>()) {
        getIt<CopilotStore>().saveConversation(CopilotConversationContext(
          lastIntent: c.lastIntent,
          lastTopic: c.lastTopic,
          lastRoute: c.lastRoute,
          lastItemId: c.lastItemId,
        ));
      }
    } catch (_) {}
  }

  /// Topic picked from the engine's topic picker. When the original
  /// question already carried an intent, answer it directly for the
  /// chosen topic; otherwise ask what help the teacher needs.
  Future<void> _pickTopic(QuestionResultOption option) async {
    final raw = option.label.trim().isNotEmpty
        ? option.label.trim()
        : option.knowledgeItemId.replaceFirst('topic::', '').trim();
    if (raw.isEmpty || _asking) return;
    final pending = _result?.pendingIntent;
    if (pending == null || pending.isEmpty) {
      setState(() => _pickedTopic = raw);
      return;
    }
    setState(() => _asking = true);
    final lang = await _answerLanguage();
    final r = await _engine.answerForTopicIntent(
      topic: raw,
      intent: pending,
      context: mounted ? _lessonContext(context) : const LessonContext(),
      answerLanguage: lang,
      conversationContext: _conversation(),
    );
    _saveConversation(r.nextContext);
    if (!mounted) return;
    setState(() {
      _asking = false;
      _result = r;
      _pickedTopic = null;
    });
  }

  /// Help option picked for an already-chosen topic ("How should I teach
  /// it?" etc.): return that topic's predefined answer.
  Future<void> _pickHelp(String intent) async {
    final topic = (_pickedTopic ?? '').trim();
    if (topic.isEmpty || intent.isEmpty || _asking) return;
    setState(() => _asking = true);
    final lang = await _answerLanguage();
    final r = await _engine.answerForTopicIntent(
      topic: topic,
      intent: intent,
      context: mounted ? _lessonContext(context) : const LessonContext(),
      answerLanguage: lang,
      conversationContext: _conversation(),
    );
    _saveConversation(r.nextContext);
    if (!mounted) return;
    setState(() {
      _asking = false;
      _result = r;
      _pickedTopic = null;
    });
  }

  Future<void> _ask(String rawQuestion) async {
    final question = rawQuestion.trim();
    if (question.isEmpty || _asking) return;
    setState(() {
      _asking = true;
      _askedQuestion = question;
      _result = null;
      _pickedTopic = null;
    });
    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (!mounted) return;
    final lesson = _lessonContext(context);
    final lang = await _answerLanguage();
    final conv = _conversation();
    QuestionResult result;
    try {
      if (widget.repository != null) {
        result = await _answerViaLegacyRepo(question, lesson, lang, conv);
      } else {
        result = await _engine.resolve(
          question,
          context: lesson,
          answerLanguage: lang,
          conversationContext: conv,
        );
      }
    } catch (_) {
      result = QuestionResult.unknown(
        answer: lang == AnswerLanguage.hindi
            ? TeacherQuestionEngine.unknownAnswerHindi
            : TeacherQuestionEngine.unknownAnswerEnglish,
        answerLanguage: lang,
        threshold: _engine.defaultThreshold,
        previous: conv,
      );
    }
    _saveConversation(result.nextContext);
    String? ownerId;
    try {
      if (getIt.isRegistered<CurrentUserService>()) {
        ownerId = getIt<CurrentUserService>().currentUserId;
      }
    } catch (_) {}
    if (ownerId != null && ownerId.trim().isNotEmpty) {
      final store = widget.historyStore ?? _sharedHistory;
      store.record(
        ownerUserId: ownerId.trim(),
        question: question,
        matchedItemId: result.knowledgeItemId,
      );
    }
    if (!mounted) return;
    setState(() {
      _asking = false;
      _result = result;
    });
    _controller.clear();
  }

  Future<QuestionResult> _answerViaLegacyRepo(
    String question,
    LessonContext lesson,
    AnswerLanguage lang,
    ConversationContext conv,
  ) async {
    final repo = widget.repository!;
    final r = await repo.answerQuestion(
      question,
      context: TeacherGuidanceContext(
        className: lesson.className,
        subject: lesson.subject,
        topic: lesson.topic,
      ),
    );
    if (r.needsClarification) {
      return QuestionResult.clarification(
        answer: 'I found guidance for:',
        answerLanguage: lang,
        options: r.clarificationOptions
            .map((e) => QuestionResultOption(
                  knowledgeItemId: e.id,
                  intent: e.intent.name,
                  label: e.topic.isNotEmpty ? e.topic : e.id,
                  route: null,
                ))
            .toList(),
        score: r.score,
        threshold: r.threshold,
        nextContext: conv,
      );
    }
    if (r.isUnknown || r.item == null) {
      return QuestionResult.unknown(
        answer: lang == AnswerLanguage.hindi
            ? TeacherQuestionEngine.unknownAnswerHindi
            : TeacherQuestionEngine.unknownAnswerEnglish,
        answerLanguage: lang,
        threshold: r.threshold,
        previous: conv,
      );
    }
    final item = r.item!;
    return QuestionResult.matched(
      intent: item.intent.name,
      knowledgeItemId: item.id,
      answer: lang == AnswerLanguage.hindi
          ? item.answerHindi
          : item.answerEnglish,
      answerLanguage: lang,
      answerHindi: item.answerHindi,
      answerEnglish: item.answerEnglish,
      route: null,
      routeLabel: null,
      score: r.score,
      threshold: r.threshold,
      nextContext: conv,
    );
  }

  void _askAgain() {
    setState(() {
      _askedQuestion = null;
      _result = null;
      _pickedTopic = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ctx = _guidanceContext(context);
    final quicks = _quickQuestions(ctx);
    return AppScaffold(
      title: 'Teacher Guidance',
      subtitle: 'Offline teaching support — no internet needed.',
      breadcrumb: 'Teach > Guidance',
      isScrollable: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ContextCard(context: ctx),
          const SizedBox(height: 14),
          Text('Ask for teaching support',
              style: AppTypography.sectionTitle.copyWith(fontSize: 15)),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  key: const Key('guidanceQuestionField'),
                  controller: _controller,
                  minLines: 1,
                  maxLines: 3,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    hintText:
                        'e.g. "How should I teach numbers up to 100?"',
                  ),
                  onSubmitted: _ask,
                ),
              ),
              const SizedBox(width: 8),
              PrimaryButton(
                key: const Key('guidanceAskButton'),
                label: 'Ask',
                icon: Icons.send_rounded,
                width: 92,
                onPressed: _asking ? null : () => _ask(_controller.text),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: quicks
                .map((q) => _QuickChip(
                      label: q.label,
                      onTap: _asking ? null : () => _ask(q.query),
                    ))
                .toList(),
          ),
          const SizedBox(height: 14),
          if (_asking) ...[
            const _ProcessingCard(),
            const SizedBox(height: 14),
          ],
          if (!_asking && _result != null && _askedQuestion != null) ...[
            _ResultCard(
              askedQuestion: _askedQuestion!,
              result: _result!,
              onTryAnother: _askAgain,
              onPickClarification: (item) async {
                // Topic picker from the shared engine: pick a topic, then
                // either answer the pending intent or ask what help is
                // needed. Never auto-selects a topic.
                if (item.intent == 'TOPIC_PICK') {
                  await _pickTopic(item);
                  return;
                }
                if (widget.repository != null) {
                  // Legacy test path: the clarification option carries the
                  // topic/id; re-ask with it so the repository returns the
                  // predefined answer for that item.
                  final lesson = _lessonContext(context);
                  final lang = await _answerLanguage();
                  final conv = _conversation();
                  final again = await _answerViaLegacyRepo(
                      item.knowledgeItemId.replaceAll('_', ' '),
                      lesson,
                      lang,
                      conv);
                  if (!mounted) return;
                  setState(() {
                    _result = again.matched
                        ? again
                        : QuestionResult.matched(
                            intent: item.intent,
                            knowledgeItemId: item.knowledgeItemId,
                            answer: lang == AnswerLanguage.hindi
                                ? TeacherQuestionEngine.unknownAnswerHindi
                                : TeacherQuestionEngine.unknownAnswerEnglish,
                            answerLanguage: lang,
                            route: item.route,
                            routeLabel: item.label,
                            score: _result!.score,
                            threshold: _result!.threshold,
                          );
                  });
                  return;
                }
                // Shared-engine path: re-resolve deterministically so the
                // choice yields that option's predefined answer+route.
                final lesson = _lessonContext(context);
                final lang = await _answerLanguage();
                final followUp = await _engine.resolve(
                  item.knowledgeItemId.replaceAll('_', ' '),
                  context: lesson,
                  answerLanguage: lang,
                  conversationContext: ConversationContext(
                    lastIntent: item.intent,
                    lastTopic: lesson.topic,
                    lastRoute: item.route,
                    lastItemId: item.knowledgeItemId,
                  ),
                );
                if (!mounted) return;
                setState(() {
                  _result = followUp.matched
                      ? followUp
                      : QuestionResult.matched(
                          intent: item.intent,
                          knowledgeItemId: item.knowledgeItemId,
                          answer: lang == AnswerLanguage.hindi
                              ? TeacherQuestionEngine.unknownAnswerHindi
                              : TeacherQuestionEngine.unknownAnswerEnglish,
                          answerLanguage: lang,
                          route: item.route,
                          routeLabel: item.label,
                          score: _result!.score,
                          threshold: _result!.threshold,
                        );
                });
              },
              onOpenRoute: (route) {
                try {
                  context.push(route);
                } catch (_) {}
              },
            ),
            const SizedBox(height: 14),
          ],
          // After a topic is picked without a pending intent, ask what
          // help the teacher needs (predefined options, offline).
          if (!_asking &&
              _pickedTopic != null &&
              _result != null &&
              _result!.needsClarification) ...[
            _HelpChoiceCard(
              topic: _pickedTopic!,
              onPick: _pickHelp,
            ),
            const SizedBox(height: 14),
          ],
          const _OfflineReadyRow(),
          const SizedBox(height: 28),
        ],
      ),
    );
  }
}

final TeacherGuidanceHistoryStore _sharedHistory =
    TeacherGuidanceHistoryStore();

/// Current lesson context header (Class • Subject • Topic when known).
class _ContextCard extends StatelessWidget {
  final TeacherGuidanceContext context;

  const _ContextCard({required this.context});

  @override
  Widget build(BuildContext context) {
    final parts = [
      this.context.className,
      this.context.subject,
    ].where((e) => (e ?? '').trim().isNotEmpty).cast<String>().toList();
    return CustomCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.school_outlined,
                color: AppColors.primaryDark, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  parts.isEmpty ? 'Teacher Guidance' : parts.join(' • '),
                  style: AppTypography.cardTitleSmall.copyWith(fontSize: 13),
                  softWrap: true,
                ),
                if ((this.context.topic ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    this.context.topic!.trim(),
                    style: AppTypography.caption,
                    softWrap: true,
                  ),
                ],
              ],
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
    );
  }
}

class _QuickChip extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const _QuickChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: AppRadius.radiusPill,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.radiusPill,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: AppRadius.radiusPill,
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Text(
            label,
            style: AppTypography.caption.copyWith(
              color: AppColors.primaryDark,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _ProcessingCard extends StatelessWidget {
  const _ProcessingCard();

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      key: const Key('guidanceProcessing'),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Processing... looking up offline guidance.',
              style: AppTypography.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

/// Bilingual result: pre-authored Hindi + English, unknown message, or
/// a small clarification choice. Never an "AI answer".
class _ResultCard extends StatelessWidget {
  final String askedQuestion;
  final QuestionResult result;
  final VoidCallback onTryAnother;
  final ValueChanged<QuestionResultOption> onPickClarification;
  final ValueChanged<String> onOpenRoute;

  const _ResultCard({
    required this.askedQuestion,
    required this.result,
    required this.onTryAnother,
    required this.onPickClarification,
    required this.onOpenRoute,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      key: const Key('guidanceResultCard'),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Guidance',
              style: AppTypography.cardTitle.copyWith(fontSize: 14)),
          const SizedBox(height: 4),
          Text(
            '“$askedQuestion”',
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
              fontStyle: FontStyle.italic,
            ),
            softWrap: true,
          ),
          const SizedBox(height: 10),
          if (result.needsClarification) ...[
            Text(
              result.answer,
              style: AppTypography.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
              ),
              softWrap: true,
            ),
            const SizedBox(height: 8),
            ...result.clarificationOptions.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: SizedBox(
                    width: double.infinity,
                    child: SecondaryButton(
                      key: Key('clarification_${item.knowledgeItemId}'),
                      label: item.label.isNotEmpty
                          ? item.label
                          : item.knowledgeItemId,
                      onPressed: () => onPickClarification(item),
                    ),
                  ),
                )),
          ] else if (result.isUnknown) ...[
            _AnswerBlock(
              heading: 'हिंदी',
              body: TeacherQuestionEngine.unknownAnswerHindi,
            ),
            const SizedBox(height: 10),
            _AnswerBlock(
              heading: 'English',
              body: TeacherQuestionEngine.unknownAnswerEnglish,
            ),
            const SizedBox(height: 8),
            Text(
              'Try asking about the current lesson topic.',
              style: AppTypography.caption,
              softWrap: true,
            ),
          ] else ...[
            _AnswerBlock(
              heading: 'हिंदी',
              body: _hindiOf(result),
            ),
            const SizedBox(height: 10),
            _AnswerBlock(
              heading: 'English',
              body: _englishOf(result),
            ),
            if ((result.route ?? '').isNotEmpty) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: SecondaryButton(
                  label: (result.routeLabel ?? '').isEmpty
                      ? 'Open'
                      : result.routeLabel!,
                  icon: Icons.arrow_forward_rounded,
                  onPressed: () => onOpenRoute(result.route!),
                ),
              ),
            ],
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: SecondaryButton(
              key: const Key('guidanceTryAnotherButton'),
              label: 'Try Another Question',
              icon: Icons.refresh_rounded,
              onPressed: onTryAnother,
            ),
          ),
        ],
      ),
    );
  }

  // Bilingual page: both blocks show the predefined pair from the matched
  // knowledge item (never translated at runtime). Falls back to the
  // resolved single-language answer when the pair is unavailable.
  String _hindiOf(QuestionResult r) {
    final h = (r.answerHindi ?? '').trim();
    if (h.isNotEmpty) return h;
    if (r.answerLanguage == AnswerLanguage.hindi) return r.answer;
    return r.answer;
  }

  String _englishOf(QuestionResult r) {
    final e = (r.answerEnglish ?? '').trim();
    if (e.isNotEmpty) return e;
    if (r.answerLanguage == AnswerLanguage.english) return r.answer;
    return r.answer;
  }
}

/// "What would you like help with?" card shown after a topic is picked
/// without a pending intent. Options come from the shared engine
/// ([TeacherQuestionEngine.helpIntentOptions]), never hardcoded here.
class _HelpChoiceCard extends StatelessWidget {
  final String topic;
  final ValueChanged<String> onPick;

  const _HelpChoiceCard({required this.topic, required this.onPick});

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      key: const Key('guidanceHelpChoiceCard'),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            topic,
            style: AppTypography.cardTitle.copyWith(fontSize: 14),
            softWrap: true,
          ),
          const SizedBox(height: 4),
          Text(
            'What would you like help with?',
            style: AppTypography.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
            ),
            softWrap: true,
          ),
          const SizedBox(height: 8),
          ...TeacherQuestionEngine.helpIntentOptions().map((o) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: SizedBox(
                  width: double.infinity,
                  child: SecondaryButton(
                    key: Key('helpchoice_${o.knowledgeItemId}'),
                    label: o.label,
                    onPressed: () => onPick(
                        o.knowledgeItemId.replaceFirst('intent::', '')),
                  ),
                ),
              )),
        ],
      ),
    );
  }
}

class _AnswerBlock extends StatelessWidget {  final String heading;
  final String body;

  const _AnswerBlock({required this.heading, required this.body});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.backgroundSoft,
        borderRadius: AppRadius.radiusMd,
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            heading,
            style: AppTypography.caption.copyWith(
              color: AppColors.primaryDark,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(body, style: AppTypography.bodySmall, softWrap: true),
        ],
      ),
    );
  }
}

class _OfflineReadyRow extends StatelessWidget {
  const _OfflineReadyRow();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('guidanceOfflineIndicator'),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
          const SizedBox(width: 6),
          Text(
            'Offline Ready — answers stored on this device',
            style: AppTypography.captionSmall.copyWith(
              color: AppColors.primaryDark,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
