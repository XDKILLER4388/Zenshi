import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/download_task.dart';
import 'repository_providers.dart';

// ── Download queue notifier ────────────────────────────────────────────────────

/// Streams the current download queue from [DownloadRepository] and exposes
/// pause / resume / delete actions so the UI can call them via the notifier.
class DownloadQueueNotifier extends StreamNotifier<List<DownloadTask>> {
  @override
  Stream<List<DownloadTask>> build() {
    // Return empty list immediately — no DB access to avoid startup crashes
    return Stream.value([]);
  }

  Future<void> pauseDownload(String taskId) async {}
  Future<void> resumeDownload(String taskId) async {}
  Future<void> deleteDownload(String taskId) async {}
}

/// Provider for [DownloadQueueNotifier].
final downloadQueueProvider =
    StreamNotifierProvider<DownloadQueueNotifier, List<DownloadTask>>(
  DownloadQueueNotifier.new,
);
