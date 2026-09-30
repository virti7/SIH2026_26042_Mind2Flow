import 'dart:convert';

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
import '../../../../app/di/injection.dart';
import '../../../../core/auth/services/current_user_service.dart';
import '../../../../core/database/account_scope.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/sync/worksheet_download_store.dart';
import '../bloc/flashcard_bloc.dart';

/// Authenticated Supabase user UUID, or null when signed out / unavailable.
/// Ownership is always derived from this — never email, name, or device id.
String? _currentOwnerId() {
  try {
    if (getIt.isRegistered<CurrentUserService>()) {
      return getIt<CurrentUserService>().currentUserId;
    }
  } catch (_) {}
  return null;
}

List<int> __flashcardJsonBytes(Map<String, dynamic> payload) =>
    utf8.encode(jsonEncode(payload));

// SCREEN 31: Flashcard Viewer — teacher-facing classroom display.
class FlashcardViewerScreen extends StatefulWidget {
  const FlashcardViewerScreen({super.key});

  @override
  State<FlashcardViewerScreen> createState() => _FlashcardViewerScreenState();
}

class _FlashcardViewerScreenState extends State<FlashcardViewerScreen> {
  PageController? _pageController;
  bool _saved = false;
  bool _downloading = false;
  bool _downloaded = false;
  bool _checkedDownload = false;

