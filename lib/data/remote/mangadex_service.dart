import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../domain/entities/chapter.dart';
import '../../domain/entities/manga.dart';
import '../../domain/entities/page.dart';

/// Fetches real manga data from the MangaDex public API.
/// No API key required — MangaDex is free and open.
class MangaDexService {
  static const _base = 'https://api.mangadex.org';
  static const _coverBase = 'https://uploads.mangadex.org/covers';

  static final _client = http.Client();

  // Common headers to avoid 403/Blocked requests
  static const _headers = {
    'User-Agent': 'Zenshi/1.0 (Mozilla/5.0; Android 13)',
    'Accept': '*/*',
    'Accept-Language': 'en-US,en;q=0.9',
    'Origin': 'https://mangadex.org',
    'Referer': 'https://mangadex.org/',
  };

  // ── Fetch popular manga ────────────────────────────────────────────────────

  static Future<List<Manga>> fetchPopular({int limit = 10}) async {
    return _fetchManga(
      '$_base/manga?limit=$limit&order[followedCount]=desc'
      '&originalLanguage[]=ja' // Japanese manga only
      '&includes[]=cover_art&includes[]=author'
      '&contentRating[]=safe&contentRating[]=suggestive&contentRating[]=erotica&contentRating[]=pornographic',
    );
  }

  // ── Fetch popular manhwa (Korean) ─────────────────────────────────────────

  static Future<List<Manga>> fetchPopularManhwa({int limit = 10}) async {
    return _fetchManga(
      '$_base/manga?limit=$limit&order[followedCount]=desc'
      '&originalLanguage[]=ko' // Korean manhwa
      '&includes[]=cover_art&includes[]=author'
      '&contentRating[]=safe&contentRating[]=suggestive&contentRating[]=erotica&contentRating[]=pornographic',
    );
  }

  // ── Fetch popular manhua (Chinese) ────────────────────────────────────────

  static Future<List<Manga>> fetchPopularManhua({int limit = 10}) async {
    return _fetchManga(
      '$_base/manga?limit=$limit&order[followedCount]=desc'
      '&originalLanguage[]=zh&originalLanguage[]=zh-hk' // Chinese manhua
      '&includes[]=cover_art&includes[]=author'
      '&contentRating[]=safe&contentRating[]=suggestive&contentRating[]=erotica&contentRating[]=pornographic',
    );
  }

  // ── Fetch popular webtoons ────────────────────────────────────────────────

  static Future<List<Manga>> fetchPopularWebtoons({int limit = 10}) async {
    return _fetchManga(
      '$_base/manga?limit=$limit&order[followedCount]=desc'
      '&publicationDemographic[]=none' // Webtoon demographic
      '&originalLanguage[]=ko'
      '&includes[]=cover_art&includes[]=author'
      '&contentRating[]=safe&contentRating[]=suggestive&contentRating[]=erotica&contentRating[]=pornographic',
    );
  }

  // ── Fetch recently updated ─────────────────────────────────────────────────

  static Future<List<Manga>> fetchRecentlyUpdated({int limit = 10}) async {
    return _fetchManga(
      '$_base/manga?limit=$limit&order[latestUploadedChapter]=desc'
      '&includes[]=cover_art&includes[]=author'
      '&contentRating[]=safe&contentRating[]=suggestive&contentRating[]=erotica&contentRating[]=pornographic',
    );
  }

  // ── Fetch top rated ────────────────────────────────────────────────────────

  static Future<List<Manga>> fetchTopRated({int limit = 10}) async {
    return _fetchManga(
      '$_base/manga?limit=$limit&order[rating]=desc'
      '&includes[]=cover_art&includes[]=author'
      '&contentRating[]=safe&contentRating[]=suggestive&contentRating[]=erotica&contentRating[]=pornographic',
    );
  }

  // ── Fetch new releases ─────────────────────────────────────────────────────

  static Future<List<Manga>> fetchNewReleases({int limit = 10}) async {
    return _fetchManga(
      '$_base/manga?limit=$limit&order[createdAt]=desc'
      '&includes[]=cover_art&includes[]=author'
      '&contentRating[]=safe&contentRating[]=suggestive&contentRating[]=erotica&contentRating[]=pornographic',
    );
  }

