import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_shadows.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_tab_bar.dart';
import '../../../../core/widgets/audio_play_button.dart';
import '../../../../core/widgets/custom_card.dart';
import '../../../../core/widgets/educational_illustrations.dart';

// SCREEN 17: Oral Language Development (Reference B Target)
class OralLanguageLibraryScreen extends StatefulWidget {
  const OralLanguageLibraryScreen({super.key});

  @override
  State<OralLanguageLibraryScreen> createState() => _OralLanguageLibraryScreenState();
}

class _OralLanguageLibraryScreenState extends State<OralLanguageLibraryScreen> {
  String _selectedLanguage = 'Hindi';

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;

    return AppScaffold(
      title: 'Oral Language Development',
      subtitle: 'मौखिक भाषा विकास: Listening, speaking, vocabulary, picture talk, stories, conversation and question prompts.',
      breadcrumb: 'Teach > Language > Foundational Literacy > Oral Language Development',
      isScrollable: true,
      onBack: () {
        if (Navigator.of(context).canPop()) {
          context.pop();
        } else {
          context.go(AppRoutes.literacy);
        }
      },
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Illustrated Hero Area (Teacher & Children Classroom Motif)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 16),
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
                  ClassroomHeroIllustration(height: isTablet ? 150 : 120),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.greenLight,
                                borderRadius: AppRadius.radiusPill,
                              ),
                              child: Text(
                                'Strand 1 · मौखिक भाषा विकास',
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.volume_up_rounded, size: 18, color: AppColors.primary),
                                const SizedBox(width: 4),
                                Text('Bilingual Audio Support', style: AppTypography.captionSmall),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Oral Language Development',
                          style: isTablet ? AppTypography.pageTitle : AppTypography.sectionHeading,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Listening, speaking, vocabulary, picture talk, stories, conversation and question prompts.',
                          style: AppTypography.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 14. LEARNING OUTCOME CARD (Strand Goal)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.strandGreenBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.25), width: 1.2),
              boxShadow: AppShadows.card,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.flag_rounded, color: AppColors.primary, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Strand Goal (लक्ष्य)',
                        style: AppTypography.cardTitleSmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Help children express themselves confidently in their home language while building vocabulary and communication skills.',
                        style: AppTypography.bodySmall.copyWith(color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 15. "WHAT YOU'LL FIND HERE" SECTION
          Text("What You'll Find Here", style: AppTypography.sectionTitle),
          const SizedBox(height: 4),
          Text('Core pedagogical resources for classroom talk', style: AppTypography.caption),
          const SizedBox(height: 12),

          // Resource Cards Grid (Responsive)
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth >= 768 ? 3 : (constraints.maxWidth >= 480 ? 2 : 1);
              return GridView.count(
                crossAxisCount: crossAxisCount,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: crossAxisCount == 1 ? 3.4 : 2.2,
                children: [
                  _buildResourceCard(
                    icon: Icons.chat_bubble_outline_rounded,
                    title: 'Conversation Prompts',
                    desc: 'Daily talk topics & teacher prompts',
                    color: AppColors.primary,
                  ),
                  _buildResourceCard(
                    icon: Icons.image_search_rounded,
                    title: 'Picture Talk',
                    desc: 'Village haat & forest observation charts',
                    color: AppColors.accentBlue,
                  ),
                  _buildResourceCard(
                    icon: Icons.auto_stories_rounded,
                    title: 'Stories',
                    desc: 'Tribal folktales & cultural narratives',
                    color: AppColors.accentAmber,
                  ),
                  _buildResourceCard(
                    icon: Icons.graphic_eq_rounded,
                    title: 'Audio Support',
                    desc: 'Native speaker pronunciation audio',
                    color: AppColors.accentOrange,
                  ),
                  _buildResourceCard(
                    icon: Icons.sports_esports_outlined,
                    title: 'Interactive Activities',
                    desc: 'Role play, circle games & rhymes',
                    color: AppColors.primary,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          // 16. FEATURED ACTIVITIES SECTION (Horizontal Scroll / Grid)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text('Featured Activities', style: AppTypography.sectionTitle, overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(width: 8),
              Text('प्रमुख गतिविधियाँ', style: AppTypography.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),

          SizedBox(
            height: 160,
            child: ListView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              children: [
                _buildFeaturedActivityCard(
                  context,
                  id: 'act_003',
                  title: 'What do you see?',
                  titleHi: 'चित्र में क्या दिखा?',
                  category: 'Picture Talk',
                  duration: '20 mins',
                  group: 'Whole Class',
                  icon: Icons.visibility_rounded,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 12),
                _buildFeaturedActivityCard(
                  context,
                  id: 'act_oral_2',
                  title: 'My Village (हमारा गाँव)',
                  titleHi: 'हाट-बाजार नाटक',
                  category: 'Conversation',
                  duration: '25 mins',
                  group: 'Pairs & Groups',
                  icon: Icons.storefront_rounded,
                  color: AppColors.accentBlue,
                ),
                const SizedBox(width: 12),
                _buildFeaturedActivityCard(
                  context,
                  id: 'act_oral_3',
                  title: 'The Clever Deer',
                  titleHi: 'चतुर हिरण की कथा',
                  category: 'Storytelling',
                  duration: '30 mins',
                  group: 'Story Circle',
                  icon: Icons.pets_rounded,
                  color: AppColors.accentAmber,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 17. MULTILINGUAL SUPPORT SECTION
          Text('Multilingual Support', style: AppTypography.sectionTitle),
          const SizedBox(height: 4),
          Text('Select a classroom language for localized prompts and audio', style: AppTypography.caption),
          const SizedBox(height: 12),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _buildLanguageChip('Hindi', 'हिंदी', Icons.translate_rounded),
                const SizedBox(width: 10),
                _buildLanguageChip('Ho', 'हो (वारंग क्षिति)', Icons.record_voice_over_rounded),
                const SizedBox(width: 10),
                _buildLanguageChip('Mundari', 'मुंडारी', Icons.volume_up_rounded),
                const SizedBox(width: 10),
                _buildLanguageChip('Santali', 'संताली (ओल चिकी)', Icons.audiotrack_rounded),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // All Activities in Strand
          Text('All Oral Language Activities', style: AppTypography.sectionTitle),
          const SizedBox(height: 10),
          _buildActivityCard(
            context,
            id: 'act_003',
            title: 'Weekly Haat Role Play (हाट-बाजार नाटक)',
            strand: 'Oral Conversation',
            time: '25 mins',
            languages: 'Hindi + Ho / Mundari',
            desc: 'Children role-play buyers and sellers at Torpa market using mother tongue numbers and greetings.',
          ),
          const SizedBox(height: 10),
          _buildActivityCard(
            context,
            id: 'act_oral_2',
            title: 'Village Forest Walk (जंगल की सैर)',
            strand: 'Picture Talk',
            time: '20 mins',
            languages: 'Hindi + Santali',
            desc: 'Large visual chart of Sal forest. Children name trees, birds, and animals in mother tongue.',
          ),
          const SizedBox(height: 10),
          _buildActivityCard(
            context,
            id: 'act_oral_3',
            title: 'Sarhul Celebration Story (सरहुल की कथा)',
            strand: 'Story Narration',
            time: '30 mins',
            languages: 'Bilingual Audio',
            desc: 'Teacher narrates sacred grove story in Hindi; native speaker audio provides Santali narration.',
          ),
          const SizedBox(height: 28),
        ],
      ),
    );
  }

  Widget _buildResourceCard({
    required IconData icon,
    required String title,
    required String desc,
    required Color color,
  }) {
    // White card; strand color lives in the small icon wash only.
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.cardTitleSmall.copyWith(fontSize: 13, fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: AppTypography.captionSmall.copyWith(color: AppColors.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedActivityCard(
    BuildContext context, {
    required String id,
    required String title,
    required String titleHi,
    required String category,
    required String duration,
    required String group,
    required IconData icon,
    required Color color,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push('/literacy/activity/$id'),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 200,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder, width: 1.2),
            boxShadow: AppShadows.card,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: AppRadius.radiusPill,
                    ),
                    child: Text(
                      category,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                  ),
                  Icon(icon, color: color, size: 18),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: AppTypography.cardTitleSmall.copyWith(fontWeight: FontWeight.w700),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                titleHi,
                style: AppTypography.captionSmall.copyWith(color: color),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '$duration • $group',
                      style: AppTypography.captionSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(Icons.arrow_forward_rounded, size: 16, color: color),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageChip(String lang, String script, IconData icon) {
    final isSelected = _selectedLanguage == lang;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _selectedLanguage = lang),
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 120,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.greenLight : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.cardBorder,
              width: isSelected ? 1.5 : 1,
            ),
            boxShadow: isSelected ? AppShadows.card : null,
          ),
          child: Column(
            children: [
              Icon(icon, size: 18, color: isSelected ? AppColors.primary : AppColors.textMuted),
              const SizedBox(height: 4),
              Text(
                lang,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                script,
                style: TextStyle(
                  fontSize: 9.5,
                  color: isSelected ? AppColors.primary : AppColors.textMuted,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// SCREEN 18: Decoding (Reference C Reusable Detail Tab Screen)
class DecodingLibraryScreen extends StatefulWidget {
  const DecodingLibraryScreen({super.key});

  @override
  State<DecodingLibraryScreen> createState() => _DecodingLibraryScreenState();
}

class _DecodingLibraryScreenState extends State<DecodingLibraryScreen> {
  int _selectedTabIndex = 0;

  final List<TabItemData> _tabs = const [
    TabItemData(label: 'Overview', icon: Icons.dashboard_outlined),
    TabItemData(label: 'Activities', icon: Icons.sports_esports_outlined, badge: '6'),
    TabItemData(label: 'Stories', icon: Icons.menu_book_rounded),
    TabItemData(label: 'Audio', icon: Icons.volume_up_rounded),
    TabItemData(label: 'Worksheets', icon: Icons.assignment_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;

    return AppScaffold(
      title: 'Class 2 · Foundational Literacy',
      subtitle: 'डिकोडिंग एवं ध्वनि-चिह्न संबंध: Sound-symbol relationships and blending.',
      breadcrumb: 'Teach > Language > Decoding',
      isScrollable: true,
      onBack: () {
        if (Navigator.of(context).canPop()) {
          context.pop();
        } else {
          context.go(AppRoutes.literacy);
        }
      },
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 20. TAB DESIGN & 19. FUNCTIONAL TABS
          AppTabBar(
            tabs: _tabs,
            selectedIndex: _selectedTabIndex,
            onTabSelected: (idx) => setState(() => _selectedTabIndex = idx),
          ),
          const SizedBox(height: 12),

          // Dynamic Tab Content Switching
          if (_selectedTabIndex == 0)
            _buildOverviewTab(context, isTablet)
          else if (_selectedTabIndex == 1)
            _buildActivitiesTab(context)
          else if (_selectedTabIndex == 2)
            _buildStoriesTab(context)
          else if (_selectedTabIndex == 3)
            _buildAudioTab(context)
          else
            _buildWorksheetsTab(context),
        ],
      ),
    );
  }

  // Reference C Overview / Decoding Detail Content
  Widget _buildOverviewTab(BuildContext context, bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 21. DECODING DETAIL HERO
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.cardBorder, width: 1),
            boxShadow: AppShadows.card,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.strandBlueBg,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.accentBlue.withValues(alpha: 0.3), width: 1),
                    ),
                    child: const Center(
                      child: Text('2', style: TextStyle(color: AppColors.accentBlue, fontWeight: FontWeight.w800, fontSize: 16)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Decoding', style: AppTypography.pageTitle.copyWith(fontSize: 24)),
                        Text('डिकोडिंग (ध्वनि-चिह्न संबंध)', style: AppTypography.caption.copyWith(color: AppColors.accentBlue, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Help children recognise and connect sounds, symbols and letters to read words with confidence.',
                style: AppTypography.bodyMedium,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Learning Outcomes Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.strandBlueBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.accentBlue.withValues(alpha: 0.25), width: 1),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.check_circle_outline_rounded, color: AppColors.accentBlue, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Learning Outcomes (अधिगम प्रतिफल)',
                      style: AppTypography.cardTitleSmall.copyWith(color: AppColors.accentBlue, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Children understand letter-sound relationships, identify letters, blend sounds and read simple words.',
                      style: AppTypography.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Explore Activities (6 Cards)
        Text('Explore Activities', style: AppTypography.sectionTitle),
        const SizedBox(height: 4),
        Text('Targeted phonics & decoding practice modules', style: AppTypography.caption),
        const SizedBox(height: 12),

        LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount = constraints.maxWidth >= 768 ? 3 : (constraints.maxWidth >= 480 ? 2 : 1);
            return GridView.count(
              crossAxisCount: crossAxisCount,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: crossAxisCount == 1 ? 3.8 : 2.2,
              children: [
                _buildDecodingPill(context, '1. Letter Recognition', 'वर्ण पहचान', Icons.sort_by_alpha_rounded, AppColors.primary),
                _buildDecodingPill(context, '2. Sound Matching', 'ध्वनि मिलान', Icons.hearing_rounded, AppColors.accentBlue),
                _buildDecodingPill(context, '3. Picture-Sound Cards', 'चित्र-ध्वनि कार्ड', Icons.style_rounded, AppColors.accentAmber),
                _buildDecodingPill(context, '4. Blending Sounds', 'अक्षर जोड़ (कम, जल)', Icons.join_inner_rounded, AppColors.accentOrange),
                _buildDecodingPill(context, '5. Word Reading', 'सरल शब्द पठन', Icons.menu_book_rounded, AppColors.primary),
                _buildDecodingPill(context, '6. Practice Worksheets', 'अभ्यास पत्रक', Icons.description_rounded, AppColors.accentBlue),
              ],
            );
          },
        ),
        const SizedBox(height: 28),
      ],
    );
  }

  Widget _buildDecodingPill(BuildContext context, String title, String titleHi, IconData icon, Color color) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _selectedTabIndex = 1),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.cardBorder, width: 1.2),
            boxShadow: AppShadows.card,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTypography.cardTitleSmall.copyWith(fontSize: 13), overflow: TextOverflow.ellipsis),
                    Text(titleHi, style: AppTypography.captionSmall.copyWith(color: color), overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }

  // Activities Tab Content
  Widget _buildActivitiesTab(BuildContext context) {
    return Column(
      children: [
        _buildActivityCard(
          context,
          id: 'act_002',
          title: 'Forest Bird Sound-Symbol Match (ध्वनि मिलान)',
          strand: 'Phonological Awareness',
          time: '15 mins',
          languages: 'Hindi + Santali',
          desc: 'Listen to bird sound cues and locate the matching initial consonant letter on slate.',
        ),
        const SizedBox(height: 12),
        _buildActivityCard(
          context,
          id: 'act_dec_2',
          title: 'Akshar Matka Blending (अक्षर मटका)',
          strand: 'Letter-Sound Blending',
          time: '20 mins',
          languages: 'Hindi + Mundari',
          desc: 'Combine consonant and vowel flashcards to form simple 2-letter words (कम, जल, फल).',
        ),
        const SizedBox(height: 12),
        _buildActivityCard(
          context,
          id: 'act_dec_3',
          title: 'Sound Cards Rapid Recognition',
          strand: 'Word Reading',
          time: '15 mins',
          languages: 'Devanagari + Ol Chiki',
          desc: 'Rapid recognition of high-frequency classroom words with instant tribal audio feedback.',
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  // Stories Tab Content
  Widget _buildStoriesTab(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Decodable Readers & Folktales', style: AppTypography.sectionTitle),
        const SizedBox(height: 4),
        Text('Controlled vocabulary stories with tribal audio narration', style: AppTypography.caption),
        const SizedBox(height: 14),
        _buildStoryCard(
          title: 'Saranda Forest Little Deer (सारंडा का हिरण)',
          lang: 'Bilingual: Hindi & Ho',
          lexile: 'Grade 2 Starter',
          desc: 'Short sentences with 2-letter and 3-letter matra words following the deer near the river.',
        ),
        const SizedBox(height: 12),
        _buildStoryCard(
          title: 'Grandmother\'s Clay Pot (दादी की मटकी)',
          lang: 'Bilingual: Hindi & Mundari',
          lexile: 'Grade 2 Intermediate',
          desc: 'Village pottery story emphasizing repetitive rhyming words and sound blends.',
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildStoryCard({required String title, required String lang, required String lexile, required String desc}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: AppColors.accentAmberLight, borderRadius: AppRadius.radiusPill),
                child: Text(lexile, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.accentAmber)),
              ),
              const AudioPlayButton(label: 'Listen Aloud'),
            ],
          ),
          const SizedBox(height: 8),
          Text(title, style: AppTypography.cardTitle),
          const SizedBox(height: 3),
          Text(lang, style: AppTypography.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(desc, style: AppTypography.bodySmall),
        ],
      ),
    );
  }

  // Audio Tab Content
  Widget _buildAudioTab(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Phoneme & Sound Library', style: AppTypography.sectionTitle),
        const SizedBox(height: 4),
        Text('Native speaker pronunciations across Devanagari and tribal phonology', style: AppTypography.caption),
        const SizedBox(height: 14),
        ...['क (Ka)', 'ख (Kha)', 'म (Ma)', 'र (Ra)', 'ल (La)'].map((akshar) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.cardBorder, width: 1),
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.greenLight,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(akshar.split(' ')[0], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary)),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Sound: $akshar', style: AppTypography.cardTitleSmall),
                        Text('Ho: 𞤀 | Mundari: क | Santali: ᱚ', style: AppTypography.captionSmall),
                      ],
                    ),
                  ),
                  const AudioPlayButton(label: 'Play Sound'),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 24),
      ],
    );
  }

  // Worksheets Tab Content
  Widget _buildWorksheetsTab(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Bilingual Decoding Worksheets', style: AppTypography.sectionTitle),
        const SizedBox(height: 4),
        Text('Printable and slate-ready exercises designed for low-resource schools', style: AppTypography.caption),
        const SizedBox(height: 14),
        _buildWorksheetItem('Letter-Sound Match Sheet 01', 'Match 8 forest animals with initial letters (क, ख, म, स)', 'PDF Available'),
        const SizedBox(height: 10),
        _buildWorksheetItem('Akshar Matka 2-Letter Blends', 'Join letters to complete 6 high-frequency words', 'Slate Exercise'),
        const SizedBox(height: 10),
        _buildWorksheetItem('Picture-to-Word Tracing Card', 'Trace word names under Sal tree, Mahua, and Flute', 'Printable'),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildWorksheetItem(String title, String subtitle, String tag) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder, width: 1),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppColors.strandBlueBg, borderRadius: AppRadius.radiusMd),
            child: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.accentBlue, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.cardTitleSmall),
                const SizedBox(height: 2),
                Text(subtitle, style: AppTypography.captionSmall),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: AppColors.greenLight, borderRadius: AppRadius.radiusPill),
            child: Text(tag, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}

