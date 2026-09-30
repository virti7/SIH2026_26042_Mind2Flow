import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/content/flashcard/santali_flashcard_model.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/custom_card.dart';
import '../bloc/santali_flashcard_bloc.dart';

/// Screen allowing teachers and primary-school learners to browse
/// Santali vocabulary flashcard decks by category and track mastery progress.
class SantaliFlashcardBrowserScreen extends StatefulWidget {
  const SantaliFlashcardBrowserScreen({super.key});

  @override
  State<SantaliFlashcardBrowserScreen> createState() =>
      _SantaliFlashcardBrowserScreenState();
}

class _SantaliFlashcardBrowserScreenState
    extends State<SantaliFlashcardBrowserScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
    // Trigger loading of curriculum decks
    context.read<SantaliFlashcardBloc>().add(const LoadSantaliDecksEvent());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Santali Visual Flashcards',
      subtitle:
          'Mother-tongue primary vocabulary (166 cards) • 100% offline curriculum',
      breadcrumb: 'Resources > Santali Flashcards',
      isScrollable: true,
      body: BlocBuilder<SantaliFlashcardBloc, SantaliFlashcardState>(
        builder: (context, state) {
          if (state is SantaliFlashcardLoading) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(48.0),
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            );
          }

          if (state is SantaliFlashcardError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        color: AppColors.accentRed, size: 48),
                    const SizedBox(height: 12),
                    Text(
                      'Could not load flashcards',
                      style: AppTypography.screenTitle.copyWith(fontSize: 18),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      state.message,
                      style: AppTypography.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Try Again'),
                      onPressed: () => context
                          .read<SantaliFlashcardBloc>()
                          .add(const LoadSantaliDecksEvent()),
                    ),
                  ],
                ),
              ),
            );
          }

          if (state is SantaliFlashcardLoaded) {
            return _buildContent(context, state);
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, SantaliFlashcardLoaded state) {
    // Total progress calculations
    int totalCards = 0;
    int totalMastered = 0;
    int totalSeen = 0;

    for (final deck in state.decks) {
      totalCards += deck.cardCount;
      totalMastered += state.masteredCountForDeck(deck.id);
      totalSeen += state.seenCountForDeck(deck.id);
    }

    final filteredDecks = state.decks.where((d) {
      if (_searchQuery.isEmpty) return true;
      final matchTitle = d.title.toLowerCase().contains(_searchQuery);
      final matchCat = d.categoryKey.toLowerCase().contains(_searchQuery);
      final matchCards = d.cards.any((c) =>
          c.concept.toLowerCase().contains(_searchQuery) ||
          c.englishLabel.toLowerCase().contains(_searchQuery) ||
          c.keywords.any((k) => k.toLowerCase().contains(_searchQuery)));
      return matchTitle || matchCat || matchCards;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Overall Mastery Overview Card
        CustomCard(
          color: AppColors.surface,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.greenLight,
                          borderRadius: AppRadius.radiusMd,
                        ),
                        child: const Icon(
                          Icons.auto_stories_rounded,
                          color: AppColors.primary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Classroom Curriculum Deck',
                            style: AppTypography.screenTitle.copyWith(fontSize: 16),
                          ),
                          Text(
                            'Source: Aao Santali Likhna Sikhe (Ol Chiki)',
                            style: AppTypography.caption.copyWith(color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.greenSurface,
                      borderRadius: AppRadius.radiusPill,
                      border: Border.all(color: AppColors.greenBorder),
                    ),
                    child: Text(
                      '100% Offline',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Progress bar
              ClipRRect(
                borderRadius: AppRadius.radiusPill,
                child: LinearProgressIndicator(
                  value: totalCards > 0 ? totalMastered / totalCards : 0,
                  backgroundColor: AppColors.backgroundSoft,
                  color: AppColors.primary,
                  minHeight: 8,
                ),
              ),

              const SizedBox(height: 12),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatBadge(
                    label: 'Total Cards',
                    value: '$totalCards',
                    icon: Icons.style_rounded,
                    color: AppColors.navy,
                  ),
                  _buildStatBadge(
                    label: 'Studied',
                    value: '$totalSeen',
                    icon: Icons.visibility_rounded,
                    color: AppColors.accentBlue,
                  ),
                  _buildStatBadge(
                    label: 'Mastered',
                    value: '$totalMastered',
                    icon: Icons.check_circle_rounded,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Search Bar
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search decks, animals, birds, fruits...',
            hintStyle: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
            prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded, size: 18),
                    onPressed: () => _searchController.clear(),
                  )
                : null,
            filled: true,
            fillColor: AppColors.surface,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: AppRadius.radiusLg,
              borderSide: const BorderSide(color: AppColors.cardBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: AppRadius.radiusLg,
              borderSide: const BorderSide(color: AppColors.cardBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: AppRadius.radiusLg,
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Category Decks Section Title
        Text(
          'VOCABULARY DECKS (${filteredDecks.length})',
          style: AppTypography.caption.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.navy,
            letterSpacing: 0.5,
          ),
        ),

        const SizedBox(height: 12),

        // Decks Grid / List
        if (filteredDecks.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Text(
                'No flashcard decks match "$_searchQuery"',
                style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filteredDecks.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final deck = filteredDecks[index];
              return _buildDeckTile(context, deck, state);
            },
          ),

        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildStatBadge({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: AppTypography.caption.copyWith(
                fontWeight: FontWeight.w800,
                color: color,
                fontSize: 14,
              ),
            ),
            Text(
              label,
              style: AppTypography.caption.copyWith(
                color: AppColors.textMuted,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDeckTile(
    BuildContext context,
    FlashcardDeck deck,
    SantaliFlashcardLoaded state,
  ) {
    final mastered = state.masteredCountForDeck(deck.id);
    final seen = state.seenCountForDeck(deck.id);
    final total = deck.cardCount;
    final isComplete = total > 0 && mastered == total;

    // First card image preview if available
    final previewCard = deck.cards.isNotEmpty ? deck.cards.first : null;
    final previewImagePath = previewCard?.resolveImagePath(state.assetRoot);

    return CustomCard(
      padding: const EdgeInsets.all(14),
      onTap: () {
        context.read<SantaliFlashcardBloc>().add(SelectSantaliDeckEvent(deck.id));
        context.push('${AppRoutes.flashcardViewer}?deck=${deck.id}');
      },
      child: Row(
        children: [
          // Visual thumbnail container
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.backgroundSoft,
              borderRadius: AppRadius.radiusMd,
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: ClipRRect(
              borderRadius: AppRadius.radiusMd,
              child: previewImagePath != null
                  ? Image.asset(
                      previewImagePath,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.style_outlined,
                        color: AppColors.primary,
                        size: 28,
                      ),
                    )
                  : const Icon(
                      Icons.style_outlined,
                      color: AppColors.primary,
                      size: 28,
                    ),
            ),
          ),

          const SizedBox(width: 14),

          // Title & Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        deck.title,
                        style: AppTypography.screenTitle.copyWith(
                          fontSize: 16,
                          color: AppColors.navy,
                        ),
                      ),
                    ),
                    if (isComplete)
                      const Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.primary,
                        size: 18,
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '$total cards • ${deck.categoryKey.replaceAll('_', ' ')}',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),

                // Mastery badge / progress indicator
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: mastered > 0
                            ? AppColors.greenSurface
                            : AppColors.backgroundSoft,
                        borderRadius: AppRadius.radiusPill,
                        border: Border.all(
                          color: mastered > 0
                              ? AppColors.greenBorder
                              : AppColors.cardBorder,
                        ),
                      ),
                      child: Text(
                        mastered > 0
                            ? '$mastered / $total Mastered'
                            : (seen > 0 ? '$seen Studied' : 'Not started'),
                        style: AppTypography.caption.copyWith(
                          color: mastered > 0
                              ? AppColors.primaryDark
                              : AppColors.textMuted,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.textMuted,
            size: 24,
          ),
        ],
      ),
    );
  }
}
