import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/models/app_models.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/chips.dart';
import '../../../../core/widgets/custom_card.dart';
import '../bloc/teach_bloc.dart';

class NipunOutcomeSelectorScreen extends StatefulWidget {
  const NipunOutcomeSelectorScreen({super.key});

  @override
  State<NipunOutcomeSelectorScreen> createState() => _NipunOutcomeSelectorScreenState();
}

class _NipunOutcomeSelectorScreenState extends State<NipunOutcomeSelectorScreen> {
  String _selectedDomain = 'All Domains';
  NipunOutcome? _selectedOutcome;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TeachBloc, TeachState>(
      builder: (context, state) {
        if (state is TeachLoaded) {
          final domains = ['All Domains', 'Foundational Numeracy', 'Foundational Literacy'];
          final filtered = _selectedDomain == 'All Domains'
              ? state.outcomes
              : state.outcomes.where((o) => o.domain == _selectedDomain).toList();

          return AppScaffold(
            title: 'NIPUN Outcome Selector',
            subtitle: 'Select specific grade-level target to generate structured lesson plan.',
            breadcrumb: 'Teach > Outcomes',
            isScrollable: true,
            bottomActionBar: PrimaryButton(
              label: 'Open Lesson Planner',
              trailingIcon: Icons.arrow_forward_rounded,
              onPressed: _selectedOutcome != null
                  ? () => context.push(AppRoutes.lessonPlanner)
                  : null,
            ),
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hierarchy Filter
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: domains.map((d) {
                      final isSelected = _selectedDomain == d;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(d),
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
                          onSelected: (val) {
                            if (val) setState(() => _selectedDomain = d);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),

                Text('Available Learning Outcomes (Class ${state.selectedGrade})', style: AppTypography.sectionTitle),
                const SizedBox(height: 10),

                ...filtered.map((outcome) {
                  final isChosen = _selectedOutcome?.id == outcome.id;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      onTap: () => setState(() => _selectedOutcome = outcome),
                      borderRadius: AppRadius.radiusLg,
                      child: CustomCard(
                        color: isChosen ? AppColors.greenSurface : Colors.white,
                        border: BorderSide(
                          color: isChosen ? AppColors.primary : AppColors.cardBorder,
                          width: isChosen ? 1.8 : 1,
                        ),
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
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: AppColors.greenLight,
                                        borderRadius: AppRadius.radiusPill,
                                      ),
                                      child: Text(
                                        outcome.code,
                                        style: AppTypography.caption.copyWith(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    Text(outcome.competency, style: AppTypography.caption),
                                  ],
                                ),
                                StatusChip(status: outcome.defaultStatus),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(outcome.titleEn, style: AppTypography.cardTitle),
                            const SizedBox(height: 2),
                            Text(outcome.titleHi, style: AppTypography.devanagariBody.copyWith(color: AppColors.primary)),
                            const SizedBox(height: 8),
                            Text(outcome.targetDescription, style: AppTypography.bodySmall),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          );
        }

        return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppColors.primary)));
      },
    );
  }
}
