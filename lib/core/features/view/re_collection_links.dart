import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../common/all_links_wid.dart';
import '../../../data/models/collection_model.dart';
import '../../../theme/recallr_colors.dart';
import '../collections/collection_provider.dart';

class ReCollectionLinks extends ConsumerWidget {
  final FolderModel folder;
  const ReCollectionLinks({super.key, required this.folder});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final theme = Theme.of(context).textTheme;
    final linksAsync = ref.watch(folderLinksProvider(folder.id));

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        backgroundColor: c.background,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: c.textPrimary, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            Icon(Icons.folder_rounded, size: 18, color: c.accent),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                folder.name,
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
                      color: c.surfaceElevated,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: c.border, width: 0.5),
                    ),
                    child: Icon(Icons.folder_open_rounded,
                        size: 32, color: c.accent),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No links yet',
                    style: theme.titleSmall!
                        .copyWith(fontWeight: FontWeight.w700, color: c.textPrimary),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Save links and assign them to "${folder.name}"',
                    style: theme.bodySmall!.copyWith(color: c.textHint),
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
                      style: theme.labelMedium!.copyWith(color: c.textHint),
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
