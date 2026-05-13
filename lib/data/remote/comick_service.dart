import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../domain/entities/chapter.dart';
import '../../domain/entities/manga.dart';
import '../../domain/entities/page.dart';

class ComickService {
  static const _base = 'https://api.comick.io';
  static const _imgBase = 'https://meo.comick.pictures';
  static final _client = http.Client();

  static const _headers = {
    'User-Agent': 'Zenshi/1.0 (Mozilla/5.0; Android 13)',
    'Accept': 'application/json',
  };

  static Future<List<Manga>> search(String query) async {
    try {
      final url = '$_base/v1.0/search?q=${Uri.encodeComponent(query)}&limit=20&t=1';
      final response = await _client.get(Uri.parse(url), headers: _headers);
      if (response.statusCode != 200) return [];

      final List<dynamic> data = jsonDecode(response.body);
      return data.map((item) => _parseManga(item)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<Manga?> fetchMangaBySlug(String slug) async {
    try {
      final url = '$_base/comic/$slug';
      final response = await _client.get(Uri.parse(url), headers: _headers);
      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body);
      return _parseManga(data['comic']);
    } catch (_) {
      return null;
    }
  }

  static Future<List<Chapter>> fetchChapterList(String hid) async {
    try {
      // Fetching all chapters using a very large limit and no pagination needed if limit is high enough
      final url = '$_base/comic/$hid/chapters?lang=en&limit=10000';
      final response = await _client.get(Uri.parse(url), headers: _headers);
      if (response.statusCode != 200) return [];

      final data = jsonDecode(response.body);
      final List<dynamic> chapters = data['chapters'] ?? [];
      
      final List<Chapter> result = [];
      final seen = <String>{};

      for (final item in chapters) {
        final chapNum = item['chap'] ?? '0';
        final vol = item['vol'] ?? '';
        final key = '${chapNum}_$vol';
        
        if (!seen.contains(key)) {
          result.add(Chapter(
            id: item['hid'],
            mangaId: hid,
            sourceId: 'comick',
            chapterNumber: double.tryParse(chapNum) ?? 0,
            title: item['title'],
            uploadDate: DateTime.tryParse(item['created_at'] ?? ''),
            pageCount: null,
            isRead: false,
          ));
          seen.add(key);
        }
      }
      
      // Sort chapters numerically: newest first
      result.sort((a, b) => b.chapterNumber.compareTo(a.chapterNumber));
      return result;
    } catch (_) {
      return [];
    }
  }

  static Future<List<Page>> fetchPages(String chapterHid) async {
    try {
      final url = '$_base/chapter/$chapterHid';
      final response = await _client.get(Uri.parse(url), headers: _headers);
      if (response.statusCode != 200) return [];

      final data = jsonDecode(response.body);
      final List<dynamic> images = data['chapter']['images'] ?? [];
      
      return images.asMap().entries.map((entry) {
        final img = entry.value;
        return Page(
          index: entry.key,
          imageUrl: '$_imgBase/${img['url']}',
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  static Manga _parseManga(Map<String, dynamic> item) {
    final cover = item['md_covers'] != null && (item['md_covers'] as List).isNotEmpty
        ? '$_imgBase/${item['md_covers'][0]['b2key']}'
        : (item['cover_url'] ?? '');

    return Manga(
      id: item['slug'] ?? item['hid'],
      sourceId: 'comick',
      title: item['title'] ?? 'Unknown',
      coverUrl: cover,
      author: item['authors'] != null && (item['authors'] as List).isNotEmpty 
          ? item['authors'][0]['name'] 
          : null,
      artist: null,
      description: item['desc'],
      status: _parseStatus(item['status']),
      genres: (item['genres'] as List?)?.map((g) => g['name'] as String).toList() ?? [],
      averageRating: (item['bayesian_rating'] as num?)?.toDouble(),
      isNsfw: item['content_rating'] == 'erotica' || item['content_rating'] == 'pornographic',
    );
  }

  static MangaStatus _parseStatus(int? status) {
    return switch (status) {
      1 => MangaStatus.ongoing,
      2 => MangaStatus.completed,
      3 => MangaStatus.hiatus,
      _ => MangaStatus.unknown,
    };
  }
}
