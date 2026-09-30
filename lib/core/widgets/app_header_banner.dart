import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import 'badges.dart';

/// Calm ivory page header: breadcrumb + navy title + subtitle.
/// No harsh gradients, no oversized illustration — illustration lives in body.
class AppHeaderBanner extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? breadcrumb;
  final bool showBackButton;
  final VoidCallback? onBack;
  final Widget? trailing;
  final bool showNipunBadge;
  final bool compact;

  const AppHeaderBanner({
    super.key,
    required this.title,
    this.subtitle,
    this.breadcrumb,
    this.showBackButton = true,
    this.onBack,
    this.trailing,
    this.showNipunBadge = true,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(
          bottom: BorderSide(color: AppColors.cardBorder, width: 1),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        compact ? 8 : 14,
        20,
        compact ? 12 : 18,
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (showBackButton && (canPop || onBack != null)) ...[
                  InkWell(
                    onTap: onBack ?? () => context.pop(),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.cardBorder, width: 1),
                      ),
                      child: const Icon(
                        Icons.arrow_back_rounded,
                        size: 18,
                        color: AppColors.navy,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                if (breadcrumb != null)
                  Expanded(
                    child: Text(
                      breadcrumb!.toUpperCase(),
                      style: AppTypography.caption.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        fontSize: 10,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  )
                else
                  const Spacer(),
                if (showNipunBadge) const Flexible(child: NipunBadge()),
                if (trailing != null) ...[
                  const SizedBox(width: 8),
                  trailing!,
                ],
              ],
            ),
            SizedBox(height: compact ? 8 : 12),
            Text(
              title,
              style: compact
                  ? AppTypography.cardTitle.copyWith(fontSize: 19)
                  : AppTypography.screenTitle,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
