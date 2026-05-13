import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../domain/entities/chapter.dart';
import '../../domain/entities/manga.dart';
import '../../domain/entities/page.dart';

class AsuraService {
  static const _base = 'https://asuracomic.net';
  static final _client = http.Client();

  static const _headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36',
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8',
    'Referer': 'https://asuracomic.net/',
  };

  static Future<List<Manga>> search(String query) async {
    try {
      final url = '$_base/search?q=${Uri.encodeComponent(query)}';
      final response = await _client.get(Uri.parse(url), headers: _headers);
      if (response.statusCode != 200) return [];
      return [];
    } catch (_) {
      return [];
    }
  }

  static Future<List<Chapter>> fetchChapterList(String seriesId) async {
    try {
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
