import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/chapter.dart';

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

/// Returns empty chapter list — no DB access to avoid startup crashes.
final chapterListProvider = FutureProvider.family<List<Chapter>, ChapterListArgs>(
  (ref, args) async => [],
);

ChapterListArgs chapterListArgs({
  required String mangaId,
  required String sourceId,
}) =>
    ChapterListArgs(mangaId: mangaId, sourceId: sourceId);
