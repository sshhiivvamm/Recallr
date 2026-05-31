import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../data/models/Link/link_model.dart';
import '../../../data/models/search/search_model.dart';
import '../../../theme/recallr_colors.dart';
import '../../../theme/ui_helpers.dart';
import '../../database/providers/isar_provider.dart';
import '../../repositrories/search/search_file.dart';

// ── Provider ─────────────────────────────────────────────────────────────────

final _searchParamsProvider = StateProvider<LinkSearchParams>(
      (_) =>  LinkSearchParams(),
);

final _searchResultsProvider =
FutureProvider.family<List<LinkModel>, LinkSearchParams>(
      (ref, params) async {
    final isar = await ref.read(isarProvider.future);
    return searchLinks(isar, params);
  },
);

// ── Screen ───────────────────────────────────────────────────────────────────

class ReSearch extends ConsumerStatefulWidget {
  const ReSearch({super.key});

  @override
  ConsumerState<ReSearch> createState() => _ReSearchState();
}

class _ReSearchState extends ConsumerState<ReSearch> {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();
  bool _showFilters = false;

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _updateQuery(String query) {
    ref.read(_searchParamsProvider.notifier).update(
          (s) => s.copyWith(query: query.isEmpty ? null : query),
    );
  }

  void _updateSort(LinkSort sort) {
    ref.read(_searchParamsProvider.notifier).update(
          (s) => s.copyWith(sort: sort),
    );
  }

  void _toggleFavorite() {
    final current = ref.read(_searchParamsProvider).isFavorite;
    ref.read(_searchParamsProvider.notifier).update(
          (s) => s.copyWith(isFavorite: current == true ? null : true),
    );
  }

  void _toggleRead() {
    final current = ref.read(_searchParamsProvider).isRead;
    ref.read(_searchParamsProvider.notifier).update(
          (s) => s.copyWith(isRead: current == false ? null : false),
    );
  }

