import 'package:flutter/foundation.dart';

enum MangaStatus { ongoing, completed, hiatus, unknown }

/// Immutable domain entity representing a manga title.
@immutable
class Manga {
  final String id;
  final String sourceId;
  final String title;
  final String? coverUrl;
  final String? author;
  final String? artist;
  final String? description;
  final MangaStatus status;
  final List<String> genres;
  final double? averageRating;
  final bool isNsfw;
  final bool inLibrary;
  final DateTime? lastUpdated;

  const Manga({
    required this.id,
    required this.sourceId,
    required this.title,
    this.coverUrl,
    this.author,
    this.artist,
    this.description,
    this.status = MangaStatus.unknown,
    this.genres = const [],
    this.averageRating,
    this.isNsfw = false,
    this.inLibrary = false,
    this.lastUpdated,
  });

  Manga copyWith({
    String? id,
    String? sourceId,
    String? title,
    String? coverUrl,
    String? author,
    String? artist,
    String? description,
    MangaStatus? status,
    List<String>? genres,
    double? averageRating,
    bool? isNsfw,
    bool? inLibrary,
    DateTime? lastUpdated,
  }) {
    return Manga(
      id: id ?? this.id,
      sourceId: sourceId ?? this.sourceId,
      title: title ?? this.title,
      coverUrl: coverUrl ?? this.coverUrl,
      author: author ?? this.author,
      artist: artist ?? this.artist,
      description: description ?? this.description,
      status: status ?? this.status,
      genres: genres ?? this.genres,
      averageRating: averageRating ?? this.averageRating,
      isNsfw: isNsfw ?? this.isNsfw,
      inLibrary: inLibrary ?? this.inLibrary,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Manga &&
        other.id == id &&
        other.sourceId == sourceId &&
        other.title == title &&
        other.coverUrl == coverUrl &&
        other.author == author &&
        other.artist == artist &&
        other.description == description &&
        other.status == status &&
        listEquals(other.genres, genres) &&
        other.averageRating == averageRating &&
        other.isNsfw == isNsfw &&
        other.inLibrary == inLibrary &&
        other.lastUpdated == lastUpdated;
  }

  @override
  int get hashCode => Object.hash(
        id,
        sourceId,
        title,
        coverUrl,
        author,
        artist,
        description,
        status,
        Object.hashAll(genres),
        averageRating,
        isNsfw,
        inLibrary,
        lastUpdated,
      );

  @override
  String toString() => 'Manga(id: $id, sourceId: $sourceId, title: $title, '
      'status: $status, inLibrary: $inLibrary, isNsfw: $isNsfw)';
}
