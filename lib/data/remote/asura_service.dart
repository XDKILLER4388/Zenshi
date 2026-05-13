import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import '../../domain/entities/chapter.dart';
import '../../domain/entities/manga.dart';
import '../../domain/entities/page.dart';

class AsuraService {
  static const _base = 'https://asuracomic.net';
  static final _client = http.Client();

  static const _headers = {
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36',
    'Accept':
        'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8',
    'Referer': 'https://asuracomic.net/',
  };

  static Future<List<Manga>> fetchLatest() async {
    try {
      final url = '$_base';
      final response = await _client.get(Uri.parse(url), headers: _headers);

      print('Asura fetchLatest: ${response.statusCode}');
      if (response.statusCode != 200) {
        print('Asura Error Body: ${response.body.take(200)}');
        return [];
      }

      final document = parser.parse(response.body);
      // Asura updated selector for their new site layout
      final items = document.querySelectorAll(
        '.grid-cols-2 > div, .listupd .bs, .utao .uta',
      );
      print('Asura items found: ${items.length}');

      return items
          .map((item) {
            final title =
                item.querySelector('.tt, h3, .title')?.text.trim() ?? 'Unknown';
            final href = item.querySelector('a')?.attributes['href'] ?? '';
            final id = href.split('/').where((s) => s.isNotEmpty).last;
            final coverUrl =
                item.querySelector('img')?.attributes['src'] ??
                item.querySelector('img')?.attributes['data-src'] ??
                '';

            return Manga(
              id: id,
              sourceId: 'asura',
              title: title,
              coverUrl: coverUrl,
              status: MangaStatus.unknown,
            );
          })
          .where((m) => m.id.isNotEmpty)
          .toList();
    } catch (e) {
      print('Asura Exception: $e');
      return [];
    }
  }

  static Future<List<Manga>> search(String query) async {
    try {
      final url = '$_base/search?q=${Uri.encodeComponent(query)}';
      final response = await _client.get(Uri.parse(url), headers: _headers);
      if (response.statusCode != 200) return [];

      final document = parser.parse(response.body);
      final items = document.querySelectorAll('.item');

      return items.map((item) {
        final title = item.querySelector('.title')?.text.trim() ?? 'Unknown';
        final href = item.querySelector('a')?.attributes['href'] ?? '';
        final id = href.split('/').last;
        final coverUrl = item.querySelector('img')?.attributes['src'] ?? '';

        return Manga(
          id: id,
          sourceId: 'asura',
          title: title,
          coverUrl: coverUrl,
          status: MangaStatus.unknown,
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<Manga?> fetchMangaById(String id) async {
    try {
      final url = '$_base/series/$id';
      final response = await _client.get(Uri.parse(url), headers: _headers);
      if (response.statusCode != 200) return null;

      final document = parser.parse(response.body);
      final title = document.querySelector('h1')?.text.trim() ?? 'Unknown';
      final coverUrl =
          document.querySelector('.attr-cover img')?.attributes['src'] ?? '';
      final description =
          document.querySelector('.description')?.text.trim() ?? '';

      return Manga(
        id: id,
        sourceId: 'asura',
        title: title,
        coverUrl: coverUrl,
        description: description,
        status: MangaStatus.unknown,
      );
    } catch (_) {
      return null;
    }
  }

  static Future<List<Chapter>> fetchChapterList(String seriesId) async {
    try {
      final url = '$_base/series/$seriesId';
      final response = await _client.get(Uri.parse(url), headers: _headers);
      if (response.statusCode != 200) return [];

      final document = parser.parse(response.body);
      final items = document.querySelectorAll('.chapter-item');

      return items.map((item) {
        final title = item.querySelector('.chapter-name')?.text.trim() ?? '';
        final href = item.querySelector('a')?.attributes['href'] ?? '';
        final id = href.split('/').last;

        double chapterNumber = 0;
        final match = RegExp(r'Chapter\s+(\d+)').firstMatch(title);
        if (match != null) {
          chapterNumber = double.tryParse(match.group(1) ?? '0') ?? 0;
        }

        return Chapter(
          id: id,
          mangaId: seriesId,
          sourceId: 'asura',
          chapterNumber: chapterNumber,
          title: title,
          isRead: false,
        );
      }).toList();
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

      // Asura sometimes uses lazy-loading or different container classes
      final images = document.querySelectorAll(
        '.reader-area img, .rd-area img, #readerarea img',
      );

      return images
          .asMap()
          .entries
          .map((entry) {
            final img = entry.value;
            // Check multiple attributes for the image URL (src, data-src, data-lazy-src)
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
