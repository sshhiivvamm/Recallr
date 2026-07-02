import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:metadata_fetch/metadata_fetch.dart';
import 'package:recallr/theme/recallr_colors.dart';

import '../core/database/providers/isar_provider.dart';
import '../core/features/category/tag_list_provider.dart';
import '../core/features/category/tag_provider.dart';
import '../core/features/collections/collection_provider.dart';
import '../core/repositrories/link_providers/recent_links_provider.dart';
import '../core/services/auto_categorizer.dart';
import '../core/services/tag_suggester.dart';
import '../data/models/Link/link_model.dart';
import '../data/models/Tag/tag_model.dart';
import '../data/models/collection_model.dart';

// ── Public API ────────────────────────────────────────────────────────────────

class ReWid {
  /// Opens the save-link bottom sheet.
  /// Pass [initialUrl] to pre-fill (e.g. from Android share intent).
  static Future<void> openSaveSheet(
    BuildContext context, {
    String? initialUrl,
    ValueChanged<double>? onSheetTopY,
    ValueChanged<Animation<double>>? onSheetAnimation,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SaveLinkSheet(
        initialUrl: initialUrl,
        onSheetTopY: onSheetTopY,
        onSheetAnimation: onSheetAnimation,
      ),
    );
  }

  // Legacy instance method kept for backward-compat
  void openSaveSheet2(BuildContext context) => ReWid.openSaveSheet(context);
}

// ── Sheet widget ──────────────────────────────────────────────────────────────

class _SaveLinkSheet extends ConsumerStatefulWidget {
  final String? initialUrl;
  final ValueChanged<double>? onSheetTopY;
  final ValueChanged<Animation<double>>? onSheetAnimation;
  const _SaveLinkSheet({this.initialUrl, this.onSheetTopY, this.onSheetAnimation});

  @override
  ConsumerState<_SaveLinkSheet> createState() => _SaveLinkSheetState();
}

class _SaveLinkSheetState extends ConsumerState<_SaveLinkSheet> {
  final _urlCtrl = TextEditingController();
  final _titleCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _urlFocus = FocusNode();

  bool _fetchingMeta = false;
  bool _saving = false;
  bool _saveSuccess = false;
  bool _notesAutoFilled = false; // true when notes were populated from metadata
  Metadata? _meta;
  String? _domain;
  TagModel? _selectedTag;
  FolderModel? _selectedFolder;
  String? _autoTagSuggestion; // shown as a banner when share intent provides URL

