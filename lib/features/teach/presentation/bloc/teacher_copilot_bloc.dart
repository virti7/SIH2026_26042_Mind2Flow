import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/teacher_assist/teacher_question_engine.dart';
import '../../../../core/copilot/copilot_store.dart';
import '../../../../core/copilot/copilot_models.dart'
    show CopilotAnswerLanguage, CopilotConversationContext;

// ------------------------------------------------------------------
// Events: screens only send question + context + language preference.
// The bloc forwards everything to the shared TeacherQuestionEngine.
// No answer is ever decided here.
// ------------------------------------------------------------------

abstract class TeacherCopilotEvent extends Equatable {
  const TeacherCopilotEvent();
  @override
  List<Object?> get props => [];
}

class AskCopilotQuestion extends TeacherCopilotEvent {
  final String query;
  final String topicContext;
  final String? className;
  final String? subject;
  final String? topic;
  const AskCopilotQuestion({
    required this.query,
    required this.topicContext,
    this.className,
    this.subject,
    this.topic,
  });
  @override
  List<Object?> get props => [query, topicContext, className, subject, topic];
}

class SelectQuickPrompt extends TeacherCopilotEvent {
  /// Quick-question QUERY text (goes through the shared engine verbatim).
  /// Legacy promptType values ('explain','example','activity','question')
  /// are mapped to engine queries using the current topic context.
  final String promptType;
  final String topicContext;
  const SelectQuickPrompt(this.promptType, {this.topicContext = ''});
  @override
  List<Object?> get props => [promptType, topicContext];
}

class SetCopilotLanguage extends TeacherCopilotEvent {
  final CopilotAnswerLanguage language;
  const SetCopilotLanguage(this.language);
  @override
  List<Object?> get props => [language];
}

class PickCopilotClarification extends TeacherCopilotEvent {
  final String knowledgeItemId;
  const PickCopilotClarification(this.knowledgeItemId);
  @override
  List<Object?> get props => [knowledgeItemId];
}

class ClearCopilotConversation extends TeacherCopilotEvent {
  const ClearCopilotConversation();
}

// ------------------------------------------------------------------

abstract class TeacherCopilotState extends Equatable {
  const TeacherCopilotState();
  @override
  List<Object?> get props => [];
}

class TeacherCopilotInitial extends TeacherCopilotState {}

class TeacherCopilotThinking extends TeacherCopilotState {}

class CopilotClarificationOption extends Equatable {
  final String knowledgeItemId;
  final String intent;
  final String label;
  final String? route;
  const CopilotClarificationOption({
    required this.knowledgeItemId,
    required this.intent,
    required this.label,
    required this.route,
  });
  @override
  List<Object?> get props => [knowledgeItemId, intent, label, route];
}

class TeacherCopilotResponse extends TeacherCopilotState {
  final String query;
  final String responseTitle;
  final String responseBody;
  final String tribalTip;
  final List<String> followUpSuggestions;

  // Shared-engine metadata (null-safe additions, old UI keeps working).
  final String? intent;
  final String? knowledgeItemId;
  final String? route;
  final String? routeLabel;
  final bool isUnknown;
  final bool needsClarification;
  final List<CopilotClarificationOption> clarificationOptions;
  final bool autoNavigate;

  const TeacherCopilotResponse({
    required this.query,
    required this.responseTitle,
    required this.responseBody,
    required this.tribalTip,
    required this.followUpSuggestions,
    this.intent,
    this.knowledgeItemId,
    this.route,
    this.routeLabel,
    this.isUnknown = false,
    this.needsClarification = false,
    this.clarificationOptions = const [],
    this.autoNavigate = false,
  });

  @override
  List<Object?> get props => [
        query,
        responseTitle,
        responseBody,
        tribalTip,
        followUpSuggestions,
        intent,
        knowledgeItemId,
        route,
        routeLabel,
        isUnknown,
        needsClarification,
        clarificationOptions,
        autoNavigate,
      ];
}

