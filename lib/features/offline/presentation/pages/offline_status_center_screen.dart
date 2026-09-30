import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/enums/app_enums.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/chips.dart';
import '../../../../core/widgets/custom_card.dart';
import '../bloc/offline_bloc.dart';

class OfflineStatusCenterScreen extends StatelessWidget {
  const OfflineStatusCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OfflineBloc, OfflineState>(
      builder: (context, state) {
        if (state is OfflineLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
          );
        }

        if (state is OfflineDataLoaded) {
          return AppScaffold(
            title: 'Offline Status Center',
            subtitle: 'Device readiness, installed language packs, and local offline storage.',
            breadcrumb: 'Device Readiness',
            isScrollable: true,
            bottomActionBar: PrimaryButton(
              label: state.syncStatus == SyncStatusState.syncing ? 'Syncing Classroom Data...' : 'Sync When Online',
              icon: Icons.sync_rounded,
              isLoading: state.syncStatus == SyncStatusState.syncing,
              onPressed: () {
                context.read<OfflineBloc>().add(TriggerManualSyncEvent());
              },
            ),
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Trust Banner — white card, green icon wash
                CustomCard(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: const BoxDecoration(
                          color: AppColors.greenLight,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.verified_user_rounded, color: AppColors.primary, size: 28),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Tablet 100% Offline Ready', style: AppTypography.cardTitle),
                            const SizedBox(height: 2),
                            Text(
                              'Lessons, stories, worksheets and classroom audio all work on this device — no internet needed.',
                              style: AppTypography.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Sync & Local Database Status
                CustomCard(
                  child: Row(
                    children: [
                      Icon(
                        state.pendingSyncCount > 0 ? Icons.cloud_upload_outlined : Icons.cloud_done_rounded,
                        color: state.pendingSyncCount > 0 ? AppColors.accentOrange : AppColors.primary,
                        size: 24,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              state.pendingSyncCount > 0
                                  ? '${state.pendingSyncCount} Pending Sync Operations'
                                  : 'All Classroom Data Synchronized',
                              style: AppTypography.cardTitle.copyWith(fontSize: 14),
                            ),
                            Text(
                              state.pendingSyncCount > 0
                                  ? 'Stored safely in local SQLite. Will sync when online.'
                                  : 'Local SQLite database is up to date.',
                              style: AppTypography.caption,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: state.pendingSyncCount > 0 ? AppColors.accentOrangeLight : AppColors.greenSurface,
                          borderRadius: AppRadius.radiusPill,
                        ),
                        child: Text(
                          state.syncStatus == SyncStatusState.syncing
                              ? 'Syncing...'
                              : (state.pendingSyncCount > 0 ? 'Pending (${state.pendingSyncCount})' : 'Synced'),
                          style: TextStyle(
                            color: state.pendingSyncCount > 0 ? AppColors.accentOrange : AppColors.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Installed Language Packs
                Text('Classroom Languages on This Device', style: AppTypography.sectionTitle),
                const SizedBox(height: 8),
                ...state.languagePacks.map((pack) {
                  final isInstalled = pack.status == PackStatus.installed;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: CustomCard(
                      child: Row(
                        children: [
                          Icon(
                            isInstalled ? Icons.check_circle_rounded : Icons.cloud_download_outlined,
                            color: isInstalled ? AppColors.primary : AppColors.accentBlue,
                            size: 26,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${pack.language.displayName} (${pack.language.hindiName})', style: AppTypography.cardTitle),
                                Text('Installed • Available on this device', style: AppTypography.caption),
                              ],
                            ),
                          ),
                          if (isInstalled)
                            const StatusChip(status: OutcomeStatus.achieved)
                          else if (pack.status == PackStatus.downloading)
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                            )
                          else
                            TextButton(
                              onPressed: () {
                                context.read<OfflineBloc>().add(InstallLanguagePackEvent(pack.id));
                              },
                              child: const Text('Install'),
                            ),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 16),

                // Tablet Storage Breakdown
                Text('Classroom Tablet Storage Breakdown', style: AppTypography.sectionTitle),
                const SizedBox(height: 8),
                CustomCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Storage: ${(state.usedStorageMb / 1024).toStringAsFixed(1)} GB / 32 GB',
                              style: AppTypography.cardTitle.copyWith(fontSize: 14),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('${(state.freeStorageMb / 1024).toStringAsFixed(1)} GB Free', style: AppTypography.caption.copyWith(color: AppColors.primary)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: AppRadius.radiusPill,
                        child: LinearProgressIndicator(
                          value: state.usedStorageMb / state.totalStorageMb,
                          minHeight: 10,
                          backgroundColor: AppColors.cardBorder,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildStorageRow('Lessons & Stories', 'Available offline', AppColors.primary),
                      _buildStorageRow('Classroom Audio', 'Available offline', AppColors.accentBlue),
                      _buildStorageRow('Worksheets & Cards', 'Available offline', AppColors.accentAmber),
                      _buildStorageRow('Teaching Records', 'On this device', AppColors.accentOrange),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        }

        return const Scaffold(body: SizedBox.shrink());
      },
    );
  }

  Widget _buildStorageRow(String label, String size, Color dotColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: AppTypography.bodySmall)),
          Text(size, style: AppTypography.caption.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
