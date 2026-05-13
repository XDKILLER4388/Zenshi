import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../domain/entities/manga.dart';
import '../../providers/mangadex_provider.dart';
import '../../widgets/common/skeleton_loader.dart';
import '../../widgets/manga_card/manga_card.dart';

const _genres = [
  'Action',
  'Romance',
  'Fantasy',
  'Horror',
  'Comedy',
  'Sci-Fi',
  'Slice of Life',
  'Sports',
  'Mystery',
  'Thriller',
  'Isekai',
  'Mecha',
  'Historical',
  'Supernatural',
  'Drama',
];

class DiscoverScreen extends ConsumerWidget {
  const DiscoverScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trending = ref.watch(trendingProvider);
    final popular = ref.watch(popularMangaProvider);
    final manhwa = ref.watch(popularManhwaProvider);
    final manhua = ref.watch(popularManhuaProvider);
    final webtoons = ref.watch(popularWebtoonsProvider);
    final recent = ref.watch(recentlyUpdatedProvider);
    final newReleases = ref.watch(newReleasesProvider);
    final topRated = ref.watch(topRatedProvider);
    final seasonal = ref.watch(seasonalProvider);

    // Collect all loaded manga for random pick
    final allLoaded = [
      ...trending.valueOrNull ?? [],
      ...popular.valueOrNull ?? [],
      ...manhwa.valueOrNull ?? [],
      ...manhua.valueOrNull ?? [],
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (allLoaded.isNotEmpty) {
            final pick = allLoaded[math.Random().nextInt(allLoaded.length)];
            context.push('/manga-details/${pick.sourceId}/${pick.id}');
          }
        },
        backgroundColor: AppColors.primary,
        tooltip: 'Random',
        child: const Icon(Icons.shuffle_rounded, color: Colors.white),
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: AppColors.surface,
        onRefresh: () async {
          ref.invalidate(trendingProvider);
          ref.invalidate(popularMangaProvider);
          ref.invalidate(popularManhwaProvider);
          ref.invalidate(popularManhuaProvider);
          ref.invalidate(popularWebtoonsProvider);
          ref.invalidate(recentlyUpdatedProvider);
          ref.invalidate(newReleasesProvider);
          ref.invalidate(topRatedProvider);
          ref.invalidate(seasonalProvider);
        },
        child: CustomScrollView(
          slivers: [
            // Genre chips
            SliverToBoxAdapter(child: _GenreChips()),

            // Trending Today
            SliverToBoxAdapter(
              child: _MangaSection(
                title: 'Trending Today',
                badge: '🔥',
                asyncValue: trending,
              ),
            ),

            // Popular Manga (Japanese)
            SliverToBoxAdapter(
              child: _MangaSection(
                title: 'Popular Manga',
                badge: '🇯🇵',
                asyncValue: popular,
              ),
            ),

            // Popular Manhwa (Korean)
            SliverToBoxAdapter(
              child: _MangaSection(
                title: 'Popular Manhwa',
                badge: '🇰🇷',
                asyncValue: manhwa,
              ),
            ),

            // Popular Manhua (Chinese)
            SliverToBoxAdapter(
              child: _MangaSection(
                title: 'Popular Manhua',
                badge: '🇨🇳',
                asyncValue: manhua,
              ),
            ),

            // Webtoons
            SliverToBoxAdapter(
              child: _MangaSection(
                title: 'Webtoons',
                badge: '📱',
                asyncValue: webtoons,
              ),
            ),

            // Recently Updated
            SliverToBoxAdapter(
              child: _MangaSection(
                title: 'Recently Updated',
                badge: '🆕',
                asyncValue: recent,
              ),
            ),

            // New Releases
            SliverToBoxAdapter(
              child: _MangaSection(
                title: 'New Releases',
                asyncValue: newReleases,
              ),
            ),

            // Top Rated
            SliverToBoxAdapter(
              child: _MangaSection(
                title: 'Top Rated',
                badge: '⭐',
                asyncValue: topRated,
              ),
            ),

            // Seasonal Picks
            SliverToBoxAdapter(
              child: _MangaSection(
                title: 'Seasonal Picks',
                badge: '🌸',
                asyncValue: seasonal,
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
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

// ── Manga section ──────────────────────────────────────────────────────────────

class _MangaSection extends StatelessWidget {
  const _MangaSection({
    required this.title,
    required this.asyncValue,
    this.badge,
  });

  final String title;
  final String? badge;
  final AsyncValue<List<Manga>> asyncValue;

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
              Row(
                children: [
                  if (badge != null) ...[
                    Text(badge!, style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 6),
                  ],
                  Text(title, style: AppTypography.titleMedium),
                ],
              ),
              TextButton(
                onPressed: () {
                  context.push('/search', extra: title);
                },
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

        // Content
        SizedBox(
          height: 230,
          child: asyncValue.when(
            loading: () => ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: 6,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, __) => const MangaCardSkeleton(),
            ),
            error: (_, __) => _ErrorRow(sectionTitle: title),
            data: (items) {
              if (items.isEmpty) return _ErrorRow(sectionTitle: title);
              return ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (ctx, i) {
                  final manga = items[i];
                  return MangaCard(manga: manga);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

// ── Error row ──────────────────────────────────────────────────────────────────

class _ErrorRow extends StatelessWidget {
  const _ErrorRow({required this.sectionTitle});
  final String sectionTitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.wifi_off_rounded,
            color: AppColors.onSurfaceMuted,
            size: 28,
          ),
          const SizedBox(height: 8),
          Text('Could not load $sectionTitle', style: AppTypography.bodySmall),
        ],
      ),
    );
  }
}
