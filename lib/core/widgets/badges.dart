import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../enums/app_enums.dart';

/// Subtle friendly offline identity. Never scary, never technical.
class OfflineBadge extends StatelessWidget {
  final bool isOfflineReady;

  const OfflineBadge({super.key, this.isOfflineReady = true});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.greenLight,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.greenBorder, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              'Offline Ready',
              style: AppTypography.chipLabel.copyWith(
                color: AppColors.primaryDark,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class SyncBadge extends StatelessWidget {
  final SyncStatusState status;

  const SyncBadge({super.key, this.status = SyncStatusState.synced});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.pastelBlue,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.sync_rounded, size: 13, color: AppColors.accentBlue),
          const SizedBox(width: 4),
          Text(
            status.label,
            style: AppTypography.chipLabel.copyWith(
              color: AppColors.accentBlue,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class NipunBadge extends StatelessWidget {
  const NipunBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _NDot(),
          SizedBox(width: 5),
          Flexible(
            child: Text(
              'NIPUN Bharat',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.navy,
                letterSpacing: 0.2,
              ),
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _NDot extends StatelessWidget {
  const _NDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 15,
      height: 15,
      decoration: const BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
      ),
      child: const Center(
        child: Text(
          'N',
          style: TextStyle(
            color: Colors.white,
            fontSize: 9,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

/// Small pastel pill used on onboarding hero (Ho / Mundari / Santali).
class LanguageMiniChip extends StatelessWidget {
  final String label;
  final Color background;

  const LanguageMiniChip({super.key, required this.label, required this.background});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Text(
        label,
        style: AppTypography.chipLabel.copyWith(
          color: AppColors.navy,
          fontSize: 11,
        ),
      ),
    );
  }
}
