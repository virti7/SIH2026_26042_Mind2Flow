import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/onboarding_bloc.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/enums/app_enums.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/custom_card.dart';

class ClassroomLanguageSetupScreen extends StatefulWidget {
  const ClassroomLanguageSetupScreen({super.key});

  @override
  State<ClassroomLanguageSetupScreen> createState() => _ClassroomLanguageSetupScreenState();
}

class _ClassroomLanguageSetupScreenState extends State<ClassroomLanguageSetupScreen> {
  final Set<TribalLanguage> _selectedLanguages = {
    TribalLanguage.mundari,
    TribalLanguage.ho,
    TribalLanguage.santali,
  };

  void _onFinish() {
    context.read<OnboardingBloc>().add(CompleteOnboarding());
    context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Classroom Languages',
      subtitle: 'Which mother tongues do your children speak?',
      breadcrumb: 'Screen 3 of 3',
      showSidebarOnTablet: false,
      isScrollable: true,
      bottomActionBar: Row(
        children: [
          SecondaryButton(
            label: 'Back',
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: PrimaryButton(
              label: 'Complete Setup',
              trailingIcon: Icons.check_rounded,
              onPressed: _selectedLanguages.isNotEmpty ? _onFinish : null,
            ),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: List.generate(
              3,
              (i) => Expanded(
                child: Container(
                  height: 6,
                  margin: EdgeInsets.only(right: i < 2 ? 6 : 0),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Informational Banner — white card, green icon
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: AppRadius.radiusMd,
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Multilingual Classroom Router',
                        style: AppTypography.cardTitle.copyWith(fontSize: 14, color: AppColors.primaryDark),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'The single teacher tablet dynamically routes vocabulary, audio, and live translation to match whichever child is speaking or practicing.',
                        style: AppTypography.bodySmall.copyWith(color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          Text('Supported Mother Tongues', style: AppTypography.sectionTitle),
          const SizedBox(height: 12),

          _buildLanguageCard(
            language: TribalLanguage.mundari,
            region: 'Khunti, Ranchi, West Singhbhum',
            description: 'Austroasiatic language with extensive oral storytelling tradition.',
          ),
          const SizedBox(height: 12),

          _buildLanguageCard(
            language: TribalLanguage.ho,
            region: 'West Singhbhum, East Singhbhum, Saraikela',
            description: 'Munda family language with Warang Chiti / Devanagari script support.',
          ),
          const SizedBox(height: 12),

          _buildLanguageCard(
            language: TribalLanguage.santali,
            region: 'Dumka, Santhal Parganas, East Singhbhum',
            description: 'Recognized 8th Schedule language with Ol Chiki / Devanagari support.',
          ),

          const SizedBox(height: 20),

          // Primary Language Confirmation
          CustomCard(
            color: Colors.white,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: AppColors.greenSurface,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Instruction Language: Hindi (हिन्दी)', style: AppTypography.cardTitle),
                      Text('All lesson scripts and teacher guides are provided in Hindi.', style: AppTypography.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageCard({
    required TribalLanguage language,
    required String region,
    required String description,
  }) {
    final isSelected = _selectedLanguages.contains(language);

    return InkWell(
      onTap: () {
        setState(() {
          if (isSelected) {
            if (_selectedLanguages.length > 1) {
              _selectedLanguages.remove(language);
            }
          } else {
            _selectedLanguages.add(language);
          }
        });
      },
      borderRadius: AppRadius.radiusLg,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.greenSurface : Colors.white,
          borderRadius: AppRadius.radiusLg,
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.cardBorder,
            width: isSelected ? 1.8 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: isSelected,
              activeColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              onChanged: (val) {
                setState(() {
                  if (val == true) {
                    _selectedLanguages.add(language);
                  } else if (_selectedLanguages.length > 1) {
                    _selectedLanguages.remove(language);
                  }
                });
              },
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    children: [
                      Text(
                        language.displayName,
                        style: AppTypography.cardTitle.copyWith(fontSize: 17),
                      ),
                      Text(
                        '(${language.hindiName})',
                        style: AppTypography.devanagariHeading.copyWith(
                          color: AppColors.primary,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('Script: ${language.script}', style: AppTypography.caption),
                  const SizedBox(height: 2),
                  Text('Districts: $region', style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
                  const SizedBox(height: 6),
                  Text(description, style: AppTypography.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
