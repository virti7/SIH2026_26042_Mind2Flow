import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/enums/app_enums.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/chips.dart';
import '../../../../core/widgets/custom_card.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../app/di/injection.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/repositories/app_repositories.dart';
import '../../../../core/sync/sync_manager.dart';
import '../../../../core/sync/worksheet_generation_queue.dart';
import '../../../../core/sync/worksheet_generation_sync.dart';
import '../../../resources/presentation/bloc/worksheet_bloc.dart';

// SCREEN 57: Language Pack Manager
class LanguagePackManagerScreen extends StatefulWidget {
  const LanguagePackManagerScreen({super.key});

  @override
  State<LanguagePackManagerScreen> createState() => _LanguagePackManagerScreenState();
}

class _LanguagePackManagerScreenState extends State<LanguagePackManagerScreen> {
  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Language Pack Manager',
      subtitle: 'Ho, Mundari and Santali voice support — available on this device, works offline.',
      breadcrumb: 'Offline > Language Packs',
      isScrollable: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLanguagePackTile(
            title: 'Mundari Pack (मुंडारी बनी)',
            language: TribalLanguage.mundari,
            size: '530 MB',
            version: 'Installed',
            isInstalled: true,
            statusDesc: 'Voice + lessons in Mundari. Available on this device.',
          ),
          const SizedBox(height: 12),
          _buildLanguagePackTile(
            title: 'Ho Pack (वारंग क्षिति)',
            language: TribalLanguage.ho,
            size: '512 MB',
            version: 'Installed',
            isInstalled: true,
            statusDesc: 'Voice + lessons in Ho. Available on this device.',
          ),
          const SizedBox(height: 12),
          _buildLanguagePackTile(
            title: 'Santali Pack (ओल चिकी)',
            language: TribalLanguage.santali,
            size: '545 MB',
            version: 'Installed',
            isInstalled: true,
            statusDesc: 'Voice + lessons in Santali. Available on this device.',
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            label: 'Check for Updates',
            icon: Icons.sync_rounded,
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Checking for updates… Everything on this device is up to date!')),
              );
            },
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildLanguagePackTile({
    required String title,
    required TribalLanguage language,
    required String size,
    required String version,
    required bool isInstalled,
    required String statusDesc,
  }) {
    return CustomCard(
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
                  LanguageChip(language: language, isSelected: true),
                  Text(version, style: AppTypography.caption.copyWith(fontWeight: FontWeight.w700)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: AppColors.greenSurface, borderRadius: AppRadius.radiusPill),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle_rounded, size: 12, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Text('Installed', style: AppTypography.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(title, style: AppTypography.cardTitle.copyWith(fontSize: 15)),
          const SizedBox(height: 2),
          Text(statusDesc, style: AppTypography.bodySmall),
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              Text('Storage: $size', style: AppTypography.caption.copyWith(fontWeight: FontWeight.w600)),
              TextButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Playing sample audio in ${language.displayName}…')),
                  );
                },
                icon: const Icon(Icons.volume_up_rounded, size: 16),
                label: const Text('Test Audio', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// SCREEN 58: Content Pack Manager
class ContentPackManagerScreen extends StatelessWidget {
  const ContentPackManagerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Content Pack Manager',
      subtitle: 'Curriculum resources, worksheets, flashcards and lesson plans for Classes 1 to 5.',
      breadcrumb: 'Offline > Content Packs',
      isScrollable: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildContentTierCard('Class 1 (Balvatika / Grade 1)', 'Full FLN Curriculum, 40 Oral Activities, 25 Worksheets', '240 MB', true),
          const SizedBox(height: 10),
          _buildContentTierCard('Class 2 (Grade 2 - Active Class)', 'All NIPUN Outcomes, 6-Stage Lessons, 40 Worksheets, 60 Flashcards', '320 MB', true),
          const SizedBox(height: 10),
          _buildContentTierCard('Class 3 (Grade 3)', 'Reading Comprehension, Advanced Math, 30 Worksheets', '280 MB', true),
          const SizedBox(height: 10),
          _buildContentTierCard('Class 4 (Grade 4)', 'Environmental Studies & Mathematics', '180 MB', false),
          const SizedBox(height: 10),
          _buildContentTierCard('Class 5 (Grade 5)', 'Advanced MTB-MLE Pedagogy', '195 MB', false),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildContentTierCard(String title, String desc, String size, bool isDownloaded) {
    return CustomCard(
      child: Row(
        children: [
          Icon(
            isDownloaded ? Icons.folder_special_rounded : Icons.cloud_download_outlined,
            color: isDownloaded ? AppColors.primary : AppColors.textMuted,
            size: 32,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.cardTitle.copyWith(fontSize: 14)),
                const SizedBox(height: 2),
                Text(desc, style: AppTypography.caption),
                const SizedBox(height: 4),
                Text('Size: $size', style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Switch(
            value: isDownloaded,
            activeTrackColor: AppColors.primary,
            activeThumbColor: Colors.white,
            onChanged: (val) {},
          ),
        ],
      ),
    );
  }
}

// SCREEN 59: Sync & Updates
class SyncUpdatesScreen extends StatefulWidget {
  const SyncUpdatesScreen({super.key});

  @override
  State<SyncUpdatesScreen> createState() => _SyncUpdatesScreenState();
}

class _SyncUpdatesScreenState extends State<SyncUpdatesScreen> {
  bool _autoSync = true;
  bool _isSyncing = false;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Sync & Updates',
      subtitle: 'Periodic background progress synchronization and curriculum updates.',
      breadcrumb: 'Offline > Sync Center',
      isScrollable: true,
      bottomActionBar: PrimaryButton(
        label: _isSyncing ? 'Syncing Classroom Data...' : 'Sync Now (Upload Records)',
        icon: Icons.sync_rounded,
        isLoading: _isSyncing,
          onPressed: () async {
          setState(() => _isSyncing = true);
          final messenger = ScaffoldMessenger.of(context);
          // Native: unchanged SyncManager path (Drift/SQLite queue).
          if (getIt.isRegistered<SyncManager>()) {
            final syncedCount =
                await getIt<SyncManager>().syncPendingOperations();
            if (mounted) {
              setState(() => _isSyncing = false);
              messenger.showSnackBar(
                SnackBar(
                  content: Text(syncedCount > 0
                      ? 'Sync complete! $syncedCount classroom records uploaded to remote server.'
                      : 'Sync complete. All classroom records are up to date in SQLite.'),
                ),
              );
            }
            return;
          }
          // Web: no SQLite sync queue. Upload pending worksheet-generation
          // requests (SharedPreferences queue) straight to FastAPI.
          await getIt<OfflineRepository>().syncClassroomData();
          WebWorksheetSyncResult? wsResult;
          if (getIt.isRegistered<WebWorksheetSyncAdapter>()) {
            wsResult = await getIt<WebWorksheetSyncAdapter>().syncPending();
          }
          if (!mounted) return;
          setState(() => _isSyncing = false);
          if (wsResult == null || !wsResult.attempted) {
            final waiting = wsResult?.remaining ?? 0;
            messenger.showSnackBar(
              SnackBar(
                content: Text(waiting > 0
                    ? 'Sync paused. Reconnect and tap Sync Now again. $waiting worksheet request(s) still waiting on this device.'
                    : 'Sync complete. Everything is up to date on this device.'),
              ),
            );
            return;
          }
          if (wsResult.completed > 0) {
            // Feed the first completed worksheet into Worksheet Preview,
            // including the full payload so Preview can offer a real Download.
            try {
              final first = wsResult.items.first;
              final payload = {
                ...first.content,
                'content_id':
                    first.content['content_id'] ?? first.contentId,
              };
              final item = worksheetItemFromGenerationPayload(payload);
              if (item.questions.isNotEmpty && mounted) {
                context.read<WorksheetBloc>().add(ShowGeneratedWorksheetEvent(
                      item,
                      contentPayload: payload,
                      contentId: first.contentId,
                    ));
              }
            } catch (_) {
              // Preview mapping must never break the sync confirmation.
            }
            messenger.showSnackBar(
              SnackBar(
                content: Text(
                    'Sync complete! ${wsResult.completed} worksheet(s) generated.'),
                action: SnackBarAction(
                  label: 'View',
                  onPressed: () {
                    if (mounted) context.push(AppRoutes.worksheetPreview);
                  },
                ),
              ),
            );
            return;
          }
          messenger.showSnackBar(
            SnackBar(
              content: Text(wsResult.remaining > 0
                  ? 'Server is currently unavailable. ${wsResult.remaining} worksheet request(s) kept and will retry on the next sync.'
                  : 'Sync complete. Everything is up to date on this device.'),
            ),
          );
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
                  children: [
                    const Icon(Icons.cloud_done_rounded, color: AppColors.primary, size: 24),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Last Synced with District Server', style: AppTypography.caption.copyWith(fontWeight: FontWeight.w700)),
                          Text('Today, 08:30 AM via School Wi-Fi', style: AppTypography.bodySmall),
                        ],
                      ),
                    ),
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
                  title: Text('Automatic Sync', style: AppTypography.cardTitle.copyWith(fontSize: 14)),
                  subtitle: Text('Upload student progress automatically when connected to internet', style: AppTypography.caption),
                  value: _autoSync,
                  activeTrackColor: AppColors.primary,
                  activeThumbColor: Colors.white,
                  onChanged: (val) => setState(() => _autoSync = val),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          SectionHeader(title: 'Pending Sync Queue', titleHindi: 'लंबित रिकॉर्ड्स'),
          const SizedBox(height: 8),
          StreamBuilder<List<SyncQueueData>>(
            // Web demo: no AppDatabase registered, show empty queue.
            stream: getIt.isRegistered<AppDatabase>()
                ? getIt<AppDatabase>().syncQueueDao.watchAllQueueItems()
                : Stream<List<SyncQueueData>>.value(const []),
            builder: (context, snapshot) {
              final items = snapshot.data ?? [];
              if (items.isEmpty) {
                return CustomCard(
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'All classroom records are synchronized with the district server.',
                          style: AppTypography.bodySmall,
                        ),
                      ),
                    ],
                  ),
                );
              }
              return Column(
                children: items.map((item) {
                  final icon = item.entityType == 'assessment_result'
                      ? Icons.assignment_rounded
                      : (item.entityType == 'teacher'
                          ? Icons.person_rounded
                          : (item.entityType == 'saved_material'
                              ? Icons.bookmark_rounded
                              : Icons.sync_rounded));
                  final isPending = item.status == 'PENDING';
                  final isFailed = item.status == 'FAILED';
                  final badgeColor = isPending
                      ? AppColors.accentOrange
                      : (isFailed ? AppColors.accentRed : AppColors.primary);
                  final badgeBg = isPending
                      ? AppColors.accentOrangeLight
                      : (isFailed ? AppColors.accentRedLight : AppColors.greenSurface);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: CustomCard(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Icon(icon, color: AppColors.primary, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${item.operation.toUpperCase()}: ${item.entityType} (${item.entityId.length > 8 ? item.entityId.substring(0, 8) : item.entityId})',
                                  style: AppTypography.cardTitle.copyWith(fontSize: 13),
                                ),
                                Text(
                                  'Recorded ${item.createdAt.toLocal().toString().substring(0, 16)}${item.retryCount > 0 ? " • Retries: ${item.retryCount}" : ""}',
                                  style: AppTypography.caption,
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: badgeBg, borderRadius: AppRadius.radiusPill),
                            child: Text(
                              item.status,
                              style: TextStyle(color: badgeColor, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// SCREEN 60: Offline Storage
class OfflineStorageScreen extends StatelessWidget {
  const OfflineStorageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Offline Storage Breakdown',
      subtitle: 'Visible local disk allocation for low-cost Android classroom tablets.',
      breadcrumb: 'Offline > Storage',
      isScrollable: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Storage Overview Gauge
          CustomCard(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text('Total Tablet Storage', style: AppTypography.cardTitle, overflow: TextOverflow.ellipsis),
                    ),
                    const SizedBox(width: 8),
                    Text('4.2 GB of 32 GB Used', style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold, color: AppColors.primary)),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: AppRadius.radiusPill,
                  child: LinearProgressIndicator(
                    value: 4.2 / 32.0,
                    minHeight: 12,
                    backgroundColor: AppColors.cardBorder,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 6),
                Text('27.8 GB Free Space Available', style: AppTypography.caption),
              ],
            ),
          ),
          const SizedBox(height: 16),

          SectionHeader(title: 'Storage Allocation by Category', titleHindi: 'श्रेणी अनुसार संग्रहण'),
          const SizedBox(height: 8),
          _buildStorageTile('Classroom Audio', 'Ho, Mundari and Santali voices on this device', 'Downloaded', Icons.record_voice_over_rounded, AppColors.accentBlue),
          const SizedBox(height: 8),
          _buildStorageTile('Worksheets & Picture Cards', 'Lesson plans, worksheets and flashcards', 'Downloaded', Icons.description_rounded, AppColors.accentOrange),
          const SizedBox(height: 8),
          _buildStorageTile('Teaching Records', 'Your lessons and assessments, kept on this device', 'On this device', Icons.storage_rounded, AppColors.statusAchieved),
          const SizedBox(height: 24),

          Center(
            child: OutlinedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Extra space freed up. Your lessons and audio are untouched.')),
                );
              },
              icon: const Icon(Icons.cleaning_services_rounded, size: 18),
              label: const Text('Free Up Space'),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildStorageTile(String title, String subtitle, String size, IconData icon, Color color) {
    return CustomCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.cardTitle.copyWith(fontSize: 14)),
                Text(subtitle, style: AppTypography.caption),
              ],
            ),
          ),
          Text(size, style: AppTypography.cardTitle.copyWith(fontSize: 14, color: AppColors.primary)),
        ],
      ),
    );
  }
}
