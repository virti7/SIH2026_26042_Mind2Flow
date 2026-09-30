import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/enums/app_enums.dart';
import '../../../../core/models/app_models.dart';
import '../../../../core/repositories/app_repositories.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/audio_play_button.dart';
import '../../../../core/widgets/badges.dart';
import '../../../../core/widgets/chips.dart';
import '../../../../core/widgets/custom_card.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../app/di/injection.dart';

// SCREEN 33: Activity Detail (Multilingual Resource Activity Implementation)
class ResourceActivityDetailScreen extends StatefulWidget {
  final String activityId;

  const ResourceActivityDetailScreen({super.key, required this.activityId});

  @override
  State<ResourceActivityDetailScreen> createState() => _ResourceActivityDetailScreenState();
}

class _ResourceActivityDetailScreenState extends State<ResourceActivityDetailScreen> {
  ActivityItem? _activity;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadActivity();
  }

  Future<void> _loadActivity() async {
    final repo = getIt<LessonRepository>();
    final item = await repo.getActivityById(widget.activityId);
    setState(() {
      _activity = item;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    final act = _activity ??
        const ActivityItem(
          id: 'act_001',
          title: 'Sal Leaf Number Tracing & Pebble Counting',
          titleHi: 'सखुआ के पत्तों पर संख्याओं की माला',
          grade: 2,
          subject: 'Mathematics',
          strandOrStage: 'Skills Practice',
          language: TribalLanguage.mundari,
          durationMinutes: 20,
          difficulty: DifficultyLevel.easy,
          materials: 'Dried sal leaves, chalk, small pebbles or tamarind seeds',
          teacherSteps: [
            'Hand out 5 broad sal leaves to each child.',
            'Instruct students to write numerals 10, 20, 30, 40, 50 with chalk.',
            'Place corresponding pebble counters beside each leaf in groups of ten.',
          ],
          studentSteps: [
            'Write numeral clearly on sal leaf using chalk.',
            'Count pebbles in Mundari: गेल (10), हिसि (20), हिसि-गेल (30).',
            'Verify counts with their desk partner in their mother tongue.',
          ],
          questions: [
            '30 में कितने 10 हैं? (चिमिन गेल मेनाः?)',
            'सखुआ के पत्तों की ढेरी से 2 पत्तियां हटाने पर कितनी बचेंगी?',
          ],
          expectedResponse: 'तीन दहाई (अपिया गेल / 30).',
          audioPromptHindi: 'सखुआ के पत्तों पर 10-10 की ढेरी बनाकर गिनें।',
          audioPromptTribal: 'सरजॉम साकाम रे गेल-गेल लेका केते नेलपे।',
        );

    return AppScaffold(
      title: act.title,
      subtitle: '${act.titleHi} • ${act.subject} Class ${act.grade}',
      breadcrumb: 'Resources > Activity Detail',
      isScrollable: true,
      bottomActionBar: Row(
        children: [
          Expanded(
            child: SecondaryButton(
              label: 'Previous',
              icon: Icons.arrow_back_rounded,
              onPressed: () => context.pop(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SecondaryButton(
              label: 'Print Guide',
              icon: Icons.print_rounded,
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Activity guide sent to offline print queue.')),
                );
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: PrimaryButton(
              label: 'Next',
              trailingIcon: Icons.arrow_forward_rounded,
              onPressed: () => context.push(AppRoutes.assessmentPlay),
            ),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Metadata Overview Card
          CustomCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        LanguageChip(language: act.language, isSelected: true),
                        const NipunBadge(),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.timer_outlined, size: 14, color: AppColors.textMuted),
                        const SizedBox(width: 4),
                        Text('${act.durationMinutes} mins', style: AppTypography.caption),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(act.title, style: AppTypography.screenTitle.copyWith(fontSize: 18)),
                Text(act.titleHi, style: AppTypography.caption.copyWith(color: AppColors.primary, fontSize: 13)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.greenSurface,
                    borderRadius: AppRadius.radiusMd,
                    border: Border.all(color: AppColors.greenBorder),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.verified_rounded, color: AppColors.primary, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('NIPUN Learning Outcome',
                                style: AppTypography.cardTitle.copyWith(fontSize: 13, color: AppColors.primaryDark)),
                            const SizedBox(height: 2),
                            const Text('M2.1.4 • Counts, reads and writes numbers up to 100 using local objects.',
                                style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            const SizedBox(height: 6),
                            const Text('Objective: By the end of this activity, children group loose objects in tens and name the total in Hindi and their mother tongue.',
                                style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                const Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    OfflineBadge(),
                    NipunBadge(),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Audio Scaffold Card
          CustomCard(
            color: AppColors.greenSurface,
            border: const BorderSide(color: AppColors.greenBorder),
            child: Row(
              children: [
                const AudioPlayButton(),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Classroom Audio Prompt (${act.language.displayName})',
                        style: AppTypography.cardTitle.copyWith(fontSize: 13, color: AppColors.primaryDark),
                      ),
                      const SizedBox(height: 2),
                      Text(act.audioPromptTribal, style: AppTypography.tribalVernacular.copyWith(fontSize: 13)),
                      Text('Hindi: "${act.audioPromptHindi}"', style: AppTypography.caption),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Required Materials Card
          CustomCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.backpack_outlined, color: AppColors.primary, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('Required Classroom Materials (आवश्यक सामग्री)', style: AppTypography.cardTitle.copyWith(fontSize: 14)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(act.materials, style: AppTypography.bodySmall),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Teacher Step-by-Step
          SectionHeader(title: 'Teacher Instructional Steps', titleHindi: 'शिक्षक निर्देश'),
          const SizedBox(height: 8),
          ...act.teacherSteps.asMap().entries.map((e) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: CustomCard(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: AppColors.primary,
                      child: Text('${e.key + 1}', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(e.value, style: AppTypography.bodySmall)),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 16),

          // Student Task
          SectionHeader(title: 'Student Interactive Task', titleHindi: 'विद्यार्थी कार्य'),
          const SizedBox(height: 8),
          ...act.studentSteps.asMap().entries.map((e) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: CustomCard(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: AppColors.accentBlue,
                      child: Text('${e.key + 1}', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(e.value, style: AppTypography.bodySmall)),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 16),

          // Expected Response
          CustomCard(
            color: AppColors.surface,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Expected Student Response (अपेक्षित उत्तर):', style: AppTypography.caption.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(act.expectedResponse, style: AppTypography.tribalVernacular.copyWith(fontSize: 14)),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Teacher prompts (multilingual)
          SectionHeader(title: 'Teacher Prompts', titleHindi: 'शिक्षक प्रश्न'),
          const SizedBox(height: 8),
          CustomCard(
            color: AppColors.greenSurface,
            border: const BorderSide(color: AppColors.greenBorder),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const AudioPlayButton(compact: true),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('“कितने समूह बने? गिनकर बताओ।”',
                          style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text('Mundari: “चिमिन पुतली बेना? लेका केते लाईपे।”',
                    style: AppTypography.tribalVernacular.copyWith(fontSize: 13)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const AudioPlayButton(compact: true),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('“अब एक पत्ता हटाओ — कितने बचे?”',
                          style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Teacher tips + extension
          SectionHeader(title: 'Teacher Tips & Extensions', titleHindi: 'सुझाव व विस्तार'),
          const SizedBox(height: 8),
          CustomCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.lightbulb_outline_rounded, color: AppColors.accentAmber, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('Tips for multilingual classes',
                          style: AppTypography.cardTitle.copyWith(fontSize: 14)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text('• Let children answer first in their mother tongue, then repeat in Hindi.\n• Keep groups of ten physically separate so “tens” stay visible.\n• Pair Ho, Mundari and Santali speakers so each hears the other’s counting words.',
                    style: AppTypography.bodySmall),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.extension_outlined, color: AppColors.primary, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('Extension idea (5 extra mins)',
                          style: AppTypography.cardTitle.copyWith(fontSize: 14)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Ask fast finishers to build 63 or 47 with leaves and pebbles, then dictate the number to a partner who writes it.',
                    style: AppTypography.bodySmall),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const CustomCard(
            child: Row(
              children: [
                Icon(Icons.offline_pin_rounded, color: AppColors.primary, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text('Fully available offline — visuals, audio prompts and print guide are stored on this device.',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
