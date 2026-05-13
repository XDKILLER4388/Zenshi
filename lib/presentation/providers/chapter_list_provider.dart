import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/chapter.dart';
import 'use_case_providers.dart';

// ── Chapter list provider ──────────────────────────────────────────────────────

class ChapterListArgs {
  const ChapterListArgs({required this.mangaId, required this.sourceId});
  final String mangaId;
  final String sourceId;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChapterListArgs &&
        other.mangaId == mangaId &&
        other.sourceId == sourceId;
  }

  @override
  int get hashCode => Object.hash(mangaId, sourceId);
}

/// Fetches chapter list using the [GetChapterListUseCase].
final chapterListProvider = FutureProvider.family<List<Chapter>, ChapterListArgs>(
  (ref, args) async {
    final useCase = ref.watch(getChapterListUseCaseProvider);
    return useCase(args.mangaId, args.sourceId);
  },
);

ChapterListArgs chapterListArgs({
  required String mangaId,
  required String sourceId,
}) =>
    ChapterListArgs(mangaId: mangaId, sourceId: sourceId);