/// Teacher Co-Pilot bloc: thin adapter over the shared
/// [TeacherQuestionEngine]. No hardcoded answers here.
class TeacherCopilotBloc extends Bloc<TeacherCopilotEvent, TeacherCopilotState> {
  final TeacherQuestionEngine engine;
  final CopilotStore store;
  QuestionResult? _lastClarification;
  // Topic-picker flow: chosen topic + original intent carried through
  // topic clarification (both reset on every new question).
  String? _pendingTopic;
  String? _pendingIntent;

  TeacherCopilotBloc({TeacherQuestionEngine? engine, CopilotStore? store})
      : engine = engine ?? TeacherQuestionEngine(),
        store = store ?? CopilotStore(),
        super(TeacherCopilotInitial()) {
    on<AskCopilotQuestion>(_onAsk);
    on<SelectQuickPrompt>(_onQuick);
    on<SetCopilotLanguage>(_onLanguage);
    on<PickCopilotClarification>(_onPick);
    on<ClearCopilotConversation>(_onClear);
  }

  LessonContext _lessonFrom(AskCopilotQuestion e) {
    if ((e.className ?? '').trim().isNotEmpty ||
        (e.subject ?? '').trim().isNotEmpty ||
        (e.topic ?? '').trim().isNotEmpty) {
      return LessonContext(
        className: e.className,
        subject: e.subject,
        topic: e.topic,
      );
    }
    // Back-compat: parse "Class 2 Mathematics: Numbers up to 100".
    final raw = e.topicContext;
    String? cls;
    String? sub;
    String? top;
    final classMatch = RegExp(r'class\s*(\d+)', caseSensitive: false).firstMatch(raw);
    if (classMatch != null) cls = 'Class ${classMatch.group(1)}';
    if (raw.toLowerCase().contains('math')) {
      sub = 'Mathematics';
      top = 'Numbers up to 100';
    } else if (raw.toLowerCase().contains('language') ||
        raw.toLowerCase().contains('hindi')) {
      sub = 'Language';
    }
    if (raw.contains(':')) {
      final after = raw.split(':').last.trim();
      if (after.isNotEmpty) top = after;
    }
    return LessonContext(className: cls, subject: sub, topic: top);
  }

  Future<void> _onAsk(
      AskCopilotQuestion event, Emitter<TeacherCopilotState> emit) async {
    emit(TeacherCopilotThinking());
    _pendingTopic = null;
    _pendingIntent = null;
    final stored = await store.getLanguage();
    final lang = stored == CopilotAnswerLanguage.english
        ? AnswerLanguage.english
        : AnswerLanguage.hindi;
    final lesson = _lessonFrom(event);
    final conv = _toConversation(store.conversation());
    final result = await engine.resolve(
      event.query,
      context: lesson,
      answerLanguage: lang,
      conversationContext: conv,
    );
    store.saveConversation(_toCopilotContext(result.nextContext));
    emit(_toState(event.query, result, lang));
  }

  Future<void> _onQuick(
      SelectQuickPrompt event, Emitter<TeacherCopilotState> emit) async {
    // Quick questions carry no hardcoded answers: map to a query string
    // and run it through the SAME shared engine.
    final topic = event.topicContext.trim().isEmpty
        ? 'Numbers up to 100'
        : event.topicContext.trim();
    final String query;
    switch (event.promptType) {
      case 'explain':
        query = 'How should I teach $topic?';
        break;
      case 'example':
        query = 'Give me an example for $topic';
        break;
      case 'activity':
        query = 'ek activity batao';
        break;
      case 'question':
        query = 'How should I assess $topic?';
        break;
      default:
        // Already a full query (new callers pass query text directly).
        query = event.promptType;
    }
    add(AskCopilotQuestion(query: query, topicContext: topic));
  }

  Future<void> _onLanguage(
      SetCopilotLanguage event, Emitter<TeacherCopilotState> emit) async {
    await store.setLanguage(event.language);
  }

