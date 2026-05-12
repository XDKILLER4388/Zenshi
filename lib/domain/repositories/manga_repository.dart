import '../entities/chapter.dart';
import '../entities/manga.dart';
import '../entities/page.dart';
import '../entities/search_query.dart';

/// Abstract interface for manga metadata and library operations.
abstract class MangaRepository {
  /// Emits the current library list and any subsequent changes.
  Stream<List<Manga>> watchLibrary();

  /// Returns the manga with [id] from [sourceId], or null if not found.
  Future<Manga?> getMangaById(String id, String sourceId);

  /// Searches for manga matching [query] across the relevant source(s).
  Future<List<Manga>> searchManga(SearchQuery query);

  /// Adds [manga] to the user's library.
  Future<void> addToLibrary(Manga manga);

  /// Removes the manga identified by [mangaId] from the user's library.
  Future<void> removeFromLibrary(String mangaId);

  /// Returns the chapter list for the given manga from [sourceId].
  Future<List<Chapter>> getChapterList(String mangaId, String sourceId);

  /// Returns the page list for [chapter].
  Future<List<Page>> getPages(Chapter chapter);
}
