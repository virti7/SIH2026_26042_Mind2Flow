import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../enums/app_enums.dart';

class StatusChip extends StatelessWidget {
  final OutcomeStatus status;
  final bool showHindi;

  const StatusChip({
    super.key,
    required this.status,
    this.showHindi = false,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    IconData icon;

    switch (status) {
      case OutcomeStatus.achieved:
        bg = AppColors.statusAchievedBg;
        fg = AppColors.statusAchieved;
        icon = Icons.check_circle_rounded;
        break;
      case OutcomeStatus.developing:
        bg = AppColors.statusDevelopingBg;
        fg = AppColors.statusDeveloping;
        icon = Icons.timelapse_rounded;
        break;
      case OutcomeStatus.needsSupport:
        bg = AppColors.statusNeedsSupportBg;
        fg = AppColors.statusNeedsSupport;
        icon = Icons.error_outline_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              showHindi ? status.labelHindi : status.label,
              style: AppTypography.chipLabel.copyWith(
                color: fg,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact language pill — consistent everywhere.
/// Selected: light green background, green text, green border.
/// Unselected: white background, light grey border, navy text.
class LanguageChip extends StatelessWidget {
  final TribalLanguage language;
  final bool isSelected;
  final VoidCallback? onTap;

  const LanguageChip({
    super.key,
    required this.language,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.greenLight : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.cardBorder,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                language.displayName,
                style: AppTypography.chipLabel.copyWith(
                  color: isSelected ? AppColors.primaryDark : AppColors.navy,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                '(${language.hindiName})',
                style: AppTypography.caption.copyWith(
                  color: isSelected ? AppColors.primaryDark : AppColors.textMuted,
                  fontSize: 10,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Simple selectable class pill used in setup + teach filters.
class ClassPill extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;

  const ClassPill({super.key, required this.label, this.isSelected = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.greenLight : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.cardBorder,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.chipLabel.copyWith(
            color: isSelected ? AppColors.primaryDark : AppColors.navy,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
