import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import '../../domain/entities/chapter.dart';
import '../../domain/entities/manga.dart';
import '../../domain/entities/page.dart';

class FlameService {
  static const _base = 'https://flamecomics.com';
  static final _client = http.Client();

  static const _headers = {
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36',
    'Accept':
        'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8',
    'Referer': 'https://flamecomics.com/',
  };

  static Future<List<Manga>> search(String query) async {
    try {
      final url = '$_base/?s=${Uri.encodeComponent(query)}';
      final response = await _client.get(Uri.parse(url), headers: _headers);
      if (response.statusCode != 200) return [];

      final document = parser.parse(response.body);
      final items = document.querySelectorAll('.listupd .bs');

      return items.map((item) {
        final titleLink = item.querySelector('a');
        final title = titleLink?.attributes['title'] ?? 'Unknown';
        final href = titleLink?.attributes['href'] ?? '';
        final id = href.split('/').where((s) => s.isNotEmpty).last;
        final coverUrl = item.querySelector('img')?.attributes['src'] ?? '';

        return Manga(
          id: id,
          sourceId: 'flame',
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
      final title = document.querySelector('h1.entry-title')?.text.trim() ?? 'Unknown';
      final coverUrl = document.querySelector('.thumb img')?.attributes['src'] ?? '';
      final description = document.querySelector('.entry-content p')?.text.trim() ?? '';

      return Manga(
        id: id,
        sourceId: 'flame',
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
      final items = document.querySelectorAll('#chapterlist li');

      final chapters = items.map((item) {
        final link = item.querySelector('a');
        final title = item.querySelector('.chapternum')?.text.trim() ?? '';
        final href = link?.attributes['href'] ?? '';
        final id = href.split('/').where((s) => s.isNotEmpty).last;

        double chapterNumber = 0;
        final match = RegExp(r'Chapter\s*(\d+\.?\d*)', caseSensitive: false)
            .firstMatch(title);
        if (match != null) {
          chapterNumber = double.tryParse(match.group(1) ?? '0') ?? 0;
        }

        return Chapter(
          id: id,
          mangaId: seriesId,
          sourceId: 'flame',
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
      final url = '$_base/$chapterId';
      final response = await _client.get(Uri.parse(url), headers: _headers);
      if (response.statusCode != 200) return [];

      final document = parser.parse(response.body);
      final images = document.querySelectorAll('#readerarea img');

      return images.asMap().entries.map((entry) {
        return Page(
          index: entry.key,
          imageUrl: entry.value.attributes['src'] ??
              entry.value.attributes['data-src'] ??
              '',
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }
}
