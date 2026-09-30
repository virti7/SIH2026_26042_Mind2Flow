import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../../app/theme/app_colors.dart';
import '../models/teacher_review.dart';
import '../../../../../../core/review/review_models.dart';

/// Compact read-only review card for the teacher review list.
///
/// Information hierarchy (top to bottom):
/// 1. Review ID + direction … status
/// 2. Confidence + priority + context
/// 3. Reason (single line)
/// 4. Timestamp … View Details →
///
/// No correct / edit / approve / verify / resolve controls exist here —
/// those belong to the separate reviewer / language-expert portal.
class TeacherReviewCard extends StatelessWidget {
  final TeacherReview review;
  final VoidCallback onTap;

  const TeacherReviewCard({
    super.key,
    required this.review,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isResolved = review.isResolved;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cardBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: ID + direction … status
            Row(
              children: [
                Text(
                  review.id,
                  style: GoogleFonts.inter(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.navy,
                  ),
                ),
                const SizedBox(width: 10),
                _buildDirectionChip(),
                const Spacer(),
                _buildStatusChip(isResolved),
              ],
            ),
            const SizedBox(height: 8),

            // Row 2: confidence + priority + context summary
            Row(
              children: [
                _buildConfidenceBadge(),
                const SizedBox(width: 8),
                _buildPriorityChip(),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    review.context.summary,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Row 3: reason (single line)
            Text(
              review.reason,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textMuted,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),

            // Row 4: timestamp … view action
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 14,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: 4),
                Text(
                  _formatDate(review.createdAt),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
                const Spacer(),
                Text(
                  'View Details →',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(bool isResolved) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isResolved
            ? AppColors.statusAchievedBg
            : AppColors.statusDevelopingBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        isResolved ? 'Resolved' : 'Pending Review',
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isResolved
              ? AppColors.statusAchieved
              : AppColors.statusDeveloping,
        ),
      ),
    );
  }

  Widget _buildDirectionChip() {
    final isHindiToSantali = review.direction == ReviewDirection.hindiToSantali;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isHindiToSantali
            ? AppColors.strandGreenBg
            : AppColors.strandBlueBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        review.directionLabel,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isHindiToSantali
              ? AppColors.primaryDark
              : AppColors.accentBlue,
        ),
      ),
    );
  }

  Widget _buildConfidenceBadge() {
    final confidence = review.confidenceScore;
    Color confidenceColor;
    if (confidence >= 80) {
      confidenceColor = AppColors.statusAchieved;
    } else if (confidence >= 50) {
      confidenceColor = AppColors.statusDeveloping;
    } else {
      confidenceColor = AppColors.statusNeedsSupport;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: confidenceColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        'Confidence $confidence%',
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: confidenceColor,
        ),
      ),
    );
  }

  Widget _buildPriorityChip() {
    Color priorityColor;
    String priorityLabel;
    switch (review.priority) {
      case ReviewPriority.high:
        priorityColor = AppColors.statusNeedsSupport;
        priorityLabel = 'High';
        break;
      case ReviewPriority.medium:
        priorityColor = AppColors.statusDeveloping;
        priorityLabel = 'Medium';
        break;
      case ReviewPriority.low:
        priorityColor = AppColors.statusAchieved;
        priorityLabel = 'Low';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: priorityColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.flag,
            size: 12,
            color: priorityColor,
          ),
          const SizedBox(width: 4),
          Text(
            priorityLabel,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: priorityColor,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    final month = months[date.month - 1];
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$month ${date.day} • $hour:$minute';
  }
}
