import '../entities/manga.dart';
import '../entities/search_query.dart';
import '../repositories/manga_repository.dart';

/// Searches for manga titles matching the given query and filters.
class SearchMangaUseCase {
  final MangaRepository _repository;

  const SearchMangaUseCase(this._repository);

  Future<List<Manga>> call(SearchQuery query) =>
      _repository.searchManga(query);
}
