import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_shadows.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/educational_illustrations.dart';

/// Reference A (Mobile) and responsive Tablet Foundational Literacy Screen.
class FoundationalLiteracyScreen extends StatelessWidget {
  const FoundationalLiteracyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;

    return AppScaffold(
      title: 'Foundational Literacy',
      subtitle: 'Build confident speakers, readers and writers through four learning strands.',
      breadcrumb: 'Teach > Language > Foundational Literacy',
      isScrollable: true,
      onBack: () {
        if (Navigator.of(context).canPop()) {
          context.pop();
        } else {
          context.go(AppRoutes.teach);
        }
      },
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Illustrated Hero Header (Classroom & Nature Motif)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.cardBorder, width: 1),
              boxShadow: AppShadows.card,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClassroomHeroIllustration(height: isTablet ? 160 : 130),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                    child: Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.greenLight,
                            borderRadius: AppRadius.radiusPill,
                            border: Border.all(color: AppColors.greenBorder, width: 1),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.stars_rounded, size: 14, color: AppColors.primary),
                              const SizedBox(width: 4),
                              Text(
                                'NIPUN Lakshya Aligned',
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          'Class 2 · FLN Language',
                          style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Section Title: Four Learning Strands
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text('Four Learning Strands', style: AppTypography.sectionTitle, overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(width: 8),
              Text('4 आयाम', style: AppTypography.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),

          // Responsive Grid: 1 column on Mobile, 2 columns on Tablet
          if (isTablet)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    children: [
                      _buildStrandCard(
                        context,
                        number: '1',
                        titleEn: 'Oral Language Development',
                        titleHi: 'मौखिक भाषा विकास',
                        description: 'Listening, speaking, vocabulary, picture talk, stories, conversation and question prompts.',
                        color: AppColors.primary,
                                                icon: Icons.record_voice_over_rounded,
                        route: AppRoutes.oralLanguage,
                      ),
                      const SizedBox(height: 14),
                      _buildStrandCard(
                        context,
                        number: '3',
                        titleEn: 'Reading & Comprehension',
                        titleHi: 'पढ़ना और समझना',
                        description: 'Bilingual short texts, read-aloud, comprehension questions, picture-supported reading and contextual questions.',
                        color: AppColors.accentOrange,
                                                icon: Icons.auto_stories_rounded,
                        route: AppRoutes.readingComprehension,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    children: [
                      _buildStrandCard(
                        context,
                        number: '2',
                        titleEn: 'Decoding',
                        titleHi: 'डिकोडिंग',
                        description: 'Sound-symbol relationships, phonological awareness, letters, sound practice, blending and word reading.',
                        color: AppColors.accentBlue,
                                                icon: Icons.spellcheck_rounded,
                        route: AppRoutes.decoding,
                      ),
                      const SizedBox(height: 14),
                      _buildStrandCard(
                        context,
                        number: '4',
                        titleEn: 'Writing & Expression',
                        titleHi: 'लिखना और अभिव्यक्ति',
                        description: 'Writing prompts, tracing/copying tasks, picture-to-sentence and expression activities.',
                        color: AppColors.accentLavender,
                                                icon: Icons.edit_note_rounded,
                        route: AppRoutes.writingExpression,
                      ),
                    ],
                  ),
                ),
              ],
            )
          else ...[
            _buildStrandCard(
              context,
              number: '1',
              titleEn: 'Oral Language Development',
              titleHi: 'मौखिक भाषा विकास',
              description: 'Listening, speaking, vocabulary, picture talk, stories, conversation and question prompts.',
              color: AppColors.primary,
                            icon: Icons.record_voice_over_rounded,
              route: AppRoutes.oralLanguage,
            ),
            const SizedBox(height: 12),
            _buildStrandCard(
              context,
              number: '2',
              titleEn: 'Decoding',
              titleHi: 'डिकोडिंग',
              description: 'Sound-symbol relationships, phonological awareness, letters, sound practice, blending and word reading.',
              color: AppColors.accentBlue,
                            icon: Icons.spellcheck_rounded,
              route: AppRoutes.decoding,
            ),
            const SizedBox(height: 12),
            _buildStrandCard(
              context,
              number: '3',
              titleEn: 'Reading & Comprehension',
              titleHi: 'पढ़ना और समझना',
              description: 'Bilingual short texts, read-aloud, comprehension questions, picture-supported reading and contextual questions.',
              color: AppColors.accentOrange,
                            icon: Icons.auto_stories_rounded,
              route: AppRoutes.readingComprehension,
            ),
            const SizedBox(height: 12),
            _buildStrandCard(
              context,
              number: '4',
              titleEn: 'Writing & Expression',
              titleHi: 'लिखना और अभिव्यक्ति',
              description: 'Writing prompts, tracing/copying tasks, picture-to-sentence and expression activities.',
              color: AppColors.accentLavender,
                            icon: Icons.edit_note_rounded,
              route: AppRoutes.writingExpression,
            ),
          ],

          const SizedBox(height: 24),

          // Your Learning Journey Section (Horizontal Progression 1 -> 2 -> 3 -> 4)
          Text('Your Learning Journey', style: AppTypography.sectionTitle),
          const SizedBox(height: 4),
          Text('Step-by-step foundational literacy progression', style: AppTypography.caption),
          const SizedBox(height: 14),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.cardBorder, width: 1),
              boxShadow: AppShadows.card,
            ),
            child: Row(
              children: [
                _buildJourneyStep(
                  step: '1',
                  label: 'Listen & Speak',
                  labelHi: 'सुनना व बोलना',
                  isActive: true,
                  isDone: false,
                ),
                _buildJourneyArrow(),
                _buildJourneyStep(
                  step: '2',
                  label: 'Decode',
                  labelHi: 'डिकोड',
                  isActive: false,
                  isDone: false,
                ),
                _buildJourneyArrow(),
                _buildJourneyStep(
                  step: '3',
                  label: 'Read & Understand',
                  labelHi: 'पढ़ना',
                  isActive: false,
                  isDone: false,
                ),
                _buildJourneyArrow(),
                _buildJourneyStep(
                  step: '4',
                  label: 'Write & Express',
                  labelHi: 'लिखना',
                  isActive: false,
                  isDone: false,
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Motivational / Context Section
          const StrongFoundationsIllustration(),
          const SizedBox(height: 28),
        ],
      ),
    );
  }

  Widget _buildStrandCard(
    BuildContext context, {
    required String number,
    required String titleEn,
    required String titleHi,
    required String description,
    required Color color,
    required IconData icon,
    required String route,
  }) {
    // White card; strand color in number badge, Hindi label, icon wash.
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push(route),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.cardBorder, width: 1),
            boxShadow: AppShadows.card,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row: Strand Number Badge, Title, Icon
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.25),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        number,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          titleEn,
                          style: AppTypography.cardTitle.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          titleHi,
                          style: AppTypography.caption.copyWith(
                            color: color,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                description,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.4,
                  fontSize: 12.5,
                ),
              ),
              const SizedBox(height: 12),
              // Explore Action Pill + Arrow
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: AppRadius.radiusPill,
                      border: Border.all(color: color.withValues(alpha: 0.35), width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Explore',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: color,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.arrow_forward_rounded, size: 14, color: color),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, size: 22, color: color.withValues(alpha: 0.7)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildJourneyStep({
    required String step,
    required String label,
    required String labelHi,
    required bool isActive,
    required bool isDone,
  }) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isActive
                  ? AppColors.primary
                  : (isDone ? AppColors.greenLight : AppColors.surfaceSubtle),
              shape: BoxShape.circle,
              border: Border.all(
                color: isActive ? AppColors.primary : AppColors.cardBorder,
                width: 1.5,
              ),
            ),
            child: Center(
              child: Text(
                step,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isActive ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? AppColors.primary : AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              labelHi,
              style: TextStyle(
                fontSize: 9.5,
                color: isActive ? AppColors.primary : AppColors.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJourneyArrow() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Icon(
        Icons.arrow_forward_rounded,
        size: 14,
        color: AppColors.textMuted.withValues(alpha: 0.6),
      ),
    );
  }
}
