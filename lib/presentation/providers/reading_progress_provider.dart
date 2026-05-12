import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/reading_progress.dart';
import 'use_case_providers.dart';

// ── Reading progress notifier ──────────────────────────────────────────────────

/// Watches the reading progress stream for a specific [mangaId] and exposes
/// a [save] method to persist updates.
class ReadingProgressNotifier
    extends FamilyStreamNotifier<ReadingProgress?, String> {
  @override
  Stream<ReadingProgress?> build(String mangaId) {
    return ref.watch(getReadingProgressUseCaseProvider).call(mangaId);
  }

  Future<void> save(ReadingProgress progress) async {
    await ref.read(saveReadingProgressUseCaseProvider).call(progress);
  }
}

/// Family provider for [ReadingProgressNotifier], keyed by [mangaId].
final readingProgressProvider = StreamNotifierProvider.family<
    ReadingProgressNotifier, ReadingProgress?, String>(
  ReadingProgressNotifier.new,
);