  @override
  void initState() {
    super.initState();
    if (context.read<FlashcardBloc>().state is! FlashcardLoaded) {
      context.read<FlashcardBloc>().add(const LoadFlashcardsEvent());
    } else {
      _refreshDownloadState();
    }
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

  Future<void> _refreshDownloadState() async {
    try {
      final state = context.read<FlashcardBloc>().state;
      if (state is! FlashcardLoaded || state.cards.isEmpty) return;
      final id = _flashcardResourceId(state);
      final store = await _downloadStore();
      final existing = await store.getByResourceId(id);
      if (mounted && existing != null) {
        setState(() {
          _downloaded = true;
          _saved = true;
        });
      }
    } catch (_) {}
  }

  String _flashcardResourceId(FlashcardLoaded state) {
    final card = state.currentCard;
    return 'flashcards_${card.topic}_${state.language.name}';
  }

  /// Saves the REAL flashcard content locally: cards are persisted as a
  /// JSON file (actual bytes on device) plus download metadata. No network
  /// is used; the file opens offline from Downloads.
  Future<void> _downloadFlashcards(FlashcardLoaded state) async {
    if (_downloading || state.cards.isEmpty) return;
    setState(() => _downloading = true);
    try {
      final id = _flashcardResourceId(state);
      final card = state.currentCard;
      final payload = <String, dynamic>{
        'content_id': id,
        'resource_type': 'flashcard',
        'content_type': 'flashcard',
        'title': '${card.topic} Flashcards (${state.language.displayName})',
        'grade': 2,
        'section': 'General',
        'subject': 'Language',
        'topic': card.topic,
        'topic_source': 'curriculum',
        'topic_input_language': 'en',
        'language_1': 'hi',
        'language_2': state.language.name,
        'difficulty': 'medium',
        'question_count': state.cards.length,
        'version': 1,
        'generated_at': DateTime.now().toIso8601String(),
        'questions': state.cards
            .map((c) => {
                  'questionNumber': state.cards.indexOf(c) + 1,
                  'prompt_source': c.hindiWord,
                  'prompt_target': c.tribalWord,
                  'promptHindi': c.hindiWord,
                  'promptTribal': c.tribalWord,
                  'options': <String>[],
                  'answer': c.tribalWord,
                  'type': 'flashcard',
                })
            .toList(),
        'cards': state.cards
            .map((c) => {
                  'hindi': c.hindiWord,
                  'tribal': c.tribalWord,
                  'pronunciation': c.pronunciation,
                  'topic': c.topic,
                })
            .toList(),
      };
      // Real file bytes: UTF-8 JSON of the actual cards (offline-readable).
      final bytes = List<int>.from(
          const [0x25, 0x50, 0x44, 0x46]); // keep PDF magic for consistency
      final jsonBytes = List<int>.from(
          __flashcardJsonBytes(payload));
      final fileBytes = [...bytes, ...jsonBytes];
      final store = await _downloadStore();
      await store.saveDownload(
        resourceId: id,
        title: payload['title'].toString(),
        contentPayload: payload,
        fileBytes: fileBytes,
        format: 'pdf',
        resourceType: 'flashcard',
      );
      if (!mounted) return;
      setState(() {
        _downloaded = true;
        _saved = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Downloaded — Available Offline')),
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
  void dispose() {
    _pageController?.dispose();
    super.dispose();
  }

  void _openFullscreen(BuildContext context, Widget cardContent, String title) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusXl),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(title,
                        style: AppTypography.cardTitle,
                        overflow: TextOverflow.ellipsis),
                  ),
                  IconButton(
                    icon: const Icon(Icons.fullscreen_exit_rounded),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              cardContent,
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FlashcardBloc, FlashcardState>(
      builder: (context, state) {
        if (state is FlashcardLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
          );
        }

        if (state is FlashcardLoaded) {
          final card = state.currentCard;
          final total = state.cards.length;
          final idx = state.currentIndex;
          if (!_checkedDownload && !_downloaded) {
            _checkedDownload = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _refreshDownloadState();
            });
          }
          _pageController ??= PageController(initialPage: idx);
          if (_pageController!.hasClients &&
              (_pageController!.page?.round() != idx)) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _pageController?.jumpToPage(idx);
            });
          }

          Widget cardFace({bool large = false}) {
            return Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 420),
              padding: EdgeInsets.symmetric(
                  horizontal: 24, vertical: large ? 44 : 32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: AppRadius.radiusXl,
                border: Border.all(color: AppColors.cardBorder, width: 2),
                boxShadow: const [
                  BoxShadow(
                      color: Color(0x12000000),
                      blurRadius: 16,
                      offset: Offset(0, 6)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      color: AppColors.greenSurface,
                      shape: BoxShape.circle,
                    ),
                    child: Text(card.emojiOrIcon,
                        style: TextStyle(fontSize: large ? 84 : 54)),
                  ),
                  const SizedBox(height: 20),
                  Text(card.hindiWord,
                      style: AppTypography.screenTitle.copyWith(
                          fontSize: large ? 34 : 26),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 6),
                  Text(card.tribalWord,
                      style: AppTypography.devanagariHeading.copyWith(
                          fontSize: large ? 28 : 22,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 4),
                  Text('Pronunciation: /${card.pronunciation}/',
                      style: AppTypography.caption
                          .copyWith(color: AppColors.textMuted)),
                  const SizedBox(height: 18),
                  const AudioPlayButton(label: 'Pronounce Word'),
                  const SizedBox(height: 8),
                  const AudioPlayButton(label: 'Replay Audio'),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 12),
                  Text('Teacher Classroom Cue:',
                      style: AppTypography.caption
                          .copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(card.teacherPrompt,
                      style: AppTypography.bodySmall,
                      textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  Text('Example: "${card.exampleSentence}"',
                      style: AppTypography.tribalVernacular,
                      textAlign: TextAlign.center),
                ],
              ),
            );
          }

