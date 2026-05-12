import '../entities/manga.dart';
import '../repositories/manga_repository.dart';

/// Adds a manga title to the user's library.
class AddToLibraryUseCase {
  final MangaRepository _repository;

  const AddToLibraryUseCase(this._repository);

  Future<void> call(Manga manga) => _repository.addToLibrary(manga);
}
