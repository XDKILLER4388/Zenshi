import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../domain/entities/extension_info.dart';
import '../../providers/extension_list_provider.dart';

// ── Mock marketplace data ──────────────────────────────────────────────────────

final _mockAvailableExtensions = [
  const ExtensionInfo(
    id: 'mangadex',
    name: 'MangaDex',
    version: '1.4.2',
    sourceClass: 'MangaDexSource',
    allowedDomains: ['mangadex.org', 'uploads.mangadex.org'],
    sourceType: SourceType.aggregator,
    language: 'Multi',
    healthStatus: ExtensionHealthStatus.healthy,
  ),
  const ExtensionInfo(
    id: 'mangaplus',
    name: 'MANGA Plus',
    version: '1.2.0',
    sourceClass: 'MangaPlusSource',
    allowedDomains: ['mangaplus.shueisha.co.jp'],
    sourceType: SourceType.manga,
    language: 'EN',
    healthStatus: ExtensionHealthStatus.healthy,
  ),
  const ExtensionInfo(
    id: 'webtoons',
    name: 'Webtoons',
    version: '2.0.1',
    sourceClass: 'WebtoonsSource',
    allowedDomains: ['webtoons.com'],
    sourceType: SourceType.webtoon,
    language: 'EN',
    healthStatus: ExtensionHealthStatus.degraded,
  ),
  const ExtensionInfo(
    id: 'manganato',
    name: 'Manganato',
    version: '1.1.3',
    sourceClass: 'ManganatoSource',
    allowedDomains: ['manganato.com', 'chapmanganato.to'],
    sourceType: SourceType.manga,
    language: 'EN',
    healthStatus: ExtensionHealthStatus.unavailable,
  ),
  const ExtensionInfo(
    id: 'bato',
    name: 'Bato.to',
    version: '1.0.5',
    sourceClass: 'BatoSource',
    allowedDomains: ['bato.to'],
    sourceType: SourceType.aggregator,
    language: 'Multi',
    healthStatus: ExtensionHealthStatus.healthy,
  ),
];

// ── Extension marketplace screen ───────────────────────────────────────────────

/// Extension marketplace screen with Installed and Available tabs.
///
/// Features:
/// - Two tabs: Installed and Available
/// - Search/filter bar at top
/// - Extension cards with name, version, source type badge, language, health indicator
/// - Install/uninstall/update buttons
/// - Drag-to-reorder for installed extensions (source prioritization)
/// - Multi-source merging note
/// - Update check button in app bar
/// - Empty states for each tab
class ExtensionMarketplaceScreen extends ConsumerStatefulWidget {
  const ExtensionMarketplaceScreen({super.key});

  @override
  ConsumerState<ExtensionMarketplaceScreen> createState() =>
      _ExtensionMarketplaceScreenState();
}

class _ExtensionMarketplaceScreenState
    extends ConsumerState<ExtensionMarketplaceScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _searchController = TextEditingController();
  String _searchQuery = '';
  bool _checkingUpdates = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _checkForUpdates() async {
    setState(() => _checkingUpdates = true);
    try {
      await ref.read(extensionListProvider.notifier).checkForUpdates();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Extensions are up to date')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to check for updates')),
        );
      }
    } finally {
      if (mounted) setState(() => _checkingUpdates = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final installedAsync = ref.watch(extensionListProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text('Extensions', style: AppTypography.titleMedium),
        actions: [
          Semantics(
            label: 'Check for extension updates',
            child: IconButton(
              icon: _checkingUpdates
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    )
                  : const Icon(Icons.system_update_alt_outlined),
              tooltip: 'Check for updates',
              onPressed: _checkingUpdates ? null : _checkForUpdates,
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.onSurfaceMuted,
          tabs: const [
            Tab(text: 'Installed'),
            Tab(text: 'Available'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Semantics(
              label: 'Search extensions',
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
                decoration: InputDecoration(
                  hintText: 'Search extensions…',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          tooltip: 'Clear search',
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                ),
              ),
            ),
          ),

          // Multi-source merging note
          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(20),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.primary.withAlpha(60)),
            ),
            child: Row(
              children: [
                const Icon(Icons.merge_type,
                    size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Multi-source merging: same titles across extensions are deduplicated automatically.',
                    style: AppTypography.bodySmall
                        .copyWith(color: AppColors.primary),
                  ),
                ),
              ],
            ),
          ),

          // Tab views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Installed tab
                installedAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                  error: (e, _) => Center(
                    child: Text(
                      'Failed to load extensions',
                      style: AppTypography.bodyMedium,
                    ),
                  ),
                  data: (installed) {
                    final filtered = _filterExtensions(installed);
                    if (filtered.isEmpty) {
                      return _EmptyState(
                        icon: Icons.extension_off_outlined,
                        title: _searchQuery.isNotEmpty
                            ? 'No results for "$_searchQuery"'
                            : 'No extensions installed',
                        subtitle: _searchQuery.isNotEmpty
                            ? 'Try a different search term.'
                            : 'Browse the Available tab to install extensions.',
                      );
                    }
                    return _InstalledExtensionList(
                      extensions: filtered,
                      onUninstall: (id) => ref
                          .read(extensionListProvider.notifier)
                          .uninstall(id),
                      onUpdate: (id) => ref
                          .read(extensionListProvider.notifier)
                          .updateExtension(id),
                    );
                  },
                ),

                // Available tab
                _AvailableExtensionsTab(
                  searchQuery: _searchQuery,
                  installedAsync: installedAsync,
                  onInstall: (id) =>
                      ref.read(extensionListProvider.notifier).install(id),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<ExtensionInfo> _filterExtensions(List<ExtensionInfo> extensions) {
    if (_searchQuery.isEmpty) return extensions;
    return extensions
        .where((e) =>
            e.name.toLowerCase().contains(_searchQuery) ||
            e.language.toLowerCase().contains(_searchQuery) ||
            e.sourceType.name.toLowerCase().contains(_searchQuery))
        .toList();
  }
}

