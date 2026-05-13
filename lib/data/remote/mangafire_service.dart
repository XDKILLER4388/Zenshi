import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import '../../domain/entities/chapter.dart';
import '../../domain/entities/manga.dart';
import '../../domain/entities/page.dart';

class MangaFireService {
  static const _base = 'https://mangafire.to';
  static final _client = http.Client();

  static const _headers = {
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Accept':
        'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8',
    'Referer': 'https://mangafire.to/',
  };

  static Future<List<Manga>> fetchLatest() async {
    try {
      final url = '$_base/filter?sort=recently_updated';
      final response = await _client.get(Uri.parse(url), headers: _headers);

      print('MangaFire fetchLatest status: ${response.statusCode}');
      if (response.statusCode != 200) {
        print('MangaFire error: ${response.body.substring(0, 100)}');
        return [];
      }

      final document = parser.parse(response.body);
      final items = document.querySelectorAll('.inner, .unit');
      print('MangaFire items found: ${items.length}');

      return items
          .map((item) {
            final titleElement = item.querySelector('.info > a');
            final title = titleElement?.text.trim() ?? 'Unknown';
            final href = titleElement?.attributes['href'] ?? '';
            final id = href.split('/').where((s) => s.isNotEmpty).last;
            final coverUrl =
                item.querySelector('img')?.attributes['src'] ??
                item.querySelector('img')?.attributes['data-src'] ??
                '';

            return Manga(
              id: id,
              sourceId: 'mangafire',
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
      final url = '$_base/filter?keyword=${Uri.encodeComponent(query)}';
      final response = await _client.get(Uri.parse(url), headers: _headers);
      if (response.statusCode != 200) return [];

      final document = parser.parse(response.body);
      final items = document.querySelectorAll('.inner');

      return items
          .map((item) {
            final titleElement = item.querySelector('.info > a');
            final title = titleElement?.text.trim() ?? 'Unknown';
            final href = titleElement?.attributes['href'] ?? '';
            final id = href.split('/').where((s) => s.isNotEmpty).last;
            final coverUrl =
                item.querySelector('img')?.attributes['src'] ??
                item.querySelector('img')?.attributes['data-src'] ??
                '';

            return Manga(
              id: id,
              sourceId: 'mangafire',
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

  static Future<Manga?> fetchDetails(String mangaId) async {
    try {
      final url = '$_base/manga/$mangaId';
      final response = await _client.get(Uri.parse(url), headers: _headers);
      if (response.statusCode != 200) return null;

      final document = parser.parse(response.body);
      final info = document.querySelector('.info');
      final title = info?.querySelector('h1')?.text.trim() ?? '';
      final description =
          info?.querySelector('.description')?.text.trim() ?? '';
      final coverUrl =
          document.querySelector('.poster img')?.attributes['src'] ?? '';

      return Manga(
        id: mangaId,
        sourceId: 'mangafire',
        title: title,
        coverUrl: coverUrl,
        description: description,
        status: MangaStatus.unknown,
      );
    } catch (_) {
      return null;
    }
  }

  static Future<List<Chapter>> fetchChapters(String mangaId) async {
    try {
      final url = '$_base/manga/$mangaId';
      final response = await _client.get(Uri.parse(url), headers: _headers);
      if (response.statusCode != 200) return [];

      final document = parser.parse(response.body);
      final chapterItems = document.querySelectorAll('.chapters li a');

      return chapterItems.map<Chapter>((item) {
        final title = item.text.trim();
        final href = item.attributes['href'] ?? '';
        final id = href.split('/').where((s) => s.isNotEmpty).last;

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
          sourceId: 'mangafire',
          chapterNumber: chapterNumber,
          title: title,
          uploadDate: DateTime.now(),
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<List<Page>> fetchPages(String chapterId) async {
    try {
      final url = '$_base/read/$chapterId';
      final response = await _client.get(Uri.parse(url), headers: _headers);
      if (response.statusCode != 200) return [];

      final document = parser.parse(response.body);
      final images = document.querySelectorAll(
        '#readerarea img, .read-content img',
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
