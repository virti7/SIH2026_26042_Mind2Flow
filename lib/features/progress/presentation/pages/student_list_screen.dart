import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/enums/app_enums.dart';
import '../../../../core/models/app_models.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/chips.dart';
import '../../../../core/widgets/custom_card.dart';
import '../bloc/progress_bloc.dart';

// SCREEN 50: Student List (Individual Learner Roster)
class StudentListScreen extends StatefulWidget {
  const StudentListScreen({super.key});

  @override
  State<StudentListScreen> createState() => _StudentListScreenState();
}

class _StudentListScreenState extends State<StudentListScreen> {
  String _searchQuery = '';
  TribalLanguage? _selectedLanguageFilter;
  bool _filterNeedsSupport = false;

  @override
  void initState() {
    super.initState();
    // Roster is loaded explicitly here so the teacher dashboard
    // never has to query student data.
    context.read<ProgressBloc>().add(LoadStudentRoster());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProgressBloc, ProgressState>(
      builder: (context, state) {
        List<StudentRecord> students = [];
        if (state is StudentRosterLoaded) {
          students = state.students;
        } else if (state is StudentDetailLoaded) {
          students = state.allStudents;
        }

        // Apply filters and search
        final filteredStudents = students.where((s) {
          if (_searchQuery.isNotEmpty) {
            final q = _searchQuery.toLowerCase();
            final matchesName = s.name.toLowerCase().contains(q);
            final matchesRoll = s.rollNumber.toString().contains(q);
            if (!matchesName && !matchesRoll) return false;
          }
          if (_selectedLanguageFilter != null && s.motherTongue != _selectedLanguageFilter) {
            return false;
          }
          if (_filterNeedsSupport && s.needsSupportOutcomes == 0) {
            return false;
          }
          return true;
        }).toList();

        return AppScaffold(
          title: 'Class 2 Learner Roster',
          subtitle: 'Individual learner portfolio directory. Select any student for outcome tracking and remediation.',
          breadcrumb: 'Progress > Student Directory',
          isScrollable: true,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search Field
              TextField(
                decoration: InputDecoration(
                  hintText: 'Search by student name or roll number...',
                  prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: () => setState(() => _searchQuery = ''),
                        )
                      : null,
                ),
                onChanged: (val) => setState(() => _searchQuery = val.trim()),
              ),
              const SizedBox(height: 12),

              // Filter Chips Row
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    FilterChip(
                      label: const Text('All Languages'),
                      selected: _selectedLanguageFilter == null,
                      onSelected: (_) => setState(() => _selectedLanguageFilter = null),
                      selectedColor: AppColors.greenSurface,
                      checkmarkColor: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Mundari'),
                      selected: _selectedLanguageFilter == TribalLanguage.mundari,
                      onSelected: (val) => setState(() => _selectedLanguageFilter = val ? TribalLanguage.mundari : null),
                      selectedColor: AppColors.greenSurface,
                      checkmarkColor: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Ho'),
                      selected: _selectedLanguageFilter == TribalLanguage.ho,
                      onSelected: (val) => setState(() => _selectedLanguageFilter = val ? TribalLanguage.ho : null),
                      selectedColor: AppColors.greenSurface,
                      checkmarkColor: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Santali'),
                      selected: _selectedLanguageFilter == TribalLanguage.santali,
                      onSelected: (val) => setState(() => _selectedLanguageFilter = val ? TribalLanguage.santali : null),
                      selectedColor: AppColors.greenSurface,
                      checkmarkColor: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Needs Support ⚠️'),
                      selected: _filterNeedsSupport,
                      onSelected: (val) => setState(() => _filterNeedsSupport = val),
                      selectedColor: AppColors.statusNeedsSupportBg,
                      checkmarkColor: AppColors.statusNeedsSupport,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              Text('${filteredStudents.length} Individual Learners Listed', style: AppTypography.caption.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),

              if (filteredStudents.isEmpty)
                CustomCard(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(Icons.search_off_rounded, size: 36, color: AppColors.textMuted),
                        const SizedBox(height: 8),
                        Text('No students match current filter', style: AppTypography.cardTitle),
                        const SizedBox(height: 4),
                        Text('Try clearing the search or language filter.', style: AppTypography.caption),
                      ],
                    ),
                  ),
                )
              else
                ...filteredStudents.map((student) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: CustomCard(
                      onTap: () {
                        context.read<ProgressBloc>().add(SelectStudentForDetails(student.id));
                        context.push(AppRoutes.studentProfile.replaceAll(':id', student.id));
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: AppColors.greenSurface,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppColors.greenBorder),
                                ),
                                child: Center(
                                  child: Text(
                                    student.name.isNotEmpty ? student.name[0] : '?',
                                    style: AppTypography.cardTitle.copyWith(color: AppColors.primary, fontSize: 18),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            student.name,
                                            style: AppTypography.cardTitle.copyWith(fontSize: 15),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text('Roll ${student.rollNumber}', style: AppTypography.caption),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 4,
                                      children: [
                                        LanguageChip(language: student.motherTongue),
                                        if (student.needsSupportOutcomes > 0)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(color: AppColors.statusNeedsSupportBg, borderRadius: AppRadius.radiusPill),
                                            child: Text('Active Gap', style: AppTypography.caption.copyWith(color: AppColors.statusNeedsSupport, fontSize: 10, fontWeight: FontWeight.w700)),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textMuted),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              _buildPill('${student.achievedOutcomes} Achieved', AppColors.statusAchievedBg, AppColors.statusAchieved),
                              _buildPill('${student.developingOutcomes} Developing', AppColors.statusDevelopingBg, AppColors.statusDeveloping),
                              _buildPill('${student.needsSupportOutcomes} Needs Help', AppColors.statusNeedsSupportBg, AppColors.statusNeedsSupport),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPill(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: AppRadius.radiusPill),
      child: Text(text, style: TextStyle(color: fg, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}