// ── Installed extension list (drag-to-reorder) ─────────────────────────────────

class _InstalledExtensionList extends StatefulWidget {
  const _InstalledExtensionList({
    required this.extensions,
    required this.onUninstall,
    required this.onUpdate,
  });

  final List<ExtensionInfo> extensions;
  final ValueChanged<String> onUninstall;
  final ValueChanged<String> onUpdate;

  @override
  State<_InstalledExtensionList> createState() =>
      _InstalledExtensionListState();
}

class _InstalledExtensionListState extends State<_InstalledExtensionList> {
  late List<ExtensionInfo> _ordered;

  @override
  void initState() {
    super.initState();
    _ordered = List.from(widget.extensions);
  }

  @override
  void didUpdateWidget(_InstalledExtensionList old) {
    super.didUpdateWidget(old);
    if (old.extensions != widget.extensions) {
      _ordered = List.from(widget.extensions);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Text(
            'Drag to set source priority (top = highest)',
            style: AppTypography.bodySmall,
          ),
        ),
        Expanded(
          child: ReorderableListView.builder(
            padding: const EdgeInsets.only(bottom: 24),
            itemCount: _ordered.length,
            onReorder: (oldIndex, newIndex) {
              setState(() {
                if (newIndex > oldIndex) newIndex--;
                final item = _ordered.removeAt(oldIndex);
                _ordered.insert(newIndex, item);
              });
            },
            itemBuilder: (context, index) {
              final ext = _ordered[index];
              return _ExtensionCard(
                key: ValueKey(ext.id),
                extension: ext,
                isInstalled: true,
                priorityIndex: index + 1,
                onAction: () => _showUninstallDialog(context, ext),
                actionLabel: 'Uninstall',
                actionColor: AppColors.error,
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _showUninstallDialog(
      BuildContext context, ExtensionInfo ext) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Uninstall ${ext.name}?', style: AppTypography.titleSmall),
        content: Text(
          'This will remove the extension and all associated cached metadata.',
          style: AppTypography.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error),
            child: const Text('Uninstall'),
          ),
        ],
      ),
    );
    if (confirmed == true) widget.onUninstall(ext.id);
  }
}

// ── Available extensions tab ───────────────────────────────────────────────────

class _AvailableExtensionsTab extends StatelessWidget {
  const _AvailableExtensionsTab({
    required this.searchQuery,
    required this.installedAsync,
    required this.onInstall,
  });

  final String searchQuery;
  final AsyncValue<List<ExtensionInfo>> installedAsync;
  final ValueChanged<String> onInstall;

