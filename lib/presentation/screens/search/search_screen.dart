import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_typography.dart';
import '../../../domain/entities/manga.dart';
import '../../providers/search_provider.dart';
import '../../widgets/manga_card/manga_card.dart';

const _trendingSearches = [
  'One Piece',
  'Jujutsu Kaisen',
  'Chainsaw Man',
  'Spy x Family',
  'Demon Slayer',
  'My Hero Academia',
  'Vinland Saga',
  'Berserk',
];

const _genres = [
  'Action',
  'Romance',
  'Fantasy',
  'Horror',
  'Comedy',
  'Sci-Fi',
  'Slice of Life',
  'Sports',
  'Mystery',
  'Thriller',
];

// ── Filter state ───────────────────────────────────────────────────────────────

enum _PublicationStatus { all, ongoing, completed, hiatus }

class _FilterState {
  const _FilterState({
    this.genres = const [],
    this.status = _PublicationStatus.all,
    this.language = 'All',
    this.minRating = 0.0,
    this.showNsfw = false,
  });

  final List<String> genres;
  final _PublicationStatus status;
  final String language;
  final double minRating;
  final bool showNsfw;

  _FilterState copyWith({
    List<String>? genres,
    _PublicationStatus? status,
    String? language,
    double? minRating,
    bool? showNsfw,
  }) {
    return _FilterState(
      genres: genres ?? this.genres,
      status: status ?? this.status,
      language: language ?? this.language,
      minRating: minRating ?? this.minRating,
      showNsfw: showNsfw ?? this.showNsfw,
    );
  }
}

// ── Screen ─────────────────────────────────────────────────────────────────────

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key, this.initialQuery});

  final String? initialQuery;

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late final _searchController = TextEditingController(
    text: widget.initialQuery,
  );
  final _focusNode = FocusNode();
  Timer? _debounce;

  late String _query = widget.initialQuery ?? '';
  List<Manga> _results = [];
  List<String> _history = [];
  bool _searching = false;
  bool _showHistory = false;
  _FilterState _filters = const _FilterState();

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _focusNode.addListener(() {
      setState(() {
        _showHistory = _focusNode.hasFocus && _query.isEmpty;
      });
    });

    if (widget.initialQuery != null) {
      _search(widget.initialQuery!);
    }
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList('search_history') ?? [];
    if (mounted) setState(() => _history = history);
  }

  Future<void> _saveToHistory(String query) async {
    if (query.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList('search_history') ?? [];
    history.remove(query);
    history.insert(0, query);
    if (history.length > AppConstants.kMaxSearchHistory) {
      history.removeLast();
    }
    await prefs.setStringList('search_history', history);
    if (mounted) setState(() => _history = history);
  }

  Future<void> _removeFromHistory(String query) async {
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList('search_history') ?? [];
    history.remove(query);
    await prefs.setStringList('search_history', history);
    if (mounted) setState(() => _history = history);
  }

  void _onQueryChanged(String value) {
    setState(() {
      _query = value;
      _showHistory = value.isEmpty && _focusNode.hasFocus;
    });
    _debounce?.cancel();
    if (value.isEmpty) {
      setState(() => _results = []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 300), () => _search(value));
  }

  Future<void> _search(String query) async {
    if (query.isEmpty) return;
    setState(() => _searching = true);
    await _saveToHistory(query);
    if (!mounted) return;
    // Use MangaDex real search
    try {
      final results = await ref.read(mangaSearchProvider(query).future);
      if (!mounted) return;

      // Filter by NSFW toggle
      final filteredResults = results.where((m) {
        if (!_filters.showNsfw && m.isNsfw) return false;
        return true;
      }).toList();

      setState(() {
        _results = filteredResults;
        _searching = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _results = [];
        _searching = false;
      });
    }
  }

  void _selectHistory(String query) {
    _searchController.text = query;
    _onQueryChanged(query);
    _focusNode.unfocus();
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _FilterSheet(
        initial: _filters,
        onApply: (f) => setState(() => _filters = f),
      ),
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: TextField(
          controller: _searchController,
          focusNode: _focusNode,
          autofocus: true,
          style: AppTypography.bodyMedium.copyWith(color: AppColors.onSurface),
          decoration: InputDecoration(
            hintText: 'Search manga, manhwa, manhua…',
            border: InputBorder.none,
            hintStyle: AppTypography.bodyMedium.copyWith(
              color: AppColors.onSurfaceMuted,
            ),
            suffixIcon: _query.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 20),
                    color: AppColors.onSurfaceMuted,
                    onPressed: () {
                      _searchController.clear();
                      _onQueryChanged('');
                    },
                  )
                : null,
          ),
          onChanged: _onQueryChanged,
          onSubmitted: _search,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            color: AppColors.onSurface,
            tooltip: 'Filters',
            onPressed: _showFilterSheet,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_showHistory) {
      return _HistoryAndTrending(
        history: _history,
        onSelect: _selectHistory,
        onDelete: _removeFromHistory,
      );
    }

    if (_searching) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_query.isNotEmpty && _results.isEmpty) {
      return _EmptyState(query: _query);
    }

    if (_results.isEmpty) {
      return const SizedBox.shrink();
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 16,
        childAspectRatio: 0.55,
      ),
      itemCount: _results.length,
      itemBuilder: (ctx, i) {
        final manga = _results[i];
        return MangaCard(
          manga: manga,
          width: double.infinity,
          height: 200,
        );
      },
    );
  }
}

// ── History and trending ───────────────────────────────────────────────────────

