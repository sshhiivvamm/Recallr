import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../common/all_links_wid.dart';
import '../../../common/chips_filter.dart';
import '../../../data/models/search/search_model.dart';
import '../../../theme/recallr_colors.dart';
import '../../repositrories/search/search_provider.dart';

// ── Screen ───────────────────────────────────────────────────────────────────

class AllLinksScreen extends ConsumerStatefulWidget {
  const AllLinksScreen({super.key});

  @override
  ConsumerState<AllLinksScreen> createState() => _AllLinksScreenState();
}

class _AllLinksScreenState extends ConsumerState<AllLinksScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  bool _showElevation = false;

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _updateQuery(String query) {
    ref
        .read(searchParamsProvider.notifier)
        .update((s) => s.copyWith(query: query.isEmpty ? null : query));
  }

  void _updateSort(LinkSort sort) {
    ref
        .read(searchParamsProvider.notifier)
        .update((s) => s.copyWith(sort: sort));
  }

  void _toggleFavorite() {
    final current = ref.read(searchParamsProvider).isFavorite;
    ref
        .read(searchParamsProvider.notifier)
        .update((s) => s.copyWith(isFavorite: current == true ? null : true));
  }

  void _toggleRead() {
    final current = ref.read(searchParamsProvider).isRead;
    ref
        .read(searchParamsProvider.notifier)
        .update((s) => s.copyWith(isRead: current == false ? null : false));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final theme = Theme.of(context).textTheme;
    final params = ref.watch(searchParamsProvider);
    final viewMode = ref.watch(viewModeProvider);
    final linksAsync = ref.watch(searchResultsProvider(params));

    final activeFilterCount = [
      params.isFavorite != null,
      params.isRead != null,
      params.tag != null,
      params.folder != null,
    ].where((v) => v).length;

    return Scaffold(
      backgroundColor: c.background,
      body: NestedScrollView(
        controller: _scrollController,
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            pinned: true,
            backgroundColor: c.background,
            elevation: _showElevation ? 0 : 0,
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back_rounded,
                color: c.textPrimary,
                size: 20,
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              'Library',
              style: theme.titleLarge!.copyWith(fontWeight: FontWeight.w700),
            ),
            actions: [
              // View toggle
              Container(
                margin: const EdgeInsets.only(right: 6),
                decoration: BoxDecoration(
                  color: c.surfaceElevated,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: c.border, width: 0.5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ViewToggleBtn(
                      icon: Icons.view_agenda_outlined,
                      selected: viewMode == ViewMode.list,
                      onTap: () => ref.read(viewModeProvider.notifier).state =
                          ViewMode.list,
                      c: c,
                    ),
                    ViewToggleBtn(
                      icon: Icons.density_small_rounded,
                      selected: viewMode == ViewMode.compact,
                      onTap: () => ref.read(viewModeProvider.notifier).state =
                          ViewMode.compact,
                      c: c,
                    ),
                  ],
                ),
              ),

              // Sort button
              Container(
                margin: const EdgeInsets.only(right: 14),
                decoration: BoxDecoration(
                  color: c.surfaceElevated,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: c.border, width: 0.5),
                ),
                child: PopupMenuButton<LinkSort>(
                  icon: Icon(
                    Icons.sort_rounded,
                    size: 18,
                    color: c.textSecondary,
                  ),
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                  color: c.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: c.border, width: 0.5),
                  ),
                  onSelected: _updateSort,
                  itemBuilder: (_) => [
                    _sortItem(
                      'Newest first',
                      LinkSort.newest,
                      params.sort,
                      Icons.arrow_downward_rounded,
                      c,
                      theme,
                    ),
                    _sortItem(
                      'Oldest first',
                      LinkSort.oldest,
                      params.sort,
                      Icons.arrow_upward_rounded,
                      c,
                      theme,
                    ),
                    _sortItem(
                      'Last opened',
                      LinkSort.lastOpened,
                      params.sort,
                      Icons.history_rounded,
                      c,
                      theme,
                    ),
                  ],
                ),
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(50),
              child: Column(
                children: [
                  // Filter chips
                  SizedBox(
                    height: 38,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      children: [
                        AppFilterChip(
                          label: 'Favorites',
                          icon: Icons.bookmark_rounded,
                          active: params.isFavorite == true,
                          onTap: _toggleFavorite,
                          c: c,
                          theme: theme,
                        ),
                        const SizedBox(width: 8),
                        AppFilterChip(
                          label: 'Unread',
                          icon: Icons.circle_outlined,
                          active: params.isRead == false,
                          onTap: _toggleRead,
                          c: c,
                          theme: theme,
                        ),
                        if (activeFilterCount > 0) ...[
                          const SizedBox(width: 8),
                          ClearChip(
                            count: activeFilterCount,
                            onTap: () {
                              ref.read(searchParamsProvider.notifier).state =
                                  LinkSearchParams();
                            },
                            c: c,
                            theme: theme,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        body: linksAsync.when(
          data: (links) {
            if (links.isEmpty) {
              return EmptyState(c: c, theme: theme);
            }

            return Column(
              children: [
                // Result count bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                  child: Row(
                    children: [
                      Text(
                        '${links.length} ${links.length == 1 ? 'link' : 'links'}',
                        style: theme.labelMedium!.copyWith(color: c.textHint),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: viewMode == ViewMode.list
                      ? ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                          itemCount: links.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (_, i) => LinkCard(
                            link: links[i],
                            c: c,
                            theme: theme,
                            onTap: () => _launch(context, links[i].url),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                          itemCount: links.length,
                          separatorBuilder: (_, __) =>
                              Divider(color: c.border, height: 1),
                          itemBuilder: (_, i) => CompactRow(
                            link: links[i],
                            c: c,
                            theme: theme,
                            onTap: () => _launch(context, links[i].url),
                          ),
                        ),
                ),
              ],
            );
          },
          loading: () => ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            itemCount: 6,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, __) => SkeletonCard(c: c),
          ),
          error: (e, _) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline_rounded, color: c.textHint, size: 32),
                const SizedBox(height: 12),
                Text(
                  'Something went wrong',
                  style: theme.titleSmall!.copyWith(color: c.textPrimary),
                ),
                const SizedBox(height: 4),
                Text(
                  e.toString(),
                  style: theme.bodySmall!.copyWith(color: c.textHint),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  PopupMenuItem<LinkSort> _sortItem(
    String label,
    LinkSort value,
    LinkSort current,
    IconData icon,
    dynamic c,
    TextTheme theme,
  ) {
    final selected = current == value;
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 16, color: selected ? c.accent : c.textSecondary),
          const SizedBox(width: 10),
          Text(
            label,
            style: theme.bodyMedium!.copyWith(
              color: selected ? c.accent : c.textPrimary,
              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          if (selected) ...[
            const Spacer(),
            Icon(Icons.check_rounded, size: 14, color: c.accent),
          ],
        ],
      ),
    );
  }
}

// ── URL launcher helper ───────────────────────────────────────────────────────

Future<void> _launch(BuildContext context, String? rawUrl) async {
  if (rawUrl == null || rawUrl.isEmpty) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Invalid URL')));
    return;
  }
  final uri = Uri.parse(rawUrl.startsWith('http') ? rawUrl : 'https://$rawUrl');
  try {
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok) throw 'Could not launch';
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Cannot open link')));
    }
  }
}
