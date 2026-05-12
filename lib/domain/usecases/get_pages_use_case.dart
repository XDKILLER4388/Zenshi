import '../entities/chapter.dart';
import '../entities/page.dart';
import '../repositories/reader_repository.dart';

/// Fetches the page list for a chapter.
class GetPagesUseCase {
  final ReaderRepository _repository;

  const GetPagesUseCase(this._repository);

  Future<List<Page>> call(Chapter chapter) => _repository.getPages(chapter);
}
