import '../repositories/manga_repository.dart';

/// Removes a manga title from the user's library.
class RemoveFromLibraryUseCase {
  final MangaRepository _repository;

  const RemoveFromLibraryUseCase(this._repository);

  Future<void> call(String mangaId) => _repository.removeFromLibrary(mangaId);
}