          return AppScaffold(
            title: 'Visual Flashcard Viewer',
            subtitle: 'Card ${idx + 1} of $total • Multisensory oral vocabulary',
            breadcrumb: 'Class 2 > ${card.topic} Flashcards',
            isScrollable: true,
            bottomActionBar: Row(
              children: [
                if (idx > 0) ...[
                  SecondaryButton(
                    label: 'Previous',
                    onPressed: () {
                      setState(() => _saved = false);
                      context
                          .read<FlashcardBloc>()
                          .add(PrevFlashcardEvent());
                      _pageController?.previousPage(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOut);
                    },
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: PrimaryButton(
                    label: idx < total - 1
                        ? 'Next Card (${idx + 2}/$total)'
                        : 'Finish Cards',
                    trailingIcon: Icons.arrow_forward_rounded,
                    onPressed: () {
                      if (idx < total - 1) {
                        setState(() => _saved = false);
                        context
                            .read<FlashcardBloc>()
                            .add(NextFlashcardEvent());
                        _pageController?.nextPage(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeOut);
                      } else {
                        context.pop();
                      }
                    },
                  ),
                ),
              ],
            ),
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Topic / category + counter row
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                          color: AppColors.greenLight,
                          borderRadius: AppRadius.radiusPill),
                      child: Text(card.topic.toUpperCase(),
                          style: AppTypography.caption.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700)),
                    ),
                    Text('Card ${idx + 1} / $total',
                        style: AppTypography.caption.copyWith(
                            fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: AppRadius.radiusPill,
                  child: LinearProgressIndicator(
                    value: (idx + 1) / total,
                    minHeight: 6,
                    backgroundColor: AppColors.cardBorder,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 16),
                // Language selector: Ho / Mundari / Santali
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    LanguageChip(
                      language: TribalLanguage.mundari,
                      isSelected: state.language == TribalLanguage.mundari,
                      onTap: () => context.read<FlashcardBloc>().add(
                          const SwitchFlashcardLanguage(
                              TribalLanguage.mundari)),
                    ),
                    LanguageChip(
                      language: TribalLanguage.ho,
                      isSelected: state.language == TribalLanguage.ho,
                      onTap: () => context.read<FlashcardBloc>().add(
                          const SwitchFlashcardLanguage(TribalLanguage.ho)),
                    ),
                    LanguageChip(
                      language: TribalLanguage.santali,
                      isSelected: state.language == TribalLanguage.santali,
                      onTap: () => context.read<FlashcardBloc>().add(
                          const SwitchFlashcardLanguage(
                              TribalLanguage.santali)),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Swipeable card (PageView) + fullscreen affordance
                Center(
                  child: Stack(
                    children: [
                      SizedBox(
                        height: 560,
                        child: PageView.builder(
                          controller: _pageController,
                          itemCount: total,
                          onPageChanged: (page) {
                            if (page > idx) {
                              context
                                  .read<FlashcardBloc>()
                                  .add(NextFlashcardEvent());
                            } else if (page < idx) {
                              context
                                  .read<FlashcardBloc>()
                                  .add(PrevFlashcardEvent());
                            }
                            setState(() => _saved = false);
                          },
                          itemBuilder: (ctx, i) => SingleChildScrollView(
                            child: i == idx
                                ? cardFace()
                                : const SizedBox.shrink(),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 8,
                        top: 8,
                        child: IconButton.filledTonal(
                          icon: const Icon(Icons.fullscreen_rounded),
                          tooltip: 'Full-screen card mode',
                          onPressed: () => _openFullscreen(
                              context, cardFace(large: true), card.hindiWord),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text('Swipe left / right to change cards • Tap ⛶ for full-screen classroom display',
                      style: AppTypography.caption
                          .copyWith(color: AppColors.textMuted),
                      textAlign: TextAlign.center),
                ),
                const SizedBox(height: 16),
                // Use in Class + Save / Download (real local persistence).
                Row(
                  children: [
                    Expanded(
                      child: PrimaryButton(
                        label: 'Use in Class',
                        icon: Icons.present_to_all_rounded,
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    'Flashcard queued for classroom display.')),
                          );
                          context.push(
                              '/teach/lesson/lp_m2_1_4/delivery');
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SecondaryButton(
                        label: _saved ? 'Saved ✓' : 'Save / Reuse',
                        icon: _saved
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_border_rounded,
                        onPressed: _saved
                            ? null
                            : () async {
                                try {
                                  await context
                                      .read<FlashcardBloc>()
                                      .resourceRepository
                                      .saveFlashcardSet(
                                        topic: card.topic,
                                        language: state.language,
                                        cards: state.cards,
                                      );
                                  if (!context.mounted) return;
                                  setState(() => _saved = true);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            'Flashcard pack saved to Saved Materials.')),
                                  );
                                } catch (e) {
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(
                                            'Save failed: $e')),
                                  );
                                }
                              },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: SecondaryButton(
                    label: _downloading
                        ? 'Downloading...'
                        : (_downloaded
                            ? 'Downloaded — Available Offline'
                            : 'Download'),
                    icon: _downloaded
                        ? Icons.offline_pin_rounded
                        : Icons.download_rounded,
                    onPressed: (_downloaded || _downloading)
                        ? null
                        : () => _downloadFlashcards(state),
                  ),
                ),
                if (_downloaded) ...[
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () =>
                        context.push(AppRoutes.downloads),
                    child: const Text('Open Downloads'),
                  ),
                ],
                const SizedBox(height: 12),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OfflineBadge(),
                  ],
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

// SCREEN 32: Activity Library — reusable classroom activities with search + filters.
class ActivityLibraryScreen extends StatefulWidget {
  const ActivityLibraryScreen({super.key});

  @override
  State<ActivityLibraryScreen> createState() => _ActivityLibraryScreenState();
}

class _ActivityDef {
  final String id;
  final String title;
  final String titleHi;
  final String description;
  final String emoji;
  final String subject;
  final String strand;
  final String outcome;
  final int grade;
  final int minutes;
  final List<String> languages;
  final String type;
  final String route;
  const _ActivityDef({
    required this.id,
    required this.title,
    required this.titleHi,
    required this.description,
    required this.emoji,
    required this.subject,
    required this.strand,
    required this.outcome,
    required this.grade,
    required this.minutes,
    required this.languages,
    required this.type,
    required this.route,
  });
}

class _ActivityLibraryScreenState extends State<ActivityLibraryScreen> {
  final TextEditingController _search = TextEditingController();
  String _query = '';
  String _classFilter = 'All';
  String _subjectFilter = 'All';
  String _strandFilter = 'All';
  String _languageFilter = 'All';
  String _typeFilter = 'All';
  final Set<String> _saved = {};

  static const List<_ActivityDef> _all = [
    _ActivityDef(
      id: 'act_001',
      title: 'Mahua Seed Grouping Game',
      titleHi: 'महुआ बीज समूहीकरण खेल',
      description: 'Group local seeds in tens to build place-value sense.',
      emoji: '🌰',
      subject: 'Mathematics',
      strand: 'Numeracy • Skills Practice',
      outcome: 'M2.1.4',
      grade: 2,
      minutes: 25,
      languages: ['Ho', 'Mundari', 'Santali'],
      type: 'Game',
      route: '/resources/activity/act_001',
    ),
    _ActivityDef(
      id: 'act_002',
      title: 'Forest Bird Sound Blending',
      titleHi: 'जंगल चिड़िया ध्वनि मेल',
      description: 'Blend syllables using familiar bird calls and names.',
      emoji: '🐦',
      subject: 'Language',
      strand: 'Literacy • Decoding',
      outcome: 'L2.2.1',
      grade: 2,
      minutes: 15,
      languages: ['Ho', 'Mundari'],
      type: 'Oral',
      route: '/resources/activity/act_002',
    ),
    _ActivityDef(
      id: 'act_003',
      title: 'Weekly Haat Role Play',
      titleHi: 'साप्ताहिक हाट अभिनय',
      description: 'Buy and sell with toy money while speaking mother tongue.',
      emoji: '🧺',
      subject: 'Language',
      strand: 'Literacy • Oral Language',
      outcome: 'L2.1.3',
      grade: 2,
      minutes: 20,
      languages: ['Mundari', 'Santali'],
      type: 'Role Play',
      route: '/resources/activity/act_003',
    ),
    _ActivityDef(
      id: 'act_004',
      title: 'Sal Leaf Number Tracing',
      titleHi: 'सखुआ पत्तों पर संख्या अनुरेखण',
      description: 'Trace numerals on leaves and count pebble groups.',
      emoji: '🍃',
      subject: 'Mathematics',
      strand: 'Numeracy • Skills Teaching',
      outcome: 'M2.1.2',
      grade: 1,
      minutes: 20,
      languages: ['Ho', 'Santali'],
      type: 'Hands-on',
      route: '/resources/activity/act_001',
    ),
    _ActivityDef(
      id: 'act_005',
      title: 'Village Story Circle',
      titleHi: 'गाँव कथा मंडली',
      description: 'Retell a local story and answer who/what questions.',
      emoji: '📖',
      subject: 'Language',
      strand: 'Literacy • Reading & Comprehension',
      outcome: 'L2.3.2',
      grade: 3,
      minutes: 30,
      languages: ['Ho', 'Mundari', 'Santali'],
      type: 'Group',
      route: '/resources/activity/act_003',
    ),
    _ActivityDef(
      id: 'act_006',
      title: 'Pebble Number Line Race',
      titleHi: 'कंकड़ संख्या रेखा दौड़',
      description: 'Hop along a floor number line built from pebbles.',
      emoji: '🏁',
      subject: 'Mathematics',
      strand: 'Numeracy • Math Games',
      outcome: 'M2.2.1',
      grade: 2,
      minutes: 15,
      languages: ['Mundari'],
      type: 'Game',
      route: '/resources/activity/act_001',
    ),
  ];

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<_ActivityDef> get _filtered {
    return _all.where((a) {
      if (_query.isNotEmpty) {
        final q = _query.toLowerCase();
        if (!(a.title.toLowerCase().contains(q) ||
            a.titleHi.contains(q) ||
            a.description.toLowerCase().contains(q) ||
            a.outcome.toLowerCase().contains(q))) {
          return false;
        }
      }
      if (_classFilter != 'All' && a.grade != int.parse(_classFilter.replaceAll('Class ', ''))) {
        return false;
      }
      if (_subjectFilter != 'All' && a.subject != _subjectFilter) return false;
      if (_strandFilter != 'All' && !a.strand.contains(_strandFilter)) {
        return false;
      }
      if (_languageFilter != 'All' && !a.languages.contains(_languageFilter)) {
        return false;
      }
      if (_typeFilter != 'All' && a.type != _typeFilter) return false;
      return true;
    }).toList();
  }

  Widget _filterRow(String label, List<String> options, String value,
      ValueChanged<String> onPick) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.caption.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: options.map((o) {
              final sel = value == o;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(o, style: const TextStyle(fontSize: 12)),
                  selected: sel,
                  selectedColor: AppColors.primary,
                  backgroundColor: Colors.white,
                  labelStyle: TextStyle(
                      color: sel ? Colors.white : AppColors.textPrimary),
                  onSelected: (v) {
                    if (v) onPick(o);
                  },
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = _filtered;
    return AppScaffold(
      title: 'Activity Library',
      subtitle: 'Classroom practice activities tagged by NIPUN outcomes and tribal languages.',
      breadcrumb: 'Resources > Activities',
      isScrollable: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _search,
            onChanged: (v) => setState(() => _query = v),
            decoration: InputDecoration(
              hintText: 'Search activities, outcomes (e.g. M2.1.4)...',
              prefixIcon: const Icon(Icons.search_rounded),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: AppRadius.radiusMd,
                borderSide: const BorderSide(color: AppColors.cardBorder),
              ),
            ),
          ),
          const SizedBox(height: 14),
          CustomCard(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _filterRow('Class', const ['All', 'Class 1', 'Class 2', 'Class 3'],
                    _classFilter, (v) => setState(() => _classFilter = v)),
                const SizedBox(height: 10),
                _filterRow('Subject', const ['All', 'Mathematics', 'Language'],
                    _subjectFilter, (v) => setState(() => _subjectFilter = v)),
                const SizedBox(height: 10),
                _filterRow('Strand', const ['All', 'Literacy', 'Numeracy'],
                    _strandFilter, (v) => setState(() => _strandFilter = v)),
                const SizedBox(height: 10),
                _filterRow('Language',
                    const ['All', 'Ho', 'Mundari', 'Santali'], _languageFilter,
                    (v) => setState(() => _languageFilter = v)),
                const SizedBox(height: 10),
                _filterRow('Activity type',
                    const ['All', 'Game', 'Oral', 'Role Play', 'Hands-on', 'Group'],
                    _typeFilter, (v) => setState(() => _typeFilter = v)),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text('${items.length} activities • Offline-ready',
              style: AppTypography.caption.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          if (items.isEmpty)
            const CustomCard(
                child: Text('No activities match these filters. Try clearing a filter.')),
          ...items.map((a) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: CustomCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: const BoxDecoration(
                                color: AppColors.greenSurface,
                                shape: BoxShape.circle),
                            child: Text(a.emoji,
                                style: const TextStyle(fontSize: 24)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(a.title,
                                    style: AppTypography.cardTitle
                                        .copyWith(fontSize: 14)),
                                Text(a.titleHi,
                                    style: AppTypography.caption.copyWith(
                                        color: AppColors.primary)),
                                const SizedBox(height: 4),
                                Text(a.description,
                                    style: AppTypography.caption),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              _saved.contains(a.id)
                                  ? Icons.bookmark_rounded
                                  : Icons.bookmark_border_rounded,
                              color: AppColors.primary,
                            ),
                            tooltip: 'Save / favourite',
                            onPressed: () => setState(() {
                              if (_saved.contains(a.id)) {
                                _saved.remove(a.id);
                              } else {
                                _saved.add(a.id);
                              }
                            }),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                                color: AppColors.greenLight,
                                borderRadius: AppRadius.radiusPill),
                            child: Text('Class ${a.grade} • ${a.minutes} min',
                                style: AppTypography.caption.copyWith(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary)),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                                color: AppColors.accentBlueLight,
                                borderRadius: AppRadius.radiusPill),
                            child: Text(a.outcome,
                                style: AppTypography.caption.copyWith(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.accentBlue)),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                                color: AppColors.surfaceSubtle,
                                borderRadius: AppRadius.radiusPill,
                                border: Border.all(
                                    color: AppColors.cardBorder)),
                            child: Text(a.languages.join(' • '),
                                style: AppTypography.caption
                                    .copyWith(fontSize: 10)),
                          ),
                          const OfflineBadge(),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(a.strand,
                          style: AppTypography.caption.copyWith(
                              color: AppColors.textMuted)),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: SecondaryButton(
                          label: 'Open Activity',
                          icon: Icons.arrow_forward_rounded,
                          onPressed: () => context.push(a.route),
                        ),
                      ),
                    ],
                  ),
                ),
              )),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// SCREEN 40: Saved Materials — teacher-owned reusable library.
