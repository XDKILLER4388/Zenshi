import '../entities/chapter.dart';
import '../repositories/manga_repository.dart';

/// Fetches the chapter list for a manga from the given source.
class GetChapterListUseCase {
  final MangaRepository _repository;

  const GetChapterListUseCase(this._repository);

  Future<List<Chapter>> call(String mangaId, String sourceId) =>
      _repository.getChapterList(mangaId, sourceId);
}
