import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/remote/mangadex_service.dart';
import '../../domain/entities/chapter.dart';
import '../../domain/entities/manga.dart';
import '../../domain/entities/page.dart';

/// Fetches popular manga from MangaDex.
final popularMangaProvider = FutureProvider<List<Manga>>((ref) async {
  return MangaDexService.fetchPopular(limit: 12);
});

/// Fetches popular manhwa (Korean) from MangaDex.
final popularManhwaProvider = FutureProvider<List<Manga>>((ref) async {
  return MangaDexService.fetchPopularManhwa(limit: 12);
});

/// Fetches popular manhua (Chinese) from MangaDex.
final popularManhuaProvider = FutureProvider<List<Manga>>((ref) async {
  return MangaDexService.fetchPopularManhua(limit: 12);
});

/// Fetches popular webtoons from MangaDex.
final popularWebtoonsProvider = FutureProvider<List<Manga>>((ref) async {
  return MangaDexService.fetchPopularWebtoons(limit: 12);
});

/// Fetches recently updated manga from MangaDex.
final recentlyUpdatedProvider = FutureProvider<List<Manga>>((ref) async {
  return MangaDexService.fetchRecentlyUpdated(limit: 12);
});

/// Fetches top rated manga from MangaDex.
final topRatedProvider = FutureProvider<List<Manga>>((ref) async {
  return MangaDexService.fetchTopRated(limit: 12);
});

/// Fetches new releases from MangaDex.
final newReleasesProvider = FutureProvider<List<Manga>>((ref) async {
  return MangaDexService.fetchNewReleases(limit: 12);
});

/// Fetches seasonal picks from MangaDex.
final seasonalProvider = FutureProvider<List<Manga>>((ref) async {
  return MangaDexService.fetchSeasonal(limit: 12);
});

/// Fetches trending (same as popular for MangaDex).
final trendingProvider = FutureProvider<List<Manga>>((ref) async {
  return MangaDexService.fetchPopular(limit: 12);
});

/// Search provider — keyed by query string.
final mangaSearchProvider =
    FutureProvider.family<List<Manga>, String>((ref, query) async {
  if (query.isEmpty) return [];
  return MangaDexService.search(query, limit: 20);
});

/// Fetch manga details by ID.
final mangaDetailProvider =
    FutureProvider.family<Manga?, String>((ref, mangaId) async {
  return MangaDexService.fetchMangaById(mangaId);
});

/// Fetch chapter list for a manga.
final chapterListByMangaProvider =
    FutureProvider.family<List<Chapter>, String>((ref, mangaId) async {
  return MangaDexService.fetchChapterList(mangaId);
});

/// Fetch pages for a chapter.
final chapterPagesProvider =
    FutureProvider.family<List<Page>, String>((ref, chapterId) async {
  return MangaDexService.fetchPages(chapterId);
});
