import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/manga.dart';
import '../../domain/entities/search_query.dart';
import 'use_case_providers.dart';

final mangaSearchProvider =
    FutureProvider.family<List<Manga>, String>((ref, query) async {
  if (query.isEmpty) return [];
  return ref.read(searchMangaUseCaseProvider).call(SearchQuery(query: query));
});
