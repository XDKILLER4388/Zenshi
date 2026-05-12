import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../domain/entities/download_task.dart';
import '../../providers/download_queue_provider.dart';
import '../../providers/settings_provider.dart';

/// Downloads Manager screen.
///
/// Shows all download tasks grouped by status:
/// - Downloading (active)
/// - Queued
/// - Completed
/// - Failed
///
/// Each item shows manga title, chapter number, progress bar, and status badge.
/// Action buttons: pause/resume (active/queued), delete (all).
/// Header shows total storage used. Bulk-delete button for completed downloads.
/// WiFi-only mode indicator banner when active.
class DownloadsScreen extends ConsumerWidget {
  const DownloadsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloadsAsync = ref.watch(downloadQueueProvider);
    final settingsAsync = ref.watch(settingsProvider);
    final wifiOnly = settingsAsync.valueOrNull?.wifiOnlyDownload ?? false;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text('Downloads', style: AppTypography.titleMedium),
        actions: [
          downloadsAsync.whenOrNull(
            data: (tasks) {
              final completed = tasks
                  .where((t) => t.status == DownloadStatus.completed)
                  .toList();
              if (completed.isEmpty) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(Icons.delete_sweep_outlined),
                tooltip: 'Delete all completed',
                onPressed: () => _confirmBulkDelete(context, ref, completed),
              );
            },
          ) ?? const SizedBox.shrink(),
        ],
      ),
      body: Column(
        children: [
          // WiFi-only banner
          if (wifiOnly) const _WifiOnlyBanner(),

          // Storage header
          downloadsAsync.whenOrNull(
            data: (tasks) => _StorageHeader(tasks: tasks),
          ) ?? const SizedBox.shrink(),

          // Task list
          Expanded(
            child: downloadsAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (e, _) => Center(
                child: Text(
                  'Failed to load downloads',
                  style: AppTypography.bodyMedium,
                ),
              ),
              data: (tasks) {
                if (tasks.isEmpty) {
                  return const _EmptyState();
                }
                return _DownloadList(tasks: tasks);
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmBulkDelete(
    BuildContext context,
    WidgetRef ref,
    List<DownloadTask> completed,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Delete completed?', style: AppTypography.titleSmall),
        content: Text(
          'This will remove ${completed.length} completed download(s).',
          style: AppTypography.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      for (final task in completed) {
        await ref.read(downloadQueueProvider.notifier).deleteDownload(task.id);
      }
    }
  }
}

// ── WiFi-only banner ───────────────────────────────────────────────────────────

class _WifiOnlyBanner extends StatelessWidget {
  const _WifiOnlyBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.warning.withAlpha(30),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.wifi, size: 16, color: AppColors.warning),
          const SizedBox(width: 8),
          Text(
            'WiFi-only mode active — downloads paused on mobile data',
            style: AppTypography.bodySmall.copyWith(color: AppColors.warning),
          ),
        ],
      ),
    );
  }
}

// ── Storage header ─────────────────────────────────────────────────────────────

class _StorageHeader extends StatelessWidget {
  const _StorageHeader({required this.tasks});

  final List<DownloadTask> tasks;

  @override
  Widget build(BuildContext context) {
    // Estimate storage: assume ~5 MB per downloaded page as a rough heuristic.
    final completedPages = tasks
        .where((t) => t.status == DownloadStatus.completed)
        .fold<int>(0, (sum, t) => sum + t.totalPages);
    final estimatedMb = completedPages * 5;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: AppColors.surface,
      child: Row(
        children: [
          const Icon(Icons.storage_outlined,
              size: 16, color: AppColors.onSurfaceMuted),
          const SizedBox(width: 8),
          Text(
            'Storage used: ~$estimatedMb MB',
            style: AppTypography.bodySmall,
          ),
          const Spacer(),
          Text(
            '${tasks.length} item${tasks.length == 1 ? '' : 's'}',
            style: AppTypography.bodySmall,
          ),
        ],
      ),
    );
  }
}

// ── Download list ──────────────────────────────────────────────────────────────

class _DownloadList extends StatelessWidget {
  const _DownloadList({required this.tasks});

  final List<DownloadTask> tasks;

