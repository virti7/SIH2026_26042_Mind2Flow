import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/utils/time_greeting_helper.dart';
import '../../../../core/widgets/badges.dart';
import '../../../../core/widgets/custom_card.dart';
import '../../../../core/widgets/home_hero_illustration.dart';
import '../../../../core/widgets/responsive_container.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../features/profile/presentation/bloc/teacher_profile_bloc.dart';
import '../bloc/home_bloc.dart';

/// Calm home dashboard per master spec: greeting + offline, three primary
/// actions (Teach / Translate / Progress), quick teaching resources,
/// language availability. No timetable, no dense stats.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeBloc, HomeState>(
      builder: (context, state) {
        if (state is HomeLoading) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }

        if (state is HomeLoaded) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: SafeArea(
              bottom: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: ResponsiveContainer(
                  padding: EdgeInsets.zero,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Greeting row
                      Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.greenBorder, width: 2),
                            ),
                            child: const Icon(Icons.person_rounded, color: Colors.white, size: 30),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            // Reactive central profile state when loaded;
                            // otherwise the Home dashboard profile (same
                            // local-Drift source). Long names truncate.
                            child: BlocBuilder<TeacherProfileBloc,
                                TeacherProfileState>(
                              builder: (context, profileState) {
                                final live = profileState
                                        is TeacherProfileLoaded
                                    ? profileState.profile
                                    : state.profile;
                                final displayName = live.name.trim();
                                final displaySchool = live.school.trim();
                                final displayDistrict = live.district.trim();
                                return Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    // Time-based English greeting from the
                                    // offline profile name + device local
                                    // time (no network call). Long names
                                    // truncate.
                                    Text(
                                      TimeGreetingHelper.greetingNow(
                                          displayName),
                                      style: AppTypography.cardTitle
                                          .copyWith(fontSize: 18),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      displaySchool.isEmpty &&
                                              displayDistrict.isEmpty
                                          ? 'Complete your teacher profile to get started'
                                          : '$displaySchool • $displayDistrict',
                                      style: AppTypography.bodySmall,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          OfflineBadge(),
                          NipunBadge(),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // Hero — white card, text left, illustration right.
                      // Flexible constraints keep whitespace comfortable and
                      // prevent RenderFlex overflow on small phones/tablets.
                      CustomCard(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'A brighter tomorrow, in every child\u2019s language.',
                                    style: AppTypography.sectionTitle.copyWith(fontSize: 17, height: 1.35),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Teach, translate and track — all offline.',
                                    style: AppTypography.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Align(
                              alignment: Alignment.centerRight,
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  final screenW = MediaQuery.of(context).size.width;
                                  final isWide = screenW >= 700;
                                  final double width = isWide ? 220.0 : 130.0;
                                  return HomeTeacherHeroIllustration(
                                    width: width,
                                    height: width * 0.66,
                                    alignment: Alignment.centerRight,
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Three primary actions — white cards, colored icon wash
                      _primaryAction(
                        context,
                        title: 'Teach',
                        subtitle: 'Lessons, worksheets & activities',
                        icon: Icons.menu_book_rounded,
                        bg: AppColors.pastelGreen,
                        iconColor: AppColors.primary,
                        onTap: () => context.go(AppRoutes.teach),
                      ),
                      const SizedBox(height: 12),
                      _primaryAction(
                        context,
                        title: 'Translate',
                        subtitle: 'Hindi ↔ Ho, Mundari, Santali voice help',
                        icon: Icons.translate_rounded,
                        bg: AppColors.pastelBlue,
                        iconColor: AppColors.accentBlue,
                        onTap: () => context.go(AppRoutes.translate),
                      ),
                      const SizedBox(height: 12),
                      _primaryAction(
                        context,
                        title: 'Progress',
                        subtitle: 'Your lessons, assessments & resources',
                        icon: Icons.bar_chart_rounded,
                        bg: AppColors.pastelPeach,
                        iconColor: AppColors.accentOrange,
                        onTap: () => context.go(AppRoutes.progress),
                      ),
                      const SizedBox(height: 24),

                      const SectionHeader(title: 'Quick teaching resources'),
                      const SizedBox(height: 4),
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1.55,
                        children: [
                          _resourceTile(context, 'Worksheets', 'Bilingual printouts', Icons.assignment_outlined, AppColors.accentAmber, AppColors.pastelYellow, () => context.push(AppRoutes.worksheetGenerator)),
                          _resourceTile(context, 'Flashcards', 'Picture + audio cards', Icons.style_outlined, AppColors.accentBlue, AppColors.pastelBlue, () => context.push(AppRoutes.flashcardGenerator)),
                          _resourceTile(context, 'Assessments', 'Quick oral checks', Icons.fact_check_outlined, AppColors.accentOrange, AppColors.pastelPeach, () => context.push(AppRoutes.assessmentBuilder)),
                          _resourceTile(context, 'Activities', 'Play-based learning', Icons.celebration_outlined, AppColors.accentLavender, AppColors.pastelLavender, () => context.push(AppRoutes.activityLibrary)),
                        ],
                      ),
                      const SizedBox(height: 24),

                      const SectionHeader(title: 'Languages in your classroom'),
                      const SizedBox(height: 4),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.cardBorder, width: 1),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                LanguageMiniChip(label: 'Hindi • Teaching', background: AppColors.pastelGreen),
                                LanguageMiniChip(label: 'Ho', background: AppColors.pastelBlue),
                                LanguageMiniChip(label: 'Mundari', background: AppColors.pastelPeach),
                                LanguageMiniChip(label: 'Santali', background: AppColors.pastelLavender),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Available on this device • Works without internet',
                              style: AppTypography.caption.copyWith(color: AppColors.primaryDark, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          body: Center(
            child: Text('Loading…', style: AppTypography.bodyMedium),
          ),
        );
      },
    );
  }

  Widget _primaryAction(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color bg,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return CustomCard(
      onTap: onTap,
      color: Colors.white,
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.cardTitle.copyWith(fontSize: 17)),
                const SizedBox(height: 2),
                Text(subtitle, style: AppTypography.bodySmall),
              ],
            ),
          ),
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
            child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _resourceTile(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color iconColor,
    Color iconBg,
    VoidCallback onTap,
  ) {
    return CustomCard(
      onTap: onTap,
      color: Colors.white,
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 8),
          Text(title, style: AppTypography.cardTitle.copyWith(fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
          Text(subtitle, style: AppTypography.caption, maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