  @override
  void initState() {
    super.initState();
    if (widget.initialUrl != null) {
      // Pre-fill URL from share intent and kick off metadata fetch
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _urlCtrl.text = widget.initialUrl!;
        _fetchMeta(widget.initialUrl!);
        final suggestion = AutoCategorizer.suggest(widget.initialUrl!);
        if (suggestion != null) setState(() => _autoTagSuggestion = suggestion);
      });
    }
    if (widget.onSheetTopY != null || widget.onSheetAnimation != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final box = context.findRenderObject() as RenderBox?;
        if (box != null && widget.onSheetTopY != null) {
          final screenH = MediaQuery.of(context).size.height;
          widget.onSheetTopY!.call(screenH - box.size.height);
        }
        final anim = ModalRoute.of(context)?.animation;
        if (anim != null) widget.onSheetAnimation?.call(anim);
      });
    }
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    _titleCtrl.dispose();
    _notesCtrl.dispose();
    _urlFocus.dispose();
    super.dispose();
  }

  // ── Metadata fetch ─────────────────────────────────────────────────────────

  // Parses <meta name="keywords"> from raw HTML — handles both attribute orderings.
  static String? _parseKeywords(String html) {
    final patterns = [
      RegExp(
        r'''<meta[^>]+name=["']keywords["'][^>]+content=["']([^"']+)["']''',
        caseSensitive: false,
      ),
      RegExp(
        r'''<meta[^>]+content=["']([^"']+)["'][^>]+name=["']keywords["']''',
        caseSensitive: false,
      ),
    ];
    for (final pattern in patterns) {
      final match = pattern.firstMatch(html);
      if (match != null) {
        final kw = match.group(1)?.trim();
        if (kw != null && kw.isNotEmpty) return kw;
      }
    }
    return null;
  }

  Future<String?> _fetchKeywords(String url) async {
    try {
      final response = await http
          .get(Uri.parse(url), headers: {'User-Agent': 'Mozilla/5.0'})
          .timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        return _parseKeywords(response.body);
      }
    } catch (_) {}
    return null;
  }

  Future<void> _fetchMeta(String raw) async {
    final url = raw.trim();
    final isValid = url.startsWith('http://') || url.startsWith('https://');
    if (!isValid) return;

    setState(() {
      _fetchingMeta = true;
      _meta = null;
    });

    try {
      // Run metadata fetch and keywords fetch in parallel — no added latency.
      final results = await Future.wait([
        MetadataFetch.extract(url),
        _fetchKeywords(url),
      ]);
      final data = results[0] as Metadata?;
      final keywords = results[1] as String?;

      final uri = Uri.tryParse(url);
      if (!mounted) return;
      setState(() {
        _meta = data;
        _domain = uri?.host ?? '';
        if (_titleCtrl.text.isEmpty && data?.title != null) {
          _titleCtrl.text = data!.title!;
        }
        // Auto-populate notes with meta keywords so they become searchable.
        // Falls back to og:description if no keywords tag found.
        // Only fills if the user hasn't typed anything yet.
        if (_notesCtrl.text.isEmpty) {
          if (keywords != null) {
            _notesCtrl.text = keywords;
            _notesAutoFilled = true;
          } else if (data?.description != null &&
              data!.description!.trim().isNotEmpty) {
            _notesCtrl.text = data.description!.trim();
            _notesAutoFilled = true;
          }
        }
        _fetchingMeta = false;
      });

      // Smart tag suggestion after fetch (only if no tag selected yet)
      if (_selectedTag == null && _autoTagSuggestion == null) {
        final userTags = ref.read(tagListProvider).valueOrNull ?? [];
        final title = _titleCtrl.text;
        final matched = TagSuggester.suggest(url, title, userTags);
        if (matched != null && mounted) {
          setState(() => _autoTagSuggestion = matched.name);
        } else {
          // No existing tag matched — fall back to domain detection so the
          // category is auto-created on save even when the user has no tags yet.
          final domainHint = AutoCategorizer.suggest(url);
          if (domainHint != null && mounted) {
            setState(() => _autoTagSuggestion = domainHint);
          }
        }
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _fetchingMeta = false);
    }
  }

  // ── Save ───────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    final url = _urlCtrl.text.trim();
    if (url.isEmpty) return;

    setState(() => _saving = true);
    try {
      final isar = await ref.read(isarProvider.future);
      final uri = Uri.tryParse(url);
      final domain = uri?.host ?? '';

      final link = LinkModel()
        ..url = url
        ..title = _titleCtrl.text.isNotEmpty
            ? _titleCtrl.text
            : (_meta?.title ?? url)
        ..description = _meta?.description
        ..thumbnail = _meta?.image
        ..siteName = _siteName(domain)
        ..domain = domain
        ..favicon = 'https://www.google.com/s2/favicons?domain=$domain&sz=64'
        ..notes = _notesCtrl.text.trim();

      // Resolve tag: manual selection wins; fall back to auto-detected category
      TagModel? tagToApply = _selectedTag;
      if (tagToApply == null && _autoTagSuggestion != null) {
        tagToApply = await ref
            .read(tagRepositoryProvider)
            .findOrCreateSystemTag(_autoTagSuggestion!);
      }

      await isar.writeTxn(() async {
        await isar.linkModels.put(link);
        if (tagToApply != null) {
          link.tags.add(tagToApply);
          await link.tags.save();
        }
        if (_selectedFolder != null) {
          link.folder.value = _selectedFolder;
          await link.folder.save();
        }
      });

      // Refresh home-screen spotlight cards that aren't on a live stream
      ref.invalidate(discoverLinkProvider);
      ref.invalidate(nextReadProvider);
      ref.invalidate(reviewDueCountProvider);

      if (!mounted) return;
      setState(() => _saveSuccess = true);
      await Future.delayed(const Duration(milliseconds: 1400));
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().contains('unique')
                  ? 'This link is already saved.'
                  : 'Could not save link. Please try again.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _siteName(String domain) {
    if (domain.contains('youtube')) return 'YouTube';
    if (domain.contains('instagram')) return 'Instagram';
    if (domain.contains('github')) return 'GitHub';
    if (domain.contains('medium')) return 'Medium';
    if (domain.contains('twitter') || domain.contains('x.com')) return 'X';
    return domain;
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final theme = Theme.of(context).textTheme;
    final kb = MediaQuery.of(context).viewInsets.bottom;

    // ── Save success overlay ──────────────────────────────────────────────────
    if (_saveSuccess) {
      return Container(
        decoration: BoxDecoration(
          color: c.background,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: c.borderSoft,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Lottie.asset(
              'assets/animations/success.json',
              width: 140,
              height: 140,
              repeat: false,
              fit: BoxFit.contain,
            ),
            Text(
              'Saved to Vault!',
              style: theme.titleMedium!.copyWith(
                fontWeight: FontWeight.w700,
                color: c.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Link added to your collection',
              style: theme.bodySmall!.copyWith(color: c.textHint),
            ),
            const SizedBox(height: 20),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: c.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + kb),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Handle ──────────────────────────────────
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: c.borderSoft,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            const SizedBox(height: 18),

            // ── Title row ───────────────────────────────
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(
                    'assets/icons/logo.png',
                    width: 36,
                    height: 36,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SAVE LINK',
                        style: theme.titleMedium!.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                          color: c.textPrimary,
                        ),
                      ),
                      Text(
                        'Add to your knowledge vault',
                        style: theme.bodySmall!
                            .copyWith(color: c.textHint, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ── URL Field ────────────────────────────────
            _SectionLabel(label: 'URL', c: c, theme: theme),
            const SizedBox(height: 6),
            _UrlField(
              controller: _urlCtrl,
              focus: _urlFocus,
              c: c,
              theme: theme,
              isLoading: _fetchingMeta,
              onChanged: (v) {
                if (v.trim().startsWith('http')) _fetchMeta(v);
              },
              onClear: () {
                setState(() {
                  _urlCtrl.clear();
                  _titleCtrl.clear();
                  _meta = null;
                  _domain = null;
                });
              },
            ),

            // ── Auto-tag suggestion banner (share intent) ─
            if (_autoTagSuggestion != null && _selectedTag == null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: GestureDetector(
                  onTap: () {
                    final tags = ref.read(tagListProvider).valueOrNull ?? [];
                    final match = tags.where((t) =>
                        t.name.toLowerCase() == _autoTagSuggestion!.toLowerCase()
                    ).firstOrNull;
                    if (match != null) setState(() => _selectedTag = match);
                    setState(() => _autoTagSuggestion = null);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: c.accentDim,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: c.accentBorder),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.auto_awesome_rounded, size: 14, color: c.accent),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Auto-detected category: $_autoTagSuggestion — tap to apply',
                            style: TextStyle(
                              fontSize: 12,
                              color: c.accent,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => setState(() => _autoTagSuggestion = null),
                          child: Icon(Icons.close_rounded, size: 14, color: c.textHint),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // ── Preview card ─────────────────────────────
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              child: (_meta != null || _fetchingMeta)
                  ? _PreviewCard(
                      meta: _meta,
                      domain: _domain,
                      isLoading: _fetchingMeta,
                      c: c,
                      theme: theme,
                    )
                  : const SizedBox.shrink(),
            ),

            const SizedBox(height: 16),

            // ── Title Field ──────────────────────────────
            _SectionLabel(label: 'TITLE', c: c, theme: theme),
            const SizedBox(height: 6),
            _StyledField(
              controller: _titleCtrl,
              hint: 'Link title (auto-filled)',
              icon: Icons.title_rounded,
              c: c,
              theme: theme,
            ),

            const SizedBox(height: 16),

            // ── Category ────────────────────────────────
            _SectionLabel(label: 'CATEGORY', c: c, theme: theme),
            const SizedBox(height: 8),
            _CategoryRow(
              c: c,
              theme: theme,
              selectedTag: _selectedTag,
              onSelect: (tag) => setState(() => _selectedTag = tag),
              ref: ref,
            ),

            const SizedBox(height: 16),

            const SizedBox(height: 16),

            // ── Collection ───────────────────────────────
            _SectionLabel(label: 'COLLECTION', c: c, theme: theme),
            const SizedBox(height: 8),
            _FolderRow(
              c: c,
              theme: theme,
              selectedFolder: _selectedFolder,
              onSelect: (f) => setState(() => _selectedFolder = f),
              ref: ref,
            ),

            const SizedBox(height: 16),

            // ── Notes ────────────────────────────────────
            _SectionLabel(label: 'NOTES', c: c, theme: theme),
            const SizedBox(height: 6),
            _StyledField(
              controller: _notesCtrl,
              hint: 'Why is this worth saving?',
              icon: Icons.notes_rounded,
              maxLines: 3,
              c: c,
              theme: theme,
              onChanged: (_) {
                if (_notesAutoFilled) setState(() => _notesAutoFilled = false);
              },
            ),
            if (_notesAutoFilled) ...[
              const SizedBox(height: 5),
              Row(
                children: [
                  Icon(Icons.auto_awesome_rounded,
                      size: 10, color: c.accent.withValues(alpha: 0.7)),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      'Auto-filled from page metadata · edit freely',
                      style: theme.labelSmall!.copyWith(
                        color: c.textHint,
                        fontSize: 10,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 24),

            // ── Save button ──────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                onPressed: _saving || _urlCtrl.text.trim().isEmpty
                    ? null
                    : _save,
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
                        'Save to Vault',
                        style: theme.titleSmall!.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── URL Field ─────────────────────────────────────────────────────────────────

class _UrlField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focus;
  final AppColorScheme c;
  final TextTheme theme;
  final bool isLoading;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _UrlField({
    required this.controller,
    required this.focus,
    required this.c,
    required this.theme,
    required this.isLoading,
    required this.onChanged,
    required this.onClear,
  });

  @override
  State<_UrlField> createState() => _UrlFieldState();
}

class _UrlFieldState extends State<_UrlField> {
  @override
  void initState() {
    super.initState();
    widget.focus.addListener(_onFocusChange);
  }

  void _onFocusChange() => setState(() {});

  @override
  void dispose() {
    widget.focus.removeListener(_onFocusChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.c;
    final theme = widget.theme;
    final isFocused = widget.focus.hasFocus;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isFocused ? c.accent : c.border,
          width: isFocused ? 1.0 : 0.5,
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          Icon(Icons.link_rounded, size: 18,
              color: isFocused ? c.accent : c.textHint),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: widget.focus,
              keyboardType: TextInputType.url,
              autocorrect: false,
              style: theme.bodyMedium!.copyWith(color: c.textPrimary),
              decoration: InputDecoration(
                hintText: 'https://',
                hintStyle: theme.bodyMedium!.copyWith(color: c.textHint),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 13),
              ),
              onChanged: widget.onChanged,
            ),
          ),
          if (widget.isLoading)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: c.accent),
              ),
            )
          else if (widget.controller.text.isNotEmpty)
            GestureDetector(
              onTap: widget.onClear,
              child: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Icon(Icons.close_rounded, size: 16, color: c.textHint),
              ),
            )
          else
            GestureDetector(
              onTap: () async {
                final data = await Clipboard.getData(Clipboard.kTextPlain);
                if (data?.text != null) {
                  widget.controller.text = data!.text!;
                  widget.onChanged(data.text!);
                }
              },
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: c.accentDim,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: c.accentBorder, width: 0.5),
                ),
                child: Text(
                  'Paste',
                  style: theme.labelSmall!.copyWith(
                    color: c.accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Preview Card ─────────────────────────────────────────────────────────────

class _PreviewCard extends StatelessWidget {
  final Metadata? meta;
  final String? domain;
  final bool isLoading;
  final AppColorScheme c;
  final TextTheme theme;

  const _PreviewCard({
    required this.meta,
    required this.domain,
    required this.isLoading,
    required this.c,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: c.surfaceElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: c.border, width: 0.5),
        ),
        child: isLoading
            ? Row(
                children: [
                  _Bone(width: 32, height: 32, radius: 8, c: c),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Bone(
                            width: double.infinity,
                            height: 11,
                            radius: 4,
                            c: c),
                        const SizedBox(height: 6),
                        _Bone(width: 100, height: 9, radius: 4, c: c),
                      ],
                    ),
                  ),
                ],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: c.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: c.border, width: 0.5),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(7),
                      child: CachedNetworkImage(
                        imageUrl: 'https://www.google.com/s2/favicons?domain=$domain&sz=64',
                        width: 32,
                        height: 32,
                        fit: BoxFit.cover,
                        errorWidget: (_, url, e) => Icon(
                          Icons.language_rounded,
                          size: 16,
                          color: c.textHint,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          meta?.title ?? domain ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.labelMedium!.copyWith(
                            color: c.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (domain != null && domain!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            domain!,
                            style: theme.labelSmall!
                                .copyWith(color: c.textHint),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: c.accentDim,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(Icons.check_rounded,
                        size: 12, color: c.accent),
                  ),
                ],
              ),
      ),
    );
  }
}

