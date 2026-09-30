import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/onboarding_bloc.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/custom_card.dart';
import '../../../../features/profile/presentation/bloc/teacher_profile_bloc.dart';

class TeacherProfileSetupScreen extends StatefulWidget {
  /// When true, this screen completes a missing name/school for an already
  /// authenticated teacher (existing account): saving refreshes the global
  /// profile state and returns Home instead of continuing onboarding.
  final bool isCompletion;

  const TeacherProfileSetupScreen({super.key, this.isCompletion = false});

  @override
  State<TeacherProfileSetupScreen> createState() => _TeacherProfileSetupScreenState();
}

class _TeacherProfileSetupScreenState extends State<TeacherProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  // New profiles always start empty; saved profiles are loaded dynamically
  // by the onboarding flow instead of prefilling a fictional teacher.
  final _nameController = TextEditingController();
  final _schoolController = TextEditingController();
  final _districtController = TextEditingController();
  final List<int> _selectedClasses = [1, 2, 3];
  final String _teachingLanguage = AppConstants.defaultTeachingLanguage;

  @override
  void dispose() {
    _nameController.dispose();
    _schoolController.dispose();
    _districtController.dispose();
    super.dispose();
  }

  void _onNext() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<OnboardingBloc>().add(UpdateTeacherDetails(
            name: _nameController.text.trim(),
            school: _schoolController.text.trim(),
            district: _districtController.text.trim(),
            classes: _selectedClasses,
            teachingLanguage: _teachingLanguage,
          ));
      if (widget.isCompletion) {
        // Existing account completing a missing name/school: refresh the
        // central profile state (headers update immediately) and go Home.
        // The local save above also queues a sync so the backend profile is
        // reconciled with the school name on the next login/sync.
        context.read<TeacherProfileBloc>().add(LoadTeacherProfile());
        context.go(AppRoutes.home);
        return;
      }
      context.push(AppRoutes.languageSetup);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: widget.isCompletion
          ? 'Complete Your Profile'
          : 'Teacher Profile Setup',
      subtitle: widget.isCompletion
          ? 'Add your name and school to finish setting up your account.'
          : 'Tell us about yourself so lessons feel personal.',
      breadcrumb: widget.isCompletion ? 'Profile' : 'Screen 1 of 3',
      showSidebarOnTablet: false,
      isScrollable: true,
      bottomActionBar: PrimaryButton(
        label: widget.isCompletion ? 'Save & Continue' : 'Next',
        trailingIcon: Icons.arrow_forward_rounded,
        onPressed: _onNext,
      ),
      body: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStepDots(0),
            const SizedBox(height: 16),
            // Teacher photo + welcome — white card, green avatar wash
            CustomCard(
              child: Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.greenLight,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.greenBorder, width: 1.5),
                    ),
                    child: const Icon(Icons.person_rounded, color: AppColors.primary, size: 34),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Namaste, Teacher 🙏', style: AppTypography.cardTitle.copyWith(fontSize: 16)),
                        const SizedBox(height: 2),
                        Text(
                          'Add your photo and details. Your classroom tablet stays personal to you.',
                          style: AppTypography.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            CustomCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Primary Teacher Details', style: AppTypography.cardTitle),
                  const SizedBox(height: 16),
                  Text('Teacher Full Name (शिक्षक का नाम)', style: AppTypography.caption),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.person_outline_rounded, color: AppColors.primary),
                      hintText: 'Enter your full name',
                    ),
                    validator: (val) => val == null || val.isEmpty ? 'Please enter teacher name' : null,
                  ),
                  const SizedBox(height: 16),
                  Text('School Name (विद्यालय का नाम)', style: AppTypography.caption),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _schoolController,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.school_outlined, color: AppColors.primary),
                      hintText: 'e.g. Govt. Primary School, Torpa',
                    ),
                    validator: (val) => val == null || val.isEmpty ? 'Please enter school name' : null,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('District (ज़िला)', style: AppTypography.caption),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _districtController,
                              decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.location_on_outlined, color: AppColors.primary),
                                hintText: 'Enter district',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('State', style: AppTypography.caption),
                            const SizedBox(height: 6),
                            TextFormField(
                              initialValue: 'Jharkhand',
                              enabled: false,
                              decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.map_outlined, color: AppColors.textMuted),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Classes Taught
            CustomCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Classes You Teach', style: AppTypography.cardTitle),
                  const SizedBox(height: 6),
                  Text(
                    'Pick one or more. You can change this later.',
                    style: AppTypography.bodySmall,
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [1, 2, 3, 4, 5].map((grade) {
                      final isSelected = _selectedClasses.contains(grade);
                      return FilterChip(
                        selected: isSelected,
                        label: Text('Class $grade'),
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : AppColors.navy,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        ),
                        selectedColor: AppColors.primary,
                        backgroundColor: Colors.white,
                        checkmarkColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: AppRadius.radiusPill,
                          side: BorderSide(
                            color: isSelected ? AppColors.primary : AppColors.cardBorder,
                          ),
                        ),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedClasses.add(grade);
                            } else {
                              if (_selectedClasses.length > 1) {
                                _selectedClasses.remove(grade);
                              }
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: AppColors.greenSurface,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.language_rounded, size: 20, color: AppColors.primary),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Teaching language: Hindi', style: AppTypography.cardTitleSmall),
                            Text('Medium of instruction for all guides', style: AppTypography.bodySmall),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepDots(int active) {
    return Row(
      children: List.generate(
        3,
        (i) => Expanded(
          child: Container(
            height: 6,
            margin: EdgeInsets.only(right: i < 2 ? 6 : 0),
            decoration: BoxDecoration(
              color: i <= active ? AppColors.primary : AppColors.cardBorder,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),
      ),
    );
  }
}
