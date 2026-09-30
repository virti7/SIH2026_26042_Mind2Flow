import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../app/di/injection.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/auth/services/current_user_service.dart';
import '../../../../core/config/api_config.dart';
import '../../../../core/constants/worksheet_languages.dart';
import '../../../../core/database/account_scope.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/enums/app_enums.dart';
import '../../../../core/models/app_models.dart';
import '../../../../core/network/connectivity_service.dart';
import '../../../../core/sync/remote_content_data_source.dart';
import '../../../../core/sync/worksheet_download_store.dart';
import '../../../../core/sync/worksheet_generation_sync.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/chips.dart';
import '../../../../core/widgets/custom_card.dart';
import '../../../../core/widgets/responsive_form_row.dart';
import '../../../../core/worksheet_template/worksheet_template.dart';
import '../bloc/content_generation_bloc.dart';
import '../bloc/flashcard_bloc.dart';
import '../bloc/worksheet_bloc.dart';
import '../widgets/generation_progress_dialog.dart';
import '../widgets/prototype_offline_card.dart';
import '../widgets/worksheet_form_options.dart';
import '../widgets/worksheet_print_preview.dart';
import '../widgets/worksheet_template_view.dart';

// SCREEN 27: Topic / Resource Detail
class TopicResourceDetailScreen extends StatelessWidget {
  const TopicResourceDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Topic / Resource Detail',
      subtitle: 'Explore comprehensive lesson resources in multiple languages with teaching notes, activities, and audio support.',
      breadcrumb: 'Class 2 > Mathematics',
      isScrollable: true,
      bottomActionBar: LayoutBuilder(
        builder: (context, constraints) {
          final narrow =
              constraints.maxWidth.isFinite && constraints.maxWidth < 480;
          return ResponsiveBottomActions(
            secondary: SecondaryButton(
              label: 'Previous',
              onPressed: () => context.pop(),
            ),
            primary: PrimaryButton(
              // Responsive label: short on narrow phones, full on tablet.
              label: narrow
                  ? 'Bilingual Worksheet'
                  : 'Bilingual Worksheet Generator',
              trailingIcon: Icons.arrow_forward_rounded,
              onPressed: () => context.push(AppRoutes.worksheetGenerator),
            ),
          );
        },
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Topic Header Box
          CustomCard(
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: AppColors.greenLight, borderRadius: AppRadius.radiusPill),
                      child: Text('MATHEMATICS', style: AppTypography.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
                    ),
                    Text('Unit 2 • Topic 1', style: AppTypography.caption),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Numbers up to 100', style: AppTypography.screenTitle.copyWith(fontSize: 20)),
                Text('Recognize, read and write numbers up to 100 using local objects', style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: 14),

                // Learning Outcomes Pill Box — white card, green icon
                CustomCard(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.verified_rounded, color: AppColors.primary, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Learning Outcomes:', style: AppTypography.cardTitle.copyWith(fontSize: 13, color: AppColors.primaryDark)),
                            const SizedBox(height: 2),
                            Text('• Counts and compares objects up to 100\n• Reads and writes 2-digit numerals in Hindi & tribal words\n• Understands place value (tens and units)', style: AppTypography.bodySmall),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Metadata Stats Row (responsive: 4-across on tablet,
                // 2x2 wrap on narrow phones — never overflows).
                LayoutBuilder(
                  builder: (context, constraints) {
                    final narrow = constraints.maxWidth.isFinite &&
                        constraints.maxWidth < 480;
                    if (!narrow) {
                      return Row(
                        children: [
                          Expanded(
                            child: _buildMetaStat(Icons.school_outlined,
                                'Class', 'Class 2'),
                          ),
                          Expanded(
                            child: _buildMetaStat(Icons.menu_book_outlined,
                                'Subject', 'Math FLN'),
                          ),
                          Expanded(
                            child: _buildMetaStat(Icons.access_time_rounded,
                                'Duration', '20–25 mins'),
                          ),
                          Expanded(
                            child: _buildMetaStat(Icons.speed_rounded,
                                'Difficulty', 'Medium'),
                          ),
                        ],
                      );
                    }
                    return Wrap(
                      spacing: 8,
                      runSpacing: 12,
                      children: [
                        SizedBox(
                          width: (constraints.maxWidth - 8) / 2,
                          child: _buildMetaStat(
                              Icons.school_outlined, 'Class', 'Class 2'),
                        ),
                        SizedBox(
                          width: (constraints.maxWidth - 8) / 2,
                          child: _buildMetaStat(
                              Icons.menu_book_outlined, 'Subject', 'Math FLN'),
                        ),
                        SizedBox(
                          width: (constraints.maxWidth - 8) / 2,
                          child: _buildMetaStat(Icons.access_time_rounded,
                              'Duration', '20–25 mins'),
                        ),
                        SizedBox(
                          width: (constraints.maxWidth - 8) / 2,
                          child: _buildMetaStat(Icons.speed_rounded,
                              'Difficulty', 'Medium'),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          Text('Available Resources', style: AppTypography.sectionTitle),
          const SizedBox(height: 10),

          _buildResourceItem(
            icon: Icons.description_outlined,
            title: 'Teacher Lesson Script',
            subtitle: 'Step-by-step teaching guide with dialogue cues',
            size: 'PDF • 2.4 MB',
            color: AppColors.primary,
            onTap: () => context.push(AppRoutes.lessonPlanner),
          ),
          const SizedBox(height: 10),
          _buildResourceItem(
            icon: Icons.volume_up_outlined,
            title: 'Audio Explanation',
            subtitle: 'Voice audio in Hindi + Ho + Mundari + Santali',
            size: 'Audio • 4.1 MB',
            color: AppColors.accentBlue,
            onTap: () => context.push(AppRoutes.translate),
          ),
          const SizedBox(height: 10),
          _buildResourceItem(
            icon: Icons.lightbulb_outline_rounded,
            title: 'Teaching Notes',
            subtitle: 'Pedagogical guidance for non-native teachers',
            size: 'Notes • 850 KB',
            color: AppColors.accentAmber,
            onTap: () => context.push(AppRoutes.teacherCopilot),
          ),
          const SizedBox(height: 10),
          _buildResourceItem(
            icon: Icons.style_outlined,
            title: 'Visual Flashcards',
            subtitle: 'Images, symbol cards and manipulatives',
            size: '12 Cards • 3.2 MB',
            color: AppColors.accentOrange,
            onTap: () => context.push(AppRoutes.flashcardGenerator),
          ),
          const SizedBox(height: 10),
          _buildResourceItem(
            icon: Icons.assignment_outlined,
            title: 'Bilingual Worksheet',
            subtitle: 'Printable practice exercises with answer spaces',
            size: 'PDF • 1.6 MB',
            color: AppColors.primary,
            onTap: () => context.push(AppRoutes.worksheetGenerator),
          ),
          const SizedBox(height: 10),
          // Deterministic offline prototype path (bundled assets only).
          const PrototypeOfflineCard(
            className: 'Class 2',
            subject: 'Mathematics',
            topic: 'Numbers up to 100',
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildMetaStat(IconData icon, String label, String value) {
    // No Expanded here: callers decide (Expanded in wide Row,
    // fixed-width SizedBox in narrow Wrap) so both modes stay overflow-free.
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(height: 4),
        Text(label,
            style: AppTypography.caption,
            textAlign: TextAlign.center,
            softWrap: true),
        Text(value,
            style: AppTypography.chipLabel.copyWith(fontSize: 11),
            textAlign: TextAlign.center,
            softWrap: true,
            maxLines: 2,
            overflow: TextOverflow.ellipsis),
      ],
    );
  }

  Widget _buildResourceItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required String size,
    required Color color,
    required VoidCallback onTap,
  }) {
    return CustomCard(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: AppRadius.radiusMd),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: AppTypography.cardTitle.copyWith(fontSize: 14),
                    softWrap: true),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: AppTypography.caption, softWrap: true),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Trailing metadata: constrained so long size strings wrap
          // instead of pushing the arrow off-screen.
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 92),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(size,
                    style: AppTypography.caption.copyWith(
                        fontSize: 10, color: AppColors.textMuted),
                    textAlign: TextAlign.end,
                    softWrap: true,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                const Icon(Icons.arrow_forward_ios_rounded,
                    size: 12, color: AppColors.textMuted),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// SCREEN 28: Bilingual Worksheet Generator
class BilingualWorksheetGeneratorScreen extends StatefulWidget {
  const BilingualWorksheetGeneratorScreen({super.key});

  @override
  State<BilingualWorksheetGeneratorScreen> createState() => _BilingualWorksheetGeneratorScreenState();
}

class _BilingualWorksheetGeneratorScreenState extends State<BilingualWorksheetGeneratorScreen> {
  // ---- Dynamic form state (all values flow into the generation request) ----
  List<int> _classes = const [1, 2, 3, 4, 5];
  int _grade = 2;
  List<String> _sections = const ['A', 'B', 'C', 'General'];
  String _section = 'A';
  List<String> _subjects = const ['Mathematics'];
  String _subject = 'Mathematics';

  // Topic: curriculum selection OR custom free text.
  bool _useCustomTopic = false;
  List<CurriculumTopic> _topics = const [];
  CurriculumTopic? _selectedTopic;
  final TextEditingController _customTopicController = TextEditingController();
  String _topicInputLanguage = 'en'; // 'hi' | 'en'
  bool _optionsLoading = true;

  // Bilingual pair (five languages).
  String _language1 = 'hi';
  String _language2 = 'sat';

  // Question count + validation.
  final TextEditingController _questionCountController =
      TextEditingController(text: '10');
  String? _questionCountError;

  // Multi-select worksheet types.
  Set<WorksheetType> _selectedTypes = {WorksheetType.practice};

  DifficultyLevel _difficulty = DifficultyLevel.medium;

  bool _includeVisuals = true;
  bool _bilingualAnswers = true;
  bool _audioPronounce = false;

  @override
  void initState() {
    super.initState();
    _loadOptions();
    _questionCountController.addListener(_validateQuestionCount);
  }

  @override
  void dispose() {
    _customTopicController.dispose();
    _questionCountController.dispose();
    super.dispose();
  }

  Future<void> _loadOptions() async {
    try {
      final db = getIt<AppDatabase>();
      final classes = await WorksheetFormOptions.loadClasses(db);
      if (!mounted) return;
      setState(() {
        _classes = classes;
        if (!_classes.contains(_grade)) _grade = _classes.first;
      });
      await _loadSectionsAndSubjects();
    } catch (_) {
      if (mounted) setState(() => _optionsLoading = false);
    }
  }

  Future<void> _loadSectionsAndSubjects() async {
    try {
      final db = getIt<AppDatabase>();
      final sections =
          await WorksheetFormOptions.loadSections(db, _grade);
      final subjects = await WorksheetFormOptions.loadSubjects(db);
      if (!mounted) return;
      setState(() {
        _sections = sections;
        if (!_sections.contains(_section)) _section = _sections.first;
        if (subjects.isNotEmpty) {
          _subjects = subjects;
          if (!_subjects.contains(_subject)) _subject = _subjects.first;
        }
      });
      await _loadTopics();
    } catch (_) {
      if (mounted) setState(() => _optionsLoading = false);
    }
  }

  Future<void> _loadTopics() async {
    try {
      final db = getIt<AppDatabase>();
      final topics =
          await WorksheetFormOptions.loadTopics(db, _grade, _subject);
      if (!mounted) return;
      setState(() {
        _topics = topics;
        if (_topics.isNotEmpty) {
          if (_selectedTopic == null ||
              !_topics.any((t) => t.id == _selectedTopic!.id)) {
            _selectedTopic = _topics.first;
          }
        } else {
          _selectedTopic = null;
        }
        _optionsLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _optionsLoading = false);
    }
  }

  void _validateQuestionCount() {
    final raw = _questionCountController.text.trim();
    final value = int.tryParse(raw);
    setState(() {
      if (value == null) {
        _questionCountError = 'Enter a whole number (e.g. 10).';
      } else if (value < 1 || value > 50) {
        _questionCountError = 'Number of questions must be between 1 and 50.';
      } else {
        _questionCountError = null;
      }
    });
  }

  int get _questionCount =>
      int.tryParse(_questionCountController.text.trim()) ?? 10;

  /// Effective topic text + source + NIPUN outcome for the request.
  /// Curriculum topics carry official metadata; custom topics preserve the
  /// teacher's text exactly with nipunOutcome null (never fabricated).
  ({String topic, String source, String? topicId, String? nipun}) _topicParts() {
    if (_useCustomTopic) {
      return (
        topic: _customTopicController.text.trim(),
        source: 'custom',
        topicId: null,
        nipun: null,
      );
    }
    final t = _selectedTopic;
    if (t == null) {
      return (topic: '', source: 'curriculum', topicId: null, nipun: null);
    }
    return (topic: t.title, source: 'curriculum', topicId: t.id, nipun: t.code);
  }

  String? _formError() {
    if (_language1 == _language2) {
      return 'Please choose two different languages for the bilingual worksheet.';
    }
    if (_questionCountError != null) return _questionCountError;
    final parts = _topicParts();
    if (_useCustomTopic && parts.topic.isEmpty) {
      return 'Please enter your topic, or choose one from the curriculum list.';
    }
    if (!_useCustomTopic && parts.topic.isEmpty) {
      return 'Please select a topic for Class $_grade • $_subject.';
    }
    if (_selectedTypes.isEmpty) {
      return 'Please select at least one worksheet type.';
    }
    return null;
  }

  String _generateLabel(ContentGenerationState state) {
    if (state is ContentGenerationCheckingConnectivity ||
        state is ContentGenerationSubmitting) {
      return 'Sending Request...';
    }
    if (state is ContentGenerationInProgress ||
        state is ContentGenerationDownloading) {
      return 'Generating Worksheet...';
    }
    if (state is ContentGenerationStillWaiting) {
      return 'Still Generating...';
    }
    if (state is ContentGenerationQueuedOffline) {
      return 'Saved for Sync';
    }
    if (state is ContentGenerationFailed) {
      return 'Retry Generation';
    }
    return 'Generate Bilingual Worksheet';
  }

  bool _isGenerateBusy(ContentGenerationState state) {
    return state is ContentGenerationCheckingConnectivity ||
        state is ContentGenerationSubmitting ||
        state is ContentGenerationInProgress ||
        state is ContentGenerationDownloading ||
        state is ContentGenerationStillWaiting;
  }

  Future<void> _onGenerate(BuildContext ctx) async {
    final bloc = ctx.read<ContentGenerationBloc>();
    if (_isGenerateBusy(bloc.state)) return;

    final formError = _formError();
    if (formError != null) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(content: Text(formError)),
      );
      return;
    }

    final connectivity = getIt<ConnectivityService>();
    final isOnline = await connectivity.isOnline;
    final isReachable = isOnline && await connectivity.checkBackendReachability();

    if (!ctx.mounted) return;

    // Safe diagnostics only (never shown in teacher UI, never secrets):
    // platform, device internet state, ACTUAL backend URL probed, backend
    // reachability, data source, generation mode. `online` (device internet)
    // and `backendReachable` (FastAPI health) are independent states.
    if (kDebugMode) {
      debugPrint(
        '[WorksheetGenerate] platform=${kIsWeb ? 'web' : 'native'} '
        'networkOnline=$isOnline backendUrl=${ApiConfig.baseUrl} '
        'backendReachable=$isReachable '
        'remote=${bloc.remoteDataSource.runtimeType} '
        'mode=${isReachable ? 'online-http' : 'offline-queued'}',
      );
    }

    // Request built directly from the teacher's on-screen selections.
    // Custom topic text is sent exactly as entered (never translated here).
    final parts = _topicParts();
    final request = buildWorksheetGenerationRequest(
      grade: _grade,
      section: _section,
      subject: _subject,
      topic: parts.topic,
      topicSource: parts.source,
      topicId: parts.topicId,
      topicInputLanguage: _topicInputLanguage,
      nipunOutcome: parts.nipun,
      language1: _language1,
      language2: _language2,
      difficulty: _difficulty,
      types: _selectedTypes.toList(),
      questionCount: _questionCount,
      visualSupport: _includeVisuals,
      bilingualAnswers: _bilingualAnswers,
      audioCue: _audioPronounce,
      deviceId: 'tablet_jharkhand_001',
      origin: isReachable ? 'online' : 'offline',
    );

    void openProgress({String? queuedMessage}) {
      GenerationProgressDialog.show(
        ctx,
        queuedMessage: queuedMessage,
        onCompleted: () {
          if (!ctx.mounted) return;
          Navigator.of(ctx, rootNavigator: true).pop();
          ctx.push(AppRoutes.worksheetPreview);
        },
      );
    }

    if (!isOnline) {
      // A. DEVICE OFFLINE: queue locally. No remote call is attempted.
      // No success message here: the progress dialog reports the real
      // outcome (saved vs. couldn't-save) once persistence completes.
      bloc.add(QueueOfflineGenerationEvent(request: request));
      openProgress();
      return;
    }

    if (!isReachable) {
      // B. ONLINE + BACKEND UNREACHABLE: save locally for later. The
      // dialog confirms the actual queue outcome; the override message
      // explains the server (not the device) is the problem.
      bloc.add(QueueOfflineGenerationEvent(request: request));
      openProgress(
        queuedMessage: 'Server is currently unavailable. Your request has '
            'been saved and will be generated when the server is reachable.',
      );
      return;
    }

    // C. ONLINE + BACKEND REACHABLE: generate immediately via HTTP.
    // The request is NOT queued locally first.

    bloc.add(
      StartContentGenerationEvent(
        request: request,
        idempotencyKey: request.requestId,
      ),
    );

    openProgress();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ContentGenerationBloc>(),
      child: Builder(
        builder: (ctx) => AppScaffold(
          title: 'Bilingual Worksheet Generator',
          subtitle: 'Create customized worksheets in multiple languages aligned with NIPUN Bharat learning outcomes.',
          breadcrumb: 'Class $_grade > $_subject',
          isScrollable: true,
          bottomActionBar: BlocBuilder<ContentGenerationBloc, ContentGenerationState>(
            builder: (context, state) {
              final busy = _isGenerateBusy(state);
              return PrimaryButton(
                label: _generateLabel(state),
                trailingIcon: Icons.auto_awesome_rounded,
                onPressed: busy ? null : () => _onGenerate(ctx),
              );
            },
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          // Offline prototype entry (bundled assets only, no network).
          PrototypeOfflineCard(
            className: 'Class $_grade',
            subject: _subject,
            topic: _useCustomTopic
                ? _customTopicController.text.trim()
                : (_selectedTopic?.title ?? ''),
          ),
          const SizedBox(height: 14),
          // 1. Class + Section (dynamic from classroom data).
          CustomCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('1. Class + Section', style: AppTypography.cardTitle.copyWith(fontSize: 14)),
                const SizedBox(height: 8),
                ResponsiveFormRow(
                  first: DropdownButtonFormField<int>(
                    value: _grade,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Class'),
                    items: _classes
                        .map((c) => DropdownMenuItem(value: c, child: Text('Class $c', overflow: TextOverflow.ellipsis)))
                        .toList(),
                    onChanged: (v) async {
                      if (v == null) return;
                      setState(() {
                        _grade = v;
                        _optionsLoading = true;
                        _selectedTopic = null;
                      });
                      await _loadSectionsAndSubjects();
                    },
                  ),
                  second: DropdownButtonFormField<String>(
                    value: _sections.contains(_section) ? _section : null,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Section'),
                    items: _sections
                        .map((s) => DropdownMenuItem(value: s, child: Text(s, overflow: TextOverflow.ellipsis)))
                        .toList(),
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() => _section = v);
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 2. Subject (dynamic from curriculum data).
          CustomCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('2. Subject', style: AppTypography.cardTitle.copyWith(fontSize: 14)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _subjects.contains(_subject) ? _subject : null,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Subject'),
                  items: _subjects
                      .map((s) => DropdownMenuItem(value: s, child: Text(s, overflow: TextOverflow.ellipsis)))
                      .toList(),
                  onChanged: (v) async {
                    if (v == null) return;
                    setState(() {
                      _subject = v;
                      _optionsLoading = true;
                      _selectedTopic = null;
                    });
                    await _loadTopics();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 3. Topic / Skill: curriculum select OR custom text.
          CustomCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('3. Topic / Skill', style: AppTypography.cardTitle.copyWith(fontSize: 14)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const Center(child: Text('Select from curriculum')),
                        selected: !_useCustomTopic,
                        selectedColor: AppColors.primary,
                        backgroundColor: Colors.white,
                        labelStyle: TextStyle(
                            color: !_useCustomTopic ? Colors.white : AppColors.textPrimary,
                            fontSize: 12),
                        shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusPill),
                        onSelected: (v) {
                          if (v) setState(() => _useCustomTopic = false);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ChoiceChip(
                        label: const Center(child: Text('Enter your own topic')),
                        selected: _useCustomTopic,
                        selectedColor: AppColors.primary,
                        backgroundColor: Colors.white,
                        labelStyle: TextStyle(
                            color: _useCustomTopic ? Colors.white : AppColors.textPrimary,
                            fontSize: 12),
                        shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusPill),
                        onSelected: (v) {
                          if (v) setState(() => _useCustomTopic = true);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (!_useCustomTopic)
                  _optionsLoading
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                        )
                      : _topics.isEmpty
                          ? Text(
                              'No curriculum topics found for Class $_grade • $_subject. '
                              'Enter your own topic below.',
                              style: AppTypography.caption)
                          : DropdownButtonFormField<String>(
                              value: _selectedTopic?.id,
                              isExpanded: true,
                              decoration: const InputDecoration(labelText: 'Topic / Skill'),
                              items: _topics
                                  .map((t) => DropdownMenuItem(
                                        value: t.id,
                                        child: Text('${t.title} (${t.code})',
                                            overflow: TextOverflow.ellipsis),
                                      ))
                                  .toList(),
                              onChanged: (v) {
                                if (v == null) return;
                                setState(() => _selectedTopic =
                                    _topics.firstWhere((t) => t.id == v));
                              },
                            ),
                if (!_useCustomTopic && _selectedTopic != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                          color: AppColors.greenSurface, borderRadius: AppRadius.radiusMd),
                      child: Text('NIPUN Code: ${_selectedTopic!.code}',
                          style: AppTypography.caption),
                    ),
                  ),
                if (_useCustomTopic)
                  TextField(
                    controller: _customTopicController,
                    decoration: const InputDecoration(
                      labelText: 'Enter your own topic',
                      hintText: 'e.g. दो अंकों की जोड़ / Addition of two-digit numbers',
                    ),
                    maxLines: 2,
                    onChanged: (_) => setState(() {}),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 4. Topic input language (Hindi / English).
          CustomCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('4. Topic Input Language', style: AppTypography.cardTitle.copyWith(fontSize: 14)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const Center(child: Text('Hindi')),
                        selected: _topicInputLanguage == 'hi',
                        selectedColor: AppColors.primary,
                        backgroundColor: Colors.white,
                        labelStyle: TextStyle(
                            color: _topicInputLanguage == 'hi'
                                ? Colors.white
                                : AppColors.textPrimary),
                        shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusPill),
                        onSelected: (v) {
                          if (v) setState(() => _topicInputLanguage = 'hi');
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ChoiceChip(
                        label: const Center(child: Text('English')),
                        selected: _topicInputLanguage == 'en',
                        selectedColor: AppColors.primary,
                        backgroundColor: Colors.white,
                        labelStyle: TextStyle(
                            color: _topicInputLanguage == 'en'
                                ? Colors.white
                                : AppColors.textPrimary),
                        shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusPill),
                        onSelected: (v) {
                          if (v) setState(() => _topicInputLanguage = 'en');
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 5. Bilingual language pair (five languages, must differ).
          // ROOT CAUSE of the "RIGHT OVERFLOWED BY 35 PIXELS": a fixed
          // Row of two Expanded DropdownButtonFormField with
          // isExpanded=false. The selected value (e.g. "Santali (संथाली)")
          // plus InputDecoration padding has an intrinsic min-width wider
          // than half a 360-400px phone, so the Row overflows. Fix:
          // isExpanded:true + ellipsis selected-item builders (keeps the
          // arrow visible, never clips the language name to unreadable),
          // and stack vertically on narrow phones via ResponsiveFormRow.
          CustomCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('5. Worksheet Languages (bilingual pair)',
                    style: AppTypography.cardTitle.copyWith(fontSize: 14)),
                const SizedBox(height: 8),
                ResponsiveFormRow(
                  first: DropdownButtonFormField<String>(
                    value: _language1,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Language 1',
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                    ),
                    selectedItemBuilder: (context) =>
                        WorksheetLanguages.all
                            .map((l) => Align(
                                  alignment: AlignmentDirectional.centerStart,
                                  child: Text(
                                      '${l.displayName} (${l.nativeName})',
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1),
                                ))
                            .toList(),
                    items: WorksheetLanguages.all
                        .map((l) => DropdownMenuItem(
                              value: l.code,
                              child: Text('${l.displayName} (${l.nativeName})',
                                  overflow: TextOverflow.ellipsis),
                            ))
                        .toList(),
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() => _language1 = v);
                    },
                  ),
                  second: DropdownButtonFormField<String>(
                    value: _language2,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Language 2',
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                    ),
                    selectedItemBuilder: (context) =>
                        WorksheetLanguages.all
                            .map((l) => Align(
                                  alignment: AlignmentDirectional.centerStart,
                                  child: Text(
                                      '${l.displayName} (${l.nativeName})',
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1),
                                ))
                            .toList(),
                    items: WorksheetLanguages.all
                        .map((l) => DropdownMenuItem(
                              value: l.code,
                              child: Text('${l.displayName} (${l.nativeName})',
                                  overflow: TextOverflow.ellipsis),
                            ))
                        .toList(),
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() => _language2 = v);
                    },
                  ),
                ),
                if (_language1 == _language2)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      'Language 1 and Language 2 must be different.',
                      style: AppTypography.caption
                          .copyWith(color: AppColors.accentRed),
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      'Worksheet will contain both: '
                      '${WorksheetLanguages.displayPair(_language1, _language2)}.',
                      style: AppTypography.caption,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 6. Number of questions.
          CustomCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('6. Number of Questions', style: AppTypography.cardTitle.copyWith(fontSize: 14)),
                const SizedBox(height: 8),
                TextField(
                  controller: _questionCountController,
                  decoration: InputDecoration(
                    labelText: 'Number of questions (1–50)',
                    errorText: _questionCountError,
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 7. Worksheet type(s): multi-select.
          CustomCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('7. Worksheet Type(s) — select one or more',
                    style: AppTypography.cardTitle.copyWith(fontSize: 14)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: WorksheetType.values.map((t) {
                    final isSel = _selectedTypes.contains(t);
                    return FilterChip(
                      label: Text(t.title),
                      selected: isSel,
                      selectedColor: AppColors.primary,
                      backgroundColor: Colors.white,
                      checkmarkColor: Colors.white,
                      labelStyle: TextStyle(
                          color: isSel ? Colors.white : AppColors.textPrimary,
                          fontSize: 12),
                      shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusPill),
                      onSelected: (val) {
                        setState(() {
                          if (val) {
                            _selectedTypes.add(t);
                          } else {
                            _selectedTypes.remove(t);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                if (_selectedTypes.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text('Select at least one worksheet type.',
                        style: AppTypography.caption
                            .copyWith(color: AppColors.accentRed)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 8. Difficulty Level
          CustomCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('8. Difficulty Level', style: AppTypography.cardTitle.copyWith(fontSize: 14)),
                const SizedBox(height: 8),
                Row(
                  children: DifficultyLevel.values.map((d) {
                    final isSel = _difficulty == d;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ChoiceChip(
                          label: Center(child: Text(d.label)),
                          selected: isSel,
                          selectedColor: AppColors.primary,
                          backgroundColor: Colors.white,
                          labelStyle: TextStyle(color: isSel ? Colors.white : AppColors.textPrimary),
                          shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusPill),
                          onSelected: (val) {
                            if (val) setState(() => _difficulty = d);
                          },
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 9. Additional Options
          CustomCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('9. Additional Options', style: AppTypography.cardTitle.copyWith(fontSize: 14)),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Include Visual Illustrations', style: AppTypography.bodySmall),
                  subtitle: Text('Adds picture cues to counting questions where supported.',
                      style: AppTypography.caption),
                  value: _includeVisuals,
                  activeTrackColor: AppColors.primaryLight,
                  activeThumbColor: AppColors.primary,
                  onChanged: (val) => setState(() => _includeVisuals = val),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Bilingual Answer Spaces', style: AppTypography.bodySmall),
                  subtitle: Text('Answer spaces for both worksheet languages.',
                      style: AppTypography.caption),
                  value: _bilingualAnswers,
                  activeTrackColor: AppColors.primaryLight,
                  activeThumbColor: AppColors.primary,
                  onChanged: (val) => setState(() => _bilingualAnswers = val),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Audio Pronunciation Cue', style: AppTypography.bodySmall),
                  subtitle: Text('Pronunciation hints where the device supports audio.',
                      style: AppTypography.caption),
                  value: _audioPronounce,
                  activeTrackColor: AppColors.primaryLight,
                  activeThumbColor: AppColors.primary,
                  onChanged: (val) => setState(() => _audioPronounce = val),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    ),
  ),
);
}
}

// SCREEN 29: Worksheet Preview
class WorksheetPreviewScreen extends StatefulWidget {
  const WorksheetPreviewScreen({super.key});

  @override
  State<WorksheetPreviewScreen> createState() => _WorksheetPreviewScreenState();
}

class _WorksheetPreviewScreenState extends State<WorksheetPreviewScreen> {
  final Future<WorksheetTemplate> _template = WorksheetTemplate.load();
  bool _downloading = false;
  WorksheetDownload? _downloaded;

  @override
  void initState() {
    super.initState();
    _refreshDownloadState();
  }

  Future<void> _refreshDownloadState() async {
    try {
      final bloc = context.read<WorksheetBloc>();
      final state = bloc.state;
      if (state is! WorksheetGenerated) return;
      final contentId = state.contentId ?? state.worksheet.id;
      final store = await _downloadStore();
      final existing = await store.getByResourceId(contentId);
      if (mounted && existing != null) {
        setState(() => _downloaded = existing);
      }
    } catch (_) {}
  }

  Future<WorksheetDownloadStore> _downloadStore() async {
    if (getIt.isRegistered<WorksheetDownloadStore>()) {
      return getIt<WorksheetDownloadStore>();
    }
    AppDatabase? db;
    try {
      db = getIt.isRegistered<AppDatabase>() ? getIt<AppDatabase>() : null;
    } catch (_) {
      db = null;
    }
    if (db != null) {
      // Degraded boot: still scope by account instead of global visibility.
      try {
        if (getIt.isRegistered<CurrentUserService>()) {
          final svc = getIt<CurrentUserService>();
          return DriftWorksheetDownloadStore(db,
              currentUserIdProvider: () => svc.currentUserId);
        }
      } catch (_) {}
    }
    return resolveDownloadStore(database: db);
  }

  /// Full server payload for download/metadata. Prefers the payload carried
  /// with the preview state; falls back to the SavedMaterial row (native
  /// SQLite, offline-safe) — but only when that row is claimed by the
  /// CURRENT teacher, so preview/download can never reach across accounts;
  /// last resort reconstructs from the visible worksheet (real questions,
  /// reduced metadata).
  Future<Map<String, dynamic>?> _payloadFor(WorksheetGenerated state) async {
    if (state.contentPayload != null && state.contentPayload!.isNotEmpty) {
      return Map<String, dynamic>.from(state.contentPayload!);
    }
    final contentId = state.contentId ?? state.worksheet.id;
    try {
      if (getIt.isRegistered<AppDatabase>()) {
        final db = getIt<AppDatabase>();
        String? ownerId;
        try {
          ownerId = getIt.isRegistered<CurrentUserService>()
              ? getIt<CurrentUserService>().currentUserId
              : null;
        } catch (_) {
          ownerId = null;
        }
        await ensureAccountIsolation(db);
        final owned = await ownedEntityIds(
          db,
          entityType: 'saved_material',
          ownerId: ownerId,
        );
        final row =
            await db.resourceDao.getOwnedSavedMaterialById(contentId, owned);
        if (row != null && row.contentJson.isNotEmpty) {
          final decoded = jsonDecode(row.contentJson);
          if (decoded is Map<String, dynamic> && decoded.isNotEmpty) {
            return decoded;
          }
        }
      }
    } catch (_) {}
    return _reconstructFromWorksheet(state.worksheet, contentId);
  }

  Map<String, dynamic> _reconstructFromWorksheet(
      WorksheetItem ws, String contentId) {
    return {
      'content_id': contentId,
      'request_id': contentId,
      'title': ws.title,
      'title_hi': ws.titleHi,
      'title_source': ws.titleHi,
      'title_target': ws.title,
      'grade': ws.grade,
      'section': 'General',
      'subject': ws.subject,
      'topic': ws.title,
      'topic_source': 'curriculum',
      'curriculum_id': ws.outcomeCode,
      'nipun_outcome': ws.outcomeCode,
      'source_language': 'hi',
      'target_language': tribalLanguageToServerCode(ws.targetLanguage),
      'language_1': 'hi',
      'language_2': tribalLanguageToServerCode(ws.targetLanguage),
      'difficulty': difficultyToServerCode(ws.difficulty),
      'content_type': 'worksheet',
      'worksheet_type': worksheetTypeToServerCode(ws.type),
      'worksheet_types': [worksheetTypeToServerCode(ws.type)],
      'question_count': ws.questions.length,
      'questions': ws.questions
          .map((q) => {
                'questionNumber': q.questionNumber,
                'promptHindi': q.promptHindi,
                'promptTribal': q.promptTribal,
                'prompt_source': q.promptHindi,
                'prompt_target': q.promptTribal,
                'options': q.options,
                'answer': q.answer,
                'visualIllustration': q.visualIllustration,
                'type': worksheetTypeToServerCode(ws.type),
              })
          .toList(),
    };
  }

  Future<void> _onDownload(WorksheetGenerated state) async {
    if (_downloading) return;
    setState(() => _downloading = true);
    try {
      final payload = await _payloadFor(state);
      if (payload == null || (payload['questions'] as List?).isNullOrEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('No worksheet content to download yet.')),
        );
        return;
      }
      final contentId =
          (state.contentId ?? payload['content_id']?.toString() ?? state.worksheet.id);
      RemoteContentDataSource? remote;
      try {
        remote = getIt<RemoteContentDataSource>();
      } catch (_) {
        remote = null;
      }
      final store = await _downloadStore();
      final record = await downloadWorksheet(
        store: store,
        remote: remote,
        contentId: contentId,
        contentPayload: payload,
        assets: state.assets,
      );
      if (!mounted) return;
      setState(() => _downloaded = record);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Worksheet downloaded and ready for offline use.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Download failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WorksheetBloc, WorksheetState>(
      builder: (context, state) {
        if (state is WorksheetGenerating) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppColors.primary),
                  SizedBox(height: 16),
                  Text('Generating Bilingual NIPUN Worksheet...'),
                ],
              ),
            ),
          );
        }

        if (state is WorksheetGenerated) {
          final ws = state.worksheet;
          final payload = state.contentPayload;
          final langPair = payload != null &&
                  payload['language_1'] != null &&
                  payload['language_2'] != null
              ? WorksheetLanguages.displayPair(
                  payload['language_1'].toString(),
                  payload['language_2'].toString())
              : ws.targetLanguage.displayName;
          final today = DateFormat('d MMM yyyy').format(DateTime.now());
          final downloaded = _downloaded != null;
          return AppScaffold(
            title: 'Worksheet Preview',
            subtitle: 'Review your bilingual worksheet before saving, printing or classroom sharing.',
            breadcrumb: 'Class ${ws.grade} > ${ws.subject}',
            isScrollable: true,
            bottomActionBar: ResponsiveBottomActions(
              secondary: SecondaryButton(
                label: state.isSaved ? 'Saved for Later' : 'Save for Later',
                icon: state.isSaved
                    ? Icons.check_circle_rounded
                    : Icons.bookmark_border_rounded,
                onPressed: () {
                  context.read<WorksheetBloc>().add(SaveWorksheetEvent(ws));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text(
                            'Worksheet saved — find it in Saved Materials.')),
                  );
                },
              ),
              primary: PrimaryButton(
                label: _downloading
                    ? 'Downloading...'
                    : (downloaded
                        ? 'Downloaded — Available Offline'
                        : 'Download Worksheet'),
                icon: downloaded
                    ? Icons.offline_pin_rounded
                    : Icons.download_rounded,
                onPressed: (downloaded || _downloading)
                    ? null
                    : () => _onDownload(state),
              ),
            ),
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (downloaded)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: CustomCard(
                      color: AppColors.greenSurface,
                      child: Row(
                        children: [
                          const Icon(Icons.offline_pin_rounded,
                              color: AppColors.primary, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Downloaded — Available Offline. Open it anytime from Downloads, no internet needed.',
                              style: AppTypography.bodySmall,
                            ),
                          ),
                          TextButton(
                            onPressed: () =>
                                context.push(AppRoutes.downloads),
                            child: const Text('Open Downloads'),
                          ),
                        ],
                      ),
                    ),
                  ),
                // Colourful interactive worksheet, laid out by the reusable
                // JSON template; Print shows the black & white version.
                FutureBuilder<WorksheetTemplate>(
                  future: _template,
                  builder: (context, snap) {
                    if (snap.hasError) {
                      return CustomCard(
                          child: Text('Worksheet layout could not be loaded.',
                              style: AppTypography.bodySmall));
                    }
                    final template = snap.data;
                    if (template == null) {
                      return const Center(
                          child: Padding(
                              padding: EdgeInsets.all(24),
                              child: CircularProgressIndicator(
                                  color: AppColors.primary)));
                    }
                    final document = WorksheetDocument.fromPayload(
                        payload ??
                            _reconstructFromWorksheet(
                                ws, state.contentId ?? ws.id),
                        template);
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                  '${ws.questions.length} questions • $langPair • $today',
                                  style: AppTypography.caption),
                            ),
                            SecondaryButton(
                              label: 'Print',
                              icon: Icons.print_outlined,
                              onPressed: () => showWorksheetPrintPreview(
                                context,
                                template: template,
                                document: document,
                                fileName: state.contentId ?? ws.id,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: AppRadius.radiusLg,
                          child: WorksheetTemplateView(
                            key: ValueKey(state.contentId ?? ws.id),
                            template: template,
                            document: document,
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        }

        return Scaffold(
          body: Center(
            child: PrimaryButton(
              label: 'Open Worksheet Generator',
              onPressed: () => context.push(AppRoutes.worksheetGenerator),
            ),
          ),
        );
      },
    );
  }
}

extension _ListNullCheck on List? {
  bool get isNullOrEmpty => this == null || this!.isEmpty;
}

// SCREEN 30: Visual Flashcard Generator
class VisualFlashcardGeneratorScreen extends StatefulWidget {
  const VisualFlashcardGeneratorScreen({super.key});

  @override
  State<VisualFlashcardGeneratorScreen> createState() => _VisualFlashcardGeneratorScreenState();
}

class _VisualFlashcardGeneratorScreenState extends State<VisualFlashcardGeneratorScreen> {
  String _category = 'Numbers';
  TribalLanguage _lang = TribalLanguage.mundari;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ContentGenerationBloc>(),
      child: Builder(
        builder: (ctx) => AppScaffold(
          title: 'Visual Flashcard Generator',
          subtitle: 'Create engaging visual flashcards with images, sound cues, and tribal vocabulary.',
          breadcrumb: 'Class 2 > Flashcards',
          isScrollable: true,
          bottomActionBar: Row(
            children: [
              Expanded(
                child: SecondaryButton(
                  label: 'View Offline Deck',
                  icon: Icons.offline_pin_rounded,
                  onPressed: () => ctx.push(AppRoutes.flashcardViewer),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: PrimaryButton(
                  label: 'Generate Flashcards',
                  trailingIcon: Icons.auto_awesome_rounded,
                  onPressed: () async {
                    final connectivity = getIt<ConnectivityService>();
                    final isOnline = await connectivity.isOnline;
                    final isReachable = isOnline && await connectivity.checkBackendReachability();
                    if (!isReachable) {
                      if (ctx.mounted) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(
                            content: Text(
                              !isOnline
                                  ? 'You are offline. Flashcards need an internet connection to generate.'
                                  : 'Internet is available, but the server is currently unreachable. '
                                      'Please try again when the server is reachable.',
                            ),
                            backgroundColor: AppColors.accentRed,
                          ),
                        );
                      }
                      return;
                    }

                    if (!ctx.mounted) return;

                    final targetLangCode = _lang == TribalLanguage.santali
                        ? 'sat'
                        : (_lang == TribalLanguage.ho ? 'ho' : 'mundari');

                    final String blueprintId;
                    final String subject;
                    if (_category == 'Numbers') {
                      blueprintId = 'BP-G1-NUM-041-01';
                      subject = 'Mathematics';
                    } else if (_category == 'Animals' || _category == 'Village Tools') {
                      blueprintId = 'BP-G1-LIT-021-01';
                      subject = 'Hindi';
                    } else if (_category == 'Forest Flora') {
                      blueprintId = 'BP-G1-LIT-028-01';
                      subject = 'Hindi';
                    } else {
                      blueprintId = 'BP-G1-LIT-011-01';
                      subject = 'Hindi';
                    }

                    ctx.read<ContentGenerationBloc>().add(
                          StartContentGenerationEvent(
                            request: TeacherGenerationRequestModel(
                              contentType: 'flashcard',
                              grade: 1,
                              subject: subject,
                              curriculumId: blueprintId,
                              outcomeCode: blueprintId,
                              topic: _category,
                              targetLanguage: targetLangCode,
                            ),
                            idempotencyKey: 'gen_fc_${DateTime.now().millisecondsSinceEpoch}',
                          ),
                        );

                    GenerationProgressDialog.show(ctx, onCompleted: () {
                      try {
                        ctx.read<FlashcardBloc>().add(
                              LoadFlashcardsEvent(topic: _category, language: _lang),
                            );
                      } catch (_) {
                        if (getIt.isRegistered<FlashcardBloc>()) {
                          getIt<FlashcardBloc>().add(
                                LoadFlashcardsEvent(topic: _category, language: _lang),
                              );
                        }
                      }
                      ctx.push(AppRoutes.flashcardViewer);
                    });
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
                    Text('Select Vocabulary Category', style: AppTypography.cardTitle.copyWith(fontSize: 14)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      children: ['Numbers', 'Animals', 'Forest Flora', 'Village Tools'].map((cat) {
                        final isSel = _category == cat;
                        return ChoiceChip(
                          label: Text(cat),
                          selected: isSel,
                          selectedColor: AppColors.primary,
                          backgroundColor: Colors.white,
                          labelStyle: TextStyle(color: isSel ? Colors.white : AppColors.textPrimary),
                          onSelected: (val) {
                            if (val) setState(() => _category = cat);
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              CustomCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Select Target Language', style: AppTypography.cardTitle.copyWith(fontSize: 14)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: LanguageChip(
                            language: TribalLanguage.mundari,
                            isSelected: _lang == TribalLanguage.mundari,
                            onTap: () => setState(() => _lang = TribalLanguage.mundari),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: LanguageChip(
                            language: TribalLanguage.ho,
                            isSelected: _lang == TribalLanguage.ho,
                            onTap: () => setState(() => _lang = TribalLanguage.ho),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: LanguageChip(
                            language: TribalLanguage.santali,
                            isSelected: _lang == TribalLanguage.santali,
                            onTap: () => setState(() => _lang = TribalLanguage.santali),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
