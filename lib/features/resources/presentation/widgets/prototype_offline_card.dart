import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/content/prototype_local_content_data_source.dart';
import '../../../../core/content/prototype_manifests.dart';
import '../../../../core/widgets/custom_card.dart';
import '../bloc/worksheet_bloc.dart';

/// Offline prototype banner wired into the existing worksheet flow.
///
/// * Reads ONLY bundled manifests via [PrototypeLocalContentDataSource]
///   (no FastAPI / Supabase / network).
/// * On tap, converts the manifest into the EXISTING `WorksheetItem` model
///   and shows it with the EXISTING preview screen
///   (`ShowGeneratedWorksheetEvent` → `WorksheetPreviewScreen`), so Save /
///   Download / Downloads keep working offline through the existing stores.
/// * Shows an honest empty state until the teacher adds files — never
///   fabricates questions or PDFs.
class PrototypeOfflineCard extends StatelessWidget {
  final String className;
  final String subject;
  final String topic;
  final PrototypeLocalContentDataSource? dataSource;

  const PrototypeOfflineCard({
    super.key,
    required this.className,
    required this.subject,
    required this.topic,
    this.dataSource,
  });

  PrototypeLocalContentDataSource get _ds =>
      dataSource ?? PrototypeLocalContentDataSource();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<PrototypeWorksheetManifest>>(
      future: _ds.getPrototypeWorksheets(),
      builder: (context, snapshot) {
        final manifests = snapshot.data ?? const [];
        return CustomCard(
          color: AppColors.greenSurface,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.offline_pin_rounded,
                  color: AppColors.primary, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Offline prototype content',
                      style: AppTypography.cardTitle
                          .copyWith(fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      manifests.isEmpty
                          ? 'No bundled worksheet yet for $className • $subject • $topic. Add the PDF + manifest under assets/prototype_content (see README). No internet required.'
                          : '${manifests.length} bundled worksheet${manifests.length == 1 ? '' : 's'} available offline — no internet required.',
                      style: AppTypography.caption,
                      softWrap: true,
                    ),
                    if (manifests.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final m in manifests.take(3))
                            _PrototypeOpenButton(
                              manifest: m,
                              dataSource: _ds,
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PrototypeOpenButton extends StatelessWidget {
  final PrototypeWorksheetManifest manifest;
  final PrototypeLocalContentDataSource dataSource;

  const _PrototypeOpenButton({
    required this.manifest,
    required this.dataSource,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonal(
      style: FilledButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primary,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.radiusPill,
          side: const BorderSide(color: AppColors.primary),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      onPressed: () {
        final item = dataSource.worksheetItemFromManifest(manifest);
        final payload =
            dataSource.downloadPayloadForWorksheet(manifest);
        context.read<WorksheetBloc>().add(
              ShowGeneratedWorksheetEvent(
                item,
                contentPayload: payload,
                contentId: manifest.id,
              ),
            );
        context.push(AppRoutes.worksheetPreview);
      },
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 220),
        child: Text(
          'View ${manifest.title}',
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ),
    );
  }
}
