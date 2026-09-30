import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/di/injection.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radius.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/auth/services/current_user_service.dart';
import '../../../core/content/prototype_teacher_guidance_repository.dart';
import '../../../core/content/teacher_guidance_models.dart';
import '../../../features/teach/presentation/bloc/teach_bloc.dart';
import '../copilot_engine.dart';
import '../copilot_models.dart';
import '../copilot_store.dart';

/// Opens the offline Teacher Co-Pilot chat panel as a bottom sheet above
/// the bottom navigation. The teacher stays on the current page.
Future<void> showCopilotSheet(BuildContext context) {
  final routerContext = context;
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => CopilotChatSheet(routerContext: routerContext),
  );
}

class _ChatEntry {
  final bool fromTeacher;
  final String text;
  final String? route;
  final String actionLabel;
  final bool autoNavigated;
  const _ChatEntry({
    required this.fromTeacher,
    required this.text,
    this.route,
    this.actionLabel = '',
    this.autoNavigated = false,
  });
}

class CopilotChatSheet extends StatefulWidget {
  /// Context that stays mounted for navigation (the page that opened the
  /// sheet). The sheet's own context is deactivated after pop, so routes
  /// are pushed through this one. Null in widget tests (no router).
  final BuildContext? routerContext;
  final CopilotEngine? engine;
  final CopilotStore? store;
  final PrototypeTeacherGuidanceRepository? guidanceRepository;

  const CopilotChatSheet({
    super.key,
    this.routerContext,
    this.engine,
    this.store,
    this.guidanceRepository,
  });

  @override
  State<CopilotChatSheet> createState() => _CopilotChatSheetState();
}

