import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../common/add_category_sheet.dart';
import '../../../common/sheet_fab.dart';
import '../../../data/models/Tag/tag_model.dart';
import '../../../theme/recallr_colors.dart';
import '../../database/providers/isar_provider.dart';
import '../category/tag_list_provider.dart';

class ReCategory extends ConsumerWidget {
  const ReCategory({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final theme = Theme.of(context).textTheme;
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
        appBar: AppBar(
          backgroundColor: c.background,
          elevation: 0,
          scrolledUnderElevation: 0,
          title: Text('CATEGORIES', style: theme.headlineLarge),
        ),
        body: tagsAsync.when(
          data: (tags) => _Body(tags: tags, c: c, theme: theme, ref: ref),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Text(e.toString(),
                style: theme.bodyMedium!.copyWith(color: c.coral)),
          ),
        ),
      ),
    );
  }
}

// ── Body ─────────────────────────────────────────────────────────────────────

class _Body extends StatelessWidget {
  final List<TagModel> tags;
  final AppColorScheme c;
  final TextTheme theme;
  final WidgetRef ref;

  const _Body({
    required this.tags,
    required this.c,
    required this.theme,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // ── Header ──────────────────────────────────────
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
                    'L I B R A R Y',
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
                      'Categories',
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
                          '${tags.length}',
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

        // ── Empty state ──────────────────────────────────
        if (tags.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: _EmptyState(c: c, theme: theme, context: context),
          ),

        // ── Category grid ────────────────────────────────
        if (tags.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate(
                (ctx, index) {
                  final tag = tags[index];
                  return _CategoryCard(
                    tag: tag,
                    c: c,
                    theme: theme,
                    onDelete: () => _confirmDelete(ctx, ref, tag),
                  );
                },
                childCount: tags.length,
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
      BuildContext context, WidgetRef ref, TagModel tag) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text(
          "Delete '${tag.name}'? Links won't be affected.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Delete',
                style: TextStyle(color: context.colors.coral)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (!context.mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      final isar = await ref.read(isarProvider.future);
      await isar.writeTxn(() async {
        for (final link in tag.links) {
          link.tags.remove(tag);
          await link.tags.save();
        }
        await isar.tagModels.delete(tag.id);
      });
      ref.invalidate(tagListProvider);
      messenger.showSnackBar(
        SnackBar(content: Text("'${tag.name}' deleted")),
      );
    }
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final AppColorScheme c;
  final TextTheme theme;
  final BuildContext context;

  const _EmptyState({
    required this.c,
    required this.theme,
    required this.context,
  });

  @override
  Widget build(BuildContext ctx) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Illustration container
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: c.surfaceElevated,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: c.border, width: 0.5),
            ),
            child: Icon(
              Icons.folder_open_rounded,
              size: 36,
              color: c.accent,
            ),
          ),

          const SizedBox(height: 20),

          Text(
            'No categories yet',
            style: theme.titleMedium!.copyWith(
              fontWeight: FontWeight.w700,
              color: c.textPrimary,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'Create categories to organise your saved\nlinks by topic, project, or interest.',
            textAlign: TextAlign.center,
            style: theme.bodySmall!.copyWith(
              color: c.textHint,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 28),

          // Suggested categories chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: const [
              _SuggestionChip(label: '🖥  Dev'),
              _SuggestionChip(label: '🎨  Design'),
              _SuggestionChip(label: '📚  Reading'),
              _SuggestionChip(label: '🔬  Research'),
              _SuggestionChip(label: '💡  Ideas'),
            ],
          ),

          const SizedBox(height: 28),

          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (_) => const AddCategorySheet(),
              ),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Create your first category'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  final String label;
  const _SuggestionChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: c.surfaceElevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.border, width: 0.5),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall!.copyWith(
              color: c.textSecondary,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

// ── Category Card ─────────────────────────────────────────────────────────────

class _CategoryCard extends StatelessWidget {
  final TagModel tag;
  final AppColorScheme c;
  final TextTheme theme;
  final VoidCallback onDelete;

  const _CategoryCard({
    required this.tag,
    required this.c,
    required this.theme,
    required this.onDelete,
  });

  static const _iconMap = {
    'code': Icons.code_rounded,
    'study': Icons.school_rounded,
    'design': Icons.design_services_rounded,
    'book': Icons.menu_book_rounded,
    'work': Icons.work_rounded,
    'star': Icons.star_rounded,
    'idea': Icons.lightbulb_rounded,
  };

  static const _colorMap = {
    0: AppColors.cyan,
    1: AppColors.purple,
    2: AppColors.green,
    3: AppColors.amber,
    4: AppColors.coral,
  };

  @override
  Widget build(BuildContext context) {
    final icon = _iconMap[tag.icon] ?? Icons.folder_rounded;
    final color = _colorMap[tag.id % 5] ?? AppColors.cyan;
    final dimColor = color.withValues(alpha: 0.12);
    final linkCount = tag.links.length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.border, width: 0.5),
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
                  color: dimColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
              GestureDetector(
                onTap: onDelete,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: c.surfaceElevated,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: c.border, width: 0.5),
                  ),
                  child: Icon(Icons.close_rounded, size: 14, color: c.textHint),
                ),
              ),
            ],
          ),

          const Spacer(),

          Text(
            tag.name,
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
                style: theme.labelSmall!.copyWith(color: c.textHint),
              ),
              const Spacer(),
              Icon(Icons.arrow_outward_rounded, size: 14, color: color),
            ],
          ),
        ],
      ),
    );
  }
}