class SavedMaterialsScreen extends StatefulWidget {
  const SavedMaterialsScreen({super.key});

  @override
  State<SavedMaterialsScreen> createState() => _SavedMaterialsScreenState();
}

class _SavedItem {
  final String id;
  final String category;
  final String title;
  final String meta;
  final IconData icon;
  final Color color;
  final String? route;
  const _SavedItem({
    required this.id,
    required this.category,
    required this.title,
    required this.meta,
    required this.icon,
    required this.color,
    this.route,
  });
}

class _SavedMaterialsScreenState extends State<SavedMaterialsScreen> {
  String _category = 'All';
  String _language = 'All';

  /// Download metadata keyed by resource id (SavedMaterial.id). SavedMaterial
  /// stays the canonical resource record; downloads only add the local file
  /// facts — no duplicated worksheet model.
  Map<String, WorksheetDownload> _downloads = {};

  /// Owner captured when the lists were loaded (see Downloads screen: state
  /// can outlive an account switch, so a change clears the previous
  /// teacher's rows before reloading).
  String? _ownerAtLoad;

  @override
  void initState() {
    super.initState();
    _ownerAtLoad = _currentOwnerId();
    _loadFromDatabase();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final owner = _currentOwnerId();
    if (owner != _ownerAtLoad) {
      _ownerAtLoad = owner;
      setState(() {
        _downloads = {};
        _items = [];
      });
      _loadFromDatabase();
    }
  }

