import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/content/flashcard/santali_flashcard_model.dart';

/// Interactive visual flashcard widget for Santali vocabulary.
/// Respects source book provenance, renders printed label images
/// as ground truth, and displays full-bleed swatches for colours.
class SantaliCardWidget extends StatelessWidget {
  final CurriculumFlashcard card;
  final String assetRoot;
  final bool isRevealed;
  final VoidCallback onFlip;

  const SantaliCardWidget({
    super.key,
    required this.card,
    required this.assetRoot,
    required this.isRevealed,
    required this.onFlip,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onFlip,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeInOut,
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 440, minHeight: 480),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.radiusXl,
          border: Border.all(
            color: isRevealed ? AppColors.greenBorder : AppColors.cardBorder,
            width: isRevealed ? 2.5 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isRevealed
                  ? AppColors.primary.withValues(alpha: 0.12)
                  : Colors.black.withValues(alpha: 0.06),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: isRevealed ? _buildBackContent(context) : _buildFrontContent(context),
      ),
    );
  }

  /// Front Face: Prominent visual asset, category tag, and clear "Tap to Reveal" prompt
  Widget _buildFrontContent(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Top tag row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.greenLight,
                borderRadius: AppRadius.radiusPill,
              ),
              child: Text(
                card.category.toUpperCase().replaceAll('_', ' '),
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

        // Visual asset (centerpiece). Fixed height (the large visual is at
        // most 240): the player hosts this card in a scroll view, where
        // an Expanded child gets unbounded height and layout fails.
        SizedBox(
          height: 260,
          child: Center(
            child: _buildVisualAsset(large: true),
          ),
        ),

        const SizedBox(height: 16),

        // Tap to reveal instruction
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.backgroundSoft,
            borderRadius: AppRadius.radiusMd,
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.touch_app_rounded, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Tap to reveal answer',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Back Face (learner-facing answer): picture, English answer, Hindi
  /// meaning and the Santhali answer. Provenance / verification metadata
  /// is deliberately not shown to learners.
  Widget _buildBackContent(BuildContext context) {
    final santaliText =
        card.santali.hasText ? card.santali.value!.trim() : null;
    // Only when no Santhali text exists, fall back to the word as printed.
    final santaliImagePath =
        santaliText == null ? card.resolveLabelImagePath(assetRoot) : null;
    final hindi = card.hindiMeaning?.trim() ?? '';

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.greenSurface,
              borderRadius: AppRadius.radiusPill,
              border: Border.all(color: AppColors.greenBorder),
            ),
            child: Text(
              'ANSWER',
              style: AppTypography.caption.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
                fontSize: 11,
              ),
            ),
          ),
        ),

        const SizedBox(height: 8),

        // 1. Picture (strongest visual element)
        SizedBox(
          height: 150,
          child: Center(child: _buildVisualAsset(large: false)),
        ),

        const SizedBox(height: 14),

        // 2. English answer (primary)
        Text(
          card.displayEnglish.toUpperCase(),
          style: AppTypography.screenTitle.copyWith(
            fontSize: 24,
            color: AppColors.navy,
            fontWeight: FontWeight.w800,
          ),
          textAlign: TextAlign.center,
        ),

        // 3. Hindi meaning (secondary)
        if (hindi.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            hindi,
            style: AppTypography.devanagariHeading.copyWith(
              fontSize: 19,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],

        // 4. Santhali answer (Ol Chiki)
        if (santaliText != null || santaliImagePath != null) ...[
          const SizedBox(height: 14),
          Text(
            'SANTHALI',
            style: AppTypography.caption.copyWith(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w700,
              fontSize: 10,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          if (santaliText != null)
            Text(
              santaliText,
              style: AppTypography.screenTitle.copyWith(
                fontSize: 26,
                color: AppColors.primaryDark,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            )
          else
            Image.asset(
              santaliImagePath!,
              height: 40,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) =>
                  const SizedBox.shrink(),
            ),
        ],

        const SizedBox(height: 14),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.refresh_rounded,
                size: 14, color: AppColors.textMuted),
            const SizedBox(width: 4),
            Text(
              'Tap to flip back',
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

  /// Builds the visual representation of the asset.
  /// For colours: renders dominant full color swatch.
  /// For objects: renders the clean 512x512 visual PNG.
  Widget _buildVisualAsset({required bool large}) {
    if (card.isColour) {
      return _buildColourSwatch(large: large);
    }

    final imagePath = card.resolveImagePath(assetRoot);
    final size = large ? 240.0 : 130.0;

    return Container(
      constraints: BoxConstraints(maxHeight: size, maxWidth: size),
      decoration: BoxDecoration(
        color: AppColors.backgroundSoft,
        borderRadius: AppRadius.radiusLg,
      ),
      child: ClipRRect(
        borderRadius: AppRadius.radiusLg,
        child: Image.asset(
          imagePath,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              height: size,
              width: size,
              alignment: Alignment.center,
              color: AppColors.greenSurface,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.image_not_supported_rounded, color: AppColors.textMuted, size: 36),
                  const SizedBox(height: 4),
                  Text(
                    card.concept,
                    style: AppTypography.caption.copyWith(color: AppColors.textMuted),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// Colour Flashcard Special Case: The color itself dominates the visual
  Widget _buildColourSwatch({required bool large}) {
    final swatchColor = _resolveSwatchColor(card.concept);
    final height = large ? 220.0 : 120.0;

    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: swatchColor,
        borderRadius: AppRadius.radiusLg,
        border: Border.all(
          color: swatchColor == Colors.white ? AppColors.cardBorder : Colors.transparent,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: swatchColor.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Overlay asset image cleanly if available
          ClipRRect(
            borderRadius: AppRadius.radiusLg,
            child: Image.asset(
              card.resolveImagePath(assetRoot),
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }

  static Color _resolveSwatchColor(String concept) {
    switch (concept.toLowerCase().trim()) {
      case 'red':
        return const Color(0xFFE53935);
      case 'blue':
        return const Color(0xFF1E88E5);
      case 'yellow':
        return const Color(0xFFFDD835);
      case 'black':
        return const Color(0xFF212121);
      case 'green':
        return const Color(0xFF43A047);
      case 'white':
        return Colors.white;
      default:
        return AppColors.primary;
    }
  }
}