  // ── Fetch seasonal (romance + fantasy) ────────────────────────────────────

  static Future<List<Manga>> fetchSeasonal({int limit = 10}) async {
    return _fetchManga(
      '$_base/manga?limit=$limit&order[followedCount]=desc'
      '&includedTags[]=4d32cc48-9f00-4cca-9b5a-a839f0764984' // Romance
      '&includes[]=cover_art&includes[]=author'
      '&contentRating[]=safe&contentRating[]=suggestive&contentRating[]=erotica&contentRating[]=pornographic',
    );
  }

  // ── Search ─────────────────────────────────────────────────────────────────

  static Future<List<Manga>> search(String query, {int limit = 20}) async {
    final encoded = Uri.encodeComponent(query);
    return _fetchManga(
      '$_base/manga?limit=$limit&title=$encoded'
      '&includes[]=cover_art&includes[]=author'
      '&contentRating[]=safe&contentRating[]=suggestive&contentRating[]=erotica&contentRating[]=pornographic',
    );
  }

  // ── Fetch manga details by ID ──────────────────────────────────────────────

  static Future<Manga?> fetchMangaById(String mangaId) async {
    try {
      final response = await _client
          .get(
            Uri.parse(
              '$_base/manga/$mangaId?includes[]=cover_art&includes[]=author&includes[]=artist',
            ),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) return null;
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final item = data['data'] as Map<String, dynamic>?;
      if (item == null) return null;
      return _parseManga(item);
    } catch (_) {
      return null;
    }
  }

  // ── Fetch chapter list for a manga ────────────────────────────────────────

  static Future<List<Chapter>> fetchChapterList(String mangaId) async {
    try {
      final chapters = <Chapter>[];
      int offset = 0;
      const limit = 100;

      // Fetch up to 1000 chapters (10 pages) to ensure completeness
      for (int page = 0; page < 10; page++) {
        final url =
            '$_base/manga/$mangaId/feed'
            '?limit=$limit&offset=$offset'
            '&translatedLanguage[]=en'
            '&order[chapter]=desc'
            '&includes[]=scanlation_group'
            '&contentRating[]=safe&contentRating[]=suggestive&contentRating[]=erotica&contentRating[]=pornographic';

        final response = await _client
            .get(Uri.parse(url), headers: _headers)
            .timeout(const Duration(seconds: 10));

        if (response.statusCode != 200) break;

        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final results = data['data'] as List<dynamic>? ?? [];
        final total = (data['total'] as num?)?.toInt() ?? 0;

        for (final item in results) {
          final ch = _parseChapter(item as Map<String, dynamic>, mangaId);
          // Only add chapters that have at least one page
          if (ch != null && (ch.pageCount == null || ch.pageCount! > 0)) {
            chapters.add(ch);
          }
        }

        offset += limit;
        if (offset >= total) break;
      }

      return chapters;
    } catch (_) {
      return [];
    }
  }

  // ── Fetch pages for a chapter ──────────────────────────────────────────────

  static Future<List<Page>> fetchPages(String chapterId) async {
    try {
      final response = await _client
          .get(Uri.parse('$_base/at-home/server/$chapterId'), headers: _headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) return [];

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final baseUrl = data['baseUrl'] as String? ?? '';
      final chapter = data['chapter'] as Map<String, dynamic>? ?? {};
      final hash = chapter['hash'] as String? ?? '';
      final pageFiles = chapter['data'] as List<dynamic>? ?? [];

      return pageFiles.asMap().entries.map((entry) {
        final index = entry.key;
        final fileName = entry.value as String;
        return Page(index: index, imageUrl: '$baseUrl/data/$hash/$fileName');
      }).toList();
    } catch (_) {
      return [];
    }
  }

  // ── Private fetch helper ───────────────────────────────────────────────────