// ── Category Row ──────────────────────────────────────────────────────────────

class _CategoryRow extends StatelessWidget {
  final AppColorScheme c;
  final TextTheme theme;
  final TagModel? selectedTag;
  final ValueChanged<TagModel?> onSelect;
  final WidgetRef ref;

  const _CategoryRow({
    required this.c,
    required this.theme,
    required this.selectedTag,
    required this.onSelect,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    final tagsAsync = ref.watch(tagListProvider);

    return tagsAsync.when(
      loading: () => _chipSkeleton(c),
      error: (e, _) => Text('Error: $e',
          style: theme.bodySmall!.copyWith(color: c.coral)),
      data: (tags) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // "+ New" chip always first
            _AddChip(c: c, theme: theme, onAdded: (tag) => onSelect(tag),
                ref: ref),
            const SizedBox(width: 8),
            ...tags.map((tag) {
              final isSelected = selectedTag?.id == tag.id;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => onSelect(isSelected ? null : tag),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: isSelected ? c.accent : c.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? c.accent : c.border,
                        width: 0.5,
                      ),
                    ),
                    child: Text(
                      tag.name,
                      style: theme.labelSmall!.copyWith(
                        color: isSelected ? Colors.white : c.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              );
            }),
            if (tags.isEmpty)
              Text(
                'Tap + New to create your first category',
                style: theme.bodySmall!.copyWith(color: c.textHint),
              ),
          ],
        ),
      ),
    );
  }

  Widget _chipSkeleton(AppColorScheme c) {
    return Row(
      children: List.generate(
        3,
        (i) => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: _Bone(width: 70, height: 30, radius: 20, c: c),
        ),
      ),
    );
  }
}

