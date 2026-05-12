import '../repositories/sync_repository.dart';

/// Triggers a full bidirectional cloud sync.
class SyncUseCase {
  final SyncRepository _repository;

  const SyncUseCase(this._repository);

  Future<void> call() => _repository.fullSync();
}
