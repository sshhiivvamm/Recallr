import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../common/sheet_fab.dart';
import '../../../data/models/collection_model.dart';
import '../../../theme/recallr_colors.dart';
import '../collections/collection_provider.dart';

class ReCollections extends ConsumerWidget {
  const ReCollections({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final theme = Theme.of(context).textTheme;
    final foldersAsync = ref.watch(collectionsStreamProvider);

    return SheetFabHost(
      heroTag: 'collections_fab',
      openSheet: (ctx, {required onSheetTopY, required onSheetAnimation}) =>
          showModalBottomSheet<void>(
            context: ctx,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => _CollectionCreateSheet(
              onSheetTopY: onSheetTopY,
              onSheetAnimation: onSheetAnimation,
            ),
          ),
      child: Scaffold(
        backgroundColor: c.background,
        appBar: AppBar(
          backgroundColor: c.background,
          elevation: 0,
          scrolledUnderElevation: 0,
          title: Text('COLLECTIONS', style: theme.headlineLarge),
        ),
        body: foldersAsync.when(
          data: (folders) => _Body(folders: folders, c: c, theme: theme),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text(e.toString())),
        ),
      ),
    );
  }
}

// ── Color helpers ─────────────────────────────────────────────────────────────

const _kPaletteColors = [
  AppColors.cyan,
  AppColors.purple,
  AppColors.green,
  AppColors.amber,
  AppColors.coral,
  Color(0xFF60A5FA), // blue
];

Color _colorFromHex(String? hex, Color fallback) {
  if (hex == null || hex.isEmpty) return fallback;
  try {
    final sanitized = hex.replaceFirst('#', '');
    return Color(int.parse('FF$sanitized', radix: 16));
  } catch (_) {
    return fallback;
  }
}

String _hexFromColor(Color color) =>
    color.toARGB32().toRadixString(16).substring(2).toUpperCase();

// ── Create-collection sheet ───────────────────────────────────────────────────

class _CollectionCreateSheet extends ConsumerStatefulWidget {
  final ValueChanged<double> onSheetTopY;
  final ValueChanged<Animation<double>> onSheetAnimation;

  const _CollectionCreateSheet({
    required this.onSheetTopY,
    required this.onSheetAnimation,
  });

  @override
  ConsumerState<_CollectionCreateSheet> createState() =>
      _CollectionCreateSheetState();
}