// ── Add Chip ──────────────────────────────────────────────────────────────────

class _AddChip extends StatelessWidget {
  final AppColorScheme c;
  final TextTheme theme;
  final ValueChanged<TagModel?> onAdded;
  final WidgetRef ref;

  const _AddChip({
    required this.c,
    required this.theme,
    required this.onAdded,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final ctrl = TextEditingController();
        final name = await showDialog<String>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text('New Category', style: theme.titleSmall),
            content: TextField(
              controller: ctrl,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Category name',
                prefixIcon: Icon(Icons.folder_outlined,
                    color: c.textHint, size: 18),
              ),
              onSubmitted: (v) => Navigator.of(ctx).pop(v),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel')),
              TextButton(
                  onPressed: () => Navigator.of(ctx).pop(ctrl.text),
                  child: const Text('Add')),
            ],
          ),
        );

        if (name != null && name.trim().isNotEmpty) {
          final isar = await ref.read(isarProvider.future);
          final newTag = TagModel()..name = name.trim();
          await isar.writeTxn(
              () async => await isar.tagModels.put(newTag));
          ref.invalidate(tagListProvider);
          onAdded(newTag);
        }
      },
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: c.accentDim,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: c.accentBorder, width: 0.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_rounded, size: 13, color: c.accent),
            const SizedBox(width: 4),
            Text(
              'New',
              style: theme.labelSmall!.copyWith(
                color: c.accent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Styled Text Field ─────────────────────────────────────────────────────────

class _StyledField extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final int maxLines;
  final AppColorScheme c;
  final TextTheme theme;
  final ValueChanged<String>? onChanged;

  const _StyledField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.maxLines = 1,
    required this.c,
    required this.theme,
    this.onChanged,
  });

  @override
  State<_StyledField> createState() => _StyledFieldState();
}