  @override
  Widget build(BuildContext context) {
    final installedIds =
        installedAsync.valueOrNull?.map((e) => e.id).toSet() ?? {};

    final available = _mockAvailableExtensions
        .where((e) => !installedIds.contains(e.id))
        .where((e) =>
            searchQuery.isEmpty ||
            e.name.toLowerCase().contains(searchQuery) ||
            e.language.toLowerCase().contains(searchQuery) ||
            e.sourceType.name.toLowerCase().contains(searchQuery))
        .toList();

    if (available.isEmpty) {
      return _EmptyState(
        icon: Icons.extension_outlined,
        title: searchQuery.isNotEmpty
            ? 'No results for "$searchQuery"'
            : 'All extensions installed',
        subtitle: searchQuery.isNotEmpty
            ? 'Try a different search term.'
            : 'You have installed all available extensions.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: available.length,
      itemBuilder: (context, index) {
        final ext = available[index];
        return _ExtensionCard(
          key: ValueKey(ext.id),
          extension: ext,
          isInstalled: false,
          onAction: () => onInstall(ext.id),
          actionLabel: 'Install',
          actionColor: AppColors.primary,
        );
      },
    );
  }
}

// ── Extension card ─────────────────────────────────────────────────────────────

class _ExtensionCard extends StatelessWidget {
  const _ExtensionCard({
    super.key,
    required this.extension,
    required this.isInstalled,
    required this.onAction,
    required this.actionLabel,
    required this.actionColor,
    this.priorityIndex,
  });

  final ExtensionInfo extension;
  final bool isInstalled;
  final VoidCallback onAction;
  final String actionLabel;
  final Color actionColor;
  final int? priorityIndex;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${extension.name} extension, ${extension.healthStatus.name}',
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // Priority index (installed only)
            if (priorityIndex != null) ...[
              SizedBox(
                width: 24,
                child: Text(
                  '$priorityIndex',
                  style: AppTypography.labelSmall,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 8),
            ],

            // Extension icon placeholder
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.extension,
                  size: 22, color: AppColors.onSurfaceMuted),
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          extension.name,
                          style: AppTypography.labelLarge,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Health indicator dot
                      _HealthDot(status: extension.healthStatus),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        'v${extension.version}',
                        style: AppTypography.bodySmall,
                      ),
                      const SizedBox(width: 8),
                      _SourceTypeBadge(type: extension.sourceType),
                      const SizedBox(width: 8),
                      Text(
                        extension.language,
                        style: AppTypography.bodySmall,
                      ),
                    ],
                  ),
                  if (extension.healthStatus != ExtensionHealthStatus.healthy)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        extension.healthStatus == ExtensionHealthStatus.degraded
                            ? 'Degraded — some content may be unavailable'
                            : 'Unavailable — source is unreachable',
                        style: AppTypography.bodySmall.copyWith(
                          color: extension.healthStatus ==
                                  ExtensionHealthStatus.degraded
                              ? AppColors.warning
                              : AppColors.error,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Action button
            Semantics(
              label: '$actionLabel ${extension.name}',
              child: TextButton(
                onPressed: onAction,
                style: TextButton.styleFrom(
                  foregroundColor: actionColor,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  minimumSize: const Size(48, 36),
                ),
                child: Text(actionLabel,
                    style: AppTypography.labelMedium
                        .copyWith(color: actionColor)),
              ),
            ),

            // Drag handle (installed only)
            if (isInstalled)
              const Icon(Icons.drag_handle,
                  size: 20, color: AppColors.onSurfaceMuted),
          ],
        ),
      ),
    );
  }
}

// ── Health dot ─────────────────────────────────────────────────────────────────

class _HealthDot extends StatelessWidget {
  const _HealthDot({required this.status});

  final ExtensionHealthStatus status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      ExtensionHealthStatus.healthy => AppColors.success,
      ExtensionHealthStatus.degraded => AppColors.warning,
      ExtensionHealthStatus.unavailable => AppColors.error,
    };
    final label = switch (status) {
      ExtensionHealthStatus.healthy => 'Healthy',
      ExtensionHealthStatus.degraded => 'Degraded',
      ExtensionHealthStatus.unavailable => 'Unavailable',
    };

    return Semantics(
      label: 'Health: $label',
      child: Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

// ── Source type badge ──────────────────────────────────────────────────────────

class _SourceTypeBadge extends StatelessWidget {
  const _SourceTypeBadge({required this.type});

  final SourceType type;

  @override
  Widget build(BuildContext context) {
    final label = switch (type) {
      SourceType.manga => 'Manga',
      SourceType.manhua => 'Manhua',
      SourceType.manhwa => 'Manhwa',
      SourceType.webtoon => 'Webtoon',
      SourceType.aggregator => 'Multi',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primary.withAlpha(30),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: AppTypography.labelSmall.copyWith(color: AppColors.primary),
      ),
    );
  }
}

// ── Empty state ────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 72, color: AppColors.onSurfaceMuted),
            const SizedBox(height: 16),
            Text(title, style: AppTypography.titleSmall),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: AppTypography.bodyMedium
                  .copyWith(color: AppColors.onSurfaceMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