  void _clearAll() {
    _ctrl.clear();
    ref.read(_searchParamsProvider.notifier).state =  LinkSearchParams();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final theme = Theme.of(context).textTheme;
    final params = ref.watch(_searchParamsProvider);
    final resultsAsync = ref.watch(_searchResultsProvider(params));
    final hasActiveFilters = params.isFavorite != null ||
        params.isRead != null ||
        params.tag != null ||
        params.folder != null;

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title row
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Search',
                          style: theme.displaySmall!.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                      if (hasActiveFilters || _ctrl.text.isNotEmpty)
                        GestureDetector(
                          onTap: _clearAll,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(color: c.border, width: 0.5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Clear all',
                              style: theme.labelMedium!.copyWith(
                                color: c.coral,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // ── Search bar ──────────────────────────
                  Container(
                    decoration: BoxDecoration(
                      color: c.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _focus.hasFocus ? c.accent : c.border,
                        width: _focus.hasFocus ? 1.5 : 0.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 14),
                        Icon(Icons.search_rounded, color: c.textHint, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _ctrl,
                            focusNode: _focus,
                            onChanged: _updateQuery,
                            style: theme.bodyMedium!.copyWith(
                              color: c.textPrimary,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Search titles, URLs, descriptions…',
                              hintStyle: theme.bodyMedium!.copyWith(
                                color: c.textHint,
                              ),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 14,
                              ),
                            ),
                          ),
                        ),
                        if (_ctrl.text.isNotEmpty)
                          GestureDetector(
                            onTap: () {
                              _ctrl.clear();
                              _updateQuery('');
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Icon(
                                Icons.close_rounded,
                                size: 16,
                                color: c.textHint,
                              ),
                            ),
                          )
                        else
                          GestureDetector(
                            onTap: () =>
                                setState(() => _showFilters = !_showFilters),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Icon(
                                _showFilters
                                    ? Icons.tune_rounded
                                    : Icons.tune_outlined,
                                size: 18,
                                color: _showFilters ? c.accent : c.textHint,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // ── Filter chips ─────────────────────────
                  AnimatedCrossFade(
                    duration: const Duration(milliseconds: 200),
                    crossFadeState: _showFilters
                        ? CrossFadeState.showFirst
                        : CrossFadeState.showSecond,
                    firstChild: _FilterRow(
                      params: params,
                      c: c,
                      theme: theme,
                      onFavorite: _toggleFavorite,
                      onUnread: _toggleRead,
                      onSort: _updateSort,
                    ),
                    secondChild: const SizedBox(width: double.infinity),
                  ),

                  // Active filter pills (always visible when active)
                  if (hasActiveFilters && !_showFilters)
                    _ActiveFilterPills(
                      params: params,
                      c: c,
                      theme: theme,
                    ),
                ],
              ),
            ),

            const SizedBox(height: 4),

            // ── Results ──────────────────────────────────────
            Expanded(
              child: resultsAsync.when(
                data: (links) {
                  if (params.query == null &&
                      params.query?.isEmpty != false &&
                      !hasActiveFilters) {
                    return _IdleState(c: c, theme: theme);
                  }
                  if (links.isEmpty) {
                    return _EmptyState(
                      c: c,
                      theme: theme,
                      query: params.query,
                    );
                  }
                  return _ResultsList(links: links, c: c, theme: theme);
                },
                loading: () => _LoadingState(c: c),
                error: (e, _) => _ErrorState(c: c, theme: theme),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Filter Row ───────────────────────────────────────────────────────────────

class _FilterRow extends StatelessWidget {
  final LinkSearchParams params;
  final dynamic c;
  final TextTheme theme;
  final VoidCallback onFavorite;
  final VoidCallback onUnread;
  final ValueChanged<LinkSort> onSort;

  const _FilterRow({
    required this.params,
    required this.c,
    required this.theme,
    required this.onFavorite,
    required this.onUnread,
    required this.onSort,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'FILTERS',
            style: theme.labelSmall!.copyWith(
              color: c.textHint,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterChip(
                  label: 'Favorites',
                  icon: Icons.bookmark_rounded,
                  active: params.isFavorite == true,
                  c: c,
                  theme: theme,
                  onTap: onFavorite,
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Unread',
                  icon: Icons.circle_outlined,
                  active: params.isRead == false,
                  c: c,
                  theme: theme,
                  onTap: onUnread,
                ),
                const SizedBox(width: 16),
                // Sort options
                Text(
                  'SORT',
                  style: theme.labelSmall!.copyWith(
                    color: c.textHint,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(width: 8),
                _SortChip(
                  label: 'Newest',
                  active: params.sort == LinkSort.newest,
                  c: c,
                  theme: theme,
                  onTap: () => onSort(LinkSort.newest),
                ),
                const SizedBox(width: 8),
                _SortChip(
                  label: 'Oldest',
                  active: params.sort == LinkSort.oldest,
                  c: c,
                  theme: theme,
                  onTap: () => onSort(LinkSort.oldest),
                ),
                const SizedBox(width: 8),
                _SortChip(
                  label: 'Last opened',
                  active: params.sort == LinkSort.lastOpened,
                  c: c,
                  theme: theme,
                  onTap: () => onSort(LinkSort.lastOpened),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final dynamic c;
  final TextTheme theme;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.icon,
    required this.active,
    required this.c,
    required this.theme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: active ? c.accentDim : c.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: active ? c.accent : c.border,
            width: active ? 1.0 : 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: active ? c.accent : c.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: theme.labelMedium!.copyWith(
                color: active ? c.accent : c.textSecondary,
                fontWeight: active ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SortChip extends StatelessWidget {
  final String label;
  final bool active;
  final dynamic c;
  final TextTheme theme;
  final VoidCallback onTap;

  const _SortChip({
    required this.label,
    required this.active,
    required this.c,
    required this.theme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: active ? c.accentDim : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: active ? c.accent : c.border,
            width: active ? 1.0 : 0.5,
          ),
        ),
        child: Text(
          label,
          style: theme.labelMedium!.copyWith(
            color: active ? c.accent : c.textSecondary,
            fontWeight: active ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

// ── Active filter pills ───────────────────────────────────────────────────────

class _ActiveFilterPills extends StatelessWidget {
  final LinkSearchParams params;
  final dynamic c;
  final TextTheme theme;

  const _ActiveFilterPills({
    required this.params,
    required this.c,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          if (params.isFavorite == true)
            _Pill(label: 'Favorites', c: c, theme: theme),
          if (params.isRead == false) ...[
            const SizedBox(width: 6),
            _Pill(label: 'Unread', c: c, theme: theme),
          ],
          if (params.sort != LinkSort.newest) ...[
            const SizedBox(width: 6),
            _Pill(
              label: params.sort == LinkSort.oldest ? 'Oldest' : 'Last opened',
              c: c,
              theme: theme,
            ),
          ],
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final dynamic c;
  final TextTheme theme;

  const _Pill({required this.label, required this.c, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: c.accentDim,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: theme.labelSmall!.copyWith(
          color: c.accent,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ── Results list ─────────────────────────────────────────────────────────────

class _ResultsList extends StatelessWidget {
  final List<LinkModel> links;
  final dynamic c;
  final TextTheme theme;

  const _ResultsList({
    required this.links,
    required this.c,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: Row(
            children: [
              Text(
                '${links.length} result${links.length == 1 ? '' : 's'}',
                style: theme.labelMedium!.copyWith(color: c.textHint),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            itemCount: links.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              return _SearchResultCard(
                link: links[index],
                c: c,
                theme: theme,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SearchResultCard extends StatelessWidget {
  final LinkModel link;
  final dynamic c;
  final TextTheme theme;

  const _SearchResultCard({
    required this.link,
    required this.c,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.border, width: 0.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Favicon
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: c.surfaceElevated,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: c.borderSoft, width: 0.5),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: link.favicon != null
                  ? Image.network(
                link.favicon!,
                height: 34,
                width: 34,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Icon(
                  Icons.link_rounded,
                  color: c.textHint,
                  size: 16,
                ),
              )
                  : Icon(Icons.link_rounded, color: c.textHint, size: 16),
            ),
          ),

          const SizedBox(width: 12),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title + badges
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        link.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.titleSmall!.copyWith(
                          fontWeight: FontWeight.w600,
                          color: c.textPrimary,
                          height: 1.35,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (link.isFavorite)
                          Icon(
                            Icons.bookmark_rounded,
                            size: 14,
                            color: c.accent,
                          ),
                        if (!link.isRead) ...[
                          const SizedBox(width: 4),
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: c.accent,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 4),

                // Domain
                Row(
                  children: [
                    Icon(Icons.language_rounded, size: 11, color: c.textHint),
                    const SizedBox(width: 4),
                    Text(
                      link.domain ?? '',
                      style: theme.bodySmall!.copyWith(
                        color: c.textHint,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),

                if ((link.description ?? '').isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    link.description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.bodySmall!.copyWith(
                      color: c.textSecondary,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],

                const SizedBox(height: 8),

                // Tags + date
                Row(
                  children: [
                    if (link.tags.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: c.accentDim,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          link.tags.first.name.toUpperCase(),
                          style: theme.labelSmall!.copyWith(
                            color: c.accent,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 11,
                      color: c.textHint,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat.yMMMd().format(link.createdAt),
                      style: theme.bodySmall!.copyWith(
                        color: c.textHint,
                        fontSize: 11,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.more_horiz_rounded,
                      size: 16,
                      color: c.textSecondary,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Thumbnail
          if (link.thumbnail != null && link.thumbnail!.isNotEmpty) ...[
            const SizedBox(width: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                link.thumbnail!,
                height: 60,
                width: 60,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── States ───────────────────────────────────────────────────────────────────

class _IdleState extends StatelessWidget {
  final dynamic c;
  final TextTheme theme;

  const _IdleState({required this.c, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: c.surfaceElevated,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: c.border, width: 0.5),
            ),
            child: Icon(
              Icons.search_rounded,
              color: c.textHint,
              size: 24,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Search your saves',
            style: theme.titleSmall!.copyWith(
              fontWeight: FontWeight.w600,
              color: c.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Type or use filters to find links',
            style: theme.bodySmall!.copyWith(color: c.textHint),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final dynamic c;
  final TextTheme theme;
  final String? query;

  const _EmptyState({required this.c, required this.theme, this.query});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: c.surfaceElevated,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: c.border, width: 0.5),
            ),
            child: Icon(
              Icons.search_off_rounded,
              color: c.textHint,
              size: 24,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'No results found',
            style: theme.titleSmall!.copyWith(
              fontWeight: FontWeight.w600,
              color: c.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            query != null ? 'Nothing matched "$query"' : 'Try different filters',
            style: theme.bodySmall!.copyWith(color: c.textHint),
          ),
        ],
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  final dynamic c;
  const _LoadingState({required this.c});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      itemCount: 5,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, __) => _SkeletonCard(c: c),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  final dynamic c;
  const _SkeletonCard({required this.c});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.border, width: 0.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Bone(width: 34, height: 34, radius: 8, c: c),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Bone(width: double.infinity, height: 13, radius: 4, c: c),
                const SizedBox(height: 6),
                _Bone(width: 100, height: 10, radius: 4, c: c),
                const SizedBox(height: 8),
                _Bone(width: double.infinity, height: 10, radius: 4, c: c),
                const SizedBox(height: 4),
                _Bone(width: 140, height: 10, radius: 4, c: c),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final dynamic c;
  final TextTheme theme;
  const _ErrorState({required this.c, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.wifi_off_rounded, color: c.textHint, size: 32),
          const SizedBox(height: 12),
          Text(
            'Search failed',
            style: theme.titleSmall!.copyWith(color: c.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            'Please try again',
            style: theme.bodySmall!.copyWith(color: c.textHint),
          ),
        ],
      ),
    );
  }
}

class _Bone extends StatelessWidget {
  final double width, height, radius;
  final dynamic c;

  const _Bone({
    required this.width,
    required this.height,
    required this.radius,
    required this.c,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: c.surfaceElevated,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}