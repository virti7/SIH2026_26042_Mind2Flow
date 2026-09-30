import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_shadows.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/badges.dart';
import '../../../../core/widgets/educational_illustrations.dart';
import '../../../../core/widgets/responsive_container.dart';

/// Reference-style onboarding: warm ivory, navy headings, friendly
/// illustration hero, language chips, Offline Ready badge, dots + Next.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  void _onNext() {
    if (_currentIndex < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      context.go(AppRoutes.teacherSetup);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _currentIndex == 2;

    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Pagination dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  3,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentIndex == index ? 26 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentIndex == index ? AppColors.primary : AppColors.border,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  if (_currentIndex > 0) ...[
                    SecondaryButton(
                      label: 'Back',
                      onPressed: () {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeInOut,
                        );
                      },
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: PrimaryButton(
                      label: isLast ? 'Get Started' : 'Next',
                      trailingIcon: Icons.arrow_forward_rounded,
                      onPressed: _onNext,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: ResponsiveContainer(
          child: Column(
            children: [
              // Top bar: NIPUN + Skip
              Row(
                children: [
                  const Flexible(child: NipunBadge()),
                  const Spacer(),
                  TextButton(
                    onPressed: () => context.go(AppRoutes.teacherSetup),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Skip',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (i) => setState(() => _currentIndex = i),
                  children: [
                    _buildWelcomeSlide(),
                    _buildNipunSlide(),
                    _buildOfflineSlide(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // SCREEN 1 — Welcome to Maatribhasha
  Widget _buildWelcomeSlide() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        children: [
          const SizedBox(height: 8),
          // Illustration hero
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            decoration: BoxDecoration(
              color: AppColors.pastelGreen,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: AppColors.greenBorder, width: 1),
              boxShadow: AppShadows.illustrationGlow,
            ),
            child: Column(
              children: [
                const ClassroomHeroIllustration(height: 150, width: 260),
                const SizedBox(height: 12),
                const Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    LanguageMiniChip(label: 'Ho', background: Colors.white),
                    LanguageMiniChip(label: 'Mundari', background: Colors.white),
                    LanguageMiniChip(label: 'Santali', background: Colors.white),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const OfflineBadge(),
          const SizedBox(height: 14),
          Text(
            'Welcome to Maatribhasha',
            style: AppTypography.pageTitle.copyWith(fontSize: 27),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'Mother-Tongue Teaching Assistant',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.primaryDark,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            'A brighter tomorrow,\nin every child\u2019s language.',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              height: 1.55,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // SCREEN 2 — NIPUN-Aligned Learning
  Widget _buildNipunSlide() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Text(
            'NIPUN-Aligned Learning',
            style: AppTypography.pageTitle.copyWith(fontSize: 26),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Play, practice and progress with structured,\nengaging lessons for Classes 1\u20135.',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              height: 1.55,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),
          _nipunCard(
            icon: Icons.record_voice_over_rounded,
            title: 'Oral Language Development',
            color: AppColors.primary,
            bg: AppColors.pastelGreen,
          ),
          const SizedBox(height: 10),
          _nipunCard(
            icon: Icons.grid_on_rounded,
            title: 'Decoding',
            color: AppColors.accentBlue,
            bg: AppColors.pastelBlue,
          ),
          const SizedBox(height: 10),
          _nipunCard(
            icon: Icons.menu_book_rounded,
            title: 'Reading & Comprehension',
            color: AppColors.accentOrange,
            bg: AppColors.pastelPeach,
          ),
          const SizedBox(height: 10),
          _nipunCard(
            icon: Icons.edit_note_rounded,
            title: 'Writing & Expression',
            color: AppColors.accentLavender,
            bg: AppColors.pastelLavender,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _nipunCard({
    required IconData icon,
    required String title,
    required Color color,
    required Color bg,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: AppTypography.cardTitle.copyWith(fontSize: 15),
            ),
          ),
          const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textMuted),
        ],
      ),
    );
  }

  // SCREEN 3 — Works Offline
  Widget _buildOfflineSlide() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: AppColors.pastelCream,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: AppColors.cardBorder, width: 1),
              boxShadow: AppShadows.illustrationGlow,
            ),
            child: Column(
              children: [
                Container(
                  width: 84,
                  height: 84,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.tablet_mac_rounded,
                    color: AppColors.primary,
                    size: 44,
                  ),
                ),
                const SizedBox(height: 14),
                const Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    LanguageMiniChip(label: 'Teach', background: AppColors.pastelGreen),
                    LanguageMiniChip(label: 'Translate', background: AppColors.pastelBlue),
                    LanguageMiniChip(label: 'Progress', background: AppColors.pastelPeach),
                  ],
                ),
                const SizedBox(height: 12),
                const OfflineBadge(),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Works Offline, Built for\nReal Classrooms',
            style: AppTypography.pageTitle.copyWith(fontSize: 26),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            'Full functionality on low-cost Android tablets.\nTeach, translate and assess without\ndepending on internet during class.',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              height: 1.55,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
