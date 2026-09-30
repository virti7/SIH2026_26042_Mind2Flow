import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/chips.dart';
import '../../../../core/widgets/custom_card.dart';
import '../bloc/teach_bloc.dart';

class LocalContextLibraryScreen extends StatefulWidget {
  const LocalContextLibraryScreen({super.key});

  @override
  State<LocalContextLibraryScreen> createState() => _LocalContextLibraryScreenState();
}

class _LocalContextLibraryScreenState extends State<LocalContextLibraryScreen> {
  String _selectedCategory = 'All';

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TeachBloc, TeachState>(
      builder: (context, state) {
        if (state is! TeachLoaded) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final categories = ['All', 'Local Objects', 'Stories', 'Environment', 'Mathematics'];
        final items = _selectedCategory == 'All'
            ? state.localContextItems
            : state.localContextItems.where((i) => i.category == _selectedCategory).toList();

        return AppScaffold(
          title: 'Local Context Library',
          subtitle: 'Verified Jharkhand tribal cultural motifs, stories, and village math analogies.',
          breadcrumb: 'Teach > Local Context',
          isScrollable: true,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Verified Banner
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.greenSurface,
                  borderRadius: AppRadius.radiusMd,
                  border: Border.all(color: AppColors.greenBorder),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.verified_rounded, color: AppColors.primary, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Verified Local Content: Culturally grounded by local Jharkhand language educators.',
                        style: AppTypography.caption.copyWith(color: AppColors.primaryDark, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Category Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: categories.map((cat) {
                    final isSel = _selectedCategory == cat;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(cat),
                        selected: isSel,
                        selectedColor: AppColors.primary,
                        backgroundColor: Colors.white,
                        labelStyle: TextStyle(
                          color: isSel ? Colors.white : AppColors.textPrimary,
                          fontWeight: isSel ? FontWeight.w600 : FontWeight.w500,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: AppRadius.radiusPill,
                          side: BorderSide(
                            color: isSel ? AppColors.primary : AppColors.cardBorder,
                          ),
                        ),
                        onSelected: (val) {
                          if (val) setState(() => _selectedCategory = cat);
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),

              ...items.map((item) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: CustomCard(
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
                              decoration: BoxDecoration(color: AppColors.greenLight, borderRadius: AppRadius.radiusPill),
                              child: Text(item.category, style: AppTypography.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
                            ),
                            LanguageChip(language: item.language),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(item.title, style: AppTypography.cardTitle),
                        Text(item.titleHi, style: AppTypography.devanagariBody.copyWith(color: AppColors.primary)),
                        const SizedBox(height: 6),
                        Text(item.description, style: AppTypography.bodySmall),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: AppColors.surfaceSubtle, borderRadius: AppRadius.radiusMd),
                          child: Row(
                            children: [
                              const Icon(Icons.nature_rounded, size: 16, color: AppColors.textSecondary),
                              const SizedBox(width: 6),
                              Expanded(child: Text(item.tribalTerm, style: AppTypography.tribalVernacular.copyWith(fontSize: 12))),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}
