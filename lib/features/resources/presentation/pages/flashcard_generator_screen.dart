import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/printing.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/config/api_config.dart';
import '../../../../core/constants/flashcard_languages.dart';
import '../../../../core/content/flashcard/flashcard_image_library.dart';
import '../../../../core/content/flashcard/santali_flashcard_model.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/enums/app_enums.dart';
import '../../../../core/network/connectivity_service.dart';
import '../../../../core/sync/flashcard_image_pdf_writer.dart';
import '../../../../core/sync/flashcard_pdf_writer.dart';
import '../../../../core/sync/worksheet_download_store.dart';
import '../../../../core/sync/worksheet_generation_sync.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/custom_card.dart';
import '../bloc/content_generation_bloc.dart';
import 'generated_flashcard_deck_screen.dart';
import '../widgets/generated_flashcard_card.dart';
import '../widgets/worksheet_form_options.dart';

/// Teach → Flashcards → Generate Flashcards.
///
/// Santali multilingual flashcard generator (Hindi/English/Santali only).
/// Topics covered by the bundled picture library are built on-device from
/// its pictures + printed Santali words (fully offline). Only uncovered
/// topics use the server: Flutter → FastAPI → Sarvam translation → visual
/// resolution → card composer → PDF artifact → preview → download. Offline
/// requests are queued in SQLite/Drift and sync when the backend is back.
/// Previously downloaded sets open fully offline, account-scoped.
class SantaliFlashcardGeneratorScreen extends StatefulWidget {
  const SantaliFlashcardGeneratorScreen({super.key});

  @override
  State<SantaliFlashcardGeneratorScreen> createState() =>
      _SantaliFlashcardGeneratorScreenState();
}

