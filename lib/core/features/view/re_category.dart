import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

import '../../../common/add_category_sheet.dart';
import '../../../common/sheet_fab.dart';
import '../../../data/models/collection_model.dart';
import '../../../data/models/Tag/tag_model.dart';
import '../../../theme/recallr_colors.dart';
import '../../database/providers/isar_provider.dart';
import '../category/tag_list_provider.dart';
import '../collections/collection_provider.dart';

// ── Platform data ─────────────────────────────────────────────────────────────

class _Platform {
  final String name;
  final String domainKeyword;
  final Color color;
  final IconData icon;
  final IconData faIcon;

  const _Platform({
    required this.name,
    required this.domainKeyword,
    required this.color,
    required this.icon,
    required this.faIcon,
  });
}

const _platforms = [
  _Platform(
    name: 'YouTube',
    domainKeyword: 'youtube',
    color: Color(0xFFFF0000),
    icon: Icons.play_circle_rounded,
    faIcon: FontAwesomeIcons.youtube,
  ),
  _Platform(
    name: 'Instagram',
    domainKeyword: 'instagram',
    color: Color(0xFFE1306C),
    icon: Icons.photo_camera_rounded,
    faIcon: FontAwesomeIcons.instagram,
  ),
  _Platform(
    name: 'X / Twitter',
    domainKeyword: 'twitter',
    color: Color(0xFF6B7280),   // mid slate-gray — visible in both light & dark modes
    icon: Icons.alternate_email_rounded,
    faIcon: FontAwesomeIcons.xTwitter,
  ),
  _Platform(
    name: 'Reddit',
    domainKeyword: 'reddit',
    color: Color(0xFFFF4500),
    icon: Icons.forum_rounded,
    faIcon: FontAwesomeIcons.reddit,
  ),
  _Platform(
    name: 'GitHub',
    domainKeyword: 'github',
    color: Color(0xFF9C6EE8),
    icon: Icons.code_rounded,
    faIcon: FontAwesomeIcons.github,
  ),
  _Platform(
    name: 'Medium',
    domainKeyword: 'medium',
    color: Color(0xFF02B875),   // Medium's signature green
    icon: Icons.article_rounded,
    faIcon: FontAwesomeIcons.medium,
  ),
  _Platform(
    name: 'LinkedIn',
    domainKeyword: 'linkedin',
    color: Color(0xFF0A66C2),
    icon: Icons.work_rounded,
    faIcon: FontAwesomeIcons.linkedin,
  ),
  _Platform(
    name: 'Facebook',
    domainKeyword: 'facebook',
    color: Color(0xFF1877F2),
    icon: Icons.people_rounded,
    faIcon: FontAwesomeIcons.facebookF,
  ),
];

// ── Screen ────────────────────────────────────────────────────────────────────

class ReCategory extends ConsumerWidget {
  const ReCategory({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final tagsAsync = ref.watch(tagListProvider);

    return SheetFabHost(
      heroTag: 'category_fab',
      openSheet: (ctx, {required onSheetTopY, required onSheetAnimation}) =>
          showModalBottomSheet<void>(
            context: ctx,
            isScrollControlled: true,
            builder: (_) => AddCategorySheet(
              onSheetTopY: onSheetTopY,
              onSheetAnimation: onSheetAnimation,
            ),
          ),
      child: Scaffold(
        backgroundColor: c.background,
        body: tagsAsync.when(
          data: (tags) => _CategoryBody(tags: tags),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text(e.toString())),
        ),
      ),
    );
  }
}

// ─── Body ─────────────────────────────────────────────────────────────────────

class _CategoryBody extends ConsumerStatefulWidget {
  final List<TagModel> tags;
  const _CategoryBody({required this.tags});

  @override
  ConsumerState<_CategoryBody> createState() => _CategoryBodyState();
}

class _CategoryBodyState extends ConsumerState<_CategoryBody> {
  bool _sortAz = true;

  List<TagModel> get _pinnedTags =>
      widget.tags.where((t) => t.isDefault).toList();

