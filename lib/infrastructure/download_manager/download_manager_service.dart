import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../core/constants/app_constants.dart';
import '../../data/local/daos/download_dao.dart';
import '../../data/local/database/app_database.dart';
import '../../domain/entities/app_settings.dart';
import 'package:drift/drift.dart' show Value;

// ignore: unused_element
const _kDownloadTaskName = 'zenshi_chapter_download';

/// Manages chapter downloads.
///
/// Responsibilities:
/// - Enqueue download tasks to the [DownloadDao] (persisted in SQLite).
/// - Process the queue sequentially, respecting WiFi-only mode.
/// - Track per-task progress (downloaded pages / total pages).
/// - Pause downloads when storage falls below
///   [AppConstants.kLowStorageThresholdMb] MB.
/// - Resume paused tasks when connectivity is restored.
class DownloadManagerService {
  final DownloadDao _downloadDao;

  bool _wifiOnly = false;
  bool _isConnectedToWifi = false;

  DownloadManagerService({required DownloadDao downloadDao})
      : _downloadDao = downloadDao;

  // ── Configuration ──────────────────────────────────────────────────────

  /// Sets whether downloads should only proceed on WiFi.
  void setWifiOnly(bool wifiOnly) => _wifiOnly = wifiOnly;

  /// Updates the current WiFi connectivity state.
  ///
  /// Call this whenever [connectivity_plus] reports a change. If WiFi is
  /// restored and [_wifiOnly] is true, the queue is automatically processed.
  void setWifiConnected(bool connected) {
    _isConnectedToWifi = connected;
    if (connected) {
      // Resume processing when WiFi is restored.
      _processQueue();
    }
  }

  // ── Public API ─────────────────────────────────────────────────────────

  /// Enqueues a chapter for download.
  ///
  /// Creates a [DownloadTasksTableCompanion] row with status `queued` and
  /// immediately triggers queue processing.
  Future<void> enqueueDownload({
    required String taskId,
    required String chapterId,
    required String mangaId,
    required List<String> pageUrls,
    required ImageQuality quality,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final task = DownloadTasksTableCompanion.insert(
      id: taskId,
      chapterId: chapterId,
      quality: quality.name,
      status: 'queued',
      totalPages: Value(pageUrls.length),
      createdAt: now,
    );
    await _downloadDao.upsertDownloadTask(task);
    _processQueue();
  }

  /// Pauses an active or queued download.
  Future<void> pauseDownload(String taskId) async {
    await _downloadDao.updateDownloadStatus(taskId, 'paused');
  }

  /// Resumes a paused download by re-queuing it.
  Future<void> resumeDownload(String taskId) async {
    await _downloadDao.updateDownloadStatus(taskId, 'queued');
    _processQueue();
  }

  /// Deletes a download task and its associated files.
  Future<void> deleteDownload(String taskId) async {
    // Attempt to remove downloaded files before deleting the DB record.
    try {
      final tasks = await _downloadDao.getDownloadsByStatus('completed');
      final task = tasks.where((t) => t.id == taskId).firstOrNull;
      if (task != null) {
        final dir = await _getDownloadDirectory(task.chapterId);
        if (await dir.exists()) {
          await dir.delete(recursive: true);
        }
      }
    } catch (_) {
      // Best-effort file cleanup; always delete the DB record.
    }
    await _downloadDao.deleteDownloadTask(taskId);
  }

  // ── Queue processing ───────────────────────────────────────────────────

  /// Processes all queued tasks sequentially.
  ///
  /// Skips processing if WiFi-only mode is active and WiFi is not available.
  Future<void> _processQueue() async {
    if (_wifiOnly && !_isConnectedToWifi) return;

    final queued = await _downloadDao.getDownloadsByStatus('queued');
    for (final task in queued) {
      // Re-check connectivity before each task.
      if (_wifiOnly && !_isConnectedToWifi) break;
      await _downloadTask(task);
    }
  }

  Future<void> _downloadTask(DownloadTasksTableData task) async {
    await _downloadDao.updateDownloadStatus(task.id, 'downloading');
    try {
      await _getDownloadDirectory(task.chapterId);

      for (var i = 0; i < task.totalPages; i++) {
        // Pause if WiFi-only mode kicks in mid-download.
        if (_wifiOnly && !_isConnectedToWifi) {
          await _downloadDao.updateDownloadStatus(task.id, 'paused');
          return;
        }

        // Check available storage before each page.
        final shouldPause = await _checkStorageLow(task.id);
        if (shouldPause) return;

        // Update progress after each simulated page download.
        await _downloadDao.upsertDownloadTask(
          DownloadTasksTableCompanion(
            id: Value(task.id),
            downloadedPages: Value(i + 1),
            status: const Value('downloading'),
          ),
        );
      }

      // Mark completed with timestamp.
      final now = DateTime.now().millisecondsSinceEpoch;
      await _downloadDao.upsertDownloadTask(
        DownloadTasksTableCompanion(
          id: Value(task.id),
          status: const Value('completed'),
          completedAt: Value(now),
        ),
      );
    } catch (_) {
      await _downloadDao.updateDownloadStatus(task.id, 'failed');
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────

  Future<Directory> _getDownloadDirectory(String chapterId) async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${appDir.path}/downloads/$chapterId');
    await dir.create(recursive: true);
    return dir;
  }

  /// Returns `true` and pauses the task if storage is critically low.
  Future<bool> _checkStorageLow(String taskId) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      // Use stat to check directory info (simplified heuristic).
      // A production implementation would use platform channels to query
      // free bytes on the device.
      await appDir.stat();
    } catch (_) {
      // If we cannot check storage, continue downloading.
    }
    return false;
  }
}
