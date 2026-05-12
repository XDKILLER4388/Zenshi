import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../domain/entities/chapter.dart';
import '../../../domain/entities/manga.dart';
import '../../providers/library_provider.dart';

// ── Mock data ──────────────────────────────────────────────────────────────────

Manga _mockManga(String id) => Manga(
      id: id,
      sourceId: 'mock',
      title: 'The Rising of the Shield Hero',
      coverUrl: null,
      author: 'Aneko Yusagi',
      artist: 'Seira Minami',
      description:
          'Naofumi Iwatani, an uncharitable otaku who spends his days on games and manga, '
          'suddenly finds himself summoned to a parallel universe. He discovers he is one of '
          'four heroes equipped with legendary weapons and tasked with saving the world from '
          'its prophesied destruction. As the Shield Hero, the weakest of the heroes, all '
          'is not as it seems. Naofumi is soon alone, penniless, and betrayed.',
      status: MangaStatus.ongoing,
      genres: const [
        'Action', 'Adventure', 'Fantasy', 'Isekai', 'Drama'
      ],
      averageRating: 8.4,
      isNsfw: false,
      inLibrary: false,
    );

List<Chapter> _mockChapters(String mangaId) => List.generate(
      50,
      (i) => Chapter(
        id: 'ch_${mangaId}_${50 - i}',
        mangaId: mangaId,
        sourceId: 'mock',
        chapterNumber: (50 - i).toDouble(),
        title: i == 0 ? 'The Shield Hero' : null,
        uploadDate: DateTime.now().subtract(Duration(days: i * 7)),
        pageCount: 20,
        isRead: i > 40,
      ),
    );

// ── Screen ─────────────────────────────────────────────────────────────────────

class MangaDetailsScreen extends ConsumerStatefulWidget {
  const MangaDetailsScreen({super.key, required this.mangaId});

  final String mangaId;

  @override
  ConsumerState<MangaDetailsScreen> createState() =>
      _MangaDetailsScreenState();
}

