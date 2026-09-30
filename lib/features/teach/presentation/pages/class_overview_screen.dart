import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/custom_card.dart';
import '../../../../core/widgets/educational_illustrations.dart';

class ClassOverviewScreen extends StatefulWidget {
  final int classId;

  const ClassOverviewScreen({super.key, this.classId = 2});

  @override
  State<ClassOverviewScreen> createState() => _ClassOverviewScreenState();
}

class _ClassOverviewScreenState extends State<ClassOverviewScreen> {
  late int _selectedClass;

  @override
  void initState() {
    super.initState();
    _selectedClass = widget.classId;
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Class Overview',
      subtitle: 'Choose a class to explore subjects and topics.',
      breadcrumb: 'Curriculum > Class $_selectedClass',
      isScrollable: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Class Selection Chips (Class 1 to 5)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [1, 2, 3, 4, 5].map((c) {
                final isSelected = _selectedClass == c;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text('Class $c'),
                    selected: isSelected,
                    selectedColor: AppColors.primary,
                    backgroundColor: Colors.white,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.radiusPill,
                      side: BorderSide(
                        color: isSelected ? AppColors.primary : AppColors.cardBorder,
                      ),
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedClass = c);
                      }
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          // Illustrated Classroom Banner — white card
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
                          'Small Steps Brighter Futures',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.w700,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Class $_selectedClass Learning Journey',
                        style: AppTypography.cardTitle.copyWith(fontSize: 14),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Foundational multi-language modules and activities',
                        style: AppTypography.caption,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                const SizedBox(
                  width: 70,
                  height: 60,
                  child: ClassroomHeroIllustration(height: 60, width: 70),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Header: Subjects in Class X
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Subjects in Class $_selectedClass',
                  style: AppTypography.sectionTitle.copyWith(fontSize: 16),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.greenSurface,
                  borderRadius: AppRadius.radiusPill,
                ),
                child: Text(
                  '4 subjects',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 1. Language
          _buildSubjectCard(
            context: context,
            title: 'Language',
            subtitle: 'Stories, rhymes and everyday communication',
            topicsTotal: 12,
            topicsCompleted: 8,
            icon: Icons.auto_stories_rounded,
            color: AppColors.primary,
            route: AppRoutes.literacy,
          ),
          const SizedBox(height: 12),

          // 2. Mathematics
          _buildSubjectCard(
            context: context,
            title: 'Mathematics',
            subtitle: 'Numbers, shapes and problem solving',
            topicsTotal: 10,
            topicsCompleted: 6,
            icon: Icons.calculate_rounded,
            color: AppColors.accentOrange,
            route: '/teach/subject/math',
          ),
          const SizedBox(height: 12),

          // 3. Environmental Studies
          _buildSubjectCard(
            context: context,
            title: 'Environmental Studies',
            subtitle: 'Our surroundings, people, plants and animals',
            topicsTotal: 8,
            topicsCompleted: 3,
            icon: Icons.eco_rounded,
            color: AppColors.primaryDark,
            route: '/teach/subject/evs',
          ),
          const SizedBox(height: 12),

          // 4. Art & Activity
          _buildSubjectCard(
            context: context,
            title: 'Art & Activity',
            subtitle: 'Creativity, crafts and fun learning',
            topicsTotal: 6,
            topicsCompleted: 4,
            icon: Icons.palette_rounded,
            color: AppColors.accentAmber,
            route: '/teach/subject/art',
          ),
          const SizedBox(height: 20),

          // Motivational Bottom Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.cardCream,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Row(
              children: [
                const Icon(Icons.park_rounded, color: AppColors.primary, size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Every subject is a new opportunity to inspire young minds.',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSubjectCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required int topicsTotal,
    required int topicsCompleted,
    required IconData icon,
    required Color color,
    required String route,
  }) {
    final progress = topicsTotal > 0 ? topicsCompleted / topicsTotal : 0.0;

    return CustomCard(
      onTap: () => context.push(route),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTypography.cardTitle.copyWith(fontSize: 15)),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textMuted),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text('$topicsTotal topics', style: AppTypography.caption, overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(width: 8),
              Text(
                '$topicsCompleted completed',
                style: AppTypography.caption.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: AppRadius.radiusPill,
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: AppColors.cardBorder,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class SubjectDetailScreen extends StatefulWidget {
  final String subjectId;

  const SubjectDetailScreen({super.key, this.subjectId = 'math'});

  @override
  State<SubjectDetailScreen> createState() => _SubjectDetailScreenState();
}

class _SubjectDetailScreenState extends State<SubjectDetailScreen> {
  int _activeTab = 0; // 0 = Units, 1 = About
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMath = widget.subjectId.toLowerCase().contains('math');
    final subjectName = isMath ? 'Mathematics' : 'Language';

    final units = isMath
        ? [
            {
              'id': 1,
              'name': 'Numbers up to 100',
              'desc': 'Read, write, compare and use numbers in daily life.',
              'topics': '6 topics',
              'status': '8 / 8 completed',
              'isCompleted': true,
            },
            {
              'id': 2,
              'name': 'Addition and Subtraction',
              'desc': 'Understand and solve simple addition and subtraction problems.',
              'topics': '5 topics',
              'status': '3 / 5 completed',
              'isCompleted': false,
            },
            {
              'id': 3,
              'name': 'Shapes and Patterns',
              'desc': 'Identify and create shapes and patterns in the environment.',
              'topics': '4 topics',
              'status': '1 / 4 completed',
              'isCompleted': false,
            },
            {
              'id': 4,
              'name': 'Measurement',
              'desc': 'Compare and measure length, weight, capacity and time.',
              'topics': '4 topics',
              'status': '0 / 4 completed',
              'isCompleted': false,
            },
            {
              'id': 5,
              'name': 'Data Handling',
              'desc': 'Collect, organise and represent data using simple charts.',
              'topics': '3 topics',
              'status': '0 / 3 completed',
              'isCompleted': false,
            },
          ]
        : [
            {
              'id': 1,
              'name': 'Oral Language Development',
              'desc': 'Listening, speaking, vocabulary, picture talk and stories.',
              'topics': '6 topics',
              'status': '5 / 6 completed',
              'isCompleted': false,
            },
            {
              'id': 2,
              'name': 'Decoding & Phonics',
              'desc': 'Sound-symbol relationships and blending local letters.',
              'topics': '5 topics',
              'status': '4 / 5 completed',
              'isCompleted': false,
            },
            {
              'id': 3,
              'name': 'Reading & Comprehension',
              'desc': 'Bilingual short texts and picture-supported reading.',
              'topics': '4 topics',
              'status': '2 / 4 completed',
              'isCompleted': false,
            },
            {
              'id': 4,
              'name': 'Writing & Expression',
              'desc': 'Letter tracing, copy work and drawing explanations.',
              'topics': '4 topics',
              'status': '1 / 4 completed',
              'isCompleted': false,
            },
          ];

    return AppScaffold(
      title: 'Subject Detail',
      subtitle: 'Explore units and topics from the curriculum.',
      breadcrumb: 'Class 2 • $subjectName',
      isScrollable: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero Banner — white card
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
                          isMath ? 'Numbers Build Brighter Futures' : 'Languages Connect Worlds',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.w700,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Class 2 • $subjectName',
                        style: AppTypography.cardTitle.copyWith(fontSize: 14),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'NIPUN Bharat aligned learning outcomes',
                        style: AppTypography.caption,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const SizedBox(
                  width: 65,
                  height: 55,
                  child: ClassroomHeroIllustration(height: 55, width: 65),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Units / About Segmented Control
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadius.radiusPill,
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _activeTab = 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: _activeTab == 0 ? AppColors.primary : Colors.transparent,
                        borderRadius: AppRadius.radiusPill,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Units',
                        style: TextStyle(
                          color: _activeTab == 0 ? Colors.white : AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _activeTab = 1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: _activeTab == 1 ? AppColors.primary : Colors.transparent,
                        borderRadius: AppRadius.radiusPill,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'About',
                        style: TextStyle(
                          color: _activeTab == 1 ? Colors.white : AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (_activeTab == 0) ...[
            // Search field
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search units or topics...',
                prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.textSecondary),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
            ),
            const SizedBox(height: 14),

            // Units List
            ...units.map((u) {
              final id = u['id'] as int;
              final name = u['name'] as String;
              final desc = u['desc'] as String;
              final topics = u['topics'] as String;
              final status = u['status'] as String;
              final isCompleted = u['isCompleted'] as bool;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: CustomCard(
                  onTap: () => context.push(AppRoutes.topicDetail),
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: isCompleted ? AppColors.greenSurface : AppColors.surface,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isCompleted ? AppColors.primary : AppColors.cardBorder,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '$id',
                              style: TextStyle(
                                color: isCompleted ? AppColors.primary : AppColors.textSecondary,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        name,
                                        style: AppTypography.cardTitle.copyWith(fontSize: 14),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: isCompleted ? AppColors.greenSurface : AppColors.surface,
                                        borderRadius: AppRadius.radiusPill,
                                        border: Border.all(
                                          color: isCompleted ? AppColors.greenBorder : AppColors.cardBorder,
                                        ),
                                      ),
                                      child: Text(
                                        status,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: isCompleted ? AppColors.primary : AppColors.textSecondary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(desc, style: AppTypography.caption),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 12,
                                  runSpacing: 4,
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.topic_outlined, size: 12, color: AppColors.textSecondary),
                                        const SizedBox(width: 4),
                                        Text(topics, style: AppTypography.captionSmall),
                                      ],
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.description_outlined, size: 12, color: AppColors.textSecondary),
                                        const SizedBox(width: 4),
                                        Text('Worksheets', style: AppTypography.captionSmall),
                                      ],
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.headphones_outlined, size: 12, color: AppColors.textSecondary),
                                        const SizedBox(width: 4),
                                        Text('Audio', style: AppTypography.captionSmall),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppColors.textMuted),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
          ] else ...[
            // About tab
            CustomCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Curriculum Overview', style: AppTypography.cardTitle),
                  const SizedBox(height: 8),
                  Text(
                    'Aligned with NIPUN Bharat Foundational Literacy and Numeracy (FLN) competencies for Class 2 students in Jharkhand government schools.',
                    style: AppTypography.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  Text('Key Pillars:', style: AppTypography.cardTitleSmall),
                  const SizedBox(height: 6),
                  Text('• Mother tongue scaffolding (Hindi, Ho, Mundari, Santali)', style: AppTypography.caption),
                  Text('• Concrete-to-abstract experiential pedagogy', style: AppTypography.caption),
                  Text('• Offline interactive worksheets and flashcards', style: AppTypography.caption),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),

          // Motivational Footer
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.cardCream,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Row(
              children: [
                const Icon(Icons.eco_rounded, color: AppColors.primary, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Every topic is a step towards a brighter tomorrow.',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
