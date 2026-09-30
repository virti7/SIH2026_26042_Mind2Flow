import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../bloc/santali_flashcard_bloc.dart';
import '../widgets/santali_card_widget.dart';

/// Screen where primary-school learners interactively practice
/// a specific Santali vocabulary deck. Supports tap-to-reveal,
/// "Need Practice" vs "I Know" feedback, and local progress tracking.
class SantaliFlashcardPlayerScreen extends StatelessWidget {
  final String? initialDeckId;

  const SantaliFlashcardPlayerScreen({
    super.key,
    this.initialDeckId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SantaliFlashcardBloc, SantaliFlashcardState>(
      listener: (context, state) {
        // If state is loaded and initialDeckId was requested but not active, switch to it
        if (state is SantaliFlashcardLoaded &&
            initialDeckId != null &&
            state.activeDeck?.id != initialDeckId) {
          context.read<SantaliFlashcardBloc>().add(SelectSantaliDeckEvent(initialDeckId!));
        }
      },
      builder: (context, state) {
        if (state is SantaliFlashcardLoading) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }

        if (state is! SantaliFlashcardLoaded || state.activeDeck == null) {
          return AppScaffold(
            title: 'Flashcard Player',
            subtitle: 'Offline vocabulary practice',
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('No deck selected.'),
                  const SizedBox(height: 12),
                  PrimaryButton(
                    label: 'Choose a Deck',
                    onPressed: () => context.pop(),
                  ),
                ],
              ),
            ),
          );
        }

        final deck = state.activeDeck!;
        final card = state.currentCard;
        final total = state.totalCardsInDeck;
        final currentIndex = state.currentIndex;
        final isRevealed = state.isRevealed;

        if (card == null || total == 0) {
          return AppScaffold(
            title: deck.title,
            subtitle: 'Deck is empty',
            body: Center(
              child: PrimaryButton(
                label: 'Back to Decks',
                onPressed: () => context.pop(),
              ),
            ),
          );
        }

        final progressFraction = (currentIndex + 1) / total;

        return AppScaffold(
          title: deck.title,
          subtitle: 'Card ${currentIndex + 1} of $total • Tap card to reveal answer',
          breadcrumb: 'Flashcards > ${deck.title}',
          isScrollable: true,
          headerTrailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.replay_rounded, color: AppColors.textSecondary),
                tooltip: 'Restart Deck (from Card 1)',
                onPressed: () {
                  context.read<SantaliFlashcardBloc>().add(const RestartDeckEvent());
                },
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded, color: AppColors.textSecondary),
                tooltip: 'Options',
                onSelected: (val) {
                  if (val == 'clear_progress') {
                    _confirmResetDeck(context, deck.id, deck.title);
                  }
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(
                    value: 'clear_progress',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline_rounded, color: AppColors.accentRed, size: 18),
                        SizedBox(width: 8),
                        Text('Clear Saved Progress', style: TextStyle(color: AppColors.accentRed)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          bottomActionBar: _buildBottomActions(context, state, isRevealed),
          body: Column(
            children: [
              // Top linear progress bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: AppRadius.radiusPill,
                        child: LinearProgressIndicator(
                          value: progressFraction,
                          backgroundColor: AppColors.backgroundSoft,
                          color: AppColors.primary,
                          minHeight: 6,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${currentIndex + 1}/$total',
                      style: AppTypography.caption.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.navy,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // The Card Widget
              SantaliCardWidget(
                card: card,
                assetRoot: state.assetRoot,
                isRevealed: isRevealed,
                onFlip: () {
                  context.read<SantaliFlashcardBloc>().add(FlipCardEvent());
                },
              ),

              const SizedBox(height: 16),

              // Previous / Next quick step controls
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton.icon(
                      onPressed: currentIndex > 0
                          ? () => context.read<SantaliFlashcardBloc>().add(PreviousCardEvent())
                          : null,
                      icon: const Icon(Icons.arrow_back_rounded, size: 18),
                      label: const Text('Previous'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        disabledForegroundColor: AppColors.cardBorder,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: currentIndex < total - 1
                          ? () => context.read<SantaliFlashcardBloc>().add(NextCardEvent())
                          : () => _showCompletionDialog(context, deck.title),
                      icon: Icon(
                        currentIndex < total - 1
                            ? Icons.arrow_forward_rounded
                            : Icons.check_circle_rounded,
                        size: 18,
                      ),
                      label: Text(currentIndex < total - 1 ? 'Skip' : 'Finish Deck'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                      ),
                    ),
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

  Widget _buildBottomActions(
    BuildContext context,
    SantaliFlashcardLoaded state,
    bool isRevealed,
  ) {
    if (!isRevealed) {
      return SizedBox(
        width: double.infinity,
        child: PrimaryButton(
          label: 'Reveal Answer',
          icon: Icons.visibility_rounded,
          onPressed: () {
            context.read<SantaliFlashcardBloc>().add(FlipCardEvent());
          },
        ),
      );
    }

    // Answer evaluation row: Need Practice vs I Know
    final isLastCard = state.currentIndex == state.totalCardsInDeck - 1;

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              context.read<SantaliFlashcardBloc>().add(
                    const AnswerCardEvent(isCorrect: false),
                  );
              if (isLastCard) {
                _showCompletionDialog(context, state.activeDeck!.title);
              }
            },
            icon: const Icon(Icons.replay_rounded, color: AppColors.accentOrange),
            label: Text(
              'Need Practice',
              style: AppTypography.buttonText.copyWith(color: AppColors.accentOrange),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: AppColors.accentOrange, width: 1.5),
              shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusMd),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: PrimaryButton(
            label: 'I Know',
            icon: Icons.check_rounded,
            onPressed: () {
              context.read<SantaliFlashcardBloc>().add(
                    const AnswerCardEvent(isCorrect: true),
                  );
              if (isLastCard) {
                _showCompletionDialog(context, state.activeDeck!.title);
              }
            },
          ),
        ),
      ],
    );
  }

  void _confirmResetDeck(BuildContext context, String deckId, String deckTitle) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Saved Progress?'),
        content: Text(
          'This will permanently delete your recorded answers and mastery count for "$deckTitle" from the local SQLite database.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentRed,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              context.read<SantaliFlashcardBloc>().add(ResetDeckProgressEvent(deckId));
              Navigator.of(ctx).pop();
            },
            child: const Text('Clear Progress'),
          ),
        ],
      ),
    );
  }

  void _showCompletionDialog(BuildContext context, String deckTitle) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusLg),
        title: Row(
          children: [
            const Icon(Icons.celebration_rounded, color: AppColors.primary, size: 28),
            const SizedBox(width: 10),
            Text('Deck Completed!', style: AppTypography.screenTitle.copyWith(fontSize: 18)),
          ],
        ),
        content: Text(
          'Great work! You have reviewed all cards in "$deckTitle". Your learning progress has been saved locally.',
          style: AppTypography.bodySmall,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.pop(); // Go back to browser
            },
            child: const Text('Back to Decks'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<SantaliFlashcardBloc>().add(const RestartDeckEvent());
            },
            child: const Text('Practice Again'),
          ),
        ],
      ),
    );
  }
}