  List<TagModel> get _sortedTags {
    final list = [...widget.tags];
    if (_sortAz) list.sort((a, b) => a.name.compareTo(b.name));
    return list;
  }

  Future<void> _togglePin(TagModel tag) async {
    final isar = await ref.read(isarProvider.future);
    await isar.writeTxn(() async {
      tag.isDefault = !tag.isDefault;
      await isar.tagModels.put(tag);
    });
    ref.invalidate(tagListProvider);
  }

  void _showTagOptions(BuildContext context, TagModel tag) {
    final c = context.colors;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: c.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: c.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Icon(Icons.edit_rounded, color: c.accent),
              title: const Text('Rename'),
              onTap: () {
                Navigator.pop(ctx);
                _promptRenameTag(context, tag);
              },
            ),
            ListTile(
              leading: Icon(
                tag.isDefault
                    ? Icons.push_pin_outlined
                    : Icons.push_pin_rounded,
                color: c.textSecondary,
              ),
              title: Text(tag.isDefault ? 'Unpin' : 'Pin to top'),
              onTap: () {
                Navigator.pop(ctx);
                _togglePin(tag);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_outline_rounded, color: c.coral),
              title: Text('Delete', style: TextStyle(color: c.coral)),
              onTap: () {
                Navigator.pop(ctx);
                _confirmDelete(context, tag);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _promptRenameTag(BuildContext context, TagModel tag) async {
    final ctrl = TextEditingController(text: tag.name);
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename Category'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Category name'),
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('Rename'),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (newName == null || newName.isEmpty || newName == tag.name) return;
    final isar = await ref.read(isarProvider.future);
    await isar.writeTxn(() async {
      tag.name = newName;
      await isar.tagModels.put(tag);
    });
    ref.invalidate(tagListProvider);
  }

  Future<void> _confirmDelete(BuildContext context, TagModel tag) async {
    final c = context.colors;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text("Delete '${tag.name}'? Links won't be affected."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Delete', style: TextStyle(color: c.coral)),
          ),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      final messenger = ScaffoldMessenger.of(context);
      final isar = await ref.read(isarProvider.future);
      await isar.writeTxn(() async {
        await tag.links.load();
        for (final link in tag.links) {
          link.tags.remove(tag);
          await link.tags.save();
        }
        await isar.tagModels.delete(tag.id);
      });
      ref.invalidate(tagListProvider);
      messenger.showSnackBar(
          SnackBar(content: Text("'${tag.name}' deleted")));
    }
  }

