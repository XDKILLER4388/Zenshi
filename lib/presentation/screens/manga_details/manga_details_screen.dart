import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../domain/entities/app_settings.dart';
import '../../../domain/entities/chapter.dart';
import '../../../domain/entities/manga.dart';
import '../../providers/library_provider.dart';
import '../../providers/manga_provider.dart';
import '../../providers/use_case_providers.dart';
import '../../widgets/common/skeleton_loader.dart';

class MangaDetailsScreen extends ConsumerStatefulWidget {
  const MangaDetailsScreen({
    super.key,
    required this.mangaId,
    required this.sourceId,
  });

  final String mangaId;
  final String sourceId;

  @override
  ConsumerState<MangaDetailsScreen> createState() => _MangaDetailsScreenState();
}

class _MangaDetailsScreenState extends ConsumerState<MangaDetailsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  bool _descriptionExpanded = false;
  bool _sortAscending = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final args = MangaDetailArgs(id: widget.mangaId, sourceId: widget.sourceId);
    final mangaAsync = ref.watch(mangaDetailProvider(args));
    final chaptersAsync = ref.watch(chapterListByMangaProvider(args));
    final library = ref.watch(libraryProvider).valueOrNull ?? [];
    final inLibrary = library.any((m) => m.id == widget.mangaId);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: mangaAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (_, __) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.wifi_off_rounded,
                color: AppColors.onSurfaceMuted,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text('Could not load manga', style: AppTypography.bodyMedium),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.invalidate(mangaDetailProvider(args)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (manga) {
          if (manga == null) {
            return Center(
              child: Text('Manga not found', style: AppTypography.bodyMedium),
            );
          }

          final sortedChapters = chaptersAsync.valueOrNull ?? [];
          final chapters = List<Chapter>.from(sortedChapters);
          // Standard sort: newest first (descending) by default for details view
          if (_sortAscending) {
            chapters.sort((a, b) => a.chapterNumber.compareTo(b.chapterNumber));
          } else {
            chapters.sort((a, b) => b.chapterNumber.compareTo(a.chapterNumber));
          }

          final firstUnread = chapters.isNotEmpty
              ? (chapters.lastWhere(
                  (c) => !c.isRead,
                  orElse: () => chapters.last,
                ))
              : null;

          return NestedScrollView(
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
                  background: _MangaHeader(manga: manga),
                ),
              ),
            ],
            body: Column(
              children: [
                // Genre chips
                if (manga.genres.isNotEmpty) _GenreChips(genres: manga.genres),

                // Description
                if (manga.description != null && manga.description!.isNotEmpty)
                  _DescriptionSection(
                    description: manga.description!,
                    expanded: _descriptionExpanded,
                    onToggle: () => setState(
                      () => _descriptionExpanded = !_descriptionExpanded,
                    ),
                  ),

                // Action buttons
                _ActionButtons(
                  inLibrary: inLibrary,
                  onToggleLibrary: () async {
                    if (inLibrary) {
                      await ref
                          .read(libraryProvider.notifier)
                          .removeFromLibrary(widget.mangaId);
                    } else {
                      await ref
                          .read(libraryProvider.notifier)
                          .addToLibrary(manga);
                    }
                  },
                  onStartReading: () {
                    if (firstUnread != null) {
                      context.push(
                        '/manga-reader/${widget.sourceId}/${widget.mangaId}/${firstUnread.id}',
                      );
                    }
                  },
                ),

                // Tab bar
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

                // Tab content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Chapters tab
                      chaptersAsync.when(
                        loading: () => ListView.builder(
                          itemCount: 8,
                          itemBuilder: (_, __) => Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 6,
                            ),
                            child: ShimmerBox(
                              width: double.infinity,
                              height: 48,
                            ),
                          ),
                        ),
                        error: (_, __) => Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.wifi_off_rounded,
                                color: AppColors.onSurfaceMuted,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Could not load chapters',
                                style: AppTypography.bodySmall,
                              ),
                              TextButton(
                                onPressed: () => ref.invalidate(
                                  chapterListByMangaProvider(args),
                                ),
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                        data: (_) => _ChapterList(
                          chapters: chapters,
                          sortAscending: _sortAscending,
                          onToggleSort: () =>
                              setState(() => _sortAscending = !_sortAscending),
                          onTap: (ch) => context.push(
                            '/manga-reader/${widget.sourceId}/${widget.mangaId}/${ch.id}',
                          ),
                          onLongPress: (ch) => _showContextMenu(context, ch),
                          mangaTitle: manga.title,
                        ),
                      ),

                      // Similar tab
                      const _SimilarTab(),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showContextMenu(BuildContext context, Chapter chapter) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
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
              padding: const EdgeInsets.all(16),
              child: Text(
                'Chapter ${chapter.chapterNumber.toStringAsFixed(0)}',
                style: AppTypography.titleSmall,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.download_outlined),
              title: const Text('Download'),
              onTap: () {
                Navigator.of(context).pop();
                ref
                    .read(enqueueDownloadUseCaseProvider)
                    .call(
                      chapter,
                      '', // Manga title not available here easily without passing it down
                      ImageQuality.high,
                    );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Downloading Chapter ${chapter.chapterNumber}...',
                    ),
                    backgroundColor: AppColors.primary,
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.check_circle_outline),
              title: const Text('Mark as Read'),
              onTap: () => Navigator.of(context).pop(),
            ),
            const SizedBox(height: 8),
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
            child: CachedNetworkImage(
              imageUrl: manga.coverUrl!,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) =>
                  Container(color: AppColors.surfaceVariant),
            ),
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
                child: SizedBox(
                  width: 110,
                  height: 160,
                  child: manga.coverUrl != null
                      ? CachedNetworkImage(
                          imageUrl: manga.coverUrl!,
                          fit: BoxFit.cover,
                          placeholder: (_, __) =>
                              Container(color: AppColors.surfaceVariant),
                          errorWidget: (_, __, ___) => Container(
                            color: AppColors.surfaceVariant,
                            child: Center(
                              child: Text(
                                manga.title[0],
                                style: AppTypography.headlineLarge.copyWith(
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                        )
                      : Container(
                          color: AppColors.surfaceVariant,
                          child: Center(
                            child: Text(
                              manga.title[0],
                              style: AppTypography.headlineLarge.copyWith(
                                color: AppColors.primary,
                              ),
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
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _StatusBadge(status: manga.status),
                        if (manga.averageRating != null) ...[
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.star_rounded,
                            color: Colors.amber,
                            size: 14,
                          ),
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

  Color get _color => switch (status) {
    MangaStatus.ongoing => AppColors.success,
    MangaStatus.completed => AppColors.secondary,
    MangaStatus.hiatus => AppColors.warning,
    MangaStatus.unknown => AppColors.onSurfaceMuted,
  };

  String get _label => switch (status) {
    MangaStatus.ongoing => 'Ongoing',
    MangaStatus.completed => 'Completed',
    MangaStatus.hiatus => 'Hiatus',
    MangaStatus.unknown => 'Unknown',
  };

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
            style: AppTypography.labelSmall.copyWith(color: AppColors.primary),
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
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onToggleLibrary,
              icon: Icon(
                inLibrary ? Icons.bookmark : Icons.bookmark_outline,
                size: 18,
              ),
              label: Text(inLibrary ? 'In Library' : 'Add to Library'),
              style: OutlinedButton.styleFrom(
                foregroundColor: inLibrary
                    ? AppColors.primary
                    : AppColors.onSurface,
                side: BorderSide(
                  color: inLibrary ? AppColors.primary : AppColors.divider,
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 12),
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
    required this.mangaTitle,
  });
  final List<Chapter> chapters;
  final bool sortAscending;
  final VoidCallback onToggleSort;
  final ValueChanged<Chapter> onTap;
  final ValueChanged<Chapter> onLongPress;
  final String mangaTitle;

  @override
  Widget build(BuildContext context) {
    if (chapters.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.menu_book,
              size: 64,
              color: AppColors.onSurfaceMuted,
            ),
            const SizedBox(height: 16),
            Text(
              'No chapters available from this source',
              style: AppTypography.bodyLarge.copyWith(
                color: AppColors.onSurfaceMuted,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                context.push('/search', extra: mangaTitle);
              },
              icon: const Icon(Icons.public),
              label: const Text('Search in other sources'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
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
            itemBuilder: (_, i) {
              final ch = chapters[i];
              final isRead = ch.isRead;
              return Opacity(
                opacity: isRead ? 0.5 : 1.0,
                child: ListTile(
                  onTap: () => onTap(ch),
                  onLongPress: () => onLongPress(ch),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  title: Text(
                    'Chapter ${ch.chapterNumber.toStringAsFixed(ch.chapterNumber % 1 == 0 ? 0 : 1)}${ch.title != null ? ' - ${ch.title}' : ''}',
                    style: AppTypography.titleSmall.copyWith(
                      color: isRead
                          ? AppColors.onSurfaceMuted
                          : AppColors.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
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
                          color: AppColors.success,
                          size: 18,
                        )
                      : const Icon(
                          Icons.chevron_right,
                          color: AppColors.onSurfaceMuted,
                          size: 18,
                        ),
                ),
              );
            },
          ),
        ),
      ],
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
