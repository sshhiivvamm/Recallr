// import 'package:flutter/material.dart';
// import 'package:recallr/common/widgets.dart';
// import '../../../theme/controller/theme_controller.dart';
// import '../../../theme/recallr_colors.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:intl/intl.dart';
//
// import '../../../theme/ui_helpers.dart';
// import '../../repositrories/link_providers/recent_links_provider.dart';
//
// class RecallrHome extends ConsumerWidget {
//   const RecallrHome({super.key});
//
//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final c = context.colors;
//     final theme = Theme.of(context).textTheme;
//     final themeMode = ref.watch(themeProvider);
//
//     return Scaffold(
//       backgroundColor: c.background,
//       appBar: AppBar(
//         title: Text(
//           "RECALLR",
//           style: Theme.of(context).textTheme.headlineLarge!,
//         ),
//         actions: [
//           IconButton(
//             onPressed: () {
//               ref.read(themeProvider.notifier).toggleTheme();
//             },
//             icon: Icon(
//               themeMode == ThemeMode.dark ? Icons.light_mode : Icons.dark_mode,
//             ),
//           ),
//         ],
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: () => ReWid.openSaveSheet(context),
//         child: Icon(Icons.add),
//       ),
//       body: Padding(
//         padding: EdgeInsets.all(12),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Text("TEST FONT", style: Theme
//             //     .of(context)
//             //     .textTheme
//             //     .displayLarge),
//             //
//             Text(
//               "THE KINETIC ARCHITECT",
//               style: Theme.of(context).textTheme.bodyLarge!.copyWith(
//                 color: c.accent.withOpacity(0.98),
//                 fontWeight: FontWeight.w800,
//                 letterSpacing: 2.90,
//               ),
//             ),
//             Text(
//               "Your Mind,",
//               style: Theme.of(context).textTheme.displayLarge!.copyWith(
//                 fontSize: 46,
//                 fontWeight: FontWeight.w900,
//                 letterSpacing: 2.90,
//               ),
//             ),
//             Text(
//               "Engineered.",
//               style: Theme.of(context).textTheme.displayLarge!.copyWith(
//                 color: c.accent,
//                 fontSize: 46,
//                 fontWeight: FontWeight.w900,
//                 letterSpacing: 2.90,
//               ),
//             ),
//
//             SizedBox(height: 250),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Text("Recent Saves", style: theme.displayLarge!.copyWith()),
//                 Text(
//                   "View All > ",
//                   style: theme.titleMedium!.copyWith(color: c.accent),
//                 ),
//               ],
//             ),
//             Consumer(
//               builder: (context, ref, _) {
//                 final asyncLinks = ref.watch(recentLinksStreamProvider);
//
//                 return asyncLinks.when(
//                   data: (links) {
//                     if (links.isEmpty) {
//                       return const Text("No recent saves");
//                     }
//
//                     return Expanded(
//                       child: ListView.builder(
//                         itemCount: links.length,
//                         itemBuilder: (context, index) {
//                           final link = links[index];
//
//                           return Container(
//                             margin: const EdgeInsets.only(bottom: 12),
//                             padding: const EdgeInsets.all(12),
//                             decoration: BoxDecoration(
//                               color: c.surface,
//                               borderRadius: BorderRadius.circular(14),
//                               border: Border.all(color: c.border),
//                             ),
//                             child: Row(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 // 🔹 ICON CONTAINER (FIXED)
//                                 Container(
//                                   height: 40,
//                                   width: 40,
//                                   decoration: BoxDecoration(
//                                     color: c.surfaceElevated,
//                                     borderRadius: BorderRadius.circular(10),
//                                     border: Border.all(color: c.borderSoft),
//                                   ),
//                                   alignment: Alignment.center,
//                                   child: ClipRRect(
//                                     borderRadius: BorderRadius.circular(6),
//                                     child: Image.network(
//                                       link.favicon ?? "",
//                                       height: 18,
//                                       width: 18,
//                                       fit: BoxFit.cover,
//                                       errorBuilder: (_, __, ___) => Icon(
//                                         Icons.link,
//                                         size: 18,
//                                         color: c.textSecondary,
//                                       ),
//                                     ),
//                                   ),
//                                 ),
//
//                                 const SizedBox(width: 12),
//
//                                 // 🔹 CONTENT
//                                 Expanded(
//                                   child: Column(
//                                     crossAxisAlignment:
//                                         CrossAxisAlignment.start,
//                                     children: [
//                                       // 🔹 TITLE + TAG
//                                       Row(
//                                         crossAxisAlignment:
//                                             CrossAxisAlignment.start,
//                                         children: [
//                                           Expanded(
//                                             child: Text(
//                                               link.title,
//                                               maxLines: 2,
//                                               overflow: TextOverflow.ellipsis,
//                                               style: theme.titleMedium!.copyWith(
//                                                 color: c.textPrimary,
//                                                 fontWeight: FontWeight.w600,
//                                                 height:
//                                                     1.3, // 🔥 improves readability
//                                               ),
//                                             ),
//                                           ),
//
//                                           if (link.tags.isNotEmpty) ...[
//                                             const SizedBox(width: 6),
//                                             Container(
//                                               padding:
//                                                   const EdgeInsets.symmetric(
//                                                     horizontal: 8,
//                                                     vertical: 3,
//                                                   ),
//                                               decoration: BoxDecoration(
//                                                 color: c.surfaceElevated,
//                                                 borderRadius:
//                                                     BorderRadius.circular(20),
//                                                 border: Border.all(
//                                                   color: c.borderSoft,
//                                                 ),
//                                               ),
//                                               child: Text(
//                                                 link.tags.first.name
//                                                     .toUpperCase(),
//                                                 style: theme.bodySmall!
//                                                     .copyWith(
//                                                       color: c.textSecondary,
//                                                       fontSize: 9,
//                                                       fontWeight:
//                                                           FontWeight.w600,
//                                                       letterSpacing: 0.6,
//                                                     ),
//                                               ),
//                                             ),
//                                           ],
//                                         ],
//                                       ),
//
//                                       const SizedBox(height: 6),
//
//                                       // 🔹 DOMAIN (subtle)
//                                       Text(
//                                         link.domain ?? "",
//                                         style: theme.bodySmall!.copyWith(
//                                           color: c.textHint,
//                                           fontSize: 11,
//                                         ),
//                                       ),
//
//                                       // 🔹 DESCRIPTION (clean spacing)
//                                       if ((link.description ?? "")
//                                           .isNotEmpty) ...[
//                                         const SizedBox(height: 4),
//                                         Text(
//                                           link.description!,
//                                           maxLines: 2,
//                                           overflow: TextOverflow.ellipsis,
//                                           style: theme.bodySmall!.copyWith(
//                                             color: c.textSecondary,
//                                             height: 1.4,
//                                           ),
//                                         ),
//                                       ],
//
//                                       const SizedBox(height: 10),
//
//                                       // 🔹 FOOTER
//                                       Row(
//                                         children: [
//                                           Icon(
//                                             Icons.calendar_today,
//                                             size: 13,
//                                             color: c.textHint,
//                                           ),
//                                           const SizedBox(width: 6),
//                                           Text(
//                                             DateFormat.yMMMd().format(
//                                               link.createdAt,
//                                             ),
//                                             style: theme.bodySmall!.copyWith(
//                                               color: c.textHint,
//                                               fontSize: 11,
//                                             ),
//                                           ),
//
//                                           const Spacer(),
//
//                                           Icon(
//                                             Icons.more_vert,
//                                             size: 18,
//                                             color: c.textSecondary,
//                                           ),
//                                         ],
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//
//                                 // 🔹 THUMBNAIL (FIXED ALIGNMENT)
//                                 if (link.thumbnail != null &&
//                                     link.thumbnail!.isNotEmpty)
//                                   Padding(
//                                     padding: const EdgeInsets.only(left: 10),
//                                     child: ClipRRect(
//                                       borderRadius: BorderRadius.circular(10),
//                                       child: Container(
//                                         height: 64,
//                                         width: 64,
//                                         decoration: BoxDecoration(
//                                           border: Border.all(
//                                             color: c.borderSoft,
//                                           ),
//                                           borderRadius: BorderRadius.circular(
//                                             10,
//                                           ),
//                                         ),
//                                         child: Image.network(
//                                           link.thumbnail!,
//                                           fit: BoxFit.cover,
//                                           errorBuilder: (_, __, ___) =>
//                                               const SizedBox(),
//                                         ),
//                                       ),
//                                     ),
//                                   ),
//                               ],
//                             ),
//                           );
//
//                           // return Container(
//                           //   margin: const EdgeInsets.only(bottom: 14),
//                           //   padding: const EdgeInsets.all(12),
//                           //   decoration: BoxDecoration(
//                           //     color: c.surface,
//                           //     borderRadius: BorderRadius.circular(16),
//                           //     border: Border.all(color: c.border),
//                           //   ),
//                           //   child: Row(
//                           //     crossAxisAlignment: CrossAxisAlignment.start,
//                           //     children: [
//                           //       // 🔹 LEFT ICON BOX
//                           //       ClipRRect(
//                           //         borderRadius: BorderRadius.circular(6),
//                           //         child: Image.network(
//                           //           link.favicon ?? "",
//                           //           height: 20,
//                           //           width: 20,
//                           //           fit: BoxFit.cover,
//                           //           errorBuilder: (_, __, ___) => Icon(
//                           //             Icons.link,
//                           //             color: c.textSecondary,
//                           //             size: 20,
//                           //           ),
//                           //         ),
//                           //       ),
//                           //
//                           //       const SizedBox(width: 12),
//                           //
//                           //       // 🔹 RIGHT CONTENT
//                           //       Expanded(
//                           //         child: Column(
//                           //           crossAxisAlignment:
//                           //               CrossAxisAlignment.start,
//                           //           children: [
//                           //             // 🔹 TITLE + TAG
//                           //             Row(
//                           //               crossAxisAlignment:
//                           //                   CrossAxisAlignment.start,
//                           //               children: [
//                           //                 Expanded(
//                           //                   child: Text(
//                           //                     link.title ?? "",
//                           //                     maxLines: 2,
//                           //                     overflow: TextOverflow.ellipsis,
//                           //                     style: theme.titleMedium!
//                           //                         .copyWith(
//                           //                           color: c.textPrimary,
//                           //                           fontWeight: FontWeight.w600,
//                           //                         ),
//                           //                   ),
//                           //                 ),
//                           //
//                           //                 const SizedBox(width: 8),
//                           //
//                           //                 // 🔹 TAG (NOT CHIP)
//                           //                 if (link.tags.isNotEmpty)
//                           //                   Container(
//                           //                     padding:
//                           //                         const EdgeInsets.symmetric(
//                           //                           horizontal: 8,
//                           //                           vertical: 4,
//                           //                         ),
//                           //                     decoration: BoxDecoration(
//                           //                       color: c.surfaceElevated,
//                           //                       borderRadius:
//                           //                           BorderRadius.circular(20),
//                           //                     ),
//                           //                     child: Text(
//                           //                       link.tags.first.name
//                           //                           .toUpperCase(),
//                           //                       style: theme.bodySmall!
//                           //                           .copyWith(
//                           //                             color: c.textSecondary,
//                           //                             fontSize: 10,
//                           //                             fontWeight:
//                           //                                 FontWeight.w600,
//                           //                             letterSpacing: 0.5,
//                           //                           ),
//                           //                     ),
//                           //                   ),
//                           //               ],
//                           //             ),
//                           //             const SizedBox(height: 10),
//                           //             Text(
//                           //               link.domain ?? "",
//                           //               style: theme.bodySmall!.copyWith(
//                           //                 color: c.textHint,
//                           //                 fontSize: 11,
//                           //               ),
//                           //             ),
//                           //
//                           //             const SizedBox(height: 10),
//                           //             if ((link.description ?? "").isNotEmpty)
//                           //               Padding(
//                           //                 padding: const EdgeInsets.only(
//                           //                   top: 4,
//                           //                 ),
//                           //                 child: Text(
//                           //                   link.description!,
//                           //                   maxLines: 2,
//                           //                   overflow: TextOverflow.ellipsis,
//                           //                   style: theme.bodySmall!.copyWith(
//                           //                     color: c.textSecondary,
//                           //                     fontSize: 12,
//                           //                   ),
//                           //                 ),
//                           //               ),
//                           //
//                           //             Row(
//                           //               children: [
//                           //                 Icon(
//                           //                   Icons.calendar_today,
//                           //                   size: 14,
//                           //                   color: c.textHint,
//                           //                 ),
//                           //                 const SizedBox(width: 6),
//                           //                 Text(
//                           //                   DateFormat.yMMMd().format(
//                           //                     link.createdAt,
//                           //                   ),
//                           //                   style: theme.bodySmall!.copyWith(
//                           //                     color: c.textHint,
//                           //                   ),
//                           //                 ),
//                           //
//                           //                 const Spacer(),
//                           //
//                           //                 Icon(
//                           //                   Icons.more_vert,
//                           //                   size: 18,
//                           //                   color: c.textSecondary,
//                           //                 ),
//                           //               ],
//                           //             ),
//                           //           ],
//                           //         ),
//                           //       ),
//                           //       if (link.thumbnail != null &&
//                           //           link.thumbnail!.isNotEmpty)
//                           //         Padding(
//                           //           padding: const EdgeInsets.only(left: 10),
//                           //           child: ClipRRect(
//                           //             borderRadius: BorderRadius.circular(10),
//                           //             child: Image.network(
//                           //               link.thumbnail!,
//                           //               height: 60,
//                           //               width: 60,
//                           //               fit: BoxFit.cover,
//                           //               errorBuilder: (_, __, ___) =>
//                           //                   const SizedBox(),
//                           //             ),
//                           //           ),
//                           //         ),
//                           //     ],
//                           //   ),
//                           // );
//                           //
//                         },
//                       ),
//                     );
//                   },
//                   loading: () => const CircularProgressIndicator(),
//                   error: (e, _) => Text("Error: $e"),
//                 );
//               },
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:recallr/common/sheet_fab.dart';
import 'package:recallr/common/widgets.dart';
import '../../../theme/controller/theme_controller.dart';
import '../../../theme/recallr_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../repositrories/link_providers/recent_links_provider.dart';
import '../../repositrories/link_providers/link_repository_provider.dart';
import '../category/tag_list_provider.dart';

