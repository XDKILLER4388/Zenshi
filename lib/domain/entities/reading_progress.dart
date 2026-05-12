import 'package:flutter/foundation.dart';

/// Immutable domain entity tracking the user's reading position for a manga.
@immutable
class ReadingProgress {
  final String id;
  final String mangaId;
  final String chapterId;
  final int pageIndex;
  final DateTime updatedAt;

  /// Null until the record has been synced to the remote backend.
  final DateTime? syncedAt;

  const ReadingProgress({
    required this.id,
    required this.mangaId,
    required this.chapterId,
    required this.pageIndex,
    required this.updatedAt,
    this.syncedAt,
  });

  ReadingProgress copyWith({
    String? id,
    String? mangaId,
    String? chapterId,
    int? pageIndex,
    DateTime? updatedAt,
    DateTime? syncedAt,
  }) {
    return ReadingProgress(
      id: id ?? this.id,
      mangaId: mangaId ?? this.mangaId,
      chapterId: chapterId ?? this.chapterId,
      pageIndex: pageIndex ?? this.pageIndex,
      updatedAt: updatedAt ?? this.updatedAt,
      syncedAt: syncedAt ?? this.syncedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ReadingProgress &&
        other.id == id &&
        other.mangaId == mangaId &&
        other.chapterId == chapterId &&
        other.pageIndex == pageIndex &&
        other.updatedAt == updatedAt &&
        other.syncedAt == syncedAt;
  }

  @override
  int get hashCode => Object.hash(
        id,
        mangaId,
        chapterId,
        pageIndex,
        updatedAt,
        syncedAt,
      );

  @override
  String toString() =>
      'ReadingProgress(id: $id, mangaId: $mangaId, chapterId: $chapterId, '
      'pageIndex: $pageIndex, updatedAt: $updatedAt)';
}
