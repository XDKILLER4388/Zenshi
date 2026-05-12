import 'package:flutter/foundation.dart';
import 'app_settings.dart';

enum DownloadStatus { queued, downloading, paused, completed, failed }

/// Immutable domain entity representing a chapter download task.
@immutable
class DownloadTask {
  final String id;
  final String chapterId;
  final String mangaId;
  final String mangaTitle;
  final double chapterNumber;
  final ImageQuality quality;
  final DownloadStatus status;
  final int totalPages;
  final int downloadedPages;
  final DateTime createdAt;
  final DateTime? completedAt;

  const DownloadTask({
    required this.id,
    required this.chapterId,
    required this.mangaId,
    required this.mangaTitle,
    required this.chapterNumber,
    required this.quality,
    required this.status,
    required this.totalPages,
    required this.downloadedPages,
    required this.createdAt,
    this.completedAt,
  });

  /// Download progress as a fraction in [0.0, 1.0].
  double get progressPercent =>
      totalPages == 0 ? 0 : downloadedPages / totalPages;

  DownloadTask copyWith({
    String? id,
    String? chapterId,
    String? mangaId,
    String? mangaTitle,
    double? chapterNumber,
    ImageQuality? quality,
    DownloadStatus? status,
    int? totalPages,
    int? downloadedPages,
    DateTime? createdAt,
    DateTime? completedAt,
  }) {
    return DownloadTask(
      id: id ?? this.id,
      chapterId: chapterId ?? this.chapterId,
      mangaId: mangaId ?? this.mangaId,
      mangaTitle: mangaTitle ?? this.mangaTitle,
      chapterNumber: chapterNumber ?? this.chapterNumber,
      quality: quality ?? this.quality,
      status: status ?? this.status,
      totalPages: totalPages ?? this.totalPages,
      downloadedPages: downloadedPages ?? this.downloadedPages,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DownloadTask &&
        other.id == id &&
        other.chapterId == chapterId &&
        other.mangaId == mangaId &&
        other.mangaTitle == mangaTitle &&
        other.chapterNumber == chapterNumber &&
        other.quality == quality &&
        other.status == status &&
        other.totalPages == totalPages &&
        other.downloadedPages == downloadedPages &&
        other.createdAt == createdAt &&
        other.completedAt == completedAt;
  }

  @override
  int get hashCode => Object.hash(
        id,
        chapterId,
        mangaId,
        mangaTitle,
        chapterNumber,
        quality,
        status,
        totalPages,
        downloadedPages,
        createdAt,
        completedAt,
      );

  @override
  String toString() =>
      'DownloadTask(id: $id, chapterId: $chapterId, status: $status, '
      'progress: ${(progressPercent * 100).toStringAsFixed(1)}%)';
}
