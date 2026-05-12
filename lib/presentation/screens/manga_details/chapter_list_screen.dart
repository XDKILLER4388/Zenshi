import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../domain/entities/chapter.dart';

// ── Mock data ──────────────────────────────────────────────────────────────────

List<Chapter> _mockChapters(String mangaId) => List.generate(
      50,
      (i) => Chapter(
        id: 'ch_${mangaId}_${50 - i}',
        mangaId: mangaId,
        sourceId: 'mock',
        chapterNumber: (50 - i).toDouble(),
        uploadDate: DateTime.now().subtract(Duration(days: i * 7)),
        pageCount: 20,
        isRead: i > 40,
      ),
    );

/// Standalone chapter list screen (accessible via /manga/:id/chapters).
///
/// Mirrors the chapter list tab in [MangaDetailsScreen] but as a full screen.
class ChapterListScreen extends StatefulWidget {
  const ChapterListScreen({super.key, required this.mangaId});

  final String mangaId;

  @override
  State<ChapterListScreen> createState() => _ChapterListScreenState();
}

class _ChapterListScreenState extends State<ChapterListScreen> {
  bool _sortAscending = false;

  List<Chapter> get _sorted {
    final chapters = _mockChapters(widget.mangaId);
    if (_sortAscending) {
      chapters.sort((a, b) => a.chapterNumber.compareTo(b.chapterNumber));
    } else {
      chapters.sort((a, b) => b.chapterNumber.compareTo(a.chapterNumber));
    }
    return chapters;
  }

  @override
  Widget build(BuildContext context) {
    final chapters = _sorted;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('Chapters'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _sortAscending
                  ? Icons.arrow_upward_rounded
                  : Icons.arrow_downward_rounded,
              color: AppColors.primary,
            ),
            onPressed: () =>
                setState(() => _sortAscending = !_sortAscending),
          ),
        ],
      ),
      body: ListView.separated(
        itemCount: chapters.length,
        separatorBuilder: (_, __) =>
            const Divider(color: AppColors.divider, height: 1),
        itemBuilder: (ctx, i) {
          final ch = chapters[i];
          final isRead = ch.isRead;
          return Opacity(
            opacity: isRead ? 0.5 : 1.0,
            child: ListTile(
              onTap: () =>
                  ctx.push('/reader/${widget.mangaId}/${ch.id}'),
              title: Text(
                'Chapter ${ch.chapterNumber.toStringAsFixed(ch.chapterNumber % 1 == 0 ? 0 : 1)}',
                style: AppTypography.titleSmall.copyWith(
                  color: isRead
                      ? AppColors.onSurfaceMuted
                      : AppColors.onSurface,
                ),
              ),
              subtitle: ch.uploadDate != null
                  ? Text(
                      _formatDate(ch.uploadDate!),
                      style: AppTypography.labelSmall,
                    )
                  : null,
              trailing: isRead
                  ? const Icon(Icons.check_circle_rounded,
                      color: AppColors.success, size: 18)
                  : null,
            ),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()} weeks ago';
    return '${(diff.inDays / 30).floor()} months ago';
  }
}
