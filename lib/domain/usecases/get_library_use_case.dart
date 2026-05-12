import '../entities/manga.dart';
import '../repositories/manga_repository.dart';

/// Returns a stream of the user's library that emits on every change.
class GetLibraryUseCase {
  final MangaRepository _repository;

  const GetLibraryUseCase(this._repository);

  Stream<List<Manga>> call() => _repository.watchLibrary();
}
