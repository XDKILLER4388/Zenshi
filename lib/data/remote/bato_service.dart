import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import '../../domain/entities/chapter.dart';
import '../../domain/entities/manga.dart';
import '../../domain/entities/page.dart';

class BatoService {
  static const _base = 'https://bato.to';
  static final _client = http.Client();

  static const _headers = {
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36',
    'Accept':
        'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8',
    'Referer': 'https://bato.to/',
    'Cookie': 'limit=0', // Disable mature filter
  };

  static Future<List<Manga>> search(String query) async {
    try {
      final url = '$_base/search?word=${Uri.encodeComponent(query)}';
      final response = await _client.get(Uri.parse(url), headers: _headers);
      if (response.statusCode != 200) return [];

      final document = parser.parse(response.body);
      final items = document.querySelectorAll('.item');

      return items.map((item) {
        final title =
            item.querySelector('.item-title')?.text.trim() ?? 'Unknown';
        final href =
            item.querySelector('.item-title')?.attributes['href'] ?? '';
        final id = href.split('/').last;
        final coverUrl = item.querySelector('img')?.attributes['src'] ?? '';

        return Manga(
          id: id,
          sourceId: 'bato',
          title: title,
          coverUrl: coverUrl,
          status: MangaStatus.unknown,
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<List<Chapter>> fetchChapterList(String seriesId) async {
    try {
      final url = '$_base/series/$seriesId';
      final response = await _client.get(Uri.parse(url), headers: _headers);
      if (response.statusCode != 200) return [];

      final document = parser.parse(response.body);
      final items = document.querySelectorAll('.main .item');

      return items.map((item) {
        final title = item.querySelector('b')?.text.trim() ?? '';
        final href = item.querySelector('a.chapt')?.attributes['href'] ?? '';
        final id = href.split('/').last;

        // Extract chapter number from title (e.g., "Ch.1")
        double chapterNumber = 0;
        final match = RegExp(r'Ch\.(\d+)').firstMatch(title);
        if (match != null) {
          chapterNumber = double.tryParse(match.group(1) ?? '0') ?? 0;
        }

        return Chapter(
          id: id,
          mangaId: seriesId,
          sourceId: 'bato',
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

      // Bato uses a specific JS variable to store image URLs
      final body = response.body;
      final match = RegExp(
        r'var\s+imgHttpLis\s*=\s*(\[.*?\]);',
      ).firstMatch(body);
      if (match != null) {
        final urlsJson = match.group(1)!;
        final List<dynamic> urls = jsonDecode(urlsJson);
        return urls.asMap().entries.map((entry) {
          return Page(index: entry.key, imageUrl: entry.value.toString());
        }).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }
}
