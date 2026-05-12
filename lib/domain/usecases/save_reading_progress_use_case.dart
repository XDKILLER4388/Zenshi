import '../entities/reading_progress.dart';
import '../repositories/reader_repository.dart';

/// Persists the user's current reading position.
class SaveReadingProgressUseCase {
  final ReaderRepository _repository;

  const SaveReadingProgressUseCase(this._repository);

  Future<void> call(ReadingProgress progress) =>
      _repository.saveReadingProgress(progress);
}
