import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import '../../domain/entities/chapter.dart';
import '../../domain/entities/manga.dart';
import '../../domain/entities/page.dart';

class ReaperService {
  static const _base = 'https://reaperscans.com';
  static final _client = http.Client();

  static const _headers = {
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36',
    'Accept':
        'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8',
    'Referer': 'https://reaperscans.com/',
  };

  static Future<List<Manga>> fetchLatest() async {
    try {
      final url = '$_base';
      final response = await _client.get(Uri.parse(url), headers: _headers);

      print('Reaper fetchLatest: ${response.statusCode}');
      if (response.statusCode != 200) return [];

      final document = parser.parse(response.body);
      // Reaper Scans updated layout selectors
      final items = document.querySelectorAll(
        '.grid > div, .listupd .bs, .utao .uta',
      );

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
              sourceId: 'reaper',
              title: title,
              coverUrl: coverUrl,
              status: MangaStatus.unknown,
            );
          })
          .where((m) => m.id.isNotEmpty)
          .toList();
    } catch (e) {
      print('Reaper Exception: $e');
      return [];
    }
  }

  static Future<List<Manga>> search(String query) async {
    try {
      final url = '$_base/search?query=${Uri.encodeComponent(query)}';
      final response = await _client.get(Uri.parse(url), headers: _headers);
      if (response.statusCode != 200) return [];

      final document = parser.parse(response.body);
      final items = document.querySelectorAll('.grid > div');

      return items.map((item) {
        final titleLink = item.querySelector('a');
        final title = titleLink?.text.trim() ?? 'Unknown';
        final href = titleLink?.attributes['href'] ?? '';
        final id = href.split('/').last;
        final coverUrl = item.querySelector('img')?.attributes['src'] ?? '';

        return Manga(
          id: id,
          sourceId: 'reaper',
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
        sourceId: 'reaper',
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
          mangaId: seriesId,
          sourceId: 'reaper',
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

      // Reaper Scans often uses specific reader classes or IDs
      final images = document.querySelectorAll(
        '.reader-area img, .rd-area img, #readerarea img, .chapter-content img',
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
                img.attributes['content'] ??
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