class _HistoryAndTrending extends StatelessWidget {
  const _HistoryAndTrending({
    required this.history,
    required this.onSelect,
    required this.onDelete,
  });

  final List<String> history;
  final ValueChanged<String> onSelect;
  final ValueChanged<String> onDelete;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        // Recent searches
        if (history.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('Recent Searches', style: AppTypography.titleSmall),
          ),
          ...history.map(
            (q) => ListTile(
              leading: const Icon(
                Icons.history,
                color: AppColors.onSurfaceMuted,
              ),
              title: Text(q, style: AppTypography.bodyMedium),
              trailing: IconButton(
                icon: const Icon(Icons.close, size: 18),
                color: AppColors.onSurfaceMuted,
                onPressed: () => onDelete(q),
              ),
              onTap: () => onSelect(q),
            ),
          ),
          const Divider(color: AppColors.divider, height: 1),
        ],
        // Trending
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              const Icon(
                Icons.local_fire_department_rounded,
                color: Colors.orange,
                size: 18,
              ),
              const SizedBox(width: 6),
              Text('Trending', style: AppTypography.titleSmall),
            ],
          ),
        ),
        ..._trendingSearches.map(
          (q) => ListTile(
            leading: const Icon(
              Icons.trending_up,
              color: AppColors.onSurfaceMuted,
            ),
            title: Text(q, style: AppTypography.bodyMedium),
            onTap: () => onSelect(q),
          ),
        ),
      ],
    );
  }
}

// ── Empty state ────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 80,
              color: AppColors.onSurfaceMuted.withAlpha(100),
            ),
            const SizedBox(height: 16),
            Text(
              'No results found',
              style: AppTypography.titleMedium.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              'No results for "$query".\nTry different keywords or adjust your filters.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.onSurfaceMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Filter bottom sheet ────────────────────────────────────────────────────────

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({required this.initial, required this.onApply});

  final _FilterState initial;
  final ValueChanged<_FilterState> onApply;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late _FilterState _state;
  bool _nsfwConfirmed = false;

  @override
  void initState() {
    super.initState();
    _state = widget.initial;
    _loadNsfwConfirmation();
  }

  Future<void> _loadNsfwConfirmation() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() => _nsfwConfirmed = prefs.getBool('nsfw_confirmed') ?? false);
    }
  }

  Future<void> _toggleNsfw(bool value) async {
    if (value && !_nsfwConfirmed) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('Age Confirmation'),
          content: const Text(
            'Adult content is only available to users 18 years or older. '
            'Do you confirm that you are 18 or above?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('I am 18+'),
            ),
          ],
        ),
      );
      if (confirmed == true) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('nsfw_confirmed', true);
        if (mounted) setState(() => _nsfwConfirmed = true);
      } else {
        return;
      }
    }
    setState(() => _state = _state.copyWith(showNsfw: value));
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (_, scrollController) => Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Filters', style: AppTypography.titleMedium),
                TextButton(
                  onPressed: () {
                    setState(() => _state = const _FilterState());
                  },
                  child: Text(
                    'Reset',
                    style: AppTypography.labelLarge.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: AppColors.divider),
          Expanded(
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                // Genre multi-select
                Text('Genre', style: AppTypography.titleSmall),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _genres.map((g) {
                    final selected = _state.genres.contains(g);
                    return FilterChip(
                      label: Text(g),
                      selected: selected,
                      onSelected: (v) {
                        final genres = List<String>.from(_state.genres);
                        if (v) {
                          genres.add(g);
                        } else {
                          genres.remove(g);
                        }
                        setState(
                          () => _state = _state.copyWith(genres: genres),
                        );
                      },
                      selectedColor: AppColors.primary.withAlpha(60),
                      checkmarkColor: AppColors.primary,
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // Status
                Text('Status', style: AppTypography.titleSmall),
                const SizedBox(height: 8),
                ..._PublicationStatus.values.map(
                  (s) => RadioListTile<_PublicationStatus>(
                    title: Text(s.name[0].toUpperCase() + s.name.substring(1)),
                    value: s,
                    groupValue: _state.status,
                    activeColor: AppColors.primary,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (v) =>
                        setState(() => _state = _state.copyWith(status: v)),
                  ),
                ),
                const SizedBox(height: 12),

                // Language
                Text('Language', style: AppTypography.titleSmall),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _state.language,
                  dropdownColor: AppColors.surface,
                  decoration: const InputDecoration(),
                  items: ['All', 'English', 'Japanese', 'Korean', 'Chinese']
                      .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                      .toList(),
                  onChanged: (v) =>
                      setState(() => _state = _state.copyWith(language: v)),
                ),
                const SizedBox(height: 20),

                // Rating
                Text(
                  'Minimum Rating: ${_state.minRating.toStringAsFixed(1)}',
                  style: AppTypography.titleSmall,
                ),
                Slider(
                  value: _state.minRating,
                  min: 0,
                  max: 10,
                  divisions: 20,
                  activeColor: AppColors.primary,
                  onChanged: (v) =>
                      setState(() => _state = _state.copyWith(minRating: v)),
                ),
                const SizedBox(height: 12),

                // NSFW toggle
                SwitchListTile(
                  title: Text(
                    'Show Adult Content (18+)',
                    style: AppTypography.bodyMedium,
                  ),
                  value: _state.showNsfw,
                  activeColor: AppColors.primary,
                  contentPadding: EdgeInsets.zero,
                  onChanged: _toggleNsfw,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  widget.onApply(_state);
                  Navigator.of(context).pop();
                },
                child: const Text('Apply Filters'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
