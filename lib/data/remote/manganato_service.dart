import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../domain/entities/chapter.dart';
import '../../domain/entities/manga.dart';
import '../../domain/entities/page.dart';

class ManganatoService {
  static const _base = 'https://manganato.com';
  static final _client = http.Client();

  static const _headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36',
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8',
    'Referer': 'https://manganato.com/',
  };

  static Future<List<Manga>> search(String query) async {
    try {
      final url = 'https://manganato.com/search/story/${query.replaceAll(' ', '_')}';
      final response = await _client.get(Uri.parse(url), headers: _headers);
      if (response.statusCode != 200) return [];
      return [];
    } catch (_) {
      return [];
    }
  }

  static Future<List<Chapter>> fetchChapterList(String mangaId) async {
    try {
      final url = 'https://chapmanganato.to/$mangaId';
      final response = await _client.get(Uri.parse(url), headers: _headers);
      if (response.statusCode != 200) return [];
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
      return [];
    } catch (_) {
      return [];
    }
  }
}
