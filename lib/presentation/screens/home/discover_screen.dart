import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../domain/entities/manga.dart';
import '../../providers/discovery_provider.dart';
import '../../widgets/common/skeleton_loader.dart';
import '../../widgets/manga_card/manga_card.dart';

const _genres = [
  'Action', 'Romance', 'Fantasy', 'Horror', 'Comedy',
  'Sci-Fi', 'Slice of Life', 'Sports', 'Mystery', 'Thriller',
  'Isekai', 'Mecha', 'Historical', 'Supernatural', 'Drama',
];

class DiscoverScreen extends ConsumerWidget {
  const DiscoverScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asura = ref.watch(asuraLatestProvider);
    final reaper = ref.watch(reaperLatestProvider);
    final flame = ref.watch(flameLatestProvider);
    final mangadex = ref.watch(mangadexPopularProvider);
    final manganato = ref.watch(manganatoLatestProvider);

    // Collect all loaded manga for random pick
    final allLoaded = [
      ...asura.valueOrNull ?? [],
      ...reaper.valueOrNull ?? [],
      ...flame.valueOrNull ?? [],
      ...mangadex.valueOrNull ?? [],
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
          ref.invalidate(asuraLatestProvider);
          ref.invalidate(reaperLatestProvider);
          ref.invalidate(flameLatestProvider);
          ref.invalidate(mangadexPopularProvider);
          ref.invalidate(manganatoLatestProvider);
        },
        child: CustomScrollView(
          slivers: [
            // Genre chips
            SliverToBoxAdapter(child: _GenreChips()),

            // Asura Scans
            SliverToBoxAdapter(
              child: _MangaSection(
                title: 'Asura Scans',
                badge: '⚡',
                asyncValue: asura,
              ),
            ),

            // Reaper Scans
            SliverToBoxAdapter(
              child: _MangaSection(
                title: 'Reaper Scans',
                badge: '💀',
                asyncValue: reaper,
              ),
            ),

            // Flame Comics
            SliverToBoxAdapter(
              child: _MangaSection(
                title: 'Flame Comics',
                badge: '🔥',
                asyncValue: flame,
              ),
            ),

            // Manganato
            SliverToBoxAdapter(
              child: _MangaSection(
                title: 'Manganato',
                badge: '📚',
                asyncValue: manganato,
              ),
            ),

            // MangaDex
            SliverToBoxAdapter(
              child: _MangaSection(
                title: 'MangaDex Popular',
                badge: '🌐',
                asyncValue: mangadex,
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
    );
  }
}

class _GenreChips extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        scrollDirection: Axis.horizontal,
        itemCount: _genres.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (ctx, i) {
          final genre = _genres[i];
          return ActionChip(
            label: Text(genre),
            labelStyle: AppTypography.labelSmall.copyWith(
              color: Colors.white70,
            ),
            backgroundColor: AppColors.surface,
            onPressed: () => context.push('/search', extra: genre),
          );
        },
      ),
    );
  }
}

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
                onPressed: () => context.push('/search', extra: title),
                child: Text('See All', style: TextStyle(color: AppColors.primary)),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 230,
          child: asyncValue.when(
            loading: () => ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: 5,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, __) => const MangaCardSkeleton(),
            ),
            error: (e, __) => Center(child: Text('Error loading $title')),
            data: (items) {
              if (items.isEmpty) return const Center(child: Text('No results'));
              return ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (ctx, i) => MangaCard(manga: items[i]),
              );
            },
          ),
        ),
      ],
    );
  }
}