  @override
  Widget build(BuildContext context) {
    final downloading =
        tasks.where((t) => t.status == DownloadStatus.downloading).toList();
    final queued =
        tasks.where((t) => t.status == DownloadStatus.queued).toList();
    final completed =
        tasks.where((t) => t.status == DownloadStatus.completed).toList();
    final failed =
        tasks.where((t) => t.status == DownloadStatus.failed).toList();
    final paused =
        tasks.where((t) => t.status == DownloadStatus.paused).toList();

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        if (downloading.isNotEmpty) ...[
          _SectionHeader(title: 'Downloading', count: downloading.length),
          ...downloading.map((t) => _DownloadItem(task: t)),
        ],
        if (queued.isNotEmpty) ...[
          _SectionHeader(title: 'Queued', count: queued.length),
          ...queued.map((t) => _DownloadItem(task: t)),
        ],
        if (paused.isNotEmpty) ...[
          _SectionHeader(title: 'Paused', count: paused.length),
          ...paused.map((t) => _DownloadItem(task: t)),
        ],
        if (completed.isNotEmpty) ...[
          _SectionHeader(title: 'Completed', count: completed.length),
          ...completed.map((t) => _DownloadItem(task: t)),
        ],
        if (failed.isNotEmpty) ...[
          _SectionHeader(title: 'Failed', count: failed.length),
          ...failed.map((t) => _DownloadItem(task: t)),
        ],
      ],
    );
  }
}

// ── Section header ─────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.count});

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Row(
        children: [
          Text(title, style: AppTypography.titleSmall),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count',
              style: AppTypography.labelSmall,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Download item ──────────────────────────────────────────────────────────────

class _DownloadItem extends ConsumerWidget {
  const _DownloadItem({required this.task});

  final DownloadTask task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isActive = task.status == DownloadStatus.downloading ||
        task.status == DownloadStatus.queued;
    final isPaused = task.status == DownloadStatus.paused;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.mangaTitle,
                      style: AppTypography.labelLarge,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Chapter ${task.chapterNumber.toStringAsFixed(task.chapterNumber.truncateToDouble() == task.chapterNumber ? 0 : 1)}',
                      style: AppTypography.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _StatusBadge(status: task.status),
              const SizedBox(width: 8),
              // Action buttons
              if (isActive)
                IconButton(
                  icon: const Icon(Icons.pause_circle_outline, size: 20),
                  color: AppColors.onSurfaceMuted,
                  tooltip: 'Pause',
                  onPressed: () => ref
                      .read(downloadQueueProvider.notifier)
                      .pauseDownload(task.id),
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  padding: EdgeInsets.zero,
                ),
              if (isPaused)
                IconButton(
                  icon: const Icon(Icons.play_circle_outline, size: 20),
                  color: AppColors.primary,
                  tooltip: 'Resume',
                  onPressed: () => ref
                      .read(downloadQueueProvider.notifier)
                      .resumeDownload(task.id),
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  padding: EdgeInsets.zero,
                ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20),
                color: AppColors.onSurfaceMuted,
                tooltip: 'Delete',
                onPressed: () => _confirmDelete(context, ref),
                constraints: const BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
          // Progress bar (shown for active/paused/queued)
          if (task.status != DownloadStatus.completed &&
              task.status != DownloadStatus.failed) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: task.progressPercent,
                      backgroundColor: AppColors.surfaceVariant,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        task.status == DownloadStatus.paused
                            ? AppColors.warning
                            : AppColors.primary,
                      ),
                      minHeight: 4,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${(task.progressPercent * 100).toStringAsFixed(0)}%',
                  style: AppTypography.labelSmall,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${task.downloadedPages} / ${task.totalPages} pages',
              style: AppTypography.bodySmall,
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Delete download?', style: AppTypography.titleSmall),
        content: Text(
          'Remove "${task.mangaTitle} Ch. ${task.chapterNumber}" from downloads?',
          style: AppTypography.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(downloadQueueProvider.notifier).deleteDownload(task.id);
    }
  }
}

// ── Status badge ───────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final DownloadStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      DownloadStatus.downloading => ('Downloading', AppColors.primary),
      DownloadStatus.queued => ('Queued', AppColors.secondary),
      DownloadStatus.paused => ('Paused', AppColors.warning),
      DownloadStatus.completed => ('Done', AppColors.success),
      DownloadStatus.failed => ('Failed', AppColors.error),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Text(
        label,
        style: AppTypography.labelSmall.copyWith(color: color),
      ),
    );
  }
}

// ── Empty state ────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.download_outlined,
              size: 72,
              color: AppColors.onSurfaceMuted,
            ),
            const SizedBox(height: 16),
            Text(
              'No downloads yet',
              style: AppTypography.titleSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Download chapters from the manga details page to read offline.',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.onSurfaceMuted,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