class _CopilotChatSheetState extends State<CopilotChatSheet> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scroll = ScrollController();
  late final CopilotEngine _engine;
  late final CopilotStore _store;
  CopilotAnswerLanguage? _language;
  bool _languageLoaded = false;
  bool _thinking = false;
  List<CopilotQuickQuestion> _quickQuestions = const [];
  List<_ChatEntry> _messages = const [];
  List<CopilotKnowledgeItem> _clarificationOptions = const [];

  @override
  void initState() {
    super.initState();
    _engine = widget.engine ?? _resolveEngine();
    _store = widget.store ?? _resolveStore();
    _init();
  }

  CopilotEngine _resolveEngine() {
    try {
      if (getIt.isRegistered<CopilotEngine>()) return getIt<CopilotEngine>();
    } catch (_) {}
    return CopilotEngine(
      guidanceLookup: (query, lesson) => _guidanceLookup(query, lesson),
    );
  }

  CopilotStore _resolveStore() {
    try {
      if (getIt.isRegistered<CopilotStore>()) return getIt<CopilotStore>();
    } catch (_) {}
    return CopilotStore(
      ownerIdProvider: () {
        try {
          if (getIt.isRegistered<CurrentUserService>()) {
            return getIt<CurrentUserService>().currentUserId;
          }
        } catch (_) {}
        return null;
      },
    );
  }

  PrototypeTeacherGuidanceRepository _guidanceRepo() {
    if (widget.guidanceRepository != null) {
      return widget.guidanceRepository!;
    }
    try {
      if (getIt.isRegistered<PrototypeTeacherGuidanceRepository>()) {
        return getIt<PrototypeTeacherGuidanceRepository>();
      }
    } catch (_) {}
    return PrototypeTeacherGuidanceRepository();
  }

  Future<CopilotGuidanceAnswer?> _guidanceLookup(
      String expandedQuery, CopilotLessonContext lesson) async {
    try {
      final repo = _guidanceRepo();
      final result = await repo.answerQuestion(
        expandedQuery,
        context: TeacherGuidanceContext(
          className: lesson.className,
          subject: lesson.subject,
          topic: lesson.topic,
        ),
      );
      if (result.isUnknown ||
          result.needsClarification ||
          result.item == null) {
        return null;
      }
      return CopilotGuidanceAnswer(
        answerHindi: result.item!.answerHindi,
        answerEnglish: result.item!.answerEnglish,
        topic: result.item!.topic,
      );
    } catch (_) {
      return null;
    }
  }

  CopilotLessonContext _lessonContext() {
    try {
      final state = context.read<TeachBloc>().state;
      if (state is TeachLoaded) {
        // Demo default topic: TeachBloc tracks grade + subject only. For
        // Class 2 Mathematics the bundled guidance centers on
        // "Numbers up to 100", so that is the documented fallback.
        final topic = state.selectedSubject.toLowerCase().contains('math')
            ? 'Numbers up to 100'
            : null;
        return CopilotLessonContext(
          className: 'Class ${state.selectedGrade}',
          subject: state.selectedSubject,
          topic: topic,
        );
      }
    } catch (_) {}
    return const CopilotLessonContext(
      className: 'Class 2',
      subject: 'Mathematics',
      topic: 'Numbers up to 100',
    );
  }

  Future<void> _init() async {
    final lang = await _store.getLanguage();
    final quick = await _engine.loadQuickQuestions();
    await _engine.loadItems();
    if (!mounted) return;
    setState(() {
      _language = lang;
      _languageLoaded = true;
      _quickQuestions = quick;
      _messages = [
        const _ChatEntry(
          fromTeacher: false,
          text:
              'नमस्ते! मैं आपकी Teacher Co-Pilot हूँ। मैं आपको lessons, activities, worksheets, flashcards और app features खोजने में मदद कर सकती हूँ।\n\n'
              'Namaste! I am your Teacher Co-Pilot. I can help you find lessons, activities, worksheets, flashcards and app features.\n\n'
              'आप जवाब किस भाषा में चाहते हैं? / Which language would you like for my answers?',
        ),
      ];
    });
  }

  Future<void> _chooseLanguage(CopilotAnswerLanguage lang) async {
    await _store.setLanguage(lang);
    if (!mounted) return;
    setState(() {
      _language = lang;
      _messages = [
        ..._messages,
        _ChatEntry(
          fromTeacher: false,
          text: lang == CopilotAnswerLanguage.hindi
              ? 'ठीक है! अब से मैं हिंदी में जवाब दूँगी। अपना सवाल लिखें या नीचे कोई सवाल चुनें।'
              : 'Done! I will answer in English from now on. Type your question or pick one below.',
        ),
      ];
    });
    _scrollToEnd();
  }

  List<CopilotQuickQuestion> get _visibleQuickQuestions {
    final hasContext = !_lessonContext().isEmpty;
    final defaults = _quickQuestions.where((q) => !q.contextAware).take(6);
    final ctx = _quickQuestions.where((q) => q.contextAware).take(5);
    final combined = hasContext ? [...ctx, ...defaults] : [...defaults];
    // De-duplicate by id, keep order.
    final seen = <String>{};
    final out = <CopilotQuickQuestion>[];
    for (final q in combined) {
      if (seen.add(q.id)) out.add(q);
      if (out.length >= 6) break;
    }
    return out;
  }

  Future<void> _send(String raw) async {
    final text = raw.trim();
    if (text.isEmpty || _thinking) return;
    final lang = _language ?? CopilotAnswerLanguage.hindi;
    setState(() {
      _thinking = true;
      _clarificationOptions = const [];
      _messages = [..._messages, _ChatEntry(fromTeacher: true, text: text)];
    });
    _controller.clear();
    _scrollToEnd();
    await Future<void>.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    final lesson = _lessonContext();
    final conv = _store.conversation();
    CopilotResult result;
    try {
      result = await _engine.answer(
        text,
        lesson: lesson,
        conversation: conv,
        language: lang,
      );
    } catch (_) {
      result = CopilotResult.unknown(
        answer: lang == CopilotAnswerLanguage.hindi
            ? CopilotEngine.unknownAnswerHindi
            : CopilotEngine.unknownAnswerEnglish,
        threshold: _engine.defaultThreshold,
        previous: conv,
      );
    }
    _store.saveConversation(result.nextContext);
    if (!mounted) return;
    setState(() {
      _thinking = false;
      _messages = [
        ..._messages,
        _ChatEntry(
          fromTeacher: false,
          text: result.answer,
          route: result.route,
          actionLabel: result.actionLabel,
          autoNavigated: result.autoNavigate,
        ),
      ];
      if (result.needsClarification) {
        _clarificationOptions = result.clarificationOptions;
      }
    });
    _scrollToEnd();
    if (result.autoNavigate && result.route != null) {
      final target = result.route!;
      await Future<void>.delayed(const Duration(milliseconds: 450));
      if (!mounted) return;
      _navigate(target);
    }
  }

  Map<String, String?> _lessonExtra(CopilotLessonContext lesson) => {
        'className': lesson.className,
        'subject': lesson.subject,
        'topic': lesson.topic,
      };

  void _navigate(String route) {
    final target = widget.routerContext ?? context;
    Navigator.of(context).pop();
    Future<void>.delayed(const Duration(milliseconds: 60), () {
      try {
        if (route == '/teach/guidance') {
          GoRouter.of(target).push(route, extra: _lessonExtra(_lessonContext()));
        } else {
          GoRouter.of(target).push(route);
        }
      } catch (_) {}
    });
  }

  void _pickClarification(CopilotKnowledgeItem item) {
    final lang = _language ?? CopilotAnswerLanguage.hindi;
    _store.saveConversation(CopilotConversationContext(
      lastIntent: item.intent,
      lastTopic: _lessonContext().topic,
      lastRoute: item.route,
      lastItemId: item.id,
    ));
    setState(() {
      _clarificationOptions = const [];
      _messages = [
        ..._messages,
        _ChatEntry(
          fromTeacher: false,
          text: item.answerFor(lang).isEmpty
              ? (lang == CopilotAnswerLanguage.hindi
                  ? 'इस विषय पर मार्गदर्शन के लिए Teaching Guidance खोलें।'
                  : 'Open Teaching Guidance for this topic.')
              : item.answerFor(lang),
          route: item.route,
          actionLabel: item.actionFor(lang),
        ),
      ];
    });
    _scrollToEnd();
  }

  void _scrollToEnd() {
    Future<void>.delayed(const Duration(milliseconds: 80), () {
      if (!_scroll.hasClients) return;
      try {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.82,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Color(0x26000000),
              blurRadius: 24,
              offset: Offset(0, -6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.cardBorder,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            _Header(onClose: () => Navigator.of(context).pop()),
            const Divider(height: 1, color: AppColors.cardBorder),
            Flexible(
              child: ListView(
                controller: _scroll,
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                shrinkWrap: true,
                children: [
                  for (final m in _messages)
                    _MessageBubble(
                      entry: m,
                      onOpen: m.route == null ? null : () => _navigate(m.route!),
                    ),
                  if (_thinking)
                    const _MessageBubble(
                      entry: _ChatEntry(
                          fromTeacher: false, text: '…'),
                    ),
                  if (_clarificationOptions.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _clarificationOptions
                          .map((o) => _ChoiceChip(
                                label: o.actionFor(
                                    _language ?? CopilotAnswerLanguage.hindi),
                                onTap: () => _pickClarification(o),
                              ))
                          .toList(),
                    ),
                  ],
                  if (_languageLoaded && _language == null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _ChoiceChip(
                            label: 'हिंदी',
                            onTap: () => _chooseLanguage(
                                CopilotAnswerLanguage.hindi),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _ChoiceChip(
                            label: 'English',
                            onTap: () => _chooseLanguage(
                                CopilotAnswerLanguage.english),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (_language != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      'Quick Questions',
                      style: AppTypography.caption.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _visibleQuickQuestions
                          .map((q) => _ChoiceChip(
                                label: q.labelFor(_language!),
                                onTap: _thinking ? null : () => _send(q.query),
                              ))
                          .toList(),
                    ),
                  ],
                  const SizedBox(height: 8),
                ],
              ),
            ),
            _InputBar(
              controller: _controller,
              enabled: !_thinking && _language != null,
              onSend: _send,
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final VoidCallback onClose;
  const _Header({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 6, 8, 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: AppColors.greenLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: AppColors.primaryDark,
              size: 18,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Teacher Co-Pilot',
              style: AppTypography.cardTitle.copyWith(fontSize: 15),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.greenLight,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppColors.greenBorder),
            ),
            child: Text(
              'Offline',
              style: AppTypography.captionSmall.copyWith(
                color: AppColors.primaryDark,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          IconButton(
            key: const Key('copilotClose'),
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded,
                color: AppColors.textSecondary, size: 20),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final _ChatEntry entry;
  final VoidCallback? onOpen;
  const _MessageBubble({required this.entry, this.onOpen});

  @override
  Widget build(BuildContext context) {
    final isTeacher = entry.fromTeacher;
    return Align(
      alignment: isTeacher ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.82,
        ),
        decoration: BoxDecoration(
          color: isTeacher ? AppColors.primary : AppColors.backgroundSoft,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(14),
            topRight: const Radius.circular(14),
            bottomLeft: Radius.circular(isTeacher ? 14 : 4),
            bottomRight: Radius.circular(isTeacher ? 4 : 14),
          ),
          border: isTeacher
              ? null
              : Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              entry.text,
              softWrap: true,
              style: AppTypography.bodySmall.copyWith(
                color: isTeacher ? Colors.white : AppColors.textPrimary,
                height: 1.4,
              ),
            ),
            if (!isTeacher && entry.route != null) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  key: Key('copilotOpen:${entry.route}'),
                  onPressed: onOpen,
                  icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                  label: Text(entry.actionLabel.isEmpty
                      ? 'Open'
                      : entry.actionLabel),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryDark,
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 8),
                    textStyle: AppTypography.caption.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ChoiceChip extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  const _ChoiceChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: AppRadius.radiusPill,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.radiusPill,
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;
  final ValueChanged<String> onSend;
  const _InputBar({
    required this.controller,
    required this.enabled,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.cardBorder)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                key: const Key('copilotInput'),
                controller: controller,
                enabled: enabled,
                minLines: 1,
                maxLines: 3,
                textInputAction: TextInputAction.send,
                decoration: const InputDecoration(
                  hintText: 'Ask your question...',
                ),
                onSubmitted: onSend,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                key: const Key('copilotSend'),
                onPressed:
                    enabled ? () => onSend(controller.text) : null,
                icon: const Icon(Icons.arrow_upward_rounded,
                    color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
