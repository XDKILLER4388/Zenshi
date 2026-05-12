import 'package:flutter/foundation.dart';

/// Immutable domain entity encapsulating all search parameters.
@immutable
class SearchQuery {
  final String query;

  /// Null means global search across all installed extensions.
  final String? sourceId;

  final List<String> genres;

  /// One of: 'ongoing', 'completed', 'hiatus', or null for any.
  final String? status;

  final String? author;
  final String? language;
  final int? year;
  final double? minRating;
  final bool showNsfw;

  const SearchQuery({
    required this.query,
    this.sourceId,
    this.genres = const [],
    this.status,
    this.author,
    this.language,
    this.year,
    this.minRating,
    this.showNsfw = false,
  });

  /// Returns an empty search query with all filters cleared.
  static SearchQuery get empty => const SearchQuery(query: '');

  SearchQuery copyWith({
    String? query,
    String? sourceId,
    List<String>? genres,
    String? status,
    String? author,
    String? language,
    int? year,
    double? minRating,
    bool? showNsfw,
  }) {
    return SearchQuery(
      query: query ?? this.query,
      sourceId: sourceId ?? this.sourceId,
      genres: genres ?? this.genres,
      status: status ?? this.status,
      author: author ?? this.author,
      language: language ?? this.language,
      year: year ?? this.year,
      minRating: minRating ?? this.minRating,
      showNsfw: showNsfw ?? this.showNsfw,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SearchQuery &&
        other.query == query &&
        other.sourceId == sourceId &&
        listEquals(other.genres, genres) &&
        other.status == status &&
        other.author == author &&
        other.language == language &&
        other.year == year &&
        other.minRating == minRating &&
        other.showNsfw == showNsfw;
  }

  @override
  int get hashCode => Object.hash(
        query,
        sourceId,
        Object.hashAll(genres),
        status,
        author,
        language,
        year,
        minRating,
        showNsfw,
      );

  @override
  String toString() =>
      'SearchQuery(query: "$query", sourceId: $sourceId, genres: $genres, '
      'status: $status, showNsfw: $showNsfw)';
}
