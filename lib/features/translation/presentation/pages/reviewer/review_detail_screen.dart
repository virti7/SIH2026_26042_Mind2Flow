import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../app/di/injection.dart';
import '../../../../../app/theme/app_colors.dart';
import '../../../../../app/theme/app_typography.dart';
import '../../../../../core/content/santali_audio_player.dart';
import '../../../../../core/review/review_models.dart';
import '../../../../../core/review/review_stores.dart';
import '../../../../../core/widgets/app_buttons.dart';
import '../../../../../core/widgets/app_scaffold.dart';
import '../../../../../core/widgets/audio_play_button.dart';
import '../../bloc/translation_bloc.dart';

/// SCREEN: Review Detail
/// Full context for reviewer: original, translation, audio, confidence,
/// classroom context, reason. Editable correction input + Send Correction.
class ReviewDetailScreen extends StatefulWidget {
  final ReviewItem reviewItem;

  const ReviewDetailScreen({super.key, required this.reviewItem});

  @override
  State<ReviewDetailScreen> createState() => _ReviewDetailScreenState();
}

class _ReviewDetailScreenState extends State<ReviewDetailScreen> {
  late final ReviewQueueStore _queue;
  late final TranslationMemoryStore _memory;
  late final CorrectionNoticeStore _notices;
  late final SantaliAudioPlayer? _audioPlayer;

  late TextEditingController _correctionController;
  late ReviewItem _currentItem;
  bool _isSubmitting = false;
  String? _submitMessage;

  @override
  void initState() {
    super.initState();
    _queue = getIt<ReviewQueueStore>();
    _memory = getIt<TranslationMemoryStore>();
    _notices = getIt<CorrectionNoticeStore>();
    _audioPlayer = getIt<SantaliAudioPlayer>();

    _currentItem = widget.reviewItem;
    _correctionController = TextEditingController(
      text: _currentItem.correctedText ?? _currentItem.translatedText,
    );

    // Refresh from queue in case status changed
    final fromQueue = _queue.byId(_currentItem.id);
    if (fromQueue != null) _currentItem = fromQueue;
  }

