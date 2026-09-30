import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/custom_card.dart';
import '../../../../core/widgets/educational_illustrations.dart';
import '../../../../core/widgets/section_header.dart';
import '../bloc/teach_bloc.dart';
import '../widgets/teacher_guidance_offline_card.dart';

class TeachHomeScreen extends StatefulWidget {
  const TeachHomeScreen({super.key});

  @override
  State<TeachHomeScreen> createState() => _TeachHomeScreenState();
}

class _TeachHomeScreenState extends State<TeachHomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TeachBloc, TeachState>(
      builder: (context, state) {
        if (state is TeachLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
          );
        }

        if (state is TeachLoaded) {
          final selectedGrade = state.selectedGrade;

          return AppScaffold(
            title: 'Teach',
            subtitle: 'Explore. Plan. Teach. Make an Impact.',
            breadcrumb: 'Teach Workspace',
            showBackButton: false,
            isScrollable: true,
            headerTrailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.search_rounded, color: AppColors.textPrimary, size: 20),
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert_rounded, color: AppColors.textPrimary, size: 20),
                  onPressed: () {},
                ),
              ],
            ),
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Class Selection Chips (Class 1 to 5)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [1, 2, 3, 4, 5].map((g) {
                      final isSelected = selectedGrade == g;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text('Class $g'),
                          selected: isSelected,
                          selectedColor: AppColors.greenLight,
                          backgroundColor: Colors.white,
                          labelStyle: TextStyle(
                            color: isSelected ? AppColors.primaryDark : AppColors.textPrimary,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            fontSize: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: AppRadius.radiusPill,
                            side: BorderSide(
                              color: isSelected ? AppColors.primary : AppColors.cardBorder,
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          onSelected: (selected) {
                            if (selected) {
                              context.read<TeachBloc>().add(LoadCurriculumData(grade: g));
                            }
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 14),

                // Hero Illustrated Banner — white card, illustration on the side
                CustomCard(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.greenLight,
                                borderRadius: AppRadius.radiusPill,
                              ),
                              child: Text(
                                'Some learning. In Every Child\'s Language.',
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.primaryDark,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Class $selectedGrade Teaching Plan',
                              style: AppTypography.cardTitle.copyWith(fontSize: 14),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Curriculum-aligned units, local resources & worksheets',
                              style: AppTypography.caption,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      const SizedBox(
                        width: 70,
                        height: 60,
                        child: ClassroomHeroIllustration(height: 60, width: 70),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Subjects Section Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text('Subjects', style: AppTypography.sectionTitle.copyWith(fontSize: 16), overflow: TextOverflow.ellipsis),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () => context.push('/teach/class/$selectedGrade'),
                      child: Row(
                        children: [
                          Text('View All', style: AppTypography.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
                          const SizedBox(width: 2),
                          const Icon(Icons.arrow_forward_ios_rounded, size: 10, color: AppColors.primary),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // 2x2 Subjects Grid (Language, Math, EVS, Art)
                Row(
                  children: [
                    Expanded(
                      child: _buildSubjectGridCard(
                        title: 'Language',
                        icon: Icons.auto_stories_rounded,
                        color: AppColors.primary,
                        onTap: () {
                          context.read<TeachBloc>().add(const SelectSubject('Language'));
                          context.push(AppRoutes.literacy);
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildSubjectGridCard(
                        title: 'Mathematics',
                        icon: Icons.calculate_rounded,
                        color: AppColors.accentOrange,
                        onTap: () {
                          context.read<TeachBloc>().add(const SelectSubject('Mathematics'));
                          context.push('/teach/subject/math');
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildSubjectGridCard(
                        title: 'Environmental\nStudies',
                        icon: Icons.eco_rounded,
                        color: AppColors.accentBlue,
                        onTap: () {
                          context.read<TeachBloc>().add(const SelectSubject('EVS'));
                          context.push('/teach/subject/evs');
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildSubjectGridCard(
                        title: 'Art & Activity',
                        icon: Icons.palette_rounded,
                        color: AppColors.accentLavender,
                        onTap: () {
                          context.read<TeachBloc>().add(const SelectSubject('Art'));
                          context.push('/teach/subject/art');
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),

                // Teacher Guidance & Offline Lesson Support — compact panel
                // in the main Teach workspace (above the bottom nav safe
                // area, part of the normal scroll with bottom padding so it
                // is never hidden behind the navbar). Class/subject context
                // comes from the live TeachBloc state — never hardcoded.
                TeacherGuidanceOfflineCard(
                  selectedGrade: selectedGrade,
                  selectedSubject: state.selectedSubject,
                  outcomeCount: state.outcomes.length,
                ),
                const SizedBox(height: 22),

                // Quick Access (4 cards)
                Text('Quick Access', style: AppTypography.sectionTitle.copyWith(fontSize: 16)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildQuickAccessCard(
                        title: 'Worksheets',
                        subtitle: 'Create & use',
                        icon: Icons.description_outlined,
                        color: AppColors.primary,
                        onTap: () => context.push(AppRoutes.worksheetGenerator),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildQuickAccessCard(
                        title: 'Flashcards',
                        subtitle: 'Visual learning',
                        icon: Icons.style_outlined,
                        color: AppColors.accentOrange,
                        onTap: () => context.push(AppRoutes.flashcardGenerator),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildQuickAccessCard(
                        title: 'Assessments',
                        subtitle: 'Quick & flexible',
                        icon: Icons.fact_check_outlined,
                        color: AppColors.accentAmber,
                        onTap: () => context.push(AppRoutes.assessmentBuilder),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildQuickAccessCard(
                        title: 'Local Library',
                        subtitle: 'Stories & examples',
                        icon: Icons.auto_awesome_outlined,
                        color: AppColors.accentBlue,
                        onTap: () => context.push(AppRoutes.localContext),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Maatribhasha SmartBoard: offline classroom whiteboard
                // (Hindi/English → Santali). Entry point for the prototype.
                _buildQuickAccessCard(
                  title: 'SmartBoard',
                  subtitle: 'Write, draw & show Santali on the big board',
                  icon: Icons.draw_rounded,
                  color: AppColors.primary,
                  onTap: () => context.push(AppRoutes.smartboard),
                ),
                const SizedBox(height: 22),

                // Recent Resources
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text('Recent Resources', style: AppTypography.sectionTitle.copyWith(fontSize: 16), overflow: TextOverflow.ellipsis),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () => context.push(AppRoutes.localContext),
                      child: Row(
                        children: [
                          Text('View All', style: AppTypography.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
                          const SizedBox(width: 2),
                          const Icon(Icons.arrow_forward_ios_rounded, size: 10, color: AppColors.primary),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildRecentResourceItem(
                  title: 'Animals Around Us',
                  subtitle: 'Class 2 • Environmental Studies',
                  icon: Icons.pets_rounded,
                  color: AppColors.primary,
                  onTap: () => context.push(AppRoutes.topicDetail),
                ),
                const SizedBox(height: 8),
                _buildRecentResourceItem(
                  title: 'Counting Objects',
                  subtitle: 'Class 1 • Mathematics',
                  icon: Icons.pin_rounded,
                  color: AppColors.accentOrange,
                  onTap: () => context.push(AppRoutes.topicDetail),
                ),
                const SizedBox(height: 8),
                _buildRecentResourceItem(
                  title: 'Our Village',
                  subtitle: 'Class 3 • Language',
                  icon: Icons.holiday_village_rounded,
                  color: AppColors.accentBlue,
                  onTap: () => context.push(AppRoutes.topicDetail),
                ),
                const SizedBox(height: 24),

                // Foundational Strands Deep Links
                SectionHeader(
                  title: 'Foundational Literacy Strands',
                  titleHindi: 'साक्षरता आयाम (FLN)',
                  actionLabel: 'Explore All',
                  onAction: () => context.push(AppRoutes.literacy),
                ),
                const SizedBox(height: 8),
                _buildStrandPill(
                  title: '1. Oral Language Development',
                  titleHi: 'मौखिक भाषा विकास (बातचीत, कहानी, चर्चा)',
                  icon: Icons.record_voice_over_rounded,
                  color: AppColors.primary,
                  onTap: () => context.push(AppRoutes.oralLanguage),
                ),
                const SizedBox(height: 8),
                _buildStrandPill(
                  title: '2. Decoding & Phonological Awareness',
                  titleHi: 'डिकोडिंग (ध्वनि-चिह्न संबंध, अक्षर जोड़)',
                  icon: Icons.grid_view_rounded,
                  color: AppColors.accentBlue,
                  onTap: () => context.push(AppRoutes.decoding),
                ),
                const SizedBox(height: 8),
                _buildStrandPill(
                  title: '3. Reading & Comprehension',
                  titleHi: 'पढ़ना और समझना (द्विभाषी पठन, समझ प्रश्न)',
                  icon: Icons.menu_book_rounded,
                  color: AppColors.accentAmber,
                  onTap: () => context.push(AppRoutes.readingComprehension),
                ),
                const SizedBox(height: 8),
                _buildStrandPill(
                  title: '4. Writing & Expression',
                  titleHi: 'लिखना और अभिव्यक्ति (अक्षर अनुरेखण, वाक्य निर्माण)',
                  icon: Icons.edit_note_rounded,
                  color: AppColors.accentOrange,
                  onTap: () => context.push(AppRoutes.writingExpression),
                ),
                const SizedBox(height: 28),
              ],
            ),
          );
        }

        return const Scaffold(body: SizedBox.shrink());
      },
    );
  }

  Widget _buildSubjectGridCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    // White card; the accent lives in the small icon wash + arrow only.
    return CustomCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTypography.cardTitle.copyWith(fontSize: 13),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAccessCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return CustomCard(
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.cardTitleSmall.copyWith(fontSize: 12, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subtitle,
                  style: AppTypography.captionSmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios_rounded, size: 10, color: AppColors.textMuted),
        ],
      ),
    );
  }

  Widget _buildRecentResourceItem({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return CustomCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.cardTitleSmall.copyWith(fontSize: 13)),
                const SizedBox(height: 2),
                Text(subtitle, style: AppTypography.captionSmall),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppColors.textMuted),
        ],
      ),
    );
  }

  Widget _buildStrandPill({
    required String title,
    required String titleHi,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return CustomCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: AppRadius.radiusMd,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.cardTitle.copyWith(fontSize: 14), overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(titleHi, style: AppTypography.caption.copyWith(color: AppColors.textSecondary), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textMuted),
        ],
      ),
    );
  }
}
