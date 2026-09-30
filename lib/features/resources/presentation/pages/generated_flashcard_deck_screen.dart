import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/printing.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/auth/services/current_user_service.dart';
import '../../../../core/constants/flashcard_languages.dart';
import '../../../../core/content/flashcard/flashcard_image_library.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/sync/flashcard_image_pdf_writer.dart';
import '../../../../core/sync/flashcard_pdf_writer.dart';
import '../../../../core/sync/remote_content_data_source.dart';
import '../../../../core/sync/worksheet_download_store.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/custom_card.dart';
import '../widgets/generated_flashcard_card.dart';

/// Route payload for [GeneratedFlashcardDeckScreen] (passed as GoRouter
/// `extra`).
class GeneratedFlashcardDeckArgs {
  final Map<String, dynamic> payload;
  final Map<String, dynamic>? assets;
  final String contentId;

  const GeneratedFlashcardDeckArgs({
    required this.payload,
    required this.contentId,
    this.assets,
  });
}

/// The account-scoped download store (same resolution as Downloads).
Future<WorksheetDownloadStore> flashcardDownloadStore() async {
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

/// Saves a generated flashcard set to Downloads (PDF + payload, offline).
Future<WorksheetDownload> saveFlashcardDeck({
  required String contentId,
  required Map<String, dynamic> payload,
  Map<String, dynamic>? assets,
}) async {
  RemoteContentDataSource? remote;
  try {
    remote = getIt<RemoteContentDataSource>();
  } catch (_) {
    remote = null;
  }
  String? ownerId;
  try {
    ownerId = getIt.isRegistered<CurrentUserService>()
        ? getIt<CurrentUserService>().currentUserId
        : null;
  } catch (_) {}
  return downloadFlashcardSet(
    store: await flashcardDownloadStore(),
    remote: remote,
    contentId: contentId,
    contentPayload: payload,
    assets: assets,
    teacherId: ownerId,
  );
}

/// Full-screen study view for a generated (or downloaded) flashcard set:
/// one card at a time — tap/Flip to turn it over, swipe or Previous/Next
/// to move, Save to keep the set in Downloads for offline use.
class GeneratedFlashcardDeckScreen extends StatefulWidget {
  final Map<String, dynamic>? payload;
  final Map<String, dynamic>? assets;
  final String? contentId;

  /// Opened from Downloads: the set is already saved on this device.
  final bool openedFromDownloads;

  const GeneratedFlashcardDeckScreen({
    super.key,
    required this.payload,
    required this.contentId,
    this.assets,
    this.openedFromDownloads = false,
  });

  @override
  State<GeneratedFlashcardDeckScreen> createState() =>
      _GeneratedFlashcardDeckScreenState();
}

class _GeneratedFlashcardDeckScreenState
    extends State<GeneratedFlashcardDeckScreen> {
  final PageController _pageController = PageController();
  int _index = 0;
  bool _showBack = false;
  bool _saving = false;
  bool _saved = false;

  late final List<Map<String, dynamic>> _cards = ((widget.payload?['cards']
              as List?) ??
          const [])
      .whereType<Map>()
      .map((e) => Map<String, dynamic>.from(e))
      .toList();

  String get _mode => (widget.payload?['language_mode'] ?? 'hi_sat').toString();
  bool get _pronunciation => widget.payload?['pronunciation'] == true;

  @override
  void initState() {
    super.initState();
    _saved = widget.openedFromDownloads;
    if (!_saved) _checkSaved();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _checkSaved() async {
    final id = widget.contentId;
    if (id == null) return;
    try {
      final existing = await (await flashcardDownloadStore()).getByResourceId(id);
      if (mounted && existing != null) setState(() => _saved = true);
    } catch (_) {}
  }

  void _goTo(int i) {
    if (i < 0 || i >= _cards.length) return;
    _pageController.animateToPage(i,
        duration: const Duration(milliseconds: 280), curve: Curves.easeOut);
  }

  Future<void> _save() async {
    final payload = widget.payload;
    final id = widget.contentId;
    if (payload == null || id == null || _saving || _saved) return;
    setState(() => _saving = true);
    try {
      await saveFlashcardDeck(
          contentId: id, payload: payload, assets: widget.assets);
      if (!mounted) return;
      setState(() => _saved = true);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Saved to Downloads — available offline.'),
        action: SnackBarAction(
          label: 'Open',
          onPressed: () => context.go(AppRoutes.downloads),
        ),
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Save failed: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _print() async {
    final payload = widget.payload;
    if (payload == null) return;
    try {
      final bytes = isImageCatalogPayload(payload)
          ? await renderImageLibraryFlashcardPdf(payload)
          : renderFlashcardPdf(payload);
      await Printing.layoutPdf(
        onLayout: (_) async => Uint8List.fromList(bytes),
        name: '${widget.contentId ?? 'flashcards'}.pdf',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Print failed: $e')));
    }
  }

  void _showAll() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${_cards.length} flashcards',
                  style: AppTypography.cardTitle.copyWith(fontSize: 16)),
              const SizedBox(height: 4),
              Text('Tap a card to jump to it', style: AppTypography.caption),
              const SizedBox(height: 12),
              Flexible(
                child: GridView.builder(
                  shrinkWrap: true,
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 200,
                    childAspectRatio: 0.72,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: _cards.length,
                  itemBuilder: (_, i) => GestureDetector(
                    onTap: () {
                      Navigator.of(ctx).pop();
                      _goTo(i);
                    },
                    child: GeneratedFlashcardFace(
                      card: _cards[i],
                      languageMode: _mode,
                      compact: true,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              PrimaryButton(
                label: 'Close',
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final payload = widget.payload;
    if (payload == null || _cards.isEmpty) {
      return AppScaffold(
        title: 'Flashcards',
        subtitle: 'No flashcards to show',
        body: Center(
          child: CustomCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('This flashcard set is no longer open. Generate it again '
                    'or open it from Downloads.',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodySmall),
                const SizedBox(height: 12),
                PrimaryButton(
                  label: 'Generate Flashcards',
                  onPressed: () =>
                      context.pushReplacement(AppRoutes.flashcardGenerator),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final total = _cards.length;
    final isLast = _index == total - 1;
    final title = (payload['title'] ?? payload['topic'] ?? 'Flashcards').toString();

    return AppScaffold(
      title: title,
      subtitle:
          'Card ${_index + 1} of $total • ${FlashcardLanguageModes.byCode(_mode).label}',
      breadcrumb: widget.openedFromDownloads
          ? 'Downloads > Flashcards'
          : 'Teach > Flashcards > Study',
      headerTrailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.grid_view_rounded,
                color: AppColors.textSecondary),
            tooltip: 'All cards',
            onPressed: _showAll,
          ),
          IconButton(
            icon: const Icon(Icons.print_outlined, color: AppColors.textSecondary),
            tooltip: 'Print',
            onPressed: _print,
          ),
        ],
      ),
      bottomActionBar: Row(
        children: [
          Expanded(
            child: SecondaryButton(
              label: _showBack ? 'Show Front' : 'Flip',
              icon: Icons.flip_rounded,
              onPressed: () => setState(() => _showBack = !_showBack),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: PrimaryButton(
              label: _saving ? 'Saving...' : (_saved ? 'Saved' : 'Save'),
              icon: _saved
                  ? Icons.offline_pin_rounded
                  : Icons.download_rounded,
              onPressed: (_saved || _saving) ? null : _save,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: AppRadius.radiusPill,
                  child: LinearProgressIndicator(
                    value: (_index + 1) / total,
                    backgroundColor: AppColors.backgroundSoft,
                    color: AppColors.primary,
                    minHeight: 6,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text('${_index + 1}/$total',
                  style: AppTypography.caption.copyWith(
                      fontWeight: FontWeight.w700, color: AppColors.navy)),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480, maxHeight: 560),
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: total,
                  onPageChanged: (i) => setState(() {
                    _index = i;
                    _showBack = false;
                  }),
                  itemBuilder: (_, i) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    child: FlippableGeneratedFlashcard(
                      key: ValueKey(i),
                      card: _cards[i],
                      languageMode: _mode,
                      showPronunciation: _pronunciation,
                      showBack: i == _index && _showBack,
                      onFlip: () => setState(() => _showBack = !_showBack),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                onPressed: _index > 0 ? () => _goTo(_index - 1) : null,
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text('Previous'),
              ),
              TextButton.icon(
                onPressed: isLast ? () => _goTo(0) : () => _goTo(_index + 1),
                icon: Icon(isLast ? Icons.replay_rounded : Icons.arrow_forward_rounded),
                label: Text(isLast ? 'Start Again' : 'Next'),
                iconAlignment: IconAlignment.end,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