// SCREEN 19: Reading & Comprehension
class ReadingComprehensionLibraryScreen extends StatelessWidget {
  const ReadingComprehensionLibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Reading & Comprehension',
      subtitle: 'पढ़ना और समझना: Bilingual short texts, read-aloud, and reflective contextual questions.',
      breadcrumb: 'Teach > Language > Reading & Comprehension',
      isScrollable: true,
      onBack: () {
        if (Navigator.of(context).canPop()) {
          context.pop();
        } else {
          context.go(AppRoutes.literacy);
        }
      },
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildActivityCard(
            context,
            id: 'act_read_1',
            title: 'The Little Deer of Saranda (सारंडा का हिरण)',
            strand: 'Bilingual Short Text',
            time: '25 mins',
            languages: 'Hindi + Ho',
            desc: 'Graded bilingual story with side-by-side Hindi and Ho translations for paired reading.',
          ),
          const SizedBox(height: 12),
          _buildActivityCard(
            context,
            id: 'act_read_2',
            title: 'Grandmother\'s Clay Pot (दादी की मटकी)',
            strand: 'Read-Aloud & Questions',
            time: '20 mins',
            languages: 'Hindi + Mundari',
            desc: 'Read aloud with pause-and-predict comprehension questions connecting to village pottery.',
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// SCREEN 20: Writing & Expression
class WritingExpressionLibraryScreen extends StatelessWidget {
  const WritingExpressionLibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Writing & Expression',
      subtitle: 'लिखना और अभिव्यक्ति: Letter/word formation, copying, picture-to-sentence, and ideas.',
      breadcrumb: 'Teach > Language > Writing & Expression',
      isScrollable: true,
      onBack: () {
        if (Navigator.of(context).canPop()) {
          context.pop();
        } else {
          context.go(AppRoutes.literacy);
        }
      },
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildActivityCard(
            context,
            id: 'act_write_1',
            title: 'Sand & Clay Letter Formation (रेत व मिट्टी में अक्षर)',
            strand: 'Tactile Tracing',
            time: '20 mins',
            languages: 'All Languages',
            desc: 'Trace numerals and Devanagari letters in wet red soil before copying onto black slates.',
          ),
          const SizedBox(height: 12),
          _buildActivityCard(
            context,
            id: 'act_write_2',
            title: 'Picture to 3-Word Sentence (चित्र से वाक्य निर्माण)',
            strand: 'Sentence Construction',
            time: '25 mins',
            languages: 'Bilingual Slate Work',
            desc: 'Look at a cow grazing near the stream and write: "गाय पानी पीती है" with tribal verbal cue.',
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// SCREEN 21: Literacy Activity Detail
class LiteracyActivityDetailScreen extends StatelessWidget {
  final String activityId;

  const LiteracyActivityDetailScreen({super.key, required this.activityId});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Weekly Haat Role Play',
      subtitle: 'कक्षा गतिविधि: हाट-बाजार नाटक व द्विभाषी संवाद',
      breadcrumb: 'Teach > Literacy > Activity > $activityId',
      isScrollable: true,
      bottomActionBar: Row(
        children: [
          Expanded(
            child: SecondaryButton(
              label: 'Save Activity',
              icon: Icons.bookmark_border_rounded,
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Activity saved to your classroom library!')),
                );
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: PrimaryButton(
              label: 'Start in Class',
              icon: Icons.play_arrow_rounded,
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Classroom activity started.')),
                );
              },
            ),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomCard(
            color: AppColors.greenSurface,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Strand: Oral Language (मौखिक भाषा)', style: AppTypography.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Text('Duration: 25 mins • Grade: Class 2', style: AppTypography.caption, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const AudioPlayButton(label: 'Pronounce Prompt'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text('Teacher Steps (शिक्षक निर्देश):', style: AppTypography.cardTitle),
          const SizedBox(height: 8),
          const Text('1. Divide classroom into 4 market stalls (Vegetables, Clay Toys, Flutes, Bangles).\n2. Model the greeting phrase: "जोहार! नेया चिमिन गोनोङ?"\n3. Prompt learners to reply using numbers 1 to 20.'),
          const SizedBox(height: 16),
          Text('Expected Student Response:', style: AppTypography.cardTitle),
          const SizedBox(height: 6),
          Text('"नेया गेल टका (This is ten rupees) — यह दस रुपये का है।"', style: AppTypography.tribalVernacular),
        ],
      ),
    );
  }
}

Widget _buildActivityCard(
  BuildContext context, {
  required String id,
  required String title,
  required String strand,
  required String time,
  required String languages,
  required String desc,
}) {
  return Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: () => context.push('/literacy/activity/$id'),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder, width: 1.2),
          boxShadow: AppShadows.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: AppColors.greenLight, borderRadius: AppRadius.radiusPill),
                    child: Text(
                      strand,
                      style: AppTypography.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(time, style: AppTypography.caption),
              ],
            ),
            const SizedBox(height: 8),
            Text(title, style: AppTypography.cardTitle),
            const SizedBox(height: 4),
            Text(desc, style: AppTypography.bodySmall),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text('Language: $languages', style: AppTypography.caption.copyWith(color: AppColors.primary), overflow: TextOverflow.ellipsis),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppColors.textMuted),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
