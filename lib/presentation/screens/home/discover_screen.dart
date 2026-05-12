import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../domain/entities/manga.dart';
import '../../providers/library_provider.dart';
import '../../widgets/common/skeleton_loader.dart';
import '../../widgets/manga_card/manga_card.dart';

// ── Mock data helpers ──────────────────────────────────────────────────────────

List<Manga> _mockMangaList(String prefix, int count) {
  return List.generate(
    count,
    (i) => Manga(
      id: '${prefix}_$i',
      sourceId: 'mock',
      title: '$prefix Title ${i + 1}',
      coverUrl: null,
      author: 'Author ${i + 1}',
      status: MangaStatus.ongoing,
      genres: const ['Action', 'Fantasy'],
    ),
  );
}

const _genres = [
  'Action', 'Romance', 'Fantasy', 'Horror', 'Comedy',
  'Sci-Fi', 'Slice of Life', 'Sports', 'Mystery', 'Thriller',
  'Isekai', 'Mecha', 'Historical', 'Supernatural', 'Drama',
];

// ── Section data ───────────────────────────────────────────────────────────────

class _Section {
  const _Section({required this.title, required this.items});

  final String title;
  final List<Manga> items;
}

// ── Screen ─────────────────────────────────────────────────────────────────────

/// Main discover / home content screen.
class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  bool _loading = false;
  late List<_Section> _sections;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _buildSections();
    _scrollController.addListener(_onScroll);
  }

  void _buildSections() {
    final library = ref.read(libraryProvider).valueOrNull ?? [];
    final continueReading = library.take(5).toList();

    _sections = [
      if (continueReading.isNotEmpty)
        _Section(title: 'Continue Reading', items: continueReading),
      _Section(title: 'Trending Today', items: _mockMangaList('Trending', 10)),
      _Section(title: 'Popular Manga', items: _mockMangaList('Popular', 10)),
      _Section(title: 'Recently Updated', items: _mockMangaList('Updated', 10)),
      _Section(title: 'New Releases', items: _mockMangaList('New', 10)),
      _Section(
          title: 'Recommended For You',
          items: _mockMangaList('Recommended', 10)),
      _Section(title: 'Top Rated', items: _mockMangaList('TopRated', 10)),
      _Section(title: 'Seasonal Picks', items: _mockMangaList('Seasonal', 10)),
    ];
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    // Infinite scroll: append more items to last section
    if (_loading) return;
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    setState(() {
      final last = _sections.last;
      _sections[_sections.length - 1] = _Section(
        title: last.title,
        items: [
          ...last.items,
          ..._mockMangaList('More', 5),
        ],
      );
      _loading = false;
    });
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;
    setState(() {
      _buildSections();
      _loading = false;
    });
  }

  void _navigateToRandom() {
    final allManga = _sections.expand((s) => s.items).toList();
    if (allManga.isEmpty) return;
    final random = allManga[math.Random().nextInt(allManga.length)];
    context.push('/manga/${random.id}');
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToRandom,
        backgroundColor: AppColors.primary,
        tooltip: 'Random Manga',
        child: const Icon(Icons.shuffle_rounded, color: Colors.white),
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: AppColors.surface,
        onRefresh: _refresh,
        child: _loading && _sections.isEmpty
            ? _buildSkeletons()
            : CustomScrollView(
                controller: _scrollController,
                slivers: [
                  // Genre chips
                  SliverToBoxAdapter(child: _GenreChips()),
                  // Sections
                  ..._sections.map(
                    (s) => SliverToBoxAdapter(
                      child: _HorizontalSection(section: s),
                    ),
                  ),
                  // Loading indicator at bottom
                  if (_loading)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: 80)),
                ],
              ),
      ),
    );
  }

  Widget _buildSkeletons() {
    return ListView.separated(
      padding: const EdgeInsets.only(top: 16),
      itemCount: 4,
      separatorBuilder: (_, __) => const SizedBox(height: 24),
      itemBuilder: (_, __) => const SectionSkeleton(),
    );
  }
}

// ── Genre chips ────────────────────────────────────────────────────────────────

class _GenreChips extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Text('Browse by Genre', style: AppTypography.titleMedium),
        ),
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _genres.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) => ActionChip(
              label: Text(
                _genres[i],
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.onSurface,
                ),
              ),
              backgroundColor: AppColors.surfaceVariant,
              side: BorderSide.none,
              onPressed: () {},
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

// ── Horizontal section ─────────────────────────────────────────────────────────

class _HorizontalSection extends StatelessWidget {
  const _HorizontalSection({required this.section});

  final _Section section;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(section.title, style: AppTypography.titleMedium),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'See All',
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Horizontal card list
        SizedBox(
          height: 230,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: section.items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (ctx, i) {
              final manga = section.items[i];
              return MangaCard(
                manga: manga,
                subtitle: 'Ch. ${(i + 1) * 10}',
                onTap: () => ctx.push('/manga/${manga.id}'),
              );
            },
          ),
        ),
      ],
    );
  }
}
