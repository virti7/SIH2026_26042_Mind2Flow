import '../../models/app_models.dart';
import '../../repositories/app_repositories.dart';

class GetLanguagePacksUseCase {
  final OfflineRepository repository;

  const GetLanguagePacksUseCase(this.repository);

  Future<List<LanguagePackInfo>> execute() async {
    return repository.getLanguagePacks();
  }
}

class DownloadLanguagePackUseCase {
  final OfflineRepository repository;

  const DownloadLanguagePackUseCase(this.repository);

  Future<void> execute(String packId) async {
    return repository.downloadLanguagePack(packId);
  }
}

class GetContentPacksUseCase {
  final OfflineRepository repository;

  const GetContentPacksUseCase(this.repository);

  Future<List<ContentPackInfo>> execute() async {
    return repository.getContentPacks();
  }
}

class TriggerSyncUseCase {
  final OfflineRepository repository;

  const TriggerSyncUseCase(this.repository);

  Future<void> execute() async {
    return repository.syncClassroomData();
  }
}

class GetPendingSyncCountUseCase {
  final OfflineRepository repository;

  const GetPendingSyncCountUseCase(this.repository);

  Future<int> execute() async {
    return repository.getPendingSyncCount();
  }
}