class _SantaliFlashcardGeneratorScreenState
    extends State<SantaliFlashcardGeneratorScreen> {
  // ---- Form state (everything flows into the generation request) ----
  List<int> _classes = const [1, 2, 3, 4, 5];
  int _grade = 1;
  List<String> _sections = const ['A', 'B', 'C', 'General'];
  String _section = 'A';
  List<String> _subjects = const ['Hindi'];
  String _subject = 'Hindi';

  /// Topic source: 'library' (picture library, offline), 'curriculum' or
  /// 'custom'. Curriculum/custom topics still use the picture library when
  /// it covers them; only uncovered topics go to the server (Sarvam).
  String _topicMode = 'library';
  bool get _useCustomTopic => _topicMode == 'custom';
  List<FlashcardLibraryTopic> _libraryTopics = const [];
  FlashcardLibraryTopic? _selectedLibraryTopic;
  bool _libraryLoading = true;
  List<CurriculumTopic> _topics = const [];
  CurriculumTopic? _selectedTopic;
  final TextEditingController _customTopicController = TextEditingController();
  final TextEditingController _outcomeController = TextEditingController();
  String _topicInputLanguage = 'en';
  bool _optionsLoading = true;

  String _languageMode = 'hi_sat';
  String _flashcardType = 'vocabulary';
  final TextEditingController _cardCountController =
      TextEditingController(text: '8');
  String? _cardCountError;
  DifficultyLevel _difficulty = DifficultyLevel.medium;
  String _visualStyle = 'illustrated';
  bool _pronunciation = false;

  // ---- Preview state (actual generated payload, never placeholders) ----
  Map<String, dynamic>? _readyPayload;
  Map<String, dynamic>? _readyAssets;
  String? _readyContentId;
  bool _downloading = false;
  WorksheetDownload? _downloaded;
  String? _failureMessage;

  @override
  void initState() {
    super.initState();
    _loadOptions();
    _loadLibraryTopics();
    _cardCountController.addListener(_validateCardCount);
  }

  FlashcardImageLibrary? get _library {
    try {
      return getIt.isRegistered<FlashcardImageLibrary>()
          ? getIt<FlashcardImageLibrary>()
          : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _loadLibraryTopics() async {
    List<FlashcardLibraryTopic> topics = const [];
    try {
      final lib = _library;
      if (lib != null) {
        topics = List.of(await lib.topics())
          ..sort((a, b) => a.label.compareTo(b.label));
      }
    } catch (_) {
      topics = const [];
    }
    if (!mounted) return;
    setState(() {
      _libraryTopics = topics;
      _selectedLibraryTopic = topics.isEmpty ? null : topics.first;
      if (topics.isEmpty && _topicMode == 'library') _topicMode = 'curriculum';
      _libraryLoading = false;
    });
  }

  @override
  void dispose() {
    _customTopicController.dispose();
    _outcomeController.dispose();
    _cardCountController.dispose();
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
      final sections = await WorksheetFormOptions.loadSections(db, _grade);
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
      final topics = await WorksheetFormOptions.loadTopics(db, _grade, _subject);
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

  void _validateCardCount() {
    final value = int.tryParse(_cardCountController.text.trim());
    setState(() {
      if (value == null) {
        _cardCountError = 'Enter a whole number (e.g. 8).';
      } else if (value < 1 || value > 20) {
        _cardCountError = 'Number of cards must be between 1 and 20.';
      } else {
        _cardCountError = null;
      }
    });
  }

  int get _cardCount => int.tryParse(_cardCountController.text.trim()) ?? 8;

  ({String topic, String source, String? topicId, String? nipun}) _topicParts() {
    if (_topicMode == 'library') {
      final t = _selectedLibraryTopic;
      final customNipun = _outcomeController.text.trim();
      return (
        topic: t?.label ?? '',
        source: kTopicSourceCatalog,
        topicId: t?.id,
        nipun: customNipun.isEmpty ? null : customNipun,
      );
    }
    if (_useCustomTopic) {
      return (
        topic: _customTopicController.text.trim(),
        source: 'custom',
        topicId: null,
        nipun: _outcomeController.text.trim().isEmpty
            ? null
            : _outcomeController.text.trim(),
      );
    }
    final t = _selectedTopic;
    if (t == null) {
      return (topic: '', source: 'curriculum', topicId: null, nipun: null);
    }
    final customNipun = _outcomeController.text.trim();
    return (
      topic: t.title,
      source: 'curriculum',
      topicId: t.id,
      nipun: customNipun.isEmpty ? t.code : customNipun,
    );
  }

  String? _formError() {
    if (_cardCountError != null) return _cardCountError;
    final parts = _topicParts();
    if (_topicMode == 'library' && parts.topic.isEmpty) {
      return 'Please choose a topic from the picture library.';
    }
    if (_useCustomTopic && parts.topic.isEmpty) {
      return 'Please enter your topic, or choose one from the curriculum list.';
    }
    if (!_useCustomTopic && parts.topic.isEmpty) {
      return 'Please select a topic for Class $_grade • $_subject.';
    }
    return null;
  }

  Future<void> _onGenerate(BuildContext ctx) async {
    final bloc = ctx.read<ContentGenerationBloc>();
    if (bloc.state is ContentGenerationCheckingConnectivity ||
        bloc.state is ContentGenerationSubmitting ||
        bloc.state is ContentGenerationInProgress ||
        bloc.state is ContentGenerationDownloading) {
      return;
    }
    final formError = _formError();
    if (formError != null) {
      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(formError)));
      return;
    }

    // Prototype image catalog first. A covered topic is sent as a catalog
    // selection, so the server builds it from the catalog with zero Sarvam
    // calls; only uncovered topics reach the server's Sarvam fallback.
    // Flutter itself never calls Sarvam.
    final libraryTopic = await _resolveLibraryTopic(_topicParts());
    if (!ctx.mounted) return;
    if (libraryTopic == null && _topicMode == 'library') {
      ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
          content: Text('No pictures in this topic have the words needed for '
              'this language mode. Try another language mode or topic.')));
      return;
    }

    final connectivity = getIt<ConnectivityService>();
    final isOnline = await connectivity.isOnline;
    final isReachable =
        isOnline && await connectivity.checkBackendReachability();
    if (!ctx.mounted) return;

    if (kDebugMode) {
      debugPrint(
        '[FlashcardGenerate] networkOnline=$isOnline backendUrl=${ApiConfig.baseUrl} '
        'backendReachable=$isReachable mode=$_languageMode type=$_flashcardType',
      );
    }

    final parts = _topicParts();
    final request = buildFlashcardGenerationRequest(
      grade: _grade,
      section: _section,
      subject: _subject,
      topic: parts.topic,
      topicSource: libraryTopic != null ? kTopicSourceCatalog : parts.source,
      topicId: libraryTopic?.id ?? parts.topicId,
      topicInputLanguage: _topicInputLanguage,
      nipunOutcome: parts.nipun,
      languageMode: _languageMode,
      flashcardType: _flashcardType,
      cardCount: _cardCount,
      difficulty: _difficulty,
      visualStyle: _visualStyle,
      pronunciation: _pronunciation,
      deviceId: 'tablet_jharkhand_001',
      origin: isReachable ? 'online' : 'offline',
    );

    setState(() {
      _readyPayload = null;
      _readyAssets = null;
      _readyContentId = null;
      _failureMessage = null;
      _downloaded = null;
    });

    if (!isReachable) {
      if (libraryTopic != null) {
        // Offline catalog topic: the same deterministic build from the
        // bundled catalog, on-device (no network, no LLM).
        _generateFromLibrary(ctx, libraryTopic);
        return;
      }
      // Offline (or server unreachable): queue locally. No Sarvam call is
      // attempted; the queue syncs when the backend becomes reachable.
      bloc.add(QueueOfflineGenerationEvent(request: request));
      return;
    }
    bloc.add(StartContentGenerationEvent(
      request: request,
      idempotencyKey: request.requestId,
    ));
  }

  /// The catalog topic serving this request, or null when the prototype
  /// catalog does not cover it (or has no usable pictures for the mode).
  Future<FlashcardLibraryTopic?> _resolveLibraryTopic(
      ({String topic, String source, String? topicId, String? nipun}) parts) async {
    final lib = _library;
    if (lib == null) return null;
    try {
      final topic = _topicMode == 'library'
          ? _selectedLibraryTopic
          : await lib.findTopic(parts.topic);
      if (topic == null || lib.usableCards(topic, _languageMode).isEmpty) {
        return null;
      }
      return topic;
    } catch (_) {
      return null;
    }
  }

  void _generateFromLibrary(BuildContext ctx, FlashcardLibraryTopic topic) {
    final parts = _topicParts();
    final payload = _library!.buildPayload(
      topic: topic,
      grade: _grade,
      section: _section,
      subject: _subject,
      topicLabel: parts.topic,
      topicSource: parts.source,
      nipunOutcome: parts.nipun,
      languageMode: _languageMode,
      flashcardType: _flashcardType,
      cardCount: _cardCount,
      difficulty: difficultyToServerCode(_difficulty),
      visualStyle: _visualStyle,
      pronunciation: _pronunciation,
    );
    final count = (payload['cards'] as List).length;
    setState(() {
      _readyPayload = payload;
      _readyAssets = null;
      _readyContentId = payload['content_id'].toString();
      _failureMessage = null;
      _downloaded = null;
    });
    _refreshDownloadState(_readyContentId!);
    _openDeck();
    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
      content: Text(count < _cardCount
          ? 'Offline: ${topic.label} has $count picture cards — showing all $count.'
          : 'Offline: built $count picture flashcards from the bundled catalog.'),
    ));
  }

  void _onBlocState(BuildContext ctx, ContentGenerationState state) {
    if (state is ContentGenerationReady) {
      final payload = state.contentPayload;
      final cards = payload['cards'];
      if (cards is List && cards.isNotEmpty) {
        setState(() {
          _readyPayload = Map<String, dynamic>.from(payload);
          _readyAssets =
              state.assets == null ? null : Map<String, dynamic>.from(state.assets!);
          _readyContentId = state.contentId;
          _failureMessage = null;
        });
        _refreshDownloadState(state.contentId);
        // Open each newly generated set in the study screen once.
        if (_openedContentId != state.contentId) _openDeck();
      }
    } else if (state is ContentGenerationFailed) {
      setState(() => _failureMessage = state.errorMessage);
    } else if (state is ContentGenerationQueuedOffline) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(content: Text('Saved for sync — will generate when online.')),
      );
    }
  }

  Future<void> _refreshDownloadState(String contentId) async {
    try {
      final store = await flashcardDownloadStore();
      final existing = await store.getByResourceId(contentId);
      if (mounted && existing != null) {
        setState(() => _downloaded = existing);
      }
    } catch (_) {}
  }

  Future<void> _onDownload() async {
    final payload = _readyPayload;
    final contentId = _readyContentId;
    if (payload == null || contentId == null || _downloading) return;
    setState(() => _downloading = true);
    try {
      final record = await saveFlashcardDeck(
        contentId: contentId,
        payload: payload,
        assets: _readyAssets,
      );
      if (!mounted) return;
      setState(() => _downloaded = record);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Flashcards downloaded — available offline.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Download failed: $e')));
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  Future<void> _onPreviewPdf() async {
    final payload = _readyPayload;
    if (payload == null) return;
    List<int> bytes;
    try {
      bytes = isImageCatalogPayload(payload)
          ? await renderImageLibraryFlashcardPdf(payload)
          : renderFlashcardPdf(payload);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Preview failed: $e')));
      return;
    }
    if (!mounted) return;
    await Printing.layoutPdf(onLayout: (_) async => Uint8List.fromList(bytes));
  }

  String? _openedContentId;

  /// Opens the ready set in the full-screen study view (flip / next / save).
  Future<void> _openDeck() async {
    final payload = _readyPayload;
    final contentId = _readyContentId;
    if (payload == null || contentId == null) return;
    _openedContentId = contentId;
    await context.push(
      AppRoutes.flashcardDeck,
      extra: GeneratedFlashcardDeckArgs(
        payload: payload,
        assets: _readyAssets,
        contentId: contentId,
      ),
    );
    // The set may have been saved from the study view.
    if (mounted) _refreshDownloadState(contentId);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ContentGenerationBloc>(),
      child: Builder(
        builder: (ctx) => BlocListener<ContentGenerationBloc, ContentGenerationState>(
          listener: _onBlocState,
          child: AppScaffold(
            title: 'Generate Flashcards',
            subtitle:
                'Visual multilingual flashcards in Hindi, English and Santali aligned with NIPUN learning outcomes.',
            breadcrumb: 'Teach > Flashcards > Generate',
            isScrollable: true,
            bottomActionBar: BlocBuilder<ContentGenerationBloc, ContentGenerationState>(
              builder: (context, state) {
                final busy = state is ContentGenerationCheckingConnectivity ||
                    state is ContentGenerationSubmitting ||
                    state is ContentGenerationInProgress ||
                    state is ContentGenerationDownloading;
                String label = 'Generate Flashcards';
                if (state is ContentGenerationInProgress) {
                  label = state.stageTitle.isNotEmpty
                      ? state.stageTitle
                      : 'Generating flashcards...';
                } else if (busy) {
                  label = 'Sending Request...';
                } else if (state is ContentGenerationQueuedOffline) {
                  label = 'Saved for Sync';
                } else if (state is ContentGenerationFailed) {
                  label = 'Retry Generation';
                } else if (state is ContentGenerationReady ||
                    state is ContentGenerationSavedLocally ||
                    _readyPayload != null) {
                  label = 'Generate Again';
                }
                return PrimaryButton(
                  label: label,
                  trailingIcon: Icons.auto_awesome_rounded,
                  onPressed: busy ? null : () => _onGenerate(ctx),
                );
              },
            ),
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatusSection(),
                _buildClassSection(),
                const SizedBox(height: 14),
                _buildSubjectSection(),
                const SizedBox(height: 14),
                _buildTopicSection(),
                const SizedBox(height: 14),
                _buildOutcomeSection(),
                const SizedBox(height: 14),
                _buildTypeSection(),
                const SizedBox(height: 14),
                _buildLanguageModeSection(),
                const SizedBox(height: 14),
                _buildCountSection(),
                const SizedBox(height: 14),
                _buildDifficultySection(),
                const SizedBox(height: 14),
                _buildVisualAudioSection(),
                const SizedBox(height: 14),
                _buildPreviewSection(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusSection() {
    return BlocBuilder<ContentGenerationBloc, ContentGenerationState>(
      builder: (context, state) {
        if (state is ContentGenerationInProgress) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: CustomCard(
              child: Row(
                children: [
                  const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5, color: AppColors.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(state.message.isNotEmpty ? state.message : 'Generating flashcards...',
                            style: AppTypography.bodySmall),
                        const SizedBox(height: 2),
                        Text('Checking picture catalog • preparing Santali cards',
                            style: AppTypography.caption),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        if (state is ContentGenerationQueuedOffline) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: CustomCard(
              color: AppColors.greenSurface,
              child: Row(
                children: [
                  const Icon(Icons.cloud_off_outlined, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Saved for sync — flashcards will generate when the server is reachable. No translation was made offline.',
                      style: AppTypography.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        if (_failureMessage != null) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: CustomCard(
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded,
                      color: AppColors.accentRed),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(_failureMessage!, style: AppTypography.bodySmall),
                  ),
                ],
              ),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildClassSection() {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Class + Section', style: AppTypography.cardTitle.copyWith(fontSize: 14)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: _grade,
                  decoration: const InputDecoration(labelText: 'Class'),
                  items: _classes
                      .map((c) => DropdownMenuItem(value: c, child: Text('Class $c')))
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
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _sections.contains(_section) ? _section : null,
                  decoration: const InputDecoration(labelText: 'Section'),
                  items: _sections
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() => _section = v);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectSection() {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Subject', style: AppTypography.cardTitle.copyWith(fontSize: 14)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _subjects.contains(_subject) ? _subject : null,
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
    );
  }

  Widget _buildTopicSection() {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Topic', style: AppTypography.cardTitle.copyWith(fontSize: 14)),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final mode in const [
                ('library', 'Picture library'),
                ('curriculum', 'Curriculum'),
                ('custom', 'Custom topic'),
              ]) ...[
                if (mode.$1 != 'library') const SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    label: Center(
                        child: Text(mode.$2,
                            maxLines: 1, overflow: TextOverflow.ellipsis)),
                    selected: _topicMode == mode.$1,
                    selectedColor: AppColors.primary,
                    backgroundColor: Colors.white,
                    labelStyle: TextStyle(
                        color: _topicMode == mode.$1
                            ? Colors.white
                            : AppColors.textPrimary,
                        fontSize: 12),
                    shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusPill),
                    onSelected: (v) {
                      if (v) setState(() => _topicMode = mode.$1);
                    },
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          if (_topicMode == 'library') _buildLibraryTopicPicker(),
          if (_topicMode == 'curriculum')
            _optionsLoading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: CircularProgressIndicator(color: AppColors.primary),
                    ),
                  )
                : _topics.isEmpty
                    ? Text(
                        'No curriculum topics for Class $_grade • $_subject. Enter your own topic.',
                        style: AppTypography.caption)
                    : DropdownButtonFormField<String>(
                        value: _selectedTopic?.id,
                        decoration: const InputDecoration(labelText: 'Topic'),
                        items: _topics
                            .map((t) => DropdownMenuItem(
                                  value: t.id,
                                  child: Text('${t.title} (${t.code})',
                                      overflow: TextOverflow.ellipsis),
                                ))
                            .toList(),
                        onChanged: (v) {
                          if (v == null) return;
                          setState(() =>
                              _selectedTopic = _topics.firstWhere((t) => t.id == v));
                        },
                      ),
          if (_useCustomTopic)
            TextField(
              controller: _customTopicController,
              decoration: const InputDecoration(
                labelText: 'Enter your own topic',
                hintText: 'e.g. Fruits / फल',
              ),
              maxLines: 2,
              onChanged: (_) => setState(() {}),
            ),
          if (_topicMode != 'library') ...[
          const SizedBox(height: 6),
          _buildCatalogAvailability(),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: const Center(child: Text('Topic in Hindi')),
                  selected: _topicInputLanguage == 'hi',
                  selectedColor: AppColors.primary,
                  backgroundColor: Colors.white,
                  labelStyle: TextStyle(
                      color: _topicInputLanguage == 'hi' ? Colors.white : AppColors.textPrimary,
                      fontSize: 12),
                  shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusPill),
                  onSelected: (v) {
                    if (v) setState(() => _topicInputLanguage = 'hi');
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ChoiceChip(
                  label: const Center(child: Text('Topic in English')),
                  selected: _topicInputLanguage == 'en',
                  selectedColor: AppColors.primary,
                  backgroundColor: Colors.white,
                  labelStyle: TextStyle(
                      color: _topicInputLanguage == 'en' ? Colors.white : AppColors.textPrimary,
                      fontSize: 12),
                  shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusPill),
                  onSelected: (v) {
                    if (v) setState(() => _topicInputLanguage = 'en');
                  },
                ),
              ),
            ],
          ),
          ],
        ],
      ),
    );
  }

  /// Tells the teacher whether the chosen curriculum/custom topic has
  /// prototype picture cards, or will be AI-generated online.
  Widget _buildCatalogAvailability() {
    final topic = _topicParts().topic;
    if (topic.isEmpty || _libraryLoading) return const SizedBox.shrink();
    final match = _library?.matchLoaded(topic);
    final count =
        match == null ? 0 : _library!.usableCards(match, _languageMode).length;
    final available = count > 0;
    return Row(
      children: [
        Icon(
          available ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
          size: 18,
          color: available ? AppColors.primary : AppColors.textSecondary,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            available
                ? 'Picture cards available • $count cards from "${match!.label}"'
                : 'No picture cards for this topic • AI-generated content will be '
                    'used (needs internet)',
            style: AppTypography.caption,
          ),
        ),
      ],
    );
  }

  Widget _buildLibraryTopicPicker() {
    if (_libraryLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }
    if (_libraryTopics.isEmpty) {
      return Text('The picture library is not available on this device.',
          style: AppTypography.caption);
    }
    final selected = _selectedLibraryTopic;
    final usableCards = selected == null || _library == null
        ? const <CurriculumFlashcard>[]
        : _library!.usableCards(selected, _languageMode);
    final usable = usableCards.length;
    final preview = usableCards.take(6).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          value: selected?.id,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Picture library topic'),
          items: _libraryTopics
              .map((t) => DropdownMenuItem(
                    value: t.id,
                    child: Text('${t.label} (${t.cardCount} pictures)',
                        overflow: TextOverflow.ellipsis),
                  ))
              .toList(),
          onChanged: (v) {
            if (v == null) return;
            setState(() => _selectedLibraryTopic =
                _libraryTopics.firstWhere((t) => t.id == v));
          },
        ),
        if (preview.isNotEmpty) ...[
          const SizedBox(height: 10),
          SizedBox(
            height: 64,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: preview.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, i) => ClipRRect(
                borderRadius: AppRadius.radiusMd,
                child: Image.asset(
                  preview[i].resolveImagePath(_library!.repository.assetRoot),
                  width: 64,
                  height: 64,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    width: 64,
                    height: 64,
                    color: AppColors.greenSurface,
                  ),
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: 6),
        Text(
          '$usable cards with printed Santali words for this language mode • '
          'works offline, no translation service needed.',
          style: AppTypography.caption,
        ),
      ],
    );
  }

  Widget _buildOutcomeSection() {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Learning Outcome / Competency',
              style: AppTypography.cardTitle.copyWith(fontSize: 14)),
          const SizedBox(height: 4),
          Text('The flashcards reinforce this objective (e.g. Oral Language Development).',
              style: AppTypography.caption),
          const SizedBox(height: 8),
          TextField(
            controller: _outcomeController,
            decoration: InputDecoration(
              labelText: 'Learning outcome (optional)',
              hintText: _selectedTopic == null
                  ? 'e.g. Oral Language Development'
                  : 'Default: ${_selectedTopic!.code}',
            ),
            maxLines: 2,
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeSection() {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Flashcard Type', style: AppTypography.cardTitle.copyWith(fontSize: 14)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: FlashcardTypes.all.map((t) {
              final sel = _flashcardType == t;
              return FilterChip(
                label: Text(FlashcardTypes.label(t)),
                selected: sel,
                selectedColor: AppColors.primary,
                backgroundColor: Colors.white,
                checkmarkColor: Colors.white,
                labelStyle: TextStyle(
                    color: sel ? Colors.white : AppColors.textPrimary, fontSize: 12),
                shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusPill),
                onSelected: (v) {
                  if (v) setState(() => _flashcardType = t);
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageModeSection() {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Language Mode', style: AppTypography.cardTitle.copyWith(fontSize: 14)),
          const SizedBox(height: 4),
          Text(
              'Santali is always included. Picture-library topics use the Santali words printed '
              'in the source book; other topics use the server translation service.',
              style: AppTypography.caption),
          const SizedBox(height: 8),
          ...FlashcardLanguageModes.all.map((m) {
            final sel = _languageMode == m.code;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ChoiceChip(
                label: SizedBox(
                  width: double.infinity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(m.label,
                          style: TextStyle(
                              color: sel ? Colors.white : AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 13)),
                      Text(m.description,
                          style: TextStyle(
                              color: sel ? Colors.white70 : AppColors.textSecondary,
                              fontSize: 11)),
                    ],
                  ),
                ),
                selected: sel,
                selectedColor: AppColors.primary,
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusMd),
                onSelected: (v) {
                  if (v) setState(() => _languageMode = m.code);
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCountSection() {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Number of Cards', style: AppTypography.cardTitle.copyWith(fontSize: 14)),
          const SizedBox(height: 8),
          TextField(
            controller: _cardCountController,
            decoration: InputDecoration(
              labelText: 'Number of cards (1–20)',
              errorText: _cardCountError,
            ),
            keyboardType: TextInputType.number,
          ),
        ],
      ),
    );
  }

  Widget _buildDifficultySection() {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Difficulty', style: AppTypography.cardTitle.copyWith(fontSize: 14)),
          const SizedBox(height: 8),
          Row(
            children: DifficultyLevel.values.map((d) {
              final sel = _difficulty == d;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Center(child: Text(d.label)),
                    selected: sel,
                    selectedColor: AppColors.primary,
                    backgroundColor: Colors.white,
                    labelStyle:
                        TextStyle(color: sel ? Colors.white : AppColors.textPrimary),
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
    );
  }

  Widget _buildVisualAudioSection() {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Visual Style + Pronunciation',
              style: AppTypography.cardTitle.copyWith(fontSize: 14)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: ['illustrated', 'vector', 'photo_neutral'].map((s) {
              final sel = _visualStyle == s;
              return ChoiceChip(
                label: Text(s == 'photo_neutral' ? 'Neutral photo' : s),
                selected: sel,
                selectedColor: AppColors.primary,
                backgroundColor: Colors.white,
                labelStyle: TextStyle(
                    color: sel ? Colors.white : AppColors.textPrimary, fontSize: 12),
                shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusPill),
                onSelected: (v) {
                  if (v) setState(() => _visualStyle = s);
                },
              );
            }).toList(),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('Pronunciation / Audio (optional)',
                style: AppTypography.bodySmall),
            subtitle: Text('Playback buttons for Hindi, English and Santali where supported.',
                style: AppTypography.caption),
            value: _pronunciation,
            activeTrackColor: AppColors.primaryLight,
            activeThumbColor: AppColors.primary,
            onChanged: (val) => setState(() => _pronunciation = val),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewSection() {
    final payload = _readyPayload;
    if (payload == null) return const SizedBox.shrink();
    final cards = ((payload['cards'] as List?) ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    if (cards.isEmpty) return const SizedBox.shrink();
    final mode = (payload['language_mode'] ?? 'hi_sat').toString();
    final downloaded = _downloaded != null;
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Flashcards Ready', style: AppTypography.cardTitle.copyWith(fontSize: 15)),
          const SizedBox(height: 2),
          Text('${cards.length} flashcards generated • ${FlashcardLanguageModes.byCode(mode).label}',
              style: AppTypography.caption),
          const SizedBox(height: 12),
          SizedBox(
            height: 150,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: cards.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (_, i) => SizedBox(
                width: 108,
                child: GestureDetector(
                  onTap: _openDeck,
                  child: GeneratedFlashcardFace(
                    card: cards[i],
                    languageMode: mode,
                    compact: true,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: PrimaryButton(
                  label: 'Open Flashcards',
                  icon: Icons.style_rounded,
                  onPressed: _openDeck,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SecondaryButton(
                  label: _downloading
                      ? 'Saving...'
                      : (downloaded ? 'Saved' : 'Save to Downloads'),
                  icon: downloaded
                      ? Icons.offline_pin_rounded
                      : Icons.download_rounded,
                  onPressed: (downloaded || _downloading) ? null : _onDownload,
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    downloaded
                        ? 'SAVED — available offline in Downloads.'
                        : 'READY TO SAVE',
                    style: AppTypography.caption
                        .copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                TextButton(
                  onPressed: downloaded
                      ? () => context.go(AppRoutes.downloads)
                      : _onPreviewPdf,
                  child: Text(downloaded ? 'Open Downloads' : 'Print preview'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
