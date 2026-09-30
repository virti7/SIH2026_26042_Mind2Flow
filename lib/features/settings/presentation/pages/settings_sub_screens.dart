import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/enums/app_enums.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/chips.dart';
import '../../../../core/widgets/custom_card.dart';
import '../../../../core/widgets/section_header.dart';

// SCREEN 61: Language Settings
class LanguageSettingsScreen extends StatefulWidget {
  const LanguageSettingsScreen({super.key});

  @override
  State<LanguageSettingsScreen> createState() => _LanguageSettingsScreenState();
}

class _LanguageSettingsScreenState extends State<LanguageSettingsScreen> {
  String _interfaceLanguage = 'Hindi';
  bool _enableHo = true;
  bool _enableMundari = true;
  bool _enableSantali = true;
  String _scriptPreference = 'Devanagari Transliteration + Native Script';

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Language Settings',
      subtitle: 'Configure teacher interface language and classroom tribal language routing.',
      breadcrumb: 'Settings > Languages',
      isScrollable: true,
      bottomActionBar: PrimaryButton(
        label: 'Save Preferences',
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Language settings saved successfully.')),
          );
          context.pop();
        },
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: 'Teacher Interface Language', titleHindi: 'ऐप भाषा'),
          const SizedBox(height: 8),
          CustomCard(
            child: RadioGroup<String>(
              groupValue: _interfaceLanguage,
              onChanged: (val) {
                if (val != null) setState(() => _interfaceLanguage = val);
              },
              child: const Column(
                children: [
                  RadioListTile<String>(
                    title: Text('Hindi (हिंदी) - Recommended for Jharkhand'),
                    subtitle: Text('All system menus and teacher instructions in Hindi'),
                    value: 'Hindi',
                    activeColor: AppColors.primary,
                  ),
                  Divider(),
                  RadioListTile<String>(
                    title: Text('English'),
                    subtitle: Text('Menus in English with Hindi teaching scaffolds'),
                    value: 'English',
                    activeColor: AppColors.primary,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          SectionHeader(title: 'Active Classroom Tribal Languages', titleHindi: 'सक्रिय जनजातीय भाषाएं'),
          const SizedBox(height: 8),
          CustomCard(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Mundari (मुंडारी)'),
                  subtitle: const Text('Mundari Bani & Devanagari Unicode support'),
                  value: _enableMundari,
                  activeTrackColor: AppColors.primary,
                  activeThumbColor: Colors.white,
                  onChanged: (val) => setState(() => _enableMundari = val),
                ),
                const Divider(),
                SwitchListTile(
                  title: const Text('Ho (हो)'),
                  subtitle: const Text('Warang Chiti & Devanagari Unicode support'),
                  value: _enableHo,
                  activeTrackColor: AppColors.primary,
                  activeThumbColor: Colors.white,
                  onChanged: (val) => setState(() => _enableHo = val),
                ),
                const Divider(),
                SwitchListTile(
                  title: const Text('Santali (संताली)'),
                  subtitle: const Text('Ol Chiki & Devanagari Unicode support'),
                  value: _enableSantali,
                  activeTrackColor: AppColors.primary,
                  activeThumbColor: Colors.white,
                  onChanged: (val) => setState(() => _enableSantali = val),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          SectionHeader(title: 'Script Display Preference', titleHindi: 'लिपि प्राथमिकता'),
          const SizedBox(height: 8),
          CustomCard(
            child: DropdownButtonFormField<String>(
              initialValue: _scriptPreference,
              decoration: const InputDecoration(border: InputBorder.none),
              isExpanded: true,
              items: const [
                DropdownMenuItem(value: 'Devanagari Transliteration + Native Script', child: Text('Dual: Devanagari + Native Script', overflow: TextOverflow.ellipsis)),
                DropdownMenuItem(value: 'Devanagari Only', child: Text('Devanagari Only (देवनागरी)', overflow: TextOverflow.ellipsis)),
                DropdownMenuItem(value: 'Native Script Only', child: Text('Native Script Only (Ol Chiki / Warang Chiti)', overflow: TextOverflow.ellipsis)),
              ],
              onChanged: (val) => setState(() => _scriptPreference = val!),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// SCREEN 62: Audio Settings
class AudioSettingsScreen extends StatefulWidget {
  const AudioSettingsScreen({super.key});

  @override
  State<AudioSettingsScreen> createState() => _AudioSettingsScreenState();
}

class _AudioSettingsScreenState extends State<AudioSettingsScreen> {
  double _speechRate = 1.0;
  bool _speakerBoost = true;
  String _voiceGender = 'Female Native (महिला स्वर)';

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Audio & Speech Settings',
      subtitle: 'Classroom acoustic reliability, speech rate, and synthesized voice outputs.',
      breadcrumb: 'Settings > Audio',
      isScrollable: true,
      bottomActionBar: PrimaryButton(
        label: 'Save Audio Settings',
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Audio configuration updated.')),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text('Speech Rate (बोलने की गति):', style: AppTypography.cardTitle.copyWith(fontSize: 14), overflow: TextOverflow.ellipsis),
                    ),
                    const SizedBox(width: 8),
                    Text('${_speechRate.toStringAsFixed(2)}x', style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold, color: AppColors.primary)),
                  ],
                ),
                const SizedBox(height: 8),
                Slider(
                  value: _speechRate,
                  min: 0.75,
                  max: 1.25,
                  divisions: 4,
                  activeColor: AppColors.primary,
                  onChanged: (val) => setState(() => _speechRate = val),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(child: Text('0.75x (Slow)', style: AppTypography.caption, overflow: TextOverflow.ellipsis)),
                    Flexible(child: Text('1.0x (Standard)', style: AppTypography.caption, overflow: TextOverflow.ellipsis)),
                    Flexible(child: Text('1.25x (Fast)', style: AppTypography.caption, overflow: TextOverflow.ellipsis)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          CustomCard(
            child: Column(
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Classroom Speaker Boost', style: AppTypography.cardTitle.copyWith(fontSize: 14)),
                  subtitle: Text('Compresses dynamic range so children in the back row hear clearly', style: AppTypography.caption),
                  value: _speakerBoost,
                  activeTrackColor: AppColors.primary,
                  activeThumbColor: Colors.white,
                  onChanged: (val) => setState(() => _speakerBoost = val),
                ),
                const Divider(),
                const SizedBox(height: 6),
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Text('Classroom Voice:', style: AppTypography.bodySmall),
                    DropdownButton<String>(
                      value: _voiceGender,
                      underline: const SizedBox(),
                      items: const [
                        DropdownMenuItem(value: 'Female Native (महिला स्वर)', child: Text('Female Native')),
                        DropdownMenuItem(value: 'Male Native (पुरुष स्वर)', child: Text('Male Native')),
                      ],
                      onChanged: (val) => setState(() => _voiceGender = val!),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          PrimaryButton(
            label: 'Test Classroom Audio Speaker',
            icon: Icons.volume_up_rounded,
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Playing high-clarity test pronunciation: "नेया मियाद सेब ताना।"')),
              );
            },
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// SCREEN 63: Classroom Settings
class ClassroomSettingsScreen extends StatefulWidget {
  const ClassroomSettingsScreen({super.key});

  @override
  State<ClassroomSettingsScreen> createState() => _ClassroomSettingsScreenState();
}

class _ClassroomSettingsScreenState extends State<ClassroomSettingsScreen> {
  int _selectedGrade = 2;
  TribalLanguage _defaultTargetLanguage = TribalLanguage.mundari;
  String _academicTerm = 'Term 2 (अक्टूबर - मार्च)';

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Classroom Settings',
      subtitle: 'Manage active grade level, term schedule, and default live translation language.',
      breadcrumb: 'Settings > Classroom',
      isScrollable: true,
      bottomActionBar: PrimaryButton(
        label: 'Save Classroom Context',
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Classroom configuration updated.')),
          );
          context.pop();
        },
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: 'Active Teaching Grade', titleHindi: 'सक्रिय कक्षा'),
          const SizedBox(height: 8),
          CustomCard(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.spaceAround,
              children: [1, 2, 3, 4, 5].map((g) {
                final isSel = _selectedGrade == g;
                return InkWell(
                  onTap: () => setState(() => _selectedGrade = g),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSel ? AppColors.primary : AppColors.surface,
                      borderRadius: AppRadius.radiusPill,
                      border: Border.all(color: isSel ? AppColors.primary : AppColors.cardBorder),
                    ),
                    child: Text(
                      'Class $g',
                      style: TextStyle(color: isSel ? Colors.white : AppColors.textPrimary, fontWeight: FontWeight.bold),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          SectionHeader(title: 'Default Live Translation Target', titleHindi: 'प्राथमिक अनुवाद भाषा'),
          const SizedBox(height: 8),
          CustomCard(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                LanguageChip(
                  language: TribalLanguage.mundari,
                  isSelected: _defaultTargetLanguage == TribalLanguage.mundari,
                  onTap: () => setState(() => _defaultTargetLanguage = TribalLanguage.mundari),
                ),
                LanguageChip(
                  language: TribalLanguage.ho,
                  isSelected: _defaultTargetLanguage == TribalLanguage.ho,
                  onTap: () => setState(() => _defaultTargetLanguage = TribalLanguage.ho),
                ),
                LanguageChip(
                  language: TribalLanguage.santali,
                  isSelected: _defaultTargetLanguage == TribalLanguage.santali,
                  onTap: () => setState(() => _defaultTargetLanguage = TribalLanguage.santali),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          SectionHeader(title: 'Academic Term & Schedule', titleHindi: 'शैक्षणिक सत्र'),
          const SizedBox(height: 8),
          CustomCard(
            child: DropdownButtonFormField<String>(
              initialValue: _academicTerm,
              decoration: const InputDecoration(border: InputBorder.none),
              isExpanded: true,
              items: const [
                DropdownMenuItem(value: 'Term 1 (अप्रैल - सितम्बर)', child: Text('Term 1 (अप्रैल - सितम्बर)', overflow: TextOverflow.ellipsis)),
                DropdownMenuItem(value: 'Term 2 (अक्टूबर - मार्च)', child: Text('Term 2 (अक्टूबर - मार्च)', overflow: TextOverflow.ellipsis)),
                DropdownMenuItem(value: 'Annual Examination Period', child: Text('Annual Examination Period', overflow: TextOverflow.ellipsis)),
              ],
              onChanged: (val) => setState(() => _academicTerm = val!),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
