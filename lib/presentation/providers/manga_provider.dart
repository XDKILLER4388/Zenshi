import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/chapter.dart';
import '../../domain/entities/manga.dart';
import '../../domain/entities/page.dart' as manga_page;
import 'use_case_providers.dart';

class MangaDetailArgs {
  final String id;
  final String sourceId;

  const MangaDetailArgs({required this.id, required this.sourceId});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MangaDetailArgs &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          sourceId == other.sourceId;

  @override
  int get hashCode => id.hashCode ^ sourceId.hashCode;
}

final mangaDetailProvider = FutureProvider.family<Manga?, MangaDetailArgs>((
  ref,
  args,
) async {
  // Try to find in library first
  final library = ref.watch(getLibraryUseCaseProvider).call();
  final inLibrary = await library.firstWhere(
    (list) => list.any((m) => m.id == args.id && m.sourceId == args.sourceId),
    orElse: () => [],
  );

  if (inLibrary.isNotEmpty) {
    return inLibrary.firstWhere((m) => m.id == args.id);
  }

  // Otherwise fetch from remote
  return ref.read(mangaRepositoryProvider).getMangaById(args.id, args.sourceId);
});

final chapterListByMangaProvider =
    FutureProvider.family<List<Chapter>, MangaDetailArgs>((ref, args) async {
      return ref
          .read(getChapterListUseCaseProvider)
          .call(args.id, args.sourceId);
    });

class PageArgs {
  final String chapterId;
  final String sourceId;

  const PageArgs({required this.chapterId, required this.sourceId});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PageArgs &&
          runtimeType == other.runtimeType &&
          chapterId == other.chapterId &&
          sourceId == other.sourceId;

  @override
  int get hashCode => chapterId.hashCode ^ sourceId.hashCode;
}

final chapterPagesProvider =
    FutureProvider.family<List<manga_page.Page>, PageArgs>((ref, args) async {
      final chapter = Chapter(
        id: args.chapterId,
        mangaId: '', // Not strictly needed for page fetching usually
        sourceId: args.sourceId,
        chapterNumber: 0,
        title: '',
      );
      return ref.read(getPagesUseCaseProvider).call(chapter);
    });
