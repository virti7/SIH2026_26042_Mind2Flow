import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/audio_play_button.dart';
import '../../../../core/widgets/custom_card.dart';

// SCREEN 22: Oral Math Talk
class OralMathTalkLibraryScreen extends StatelessWidget {
  const OralMathTalkLibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Oral Math Talk',
      subtitle: 'मौखिक गणित वार्ता: Describe quantity, compare, estimate, and explain strategies.',
      breadcrumb: 'Teach > Numeracy > Oral Math Talk',
      isScrollable: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildNumeracyCard(
            context,
            id: 'num_oral_1',
            title: 'Which Leaf Plate Has More? (किस थाली में अधिक है?)',
            stage: 'Comparison & Estimation',
            time: '15 mins',
            desc: 'Teacher shows two leaf plates with tamarind seeds (14 vs 19). Children estimate without counting.',
          ),
          const SizedBox(height: 12),
          _buildNumeracyCard(
            context,
            id: 'num_oral_2',
            title: 'Subitizing with Dot Cards (बिंदु पहचान)',
            stage: 'Instant Recognition',
            time: '10 mins',
            desc: 'Quickly flash 1 to 10 dot patterns. Children call out quantities instantly in mother tongue.',
          ),
        ],
      ),
    );
  }
}

// SCREEN 23: Skills Teaching
class SkillsTeachingLibraryScreen extends StatelessWidget {
  const SkillsTeachingLibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Skills Teaching',
      subtitle: 'कौशल शिक्षण: Explicit teacher modelling of counting, addition, subtraction, shapes.',
      breadcrumb: 'Teach > Numeracy > Skills Teaching',
      isScrollable: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildNumeracyCard(
            context,
            id: 'num_teach_1',
            title: 'Tens & Units: 10-Bundle Modeling (दहाई-इकाई)',
            stage: 'Explicit Modeling',
            time: '25 mins',
            desc: 'Teacher explicitly counts 10 loose sal twigs, ties with string to define 1 Ten ("गेल").',
          ),
          const SizedBox(height: 12),
          _buildNumeracyCard(
            context,
            id: 'num_teach_2',
            title: 'Number Line on Classroom Floor (फर्श पर संख्या रेखा)',
            stage: 'Spatial Representation',
            time: '20 mins',
            desc: 'Chalk number line 0–20 on the floor. Children jump forward for addition and backward for subtraction.',
          ),
        ],
      ),
    );
  }
}

// SCREEN 24: Skills Practice
class SkillsPracticeLibraryScreen extends StatelessWidget {
  const SkillsPracticeLibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Skills Practice Library',
      subtitle: 'कौशल अभ्यास: Guided practice, bilingual worksheets, matching, and counting exercises.',
      breadcrumb: 'Teach > Numeracy > Skills Practice',
      isScrollable: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildNumeracyCard(
            context,
            id: 'act_001',
            title: 'Sal Leaf Number Tracing & Pebbles',
            stage: 'Guided Practice',
            time: '20 mins',
            desc: 'Draw tens on broad sal leaves with chalk, pair with pebble piles, and verify in pairs.',
          ),
          const SizedBox(height: 12),
          _buildNumeracyCard(
            context,
            id: 'num_prac_2',
            title: 'Bilingual 10-Frame Counting Slates',
            stage: 'Pair Practice',
            time: '15 mins',
            desc: 'Students fill 10-frames on their slates using chalk crosses representing quantities up to 50.',
          ),
        ],
      ),
    );
  }
}

// SCREEN 25: Math Games
class MathGamesLibraryScreen extends StatelessWidget {
  const MathGamesLibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Math Games Library',
      subtitle: 'गणित खेल: Play-based counting, patterns, shapes, and movement-based classroom games.',
      breadcrumb: 'Teach > Numeracy > Math Games',
      isScrollable: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildNumeracyCard(
            context,
            id: 'num_game_1',
            title: 'Banjha Khel: Number Hunt (संख्या खोज खेल)',
            stage: 'Play-Based Game',
            time: '20 mins',
            desc: 'Hide numbered cards around the verandah. Teacher calls out number in Mundari; children run to tag it.',
          ),
          const SizedBox(height: 12),
          _buildNumeracyCard(
            context,
            id: 'num_game_2',
            title: 'Mādal Beat Counting (मांदर ताल गिनती)',
            stage: 'Rhythm & Patterns',
            time: '15 mins',
            desc: 'Teacher claps 2 slow beats and 1 fast beat. Children predict the next rhythm and jump.',
          ),
        ],
      ),
    );
  }
}

// SCREEN 26: Numeracy Activity Detail
class NumeracyActivityDetailScreen extends StatelessWidget {
  final String activityId;

  const NumeracyActivityDetailScreen({super.key, required this.activityId});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Numeracy Activity: Sal Leaf Number Tracing',
      subtitle: 'सखुआ के पत्तों पर संख्याओं की माला व मूर्त गिनती',
      breadcrumb: 'Numeracy > Activity > $activityId',
      isScrollable: true,
      bottomActionBar: PrimaryButton(
        label: 'Start Guided Activity',
        icon: Icons.play_arrow_rounded,
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Math practice activity initiated.')),
          );
        },
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomCard(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Stage: Skills Practice (कौशल अभ्यास)', style: AppTypography.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text('Topic: Numbers up to 100 • 20 mins', style: AppTypography.caption),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const AudioPlayButton(label: 'Audio Cue'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text('Teacher Demonstration Steps:', style: AppTypography.cardTitle),
          const SizedBox(height: 8),
          const Text('1. Distribute 5 large dried sal leaves to each group of two children.\n2. Prompt them to write "10, 20, 30, 40, 50" with white chalk.\n3. Instruct them to place 10 pebbles beside leaf 1, 20 pebbles beside leaf 2.\n4. Ask: "30 में कितने 10 हैं?" Prompt reply in Mundari: "अपिया गेल (Three tens)".'),
        ],
      ),
    );
  }
}

Widget _buildNumeracyCard(
  BuildContext context, {
  required String id,
  required String title,
  required String stage,
  required String time,
  required String desc,
}) {
  return CustomCard(
    onTap: () => context.push('/numeracy/activity/$id'),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: AppColors.greenLight, borderRadius: BorderRadius.circular(12)),
                child: Text(
                  stage,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700),
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
        const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppColors.textMuted),
          ],
        ),
      ],
    ),
  );
}