  void _showAddSheet() => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) => const AddCategorySheet(),
      );

  void _openTag(TagModel tag) {
    context.push('/categories/filter', extra: {
      'title': tag.name,
      'color': _resolveColor(tag),
      'icon': _resolveIcon(tag.icon),
      'tagId': tag.id,
      'domainKeyword': null,
    });
  }

  void _openPlatform(_Platform p) {
    context.push('/categories/filter', extra: {
      'title': p.name,
      'color': p.color,
      'icon': p.icon,
      'tagId': null,
      'domainKeyword': p.domainKeyword,
    });
  }

  static Color _resolveColor(TagModel tag) {
    const fallback = [
      AppColors.cyan, AppColors.purple, AppColors.green,
      AppColors.amber, AppColors.coral,
    ];
    if (tag.colorHex != null && tag.colorHex!.isNotEmpty) {
      try {
        final hex = tag.colorHex!.replaceFirst('#', '');
        return Color(int.parse('FF$hex', radix: 16));
      } catch (_) {}
    }
    return fallback[tag.id % fallback.length];
  }

  static final _cpMap = <int, IconData>{
    Icons.code_rounded.codePoint:            Icons.code_rounded,
    Icons.book_rounded.codePoint:            Icons.book_rounded,
    Icons.school_rounded.codePoint:          Icons.school_rounded,
    Icons.work_rounded.codePoint:            Icons.work_rounded,
    Icons.favorite_rounded.codePoint:        Icons.favorite_rounded,
    Icons.star_rounded.codePoint:            Icons.star_rounded,
    Icons.lightbulb_rounded.codePoint:       Icons.lightbulb_rounded,
    Icons.sports_esports_rounded.codePoint:  Icons.sports_esports_rounded,
    Icons.science_rounded.codePoint:         Icons.science_rounded,
    Icons.palette_rounded.codePoint:         Icons.palette_rounded,
    Icons.music_note_rounded.codePoint:      Icons.music_note_rounded,
    Icons.trending_up_rounded.codePoint:     Icons.trending_up_rounded,
    Icons.design_services_rounded.codePoint: Icons.design_services_rounded,
    Icons.menu_book_rounded.codePoint:       Icons.menu_book_rounded,
    Icons.play_circle_rounded.codePoint:     Icons.play_circle_rounded,
    Icons.article_rounded.codePoint:         Icons.article_rounded,
    Icons.people_rounded.codePoint:          Icons.people_rounded,
    Icons.build_rounded.codePoint:           Icons.build_rounded,
    Icons.folder_rounded.codePoint:          Icons.folder_rounded,
  };

  static IconData _resolveIcon(String? iconStr) {
    if (iconStr == null) return Icons.folder_rounded;
    final cp = int.tryParse(iconStr);
    if (cp != null) return _cpMap[cp] ?? Icons.folder_rounded;
    const map = {
      'code':    Icons.code_rounded,
      'study':   Icons.school_rounded,
      'design':  Icons.design_services_rounded,
      'book':    Icons.menu_book_rounded,
      'work':    Icons.work_rounded,
      'star':    Icons.star_rounded,
      'idea':    Icons.lightbulb_rounded,
      'video':   Icons.play_circle_rounded,
      'article': Icons.article_rounded,
      'social':  Icons.people_rounded,
      'tool':    Icons.build_rounded,
    };
    return map[iconStr] ?? Icons.folder_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final theme = Theme.of(context).textTheme;
    final pinned = _pinnedTags;
    final allSorted = _sortedTags;
    final collectionsAsync = ref.watch(collectionsStreamProvider);

    final gridItems = <Widget>[
      ...pinned.map((tag) => _PinnedCard(
            tag: tag,
            onTap: () => _openTag(tag),
            onDelete: () => _confirmDelete(context, tag),
            onUnpin: () => _togglePin(tag),
            onRename: () => _promptRenameTag(context, tag),
          )),
      _NewCategoryCard(onTap: _showAddSheet),
    ];

    return CustomScrollView(
      slivers: [
        // ── Library heading ───────────────────────────────
        SliverAppBar(
          pinned: true,
          floating: false,
          backgroundColor: c.background,
          surfaceTintColor: Colors.transparent,
          shadowColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false,
          toolbarHeight: 56,
          titleSpacing: 16,
          title: Text(
            'Library',
            style: theme.headlineSmall!.copyWith(
              fontWeight: FontWeight.w800,
              color: c.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
        ),

        // ── PLATFORMS section label ───────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Text(
              'PLATFORMS',
              style: theme.labelSmall!.copyWith(
                color: c.textHint,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.8,
              ),
            ),
          ),
        ),

        // ── Platform cards grid ───────────────────────────
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverGrid(
            delegate: SliverChildBuilderDelegate(
              (ctx, i) => _PlatformCard(
                platform: _platforms[i],
                onTap: () => _openPlatform(_platforms[i]),
              ),
              childCount: _platforms.length,
            ),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.82,
            ),
          ),
        ),

        // ── COLLECTIONS label ─────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 28, 16, 12),
            child: Row(
              children: [
                Text(
                  'COLLECTIONS',
                  style: theme.labelSmall!.copyWith(
                    color: c.textHint,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.8,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => context.push('/collections'),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'See all',
                        style: theme.labelSmall!.copyWith(
                          color: c.accent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(Icons.arrow_forward_rounded,
                          size: 12, color: c.accent),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Collections strip ─────────────────────────────
        SliverToBoxAdapter(
          child: SizedBox(
            height: 118,
            child: collectionsAsync.when(
              data: (folders) => folders.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _NewCollectionMiniCard(
                        c: c,
                        theme: theme,
                        label: 'Create your first collection',
                        onTap: () => context.push('/collections'),
                      ),
                    )
                  : ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: folders.length + 1,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (ctx, i) {
                        if (i == folders.length) {
                          return _NewCollectionMiniCard(
                            c: c,
                            theme: theme,
                            label: 'New Collection',
                            onTap: () => context.push('/collections'),
                          );
                        }
                        final folder = folders[i];
                        return _CollectionMiniCard(
                          folder: folder,
                          c: c,
                          theme: theme,
                          onTap: () => context.push(
                            '/collections/${folder.id}',
                            extra: folder,
                          ),
                        );
                      },
                    ),
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ),
        ),

        // ── PINNED CATEGORIES label ───────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 28, 16, 12),
            child: Text(
              'PINNED CATEGORIES',
              style: theme.labelSmall!.copyWith(
                color: c.textHint,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.8,
              ),
            ),
          ),
        ),

        // ── Pinned grid ───────────────────────────────────
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverGrid(
            delegate: SliverChildBuilderDelegate(
              (ctx, i) => gridItems[i],
              childCount: gridItems.length,
            ),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.92,
            ),
          ),
        ),

        // ── ALL TAGS header ───────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 28, 16, 14),
            child: Row(
              children: [
                Text(
                  'ALL TAGS',
                  style: theme.labelSmall!.copyWith(
                    color: c.textHint,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.8,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => setState(() => _sortAz = !_sortAz),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: c.surfaceElevated,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: c.border),
                    ),
                    child: Text(
                      _sortAz ? 'A-Z' : 'Z-A',
                      style: theme.labelSmall!.copyWith(
                        color: c.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Empty state ───────────────────────────────────
        if (allSorted.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Text(
                'No tags yet — tap + to create your first category.',
                textAlign: TextAlign.center,
                style: theme.bodySmall!.copyWith(color: c.textHint),
              ),
            ),
          ),

        // ── Tags chip wrap ────────────────────────────────
        if (allSorted.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
              child: Wrap(
                spacing: 8,
                runSpacing: 10,
                children: allSorted
                    .map((tag) => _TagChip(
                          tag: tag,
                          onTap: () => _openTag(tag),
                          onLongPress: () =>
                              _showTagOptions(context, tag),
                        ))
                    .toList(),
              ),
            ),
          ),
      ],
    );
  }
}

