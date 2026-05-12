import '../entities/chapter.dart';
import '../entities/app_settings.dart';
import '../entities/download_task.dart';

/// Abstract interface for managing the chapter download queue.
abstract class DownloadRepository {
  /// Emits the current download queue and any subsequent changes.
  Stream<List<DownloadTask>> watchDownloadQueue();

  /// Adds [chapter] to the download queue with the given [quality].
  Future<void> enqueueDownload(
    Chapter chapter,
    String mangaTitle,
    ImageQuality quality,
  );

  /// Pauses the download identified by [taskId].
  Future<void> pauseDownload(String taskId);

  /// Resumes a paused download identified by [taskId].
  Future<void> resumeDownload(String taskId);

  /// Deletes the download task and any partially downloaded files for [taskId].
  Future<void> deleteDownload(String taskId);

  /// Returns the total size in bytes consumed by all completed downloads.
  Future<int> getTotalDownloadSizeBytes();
}
