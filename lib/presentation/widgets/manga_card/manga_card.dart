import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../domain/entities/manga.dart';

/// A fixed-size card displaying a manga cover, title, and optional subtitle.
///
/// Used in horizontal scroll sections on the Discover screen, search results,
/// and library grids.
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

  /// Optional subtitle shown below the title (e.g. "Ch. 42" or "Updated 2h ago").
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
            // ── Cover image ──────────────────────────────────────────────
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
                        errorWidget: (_, __, ___) => _CoverPlaceholder(
                          title: manga.title,
                          width: width,
                          height: height,
                        ),
                      )
                    : _CoverPlaceholder(
                        title: manga.title,
                        width: width,
                        height: height,
                      ),
              ),
            ),
            const SizedBox(height: 6),
            // ── Title ────────────────────────────────────────────────────
            Text(
              manga.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.onSurface,
              ),
            ),
            // ── Subtitle ─────────────────────────────────────────────────
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                subtitle!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.labelSmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Shimmer placeholder ────────────────────────────────────────────────────────

class _ShimmerBox extends StatelessWidget {
  const _ShimmerBox({required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.surfaceVariant,
      highlightColor: AppColors.surface,
      child: Container(
        width: width,
        height: height,
        color: AppColors.surfaceVariant,
      ),
    );
  }
}

// ── Cover placeholder (no image) ──────────────────────────────────────────────

class _CoverPlaceholder extends StatelessWidget {
  const _CoverPlaceholder({
    required this.title,
    required this.width,
    required this.height,
  });

  final String title;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(8),
      child: Text(
        title,
        textAlign: TextAlign.center,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        style: AppTypography.labelSmall.copyWith(
          color: AppColors.onSurfaceMuted,
        ),
      ),
    );
  }
}
