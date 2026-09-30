import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../../app/di/injection.dart';
import '../../../../../app/theme/app_colors.dart';
import '../../../../../core/review/review_models.dart';
import '../../../../../core/review/review_stores.dart';
import '../../../../../core/widgets/app_scaffold.dart';
import '../../bloc/review_portal_bloc.dart';
import 'review_detail_screen.dart';

/// SCREEN: Reviewer Queue Portal
/// Lists all pending review items, sorted by confidence ascending
/// (lowest confidence = highest priority first).
class ReviewQueueScreen extends StatefulWidget {
  const ReviewQueueScreen({super.key});

  @override
  State<ReviewQueueScreen> createState() => _ReviewQueueScreenState();
}

class _ReviewQueueScreenState extends State<ReviewQueueScreen> {
  late final ReviewQueueStore _queue;

  @override
  void initState() {
    super.initState();
    _queue = getIt<ReviewQueueStore>();
    // Seed static demo items if queue is empty
    _seedStaticDemoItems();
  }

  void _seedStaticDemoItems() {
    if (_queue.all().isNotEmpty) return;

    final now = DateTime.now();

    // Static demo item A: phrase_003 (Santali -> Hindi, 38% confidence, HIGH priority)
    _queue.enqueue(
      phraseId: 'phrase_003',
      direction: ReviewDirection.santaliToHindi,
      originalText: 'ᱤᱧ ᱟᱢ ᱵᱟᱝ ᱵᱩᱡᱷᱟᱹᱣ ᱮᱫᱟᱸ',
      originalRoman: 'Iñ am bang bujhaṛ edañ.',
      translatedText: 'मैं यह नहीं समझ रहा हूँ',
      translatedRoman: 'Main yah nahin samajh raha hoon',
      confidenceScore: 38,
      reason: 'Teacher did not understand the translation',
      audioAsset:
          'assets/prototype_content/translation/audio/santali/santali_i_dont_understand_this.wav',
      createdAt: now.subtract(const Duration(minutes: 10)),
    );

    // Static demo item B: phrase_001 (Santali -> Hindi, 62% confidence, MEDIUM priority)
    _queue.enqueue(
      phraseId: 'phrase_001',
      direction: ReviewDirection.santaliToHindi,
      originalText: 'ᱤᱧ ᱱᱚᱣᱟ ᱵᱟᱝ ᱵᱩᱡᱷᱟᱹᱣ ᱮᱫᱟᱸ',
      originalRoman: 'Iñ nowa bang bujhaṛ edañ.',
      translatedText: 'मुझे यह नहीं समझ रहा है',
      translatedRoman: 'Mujhe yah nahin samajh raha hai',
      confidenceScore: 62,
      reason: 'Teacher did not understand the translation',
      audioAsset:
          'assets/prototype_content/translation/audio/santali/santali_i_dont_understand_this.wav',
      createdAt: now.subtract(const Duration(minutes: 5)),
    );

    // Static demo item C: phrase_004 (Hindi -> Santali, 78% confidence, MEDIUM priority)
    _queue.enqueue(
      phraseId: 'phrase_004',
      direction: ReviewDirection.hindiToSantali,
      originalText: 'मैं तुम्हें समझाती हूँ',
      originalRoman: 'Main tumhe samjhati hu',
      translatedText: 'ᱤᱧ ᱟᱢ ᱞᱟᱹᱜᱤᱛ ᱯᱟᱲᱦᱟᱣ ᱮᱫᱟᱸ',
      translatedRoman: 'Iñ am lāgit paṛhaw edañ.',
      confidenceScore: 78,
      reason: 'Student did not understand the translation',
      audioAsset:
          'assets/prototype_content/translation/audio/santali/santali_i_explain_to_you.wav',
      createdAt: now.subtract(const Duration(minutes: 2)),
    );

    // Notify bloc to refresh by accessing it from context
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReviewPortalBloc>().add(const LoadReviewQueue());
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReviewPortalBloc, ReviewPortalState>(
      builder: (context, state) {
        final pendingItems = state is ReviewPortalLoaded ? state.queue : [];
        final resolvedItems =
            state is ReviewPortalLoaded ? state.resolved : [];
        final allItems = [...pendingItems, ...resolvedItems];

        return AppScaffold(
          title: 'Reviewer Portal',
          subtitle:
              'Translation review queue — ordered by confidence (lowest first = highest priority).',
          breadcrumb: 'Translate > Reviewer Portal',
          isScrollable: true,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F9FF),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: const Color(0xFFBAE6FD), width: 1),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildSummaryStat(
                        'Total Reviews',
                        allItems.length.toString(),
                        Icons.assignment_rounded,
                        AppColors.navy,
                      ),
                    ),
                    Container(
                        width: 1,
                        height: 40,
                        color: const Color(0xFFBAE6FD)),
                    Expanded(
                      child: _buildSummaryStat(
                        'Pending',
                        pendingItems.length.toString(),
                        Icons.pending_actions_rounded,
                        const Color(0xFFB45309),
                      ),
                    ),
                    Container(
                        width: 1,
                        height: 40,
                        color: const Color(0xFFBAE6FD)),
                    Expanded(
                      child: _buildSummaryStat(
                        'Resolved',
                        resolvedItems.length.toString(),
                        Icons.check_circle_rounded,
                        AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Review items list
              if (allItems.isEmpty)
                _buildEmptyState()
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: allItems.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = allItems[index];
                    return _buildReviewCard(context, item);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryStat(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 6),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.assignment_turned_in_rounded,
                size: 48,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No Review Items',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.navy,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Review items will appear here when a teacher or student '
              'taps NO on the Understanding Check.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewCard(BuildContext context, ReviewItem item) {
    final isPending = item.status == ReviewItemStatus.pending;

    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ReviewDetailScreen(reviewItem: item),
        ),
      ),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isPending ? AppColors.primary : AppColors.cardBorder,
            width: isPending ? 1.5 : 1,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x06000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row: ID, direction, status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item.id,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      item.directionLabel,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.navy,
                      ),
                    ),
                  ],
                ),
                _buildStatusBadge(item.status),
              ],
            ),
            const SizedBox(height: 12),

            // Confidence + Priority (prominent)
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color:
                        _priorityColor(item.priority).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: _priorityColor(item.priority), width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.analytics_outlined, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        'Confidence: ${item.confidenceScore}%',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _priorityColor(item.priority),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color:
                        _priorityColor(item.priority).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: _priorityColor(item.priority), width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.priority_high_rounded, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        item.priority.shortLabel,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _priorityColor(item.priority),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Original text
            _buildTextRow(
                'Original (${item.direction == ReviewDirection.santaliToHindi ? 'Santali' : 'Hindi'})',
                item.originalText,
                AppColors.navy),
            if (item.originalRoman.isNotEmpty)
              _buildTextRow('Roman', item.originalRoman, AppColors.textSecondary),
            const SizedBox(height: 8),

            // Current translation
            _buildTextRow(
              'Current Translation (${item.direction == ReviewDirection.santaliToHindi ? 'Hindi' : 'Santali'})',
              item.translatedText,
              AppColors.primary,
            ),
            if (item.translatedRoman.isNotEmpty)
              _buildTextRow('Roman', item.translatedRoman, AppColors.textSecondary),

            // Corrected preview if exists
            if (item.correctedText != null && item.correctedText!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.primary, width: 1),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.verified_rounded,
                        size: 16, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Corrected by Expert:',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.correctedText!,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.navy,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 12),

            // Context + reason + date
            Row(
              children: [
                Expanded(
                  child: _buildInfoChip(
                    Icons.school_rounded,
                    item.context.summary,
                    AppColors.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildInfoChip(
                    Icons.help_outline_rounded,
                    item.reason,
                    const Color(0xFFB45309),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                if (item.audioAsset != null && item.audioAsset!.isNotEmpty)
                  Expanded(
                    child: _buildInfoChip(
                      Icons.audiotrack_rounded,
                      'Audio available',
                      AppColors.accentBlue,
                    ),
                  ),
                if (item.audioAsset != null && item.audioAsset!.isNotEmpty)
                  const SizedBox(width: 8),
                Expanded(
                  child: _buildInfoChip(
                    Icons.access_time_rounded,
                    DateFormat('MMM d, HH:mm').format(item.createdAt),
                    AppColors.textMuted,
                  ),
                ),
              ],
            ),

            // Tap hint
            if (isPending) ...[
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Tap to review and correct →',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTextRow(String label, String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: color,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(ReviewItemStatus status) {
    Color bgColor;
    Color textColor;
    switch (status) {
      case ReviewItemStatus.pending:
        bgColor = const Color(0xFFFEF3C7);
        textColor = const Color(0xFFB45309);
        break;
      case ReviewItemStatus.corrected:
        bgColor = const Color(0xFFDBEAFE);
        textColor = AppColors.primary;
        break;
      case ReviewItemStatus.approved:
        bgColor = const Color(0xFFF0FDF4);
        textColor = AppColors.primary;
        break;
      case ReviewItemStatus.resolved:
        bgColor = const Color(0xFFF1F5F9);
        textColor = AppColors.textMuted;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
            color: textColor.withValues(alpha: 0.3), width: 1),
      ),
      child: Text(
        status.label,
        style: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Color _priorityColor(ReviewPriority priority) {
    switch (priority) {
      case ReviewPriority.high:
        return AppColors.accentRed;
      case ReviewPriority.medium:
        return const Color(0xFFB45309);
      case ReviewPriority.low:
        return AppColors.primary;
    }
  }
}