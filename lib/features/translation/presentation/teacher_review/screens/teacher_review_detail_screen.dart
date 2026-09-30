import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../../app/theme/app_colors.dart';
import '../../../../../../core/widgets/app_scaffold.dart';
import '../models/teacher_review.dart';
import '../../../../../../core/review/review_models.dart';

/// Review Details — teacher-facing, READ-ONLY.
///
/// Tablet-first layout:
/// - Wide (>= 1100 px): context + status side-by-side, script/roman
///   side-by-side inside INPUT/OUTPUT.
/// - Medium (800–1099 px): script/roman stay side-by-side, top sections
///   stack when space is tight.
/// - Narrow (< 800 px): single-column fallback.
///
/// One vertical scroll container only — no nested scrolling.
/// No correction, verification, approval or resolution controls exist here.
class TeacherReviewDetailScreen extends StatelessWidget {
  final TeacherReview review;

  const TeacherReviewDetailScreen({super.key, required this.review});

  static String formatTimestamp(DateTime date) {
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

  @override
  Widget build(BuildContext context) {
    final isResolved = review.isResolved;
    final isHindiToSantali = review.direction == ReviewDirection.hindiToSantali;

    return AppScaffold(
      title: 'Review Details',
      subtitle: '${review.id} • ${review.directionLabel}',
      breadcrumb: 'Translate > Review > ${review.id}',
      showBackButton: true,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final isWide = width >= 1100;
          final isNarrow = width < 800;
          final horizontalPadding = isWide
              ? 40.0
              : width >= 800
                  ? 32.0
                  : 4.0;

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: 8,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Compact badge row: status + direction + confidence + priority.
                _buildBadgeRow(isResolved),
                const SizedBox(height: 6),
                Text(
                  formatTimestamp(review.createdAt),
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 20),

                // Context + review-status side-by-side on wide tablets.
                if (isWide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: _buildContextCard(isNarrow)),
                      const SizedBox(width: 16),
                      Expanded(flex: 2, child: _buildStatusCard(isResolved)),
                    ],
                  )
                else ...[
                  _buildContextCard(isNarrow),
                  const SizedBox(height: 16),
                  _buildStatusCard(isResolved),
                ],
                const SizedBox(height: 20),

                // INPUT section.
                _buildSectionTitle('INPUT — ${_inputLanguageLabel(isHindiToSantali)}'),
                const SizedBox(height: 10),
                _buildLanguageCard(
                  context: context,
                  isInput: true,
                  isHindiToSantali: isHindiToSantali,
                  sideBySide: !isNarrow,
                ),
                const SizedBox(height: 20),

                // OUTPUT section.
                _buildSectionTitle('OUTPUT — ${_outputLanguageLabel(isHindiToSantali)}'),
                const SizedBox(height: 10),
                _buildLanguageCard(
                  context: context,
                  isInput: false,
                  isHindiToSantali: isHindiToSantali,
                  sideBySide: !isNarrow,
                ),
                const SizedBox(height: 20),

                // Reason for review.
                _buildSectionTitle('REASON FOR REVIEW'),
                const SizedBox(height: 10),
                _buildInfoCard(review.reason),
                const SizedBox(height: 20),

                // Final reviewed translation (resolved reviews only).
                if (isResolved) ...[
                  _buildSectionTitle('FINAL REVIEWED TRANSLATION'),
                  const SizedBox(height: 10),
                  _buildFinalTranslationCard(),
                  const SizedBox(height: 20),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  // ------------------------------------------------------------------
  // Header badges
  // ------------------------------------------------------------------

  Widget _buildBadgeRow(bool isResolved) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _badge(
          icon: isResolved ? Icons.check_circle : Icons.pending,
          label: isResolved ? 'Resolved' : 'Pending Review',
          color: isResolved
              ? AppColors.statusAchieved
              : AppColors.statusDeveloping,
          background: isResolved
              ? AppColors.statusAchievedBg
              : AppColors.statusDevelopingBg,
        ),
        _badge(
          icon: Icons.translate,
          label: review.directionLabel,
          color: AppColors.accentBlue,
          background: AppColors.strandBlueBg,
        ),
        _badge(
          icon: Icons.psychology,
          label: '${review.confidenceScore}% Confidence',
          color: _confidenceColor(review.confidenceScore),
          background: _confidenceColor(review.confidenceScore)
              .withValues(alpha: 0.1),
        ),
        _badge(
          icon: Icons.flag,
          label: '${_priorityLabel(review.priority)} Priority',
          color: _priorityColor(review.priority),
          background:
              _priorityColor(review.priority).withValues(alpha: 0.1),
        ),
      ],
    );
  }

  Widget _badge({
    required IconData icon,
    required String label,
    required Color color,
    required Color background,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------
  // Context + status cards
  // ------------------------------------------------------------------

  Widget _buildContextCard(bool singleColumn) {
    final entries = [
      ('Class', review.context.className),
      ('Subject', review.context.subject),
      ('Topic', review.context.topic),
      ('Session', review.context.sessionLabel),
      ('Teacher', review.teacherName),
      ('Classroom', review.classroomName),
    ];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.backgroundSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeading('CLASSROOM CONTEXT'),
          const SizedBox(height: 12),
          if (singleColumn)
            ...entries.map((e) => _contextRow(e.$1, e.$2))
          else
            for (var i = 0; i < entries.length; i += 2)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _contextCell(entries[i].$1, entries[i].$2)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: i + 1 < entries.length
                          ? _contextCell(entries[i + 1].$1, entries[i + 1].$2)
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }

  Widget _contextRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 84,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.navy,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _contextCell(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.navy,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusCard(bool isResolved) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
          _cardHeading('REVIEW STATUS'),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${review.confidenceScore}%',
                style: GoogleFonts.inter(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: _confidenceColor(review.confidenceScore),
                  height: 1.0,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  'confidence',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: AppColors.divider, height: 1),
          const SizedBox(height: 12),
          _statusRow('Status', isResolved ? 'Resolved' : 'Pending Review'),
          _statusRow('Priority', _priorityLabel(review.priority)),
          _statusRow('Reviewed', formatTimestamp(review.createdAt)),
          if (review.reviewer != null)
            _statusRow('Reviewed by', review.reviewer!),
        ],
      ),
    );
  }

  Widget _statusRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.navy,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------
  // INPUT / OUTPUT language cards (direction-aware)
  // ------------------------------------------------------------------

  String _inputLanguageLabel(bool isHindiToSantali) =>
      isHindiToSantali ? 'Hindi' : 'Santali';

  String _outputLanguageLabel(bool isHindiToSantali) =>
      isHindiToSantali ? 'Santali' : 'Hindi';

  Widget _buildLanguageCard({
    required BuildContext context,
    required bool isInput,
    required bool isHindiToSantali,
    required bool sideBySide,
  }) {
    // Direction determines which language sits in INPUT vs OUTPUT.
    final bool showHindi;
    if (isHindiToSantali) {
      showHindi = isInput;
    } else {
      showHindi = !isInput;
    }

    final String scriptLabel;
    final String scriptText;
    final String romanLabel;
    final String romanText;
    final String audioLabel;
    final Color iconColor;
    if (showHindi) {
      scriptLabel = 'Hindi';
      scriptText = isInput ? review.originalText : review.effectiveTranslation;
      romanLabel = 'Hindi Roman';
      romanText = isInput ? review.originalRoman : review.effectiveRoman;
      audioLabel = 'Hindi Audio';
      iconColor = AppColors.accentBlue;
    } else {
      scriptLabel = 'Santali (Ol Chiki)';
      scriptText = isInput ? review.originalText : review.effectiveTranslation;
      romanLabel = 'Santali Roman';
      romanText = isInput ? review.originalRoman : review.effectiveRoman;
      audioLabel = 'Santali Audio';
      iconColor = AppColors.primary;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
          if (sideBySide)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: _scriptBlock(
                    scriptLabel,
                    scriptText,
                    iconColor,
                    isInput: isInput,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  flex: 2,
                  child: _romanBlock(romanLabel, romanText),
                ),
              ],
            )
          else ...[
            _scriptBlock(scriptLabel, scriptText, iconColor, isInput: isInput),
            const SizedBox(height: 12),
            _romanBlock(romanLabel, romanText),
          ],
          const SizedBox(height: 12),
          const Divider(color: AppColors.divider, height: 1),
          const SizedBox(height: 10),
          _audioRow(context, audioLabel, iconColor),
        ],
      ),
    );
  }

  Widget _scriptBlock(
    String label,
    String text,
    Color iconColor, {
    required bool isInput,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isInput ? Icons.input : Icons.output,
                color: iconColor,
                size: 18,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 19,
            fontWeight: FontWeight.w500,
            color: AppColors.navy,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _romanBlock(String label, String text) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 15,
            color: AppColors.textSecondary,
            fontStyle: FontStyle.italic,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _audioRow(BuildContext context, String label, Color iconColor) {
    return Row(
      children: [
        Icon(Icons.volume_up, color: iconColor, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        OutlinedButton.icon(
          onPressed: () => _playAudioPlaceholder(context),
          icon: Icon(Icons.play_arrow, size: 16, color: iconColor),
          label: Text(
            'Play Audio',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: iconColor,
            ),
          ),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: iconColor),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      ],
    );
  }

  void _playAudioPlaceholder(BuildContext context) {
    // Local-asset audio playback placeholder (behavior unchanged).
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Audio playback - local asset',
          style: GoogleFonts.inter(color: AppColors.textLight),
        ),
        backgroundColor: AppColors.navy,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ------------------------------------------------------------------
  // Reason + resolved result
  // ------------------------------------------------------------------

  Widget _buildInfoCard(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.backgroundSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 15,
          color: AppColors.textSecondary,
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildFinalTranslationCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.statusAchievedBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: AppColors.statusAchieved.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.check_circle,
                      color: AppColors.statusAchieved, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Final Reviewed Translation',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.statusAchieved,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                review.correctedText ?? review.effectiveTranslation,
                style: GoogleFonts.inter(
                  fontSize: 19,
                  fontWeight: FontWeight.w500,
                  color: AppColors.navy,
                  height: 1.5,
                ),
              ),
              if (review.correctedRoman != null) ...[
                const SizedBox(height: 8),
                Text(
                  review.correctedRoman!,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
              if (review.reviewer != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Reviewed by: ${review.reviewer}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ],
          ),
        ),
        // Original translation kept for comparison (compact reference).
        if (review.correctedText != null) ...[
          const SizedBox(height: 12),
          _buildSectionTitle('ORIGINAL TRANSLATION'),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.backgroundSoft,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  review.translatedText,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  review.translatedRoman,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.textMuted,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // ------------------------------------------------------------------
  // Shared bits
  // ------------------------------------------------------------------

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: AppColors.navy,
      ),
    );
  }

  Widget _cardHeading(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppColors.navy,
      ),
    );
  }

  Color _confidenceColor(int confidence) {
    if (confidence >= 80) return AppColors.statusAchieved;
    if (confidence >= 50) return AppColors.statusDeveloping;
    return AppColors.statusNeedsSupport;
  }

  String _priorityLabel(ReviewPriority priority) {
    switch (priority) {
      case ReviewPriority.high:
        return 'High';
      case ReviewPriority.medium:
        return 'Medium';
      case ReviewPriority.low:
        return 'Low';
    }
  }

  Color _priorityColor(ReviewPriority priority) {
    switch (priority) {
      case ReviewPriority.high:
        return AppColors.statusNeedsSupport;
      case ReviewPriority.medium:
        return AppColors.statusDeveloping;
      case ReviewPriority.low:
        return AppColors.statusAchieved;
    }
  }
}
