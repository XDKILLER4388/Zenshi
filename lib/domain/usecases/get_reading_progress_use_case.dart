import '../entities/reading_progress.dart';
import '../repositories/reader_repository.dart';

/// Returns a stream of reading progress for a manga that emits on every change.
class GetReadingProgressUseCase {
  final ReaderRepository _repository;

  const GetReadingProgressUseCase(this._repository);

  Stream<ReadingProgress?> call(String mangaId) =>
      _repository.watchProgress(mangaId);
}