  @override
  void dispose() {
    _correctionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPending = _currentItem.status == ReviewItemStatus.pending;

    return AppScaffold(
      title: 'Review Detail',
      subtitle: 'Inspect context, edit translation, send correction to teacher portal.',
      breadcrumb: 'Translate > Reviewer Portal > ${_currentItem.id}',
      isScrollable: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _statusBgColor(_currentItem.status).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _statusTextColor(_currentItem.status), width: 1),
            ),
            child: Row(
              children: [
                Icon(
                  _statusIcon(_currentItem.status),
                  color: _statusTextColor(_currentItem.status),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _currentItem.id,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _statusTextColor(_currentItem.status),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _currentItem.directionLabel,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.navy,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildPriorityBadge(),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Classroom Context (§10) - prominently displayed
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F9FF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFBAE6FD), width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.school_rounded, color: AppColors.primary, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Classroom Context',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryDark,
                      ),
),
                  ],
                ),
                const SizedBox(height: 12),
                _buildContextRow('Class', _currentItem.context.className),
                _buildContextRow('Subject', _currentItem.context.subject),
                _buildContextRow('Topic', _currentItem.context.topic),
                _buildContextRow('Session', _currentItem.context.sessionLabel),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Original Input
          _buildSectionCard(
            title: 'Original Input (${_currentItem.direction == ReviewDirection.santaliToHindi ? 'Santali' : 'Hindi'})',
            icon: Icons.record_voice_over_rounded,
            iconColor: AppColors.navy,
            children: [
              _buildTextDisplay(_currentItem.originalText, AppColors.navy),
              if (_currentItem.originalRoman.isNotEmpty) ...[
                const SizedBox(height: 8),
                _buildTextDisplay(_currentItem.originalRoman, AppColors.textSecondary, fontSize: 13),
              ],
              if (_currentItem.audioAsset != null && _currentItem.audioAsset!.isNotEmpty) ...[
                const SizedBox(height: 12),
                AudioPlayButton(
                  compact: false,
                  onPlay: () async {
                    try {
                      await _audioPlayer?.playAsset(_currentItem.audioAsset!);
                    } catch (_) {}
                  },
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),

          // Current Prototype Translation
          _buildSectionCard(
            title: 'Current Prototype Translation (${_currentItem.direction == ReviewDirection.santaliToHindi ? 'Hindi' : 'Santali'})',
            icon: Icons.translate_rounded,
            iconColor: AppColors.primary,
            children: [
              _buildTextDisplay(_currentItem.translatedText, AppColors.primary),
              if (_currentItem.translatedRoman.isNotEmpty) ...[
                const SizedBox(height: 8),
                _buildTextDisplay(_currentItem.translatedRoman, AppColors.textSecondary, fontSize: 13),
              ],
            ],
          ),
          const SizedBox(height: 16),

          // Confidence + Priority + Reason
          _buildSectionCard(
            title: 'Confidence & Review Priority',
            icon: Icons.analytics_outlined,
            iconColor: _priorityColor(_currentItem.priority),
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      'Confidence Score',
                      '${_currentItem.confidenceScore}%',
                      Icons.speed_rounded,
                      _priorityColor(_currentItem.priority),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      'Priority',
                      _currentItem.priority.label,
                      Icons.priority_high_rounded,
                      _priorityColor(_currentItem.priority),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: _currentItem.confidenceScore / 100,
                  backgroundColor: const Color(0xFFFDE68A),
                  valueColor: AlwaysStoppedAnimation(_priorityColor(_currentItem.priority)),
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFCD34D), width: 1),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline_rounded, color: Color(0xFFB45309), size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Reason for Review',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFFB45309),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _currentItem.reason,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                                color: AppColors.navy,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
],
            ),
            const SizedBox(height: 16),

          // Correction Input (§11)
          _buildSectionCard(
            title: 'Expert Correction',
            icon: Icons.edit_rounded,
            iconColor: AppColors.accentPurple,
            children: [
              Text(
                'Edit the translation below. The corrected version will be sent to the teacher portal and stored in Translation Memory for future use.',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _correctionController,
                maxLines: 4,
                enabled: isPending,
                decoration: InputDecoration(
                  hintText: 'Enter corrected translation...',
                  hintStyle: GoogleFonts.poppins(
                    fontSize: 14,
                    color: AppColors.textMuted,
                  ),
                  filled: true,
                  fillColor: isPending ? Colors.white : const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isPending ? AppColors.primary : AppColors.cardBorder,
                      width: 1.5,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isPending ? AppColors.primary.withValues(alpha: 0.5) : AppColors.cardBorder,
                      width: 1.5,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary, width: 2),
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.navy,
                ),
              ),
              if (_submitMessage != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _submitMessage!.startsWith('✅')
                        ? const Color(0xFFF0FDF4)
                        : const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _submitMessage!.startsWith('✅')
                          ? AppColors.primary
                          : AppColors.accentRed,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _submitMessage!.startsWith('✅')
                            ? Icons.check_circle_rounded
                            : Icons.error_outline_rounded,
                        color: _submitMessage!.startsWith('✅')
                            ? AppColors.primary
                            : AppColors.accentRed,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _submitMessage!,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: _submitMessage!.startsWith('✅')
                                ? AppColors.primary
                                : AppColors.accentRed,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  if (isPending) ...[
                    Expanded(
                      child: PrimaryButton(
                        label: _isSubmitting ? 'Sending...' : 'Send Correction',
                        icon: Icons.send_rounded,
                        onPressed: _isSubmitting ? null : _sendCorrection,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SecondaryButton(
                        label: 'Approve as Is',
                        icon: Icons.check_circle_outline_rounded,
                        onPressed: _isSubmitting ? null : _approveAsIs,
                      ),
                    ),
                  ] else ...[
                    Expanded(
                      child: SecondaryButton(
                        label: 'Already ${_currentItem.status.label}',
                        icon: Icons.lock_outline_rounded,
                        onPressed: null,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Translation Memory Preview
          _memory.hasCorrection(_currentItem.phraseId)
              ? _buildSectionCard(
                  title: 'Translation Memory (Stored Correction)',
                  icon: Icons.memory_rounded,
                  iconColor: AppColors.primary,
                  children: _buildMemoryPreview(),
                )
              : const SizedBox.shrink(),
        ],
      ),
    );
  }

  List<Widget> _buildMemoryPreview() {
    final entry = _memory.correctionFor(_currentItem.phraseId)!;
    return [
      _buildTextDisplay(
        'Original: ${entry.originalTranslation}',
        AppColors.textSecondary,
        fontSize: 13,
      ),
      const SizedBox(height: 8),
      _buildTextDisplay(
        'Corrected: ${entry.correctedTranslation}',
        AppColors.primary,
        fontSize: 14,
      ),
      const SizedBox(height: 8),
      Text(
        'Reviewer: ${entry.reviewer} • Status: ${entry.reviewStatus}',
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: AppColors.textMuted,
        ),
      ),
    ];
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1),
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
          Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.navy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextDisplay(String text, Color color, {double fontSize = 15}) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: fontSize,
        fontWeight: FontWeight.w500,
        color: color,
        height: 1.4,
      ),
    );
  }

  Widget _buildContextRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Text(
              '$label:',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.navy,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 18,
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
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _priorityColor(_currentItem.priority).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _priorityColor(_currentItem.priority), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.priority_high_rounded, size: 14),
          const SizedBox(width: 4),
          Text(
            _currentItem.priority.shortLabel,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: _priorityColor(_currentItem.priority),
            ),
          ),
        ],
      ),
    );
  }

  Color _statusBgColor(ReviewItemStatus status) {
    switch (status) {
      case ReviewItemStatus.pending:
        return const Color(0xFFFEF3C7);
      case ReviewItemStatus.corrected:
        return const Color(0xFFDBEAFE);
      case ReviewItemStatus.approved:
        return const Color(0xFFF0FDF4);
      case ReviewItemStatus.resolved:
        return const Color(0xFFF1F5F9);
    }
  }

  Color _statusTextColor(ReviewItemStatus status) {
    switch (status) {
      case ReviewItemStatus.pending:
        return const Color(0xFFB45309);
      case ReviewItemStatus.corrected:
        return AppColors.primary;
      case ReviewItemStatus.approved:
        return AppColors.primary;
      case ReviewItemStatus.resolved:
        return AppColors.textMuted;
    }
  }

  IconData _statusIcon(ReviewItemStatus status) {
    switch (status) {
      case ReviewItemStatus.pending:
        return Icons.pending_actions_rounded;
      case ReviewItemStatus.corrected:
        return Icons.edit_rounded;
      case ReviewItemStatus.approved:
        return Icons.check_circle_rounded;
      case ReviewItemStatus.resolved:
        return Icons.check_circle_outline_rounded;
    }
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

  Future<void> _sendCorrection() async {
    setState(() {
      _isSubmitting = true;
      _submitMessage = null;
    });

    try {
      final correctedText = _correctionController.text.trim();
      if (correctedText.isEmpty) {
        setState(() {
          _submitMessage = '❌ Please enter a corrected translation.';
          _isSubmitting = false;
        });
        return;
      }

      // 1. Apply correction to review queue
      _queue.applyCorrection(
        _currentItem.id,
        correctedText: correctedText,
        reviewer: 'Language Expert',
        status: ReviewItemStatus.corrected,
      );

      // 2. Store in Translation Memory (§12, §14)
      _memory.add(TranslationMemoryEntry(
        phraseId: _currentItem.phraseId,
        direction: _currentItem.direction,
        sourceLanguage: _currentItem.direction == ReviewDirection.santaliToHindi ? 'Santali' : 'Hindi',
        targetLanguage: _currentItem.direction == ReviewDirection.santaliToHindi ? 'Hindi' : 'Santali',
        originalTranslation: _currentItem.translatedText,
        correctedTranslation: correctedText,
        reviewStatus: 'corrected',
        reviewer: 'Language Expert',
        context: _currentItem.context,
        createdAt: DateTime.now(),
      ));

      // 3. Create CorrectionNotice for Teacher Portal (§13)
      _notices.add(CorrectionNotice(
        reviewId: _currentItem.id,
        phraseId: _currentItem.phraseId,
        originalTranslation: _currentItem.translatedText,
        correctedTranslation: correctedText,
        context: _currentItem.context,
        createdAt: DateTime.now(),
      ));

      // Refresh local item
      final updated = _queue.byId(_currentItem.id);
      if (updated != null) {
        setState(() {
          _currentItem = updated;
        });
      }

      setState(() {
        _isSubmitting = false;
        _submitMessage = '✅ Correction sent! Teacher portal notified. Translation Memory updated.';
      });
    } catch (e) {
      setState(() {
        _isSubmitting = false;
        _submitMessage = '❌ Failed: $e';
      });
    }
  }

  Future<void> _approveAsIs() async {
    setState(() {
      _isSubmitting = true;
      _submitMessage = null;
    });

    try {
      _queue.approve(_currentItem.id, reviewer: 'Language Expert');

      // Also store in Translation Memory as approved (no correction needed)
      _memory.add(TranslationMemoryEntry(
        phraseId: _currentItem.phraseId,
        direction: _currentItem.direction,
        sourceLanguage: _currentItem.direction == ReviewDirection.santaliToHindi ? 'Santali' : 'Hindi',
        targetLanguage: _currentItem.direction == ReviewDirection.santaliToHindi ? 'Hindi' : 'Santali',
        originalTranslation: _currentItem.translatedText,
        correctedTranslation: _currentItem.translatedText,
        reviewStatus: 'approved',
        reviewer: 'Language Expert',
        context: _currentItem.context,
        createdAt: DateTime.now(),
      ));

      final updated = _queue.byId(_currentItem.id);
      if (updated != null) {
        setState(() {
          _currentItem = updated;
        });
      }

      setState(() {
        _isSubmitting = false;
        _submitMessage = '✅ Approved! Translation marked as expert-verified.';
      });
    } catch (e) {
      setState(() {
        _isSubmitting = false;
        _submitMessage = '❌ Failed: $e';
      });
    }
  }
}