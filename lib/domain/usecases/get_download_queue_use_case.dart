import '../entities/download_task.dart';
import '../repositories/download_repository.dart';

/// Returns a stream of the download queue that emits on every change.
class GetDownloadQueueUseCase {
  final DownloadRepository _repository;

  const GetDownloadQueueUseCase(this._repository);

  Stream<List<DownloadTask>> call() => _repository.watchDownloadQueue();
}
