import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:recallr/theme/recallr_colors.dart';

import '../core/repositrories/link_providers/link_repository_provider.dart';
import '../data/models/Link/link_model.dart';
import 'edit_link_sheet.dart';

Future<void> showLinkOptions(
  BuildContext context,
  WidgetRef ref,
  LinkModel link,
) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    useRootNavigator: true,
    isScrollControlled: true,
    builder: (_) => LinkOptionsSheet(link: link, ref: ref),
  );
}

/// Public (unlike edit_link_sheet's private sibling) so golden tests can
/// render it directly instead of driving `showLinkOptions`'s modal —
/// see `test/golden/link_options_sheet_golden_test.dart`.
class LinkOptionsSheet extends ConsumerWidget {
  final LinkModel link;
  final WidgetRef ref;

  const LinkOptionsSheet({super.key, required this.link, required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef innerRef) {
    final c = context.colors;
    final theme = Theme.of(context).textTheme;
    final repo = ref.read(linkRepositoryProvider);
    final router = GoRouter.of(context);
    final messenger = ScaffoldMessenger.of(context);

    void openReader() {
      Navigator.of(context).pop();
      router.push('/reader', extra: {'url': link.url, 'linkId': link.id});
    }

    void openExternal() async {
      Navigator.of(context).pop();
      final uri = Uri.tryParse(link.url);
      if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
    }

    void toggleFavorite() async {
      await repo.toggleFavorite(link.id);
      if (context.mounted) Navigator.of(context).pop();
    }

    void toggleRead() async {
      await repo.toggleRead(link.id);
      if (context.mounted) Navigator.of(context).pop();
    }

    void shareLink() {
      Navigator.of(context).pop();
      Share.share(
        '${link.url}\n\nShared from Recallr vault',
        subject: link.title,
      );
    }

    void copyUrl() {
      Clipboard.setData(ClipboardData(text: link.url));
      Navigator.of(context).pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text('URL copied to clipboard'),
          backgroundColor: c.surface,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }

    void deleteLink() async {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dCtx) => AlertDialog(
          backgroundColor: c.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Delete link?',
            style: theme.titleMedium!.copyWith(
              color: c.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            'This will permanently remove "${link.title}".',
            style: theme.bodySmall!.copyWith(color: c.textSecondary, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dCtx).pop(false),
              child: Text('Cancel', style: TextStyle(color: c.textSecondary)),
            ),
            TextButton(
              onPressed: () => Navigator.of(dCtx).pop(true),
              child: Text(
                'Delete',
                style: TextStyle(color: c.coral, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        await repo.deleteLink(link.id);
        if (context.mounted) Navigator.of(context).pop();
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: c.border, width: 0.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 16),
            decoration: BoxDecoration(
              color: c.borderSoft,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Link preview header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: c.surfaceElevated,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: c.border, width: 0.5),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(9),
                    child: CachedNetworkImage(
                      imageUrl: link.favicon ?? '',
                      fit: BoxFit.cover,
                      errorWidget: (ctx, url, e) =>
                          Icon(Icons.link_rounded, size: 16, color: c.textHint),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        link.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.titleSmall!.copyWith(
                          fontWeight: FontWeight.w600,
                          color: c.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        link.domain ?? link.url,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.bodySmall!.copyWith(
                          color: c.textHint,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Divider(color: c.border, height: 1, thickness: 0.5),
          const SizedBox(height: 6),

          _ActionTile(
            icon: Icons.open_in_new_rounded,
            label: 'Open in reader',
            color: c.accent,
            c: c,
            theme: theme,
            onTap: openReader,
          ),
          _ActionTile(
            icon: Icons.edit_rounded,
            label: 'Edit link',
            color: c.purple,
            c: c,
            theme: theme,
            onTap: () {
              Navigator.of(context).pop();
              showEditLink(context, ref, link);
            },
          ),
          _ActionTile(
            icon: Icons.open_in_browser_rounded,
            label: 'Open in browser',
            color: c.purple,
            c: c,
            theme: theme,
            onTap: openExternal,
          ),
          _ActionTile(
            icon: link.isFavorite
                ? Icons.bookmark_rounded
                : Icons.bookmark_border_rounded,
            label: link.isFavorite ? 'Remove from favorites' : 'Add to favorites',
            color: c.amber,
            c: c,
            theme: theme,
            onTap: toggleFavorite,
          ),
          _ActionTile(
            icon: link.isRead
                ? Icons.remove_done_rounded
                : Icons.done_all_rounded,
            label: link.isRead ? 'Mark as unread' : 'Mark as read',
            color: c.green,
            c: c,
            theme: theme,
            onTap: toggleRead,
          ),
          _ActionTile(
            icon: Icons.copy_rounded,
            label: 'Copy URL',
            color: c.accent,
            c: c,
            theme: theme,
            onTap: copyUrl,
          ),
          _ActionTile(
            icon: Icons.share_rounded,
            label: 'Share link',
            color: c.green,
            c: c,
            theme: theme,
            onTap: shareLink,
          ),

          const SizedBox(height: 6),
          Divider(color: c.border, height: 1, thickness: 0.5),
          const SizedBox(height: 6),

          _ActionTile(
            icon: Icons.delete_outline_rounded,
            label: 'Delete',
            color: c.coral,
            c: c,
            theme: theme,
            isDestructive: true,
            onTap: deleteLink,
          ),

          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }
}

class _ActionTile extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final dynamic c;
  final TextTheme theme;
  final VoidCallback onTap;
  final bool isDestructive;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.c,
    required this.theme,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  State<_ActionTile> createState() => _ActionTileState();
}

class _ActionTileState extends State<_ActionTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        color: _pressed ? widget.c.surfaceElevated : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: widget.color.withValues(alpha: _pressed ? 0.18 : 0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(widget.icon, size: 18, color: widget.color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                widget.label,
                style: widget.theme.bodyMedium!.copyWith(
                  color: widget.isDestructive ? widget.color : widget.c.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 16,
              color: widget.c.textHint,
            ),
          ],
        ),
      ),
    );
  }
}
