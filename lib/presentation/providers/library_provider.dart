import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/manga.dart';
import 'use_case_providers.dart';

// ── Sort options ───────────────────────────────────────────────────────────────

enum LibrarySortOption {
  alphabeticalAZ,
  alphabeticalZA,
  lastRead,
  latestUpdate,
  mostViewed,
  userRating,
}

// ── Filter state ───────────────────────────────────────────────────────────────

/// Holds the active sort and filter criteria for the Library screen.
class LibraryFilterState {
  const LibraryFilterState({
    this.sort = LibrarySortOption.alphabeticalAZ,
    this.collectionId,
    this.tagId,
    this.genre,
    this.status,
    this.isRead,
  });

  final LibrarySortOption sort;
  final String? collectionId;
  final String? tagId;
  final String? genre;
  final String? status;
  final bool? isRead;

  static LibraryFilterState get empty => const LibraryFilterState();

  LibraryFilterState copyWith({
    LibrarySortOption? sort,
    String? collectionId,
    String? tagId,
    String? genre,
    String? status,
    bool? isRead,
  }) {
    return LibraryFilterState(
      sort: sort ?? this.sort,
      collectionId: collectionId ?? this.collectionId,
      tagId: tagId ?? this.tagId,
      genre: genre ?? this.genre,
      status: status ?? this.status,
      isRead: isRead ?? this.isRead,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LibraryFilterState &&
        other.sort == sort &&
        other.collectionId == collectionId &&
        other.tagId == tagId &&
        other.genre == genre &&
        other.status == status &&
        other.isRead == isRead;
  }

  @override
  int get hashCode =>
      Object.hash(sort, collectionId, tagId, genre, status, isRead);
}

// ── Library notifier ───────────────────────────────────────────────────────────

/// Watches the library stream and exposes add/remove operations.
class LibraryNotifier extends StreamNotifier<List<Manga>> {
  @override
  Stream<List<Manga>> build() {
    return ref.watch(getLibraryUseCaseProvider).call();
  }

  Future<void> addToLibrary(Manga manga) async {
    await ref.read(addToLibraryUseCaseProvider).call(manga);
  }

  Future<void> removeFromLibrary(String mangaId) async {
    await ref.read(removeFromLibraryUseCaseProvider).call(mangaId);
  }
}

/// Provider for [LibraryNotifier].
final libraryProvider = StreamNotifierProvider<LibraryNotifier, List<Manga>>(
  LibraryNotifier.new,
);

// ── Library filter notifier ────────────────────────────────────────────────────

/// Manages the active sort and filter state for the Library screen.
class LibraryFilterNotifier extends Notifier<LibraryFilterState> {
  @override
  LibraryFilterState build() => LibraryFilterState.empty;

  void updateSort(LibrarySortOption sort) {
    state = state.copyWith(sort: sort);
  }

  void updateFilters(LibraryFilterState filters) {
    state = filters;
  }

  void clearFilters() {
    state = LibraryFilterState.empty;
  }
}

/// Provider for [LibraryFilterNotifier].
final libraryFilterProvider =
    NotifierProvider<LibraryFilterNotifier, LibraryFilterState>(
      LibraryFilterNotifier.new,
    );
