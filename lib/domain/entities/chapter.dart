import 'package:flutter/foundation.dart';

/// Immutable domain entity representing a single chapter of a manga.
@immutable
class Chapter {
  final String id;
  final String mangaId;
  final String sourceId;
  final double chapterNumber;
  final String? title;
  final DateTime? uploadDate;
  final int? pageCount;
  final bool isRead;
  final bool isDownloaded;

  const Chapter({
    required this.id,
    required this.mangaId,
    required this.sourceId,
    required this.chapterNumber,
    this.title,
    this.uploadDate,
    this.pageCount,
    this.isRead = false,
    this.isDownloaded = false,
  });

  Chapter copyWith({
    String? id,
    String? mangaId,
    String? sourceId,
    double? chapterNumber,
    String? title,
    DateTime? uploadDate,
    int? pageCount,
    bool? isRead,
    bool? isDownloaded,
  }) {
    return Chapter(
      id: id ?? this.id,
      mangaId: mangaId ?? this.mangaId,
      sourceId: sourceId ?? this.sourceId,
      chapterNumber: chapterNumber ?? this.chapterNumber,
      title: title ?? this.title,
      uploadDate: uploadDate ?? this.uploadDate,
      pageCount: pageCount ?? this.pageCount,
      isRead: isRead ?? this.isRead,
      isDownloaded: isDownloaded ?? this.isDownloaded,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Chapter &&
        other.id == id &&
        other.mangaId == mangaId &&
        other.sourceId == sourceId &&
        other.chapterNumber == chapterNumber &&
        other.title == title &&
        other.uploadDate == uploadDate &&
        other.pageCount == pageCount &&
        other.isRead == isRead &&
        other.isDownloaded == isDownloaded;
  }

  @override
  int get hashCode => Object.hash(
        id,
        mangaId,
        sourceId,
        chapterNumber,
        title,
        uploadDate,
        pageCount,
        isRead,
        isDownloaded,
      );

  @override
  String toString() =>
      'Chapter(id: $id, mangaId: $mangaId, chapterNumber: $chapterNumber, '
      'isRead: $isRead, isDownloaded: $isDownloaded)';
}
