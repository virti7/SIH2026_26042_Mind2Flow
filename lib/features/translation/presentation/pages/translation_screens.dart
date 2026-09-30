import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/models/app_models.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/content/santali_audio_player.dart';
import '../../../../core/content/santali_phrase_bank.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/audio_play_button.dart';
import '../../../../core/widgets/badges.dart';
import '../../../../core/widgets/custom_card.dart';
import '../../../../core/review/review_models.dart';
import '../bloc/translation_bloc.dart';

// SCREEN 41: Translate Home / Live Lesson
class TranslateHomeScreen extends StatefulWidget {
  const TranslateHomeScreen({super.key});

  @override
  State<TranslateHomeScreen> createState() => _TranslateHomeScreenState();
}

class _TranslateHomeScreenState extends State<TranslateHomeScreen> {
  @override
  void initState() {
    super.initState();
    context.read<TranslationBloc>().add(InitTranslationSession());
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width >= 600;

    return BlocBuilder<TranslationBloc, TranslationState>(
      builder: (context, state) {
        if (state is! TranslationSessionActive) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }

        return AppScaffold(
          showHeader: false,
          showBackButton: false,
          isScrollable: true,
          contentPadding: EdgeInsets.symmetric(
            horizontal: isTablet ? 32 : 20,
            vertical: 16,
          ),
          body: SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(context),
                const SizedBox(height: 18),
                // NOTE (prototype): no manual target-language selector.
                // Direction is automatic from the tap flow —
                // single tap = Hindi → Santali, double tap = Santali → Hindi.
                _buildTranslationPanels(context, state),
                _buildUnderstandingCheck(context, state),
                _buildCorrectionNotice(context, state),
                const SizedBox(height: 28),
                _buildMicrophoneSection(context, state),
                const SizedBox(height: 24),
                _buildClassroomActionGrid(context),
                const SizedBox(height: 24),
                _buildRecentUtterancesSection(context, state),
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // HEADER
  // ---------------------------------------------------------------------------
  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CLASS 2 > LIVE TRANSLATION',
          style: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                'Live Classroom Translator',
                style: GoogleFonts.poppins(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: AppColors.navy,
                  letterSpacing: -0.4,
                  height: 1.2,
                ),
              ),
            ),
            const SizedBox(width: 12),
            InkWell(
              onTap: () => context.push(AppRoutes.translateContext),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.cardBorder, width: 1),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x06000000),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.menu_book_rounded,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Class Context',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.navy,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 16,
                      color: AppColors.navy,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Speak naturally in Hindi to broadcast instant tribal translation in classroom.',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // TRANSLATION PANELS
  // ---------------------------------------------------------------------------
  Widget _buildTranslationPanels(
    BuildContext context,
    TranslationSessionActive state,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 600;

        final teacherCard = _buildTeacherCard(context, state);
        final translationCard = _buildTargetTranslationCard(context, state);

        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: teacherCard),
              const SizedBox(width: 16),
              Expanded(child: translationCard),
            ],
          );
        }

        return Column(
          children: [teacherCard, const SizedBox(height: 14), translationCard],
        );
      },
    );
  }

  Widget _buildTeacherCard(
    BuildContext context, TranslationSessionActive state) {
    // No ASR on this path: the input card shows the preselected phrase from
    // the JSON bank (never recognized speech, never a confidence score).
    // Single tap → phrase_002 Hindi (+ Roman); double tap → phrase_001
    // Santali Ol Chiki (+ Roman) with its local input clip.
    final fromStudent = state.translatorFlow == 'sat_to_hi';
    final spoken = state.currentInputHindi;
    final spokenRoman = state.currentInputSecondary;
    
    // Determine if we should show the input phrase text:
    // - Not recording (not in LISTENING state)
    // - Not processing (not in PREPARING state)
    // - Has content (result is ready)
    final bool showInputPhrase =
        !state.isRecording &&
        !state.isProcessing &&
        spoken.isNotEmpty;

    return Container(
      constraints: const BoxConstraints(minHeight: 200),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.record_voice_over_rounded,
                        size: 18,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        fromStudent ? 'Student (Santali)' : 'Teacher (Hindi)',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.navy,
                        ),
                      ),
                    ],
                  ),
                  Semantics(
                    button: true,
                    label: 'Play input audio',
                    child: AudioPlayButton(
                      compact: true,
                      onPlay: (state.inputAudioAsset != null &&
                              state.inputAudioAsset!.isNotEmpty &&
                              !state.isRecording &&
                              !state.isProcessing)
                          ? () => context.read<TranslationBloc>().add(
                                ReplayTranslatorInputAudio(),
                              )
                          : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Input phrase visibility: hidden during IDLE, LISTENING,
              // and PREPARING. Shown only after the translation result is
              // ready (for both single-tap and double-tap flows).
              //
              // IDLE/LISTENING/PREPARING: show waiting or listening text.
              // RESULT: show the preselected JSON input phrase.
              Text(
                state.isRecording
                    ? 'Listening...'
                    : (state.isProcessing
                        ? 'Ready...'
                        : (spoken.isEmpty
                            ? 'Ready — tap Translate\nto begin.'
                            : spoken)),
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: (state.isRecording ||
                          state.isProcessing ||
                          spoken.isEmpty)
                      ? FontWeight.w400
                      : FontWeight.w500,
                  color: (state.isRecording ||
                          state.isProcessing ||
                          spoken.isEmpty)
                      ? AppColors.textSecondary
                      : AppColors.navy,
                  height: 1.45,
                ),
              ),
              // Input Roman line (Hindi Roman / Santali Roman from the JSON
              // bank). Visible only when the result is ready — never during
              // IDLE, LISTENING, or PREPARING.
              if (showInputPhrase &&
                  spokenRoman.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  spokenRoman,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 24),
          Center(
            child: _AudioWaveformVisualizer(isRecording: state.isRecording),
          ),
        ],
      ),
    );
  }

  Widget _buildTargetTranslationCard(
    BuildContext context,
    TranslationSessionActive state,
  ) {
    return Container(
      constraints: const BoxConstraints(minHeight: 200),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.greenBorder, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.translate_rounded,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    state.translatorFlow == 'sat_to_hi'
                        ? 'Hindi Translation'
                        : 'Santali Translation',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ],
              ),
              Semantics(
                button: true,
                label: 'Play translation audio',
                child: AudioPlayButton(
                  compact: true,
                  onPlay:
                      (state.isLocalPrototype &&
                          state.localAudioAsset != null &&
                          !state.isRecording &&
                          !state.isProcessing)
                      ? () => context.read<TranslationBloc>().add(
                          ReplayLocalSantaliAudio(),
                        )
                      : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (state.translationError != null)
            Text(
              state.translationError!,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.accentRed,
                height: 1.4,
              ),
            )
          else if (state.isRecording)
            // Listening: output stays hidden — same waiting text as Idle.
            Text(
              state.translatorFlow == 'sat_to_hi'
                  ? 'Waiting for Santali input...'
                  : 'Waiting for translation...',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            )
          else if (state.isProcessing)
            Text(
              'Preparing translation...',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            )
          else if (state.currentTranslationResult.isEmpty)
            Text(
              state.translatorFlow == 'sat_to_hi'
                  ? 'Waiting for Santali input...'
                  : 'Waiting for translation...',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            )
else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      state.currentTranslationResult,
                      style: AppTypography.tribalVernacular.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: AppColors.navy,
                        height: 1.45,
                      ),
                    ),
                    // Second line: Santali Roman (single tap) or Hindi Roman
                    // (double tap). Shown only after the delay.
                    if (state.currentTranslationSecondary.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        state.currentTranslationSecondary,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ],
                    // Confidence score display (§3, §22)
                    if (state.hasConfidence && state.currentConfidenceScore > 0) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFCD34D), width: 1),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.analytics_outlined,
                                  size: 16,
                                  color: Color(0xFFB45309),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Translation Confidence',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFFB45309),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: const Color(0xFFFCD34D), width: 1),
                                  ),
                                  child: Text(
                                    '${state.currentConfidenceScore} / 100',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFFB45309),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            // Confidence progress bar
                            LinearProgressIndicator(
                              value: state.currentConfidenceScore / 100,
                              backgroundColor: const Color(0xFFFDE68A),
                              valueColor: const AlwaysStoppedAnimation(Color(0xFFB45309)),
                              minHeight: 6,
                              borderRadius: BorderRadius.circular(3),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Priority: ${calculatePriority(state.currentConfidenceScore).label}',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: calculatePriority(state.currentConfidenceScore) == ReviewPriority.high
                                    ? AppColors.accentRed
                                    : (calculatePriority(state.currentConfidenceScore) == ReviewPriority.medium
                                        ? const Color(0xFFB45309)
                                        : AppColors.primary),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // MAIN MICROPHONE AREA & STATUS
  // ---------------------------------------------------------------------------
  Widget _buildMicrophoneSection(
    BuildContext context,
    TranslationSessionActive state,
  ) {
    // ONE Translator action button (no mode selector). Start/stop
    // recording interaction: first tap starts Listening, next tap stops
    // and translates Hindi → Santali; a quick double tap from Idle runs
    // Santali → Hindi instead. The bloc holds the first tap briefly so a
    // double tap never flashes Listening or fires the Hindi flow.
    final isListening = state.isRecording;
    final isBusy = state.isProcessing || isListening;
    final label = state.isProcessing
        ? 'Preparing translation…'
        : (isListening ? 'Listening… tap to stop' : 'Tap to Translate');
    // Latency pill is shown ONLY after a translation result exists, with
    // EXACTLY the generated delay: the same stored value that was awaited
    // — never a separately generated number, never a visible range.
    final showLatency = !state.isProcessing &&
        !isListening &&
        state.currentTranslationResult.isNotEmpty &&
        state.generatedLatencyMs > 0;
    final latencyLabel =
        '${(state.generatedLatencyMs / 1000).toStringAsFixed(2)}s Latency';

    return Column(
      children: [
        Semantics(
          button: true,
          label: label,
          child: GestureDetector(
            onTap: () {
              // Every tap goes to the bloc: it cancels any pending
              // translation and decides single vs double tap. Never ignored.
              context.read<TranslationBloc>().add(TranslatorButtonTapped());
            },
            child: Container(
              width: 112,
              height: 112,
              decoration: BoxDecoration(
                color: isBusy
                    ? AppColors.statusNeedsSupport.withValues(alpha: 0.12)
                    : const Color(0xFFEDFAF2),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    color: isBusy
                        ? AppColors.statusNeedsSupport
                        : AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3.5),
                    boxShadow: [
                      BoxShadow(
                        color:
                            (isBusy
                                    ? AppColors.statusNeedsSupport
                                    : AppColors.primary)
                                .withValues(alpha: 0.35),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Icon(
                    state.isProcessing
                        ? Icons.hourglass_top_rounded
                        : (isListening
                            ? Icons.mic_rounded
                            : Icons.translate_rounded),
                    size: 38,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: isBusy
                ? AppColors.statusNeedsSupport
                : AppColors.primary,
          ),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Latency badge: visible ONLY after a translation result is
            // ready. Never a range, never before the result.
            if (showLatency) ...[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: AppColors.cardBorder, width: 1),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x05000000),
                      blurRadius: 4,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.bolt_rounded,
                      size: 14,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      latencyLabel,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.navy,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
            ],
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
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
                  Text(
                    'Offline Ready',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // CLASSROOM ACTION GRID
  // ---------------------------------------------------------------------------
  Widget _buildClassroomActionGrid(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 540;

        final item1 = _buildActionItem(
          icon: Icons.format_list_bulleted_rounded,
          label: 'Phrase Bank',
          onTap: () => context.push(AppRoutes.quickPhrases),
        );
        final item2 = _buildActionItem(
          icon: Icons.sentiment_satisfied_alt_rounded,
          label: 'Student Reply',
          onTap: () => context.push(AppRoutes.studentResponse),
        );
        final item3 = _buildActionItem(
          icon: Icons.chat_bubble_outline_rounded,
          label: 'Dialogue',
          onTap: () => context.push(AppRoutes.twoWayConversation),
        );
        final item4 = _buildActionItem(
          icon: Icons.auto_awesome_rounded,
          label: 'New Sentence',
          onTap: () => context.push(AppRoutes.newSentence),
        );
        final item5 = _buildActionItem(
          icon: Icons.alt_route_rounded,
          label: '3-Language\nRouter',
          onTap: () => context.push(AppRoutes.languageRouter),
        );
        final item6 = _buildActionItem(
          icon: Icons.assignment_turned_in_rounded,
          label: 'Review',
          onTap: () => context.push(AppRoutes.teacherReview),
        );

        if (isWide) {
          return Row(
            children: [
              Expanded(child: item1),
              const SizedBox(width: 8),
              Expanded(child: item2),
              const SizedBox(width: 8),
              Expanded(child: item3),
              const SizedBox(width: 12),
              Container(width: 1, height: 36, color: AppColors.cardBorder),
              const SizedBox(width: 12),
              Expanded(child: item4),
              const SizedBox(width: 8),
              Expanded(child: item5),
              const SizedBox(width: 8),
              Expanded(child: item6),
            ],
          );
        }

        return Column(
          children: [
            Row(
              children: [
                Expanded(child: item1),
                const SizedBox(width: 8),
                Expanded(child: item2),
                const SizedBox(width: 8),
                Expanded(child: item3),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: item4),
                const SizedBox(width: 8),
                Expanded(child: item5),
                const SizedBox(width: 8),
                Expanded(child: item6),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildActionItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 76,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder, width: 1),
          boxShadow: const [
            BoxShadow(
              color: Color(0x04000000),
              blurRadius: 4,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: AppColors.primary),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.navy,
                  height: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // RECENT CLASSROOM UTTERANCES
  // ---------------------------------------------------------------------------
  Widget _buildRecentUtterancesSection(
    BuildContext context,
    TranslationSessionActive state,
  ) {
    final history = state.conversationHistory.reversed.take(4).toList();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text.rich(
                  TextSpan(
                    text: 'Recent Classroom Utterances ',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.navy,
                    ),
                    children: [
                      TextSpan(
                        text: '(कक्षा वार्तालाप)',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              InkWell(
                onTap: () => context.push(AppRoutes.translationFeedback),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'View All',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(
                        Icons.chevron_right_rounded,
                        size: 16,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...history.map((msg) => _buildUtteranceCard(msg)),
        ],
      ),
    );
  }

  Widget _buildUtteranceCard(TranslationMessage msg) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: msg.isTeacher
                  ? AppColors.greenLight
                  : AppColors.pastelBlue,
              shape: BoxShape.circle,
            ),
            child: Icon(
              msg.isTeacher
                  ? Icons.school_rounded
                  : Icons.sentiment_satisfied_alt_rounded,
              color: msg.isTeacher ? AppColors.primary : AppColors.accentBlue,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  msg.speakerName,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  msg.originalText,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.navy,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  msg.translatedText,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const AudioPlayButton(compact: true),
              const SizedBox(height: 6),
              Text(
                _formatRelativeTime(msg.timestamp),
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatRelativeTime(DateTime timestamp) {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes} min ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${diff.inDays}d ago';
    }
  }

  // ---------------------------------------------------------------------------
  // UNDERSTANDING CHECK (§5, §21)
  // ---------------------------------------------------------------------------
  Widget _buildUnderstandingCheck(
      BuildContext context, TranslationSessionActive state) {
    // Show understanding check only after translation result is visible,
    // confidence is shown, and not already answered.
    final showCheck = state.showUnderstandingCheck &&
        state.currentTranslationResult.isNotEmpty &&
        state.understandingResponse == null;

    if (!showCheck) return const SizedBox.shrink();

    final isSantaliToHindi = state.translatorFlow == 'sat_to_hi';
    final question = isSantaliToHindi
        ? 'Did you understand the translation?'
        : 'Did you understand?';
    final questionHindi = 'क्या आपको समझ आया?';

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.help_outline_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Understanding Check',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.navy,
                      ),
                    ),
                    Text(
                      isSantaliToHindi
                          ? 'Teacher: check if you understood the Hindi translation'
                          : 'Student: check if you understood the Santali translation',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            question,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.navy,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            questionHindi,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: PrimaryButton(
                  label: 'YES',
                  icon: Icons.check_circle_rounded,
                  onPressed: () {
                    context.read<TranslationBloc>().add(
                          UnderstandingCheckAnswered(true),
                        );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SecondaryButton(
                  label: 'NO',
                  icon: Icons.cancel_outlined,
                  onPressed: () {
                    context.read<TranslationBloc>().add(
                          UnderstandingCheckAnswered(false),
                        );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // CORRECTION NOTICE (§13, §19)
  // ---------------------------------------------------------------------------
  /// Displays the "Translation corrected by language expert" notification
  /// when a reviewer has sent a correction back to the teacher portal.
  Widget _buildCorrectionNotice(
      BuildContext context, TranslationSessionActive state) {
    final notice = state.correctionNotice;
    if (notice == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary, width: 2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.verified_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Translation Corrected by Language Expert',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    Text(
                      'Expert Verified • ${notice.context.summary}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  context.read<TranslationBloc>().add(DismissCorrectionNotice());
                },
                icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                tooltip: 'Dismiss',
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Original Translation',
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            notice.originalTranslation,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary,
              height: 1.3,
              decoration: TextDecoration.lineThrough,
              decorationColor: AppColors.accentRed,
              decorationThickness: 2,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Corrected Translation (Expert Verified)',
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            notice.correctedTranslation,
            style: AppTypography.tribalVernacular.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.navy,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          PrimaryButton(
            label: 'Use Corrected Translation',
            icon: Icons.check_circle_rounded,
            onPressed: () {
              context.read<TranslationBloc>().add(
                    ApplyCorrectionNotice(notice.reviewId),
                  );
            },
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// AUDIO WAVEFORM VISUALIZER
// ---------------------------------------------------------------------------
class _AudioWaveformVisualizer extends StatelessWidget {
  final bool isRecording;

  const _AudioWaveformVisualizer({required this.isRecording});

  static const List<double> _barHeights = [
    6,
    10,
    14,
    8,
    18,
    12,
    22,
    16,
    28,
    20,
    32,
    24,
    18,
    26,
    14,
    20,
    10,
    16,
    8,
    12,
    6,
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(_barHeights.length, (i) {
          final h = _barHeights[i];
          return Container(
            width: 2.5,
            height: h,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: isRecording ? AppColors.primary : const Color(0xFFD6DFE8),
              borderRadius: BorderRadius.circular(2),
            ),
          );
        }),
      ),
    );
  }
}

// SCREEN 42: Context-Aware Translation
class ContextAwareTranslationScreen extends StatelessWidget {
  const ContextAwareTranslationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Context Engine Inspector',
      subtitle: 'The contextual signals powering accurate pedagogical translation rather than literal word substitution.',
      breadcrumb: 'Translate > Context Engine',
      isScrollable: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accentPurpleLight,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'ACTIVE CLASSROOM CONTEXT SIGNALS',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.accentPurple,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _buildSignalRow(
                  Icons.school_outlined,
                  'Active Grade & Section',
                  'Class 2, Section A',
                ),
                _buildSignalRow(
                  Icons.flag_outlined,
                  'NIPUN Learning Target',
                  'M2.1.4: Numbers up to 100',
                ),
                _buildSignalRow(
                  Icons.menu_book_outlined,
                  'Current Lesson Stage',
                  'Step 4: Activity (Mahua Seeds Grouping)',
                ),
                _buildSignalRow(
                  Icons.forum_outlined,
                  'Recent 3 Dialogue Turns',
                  'Teacher asked for 3 bundles of ten',
                ),
                _buildSignalRow(
                  Icons.translate_outlined,
                  'Active Domain Vocabulary',
                  'Gela (दहाई), Jaang (बीज), Haat (बाजार)',
                ),
                _buildSignalRow(
                  Icons.image_outlined,
                  'Active Visual Context',
                  '10-seeds per leaf plate representation',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Contextual vs. Literal Translation Example:',
            style: AppTypography.sectionTitle,
          ),
          const SizedBox(height: 10),
          CustomCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Teacher says: "दस की ढेरी बनाओ"',
                  style: AppTypography.cardTitle.copyWith(fontSize: 14),
                ),
                const SizedBox(height: 8),
                const Text(
                  '❌ Literal Translation:\n"10 reya kachra baipe" (Unnatural / Incorrect)',
                ),
                const SizedBox(height: 6),
                Text(
                  '✅ Context-Aware Translation:\n"गेल-गेल जांग पुतली बाईकेते दोहपे" (Culturally precise)',
                  style: AppTypography.tribalVernacular,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignalRow(IconData icon, String label, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Flexible(
            child: Text.rich(
              TextSpan(
                text: '$label: ',
                style: AppTypography.caption.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                children: [
                  TextSpan(
                    text: val,
                    style: AppTypography.caption.copyWith(
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// SCREEN 43: Classroom Language Router
class ClassroomLanguageRouterScreen extends StatelessWidget {
  const ClassroomLanguageRouterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Classroom Language Router',
      subtitle: 'Dynamically routes translations across Ho, Mundari, and Santali speakers.',
      breadcrumb: 'Translate > Router',
      isScrollable: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'One Tablet, Multiple Mother Tongues',
                  style: AppTypography.cardTitle,
                ),
                const SizedBox(height: 6),
                Text(
                  'The single teacher tablet allows instant switching between learners speaking different languages without needing individual student devices.',
                  style: AppTypography.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// SCREEN 44: Student Response Input
class StudentResponseScreen extends StatelessWidget {
  const StudentResponseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Student Response Input',
      subtitle: 'Turn the tablet toward the learner. Student speaks their mother tongue into the microphone.',
      breadcrumb: 'Translate > Student Response',
      isScrollable: true,
      bottomActionBar: PrimaryButton(
        label: 'Simulate Student Speaking in Santali',
        icon: Icons.mic_rounded,
        onPressed: () {
          context.read<TranslationBloc>().add(
            TriggerStudentResponseSimulation(),
          );
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Student response captured and translated for teacher!',
              ),
            ),
          );
        },
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: AppColors.accentBlueLight,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.face_rounded,
                        color: AppColors.accentBlue,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Student Facing Mode',
                        style: AppTypography.cardTitle.copyWith(
                          color: AppColors.accentBlue,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Detected Language: Santali (संताली पारसी)',
                  style: AppTypography.caption.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Child Speech: "इञ नेया सवाल बांञ बुझाव दाड़ेयाक् काना।"',
                  style: AppTypography.tribalVernacular.copyWith(fontSize: 16),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          CustomCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.school_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Translated Meaning for Teacher (Hindi):',
                        style: AppTypography.cardTitle.copyWith(fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '"गुरुजी, मुझे यह सवाल समझ नहीं आ रहा है। कृपया दोबारा बताएं।"',
                  style: AppTypography.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// SCREEN 45: Two-Way Conversation Session
class TwoWayConversationScreen extends StatelessWidget {
  const TwoWayConversationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TranslationBloc, TranslationState>(
      builder: (context, state) {
        if (state is! TranslationSessionActive) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return AppScaffold(
          title: 'Two-Way Classroom Dialogue',
          subtitle: 'Continuous back-and-forth communication between Hindi teacher and tribal student.',
          breadcrumb: 'Translate > Dialogue',
          isScrollable: true,
          bottomActionBar: Row(
            children: [
              Expanded(
                child: SecondaryButton(
                  label: 'Student Speaks',
                  icon: Icons.face_rounded,
                  onPressed: () {
                    context.read<TranslationBloc>().add(
                      TriggerStudentResponseSimulation(),
                    );
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: PrimaryButton(
                  label: 'Teacher Responds',
                  icon: Icons.mic_rounded,
                  onPressed: () {
                    context.read<TranslationBloc>().add(
                      const SendTeacherCustomUtterance(
                        'कोई बात नहीं, मैं तुम्हें दोबारा समझाती हूँ।',
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          body: Column(
            children: state.conversationHistory.map((m) {
              return Align(
                alignment: m.isTeacher
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  constraints: const BoxConstraints(maxWidth: 320),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: m.isTeacher ? AppColors.greenSurface : Colors.white,
                    borderRadius: AppRadius.radiusLg,
                    border: Border.all(
                      color: m.isTeacher
                          ? AppColors.greenBorder
                          : AppColors.cardBorder,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            m.speakerName,
                            style: AppTypography.caption.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const AudioPlayButton(compact: true),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(m.originalText, style: AppTypography.bodySmall),
                      const SizedBox(height: 4),
                      Text(
                        m.translatedText,
                        style: AppTypography.tribalVernacular.copyWith(
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

// SCREEN 46: Quick Phrase Bank — MASTER OFFLINE SANTALI PHRASE BANK.
//
// Data-driven: MASTER JSON + local audio/santali/ folder
//   -> SantaliPhraseBankRepository -> this UI
//   -> Speaker / Repeat / Use in Live Lesson.
// No hardcoded phrase lists here. No network, no Sarvam, no FastAPI.
class QuickPhraseBankScreen extends StatefulWidget {
  const QuickPhraseBankScreen({super.key});

  @override
  State<QuickPhraseBankScreen> createState() => _QuickPhraseBankScreenState();
}

class _QuickPhraseBankScreenState extends State<QuickPhraseBankScreen> {
  SantaliPhraseBankRepository? _bank;
  List<SantaliPhrase> _all = [];
  List<String> _categories = const ['All'];
  bool _loading = true;
  String? _loadError;

  String _category = 'All';
  String _query = '';
  // Session-only favourites (never persisted, so one teacher's favourites
  // can never appear for another account).
  final Set<String> _favs = {};
  final TextEditingController _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    final bloc = context.read<TranslationBloc>();
    if (bloc.state is! TranslationSessionActive) {
      bloc.add(InitTranslationSession());
    }
    _loadBank();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  /// Loads the master JSON once (repository caches it in memory).
  Future<void> _loadBank() async {
    try {
      late final SantaliPhraseBankRepository bank;
      try {
        bank = getIt<SantaliPhraseBankRepository>();
      } catch (_) {
        bank = SantaliPhraseBankRepository();
      }
      final phrases = await bank.load();
      final cats = await bank.categories();
      if (!mounted) return;
      setState(() {
        _bank = bank;
        _all = phrases;
        _categories = ['All', ...cats];
        _loading = false;
      });
    } catch (e) {
      debugPrint('[SantaliPhraseBank] bankUiLoadFailed error=$e');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = 'Phrase Bank unavailable. Please rebuild the app.';
      });
    }
  }

  SantaliAudioPlayer? _audioPlayer() {
    try {
      return getIt<SantaliAudioPlayer>();
    } catch (_) {
      return null;
    }
  }

  /// Speaker / Repeat: plays THIS phrase's own local audio asset.
  /// Never another phrase's clip; a missing asset shows an honest message
  /// and never crashes.
  Future<void> _playPhrase(SantaliPhrase phrase) async {
    try {
      final exists = await _bank?.audioExists(phrase);
      if (exists == false) {
        _audioUnavailable(phrase);
        return;
      }
    } catch (_) {}
    final player = _audioPlayer();
    if (player == null) {
      _audioUnavailable(phrase);
      return;
    }
    try {
      await player.playAsset(phrase.audio);
    } catch (e) {
      debugPrint(
        '[SantaliPhraseBank] playbackFailed '
        'phraseId=${phrase.id} asset=${phrase.audio} error=$e',
      );
      _audioUnavailable(phrase);
    }
  }

  void _audioUnavailable(SantaliPhrase phrase) {
    debugPrint(
      '[SantaliPhraseBank] missingAsset=${phrase.audio} '
      'phraseId=${phrase.id}',
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Audio unavailable for this phrase.')),
    );
  }

  /// Passes the phrase's own pre-verified data to the Live Translator.
  /// The Live Translator displays it directly — no translation is generated.
  void _useInLiveLesson(SantaliPhrase phrase) {
    context.read<TranslationBloc>().add(
      UsePhraseBankPhraseInLiveLesson(
        phraseId: phrase.id,
        hindi: phrase.hindi,
        santaliOlChiki: phrase.santaliOlChiki,
        santaliRoman: phrase.santaliRoman,
        audioAsset: phrase.audio,
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Phrase sent to Live Lesson.')),
    );
    context.go(AppRoutes.translate);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TranslationBloc, TranslationState>(
      builder: (context, state) {
        if (state is! TranslationSessionActive || _loading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (_loadError != null) {
          return AppScaffold(
            title: 'Quick Phrase Bank',
            subtitle: 'Pre-verified phrases with instant native audio (<50ms) — works fully offline.',
            breadcrumb: 'Translate > Phrase Bank',
            body: CustomCard(child: Text(_loadError!)),
          );
        }

        final visible = _all.where((p) {
          if (_category != 'All' && p.category != _category) {
            return false;
          }
          return p.matchesQuery(_query);
        }).toList();

        return AppScaffold(
          title: 'Quick Phrase Bank',
          subtitle: 'Pre-verified phrases with instant native audio (<50ms) — works fully offline.',
          breadcrumb: 'Translate > Phrase Bank',
          isScrollable: true,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _search,
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: 'Search fast — “book”, “गिनो”, “try”…',
                  prefixIcon: const Icon(Icons.search_rounded),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: AppRadius.radiusMd,
                    borderSide: const BorderSide(color: AppColors.cardBorder),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _categories.map((cat) {
                    final isSel = _category == cat;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(cat, style: const TextStyle(fontSize: 12)),
                        selected: isSel,
                        selectedColor: AppColors.primary,
                        backgroundColor: Colors.white,
                        labelStyle: TextStyle(
                          color: isSel ? Colors.white : AppColors.textPrimary,
                        ),
                        onSelected: (val) {
                          if (val) setState(() => _category = cat);
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    '${visible.length} phrases',
                    style: AppTypography.caption.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const OfflineBadge(),
                ],
              ),
              const SizedBox(height: 12),
              if (visible.isEmpty)
                const CustomCard(
                  child: Text(
                    'No phrase matches. Try another word or category.',
                  ),
                ),
              ...visible.map((phrase) {
                final fav = _favs.contains(phrase.id);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: CustomCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.greenLight,
                                borderRadius: AppRadius.radiusPill,
                              ),
                              child: Text(
                                phrase.category,
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                AudioPlayButton(
                                  compact: true,
                                  onPlay: () => _playPhrase(phrase),
                                ),
                                IconButton(
                                  icon: Icon(
                                    fav
                                        ? Icons.favorite_rounded
                                        : Icons.favorite_border_rounded,
                                    color: fav
                                        ? Colors.red
                                        : AppColors.textMuted,
                                    size: 20,
                                  ),
                                  tooltip: 'Favourite',
                                  onPressed: () => setState(() {
                                    if (fav) {
                                      _favs.remove(phrase.id);
                                    } else {
                                      _favs.add(phrase.id);
                                    }
                                  }),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Hindi',
                          style: AppTypography.caption.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          phrase.hindi,
                          style: AppTypography.cardTitle.copyWith(fontSize: 15),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Santali (Ol Chiki)',
                          style: AppTypography.caption.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          phrase.hasOlChiki
                              ? phrase.santaliOlChiki
                              : 'Not provided',
                          style: AppTypography.tribalVernacular.copyWith(
                            color: AppColors.accentBlue,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Santali (Roman)',
                          style: AppTypography.caption.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          phrase.hasRoman
                              ? phrase.santaliRoman
                              : 'Not provided',
                          style: AppTypography.tribalVernacular.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: SecondaryButton(
                                label: 'Repeat',
                                icon: Icons.replay_rounded,
                                onPressed: () {
                                  _playPhrase(phrase);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Replaying: “${phrase.hindi}”',
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: PrimaryButton(
                                label: 'Use in Live Lesson',
                                icon: Icons.present_to_all_rounded,
                                onPressed: () => _useInLiveLesson(phrase),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
}

// SCREEN 48: Translation Feedback
class TranslationFeedbackScreen extends StatefulWidget {
  const TranslationFeedbackScreen({super.key});

  @override
  State<TranslationFeedbackScreen> createState() =>
      _TranslationFeedbackScreenState();
}

class _TranslationFeedbackScreenState extends State<TranslationFeedbackScreen> {
  String _issueType = 'Wrong meaning';
  final TextEditingController _correctionController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();

  static const _issues = [
    'Wrong meaning',
    'Unnatural wording',
    'Wrong language',
    'Pronunciation issue',
    'Other',
  ];

  @override
  void dispose() {
    _correctionController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Translation Feedback',
      subtitle: 'Report an issue without leaving your flow. Saved on-device, synced later.',
      breadcrumb: 'Translate > Feedback',
      isScrollable: true,
      bottomActionBar: PrimaryButton(
        label: 'Save Feedback',
        onPressed: () {
          context.read<TranslationBloc>().add(
            SubmitTranslationFeedbackEvent(
              original: 'अपनी पुस्तक पृष्ठ 5 पर खोलें',
              translated: 'सबिन होनको आपन पुथी उगुइपे',
              issueType: _issueType,
              comment:
                  'Correction: ${_correctionController.text}\nNotes: ${_commentController.text}',
            ),
          );
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Feedback saved locally! Will sync when device is online.',
              ),
            ),
          );
          context.pop();
        },
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'What you flagged',
                  style: AppTypography.caption.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Original (Hindi): “अपनी पुस्तक पृष्ठ 5 पर खोलें”',
                  style: AppTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Translation shown: “सबिन होनको आपन पुथी उगुइपे”',
                  style: AppTypography.tribalVernacular.copyWith(fontSize: 13),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accentBlueLight,
                        borderRadius: AppRadius.radiusPill,
                      ),
                      child: Text(
                        'Mundari',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.accentBlue,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.greenSurface,
                        borderRadius: AppRadius.radiusPill,
                        border: Border.all(color: AppColors.greenBorder),
                      ),
                      child: Text(
                        'Context: Class 2 • Numbers • Live Lesson',
                        style: AppTypography.caption,
                      ),
                    ),
                    const OfflineBadge(),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          CustomCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Issue type',
                  style: AppTypography.cardTitle.copyWith(fontSize: 14),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _issues.map((issue) {
                    final isSel = _issueType == issue;
                    return ChoiceChip(
                      label: Text(issue, style: const TextStyle(fontSize: 12)),
                      selected: isSel,
                      selectedColor: AppColors.primary,
                      backgroundColor: Colors.white,
                      labelStyle: TextStyle(
                        color: isSel ? Colors.white : AppColors.textPrimary,
                      ),
                      onSelected: (val) {
                        if (val) setState(() => _issueType = issue);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                Text(
                  'Your correction (in Ho / Mundari / Santali)',
                  style: AppTypography.caption.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _correctionController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    hintText: 'Type the correct mother-tongue sentence…',
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Extra notes for the language team (optional)',
                  style: AppTypography.caption,
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _commentController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'E.g. villagers in my block say it differently…',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
