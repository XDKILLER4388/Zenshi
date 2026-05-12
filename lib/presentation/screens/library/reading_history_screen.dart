import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../domain/entities/reading_progress.dart';

// ── Reading history provider ───────────────────────────────────────────────────

/// Provides a list of all reading progress records sorted by most recently read.
///
/// In a full implementation this would query the [ReadingProgressDao] for all
/// records. For now it exposes a stub that returns an empty list.
final readingHistoryProvider =
    StreamProvider<List<ReadingProgress>>((ref) async* {
  // TODO(task-22): wire to a real DAO query that returns all progress records
  // sorted by updatedAt descending.
  yield [];
});

// ── Screen ─────────────────────────────────────────────────────────────────────

/// Reading History screen.
///
/// Shows all titles the user has opened in the Reader, sorted by most recently
/// read. Each item shows cover, title, last chapter read, and time ago.
/// Swipe-to-dismiss removes an entry from history.
class ReadingHistoryScreen extends ConsumerWidget {
  const ReadingHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(readingHistoryProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text('Reading History', style: AppTypography.titleMedium),
        actions: [
          historyAsync.whenOrNull(
            data: (history) {
              if (history.isEmpty) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(Icons.delete_sweep_outlined),
                tooltip: 'Clear all history',
                onPressed: () => _confirmClearAll(context, ref),
              );
            },
          ) ?? const SizedBox.shrink(),
        ],
      ),
      body: historyAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, _) => Center(
          child: Text(
            'Failed to load history',
            style: AppTypography.bodyMedium,
          ),
        ),
        data: (history) {
          if (history.isEmpty) {
            return const _EmptyState();
          }
          return _HistoryList(history: history);
        },
      ),
    );
  }

  Future<void> _confirmClearAll(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Clear history?', style: AppTypography.titleSmall),
        content: Text(
          'This will remove all reading history. This cannot be undone.',
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
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      // TODO(task-22): call DAO to clear all reading progress records.
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('History cleared')),
      );
    }
  }
}

// ── History list ───────────────────────────────────────────────────────────────

class _HistoryList extends StatelessWidget {
  const _HistoryList({required this.history});

  final List<ReadingProgress> history;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: history.length,
      itemBuilder: (context, index) {
        final progress = history[index];
        return _HistoryItem(
          progress: progress,
          onDismiss: () {
            // TODO(task-22): call DAO to remove this progress record.
          },
        );
      },
    );
  }
}

// ── History item ───────────────────────────────────────────────────────────────

class _HistoryItem extends StatelessWidget {
  const _HistoryItem({
    required this.progress,
    required this.onDismiss,
  });

  final ReadingProgress progress;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(progress.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: AppColors.error,
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) => onDismiss(),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // Cover placeholder
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 48,
                height: 68,
                color: AppColors.surfaceVariant,
                child: const Icon(
                  Icons.book_outlined,
                  color: AppColors.onSurfaceMuted,
                  size: 24,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Manga ${progress.mangaId}',
                    style: AppTypography.labelLarge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Chapter ${progress.chapterId} · Page ${progress.pageIndex + 1}',
                    style: AppTypography.bodySmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _timeAgo(progress.updatedAt),
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.onSurfaceMuted,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppColors.onSurfaceMuted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  String _timeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
    if (diff.inDays < 365) return '${(diff.inDays / 30).floor()}mo ago';
    return '${(diff.inDays / 365).floor()}y ago';
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
              Icons.history,
              size: 72,
              color: AppColors.onSurfaceMuted,
            ),
            const SizedBox(height: 16),
            Text('No reading history', style: AppTypography.titleSmall),
            const SizedBox(height: 8),
            Text(
              'Titles you open in the Reader will appear here.',
              style: AppTypography.bodyMedium
                  .copyWith(color: AppColors.onSurfaceMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