  Future<void> _onPick(PickCopilotClarification event,
      Emitter<TeacherCopilotState> emit) async {
    final id = event.knowledgeItemId;
    final stored = await store.getLanguage();
    final lang = stored == CopilotAnswerLanguage.english
        ? AnswerLanguage.english
        : AnswerLanguage.hindi;
    // --- Topic picker (shared engine TOPIC_PICK): store the explicitly
    // chosen topic, then either answer the pending intent directly or ask
    // what help is needed. Never invents content. ---
    if (id.startsWith('topic::')) {
      final topic = id.substring('topic::'.length).trim();
      if (topic.isEmpty) return;
      final conv = store.conversation();
      store.saveConversation(CopilotConversationContext(
        lastIntent: conv.lastIntent ?? _pendingIntent,
        lastTopic: topic,
        lastRoute: conv.lastRoute,
        lastItemId: conv.lastItemId,
      ));
      final pending = _pendingIntent;
      if (pending != null && pending.isNotEmpty) {
        emit(TeacherCopilotThinking());
        final r = await engine.answerForTopicIntent(
          topic: topic,
          intent: pending,
          answerLanguage: lang,
          conversationContext:
              _toConversation(store.conversation()),
        );
        store.saveConversation(_toCopilotContext(r.nextContext));
        _pendingTopic = null;
        _pendingIntent = null;
        emit(_toState(topic, r, lang));
      } else {
        _pendingTopic = topic;
        _pendingIntent = null;
        emit(TeacherCopilotResponse(
          query: topic,
          responseTitle: 'Teaching Guidance',
          responseBody: lang == AnswerLanguage.hindi
              ? TeacherQuestionEngine.helpChoiceHindi
              : TeacherQuestionEngine.helpChoiceEnglish,
          tribalTip: '',
          followUpSuggestions: const [],
          intent: 'HELP_CHOICE',
          isUnknown: false,
          needsClarification: true,
          clarificationOptions: TeacherQuestionEngine.helpIntentOptions()
              .map((o) => CopilotClarificationOption(
                    knowledgeItemId: o.knowledgeItemId,
                    intent: o.intent,
                    label: o.label,
                    route: o.route,
                  ))
              .toList(),
        ));
      }
      return;
    }
    // --- Help choice (shared engine INTENT_PICK): predefined answer for
    // the established (topic, intent) pair. ---
    if (id.startsWith('intent::')) {
      final intent = id.substring('intent::'.length).trim();
      final storedTopic = (store.conversation().lastTopic ?? '').trim();
      final topic = (_pendingTopic ?? '').trim().isEmpty
          ? storedTopic
          : _pendingTopic!.trim();
      if (intent.isEmpty || topic.isEmpty) return;
      emit(TeacherCopilotThinking());
      final r = await engine.answerForTopicIntent(
        topic: topic,
        intent: intent,
        answerLanguage: lang,
        conversationContext: _toConversation(store.conversation()),
      );
      store.saveConversation(_toCopilotContext(r.nextContext));
      _pendingTopic = null;
      _pendingIntent = null;
      emit(_toState('$topic: $intent', r, lang));
      return;
    }
    final pending = _lastClarification;
    if (pending == null) return;
    final opt = pending.clarificationOptions
        .where((o) => o.knowledgeItemId == event.knowledgeItemId);
    if (opt.isEmpty) return;
    final chosen = opt.first;
    // Deterministic pick: return the chosen knowledge item's predefined
    // answer (looked up from the shared engine cache), never generated.
    String answer = pending.answer;
    try {
      // Re-resolve with the chosen option anchored in conversation context
      // so the same deterministic scorer selects its predefined answer.
      final retry = await engine.resolve(
        chosen.knowledgeItemId.replaceAll('_', ' '),
        context: LessonContext(topic: pending.nextContext.lastTopic),
        answerLanguage: lang,
        conversationContext: ConversationContext(
          lastIntent: chosen.intent,
          lastTopic: pending.nextContext.lastTopic,
          lastRoute: chosen.route,
          lastItemId: chosen.knowledgeItemId,
        ),
      );
      if (retry.matched) {
        answer = retry.answer;
      }
    } catch (_) {}
    store.saveConversation(_toCopilotContext(ConversationContext(
      lastIntent: chosen.intent,
      lastTopic: pending.nextContext.lastTopic,
      lastRoute: chosen.route,
      lastItemId: chosen.knowledgeItemId,
    )));
    emit(TeacherCopilotResponse(
      query: chosen.label,
      responseTitle: _titleFor(chosen.intent),
      responseBody: answer,
      tribalTip: chosen.label,
      followUpSuggestions: const [],
      intent: chosen.intent,
      knowledgeItemId: chosen.knowledgeItemId,
      route: chosen.route,
      routeLabel: chosen.label,
      isUnknown: false,
      needsClarification: false,
      clarificationOptions: const [],
    ));
  }

