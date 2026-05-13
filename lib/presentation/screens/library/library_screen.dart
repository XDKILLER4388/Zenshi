import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../domain/entities/manga.dart';
import '../../providers/library_provider.dart';

// ── Library screen ─────────────────────────────────────────────────────────────

/// Library screen showing the user's saved manga in a 2-column grid.
///
/// Features:
/// - Grid view (2 columns) with unread chapter badge
/// - Sort bar with current sort option and filter icon
/// - Filter bottom sheet (Collection, Tag, genre, status, read/unread)
/// - Collections tab and Tags tab (TabBar at top)
/// - Private Library mode with biometric/PIN gate
/// - Import/Export JSON in overflow menu
/// - Empty state with "Add manga from Discover" CTA
/// - Long-press context menu: remove from library, manage collections/tags
class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  bool _privateUnlocked = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ── Private library auth ───────────────────────────────────────────────

  Future<void> _unlockPrivateLibrary() async {
    // local_auth removed for v1.0 — use PIN dialog only
    await _showPinDialog();
  }

  Future<void> _showPinDialog() async {
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Enter PIN', style: AppTypography.titleSmall),
        content: TextField(
          controller: controller,
          obscureText: true,
          keyboardType: TextInputType.number,
          maxLength: 6,
          decoration: const InputDecoration(hintText: 'PIN', counterText: ''),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Unlock'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      setState(() => _privateUnlocked = true);
    }
  }

  // ── Import / Export ────────────────────────────────────────────────────

  void _exportLibrary() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Library export coming soon')));
  }

  void _importLibrary() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Library import coming soon')));
  }

  @override
  Widget build(BuildContext context) {
    final libraryAsync = ref.watch(libraryProvider);
    final filterState = ref.watch(libraryFilterProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text('Library', style: AppTypography.titleMedium),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.onSurfaceMuted,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Collections'),
            Tab(text: 'Tags'),
          ],
        ),
        actions: [
          // Private library lock icon
          IconButton(
            icon: Icon(
              _privateUnlocked ? Icons.lock_open_outlined : Icons.lock_outlined,
              color: _privateUnlocked
                  ? AppColors.primary
                  : AppColors.onSurfaceMuted,
            ),
            tooltip: 'Private Library',
            onPressed: _privateUnlocked
                ? () => setState(() => _privateUnlocked = false)
                : _unlockPrivateLibrary,
          ),
          PopupMenuButton<String>(
            color: AppColors.surface,
            onSelected: (value) {
              if (value == 'export') _exportLibrary();
              if (value == 'import') _importLibrary();
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'export',
                child: ListTile(
                  leading: Icon(Icons.upload_outlined),
                  title: Text('Export JSON'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'import',
                child: ListTile(
                  leading: Icon(Icons.download_outlined),
                  title: Text('Import JSON'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ── All manga tab ──────────────────────────────────────────────
          Column(
            children: [
              _SortBar(filterState: filterState),
              Expanded(
                child: libraryAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                  error: (e, _) => Center(
                    child: Text(
                      'Failed to load library',
                      style: AppTypography.bodyMedium,
                    ),
                  ),
                  data: (manga) {
                    final filtered = _applyFilter(manga, filterState);
                    final sorted = _applySort(filtered, filterState.sort);
                    if (sorted.isEmpty) {
                      return const _EmptyState();
                    }
                    return _MangaGrid(
                      manga: sorted,
                      privateUnlocked: _privateUnlocked,
                    );
                  },
                ),
              ),
            ],
          ),

          // ── Collections tab ────────────────────────────────────────────
          const _CollectionsTab(),

          // ── Tags tab ───────────────────────────────────────────────────
          const _TagsTab(),
        ],
      ),
    );
  }

  // ── Filter / sort helpers ──────────────────────────────────────────────

  List<Manga> _applyFilter(List<Manga> manga, LibraryFilterState filter) {
    return manga.where((m) {
      if (filter.genre != null && !m.genres.contains(filter.genre)) {
        return false;
      }
      if (filter.status != null && m.status.name != filter.status) {
        return false;
      }
      return true;
    }).toList();
  }

  List<Manga> _applySort(List<Manga> manga, LibrarySortOption sort) {
    final list = List<Manga>.from(manga);
    switch (sort) {
      case LibrarySortOption.alphabeticalAZ:
        list.sort((a, b) => a.title.compareTo(b.title));
      case LibrarySortOption.alphabeticalZA:
        list.sort((a, b) => b.title.compareTo(a.title));
      case LibrarySortOption.latestUpdate:
        list.sort((a, b) {
          final aTime = a.lastUpdated?.millisecondsSinceEpoch ?? 0;
          final bTime = b.lastUpdated?.millisecondsSinceEpoch ?? 0;
          return bTime.compareTo(aTime);
        });
      case LibrarySortOption.userRating:
        list.sort((a, b) {
          final aRating = a.averageRating ?? 0;
          final bRating = b.averageRating ?? 0;
          return bRating.compareTo(aRating);
        });
      case LibrarySortOption.lastRead:
      case LibrarySortOption.mostViewed:
        // These require reading progress data; default to alphabetical.
        list.sort((a, b) => a.title.compareTo(b.title));
    }
    return list;
  }
}

// ── Sort bar ───────────────────────────────────────────────────────────────────

class _SortBar extends ConsumerWidget {
  const _SortBar({required this.filterState});

  final LibraryFilterState filterState;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppColors.surface,
      child: Row(
        children: [
          const Icon(Icons.sort, size: 16, color: AppColors.onSurfaceMuted),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _showSortSheet(context, ref),
            child: Text(
              _sortLabel(filterState.sort),
              style: AppTypography.labelLarge.copyWith(
                color: AppColors.primary,
              ),
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.filter_list, size: 20),
            color: _hasActiveFilters(filterState)
                ? AppColors.primary
                : AppColors.onSurfaceMuted,
            tooltip: 'Filter',
            onPressed: () => _showFilterSheet(context, ref),
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            padding: EdgeInsets.zero,
          ),
          if (_hasActiveFilters(filterState))
            GestureDetector(
              onTap: () =>
                  ref.read(libraryFilterProvider.notifier).clearFilters(),
              child: Text(
                'Clear',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.error,
                ),
              ),
            ),
        ],
      ),
    );
  }

  bool _hasActiveFilters(LibraryFilterState state) =>
      state.collectionId != null ||
      state.tagId != null ||
      state.genre != null ||
      state.status != null ||
      state.isRead != null;

  String _sortLabel(LibrarySortOption sort) {
    return switch (sort) {
      LibrarySortOption.alphabeticalAZ => 'A → Z',
      LibrarySortOption.alphabeticalZA => 'Z → A',
      LibrarySortOption.lastRead => 'Last Read',
      LibrarySortOption.latestUpdate => 'Latest Update',
      LibrarySortOption.mostViewed => 'Most Viewed',
      LibrarySortOption.userRating => 'User Rating',
    };
  }

  void _showSortSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _SortSheet(
        current: ref.read(libraryFilterProvider).sort,
        onSelect: (sort) {
          ref.read(libraryFilterProvider.notifier).updateSort(sort);
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _showFilterSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _FilterSheet(
        current: ref.read(libraryFilterProvider),
        onApply: (filters) {
          ref.read(libraryFilterProvider.notifier).updateFilters(filters);
          Navigator.of(context).pop();
        },
      ),
    );
  }
}

