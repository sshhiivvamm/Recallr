import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

import '../../../common/add_category_sheet.dart';
import '../../../common/sheet_fab.dart';
import '../../../data/models/Tag/tag_model.dart';
import '../../../theme/recallr_colors.dart';
import '../../database/providers/isar_provider.dart';
import '../category/tag_list_provider.dart';

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

  static IconData _resolveIcon(String? iconStr) {
    if (iconStr == null) return Icons.folder_rounded;
    final cp = int.tryParse(iconStr);
    if (cp != null) return IconData(cp, fontFamily: 'MaterialIcons');
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

    final gridItems = <Widget>[
      ...pinned.map((tag) => _PinnedCard(
            tag: tag,
            onTap: () => _openTag(tag),
            onDelete: () => _confirmDelete(context, tag),
            onUnpin: () => _togglePin(tag),
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
                          onLongPress: () => _togglePin(tag),
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

  const _PinnedCard({
    required this.tag,
    required this.onTap,
    required this.onDelete,
    required this.onUnpin,
  });

  @override
  State<_PinnedCard> createState() => _PinnedCardState();
}

class _PinnedCardState extends State<_PinnedCard> {
  bool _pressed = false;

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

  static IconData _resolveIcon(String? iconStr) {
    if (iconStr == null) return Icons.folder_rounded;
    final cp = int.tryParse(iconStr);
    if (cp != null) return IconData(cp, fontFamily: 'MaterialIcons');
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
      onLongPress: widget.onUnpin,
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
