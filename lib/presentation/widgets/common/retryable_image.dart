import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';

/// A [CachedNetworkImage] wrapper with automatic retry logic.
///
/// Retry behaviour (per Requirement 7.6):
/// - **First failure**: automatically retries after a 1-second delay.
/// - **Second failure**: shows a broken-image placeholder with a manual
///   "Retry" button that resets the attempt counter and tries again.
class RetryableImage extends StatefulWidget {
  const RetryableImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.placeholder,
  });

  /// The image URL to load.
  final String url;

  /// How the image should be inscribed into the available space.
  final BoxFit fit;

  final double? width;
  final double? height;

  /// Optional custom placeholder shown while loading.
  final Widget? placeholder;

  @override
  State<RetryableImage> createState() => _RetryableImageState();
}

class _RetryableImageState extends State<RetryableImage> {
  /// Number of load failures so far for the current [_cacheKey].
  int _failureCount = 0;

  /// Changing the cache key forces [CachedNetworkImage] to reload.
  late int _cacheKey;

  Timer? _retryTimer;

  @override
  void initState() {
    super.initState();
    _cacheKey = 0;
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    super.dispose();
  }

  // ── Retry logic ────────────────────────────────────────────────────────

  void _onLoadError() {
    if (!mounted) return;
    _failureCount++;

    if (_failureCount == 1) {
      // First failure: auto-retry after 1 second.
      _retryTimer = Timer(const Duration(seconds: 1), () {
        if (mounted) {
          setState(() => _cacheKey++);
        }
      });
    }
    // Second+ failure: the error widget is shown (manual retry button).
    // No automatic action — wait for user interaction.
    if (_failureCount >= 2) {
      setState(() {}); // Trigger rebuild to show manual retry UI.
    }
  }

  void _manualRetry() {
    setState(() {
      _failureCount = 0;
      _cacheKey++;
    });
  }

  // ── Build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // After 2+ failures, show the broken-image placeholder with retry button.
    if (_failureCount >= 2) {
      return _BrokenImagePlaceholder(
        width: widget.width,
        height: widget.height,
        onRetry: _manualRetry,
      );
    }

    return CachedNetworkImage(
      key: ValueKey('${widget.url}_$_cacheKey'),
      imageUrl: widget.url,
      fit: widget.fit,
      width: widget.width,
      height: widget.height,
      placeholder: (context, url) =>
          widget.placeholder ?? _DefaultPlaceholder(
            width: widget.width,
            height: widget.height,
          ),
      errorWidget: (context, url, error) {
        // Schedule the error handler after the current frame to avoid
        // calling setState during build.
        WidgetsBinding.instance.addPostFrameCallback((_) => _onLoadError());
        return _DefaultPlaceholder(
          width: widget.width,
          height: widget.height,
        );
      },
    );
  }
}

// ── Broken-image placeholder ───────────────────────────────────────────────────

class _BrokenImagePlaceholder extends StatelessWidget {
  const _BrokenImagePlaceholder({
    this.width,
    this.height,
    required this.onRetry,
  });

  final double? width;
  final double? height;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: AppColors.surfaceVariant,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.broken_image_outlined,
            size: 48,
            color: AppColors.onSurfaceMuted,
          ),
          const SizedBox(height: 8),
          Text(
            'Failed to load',
            style: AppTypography.bodySmall,
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Retry'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Default loading placeholder ────────────────────────────────────────────────

class _DefaultPlaceholder extends StatelessWidget {
  const _DefaultPlaceholder({this.width, this.height});

  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: AppColors.surfaceVariant,
      child: const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: AppColors.primary,
        ),
      ),
    );
  }
}