final _discoverDismissedProvider = StateProvider<bool>((ref) => false);

class RecallrHome extends ConsumerWidget {
  const RecallrHome({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final theme = Theme.of(context).textTheme;
    final themeMode = ref.watch(themeProvider);

    return SheetFabHost(
      heroTag: 'home_fab',
      openSheet: (ctx, {required onSheetTopY, required onSheetAnimation}) =>
          ReWid.openSaveSheet(
            ctx,
            onSheetTopY: onSheetTopY,
            onSheetAnimation: onSheetAnimation,
          ),
      child: Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        backgroundColor: c.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text('RECALLR', style: theme.headlineLarge),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: c.surfaceElevated,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: c.border, width: 0.5),
            ),
            child: IconButton(
              onPressed: () {
                ref.read(themeProvider.notifier).toggleTheme();
              },
              icon: Icon(
                themeMode == ThemeMode.dark
                    ? Icons.light_mode_outlined
                    : Icons.dark_mode_outlined,
                size: 18,
                color: c.textSecondary,
              ),
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),

            // ── Hero header ──────────────────────────────────────
            _HeroHeader(c: c, theme: theme),

            const SizedBox(height: 24),

            // ── Discover Mode card ───────────────────────────────
            Consumer(
              builder: (context, ref, _) {
                final dismissed = ref.watch(_discoverDismissedProvider);
                if (dismissed) return const SizedBox.shrink();
                final discoverAsync = ref.watch(discoverLinkProvider);
                return discoverAsync.maybeWhen(
                  data: (link) {
                    if (link == null) return const SizedBox.shrink();
                    return _DiscoverCard(link: link, c: c, theme: theme);
                  },
                  orElse: () => const SizedBox.shrink(),
                );
              },
            ),

            const SizedBox(height: 8),

            // ── Section header ───────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Recent Saves',
                  style: theme.titleLarge!.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    context.go('/all-links');
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: c.border, width: 0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'View All',
                          style: theme.labelMedium!.copyWith(
                            color: c.accent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.arrow_forward, size: 12, color: c.accent),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // ── Links list ───────────────────────────────────────
            Consumer(
              builder: (context, ref, _) {
                final asyncLinks = ref.watch(recentLinksStreamProvider);

                return asyncLinks.when(
                  data: (links) {
                    if (links.isEmpty) {
                      return _EmptyState(c: c, theme: theme);
                    }

                    return Expanded(
                      child: ListView.separated(
                        itemCount: links.length,
                        separatorBuilder: (ctx, i) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final link = links[index];
                          return _LinkCard(link: link, c: c, theme: theme);
                        },
                      ),
                    );
                  },
                  loading: () => Expanded(
                    child: ListView.separated(
                      itemCount: 4,
                      separatorBuilder: (ctx, i) => const SizedBox(height: 10),
                      itemBuilder: (_, i) => _SkeletonCard(c: c),
                    ),
                  ),
                  error: (e, _) =>
                      _ErrorState(c: c, theme: theme, error: e.toString()),
                );
              },
            ),
          ],
        ),
      ),
      ),
    );
  }
}

