import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:recallr/common/link_options_sheet.dart';

import '../../../data/models/search/search_model.dart';
import '../../../theme/recallr_colors.dart';
import '../../database/providers/isar_provider.dart';
import '../../repositrories/search/search_file.dart';

// ── Providers ─────────────────────────────────────────────────────────────────

final _searchParamsProvider = StateProvider<LinkSearchParams>(
  (_) => LinkSearchParams(),
);

final _searchResultsProvider =
    FutureProvider.family<List<SearchResult>, LinkSearchParams>(
  (ref, params) async {
    final isar = await ref.read(isarProvider.future);
    return searchLinks(isar, params);
  },
);

// ── Screen ────────────────────────────────────────────────────────────────────

class ReSearch extends ConsumerStatefulWidget {
  const ReSearch({super.key});

  @override
  ConsumerState<ReSearch> createState() => _ReSearchState();
}

class _ReSearchState extends ConsumerState<ReSearch> {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();
  int _hintIndex = 0;
  Timer? _hintTimer;

  static const _hints = [
    'Search titles, descriptions, notes…',
    'Try "flutter", "design", "tools"…',
    'Search by domain or tag…',
    'Find your unread saves…',
  ];

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
    _hintTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!_focus.hasFocus && _ctrl.text.isEmpty && mounted) {
        setState(() => _hintIndex = (_hintIndex + 1) % _hints.length);
      }
    });
  }

  @override
  void dispose() {
    _hintTimer?.cancel();
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

  void _toggleUnread() {
    final current = ref.read(_searchParamsProvider).isRead;
    ref.read(_searchParamsProvider.notifier).update(
          (s) => s.copyWith(isRead: current == false ? null : false),
        );
  }

  void _clearAll() {
    _ctrl.clear();
    ref.read(_searchParamsProvider.notifier).state = LinkSearchParams();
  }

  void _applySuggestion(String text) {
    _ctrl.text = text;
    _updateQuery(text);
    _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final theme = Theme.of(context).textTheme;
    final params = ref.watch(_searchParamsProvider);
    final resultsAsync = ref.watch(_searchResultsProvider(params));
    final hasQuery =
        params.query != null && params.query!.isNotEmpty;
    final hasFilters = params.isFavorite != null ||
        params.isRead != null;
    final hasAny = hasQuery || hasFilters;

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        bottom: false,
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
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Search',
                              style: theme.displaySmall!.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                              ),
                            ),
                            Text(
                              'Find anything you\'ve saved',
                              style: theme.bodySmall!
                                  .copyWith(color: c.textHint),
                            ),
                          ],
                        ),
                      ),
                      if (hasAny)
                        GestureDetector(
                          onTap: _clearAll,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: c.coralDim,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: c.coral.withValues(alpha: 0.3),
                                  width: 0.5),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.close_rounded,
                                    size: 12, color: c.coral),
                                const SizedBox(width: 4),
                                Text(
                                  'Clear',
                                  style: theme.labelSmall!.copyWith(
                                    color: c.coral,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // ── Search bar ────────────────────────────
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _focus.requestFocus(),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: c.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _focus.hasFocus ? c.accent : c.border,
                          width: 1.0,
                        ),
                        boxShadow: _focus.hasFocus
                            ? [
                                BoxShadow(
                                  color: c.accent.withValues(alpha: 0.12),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : [],
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 14),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: Icon(
                              Icons.search_rounded,
                              key: ValueKey(_focus.hasFocus),
                              color: _focus.hasFocus ? c.accent : c.textHint,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Stack(
                              alignment: Alignment.centerLeft,
                              children: [
                                if (_ctrl.text.isEmpty)
                                  IgnorePointer(
                                    child: _AnimatedHintText(
                                      text: _hints[_hintIndex],
                                      style: theme.bodyMedium!
                                          .copyWith(color: c.textHint),
                                    ),
                                  ),
                                TextField(
                                  controller: _ctrl,
                                  focusNode: _focus,
                                  onChanged: _updateQuery,
                                  style: theme.bodyMedium!
                                      .copyWith(color: c.textPrimary),
                                  decoration: InputDecoration(
                                    hintText: '',
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    filled: true,
                                    fillColor: Colors.transparent,
                                    isDense: true,
                                    contentPadding:
                                        const EdgeInsets.symmetric(vertical: 9),
                                  ),
                                ),
                              ],
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
                                child: Container(
                                  width: 18,
                                  height: 18,
                                  decoration: BoxDecoration(
                                    color: c.surfaceElevated,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.close_rounded,
                                      size: 12, color: c.textHint),
                                ),
                              ),
                            )
                          else
                            const SizedBox(width: 14),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ── Filter chips (always visible) ─────────
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _QuickChip(
                          label: 'Unread',
                          icon: Icons.fiber_manual_record,
                          active: params.isRead == false,
                          accent: c.accent,
                          c: c,
                          theme: theme,
                          onTap: _toggleUnread,
                        ),
                        const SizedBox(width: 8),
                        _QuickChip(
                          label: 'Favorites',
                          icon: Icons.bookmark_rounded,
                          active: params.isFavorite == true,
                          accent: c.amber,
                          c: c,
                          theme: theme,
                          onTap: _toggleFavorite,
                        ),
                        const SizedBox(width: 8),
                        _SortChipRow(
                          currentSort: params.sort,
                          c: c,
                          theme: theme,
                          onSort: _updateSort,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 4),
                ],
              ),
            ),

            // ── Results ──────────────────────────────────────
            Expanded(
              child: resultsAsync.when(
                data: (results) {
                  if (!hasAny) return _IdleState(c: c, theme: theme, onSuggestionTap: _applySuggestion);
                  if (results.isEmpty) {
                    return _EmptyState(
                        c: c, theme: theme, query: params.query);
                  }
                  return _ResultsList(
                    results: results,
                    query: params.query,
                    c: c,
                    theme: theme,
                  );
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

// ── Quick Chip ────────────────────────────────────────────────────────────────

class _QuickChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final Color accent;
  final AppColorScheme c;
  final TextTheme theme;
  final VoidCallback onTap;

  const _QuickChip({
    required this.label,
    required this.icon,
    required this.active,
    required this.accent,
    required this.c,
    required this.theme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: active ? accent.withValues(alpha: 0.15) : c.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: active ? accent : c.borderSoft,
            width: active ? 1.0 : 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 12,
              color: active ? accent : c.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: theme.labelMedium!.copyWith(
                color: active ? accent : c.textSecondary,
                fontWeight:
                    active ? FontWeight.w700 : FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sort Chip Row ─────────────────────────────────────────────────────────────

class _SortChipRow extends StatelessWidget {
  final LinkSort currentSort;
  final AppColorScheme c;
  final TextTheme theme;
  final ValueChanged<LinkSort> onSort;

  const _SortChipRow({
    required this.currentSort,
    required this.c,
    required this.theme,
    required this.onSort,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 0.5,
          height: 20,
          color: c.borderSoft,
          margin: const EdgeInsets.only(right: 8),
        ),
        _SortPill(
          label: 'Newest',
          active: currentSort == LinkSort.newest,
          c: c,
          theme: theme,
          onTap: () => onSort(LinkSort.newest),
        ),
        const SizedBox(width: 6),
        _SortPill(
          label: 'Oldest',
          active: currentSort == LinkSort.oldest,
          c: c,
          theme: theme,
          onTap: () => onSort(LinkSort.oldest),
        ),
        const SizedBox(width: 6),
        _SortPill(
          label: 'Last opened',
          active: currentSort == LinkSort.lastOpened,
          c: c,
          theme: theme,
          onTap: () => onSort(LinkSort.lastOpened),
        ),
      ],
    );
  }
}

class _SortPill extends StatelessWidget {
  final String label;
  final bool active;
  final AppColorScheme c;
  final TextTheme theme;
  final VoidCallback onTap;

  const _SortPill({
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
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: active ? c.accentDim : Colors.transparent,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: active ? c.accent : c.border,
            width: active ? 1.0 : 0.5,
          ),
        ),
        child: Text(
          label,
          style: theme.labelMedium!.copyWith(
            color: active ? c.accent : c.textSecondary,
            fontWeight:
                active ? FontWeight.w700 : FontWeight.w400,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

// ── Results list ──────────────────────────────────────────────────────────────

class _ResultsList extends StatelessWidget {
  final List<SearchResult> results;
  final String? query;
  final AppColorScheme c;
  final TextTheme theme;

  const _ResultsList({
    required this.results,
    required this.query,
    required this.c,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: c.surfaceElevated,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${results.length} result${results.length == 1 ? '' : 's'}',
                  style: theme.labelSmall!
                      .copyWith(color: c.textHint, fontSize: 11),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
            itemCount: results.length,
            separatorBuilder: (ctx, i) =>
                const SizedBox(height: 10),
            itemBuilder: (context, index) {
              return _SearchResultCard(
                result: results[index],
                query: query,
              );
            },
          ),
        ),
      ],
    );
  }
}

// ── Search Result Card ────────────────────────────────────────────────────────

class _SearchResultCard extends ConsumerStatefulWidget {
  final SearchResult result;
  final String? query;
  const _SearchResultCard({required this.result, this.query});

  @override
  ConsumerState<_SearchResultCard> createState() =>
      _SearchResultCardState();
}

class _SearchResultCardState
    extends ConsumerState<_SearchResultCard> {
  bool _pressed = false;

  int get _readTime {
    final link = widget.result.link;
    final words =
        '${link.title} ${link.description ?? ''}'
            .split(RegExp(r'\s+'))
            .where((w) => w.isNotEmpty)
            .length;
    return (words / 200).ceil().clamp(1, 99);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final theme = Theme.of(context).textTheme;
    final link = widget.result.link;
    final matchedField = widget.result.matchedField;
    final snippet = widget.result.snippet;
    final query = widget.query;
    final showSnippet = matchedField != MatchedField.title &&
        snippet != null &&
        query != null;

    return Listener(
      onPointerDown: (_) => setState(() => _pressed = true),
      onPointerUp: (_) => setState(() => _pressed = false),
      onPointerCancel: (_) => setState(() => _pressed = false),
      child: GestureDetector(
        onTap: () {
          if (link.url.isEmpty) return;
          context.push(
              '/reader', extra: {'url': link.url, 'linkId': link.id});
        },
        child: AnimatedScale(
          scale: _pressed ? 0.972 : 1.0,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color:
                  _pressed ? c.surfaceElevated : c.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color:
                    _pressed ? c.accentBorder : c.border,
                width: _pressed ? 1.0 : 0.5,
              ),
              boxShadow: _pressed
                  ? []
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Left accent bar
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: 3,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      gradient: link.isRead
                          ? null
                          : AppColors.brandGradient,
                      color: link.isRead ? c.border : null,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Favicon + title
                        Row(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: c.surfaceElevated,
                                    borderRadius:
                                        BorderRadius.circular(8),
                                    border: Border.all(
                                        color: c.borderSoft,
                                        width: 0.5),
                                  ),
                                  child: ClipRRect(
                                    borderRadius:
                                        BorderRadius.circular(7),
                                    child: CachedNetworkImage(
                                      imageUrl: link.favicon ?? '',
                                      fit: BoxFit.cover,
                                      errorWidget: (ctx, url, e) =>
                                          Icon(Icons.link_rounded,
                                              color: c.textHint,
                                              size: 14),
                                    ),
                                  ),
                                ),
                                if (!link.isRead)
                                  Positioned(
                                    top: -2,
                                    right: -2,
                                    child: Container(
                                      width: 9,
                                      height: 9,
                                      decoration: BoxDecoration(
                                        color: c.accent,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: c.surface,
                                            width: 1.5),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                link.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: theme.titleSmall!.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: link.isRead
                                      ? c.textSecondary
                                      : c.textPrimary,
                                  height: 1.35,
                                ),
                              ),
                            ),
                            if (link.isFavorite) ...[
                              const SizedBox(width: 6),
                              Padding(
                                padding:
                                    const EdgeInsets.only(top: 1),
                                child: Icon(
                                    Icons.bookmark_rounded,
                                    size: 13,
                                    color: c.amber),
                              ),
                            ],
                          ],
                        ),

                        const SizedBox(height: 7),

                        // Domain + tag
                        Row(
                          children: [
                            Icon(Icons.language_rounded,
                                size: 10, color: c.textHint),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                link.domain ?? '',
                                overflow: TextOverflow.ellipsis,
                                style: theme.bodySmall!.copyWith(
                                  color: c.textHint,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                            if (link.tags.isNotEmpty) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding:
                                    const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: c.accentDim,
                                  borderRadius:
                                      BorderRadius.circular(5),
                                ),
                                child: Text(
                                  link.tags.first.name.toUpperCase(),
                                  style: theme.labelSmall!.copyWith(
                                    color: c.accent,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 9,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),

                        // Snippet row — shown when match is in description, notes, or highlight
                        if (showSnippet) ...[
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              if (matchedField == MatchedField.notes ||
                                  matchedField ==
                                      MatchedField.highlight) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 5, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: matchedField ==
                                            MatchedField.highlight
                                        ? const Color(0xFFFBBF24)
                                            .withValues(alpha: 0.12)
                                        : c.surfaceElevated,
                                    borderRadius:
                                        BorderRadius.circular(4),
                                    border: Border.all(
                                      color: matchedField ==
                                              MatchedField.highlight
                                          ? const Color(0xFFFBBF24)
                                              .withValues(alpha: 0.35)
                                          : c.border,
                                      width: 0.5,
                                    ),
                                  ),
                                  child: Text(
                                    matchedField == MatchedField.highlight
                                        ? 'highlight'
                                        : 'note',
                                    style: theme.labelSmall!.copyWith(
                                      color: matchedField ==
                                              MatchedField.highlight
                                          ? const Color(0xFFFBBF24)
                                          : c.textHint,
                                      fontSize: 9,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                              ],
                              Expanded(
                                child: RichText(
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  text: _buildSnippetSpan(
                                      snippet, query, theme, c),
                                ),
                              ),
                            ],
                          ),
                        ],

                        // Description — only shown for title matches
                        if (matchedField == MatchedField.title &&
                            (link.description ?? '').isNotEmpty) ...[
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

                        const SizedBox(height: 9),

                        // Footer
                        Row(
                          children: [
                            Icon(Icons.calendar_today_outlined,
                                size: 10, color: c.textHint),
                            const SizedBox(width: 3),
                            Text(
                              DateFormat.MMMd()
                                  .format(link.createdAt),
                              style: theme.bodySmall!.copyWith(
                                color: c.textHint,
                                fontSize: 10,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(Icons.schedule_rounded,
                                size: 10, color: c.textHint),
                            const SizedBox(width: 3),
                            Text(
                              '$_readTime min',
                              style: theme.bodySmall!.copyWith(
                                color: c.textHint,
                                fontSize: 10,
                              ),
                            ),
                            const Spacer(),
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () =>
                                  showLinkOptions(context, ref, link),
                              child: Container(
                                padding: const EdgeInsets.all(5),
                                decoration: BoxDecoration(
                                  color: c.surfaceElevated,
                                  borderRadius:
                                      BorderRadius.circular(7),
                                  border: Border.all(
                                      color: c.border, width: 0.5),
                                ),
                                child: Icon(
                                  Icons.more_horiz_rounded,
                                  size: 14,
                                  color: c.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Thumbnail
                  if (link.thumbnail != null &&
                      link.thumbnail!.isNotEmpty) ...[
                    const SizedBox(width: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: CachedNetworkImage(
                        imageUrl: link.thumbnail!,
                        height: 72,
                        width: 72,
                        fit: BoxFit.cover,
                        errorWidget: (ctx, url, e) => const SizedBox(),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

TextSpan _buildSnippetSpan(
    String snippet, String query, TextTheme theme, AppColorScheme c) {
  final base = theme.bodySmall!
      .copyWith(color: c.textSecondary, fontSize: 11, height: 1.4);
  final lowerSnippet = snippet.toLowerCase();
  final lowerQuery = query.toLowerCase();
  final idx = lowerSnippet.indexOf(lowerQuery);
  if (idx == -1) {
    return TextSpan(text: snippet, style: base);
  }
  return TextSpan(
    style: base,
    children: [
      if (idx > 0) TextSpan(text: snippet.substring(0, idx)),
      TextSpan(
        text: snippet.substring(idx, idx + query.length),
        style: base.copyWith(fontWeight: FontWeight.w700, color: c.textPrimary),
      ),
      if (idx + query.length < snippet.length)
        TextSpan(text: snippet.substring(idx + query.length)),
    ],
  );
}

// ── Idle State ────────────────────────────────────────────────────────────────

class _IdleState extends StatelessWidget {
  final AppColorScheme c;
  final TextTheme theme;
  final void Function(String) onSuggestionTap;

  const _IdleState({
    required this.c,
    required this.theme,
    required this.onSuggestionTap,
  });

  static const _suggestions = [
    ('flutter.dev', 'Flutter documentation', Icons.code_rounded),
    ('youtube.com', 'Video tutorials', Icons.play_circle_outlined),
    ('github.com', 'Open source repos', Icons.folder_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
      children: [
        const SizedBox(height: 12),
        Text(
          'QUICK PICKS',
          style: theme.labelSmall!.copyWith(
            color: c.textHint,
            letterSpacing: 2.0,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        ..._suggestions.map(
          (s) => _SuggestionRow(
            domain: s.$1,
            label: s.$2,
            icon: s.$3,
            c: c,
            theme: theme,
            onTap: () => onSuggestionTap(s.$1),
          ),
        ),
        const SizedBox(height: 24),
        Center(
          child: Column(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: c.surfaceElevated,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: c.border, width: 0.5),
                ),
                child:
                    Icon(Icons.search_rounded, color: c.textHint, size: 22),
              ),
              const SizedBox(height: 12),
              Text(
                'Type to search your saves',
                style: theme.bodySmall!
                    .copyWith(color: c.textHint, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Animated Hint Text ────────────────────────────────────────────────────────

class _AnimatedHintText extends StatefulWidget {
  final String text;
  final TextStyle style;

  const _AnimatedHintText({required this.text, required this.style});

  @override
  State<_AnimatedHintText> createState() => _AnimatedHintTextState();
}

class _AnimatedHintTextState extends State<_AnimatedHintText>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  late Animation<double> _opacity;
  late Animation<Offset> _slide;
  late String _displayText;

  @override
  void initState() {
    super.initState();
    _displayText = widget.text;
    _anim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 280));
    _opacity = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.35),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _anim, curve: Curves.easeOut));
    _anim.forward();
  }

  @override
  void didUpdateWidget(_AnimatedHintText old) {
    super.didUpdateWidget(old);
    if (old.text != widget.text) {
      _anim.reverse().then((_) {
        if (mounted) {
          setState(() => _displayText = widget.text);
          _anim.forward();
        }
      });
    }
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _slide,
        child: Text(
          _displayText,
          style: widget.style,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

// ── Suggestion Row ────────────────────────────────────────────────────────────

class _SuggestionRow extends StatefulWidget {
  final String domain;
  final String label;
  final IconData icon;
  final AppColorScheme c;
  final TextTheme theme;
  final VoidCallback onTap;

  const _SuggestionRow({
    required this.domain,
    required this.label,
    required this.icon,
    required this.c,
    required this.theme,
    required this.onTap,
  });

  @override
  State<_SuggestionRow> createState() => _SuggestionRowState();
}

class _SuggestionRowState extends State<_SuggestionRow> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.c;
    final theme = widget.theme;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: _pressed ? c.surfaceElevated : c.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _pressed ? c.accentBorder : c.border,
            width: _pressed ? 1.0 : 0.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: _pressed ? c.accent.withValues(alpha: 0.2) : c.accentDim,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(widget.icon, size: 16, color: c.accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.label,
                      style: theme.titleSmall!.copyWith(
                          fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 1),
                  Text(widget.domain,
                      style: theme.bodySmall!
                          .copyWith(color: c.textHint, fontSize: 11)),
                ],
              ),
            ),
            Icon(Icons.north_west_rounded,
                size: 14, color: _pressed ? c.accent : c.textHint),
          ],
        ),
      ),
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final AppColorScheme c;
  final TextTheme theme;
  final String? query;
  const _EmptyState(
      {required this.c, required this.theme, this.query});

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
            child:
                Icon(Icons.search_off_rounded, color: c.textHint, size: 24),
          ),
          const SizedBox(height: 14),
          Text(
            'No results found',
            style: theme.titleSmall!
                .copyWith(fontWeight: FontWeight.w600, color: c.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            query != null
                ? 'Nothing matched "$query"'
                : 'Try different filters',
            style: theme.bodySmall!.copyWith(color: c.textHint),
          ),
        ],
      ),
    );
  }
}

// ── Loading State ─────────────────────────────────────────────────────────────

class _LoadingState extends StatelessWidget {
  final AppColorScheme c;
  const _LoadingState({required this.c});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      itemCount: 5,
      separatorBuilder: (ctx, i) => const SizedBox(height: 10),
      itemBuilder: (ctx, i) => _SkeletonCard(c: c),
    );
  }
}

// ── Error State ───────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  final AppColorScheme c;
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
          Text('Search failed',
              style: theme.titleSmall!.copyWith(color: c.textPrimary)),
          const SizedBox(height: 4),
          Text('Please try again',
              style: theme.bodySmall!.copyWith(color: c.textHint)),
        ],
      ),
    );
  }
}

// ── Skeleton Card ─────────────────────────────────────────────────────────────

class _SkeletonCard extends StatelessWidget {
  final AppColorScheme c;
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
                _Bone(
                    width: double.infinity, height: 13, radius: 4, c: c),
                const SizedBox(height: 6),
                _Bone(width: 100, height: 10, radius: 4, c: c),
                const SizedBox(height: 8),
                _Bone(
                    width: double.infinity, height: 10, radius: 4, c: c),
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

class _Bone extends StatelessWidget {
  final double width, height, radius;
  final AppColorScheme c;
  const _Bone(
      {required this.width,
      required this.height,
      required this.radius,
      required this.c});

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