class _StyledFieldState extends State<_StyledField> {
  late final FocusNode _focus;

  @override
  void initState() {
    super.initState();
    _focus = FocusNode()..addListener(_onFocusChange);
  }

  void _onFocusChange() => setState(() {});

  @override
  void dispose() {
    _focus
      ..removeListener(_onFocusChange)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.c;
    final theme = widget.theme;
    final isFocused = _focus.hasFocus;

    final isMultiLine = widget.maxLines > 1;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isFocused ? c.accent : c.border,
          width: isFocused ? 1.0 : 0.5,
        ),
      ),
      child: Row(
        // center-align for single-line so icon lines up with the text
        crossAxisAlignment: isMultiLine
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          Padding(
            padding: EdgeInsets.only(
              left: 12,
              top: isMultiLine ? 13 : 0,
            ),
            child: Icon(widget.icon, size: 18,
                color: isFocused ? c.accent : c.textHint),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: _focus,
              maxLines: widget.maxLines,
              onChanged: widget.onChanged,
              style: theme.bodyMedium!.copyWith(color: c.textPrimary),
              decoration: InputDecoration(
                hintText: widget.hint,
                hintStyle: theme.bodyMedium!.copyWith(color: c.textHint),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 13),
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
    );
  }
}

// ── Section Label ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  final AppColorScheme c;
  final TextTheme theme;

  const _SectionLabel(
      {required this.label, required this.c, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: theme.labelSmall!.copyWith(
        color: c.textHint,
        letterSpacing: 1.4,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

// ── Folder Row ────────────────────────────────────────────────────────────────

class _FolderRow extends StatelessWidget {
  final AppColorScheme c;
  final TextTheme theme;
  final FolderModel? selectedFolder;
  final ValueChanged<FolderModel?> onSelect;
  final WidgetRef ref;

  const _FolderRow({
    required this.c,
    required this.theme,
    required this.selectedFolder,
    required this.onSelect,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    final foldersAsync = ref.watch(collectionsStreamProvider);
    return foldersAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (e, st) => const SizedBox.shrink(),
      data: (folders) {
        if (folders.isEmpty) {
          return Text(
            'No collections yet — create one in the Collections tab',
            style: theme.bodySmall!.copyWith(color: c.textHint),
          );
        }
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              GestureDetector(
                onTap: () => onSelect(null),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: selectedFolder == null ? c.surfaceElevated : c.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selectedFolder == null ? c.accent : c.border,
                      width: 0.5,
                    ),
                  ),
                  child: Text(
                    'None',
                    style: theme.labelSmall!.copyWith(
                      color: selectedFolder == null ? c.accent : c.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ...folders.map((folder) {
                final isSelected = selectedFolder?.id == folder.id;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => onSelect(isSelected ? null : folder),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: isSelected ? c.accent : c.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? c.accent : c.border,
                          width: 0.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.folder_rounded,
                            size: 12,
                            color: isSelected ? Colors.white : c.textSecondary,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            folder.name,
                            style: theme.labelSmall!.copyWith(
                              color: isSelected ? Colors.white : c.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}

// ── Bone (skeleton) ───────────────────────────────────────────────────────────

class _Bone extends StatelessWidget {
  final double width, height, radius;
  final AppColorScheme c;

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