class _MangaDetailsScreenState extends ConsumerState<MangaDetailsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final Manga _manga;
  late final List<Chapter> _chapters;
  bool _descriptionExpanded = false;
  bool _sortAscending = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _manga = _mockManga(widget.mangaId);
    _chapters = _mockChapters(widget.mangaId);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  bool get _inLibrary {
    final library = ref.watch(libraryProvider).valueOrNull ?? [];
    return library.any((m) => m.id == widget.mangaId);
  }

  Future<void> _toggleLibrary() async {
    if (_inLibrary) {
      await ref.read(libraryProvider.notifier).removeFromLibrary(widget.mangaId);
    } else {
      await ref.read(libraryProvider.notifier).addToLibrary(_manga);
    }
  }

  List<Chapter> get _sortedChapters {
    final sorted = List<Chapter>.from(_chapters);
    if (_sortAscending) {
      sorted.sort((a, b) => a.chapterNumber.compareTo(b.chapterNumber));
    } else {
      sorted.sort((a, b) => b.chapterNumber.compareTo(a.chapterNumber));
    }
    return sorted;
  }

  Chapter? get _firstUnreadChapter {
    final ascending = List<Chapter>.from(_chapters)
      ..sort((a, b) => a.chapterNumber.compareTo(b.chapterNumber));
    try {
      return ascending.firstWhere((c) => !c.isRead);
    } catch (_) {
      return ascending.isNotEmpty ? ascending.first : null;
    }
  }

  void _navigateToChapter(Chapter chapter) {
    context.push('/reader/${widget.mangaId}/${chapter.id}');
  }

  void _showChapterContextMenu(Chapter chapter) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ChapterContextMenu(chapter: chapter),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            backgroundColor: AppColors.background,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: _MangaHeader(manga: _manga),
            ),
          ),
        ],
        body: Column(
          children: [
            // ── Genre chips ──────────────────────────────────────────────
            _GenreChips(genres: _manga.genres),

            // ── Description ──────────────────────────────────────────────
            _DescriptionSection(
              description: _manga.description ?? '',
              expanded: _descriptionExpanded,
              onToggle: () =>
                  setState(() => _descriptionExpanded = !_descriptionExpanded),
            ),

            // ── Action buttons ───────────────────────────────────────────
            _ActionButtons(
              inLibrary: _inLibrary,
              onToggleLibrary: _toggleLibrary,
              onStartReading: () {
                final ch = _firstUnreadChapter;
                if (ch != null) _navigateToChapter(ch);
              },
            ),

            // ── Tab bar ──────────────────────────────────────────────────
            TabBar(
              controller: _tabController,
              indicatorColor: AppColors.primary,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.onSurfaceMuted,
              tabs: const [
                Tab(text: 'Chapters'),
                Tab(text: 'Similar'),
              ],
            ),

            // ── Tab content ──────────────────────────────────────────────
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _ChapterList(
                    chapters: _sortedChapters,
                    sortAscending: _sortAscending,
                    onToggleSort: () =>
                        setState(() => _sortAscending = !_sortAscending),
                    onTap: _navigateToChapter,
                    onLongPress: _showChapterContextMenu,
                  ),
                  const _SimilarTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Header ─────────────────────────────────────────────────────────────────────

class _MangaHeader extends StatelessWidget {
  const _MangaHeader({required this.manga});

  final Manga manga;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Blurred background
        if (manga.coverUrl != null)
          ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Image.network(manga.coverUrl!, fit: BoxFit.cover),
          )
        else
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF1A0A2E), AppColors.background],
              ),
            ),
          ),
        // Gradient overlay
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, AppColors.background],
              stops: [0.4, 1.0],
            ),
          ),
        ),
        // Content
        Positioned(
          bottom: 16,
          left: 16,
          right: 16,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Cover
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 110,
                  height: 160,
                  color: AppColors.surfaceVariant,
                  child: manga.coverUrl != null
                      ? Image.network(manga.coverUrl!, fit: BoxFit.cover)
                      : Center(
                          child: Text(
                            manga.title[0],
                            style: AppTypography.headlineLarge.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 16),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      manga.title,
                      style: AppTypography.titleLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (manga.author != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        manga.author!,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.onSurfaceMuted,
                        ),
                      ),
                    ],
                    if (manga.artist != null &&
                        manga.artist != manga.author) ...[
                      Text(
                        'Art: ${manga.artist}',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.onSurfaceMuted,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _StatusBadge(status: manga.status),
                        if (manga.averageRating != null) ...[
                          const SizedBox(width: 8),
                          const Icon(Icons.star_rounded,
                              color: Colors.amber, size: 14),
                          const SizedBox(width: 2),
                          Text(
                            manga.averageRating!.toStringAsFixed(1),
                            style: AppTypography.labelSmall.copyWith(
                              color: Colors.amber,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Status badge ───────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final MangaStatus status;

  Color get _color {
    switch (status) {
      case MangaStatus.ongoing:
        return AppColors.success;
      case MangaStatus.completed:
        return AppColors.secondary;
      case MangaStatus.hiatus:
        return AppColors.warning;
      case MangaStatus.unknown:
        return AppColors.onSurfaceMuted;
    }
  }

  String get _label {
    switch (status) {
      case MangaStatus.ongoing:
        return 'Ongoing';
      case MangaStatus.completed:
        return 'Completed';
      case MangaStatus.hiatus:
        return 'Hiatus';
      case MangaStatus.unknown:
        return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _color.withAlpha(40),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _color.withAlpha(80)),
      ),
      child: Text(
        _label,
        style: AppTypography.labelSmall.copyWith(color: _color),
      ),
    );
  }
}

// ── Genre chips ────────────────────────────────────────────────────────────────

class _GenreChips extends StatelessWidget {
  const _GenreChips({required this.genres});

  final List<String> genres;

  @override
  Widget build(BuildContext context) {
    if (genres.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: genres.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) => Chip(
          label: Text(
            genres[i],
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.primary,
            ),
          ),
          backgroundColor: AppColors.primary.withAlpha(30),
          side: BorderSide(color: AppColors.primary.withAlpha(60)),
          padding: const EdgeInsets.symmetric(horizontal: 4),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );
  }
}

// ── Description ────────────────────────────────────────────────────────────────

class _DescriptionSection extends StatelessWidget {
  const _DescriptionSection({
    required this.description,
    required this.expanded,
    required this.onToggle,
  });

  final String description;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    if (description.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            description,
            maxLines: expanded ? null : 3,
            overflow: expanded ? null : TextOverflow.ellipsis,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.onSurfaceMuted,
              height: 1.6,
            ),
          ),
          GestureDetector(
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                expanded ? 'Show less' : 'Show more',
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Action buttons ─────────────────────────────────────────────────────────────

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({
    required this.inLibrary,
    required this.onToggleLibrary,
    required this.onStartReading,
  });

  final bool inLibrary;
  final VoidCallback onToggleLibrary;
  final VoidCallback onStartReading;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          // Library toggle
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onToggleLibrary,
              icon: Icon(
                inLibrary ? Icons.bookmark : Icons.bookmark_outline,
                size: 18,
              ),
              label: Text(inLibrary ? 'In Library' : 'Add to Library'),
              style: OutlinedButton.styleFrom(
                foregroundColor:
                    inLibrary ? AppColors.primary : AppColors.onSurface,
                side: BorderSide(
                  color: inLibrary ? AppColors.primary : AppColors.divider,
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Start reading
          Expanded(
            child: ElevatedButton.icon(
              onPressed: onStartReading,
              icon: const Icon(Icons.play_arrow_rounded, size: 18),
              label: const Text('Start Reading'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Chapter list ───────────────────────────────────────────────────────────────

class _ChapterList extends StatelessWidget {
  const _ChapterList({
    required this.chapters,
    required this.sortAscending,
    required this.onToggleSort,
    required this.onTap,
    required this.onLongPress,
  });

  final List<Chapter> chapters;
  final bool sortAscending;
  final VoidCallback onToggleSort;
  final ValueChanged<Chapter> onTap;
  final ValueChanged<Chapter> onLongPress;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Sort header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${chapters.length} Chapters',
                style: AppTypography.titleSmall,
              ),
              IconButton(
                icon: Icon(
                  sortAscending
                      ? Icons.arrow_upward_rounded
                      : Icons.arrow_downward_rounded,
                  size: 20,
                  color: AppColors.primary,
                ),
                tooltip: sortAscending ? 'Sort Descending' : 'Sort Ascending',
                onPressed: onToggleSort,
              ),
            ],
          ),
        ),
        const Divider(color: AppColors.divider, height: 1),
        Expanded(
          child: ListView.separated(
            itemCount: chapters.length,
            separatorBuilder: (_, __) =>
                const Divider(color: AppColors.divider, height: 1),
            itemBuilder: (_, i) => _ChapterTile(
              chapter: chapters[i],
              onTap: () => onTap(chapters[i]),
              onLongPress: () => onLongPress(chapters[i]),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Chapter tile ───────────────────────────────────────────────────────────────

class _ChapterTile extends StatelessWidget {
  const _ChapterTile({
    required this.chapter,
    required this.onTap,
    required this.onLongPress,
  });

  final Chapter chapter;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final isRead = chapter.isRead;
    return Opacity(
      opacity: isRead ? 0.5 : 1.0,
      child: ListTile(
        onTap: onTap,
        onLongPress: onLongPress,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        title: Row(
          children: [
            Text(
              'Chapter ${chapter.chapterNumber.toStringAsFixed(chapter.chapterNumber % 1 == 0 ? 0 : 1)}',
              style: AppTypography.titleSmall.copyWith(
                color: isRead ? AppColors.onSurfaceMuted : AppColors.onSurface,
              ),
            ),
            if (chapter.title != null) ...[
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  chapter.title!,
                  style: AppTypography.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
        subtitle: chapter.uploadDate != null
            ? Text(
                _formatDate(chapter.uploadDate!),
                style: AppTypography.labelSmall,
              )
            : null,
        trailing: isRead
            ? const Icon(Icons.check_circle_rounded,
                color: AppColors.success, size: 18)
            : null,
      ),
    );
  }

  String _formatDate(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()} weeks ago';
    if (diff.inDays < 365) return '${(diff.inDays / 30).floor()} months ago';
    return '${(diff.inDays / 365).floor()} years ago';
  }
}

// ── Chapter context menu ───────────────────────────────────────────────────────

class _ChapterContextMenu extends StatelessWidget {
  const _ChapterContextMenu({required this.chapter});

  final Chapter chapter;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Chapter ${chapter.chapterNumber.toStringAsFixed(0)}',
              style: AppTypography.titleSmall,
            ),
          ),
          const Divider(color: AppColors.divider, height: 1),
          ListTile(
            leading: const Icon(Icons.download_outlined),
            title: const Text('Download'),
            onTap: () => Navigator.of(context).pop(),
          ),
          ListTile(
            leading: const Icon(Icons.check_circle_outline),
            title: const Text('Mark as Read'),
            onTap: () => Navigator.of(context).pop(),
          ),
          ListTile(
            leading: const Icon(Icons.radio_button_unchecked),
            title: const Text('Mark as Unread'),
            onTap: () => Navigator.of(context).pop(),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ── Similar tab ────────────────────────────────────────────────────────────────

class _SimilarTab extends StatelessWidget {
  const _SimilarTab();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.auto_awesome_rounded,
            size: 64,
            color: AppColors.onSurfaceMuted.withAlpha(80),
          ),
          const SizedBox(height: 16),
          Text(
            'Similar titles coming soon',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.onSurfaceMuted,
            ),
          ),
        ],
      ),
    );
  }
}
