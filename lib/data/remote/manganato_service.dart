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
      // Manganato search uses underscores
      final formattedQuery = query.toLowerCase().replaceAll(
        RegExp(r'[^a-z0-9]'),
        '_',
      );
      final url = 'https://manganato.com/search/story/$formattedQuery';
      final response = await _client.get(Uri.parse(url), headers: _headers);

      if (response.statusCode != 200) {
        // Try alternative search if first one fails
        final altUrl =
            'https://manganato.com/search/story/${Uri.encodeComponent(query)}';
        final altResponse = await _client.get(
          Uri.parse(altUrl),
          headers: _headers,
        );
        if (altResponse.statusCode != 200) return [];
      }

      final document = parser.parse(response.body);
      final items = document.querySelectorAll('.search-story-item, .item-list');

      return items.map((item) {
        final titleLink = item.querySelector('.item-title, .title a');
        final title = titleLink?.text.trim() ?? 'Unknown';
        final href = titleLink?.attributes['href'] ?? '';
        final id = href.split('/').where((s) => s.isNotEmpty).last;
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

  static Future<Manga?> fetchMangaById(String id) async {
    try {
      final url = 'https://chapmanganato.to/$id';
      final response = await _client.get(Uri.parse(url), headers: _headers);
      if (response.statusCode != 200) return null;

      final document = parser.parse(response.body);
      final title =
          document.querySelector('.story-info-right h1')?.text.trim() ??
          'Unknown';
      final coverUrl =
          document.querySelector('.info-image img')?.attributes['src'] ?? '';
      final description =
          document
              .querySelector('#panel-story-info-description')
              ?.text
              .trim() ??
          '';
      final genres = document
          .querySelectorAll('.variations-tableInfo .table-value a')
          .map((e) => e.text.trim())
          .toList();

      return Manga(
        id: id,
        sourceId: 'manganato',
        title: title,
        coverUrl: coverUrl,
        description: description,
        genres: genres,
        status: MangaStatus.unknown,
      );
    } catch (_) {
      return null;
    }
  }

  static Future<List<Chapter>> fetchChapterList(String mangaId) async {
    try {
      final domains = [
        'chapmanganato.to',
        'manganato.com',
        'readmanganato.com',
      ];
      for (final domain in domains) {
        final url = 'https://$domain/$mangaId';
        final response = await _client.get(Uri.parse(url), headers: _headers);
        if (response.statusCode != 200) continue;

        final document = parser.parse(response.body);
        final selectors = [
          '.row-content-chapter li',
          '.chapter-list .row',
          '.a-h',
        ];
        var items = <parser.Element>[];
        for (final selector in selectors) {
          items = document.querySelectorAll(selector);
          if (items.isNotEmpty) break;
        }

        if (items.isEmpty) continue;

        final chapters = items.map((item) {
          final link = item.querySelector('a');
          final title = link?.text.trim() ?? '';
          final href = link?.attributes['href'] ?? '';
          final id = href.split('/').last;

          double chapterNumber = 0;
          final numMatch = RegExp(r'Chapter\s+(\d+\.?\d*)').firstMatch(title);
          if (numMatch != null) {
            chapterNumber = double.tryParse(numMatch.group(1) ?? '0') ?? 0;
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

        // Manganato usually lists chapters in reverse order (newest first)
        // Sort to ensure chronological order (oldest first)
        chapters.sort((a, b) => a.chapterNumber.compareTo(b.chapterNumber));
        return chapters;
      }
      return [];
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