  static Future<List<Manga>> _fetchManga(String url) async {
    try {
      final response = await _client
          .get(Uri.parse(url), headers: _headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        // Log error if status is not 200 (e.g. 403, 429)
        print('MangaDex API Error: ${response.statusCode} for $url');
        return [];
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final results = data['data'] as List<dynamic>? ?? [];

      return results
          .map((item) => _parseManga(item as Map<String, dynamic>))
          .whereType<Manga>()
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Manga? _parseManga(Map<String, dynamic> item) {
    try {
      final id = item['id'] as String;
      final attrs = item['attributes'] as Map<String, dynamic>;

      // Title — prefer English, fall back to first available
      final titleMap = attrs['title'] as Map<String, dynamic>? ?? {};
      final title =
          (titleMap['en'] ??
                  titleMap.values.firstWhere(
                    (v) => v != null && (v as String).isNotEmpty,
                    orElse: () => 'Unknown',
                  ))
              .toString();

      // Description
      final descMap = attrs['description'] as Map<String, dynamic>? ?? {};
      final description = (descMap['en'] ?? descMap.values.firstOrNull ?? '')
          .toString();

      // Status
      final statusStr = attrs['status'] as String? ?? 'unknown';
      final status = switch (statusStr) {
        'ongoing' => MangaStatus.ongoing,
        'completed' => MangaStatus.completed,
        'hiatus' => MangaStatus.hiatus,
        _ => MangaStatus.unknown,
      };

      // Genres from tags
      final tags = attrs['tags'] as List<dynamic>? ?? [];
      final genres = tags
          .map((t) {
            final tagAttrs = (t as Map)['attributes'] as Map<String, dynamic>?;
            final nameMap = tagAttrs?['name'] as Map<String, dynamic>? ?? {};
            return (nameMap['en'] ?? '').toString();
          })
          .where((g) => g.isNotEmpty)
          .take(5)
          .toList();

      // Cover URL from relationships
      final relationships = item['relationships'] as List<dynamic>? ?? [];
      String? coverUrl;
      String? author;
      String? artist;

      for (final rel in relationships) {
        final relMap = rel as Map<String, dynamic>;
        if (relMap['type'] == 'cover_art') {
          final relAttrs = relMap['attributes'] as Map<String, dynamic>?;
          final fileName = relAttrs?['fileName'] as String?;
          if (fileName != null) {
            coverUrl = '$_coverBase/$id/$fileName.512.jpg';
          }
        }
        if (relMap['type'] == 'author') {
          final relAttrs = relMap['attributes'] as Map<String, dynamic>?;
          author = relAttrs?['name'] as String?;
        }
        if (relMap['type'] == 'artist') {
          final relAttrs = relMap['attributes'] as Map<String, dynamic>?;
          artist = relAttrs?['name'] as String?;
        }
      }

      // Rating
      final stats = attrs['rating'] as Map<String, dynamic>?;
      final rating = (stats?['average'] as num?)?.toDouble();

      final contentRating = attrs['contentRating'] as String?;
      final isNsfw =
          contentRating == 'erotica' || contentRating == 'pornographic';

      return Manga(
        id: id,
        sourceId: 'mangadex',
        title: title,
        coverUrl: coverUrl,
        author: author,
        artist: artist,
        description: description.isNotEmpty ? description : null,
        status: status,
        genres: genres,
        averageRating: rating,
        isNsfw: isNsfw,
      );
    } catch (_) {
      return null;
    }
  }

  static Chapter? _parseChapter(Map<String, dynamic> item, String mangaId) {
    try {
      final id = item['id'] as String;
      final attrs = item['attributes'] as Map<String, dynamic>;

      final chapterStr = attrs['chapter'] as String?;
      final chapterNum = double.tryParse(chapterStr ?? '') ?? 0;
      final title = attrs['title'] as String?;
      final publishAt = attrs['publishAt'] as String?;
      final pages = (attrs['pages'] as num?)?.toInt();

      return Chapter(
        id: id,
        mangaId: mangaId,
        sourceId: 'mangadex',
        chapterNumber: chapterNum,
        title: title,
        uploadDate: publishAt != null ? DateTime.tryParse(publishAt) : null,
        pageCount: pages,
        isRead: false,
        isDownloaded: false,
      );
    } catch (_) {
      return null;
    }
  }
}
