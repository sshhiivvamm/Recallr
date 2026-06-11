import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:recallr/theme/recallr_colors.dart';

import '../data/models/Link/link_model.dart';
import 'link_options_sheet.dart';

// ── Reading time helper ───────────────────────────────────────────────────────

String readingTimeLabel(String title, String? description) {
  final text = '$title ${description ?? ''}';
  final words =
      text.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
  final minutes = (words / 200).ceil();
  if (minutes <= 1) return '< 1 min';
  return '$minutes min';
}

// ── LinkCard ──────────────────────────────────────────────────────────────────

class LinkCard extends ConsumerStatefulWidget {
  final LinkModel link;
  final VoidCallback onTap;

  const LinkCard({
    super.key,
    required this.link,
    required this.onTap,
  });

  @override
  ConsumerState<LinkCard> createState() => _LinkCardState();
}

class _LinkCardState extends ConsumerState<LinkCard> {
  bool _pressed = false;

  int get _readTime {
    final words =
        '${widget.link.title} ${widget.link.description ?? ''}'
            .split(RegExp(r'\s+'))
            .where((w) => w.isNotEmpty)
            .length;
    return (words / 200).ceil().clamp(1, 99);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final theme = Theme.of(context).textTheme;
    final link = widget.link;

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
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _pressed ? c.surfaceElevated : c.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _pressed ? c.accentBorder : c.border,
                width: _pressed ? 1.0 : 0.5,
              ),
              boxShadow: _pressed
                  ? []
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 8,
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
                      color: link.isRead ? c.border : c.accent,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Favicon + title + bookmark
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: c.surfaceElevated,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                        color: c.borderSoft, width: 0.5),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(7),
                                    child: CachedNetworkImage(
                                      imageUrl: link.favicon ?? '',
                                      fit: BoxFit.cover,
                                      errorWidget: (ctx, url, e) => Icon(
                                        Icons.link_rounded,
                                        size: 14,
                                        color: c.textHint,
                                      ),
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
                                            color: c.surface, width: 1.5),
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
                                padding: const EdgeInsets.only(top: 1),
                                child: Icon(Icons.bookmark_rounded,
                                    size: 13, color: c.amber),
                              ),
                            ],
                          ],
                        ),

                        const SizedBox(height: 8),

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
                                    color: c.textHint, fontSize: 11),
                              ),
                            ),
                            if (link.tags.isNotEmpty) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: c.accentDim,
                                  borderRadius: BorderRadius.circular(5),
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

                        // Description
                        if ((link.description ?? '').isNotEmpty) ...[
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

                        const SizedBox(height: 10),

                        // Footer
                        Row(
                          children: [
                            Icon(Icons.calendar_today_outlined,
                                size: 10, color: c.textHint),
                            const SizedBox(width: 3),
                            Text(
                              DateFormat.MMMd().format(link.createdAt),
                              style: theme.bodySmall!
                                  .copyWith(color: c.textHint, fontSize: 10),
                            ),
                            const SizedBox(width: 8),
                            Icon(Icons.schedule_rounded,
                                size: 10, color: c.textHint),
                            const SizedBox(width: 3),
                            Text(
                              '$_readTime min',
                              style: theme.bodySmall!
                                  .copyWith(color: c.textHint, fontSize: 10),
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
                                  borderRadius: BorderRadius.circular(7),
                                  border: Border.all(
                                      color: c.border, width: 0.5),
                                ),
                                child: Icon(Icons.more_horiz_rounded,
                                    size: 14, color: c.textSecondary),
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
                        height: 76,
                        width: 76,
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

// ── CompactRow ────────────────────────────────────────────────────────────────

class CompactRow extends ConsumerStatefulWidget {
  final LinkModel link;
  final VoidCallback onTap;

  const CompactRow({super.key, required this.link, required this.onTap});

  @override
  ConsumerState<CompactRow> createState() => _CompactRowState();
}

class _CompactRowState extends ConsumerState<CompactRow> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final theme = Theme.of(context).textTheme;
    final link = widget.link;

    return Listener(
      onPointerDown: (_) => setState(() => _pressed = true),
      onPointerUp: (_) => setState(() => _pressed = false),
      onPointerCancel: (_) => setState(() => _pressed = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
          color: _pressed ? c.surfaceElevated : Colors.transparent,
          child: Row(
            children: [
              // Favicon with unread dot
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: c.surfaceElevated,
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: CachedNetworkImage(
                        imageUrl: link.favicon ?? '',
                        fit: BoxFit.cover,
                        errorWidget: (ctx, url, e) =>
                            Icon(Icons.link_rounded, size: 12, color: c.textHint),
                      ),
                    ),
                  ),
                  if (!link.isRead)
                    Positioned(
                      top: -2,
                      right: -2,
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: c.accent,
                          shape: BoxShape.circle,
                          border:
                              Border.all(color: c.background, width: 1.5),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 10),

              // Title
              Expanded(
                child: Text(
                  link.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.bodyMedium!.copyWith(
                    color:
                        link.isRead ? c.textSecondary : c.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              // Date + bookmark
              if (link.isFavorite)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Icon(Icons.bookmark_rounded,
                      size: 12, color: c.amber),
                ),
              Text(
                DateFormat.MMMd().format(link.createdAt),
                style: theme.bodySmall!
                    .copyWith(color: c.textHint, fontSize: 11),
              ),
              const SizedBox(width: 4),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => showLinkOptions(context, ref, link),
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Icon(Icons.more_horiz_rounded,
                      size: 16, color: c.textSecondary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


// ── LinkSkeletonCard ──────────────────────────────────────────────────────────────

class LinkSkeletonCard extends StatelessWidget {
  final dynamic c;

  const LinkSkeletonCard({super.key, required this.c});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.border, width: 0.5),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Bone(width: 3, height: double.infinity, radius: 2, c: c),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _Bone(width: 32, height: 32, radius: 8, c: c),
                      const SizedBox(width: 10),
                      Expanded(
                          child: _Bone(
                              width: double.infinity, height: 13, radius: 4, c: c)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _Bone(width: 120, height: 10, radius: 4, c: c),
                  const SizedBox(height: 8),
                  _Bone(width: double.infinity, height: 10, radius: 4, c: c),
                  const SizedBox(height: 4),
                  _Bone(width: 180, height: 10, radius: 4, c: c),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Bone extends StatelessWidget {
  final double width, height, radius;
  final dynamic c;

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

