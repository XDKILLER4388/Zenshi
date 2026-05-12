import '../entities/chapter.dart';
import '../entities/page.dart';
import '../entities/reading_progress.dart';

/// Abstract interface for reader page loading and progress persistence.
abstract class ReaderRepository {
  /// Returns the page list for [chapter].
  Future<List<Page>> getPages(Chapter chapter);

  /// Persists [progress] to local storage (and queues for remote sync).
  Future<void> saveReadingProgress(ReadingProgress progress);

  /// Emits the current reading progress for [mangaId] and any updates.
  Stream<ReadingProgress?> watchProgress(String mangaId);

  /// Returns the most recent reading progress for [mangaId], or null.
  Future<ReadingProgress?> getProgress(String mangaId);
}