// ─── Platform Card ────────────────────────────────────────────────────────────

class _PlatformCard extends StatefulWidget {
  final _Platform platform;
  final VoidCallback onTap;
  const _PlatformCard({required this.platform, required this.onTap});

  @override
  State<_PlatformCard> createState() => _PlatformCardState();
}

class _PlatformCardState extends State<_PlatformCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final theme = Theme.of(context).textTheme;
    final p = widget.platform;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                p.color.withValues(alpha: _pressed ? 0.22 : 0.16),
                p.color.withValues(alpha: _pressed ? 0.08 : 0.04),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: p.color.withValues(alpha: 0.28),
              width: 0.8,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      p.color.withValues(alpha: 0.30),
                      p.color.withValues(alpha: 0.14),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: FaIcon(p.faIcon, size: 19, color: p.color),
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  p.name,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.labelSmall!.copyWith(
                    color: c.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Pinned Category Card ─────────────────────────────────────────────────────

class _PinnedCard extends StatefulWidget {
  final TagModel tag;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onUnpin;
  final VoidCallback onRename;

  const _PinnedCard({
    required this.tag,
    required this.onTap,
    required this.onDelete,
    required this.onUnpin,
    required this.onRename,
  });

  @override
  State<_PinnedCard> createState() => _PinnedCardState();
}

class _PinnedCardState extends State<_PinnedCard> {
  bool _pressed = false;

  void _showOptions(BuildContext context) {
    final c = context.colors;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: c.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: c.border, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Icon(Icons.edit_rounded, color: c.accent),
              title: const Text('Rename'),
              onTap: () {
                Navigator.pop(ctx);
                widget.onRename();
              },
            ),
            ListTile(
              leading: Icon(Icons.push_pin_outlined, color: c.textSecondary),
              title: const Text('Unpin'),
              onTap: () {
                Navigator.pop(ctx);
                widget.onUnpin();
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_outline_rounded, color: c.coral),
              title: Text('Delete', style: TextStyle(color: c.coral)),
              onTap: () {
                Navigator.pop(ctx);
                widget.onDelete();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  static const _fallbackColors = [
    AppColors.cyan,
    AppColors.purple,
    AppColors.green,
    AppColors.amber,
    AppColors.coral,
  ];

  static Color _resolveColor(TagModel tag) {
    if (tag.colorHex != null && tag.colorHex!.isNotEmpty) {
      try {
        final hex = tag.colorHex!.replaceFirst('#', '');
        return Color(int.parse('FF$hex', radix: 16));
      } catch (_) {}
    }
    return _fallbackColors[tag.id % _fallbackColors.length];
  }

  static final _cpMap = <int, IconData>{
    Icons.code_rounded.codePoint:            Icons.code_rounded,
    Icons.book_rounded.codePoint:            Icons.book_rounded,
    Icons.school_rounded.codePoint:          Icons.school_rounded,
    Icons.work_rounded.codePoint:            Icons.work_rounded,
    Icons.favorite_rounded.codePoint:        Icons.favorite_rounded,
    Icons.star_rounded.codePoint:            Icons.star_rounded,
    Icons.lightbulb_rounded.codePoint:       Icons.lightbulb_rounded,
    Icons.sports_esports_rounded.codePoint:  Icons.sports_esports_rounded,
    Icons.science_rounded.codePoint:         Icons.science_rounded,
    Icons.palette_rounded.codePoint:         Icons.palette_rounded,
    Icons.music_note_rounded.codePoint:      Icons.music_note_rounded,
    Icons.trending_up_rounded.codePoint:     Icons.trending_up_rounded,
    Icons.design_services_rounded.codePoint: Icons.design_services_rounded,
    Icons.menu_book_rounded.codePoint:       Icons.menu_book_rounded,
    Icons.play_circle_rounded.codePoint:     Icons.play_circle_rounded,
    Icons.article_rounded.codePoint:         Icons.article_rounded,
    Icons.people_rounded.codePoint:          Icons.people_rounded,
    Icons.build_rounded.codePoint:           Icons.build_rounded,
    Icons.folder_rounded.codePoint:          Icons.folder_rounded,
  };

  static IconData _resolveIcon(String? iconStr) {
    if (iconStr == null) return Icons.folder_rounded;
    final cp = int.tryParse(iconStr);
    if (cp != null) return _cpMap[cp] ?? Icons.folder_rounded;
    const map = {
      'code':    Icons.code_rounded,
      'study':   Icons.school_rounded,
      'design':  Icons.design_services_rounded,
      'book':    Icons.menu_book_rounded,
      'work':    Icons.work_rounded,
      'star':    Icons.star_rounded,
      'idea':    Icons.lightbulb_rounded,
      'video':   Icons.play_circle_rounded,
      'article': Icons.article_rounded,
      'social':  Icons.people_rounded,
      'tool':    Icons.build_rounded,
    };
    return map[iconStr] ?? Icons.folder_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final theme = Theme.of(context).textTheme;
    final color = _resolveColor(widget.tag);
    final iconData = _resolveIcon(widget.tag.icon);
    final linkCount = widget.tag.links.length;

    return GestureDetector(
      onTap: widget.onTap,
      onLongPress: () => _showOptions(context),
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: c.border, width: 0.5),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(iconData, color: color, size: 20),
                        ),
                        const Spacer(),
                        Text(
                          '$linkCount',
                          style: theme.bodySmall!.copyWith(
                            color: c.textHint,
                            fontWeight: FontWeight.w600,
                            height: 1,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      widget.tag.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.titleSmall!.copyWith(
                        fontWeight: FontWeight.w700,
                        color: c.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
              Positioned(
                left: 0, right: 0, bottom: 0,
                child: Container(
                  height: 3,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.transparent, color, Colors.transparent],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── New Category Card ────────────────────────────────────────────────────────

class _NewCategoryCard extends StatelessWidget {
  final VoidCallback onTap;
  const _NewCategoryCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final theme = Theme.of(context).textTheme;
    return GestureDetector(
      onTap: onTap,
      child: CustomPaint(
        painter: _DashedBorderPainter(color: c.border),
        child: Container(
          decoration: BoxDecoration(
            color: c.surface.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: c.border, width: 1.5),
                  ),
                  child:
                      Icon(Icons.add_rounded, color: c.textHint, size: 22),
                ),
                const SizedBox(height: 10),
                Text(
                  'New Category',
                  style: theme.bodySmall!.copyWith(
                    color: c.textHint,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  _DashedBorderPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    const pad = 0.75;
    const radius = 20.0;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(pad, pad, size.width - pad * 2, size.height - pad * 2),
      const Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);
    canvas.drawPath(_dashPath(path), paint);
  }

  static Path _dashPath(Path source) {
    const dashLen = 6.0;
    const gapLen = 4.0;
    final dest = Path();
    for (final metric in source.computeMetrics()) {
      double distance = 0;
      bool draw = true;
      while (distance < metric.length) {
        final seg = draw ? dashLen : gapLen;
        if (draw) {
          dest.addPath(
            metric.extractPath(distance, distance + seg),
            Offset.zero,
          );
        }
        distance += seg;
        draw = !draw;
      }
    }
    return dest;
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) => old.color != color;
}

// ─── Tag Chip ─────────────────────────────────────────────────────────────────

class _TagChip extends StatelessWidget {
  final TagModel tag;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _TagChip({
    required this.tag,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final theme = Theme.of(context).textTheme;
    final isPinned = tag.isDefault;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(50),
          border: Border.all(
            color: isPinned ? c.accentBorder : c.border,
            width: isPinned ? 1.0 : 0.5,
          ),
        ),
        child: RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: '#${tag.name.toLowerCase()} ',
                style: theme.bodySmall!.copyWith(
                  color: c.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              TextSpan(
                text: '${tag.links.length}',
                style: theme.bodySmall!.copyWith(
                  color: c.accent,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Collection Mini Card (horizontal strip) ──────────────────────────────────

class _CollectionMiniCard extends StatelessWidget {
  final FolderModel folder;
  final AppColorScheme c;
  final TextTheme theme;
  final VoidCallback onTap;

  const _CollectionMiniCard({
    required this.folder,
    required this.c,
    required this.theme,
    required this.onTap,
  });

  static const _fallbacks = [
    AppColors.cyan,
    AppColors.purple,
    AppColors.green,
    AppColors.amber,
    AppColors.coral,
  ];

  static Color _resolveColor(FolderModel folder) {
    if (folder.colorHex != null && folder.colorHex!.isNotEmpty) {
      try {
        final hex = folder.colorHex!.replaceFirst('#', '');
        return Color(int.parse('FF$hex', radix: 16));
      } catch (_) {}
    }
    return _fallbacks[folder.id % _fallbacks.length];
  }

  @override
  Widget build(BuildContext context) {
    final color = _resolveColor(folder);
    final linkCount = folder.links.length;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 130,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: c.border, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(Icons.folder_rounded, color: color, size: 16),
            ),
            const Spacer(),
            Text(
              folder.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.labelMedium!.copyWith(
                fontWeight: FontWeight.w700,
                color: c.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '$linkCount ${linkCount == 1 ? 'link' : 'links'}',
              style: theme.labelSmall!
                  .copyWith(color: c.textHint, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── New Collection Mini Card ──────────────────────────────────────────────────

class _NewCollectionMiniCard extends StatelessWidget {
  final AppColorScheme c;
  final TextTheme theme;
  final String label;
  final VoidCallback onTap;

  const _NewCollectionMiniCard({
    required this.c,
    required this.theme,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: CustomPaint(
        painter: _DashedBorderPainter(color: c.border),
        child: Container(
          width: 130,
          decoration: BoxDecoration(
            color: c.surface.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: c.border, width: 1.5),
                    ),
                    child: Icon(Icons.add_rounded,
                        color: c.textHint, size: 18),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.labelSmall!.copyWith(
                      color: c.textHint,
                      fontWeight: FontWeight.w500,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
