import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import '../../domain/entities/chapter.dart';
import '../../domain/entities/manga.dart';
import '../../domain/entities/page.dart';

class ComixService {
  static const _base = 'https://comix.xyz';
  static final _client = http.Client();

  static const _headers = {
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Accept':
        'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8',
    'Referer': 'https://comix.xyz/',
  };

  static Future<List<Manga>> fetchLatest() async {
    try {
      final url = '$_base/latest';
      final response = await _client.get(Uri.parse(url), headers: _headers);
      print('Comix fetchLatest status: ${response.statusCode}');
      if (response.statusCode != 200) return [];

      final document = parser.parse(response.body);
      final items = document.querySelectorAll('.list-item, .manga-item, .bs');
      print('Comix items found: ${items.length}');

      return items
          .map((item) {
            final titleElement = item.querySelector('.title a');
            final title = titleElement?.text.trim() ?? 'Unknown';
            final href = titleElement?.attributes['href'] ?? '';
            final id = href.split('/').where((s) => s.isNotEmpty).last;
            final coverUrl =
                item.querySelector('img')?.attributes['src'] ??
                item.querySelector('img')?.attributes['data-src'] ??
                '';

            return Manga(
              id: id,
              sourceId: 'comix',
              title: title,
              coverUrl: coverUrl,
              status: MangaStatus.unknown,
            );
          })
          .where((m) => m.id.isNotEmpty)
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<List<Manga>> search(String query) async {
    try {
      final url = '$_base/search?q=${Uri.encodeComponent(query)}';
      final response = await _client.get(Uri.parse(url), headers: _headers);
      if (response.statusCode != 200) return [];

      final document = parser.parse(response.body);
      final items = document.querySelectorAll('.list-item');

      return items
          .map((item) {
            final titleElement = item.querySelector('.title a');
            final title = titleElement?.text.trim() ?? 'Unknown';
            final href = titleElement?.attributes['href'] ?? '';
            final id = href.split('/').where((s) => s.isNotEmpty).last;
            final coverUrl =
                item.querySelector('img')?.attributes['src'] ??
                item.querySelector('img')?.attributes['data-src'] ??
                '';

            return Manga(
              id: id,
              sourceId: 'comix',
              title: title,
              coverUrl: coverUrl,
              status: MangaStatus.unknown,
            );
          })
          .where((m) => m.id.isNotEmpty)
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<Manga?> fetchMangaById(String id) async {
    try {
      final url = '$_base/manga/$id';
      final response = await _client.get(Uri.parse(url), headers: _headers);
      if (response.statusCode != 200) return null;

      final document = parser.parse(response.body);
      final title = document.querySelector('h1')?.text.trim() ?? 'Unknown';
      final coverUrl =
          document.querySelector('.manga-cover img')?.attributes['src'] ?? '';
      final description =
          document.querySelector('.summary-content')?.text.trim() ?? '';

      return Manga(
        id: id,
        sourceId: 'comix',
        title: title,
        coverUrl: coverUrl,
        description: description,
        status: MangaStatus.unknown,
      );
    } catch (_) {
      return null;
    }
  }

  static Future<List<Chapter>> fetchChapterList(String mangaId) async {
    try {
      final url = '$_base/manga/$mangaId';
      final response = await _client.get(Uri.parse(url), headers: _headers);
      if (response.statusCode != 200) return [];

      final document = parser.parse(response.body);
      final items = document.querySelectorAll('.chapter-list li');

      final chapters = items.map((item) {
        final link = item.querySelector('a');
        final title = link?.text.trim() ?? '';
        final href = link?.attributes['href'] ?? '';
        final id = href.split('/').last;

        double chapterNumber = 0;
        final match = RegExp(
          r'Chapter\s*(\d+\.?\d*)',
          caseSensitive: false,
        ).firstMatch(title);
        if (match != null) {
          chapterNumber = double.tryParse(match.group(1) ?? '0') ?? 0;
        }

        return Chapter(
          id: id,
          mangaId: mangaId,
          sourceId: 'comix',
          chapterNumber: chapterNumber,
          title: title,
          isRead: false,
        );
      }).toList();

      chapters.sort((a, b) => a.chapterNumber.compareTo(b.chapterNumber));
      return chapters;
    } catch (_) {
      return [];
    }
  }

  static Future<List<Page>> fetchPages(String chapterId) async {
    try {
      final url = '$_base/chapter/$chapterId';
      final response = await _client.get(Uri.parse(url), headers: _headers);
      if (response.statusCode != 200) return [];

      final document = parser.parse(response.body);
      final images = document.querySelectorAll(
        '.reader-area img, .chapter-content img',
      );

      return images
          .asMap()
          .entries
          .map((entry) {
            final img = entry.value;
            final imageUrl =
                img.attributes['src'] ??
                img.attributes['data-src'] ??
                img.attributes['data-lazy-src'] ??
                '';
            return Page(index: entry.key, imageUrl: imageUrl.trim());
          })
          .where((p) => p.imageUrl.isNotEmpty)
          .toList();
    } catch (_) {
      return [];
    }
  }
}
