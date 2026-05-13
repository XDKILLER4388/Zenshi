import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import '../../domain/entities/chapter.dart';
import '../../domain/entities/manga.dart';
import '../../domain/entities/page.dart';

class ManganatoService {
  static const _base = 'https://manganato.com';
  static final _client = http.Client();

  static const _headers = {
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36',
    'Accept':
        'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8',
    'Referer': 'https://manganato.com/',
  };

  static Future<List<Manga>> search(String query) async {
    try {
      final url =
          'https://manganato.com/search/story/${query.replaceAll(' ', '_')}';
      final response = await _client.get(Uri.parse(url), headers: _headers);
      if (response.statusCode != 200) return [];

      final document = parser.parse(response.body);
      final items = document.querySelectorAll('.search-story-item');

      return items.map((item) {
        final title =
            item.querySelector('.item-title')?.text.trim() ?? 'Unknown';
        final href =
            item.querySelector('.item-title')?.attributes['href'] ?? '';
        final id = href.split('/').last;
        final coverUrl = item.querySelector('img')?.attributes['src'] ?? '';

        return Manga(
          id: id,
          sourceId: 'manganato',
          title: title,
          coverUrl: coverUrl,
          status: MangaStatus.unknown,
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<List<Chapter>> fetchChapterList(String mangaId) async {
    try {
      final url = 'https://chapmanganato.to/$mangaId';
      final response = await _client.get(Uri.parse(url), headers: _headers);
      if (response.statusCode != 200) return [];

      final document = parser.parse(response.body);
      final items = document.querySelectorAll('.row-content-chapter li');

      return items.map((item) {
        final title = item.querySelector('.chapter-name')?.text.trim() ?? '';
        final href =
            item.querySelector('.chapter-name')?.attributes['href'] ?? '';
        final id = href.split('/').last;

        // Extract chapter number
        double chapterNumber = 0;
        final match = RegExp(r'Chapter\s+(\d+)').firstMatch(title);
        if (match != null) {
          chapterNumber = double.tryParse(match.group(1) ?? '0') ?? 0;
        }

        return Chapter(
          id: id,
          mangaId: mangaId,
          sourceId: 'manganato',
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
      final url = 'https://chapmanganato.to/$chapterId';
      final response = await _client.get(Uri.parse(url), headers: _headers);
      if (response.statusCode != 200) return [];

      final document = parser.parse(response.body);
      final images = document.querySelectorAll('.container-chapter-reader img');

      return images.asMap().entries.map((entry) {
        return Page(
          index: entry.key,
          imageUrl: entry.value.attributes['src'] ?? '',
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }
}
