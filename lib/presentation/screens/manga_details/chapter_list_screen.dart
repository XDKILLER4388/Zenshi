import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../domain/entities/chapter.dart';
import '../../providers/manga_provider.dart';

/// Standalone chapter list screen (accessible via /manga-details/:sourceId/:id/chapters).
class ChapterListScreen extends ConsumerStatefulWidget {
  const ChapterListScreen({
    super.key,
    required this.mangaId,
    required this.sourceId,
  });

  final String mangaId;
  final String sourceId;

  @override
  ConsumerState<ChapterListScreen> createState() => _ChapterListScreenState();
}

class _ChapterListScreenState extends ConsumerState<ChapterListScreen> {
  bool _sortAscending = false;

  @override
  Widget build(BuildContext context) {
    final args = MangaDetailArgs(id: widget.mangaId, sourceId: widget.sourceId);
    final chaptersAsync = ref.watch(chapterListByMangaProvider(args));

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
            onPressed: () => setState(() => _sortAscending = !_sortAscending),
          ),
        ],
      ),
      body: chaptersAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (_, __) => const Center(child: Text('Error loading chapters')),
        data: (chapters) {
          final sorted = List<Chapter>.from(chapters);
          if (_sortAscending) {
            sorted.sort((a, b) => a.chapterNumber.compareTo(b.chapterNumber));
          } else {
            sorted.sort((a, b) => b.chapterNumber.compareTo(a.chapterNumber));
          }

          if (sorted.isEmpty) {
            return const Center(child: Text('No chapters found'));
          }

          return ListView.separated(
            itemCount: sorted.length,
            separatorBuilder: (_, __) =>
                const Divider(color: AppColors.divider, height: 1),
            itemBuilder: (ctx, i) {
              final ch = sorted[i];
              final isRead = ch.isRead;
              return Opacity(
                opacity: isRead ? 0.5 : 1.0,
                child: ListTile(
                  onTap: () => ctx.push(
                    '/manga-reader/${widget.sourceId}/${widget.mangaId}/${ch.id}',
                  ),
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
                      ? const Icon(
                          Icons.check_circle_rounded,
                          color: Colors.green,
                          size: 20,
                        )
                      : null,
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