class _CollectionCreateSheetState
    extends ConsumerState<_CollectionCreateSheet>
    with SheetFabReporter<_CollectionCreateSheet> {
  @override
  ValueChanged<double>? get onSheetTopY => widget.onSheetTopY;
  @override
  ValueChanged<Animation<double>>? get onSheetAnimation =>
      widget.onSheetAnimation;

  final _ctrl = TextEditingController();
  Color _selectedColor = AppColors.cyan;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _ctrl.text.trim();
    if (name.isEmpty) return;
    final repo = await ref.read(collectionRepoProvider.future);
    await repo.create(name, colorHex: _hexFromColor(_selectedColor));
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final theme = Theme.of(context).textTheme;
    final kb = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + kb),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.border, width: 0.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'New Collection',
            style: theme.titleMedium!.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _ctrl,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Collection name'),
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: 16),
          Text(
            'COLOR',
            style: theme.labelSmall!.copyWith(
              color: c.textHint,
              letterSpacing: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: _kPaletteColors.map((color) {
              final isSelected = _selectedColor == color;
              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: GestureDetector(
                  onTap: () => setState(() => _selectedColor = color),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(color: Colors.white, width: 2.5)
                          : null,
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: color.withValues(alpha: 0.5),
                                blurRadius: 8,
                                spreadRadius: 1,
                              )
                            ]
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check_rounded,
                            color: Colors.white, size: 14)
                        : null,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _save,
              child: const Text('Create'),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Body ──────────────────────────────────────────────────────────────────────

class _Body extends ConsumerWidget {
  final List<FolderModel> folders;
  final AppColorScheme c;
  final TextTheme theme;

  const _Body({required this.folders, required this.c, required this.theme});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: c.border, width: 0.5),
                    borderRadius: BorderRadius.circular(20),
                    color: c.surfaceElevated,
                  ),
                  child: Text(
                    'O R G A N I Z E',
                    style: theme.labelSmall!.copyWith(
                      color: c.accent,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.8,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Collections',
                      style: theme.displayLarge!.copyWith(
                        fontSize: 38,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: c.accentDim,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${folders.length}',
                          style: theme.labelMedium!.copyWith(
                            color: c.accent,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        if (folders.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: _EmptyState(c: c, theme: theme),
          ),

        if (folders.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate(
                (ctx, index) => _FolderCard(
                  folder: folders[index],
                  c: c,
                  theme: theme,
                  onTap: () => ctx.push(
                    '/collections/${folders[index].id}',
                    extra: folders[index],
                  ),
                  onDelete: () =>
                      _confirmDelete(ctx, ref, folders[index]),
                ),
                childCount: folders.length,
              ),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.05,
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, FolderModel folder) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Collection'),
        content:
            Text("Delete '${folder.name}'? Links won't be affected."),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Delete',
                style: TextStyle(color: context.colors.coral)),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      final repo = await ref.read(collectionRepoProvider.future);
      await repo.delete(folder.id);
    }
  }
}

// ── Folder Card ───────────────────────────────────────────────────────────────

class _FolderCard extends StatefulWidget {
  final FolderModel folder;
  final AppColorScheme c;
  final TextTheme theme;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _FolderCard({
    required this.folder,
    required this.c,
    required this.theme,
    required this.onTap,
    required this.onDelete,
  });

  @override
  State<_FolderCard> createState() => _FolderCardState();
}

class _FolderCardState extends State<_FolderCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final folder = widget.folder;
    final c = widget.c;
    final theme = widget.theme;

    const fallbacks = [
      AppColors.cyan,
      AppColors.purple,
      AppColors.green,
      AppColors.amber,
      AppColors.coral,
    ];
    final color = _colorFromHex(
      folder.colorHex,
      fallbacks[folder.id % fallbacks.length],
    );
    final linkCount = folder.links.length;

    return Listener(
      onPointerDown: (_) => setState(() => _pressed = true),
      onPointerUp: (_) => setState(() => _pressed = false),
      onPointerCancel: (_) => setState(() => _pressed = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _pressed ? 0.972 : 1.0,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _pressed ? c.surfaceElevated : c.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _pressed ? color.withValues(alpha: 0.4) : c.border,
                width: _pressed ? 1.0 : 0.5,
              ),
              boxShadow: _pressed
                  ? []
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.folder_rounded,
                          color: color, size: 20),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: widget.onDelete,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: c.surfaceElevated,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: c.border, width: 0.5),
                        ),
                        child: Icon(Icons.close_rounded,
                            size: 14, color: c.textHint),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  folder.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.titleSmall!.copyWith(
                    fontWeight: FontWeight.w700,
                    color: c.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '$linkCount ${linkCount == 1 ? 'link' : 'links'}',
                      style:
                          theme.labelSmall!.copyWith(color: c.textHint),
                    ),
                    const Spacer(),
                    Icon(Icons.arrow_outward_rounded,
                        size: 14, color: color),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final AppColorScheme c;
  final TextTheme theme;

  const _EmptyState({required this.c, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: c.surfaceElevated,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: c.border, width: 0.5),
            ),
            child: Icon(Icons.folder_open_rounded, size: 36, color: c.accent),
          ),
          const SizedBox(height: 20),
          Text(
            'No collections yet',
            style: theme.titleMedium!.copyWith(
              fontWeight: FontWeight.w700,
              color: c.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create collections to group your\nlinks by project or topic.',
            textAlign: TextAlign.center,
            style: theme.bodySmall!.copyWith(color: c.textHint, height: 1.5),
          ),
        ],
      ),
    );
  }
}
