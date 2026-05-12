import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/chapter.dart';
import 'use_case_providers.dart';

// ── Chapter list provider ──────────────────────────────────────────────────────

/// Argument record for [chapterListProvider].
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

/// Fetches the chapter list for a given [mangaId] + [sourceId] pair.
///
/// Returns [AsyncValue<List<Chapter>>] so the UI can handle loading and error
/// states. The result is cached for the lifetime of the provider.
final chapterListProvider = FutureProvider.family<List<Chapter>, ChapterListArgs>(
  (ref, args) async {
    return ref
        .watch(getChapterListUseCaseProvider)
        .call(args.mangaId, args.sourceId);
  },
);

/// Convenience constructor for [ChapterListArgs].
///
/// Example:
/// ```dart
/// ref.watch(chapterListProvider(chapterListArgs(mangaId: id, sourceId: src)));
/// ```
ChapterListArgs chapterListArgs({
  required String mangaId,
  required String sourceId,
}) =>
    ChapterListArgs(mangaId: mangaId, sourceId: sourceId);
