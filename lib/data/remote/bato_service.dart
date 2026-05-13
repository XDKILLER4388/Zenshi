import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../domain/entities/chapter.dart';
import '../../domain/entities/manga.dart';
import '../../domain/entities/page.dart';

class BatoService {
  static const _base = 'https://bato.to';
  static final _client = http.Client();

  static const _headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36',
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8',
    'Referer': 'https://bato.to/',
  };

  static Future<List<Manga>> search(String query) async {
    try {
      final url = '$_base/search?word=${Uri.encodeComponent(query)}';
      final response = await _client.get(Uri.parse(url), headers: _headers);
      if (response.statusCode != 200) return [];
      
      // Bato returns HTML, we'd need a parser for real usage.
      // For now, returning empty to allow the parallel search to continue.
      return [];
    } catch (_) {
      return [];
    }
  }

  static Future<List<Chapter>> fetchChapterList(String seriesId) async {
    try {
      // Bato series IDs look like '74321' or 'series-slug'
      final url = '$_base/series/$seriesId';
      final response = await _client.get(Uri.parse(url), headers: _headers);
      if (response.statusCode != 200) return [];

      return [];
    } catch (_) {
      return [];
    }
  }

  static Future<List<Page>> fetchPages(String chapterId) async {
    try {
      final url = '$_base/chapter/$chapterId';
      final response = await _client.get(Uri.parse(url), headers: _headers);
      if (response.statusCode != 200) return [];

      return [];
    } catch (_) {
      return [];
    }
  }
}