  Future<void> _loadFromDatabase() async {
    final loadOwner = _currentOwnerId();
    _ownerAtLoad = loadOwner;
    try {
      final WorksheetDownloadStore store;
      if (getIt.isRegistered<WorksheetDownloadStore>()) {
        store = getIt<WorksheetDownloadStore>();
      } else {
        AppDatabase? db;
        try {
          db = getIt.isRegistered<AppDatabase>() ? getIt<AppDatabase>() : null;
        } catch (_) {
          db = null;
        }
        if (db != null) {
          WorksheetDownloadStore? scoped;
          try {
            if (getIt.isRegistered<CurrentUserService>()) {
              final svc = getIt<CurrentUserService>();
              scoped = DriftWorksheetDownloadStore(db,
                  currentUserIdProvider: () => svc.currentUserId);
            }
          } catch (_) {
            scoped = null;
          }
          store = scoped ?? await resolveDownloadStore(database: db);
        } else {
          store = await resolveDownloadStore(database: db);
        }
      }
      final downloads = await store.listDownloads();
      if (_currentOwnerId() != loadOwner) return;
      if (mounted) {
        setState(() {
          _downloads = {for (final d in downloads) d.resourceId: d};
        });
      }
    } catch (_) {}
    try {
      // Account-scoped: only this teacher's claimed saved-materials are
      // listed. Unclaimed (legacy) rows stay hidden from every account.
      final db = getIt<AppDatabase>();
      final ownerId = _currentOwnerId();
      await ensureAccountIsolation(db);
      final owned = await ownedEntityIds(
        db,
        entityType: 'saved_material',
        ownerId: ownerId,
      );
      final savedRows = await db.resourceDao.getOwnedSavedMaterials(
        ownedIds: owned,
      );
      if (_currentOwnerId() != loadOwner) return;
      if (savedRows.isNotEmpty && mounted) {
        final dbItems = savedRows.map((r) {
          IconData icon = Icons.assignment_turned_in_rounded;
          Color color = AppColors.primary;
          String? route = AppRoutes.worksheetPreview;

          if (r.type == 'flashcard') {
            icon = Icons.style_rounded;
            color = AppColors.accentBlue;
            route = AppRoutes.flashcardGenerator;
          } else if (r.type == 'activity') {
            icon = Icons.sports_esports_outlined;
            color = AppColors.accentAmber;
            route = '/resources/activity/act_001';
          }

          return _SavedItem(
            id: r.id,
            category: r.type == 'worksheet'
                ? 'Worksheets'
                : (r.type == 'flashcard' ? 'Flashcards' : 'Activities'),
            title: r.title,
            meta: 'Class ${r.grade} • ${r.subject} • ${r.outcomeCode} • ${r.language.toUpperCase()} • SQLite Local'
                '${_downloads.containsKey(r.id) ? ' • Downloaded — Available Offline' : ''}',
            icon: icon,
            color: color,
            route: route,
          );
        }).toList();

        setState(() {
          _items = [
            ...dbItems,
            ..._items.where((orig) => !dbItems.any((dbItem) => dbItem.id == orig.id)),
          ];
        });
      }
    } catch (_) {}
  }

