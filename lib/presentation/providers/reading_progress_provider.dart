import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/reading_progress.dart';

// ── Reading progress notifier ──────────────────────────────────────────────────

class ReadingProgressNotifier
    extends FamilyStreamNotifier<ReadingProgress?, String> {
  @override
  Stream<ReadingProgress?> build(String mangaId) {
    // Return null immediately — no DB access to avoid startup crashes
    return Stream.value(null);
  }

  Future<void> save(ReadingProgress progress) async {}
}

final readingProgressProvider = StreamNotifierProvider.family<
    ReadingProgressNotifier, ReadingProgress?, String>(
  ReadingProgressNotifier.new,
);
