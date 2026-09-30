import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/models/app_models.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/custom_card.dart';
import '../../../home/presentation/bloc/home_bloc.dart';
import '../bloc/teacher_profile_bloc.dart';

class TeacherProfileScreen extends StatelessWidget {
  const TeacherProfileScreen({super.key});

  void _showEditProfileSheet(BuildContext context, TeacherProfile current) {
    final nameController = TextEditingController(text: current.name);
    final schoolController = TextEditingController(text: current.school);
    final districtController = TextEditingController(text: current.district);
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(bottomSheetContext).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Edit Teacher Profile', style: AppTypography.screenTitle.copyWith(fontSize: 18)),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(bottomSheetContext),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text('Teacher Full Name', style: AppTypography.caption),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.person_outline_rounded, color: AppColors.primary),
                        hintText: 'Enter teacher full name',
                      ),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Name cannot be empty' : null,
                    ),
                    const SizedBox(height: 14),
                    Text('School Name', style: AppTypography.caption),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: schoolController,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.school_outlined, color: AppColors.primary),
                        hintText: 'Enter school name',
                      ),
                      validator: (v) => v == null || v.trim().isEmpty ? 'School cannot be empty' : null,
                    ),
                    const SizedBox(height: 14),
                    Text('District', style: AppTypography.caption),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: districtController,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.location_on_outlined, color: AppColors.primary),
                        hintText: 'Enter district',
                      ),
                      validator: (v) => v == null || v.trim().isEmpty ? 'District cannot be empty' : null,
                    ),
                    const SizedBox(height: 24),
                    PrimaryButton(
                      label: 'Save Changes to SQLite',
                      icon: Icons.check_rounded,
                      onPressed: () {
                        if (formKey.currentState?.validate() ?? false) {
                          final updated = current.copyWith(
                            name: nameController.text.trim(),
                            school: schoolController.text.trim(),
                            district: districtController.text.trim(),
                          );
                          context.read<TeacherProfileBloc>().add(UpdateTeacherProfileEvent(updated));
                          Navigator.pop(bottomSheetContext);
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TeacherProfileBloc, TeacherProfileState>(
      listener: (context, state) {
        if (state is TeacherProfileLoaded && state.successMessage != null) {
          context.read<HomeBloc>().add(LoadHomeDashboard());
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.successMessage!),
              backgroundColor: AppColors.primary,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is TeacherProfileLoading || state is TeacherProfileInitial) {
          if (state is TeacherProfileInitial) {
            context.read<TeacherProfileBloc>().add(LoadTeacherProfile());
          }
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
          );
        }

        if (state is TeacherProfileError) {
          return AppScaffold(
            title: 'Teacher Profile',
            subtitle: 'Error loading profile',
            breadcrumb: 'Global Profile',
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(state.message, style: AppTypography.bodyMedium),
                  const SizedBox(height: 12),
                  PrimaryButton(
                    label: 'Retry',
                    onPressed: () => context.read<TeacherProfileBloc>().add(LoadTeacherProfile()),
                  ),
                ],
              ),
            ),
          );
        }

        final p = (state as TeacherProfileLoaded).profile;
        final classesStr = p.classesTaught.map((c) => 'Class $c').join(', ');
        final languagesStr = p.supportedClassroomLanguages.map((l) => l.displayName).join(', ');

        return AppScaffold(
          title: 'Teacher Profile',
          subtitle: 'Classroom profile and persistent MTB-MLE settings.',
          breadcrumb: 'Global Profile',
          isScrollable: true,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Empty state when no teacher profile has been saved yet.
              if (p.name.trim().isEmpty)
                CustomCard(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(9),
                        decoration: const BoxDecoration(
                          color: AppColors.greenSurface,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.person_add_alt_rounded, color: AppColors.primary, size: 22),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Complete your teacher profile to get started',
                                style: AppTypography.cardTitle.copyWith(fontSize: 14)),
                            const SizedBox(height: 2),
                            Text('Your name, school and district stay on this device.',
                                style: AppTypography.caption),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              if (p.name.trim().isEmpty) const SizedBox(height: 16),
              // Profile Card
              CustomCard(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(Icons.person_rounded, size: 36, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Long real-world teacher/school names must truncate
                          // instead of overflowing the Row on narrow phones.
                          Text(
                              p.name.trim().isEmpty ? 'Teacher' : p.name,
                              style: AppTypography.screenTitle.copyWith(fontSize: 18),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 2),
                          Text('Govt. Primary Teacher (PRT)', style: AppTypography.bodySmall.copyWith(color: AppColors.primary)),
                          const SizedBox(height: 4),
                          Text(
                              p.school.trim().isEmpty && p.district.trim().isEmpty
                                  ? 'No school details saved yet'
                                  : '${p.school}, ${p.district}',
                              style: AppTypography.caption,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
                      tooltip: 'Edit Profile Details',
                      onPressed: () => _showEditProfileSheet(context, p),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Teaching Configuration
              CustomCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Classroom & Language Context', style: AppTypography.cardTitle),
                    const SizedBox(height: 14),
                    _buildInfoRow('Teaching Language', '${p.teachingLanguage} (Medium of Instruction)'),
                    const Divider(),
                    _buildInfoRow('Classes Assigned', classesStr),
                    const Divider(),
                    _buildInfoRow('Supported Mother Tongues', languagesStr),
                    const Divider(),
                    _buildInfoRow('Target State', '${p.state} (${p.district})'),
                    const Divider(),
                    _buildInfoRow('Framework Alignment', 'NIPUN Bharat FLN (Class 1–3)'),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Quick Management Actions
              CustomCard(
                child: Column(
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.language_rounded, color: AppColors.primary),
                      title: Text('Edit Classroom Languages', style: AppTypography.bodyMedium),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                      onTap: () async {
                        await context.push(AppRoutes.languageSetup);
                        if (context.mounted) {
                          context.read<TeacherProfileBloc>().add(LoadTeacherProfile());
                        }
                      },
                    ),
                    const Divider(),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.offline_pin_rounded, color: AppColors.primary),
                      title: Text('Offline Status Center', style: AppTypography.bodyMedium),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                      onTap: () => context.push(AppRoutes.offlineStatus),
                    ),
                    const Divider(),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.settings_outlined, color: AppColors.primary),
                      title: Text('App & Audio Settings', style: AppTypography.bodyMedium),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                      onTap: () => context.push(AppRoutes.settings),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                label: 'Edit Profile Details',
                icon: Icons.edit_note_rounded,
                onPressed: () => _showEditProfileSheet(context, p),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Both sides flex so long labels/values shrink instead of
          // overflowing the Row on narrow phones. Visual layout unchanged
          // when content fits (label left, value right).
          Flexible(
            flex: 2,
            child: Text(
              label,
              style: AppTypography.caption,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            flex: 3,
            child: Text(
              value,
              style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.end,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