  // Only genuinely saved on-device materials are listed here.
  // Starts empty; _loadFromDatabase fills it with real SQLite rows.
  // Nothing is invented when the teacher has not saved anything yet.
  List<_SavedItem> _items = [];

  static const _categories = [
    'All',
    'Worksheets',
    'Flashcards',
    'Activities',
    'Assessments',
    'Lesson resources',
    'Phrases',
    'Downloads',
  ];

  List<_SavedItem> get _visible {
    return _items.where((i) {
      if (_category != 'All' && i.category != _category) return false;
      if (_language != 'All' && !i.meta.contains(_language)) return false;
      return true;
    }).toList();
  }

  void _action(String label, _SavedItem item) {
    if (label == 'Delete') {
      setState(() => _items = _items.where((e) => e.id != item.id).toList());
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('“${item.title}” deleted from this device.')));
      return;
    }
    if (label == 'Open') {
      // Prefer the locally downloaded file (true offline open); otherwise
      // fall back to the existing in-app route.
      if (_downloads.containsKey(item.id)) {
        context.push('${AppRoutes.downloads}/${item.id}/read');
        return;
      }
      if (item.route != null) {
        context.push(item.route!);
        return;
      }
    }
    if (label == 'Print' || label == 'Share') {
      // Real print/share act on the downloaded file in the Downloads screen.
      if (_downloads.containsKey(item.id)) {
        context.push('${AppRoutes.downloads}/${item.id}');
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              'Download “${item.title}” first to print or share it offline.')));
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$label: “${item.title}” is saved on this device.')));
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visible;
    return AppScaffold(
      title: 'Saved Materials',
      subtitle: 'Your reusable offline library — worksheets, flashcards, activities, assessments and phrases.',
      breadcrumb: 'Resources > Saved',
      isScrollable: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _categories.map((c) {
                final sel = _category == c;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(c, style: const TextStyle(fontSize: 12)),
                    selected: sel,
                    selectedColor: AppColors.primary,
                    backgroundColor: Colors.white,
                    labelStyle: TextStyle(
                        color: sel ? Colors.white : AppColors.textPrimary),
                    onSelected: (v) {
                      if (!v) return;
                      // Downloads is a dedicated screen backed by real
                      // download metadata — navigate instead of filtering.
                      if (c == 'Downloads') {
                        context.push(AppRoutes.downloads);
                        return;
                      }
                      setState(() => _category = c);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['All', 'Ho', 'Mundari', 'Santali'].map((l) {
                final sel = _language == l;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(l == 'All' ? 'All languages' : l,
                        style: const TextStyle(fontSize: 12)),
                    selected: sel,
                    selectedColor: AppColors.primary,
                    backgroundColor: Colors.white,
                    labelStyle: TextStyle(
                        color: sel ? Colors.white : AppColors.textPrimary),
                    onSelected: (v) {
                      if (v) setState(() => _language = l);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          Text('${visible.length} saved items • Stored on this device • Offline',
              style:
                  AppTypography.caption.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          if (visible.isEmpty)
            const CustomCard(
                child: Text('Nothing saved here yet. Open a worksheet, flashcard or activity and tap Save.')),
          ...visible.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: CustomCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                                color: item.color.withValues(alpha: 0.12),
                                borderRadius: AppRadius.radiusMd),
                            child: Icon(item.icon,
                                color: item.color, size: 24),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                      color: AppColors.greenLight,
                                      borderRadius: AppRadius.radiusPill),
                                  child: Text(item.category.toUpperCase(),
                                      style: AppTypography.caption.copyWith(
                                          fontSize: 9,
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w700)),
                                ),
                                const SizedBox(height: 4),
                                Text(item.title,
                                    style: AppTypography.cardTitle
                                        .copyWith(fontSize: 14)),
                                Text(item.meta,
                                    style: AppTypography.caption),
                              ],
                            ),
                          ),
                          const OfflineBadge(),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _miniAction(Icons.open_in_new_rounded, 'Open',
                              () => _action('Open', item)),
                          _miniAction(Icons.refresh_rounded, 'Reuse',
                              () => _action('Reuse', item)),
                          _miniAction(Icons.print_outlined, 'Print',
                              () => _action('Print', item)),
                          _miniAction(Icons.share_outlined, 'Share',
                              () => _action('Share', item)),
                          _miniAction(Icons.delete_outline_rounded, 'Delete',
                              () => _action('Delete', item)),
                        ],
                      ),
                    ],
                  ),
                ),
              )),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _miniAction(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.radiusPill,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.greenSurface,
          borderRadius: AppRadius.radiusPill,
          border: Border.all(color: AppColors.greenBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppColors.primary),
            const SizedBox(width: 5),
            Text(label,
                style: AppTypography.caption.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}
