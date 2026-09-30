import '../enums/app_enums.dart';
import '../models/app_models.dart';
import '../repositories/app_repositories.dart';
import 'prototype_local_content_data_source.dart';
import 'prototype_manifests.dart';

/// Offline prototype path that sits BESIDE the production remote path:
///
/// ```text
/// ContentRepository
///       |
///       +-- RemoteContentDataSource   (FastAPI / Sarvam — untouched)
///       |
///       +-- PrototypeLocalContentDataSource (bundled assets — this demo)
/// ```
///
/// The demo UI reads the catalog through this repository; saving and
/// downloading still go through the EXISTING [ResourceRepository] /
/// `WorksheetDownloadStore` so account isolation, Drift, SavedMaterials,
/// and Downloads keep working unchanged.
///
/// * Catalog (manifests) = SHARED curriculum content.
/// * Download records / saved state / progress = account-specific
///   (resolved downstream by `CurrentUserService` owner id).
class PrototypeContentRepository {
  final PrototypeLocalContentDataSource local;
  final ResourceRepository resources;

  const PrototypeContentRepository({
    required this.local,
    required this.resources,
  });

  Future<List<PrototypeWorksheetManifest>> getPrototypeWorksheets() =>
      local.getPrototypeWorksheets();

  Future<List<PrototypeFlashcardSetManifest>> getPrototypeFlashcardSets() =>
      local.getPrototypeFlashcardSets();

  Future<List<PrototypeAssessmentManifest>> getPrototypeAssessments() =>
      local.getPrototypeAssessments();

  /// Saves a prototype worksheet into the existing SavedMaterials flow
  /// (account-scoped). Preview/download UI is reused unchanged.
  Future<void> savePrototypeWorksheet(WorksheetItem item) =>
      resources.saveWorksheet(item);

  /// Builds the existing [WorksheetItem] for a prototype manifest.
  WorksheetItem worksheetItemFromManifest(
    PrototypeWorksheetManifest manifest, {
    Map<String, dynamic>? manifestJson,
  }) =>
      local.worksheetItemFromManifest(manifest,
          manifestJson: manifestJson);

  /// Maps a prototype target-language label to the existing enum
  /// (defaults to Santali for the Class 2 demo).
  static TribalLanguage tribalLanguageFromLabels(List<String> languages) {
    final joined = languages.join(' ').toLowerCase();
    if (joined.contains('ho')) return TribalLanguage.ho;
    if (joined.contains('mundari')) return TribalLanguage.mundari;
    return TribalLanguage.santali;
  }
}
