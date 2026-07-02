import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:isar/isar.dart';

import '../../../common/all_links_wid.dart';
import '../../../data/models/Link/link_model.dart';
import '../../../data/models/Tag/tag_model.dart';
import '../../../theme/recallr_colors.dart';
import '../../database/providers/isar_provider.dart';

// ── Providers ─────────────────────────────────────────────────────────────────

final _tagLinksProvider =
    StreamProvider.family<List<LinkModel>, int>((ref, tagId) async* {
  final isar = await ref.watch(isarProvider.future);
  // Use the tag's backlinks so we don't need the generated filter extension
  yield* isar.tagModels
      .watchObject(tagId, fireImmediately: true)
      .asyncMap((tag) async {
    if (tag == null) return <LinkModel>[];
    await tag.links.load();
    final list = tag.links.toList();
    await Future.wait(list.map((l) => l.tags.load()));
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  });
});

final _domainLinksProvider =
    StreamProvider.family<List<LinkModel>, String>((ref, keyword) async* {
  final isar = await ref.watch(isarProvider.future);
  // watchLazy fires on any LinkModel change; we re-query and sort in Dart
  final kw = keyword.toLowerCase();
  yield* isar.linkModels.watchLazy(fireImmediately: true).asyncMap((_) async {
    final all = await isar.linkModels.where().findAll();
    final filtered = all
        .where((l) => (l.domain ?? '').toLowerCase().contains(kw))
        .toList();
    await Future.wait(filtered.map((l) => l.tags.load()));
    filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return filtered;
  });
});

// ── Screen ────────────────────────────────────────────────────────────────────

class ReFilteredLinks extends ConsumerWidget {
  final String title;
  final Color color;
  final IconData icon;
  /// If set, filters by tag id.
  final int? tagId;
  /// If set, filters by domain keyword (e.g. "youtube").
  final String? domainKeyword;

  const ReFilteredLinks({
    super.key,
    required this.title,
    required this.color,
    required this.icon,
    this.tagId,
    this.domainKeyword,
  }) : assert(tagId != null || domainKeyword != null);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final theme = Theme.of(context).textTheme;

    final linksAsync = tagId != null
        ? ref.watch(_tagLinksProvider(tagId!))
        : ref.watch(_domainLinksProvider(domainKeyword!));

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        backgroundColor: c.background,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon:
              Icon(Icons.arrow_back_rounded, color: c.textPrimary, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: theme.titleLarge!.copyWith(fontWeight: FontWeight.w700),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      body: linksAsync.when(
        data: (links) {
          if (links.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(icon, size: 32, color: color),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No links yet',
                    style: theme.titleSmall!.copyWith(
                        fontWeight: FontWeight.w700, color: c.textPrimary),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Save a link from $title to see it here',
                    style:
                        theme.bodySmall!.copyWith(color: c.textHint),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                child: Row(
                  children: [
                    Text(
                      '${links.length} ${links.length == 1 ? 'link' : 'links'}',
                      style:
                          theme.labelMedium!.copyWith(color: c.textHint),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                  itemCount: links.length,
                  separatorBuilder: (ctx, i) => const SizedBox(height: 8),
                  itemBuilder: (ctx, i) => LinkCard(
                    link: links[i],
                    onTap: () {
                      final url = links[i].url;
                      if (url.isEmpty) return;
                      context.push(
                        '/reader',
                        extra: {'url': url, 'linkId': links[i].id},
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          itemCount: 5,
          separatorBuilder: (ctx, i) => const SizedBox(height: 8),
          itemBuilder: (ctx, i) => LinkSkeletonCard(c: c),
        ),
        error: (e, _) => Center(
          child: Text(e.toString(),
              style: theme.bodySmall!.copyWith(color: c.coral)),
        ),
      ),
    );
  }
}
