import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../domain/entities/manga.dart';

/// Neon gradient palettes for placeholder covers.
const _gradients = [
  [Color(0xFF7C3AED), Color(0xFF4F46E5)], // purple → indigo
  [Color(0xFF2563EB), Color(0xFF0891B2)], // blue → cyan
  [Color(0xFF059669), Color(0xFF0D9488)], // emerald → teal
  [Color(0xFFDC2626), Color(0xFF9333EA)], // red → purple
  [Color(0xFFD97706), Color(0xFFDC2626)], // amber → red
  [Color(0xFF7C3AED), Color(0xFF06B6D4)], // purple → cyan
  [Color(0xFF0891B2), Color(0xFF059669)], // cyan → green
  [Color(0xFF9333EA), Color(0xFFEC4899)], // purple → pink
];

class MangaCard extends StatelessWidget {
  const MangaCard({
    super.key,
    required this.manga,
    this.subtitle,
    this.onTap,
    this.width = 120,
    this.height = 180,
  });

  final Manga manga;
  final String? subtitle;
  final VoidCallback? onTap;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Cover
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: width,
                    height: height,
                    child: manga.coverUrl != null && manga.coverUrl!.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: manga.coverUrl!,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => _ShimmerBox(
                              width: width,
                              height: height,
                            ),
                            errorWidget: (_, __, ___) => _GradientPlaceholder(
                              title: manga.title,
                              width: width,
                              height: height,
                            ),
                          )
                        : _GradientPlaceholder(
                            title: manga.title,
                            width: width,
                            height: height,
                          ),
                  ),
                ),
                // Source label
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(150),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      manga.sourceId.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // Title
            Text(
              manga.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                subtitle!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Shimmer loading placeholder ────────────────────────────────────────────────

class _ShimmerBox extends StatelessWidget {
  const _ShimmerBox({required this.width, required this.height});
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFF1A1A2E),
      highlightColor: const Color(0xFF2D2D4E),
      child: Container(
        width: width,
        height: height,
        color: const Color(0xFF1A1A2E),
      ),
    );
  }
}

// ── Gradient placeholder (no cover image) ─────────────────────────────────────

class _GradientPlaceholder extends StatelessWidget {
  const _GradientPlaceholder({
    required this.title,
    required this.width,
    required this.height,
  });

  final String title;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    // Pick a consistent gradient based on title hash
    final gradientIndex = title.hashCode.abs() % _gradients.length;
    final colors = _gradients[gradientIndex];

    // First letter of title for the big initial
    final initial = title.isNotEmpty ? title[0].toUpperCase() : '?';

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          // Big faded initial in background
          Positioned(
            bottom: -10,
            right: -5,
            child: Text(
              initial,
              style: TextStyle(
                fontSize: 80,
                fontWeight: FontWeight.w900,
                color: Colors.white.withAlpha(30),
                height: 1,
              ),
            ),
          ),
          // Title text
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  title,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                    shadows: [
                      Shadow(
                        color: Colors.black54,
                        blurRadius: 4,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
