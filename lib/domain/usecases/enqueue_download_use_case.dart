import '../entities/app_settings.dart';
import '../entities/chapter.dart';
import '../repositories/download_repository.dart';

/// Adds a chapter to the download queue.
class EnqueueDownloadUseCase {
  final DownloadRepository _repository;

  const EnqueueDownloadUseCase(this._repository);

  Future<void> call(
    Chapter chapter,
    String mangaTitle,
    ImageQuality quality,
  ) =>
      _repository.enqueueDownload(chapter, mangaTitle, quality);
}