  void _onClear(
      ClearCopilotConversation event, Emitter<TeacherCopilotState> emit) {
    store.clearConversation();
    _lastClarification = null;
    _pendingTopic = null;
    _pendingIntent = null;
    emit(TeacherCopilotInitial());
  }

  TeacherCopilotResponse _toState(
      String query, QuestionResult r, AnswerLanguage lang) {
    if (r.needsClarification) {
      _lastClarification = r;
      _pendingIntent = r.pendingIntent;
      _pendingTopic = null;
      final isTopicPicker = r.clarificationKind == 'topic';
      return TeacherCopilotResponse(
        query: query,
        responseTitle: isTopicPicker ? 'Choose a topic' : 'Which resource?',
        responseBody: r.answer,
        tribalTip: '',
        followUpSuggestions: const [],
        intent: 'CLARIFICATION',
        isUnknown: false,
        needsClarification: true,
        clarificationOptions: r.clarificationOptions
            .map((o) => CopilotClarificationOption(
                  knowledgeItemId: o.knowledgeItemId,
                  intent: o.intent,
                  label: o.label,
                  route: o.route,
                ))
            .toList(),
      );
    }
    if (r.isUnknown) {
      _lastClarification = null;
      return TeacherCopilotResponse(
        query: query,
        responseTitle: 'Offline guidance unavailable',
        responseBody: r.answer,
        tribalTip: '',
        followUpSuggestions: const [
          'Worksheet कैसे बनाएं?',
          'एक activity बताएं',
          'Flashcard बनाएं',
          'Assessment करें',
        ],
        intent: 'UNKNOWN',
        isUnknown: true,
      );
    }
    _lastClarification = null;
    return TeacherCopilotResponse(
      query: query,
      responseTitle: _titleFor(r.intent ?? ''),
      responseBody: r.answer,
      tribalTip: (r.routeLabel ?? '').trim().isEmpty
          ? ''
          : r.routeLabel!.trim(),
      followUpSuggestions: const [],
      intent: r.intent,
      knowledgeItemId: r.knowledgeItemId,
      route: r.route,
      routeLabel: r.routeLabel,
      autoNavigate: r.autoNavigate,
    );
  }

  static String _titleFor(String intent) {
    switch (intent.toUpperCase()) {
      case 'WORKSHEET_GENERATION':
        return 'Worksheet Generator';
      case 'FLASHCARD_GENERATION':
        return 'Flashcard Generator';
      case 'ASSESSMENT':
      case 'ASSESSMENT_GUIDANCE':
        return 'Assessment Guidance';
      case 'LIVE_TRANSLATION':
        return 'Live Classroom Translator';
      case 'DOWNLOADS':
        return 'Downloads';
      case 'PROGRESS':
        return 'Progress';
      case 'SETTINGS':
        return 'Settings';
      case 'SUBJECT_PLANNING':
        return 'Subject Planning';
      case 'TEACHING_METHOD':
      case 'ACTIVITY':
      case 'EXAMPLE':
      case 'EXPLANATION':
      case 'SIMPLIFY':
      case 'CLASSROOM_ACTIVITY':
      case 'COMMON_DIFFICULTY':
      case 'TEACHER_GUIDANCE':
        return 'Teaching Guidance';
      default:
        return intent.isEmpty ? 'Co-Pilot' : intent;
    }
  }

  static ConversationContext _toConversation(CopilotConversationContext c) {
    return ConversationContext(
      lastIntent: c.lastIntent,
      lastTopic: c.lastTopic,
      lastRoute: c.lastRoute,
      lastItemId: c.lastItemId,
    );
  }

  static CopilotConversationContext _toCopilotContext(
      ConversationContext c) {
    return CopilotConversationContext(
      lastIntent: c.lastIntent,
      lastTopic: c.lastTopic,
      lastRoute: c.lastRoute,
      lastItemId: c.lastItemId,
    );
  }
}