// ── Discover Card ────────────────────────────────────────────────────────────

class _DiscoverCard extends ConsumerWidget {
  final dynamic link;
  final dynamic c;
  final TextTheme theme;

  const _DiscoverCard({required this.link, required this.c, required this.theme});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            c.accent.withValues(alpha: 0.08),
            c.purple.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.accentBorder, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: c.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome_rounded, size: 10, color: c.accent),
                    const SizedBox(width: 4),
                    Text(
                      'REMEMBER THIS?',
                      style: theme.labelSmall!.copyWith(
                        color: c.accent,
                        fontWeight: FontWeight.w700,
                        fontSize: 9,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => ref.read(_discoverDismissedProvider.notifier).state = true,
                child: Icon(Icons.close_rounded, size: 16, color: c.textHint),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              if (link.favicon != null)
                Container(
                  width: 28,
                  height: 28,
                  margin: const EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    color: c.surfaceElevated,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.network(
                      link.favicon,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          Icon(Icons.link, size: 14, color: c.textHint),
                    ),
                  ),
                ),
              Expanded(
                child: Text(
                  link.title ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.titleSmall!.copyWith(
                    fontWeight: FontWeight.w600,
                    color: c.textPrimary,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            link.domain ?? '',
            style: theme.bodySmall!.copyWith(color: c.textHint, fontSize: 11),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final url = link.url as String;
                    final uri = Uri.parse(url.startsWith('http') ? url : 'https://$url');
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                    ref.read(linkRepositoryProvider).updateLastOpened(link.id as int);
                    ref.read(_discoverDismissedProvider.notifier).state = true;
                  },
                  icon: Icon(Icons.open_in_new_rounded, size: 14, color: c.accent),
                  label: Text('Open', style: TextStyle(color: c.accent, fontSize: 13)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    side: BorderSide(color: c.accentBorder, width: 0.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Hero Header ─────────────────────────────────────────────────────────────

class _HeroHeader extends ConsumerWidget {
  final dynamic c;
  final TextTheme theme;

  const _HeroHeader({required this.c, required this.theme});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalLinks = ref.watch(totalLinksCountProvider);
    final thisWeekLinks = ref.watch(thisWeekLinksCountProvider);
    final tags = ref.watch(tagListProvider);

    final savedValue = totalLinks.maybeWhen(data: (n) => '$n', orElse: () => '—');
    final tagsValue = tags.maybeWhen(data: (t) => '${t.length}', orElse: () => '—');
    final weekValue = thisWeekLinks.maybeWhen(data: (n) => '$n', orElse: () => '—');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: c.border, width: 0.5),
            borderRadius: BorderRadius.circular(20),
            color: c.surfaceElevated,
          ),
          child: Text(
            'THE KINETIC ARCHITECT',
            style: theme.labelSmall!.copyWith(
              color: c.accent,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.8,
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Main heading
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'Your Mind,\n',
                style: theme.displayLarge!.copyWith(
                  fontSize: 42,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                  height: 1.1,
                  color: c.textPrimary,
                ),
              ),
              TextSpan(
                text: 'Engineered.',
                style: theme.displayLarge!.copyWith(
                  fontSize: 42,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                  height: 1.1,
                  color: c.accent,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Stats row
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: c.border, width: 0.5),
          ),
          child: Row(
            children: [
              _StatItem(label: 'Saved', value: savedValue, c: c, theme: theme),
              _Divider(c: c),
              _StatItem(label: 'Tags', value: tagsValue, c: c, theme: theme),
              _Divider(c: c),
              _StatItem(label: 'This week', value: weekValue, c: c, theme: theme),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label, value;
  final dynamic c;
  final TextTheme theme;

  const _StatItem({
    required this.label,
    required this.value,
    required this.c,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: theme.titleLarge!.copyWith(
              fontWeight: FontWeight.w700,
              color: c.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: theme.labelSmall!.copyWith(color: c.textHint)),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  final dynamic c;

  const _Divider({required this.c});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 0.5,
      height: 28,
      color: c.border,
      margin: const EdgeInsets.symmetric(horizontal: 8),
    );
  }
}

// ── Link Card ────────────────────────────────────────────────────────────────

class _LinkCard extends StatelessWidget {
  final dynamic link;
  final dynamic c;
  final TextTheme theme;

  const _LinkCard({required this.link, required this.c, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: c.surface,
      borderRadius: BorderRadius.circular(14),

      child: InkWell(
        splashColor: c.accent.withOpacity(0.1),
        highlightColor: c.accent.withOpacity(0.05),
        onTap: () async {
          final rawUrl = link.url;

          if (rawUrl == null || rawUrl.isEmpty) {
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Invalid URL")),
            );
            return;
          }

          final uri = Uri.parse(
            rawUrl.startsWith('http') ? rawUrl : 'https://$rawUrl',
          );

          try {
            final success = await launchUrl(
              uri,
              mode: LaunchMode.externalApplication,
            );

            if (!success) throw 'Could not launch';
          } catch (e) {
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Cannot open the link")),
            );
          }
        },
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: c.border, width: 0.5),
          ),
          child: Ink(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: c.border, width: 0.5),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Favicon + domain col ────────────
                Column(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: c.surfaceElevated,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: c.borderSoft, width: 0.5),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(7),
                        child: Image.network(
                          link.favicon ?? '',
                          height: 34,
                          width: 34,
                          fit: BoxFit.cover,
                          errorBuilder: (_, e, s) => Icon(
                            Icons.link_rounded,
                            color: c.textHint,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(width: 12),

                // ── Content ─────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title + tag row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              link.title ?? '',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.titleSmall!.copyWith(
                                fontWeight: FontWeight.w600,
                                color: c.textPrimary,
                                height: 1.35,
                              ),
                            ),
                          ),
                          if (link.tags.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: c.accentDim,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                link.tags.first.name.toUpperCase(),
                                style: theme.labelSmall!.copyWith(
                                  color: c.accent,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),

                      const SizedBox(height: 6),

                      // Domain
                      Row(
                        children: [
                          Icon(
                            Icons.language_rounded,
                            size: 11,
                            color: c.textHint,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            link.domain ?? '',
                            style: theme.bodySmall!.copyWith(
                              color: c.textHint,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),

                      // Description
                      if ((link.description ?? '').isNotEmpty) ...[
                        const SizedBox(height: 6),
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

                      const SizedBox(height: 8),

                      // Footer
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 11,
                            color: c.textHint,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat.yMMMd().format(link.createdAt),
                            style: theme.bodySmall!.copyWith(
                              color: c.textHint,
                              fontSize: 11,
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            Icons.more_horiz_rounded,
                            size: 16,
                            color: c.textSecondary,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ── Thumbnail ───────────────────────
                if (link.thumbnail != null && link.thumbnail!.isNotEmpty) ...[
                  const SizedBox(width: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      link.thumbnail!,
                      height: 64,
                      width: 64,
                      fit: BoxFit.cover,
                      errorBuilder: (_, e, s) => const SizedBox(),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Empty State ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final dynamic c;
  final TextTheme theme;

  const _EmptyState({required this.c, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: c.surfaceElevated,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: c.border, width: 0.5),
              ),
              child: Icon(
                Icons.bookmark_border_rounded,
                color: c.textHint,
                size: 24,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Nothing saved yet',
              style: theme.titleSmall!.copyWith(
                fontWeight: FontWeight.w600,
                color: c.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tap + to save your first link',
              style: theme.bodySmall!.copyWith(color: c.textHint),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Error State ──────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  final dynamic c;
  final TextTheme theme;
  final String error;

  const _ErrorState({
    required this.c,
    required this.theme,
    required this.error,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded, color: c.textHint, size: 32),
            const SizedBox(height: 12),
            Text(
              'Could not load saves',
              style: theme.titleSmall!.copyWith(color: c.textPrimary),
            ),
            const SizedBox(height: 4),
            Text(
              error,
              style: theme.bodySmall!.copyWith(color: c.textHint),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Skeleton Card ────────────────────────────────────────────────────────────

class _SkeletonCard extends StatelessWidget {
  final dynamic c;

  const _SkeletonCard({required this.c});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.border, width: 0.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Bone(width: 34, height: 34, radius: 8, c: c),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Bone(width: double.infinity, height: 13, radius: 4, c: c),
                const SizedBox(height: 6),
                _Bone(width: 120, height: 10, radius: 4, c: c),
                const SizedBox(height: 10),
                _Bone(width: double.infinity, height: 10, radius: 4, c: c),
                const SizedBox(height: 4),
                _Bone(width: 160, height: 10, radius: 4, c: c),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Bone (skeleton) ───────────────────────────────────────────────────────────

class _Bone extends StatelessWidget {
  final double width, height, radius;
  final dynamic c;

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
