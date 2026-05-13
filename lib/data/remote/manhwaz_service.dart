import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../domain/entities/chapter.dart';
import '../../domain/entities/manga.dart';
import '../../domain/entities/page.dart';

class ManhwazService {
  static const _base = 'https://manhwaz.com';
  static final _client = http.Client();

  static const _headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36',
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8',
    'Accept-Language': 'en-US,en;q=0.9',
    'Referer': 'https://manhwaz.com/',
  };

  static Future<List<Manga>> search(String query) async {
    try {
      final encodedQuery = Uri.encodeComponent(query);
      final url = '$_base/search?q=$encodedQuery';
      final response = await _client.get(Uri.parse(url), headers: _headers);
      
      if (response.statusCode != 200) return [];

      // Note: In a real environment, we would use an HTML parser like 'html'.
      // For this implementation, we'll simulate the parsing logic based on typical Manhwaz structure.
      // This is a placeholder for the actual HTML extraction.
      return []; 
    } catch (_) {
      return [];
    }
  }

  static Future<List<Chapter>> fetchChapterList(String mangaId) async {
    try {
      final url = '$_base/manga/$mangaId';
      final response = await _client.get(Uri.parse(url), headers: _headers);
      if (response.statusCode != 200) return [];

      // Logic to parse the chapter list from the HTML response
      return [];
    } catch (_) {
      return [];
    }
  }

  static Future<List<Page>> fetchPages(String chapterId) async {
    try {
      final url = '$_base/read/$chapterId';
      final response = await _client.get(Uri.parse(url), headers: _headers);
      if (response.statusCode != 200) return [];

      // Logic to parse image URLs from the reader page
      return [];
    } catch (_) {
      return [];
    }
  }
}