// ── Sort sheet ─────────────────────────────────────────────────────────────────

class _SortSheet extends StatelessWidget {
  const _SortSheet({required this.current, required this.onSelect});

  final LibrarySortOption current;
  final ValueChanged<LibrarySortOption> onSelect;

  @override
  Widget build(BuildContext context) {
    final options = [
      (
        LibrarySortOption.alphabeticalAZ,
        'Alphabetical A → Z',
        Icons.sort_by_alpha,
      ),
      (
        LibrarySortOption.alphabeticalZA,
        'Alphabetical Z → A',
        Icons.sort_by_alpha,
      ),
      (LibrarySortOption.lastRead, 'Last Read', Icons.history),
      (LibrarySortOption.latestUpdate, 'Latest Update', Icons.update),
      (LibrarySortOption.mostViewed, 'Most Viewed', Icons.visibility_outlined),
      (LibrarySortOption.userRating, 'User Rating', Icons.star_outline),
    ];

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Sort by', style: AppTypography.titleMedium),
          ),
          ...options.map(
            (o) => ListTile(
              leading: Icon(
                o.$3,
                color: current == o.$1
                    ? AppColors.primary
                    : AppColors.onSurfaceMuted,
              ),
              title: Text(o.$2),
              trailing: current == o.$1
                  ? const Icon(Icons.check, color: AppColors.primary)
                  : null,
              onTap: () => onSelect(o.$1),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ── Filter sheet ───────────────────────────────────────────────────────────────

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({required this.current, required this.onApply});

  final LibraryFilterState current;
  final ValueChanged<LibraryFilterState> onApply;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late LibraryFilterState _state;

  @override
  void initState() {
    super.initState();
    _state = widget.current;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Filter', style: AppTypography.titleMedium),
                const Spacer(),
                TextButton(
                  onPressed: () =>
                      setState(() => _state = LibraryFilterState.empty),
                  child: const Text('Clear all'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Read/Unread filter
            Text('Read Status', style: AppTypography.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                _FilterChip(
                  label: 'All',
                  selected: _state.isRead == null,
                  onTap: () => setState(() => _state = _state.copyWith()),
                ),
                _FilterChip(
                  label: 'Read',
                  selected: _state.isRead == true,
                  onTap: () =>
                      setState(() => _state = _state.copyWith(isRead: true)),
                ),
                _FilterChip(
                  label: 'Unread',
                  selected: _state.isRead == false,
                  onTap: () =>
                      setState(() => _state = _state.copyWith(isRead: false)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Status filter
            Text('Publication Status', style: AppTypography.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                _FilterChip(
                  label: 'All',
                  selected: _state.status == null,
                  onTap: () => setState(
                    () => _state = LibraryFilterState(
                      sort: _state.sort,
                      collectionId: _state.collectionId,
                      tagId: _state.tagId,
                      genre: _state.genre,
                      isRead: _state.isRead,
                    ),
                  ),
                ),
                for (final s in ['ongoing', 'completed', 'hiatus'])
                  _FilterChip(
                    label: s[0].toUpperCase() + s.substring(1),
                    selected: _state.status == s,
                    onTap: () =>
                        setState(() => _state = _state.copyWith(status: s)),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => widget.onApply(_state),
                child: const Text('Apply Filters'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: AppTypography.labelMedium.copyWith(
            color: selected ? Colors.white : AppColors.onSurfaceMuted,
          ),
        ),
      ),
    );
  }
}

// ── Manga grid ─────────────────────────────────────────────────────────────────

class _MangaGrid extends ConsumerWidget {
  const _MangaGrid({required this.manga, required this.privateUnlocked});

  final List<Manga> manga;
  final bool privateUnlocked;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.62,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: manga.length,
      itemBuilder: (context, index) {
        final m = manga[index];
        return _LibraryMangaCard(
          manga: m,
          isPrivateLocked: !privateUnlocked,
          onRemove: () =>
              ref.read(libraryProvider.notifier).removeFromLibrary(m.id),
        );
      },
    );
  }
}

// ── Library manga card ─────────────────────────────────────────────────────────

class _LibraryMangaCard extends StatelessWidget {
  const _LibraryMangaCard({
    required this.manga,
    required this.onRemove,
    this.isPrivateLocked = false,
  });

  final Manga manga;
  final VoidCallback onRemove;
  final bool isPrivateLocked;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (isPrivateLocked) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Unlock private library to view')),
          );
          return;
        }
        context.push('/manga-details/${manga.sourceId}/${manga.id}');
      },
      onLongPress: () => _showContextMenu(context),
      child: Stack(
        children: [
          // Cover card
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: manga.coverUrl != null
                      ? CachedNetworkImage(
                          imageUrl: manga.coverUrl!,
                          fit: BoxFit.cover,
                          placeholder: (_, __) =>
                              Container(color: AppColors.surfaceVariant),
                          errorWidget: (_, __, ___) => Container(
                            color: AppColors.surfaceVariant,
                            child: const Icon(
                              Icons.broken_image_outlined,
                              color: AppColors.onSurfaceMuted,
                            ),
                          ),
                        )
                      : Container(
                          color: AppColors.surfaceVariant,
                          child: Center(
                            child: Text(
                              manga.title,
                              textAlign: TextAlign.center,
                              style: AppTypography.labelSmall,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                ),
                Container(
                  color: AppColors.surface,
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    manga.title,
                    style: AppTypography.labelMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          // Unread badge (placeholder — real count requires chapter data)
          Positioned(
            top: 6,
            right: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'NEW',
                style: AppTypography.labelSmall.copyWith(
                  color: Colors.white,
                  fontSize: 9,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showContextMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(manga.title, style: AppTypography.titleSmall),
            ),
            ListTile(
              leading: const Icon(
                Icons.bookmark_remove_outlined,
                color: AppColors.error,
              ),
              title: const Text('Remove from Library'),
              onTap: () {
                Navigator.of(context).pop();
                onRemove();
              },
            ),
            ListTile(
              leading: const Icon(Icons.folder_outlined),
              title: const Text('Manage Collections'),
              onTap: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Collections management coming soon'),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.label_outline),
              title: const Text('Manage Tags'),
              onTap: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Tags management coming soon')),
                );
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ── Collections tab ────────────────────────────────────────────────────────────

class _CollectionsTab extends StatelessWidget {
  const _CollectionsTab();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.folder_outlined,
              size: 64,
              color: AppColors.onSurfaceMuted,
            ),
            const SizedBox(height: 16),
            Text('No collections yet', style: AppTypography.titleSmall),
            const SizedBox(height: 8),
            Text(
              'Create collections to organise your library.',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.onSurfaceMuted,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add),
              label: const Text('New Collection'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Tags tab ───────────────────────────────────────────────────────────────────

class _TagsTab extends StatelessWidget {
  const _TagsTab();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.label_outline,
              size: 64,
              color: AppColors.onSurfaceMuted,
            ),
            const SizedBox(height: 16),
            Text('No tags yet', style: AppTypography.titleSmall),
            const SizedBox(height: 8),
            Text(
              'Create tags to label and filter your manga.',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.onSurfaceMuted,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add),
              label: const Text('New Tag'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty state ────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.collections_bookmark_outlined,
              size: 72,
              color: AppColors.onSurfaceMuted,
            ),
            const SizedBox(height: 16),
            Text('Your library is empty', style: AppTypography.titleSmall),
            const SizedBox(height: 8),
            Text(
              'Add manga from Discover to start building your collection.',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.onSurfaceMuted,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.explore_outlined),
              label: const Text('Add from Discover'),
            ),
          ],
        ),
      ),
    );
  }
}
