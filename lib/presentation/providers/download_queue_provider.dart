import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/download_task.dart';
import 'repository_providers.dart';

// ── Download queue notifier ────────────────────────────────────────────────────

/// Streams the current download queue from [DownloadRepository] and exposes
/// pause / resume / delete actions so the UI can call them via the notifier.
class DownloadQueueNotifier extends StreamNotifier<List<DownloadTask>> {
  @override
  Stream<List<DownloadTask>> build() {
    return ref.watch(downloadRepositoryProvider).watchDownloadQueue();
  }

  /// Pauses the download identified by [taskId].
  Future<void> pauseDownload(String taskId) async {
    await ref.read(downloadRepositoryProvider).pauseDownload(taskId);
  }

  /// Resumes a paused download identified by [taskId].
  Future<void> resumeDownload(String taskId) async {
    await ref.read(downloadRepositoryProvider).resumeDownload(taskId);
  }

  /// Deletes the download task and any partially downloaded files.
  Future<void> deleteDownload(String taskId) async {
    await ref.read(downloadRepositoryProvider).deleteDownload(taskId);
  }
}

/// Provider for [DownloadQueueNotifier].
final downloadQueueProvider =
    StreamNotifierProvider<DownloadQueueNotifier, List<DownloadTask>>(
  DownloadQueueNotifier.new,
);
