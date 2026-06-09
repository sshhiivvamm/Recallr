import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../core/repositrories/link_providers/link_repository_provider.dart';
import '../core/services/link_health_service.dart';

String readingTimeLabel(String title, String? description) {
  final text = '$title ${description ?? ''}';
  final words = text.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
  final minutes = (words / 200).ceil();
  if (minutes <= 1) return '< 1 min';
  return '$minutes min';
}

final _healthProvider = FutureProvider.family<bool?, int>((ref, linkId) async {
  return LinkHealthService.instance.getCachedStatus(linkId);
});

void showLinkActions({
  required BuildContext context,
  required dynamic link,
  required dynamic c,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: c.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => _ActionSheet(link: link, c: c),
  );
}

class _ActionSheet extends ConsumerWidget {
  final dynamic link;
  final dynamic c;

  const _ActionSheet({required this.link, required this.c});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _tile(
            icon: link.isFavorite
                ? Icons.bookmark_remove_outlined
                : Icons.bookmark_rounded,
            label: link.isFavorite ? 'Remove Favorite' : 'Mark Favorite',
            onTap: () async {
              Navigator.pop(context);
              await ref.read(linkRepositoryProvider).toggleFavorite(link.id);
            },
          ),
          _tile(
            icon: link.isRead
                ? Icons.radio_button_unchecked_rounded
                : Icons.check_circle_outline,
            label: link.isRead ? 'Mark as Unread' : 'Mark as Read',
            onTap: () async {
              Navigator.pop(context);
              await ref.read(linkRepositoryProvider).toggleRead(link.id);
            },
          ),
          _tile(
            icon: Icons.delete_outline,
            label: 'Delete',
            isDanger: true,
            onTap: () async {
              Navigator.pop(context);
              await ref.read(linkRepositoryProvider).deleteLink(link.id);
            },
          ),
        ],
      ),
    );
  }

  Widget _tile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isDanger = false,
  }) {
    return ListTile(
      leading: Icon(icon, color: isDanger ? Colors.red : null),
      title: Text(label, style: TextStyle(color: isDanger ? Colors.red : null)),
      onTap: onTap,
    );
  }
}

class LinkCard extends ConsumerWidget {
  final dynamic link;
  final dynamic c;
  final TextTheme theme;
  final VoidCallback onTap;

  const LinkCard({
    super.key,
    required this.link,
    required this.c,
    required this.theme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final healthAsync = ref.watch(_healthProvider(link.id as int));
    final isDead = healthAsync.maybeWhen(data: (v) => v == false, orElse: () => false);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDead ? Colors.red.withValues(alpha: 0.4) : c.border,
            width: isDead ? 1.0 : 0.5,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _favicon(),
            const SizedBox(width: 12),

            Expanded(child: _content(context, isDead)),

            const SizedBox(width: 6),

            _moreButton(context),
            _thumbnail(),
          ],
        ),
      ),
    );
  }

  Widget _moreButton(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: () =>
          showLinkActions(context: context, link: link, c: c),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(
          Icons.more_horiz,
          size: 18,
          color: c.textSecondary,
        ),
      ),
    );
  }

  Widget _favicon() => Container(
    width: 32,
    height: 32,
    decoration: BoxDecoration(
      color: c.surfaceElevated,
      borderRadius: BorderRadius.circular(8),
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(7),
      child: Image.network(
        link.favicon ?? '',
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            Icon(Icons.link, size: 14, color: c.textHint),
      ),
    ),
  );

  Widget _content(BuildContext context, bool isDead) {
    final readTime = readingTimeLabel(link.title ?? '', link.description as String?);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                link.title ?? '',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.titleSmall!.copyWith(
                  fontWeight: FontWeight.w600,
                  color: c.textPrimary,
                ),
              ),
            ),
            if (isDead)
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Icon(Icons.wifi_off_rounded, size: 13, color: Colors.red.shade400),
              )
            else if (link.isFavorite == true)
              Icon(Icons.bookmark_rounded, size: 14, color: c.accent),
          ],
        ),

        const SizedBox(height: 4),

        Text(
          link.domain ?? '',
          style: theme.bodySmall!.copyWith(color: c.textHint),
        ),

        const SizedBox(height: 8),

        Row(
          children: [
            if (link.tags.isNotEmpty)
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: c.accentDim,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    link.tags.first.name.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.labelSmall!.copyWith(
                      color: c.accent,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),

            if (link.tags.isNotEmpty) const SizedBox(width: 6),

            // Reading time badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: c.surfaceElevated,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: c.borderSoft, width: 0.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.schedule_rounded, size: 9, color: c.textHint),
                  const SizedBox(width: 3),
                  Text(
                    readTime,
                    style: theme.labelSmall!.copyWith(
                      color: c.textHint,
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            Text(
              DateFormat.MMMd().format(link.createdAt),
              style: theme.bodySmall!.copyWith(color: c.textHint),
            ),

            const SizedBox(width: 6),
          ],
        )
      ],
    );
  }

  Widget _thumbnail() {
    if (link.thumbnail == null || link.thumbnail.isEmpty) {
      return const SizedBox();
    }

    return Padding(
      padding: const EdgeInsets.only(left: 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          link.thumbnail!,
          width: 60,
          height: 60,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}


class CompactRow extends StatelessWidget {
  final dynamic link;
  final dynamic c;
  final TextTheme theme;
  final VoidCallback onTap;

  const CompactRow({
    super.key,
    required this.link,
    required this.c,
    required this.theme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Image.network(link.favicon ?? '', width: 24, height: 24,
                errorBuilder: (_, __, ___) =>
                    Icon(Icons.link, size: 14, color: c.textHint)),

            const SizedBox(width: 10),

            Expanded(
              child: Text(
                link.title ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            Text(DateFormat.MMMd().format(link.createdAt)),
            IconButton(
              icon: const Icon(Icons.more_horiz, size: 16),
              onPressed: () =>
                  showLinkActions(context: context, link: link, c: c),
            )
          ],
        ),
      ),
    );
  }
}