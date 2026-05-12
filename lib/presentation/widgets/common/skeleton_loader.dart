import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/constants/app_colors.dart';

// ── Base shimmer box ───────────────────────────────────────────────────────────

/// A single shimmer-animated rectangle. Use as a building block for skeletons.
class ShimmerBox extends StatelessWidget {
  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
  });

  final double width;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.surfaceVariant,
      highlightColor: const Color(0xFF2A2A2A),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

// ── Manga card skeleton ────────────────────────────────────────────────────────

/// Skeleton placeholder matching the size of a [MangaCard].
class MangaCardSkeleton extends StatelessWidget {
  const MangaCardSkeleton({
    super.key,
    this.width = 120,
    this.height = 180,
  });

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          ShimmerBox(width: width, height: height, borderRadius: 12),
          const SizedBox(height: 6),
          ShimmerBox(width: width * 0.9, height: 12),
          const SizedBox(height: 4),
          ShimmerBox(width: width * 0.6, height: 10),
        ],
      ),
    );
  }
}

// ── Section skeleton ───────────────────────────────────────────────────────────

/// Skeleton for a full horizontal-scroll section (title + row of cards).
class SectionSkeleton extends StatelessWidget {
  const SectionSkeleton({
    super.key,
    this.cardCount = 5,
    this.cardWidth = 120,
    this.cardHeight = 180,
  });

  final int cardCount;
  final double cardWidth;
  final double cardHeight;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title shimmer
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ShimmerBox(width: 140, height: 18),
              ShimmerBox(width: 60, height: 14),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Horizontal card row
        SizedBox(
          height: cardHeight + 50,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: cardCount,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, __) => MangaCardSkeleton(
              width: cardWidth,
              height: cardHeight,
            ),
          ),
        ),
      ],
    );
  }
}
