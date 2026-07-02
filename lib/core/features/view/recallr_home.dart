import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:go_router/go_router.dart';
import 'package:recallr/common/link_options_sheet.dart';
import 'package:recallr/common/sheet_fab.dart';
import 'package:recallr/common/widgets.dart';
import 'package:recallr/data/models/Link/link_model.dart';
import '../../../theme/recallr_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../notifications/notification_providers.dart';
import '../../repositrories/link_providers/link_repository_provider.dart';
import '../../repositrories/link_providers/recent_links_provider.dart';

final _nextReadDismissedProvider = StateProvider<bool>((ref) => false);

final _discoverDismissedProvider = StateProvider<bool>((ref) => false);

// ── Helpers ───────────────────────────────────────────────────────────────────


// ── Word-cycle animation helpers ──────────────────────────────────────────────

const _heroWords = [
  'Engineered.',
  'Organized.',
  'Curated.',
  'Amplified.',
  'Supercharged.',
];

Widget _wordSlideTransition(Widget child, Animation<double> animation) {
  // Exiting word slides UP and out; entering word slides UP from below.
  final isExiting = animation.status == AnimationStatus.reverse ||
      animation.status == AnimationStatus.dismissed;
  final slide = isExiting
      ? Tween<Offset>(begin: const Offset(0, -1.0), end: Offset.zero)
          .animate(CurvedAnimation(parent: animation, curve: Curves.easeInCubic))
      : Tween<Offset>(begin: const Offset(0, 1.0), end: Offset.zero)
          .animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));
  return SlideTransition(
    position: slide,
    child: FadeTransition(opacity: animation, child: child),
  );
}

// ── Screen ────────────────────────────────────────────────────────────────────

class RecallrHome extends ConsumerStatefulWidget {
  const RecallrHome({super.key});

  @override
  ConsumerState<RecallrHome> createState() => _RecallrHomeState();
}

class _RecallrHomeState extends ConsumerState<RecallrHome> {
  final _ctrl = ScrollController();
  int _wordIdx = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 2500), (_) {
      if (mounted) setState(() => _wordIdx = (_wordIdx + 1) % _heroWords.length);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

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
        body: SafeArea(
          bottom: false,
          child: Consumer(
            builder: (context, ref, _) {
              final asyncLinks = ref.watch(recentLinksStreamProvider);

              return ColoredBox(
                color: c.background,
                child: CustomScrollView(
                controller: _ctrl,
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                cacheExtent: 300,
                slivers: [
                  // ── Pinned top bar ───────────────────────────────
                  SliverAppBar(
                    pinned: true,
                    floating: false,
                    backgroundColor: c.background,
                    surfaceTintColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    elevation: 0,
                    automaticallyImplyLeading: false,
                    toolbarHeight: 52,
                    titleSpacing: 16,
                    title: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: c.accentDim,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: c.accentBorder, width: 0.5),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  gradient: AppColors.brandGradient,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'RECALLR',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall!
                                    .copyWith(
                                  color: c.accent,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.6,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => context.push('/notifications'),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: c.surface,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: c.border, width: 0.5),
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Icon(Icons.notifications_outlined,
                                    size: 18, color: c.textSecondary),
                                if (ref.watch(notifEnabledProvider) ||
                                    (ref.watch(reviewDueCountProvider).valueOrNull ?? 0) > 0)
                                  Positioned(
                                    top: 7,
                                    right: 7,
                                    child: Container(
                                      width: 7,
                                      height: 7,
                                      decoration: BoxDecoration(
                                        color: c.amber,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: c.surface, width: 1.5),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Hero title: shrinks and sticks on scroll ─────
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _HeroTitleDelegate(wordIdx: _wordIdx, c: c),
                  ),

                  // ── Hero stats ──────────────────────────────────
                  SliverToBoxAdapter(
                    child: _HeroSection(c: c),
                  ),

                  // ── Spotlight carousel ───────────────────────────
                  const SliverToBoxAdapter(
                    child: _SpotlightCarousel(),
                  ),

                  // ── Recent saves header (sticky) ─────────────────
                  SliverAppBar(
                    pinned: true,
                    floating: false,
                    backgroundColor: c.background,
                    surfaceTintColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    elevation: 0,
                    automaticallyImplyLeading: false,
                    toolbarHeight: 52,
                    titleSpacing: 16,
                    title: Row(
                      children: [
                        Text(
                          'Recent Saves',
                          style: Theme.of(context).textTheme.titleLarge!.copyWith(
                                fontWeight: FontWeight.w700,
                                color: c.textPrimary,
                              ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => context.go('/all-links'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              border: Border.all(color: c.border, width: 0.5),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'View All',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelMedium!
                                      .copyWith(
                                        color: c.accent,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                                const SizedBox(width: 4),
                                Icon(Icons.arrow_forward_rounded,
                                    size: 12, color: c.accent),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Link list ────────────────────────────────────
                  asyncLinks.when(
                    data: (links) {
                      if (links.isEmpty) {
                        return SliverToBoxAdapter(
                          child: _EmptyState(c: c),
                        );
                      }
                      return SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            addAutomaticKeepAlives: false,
                            (context, index) {
                              final link = links[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Dismissible(
                                  key: ValueKey('swipe-${link.id}'),
                                  direction: DismissDirection.startToEnd,
                                  confirmDismiss: (_) async {
                                    await ref
                                        .read(linkRepositoryProvider)
                                        .toggleFavorite(link.id);
                                    return false;
                                  },
                                  background: Container(
                                    decoration: BoxDecoration(
                                      color: c.amberDim,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: c.amber.withValues(alpha: 0.3),
                                        width: 0.5,
                                      ),
                                    ),
                                    alignment: Alignment.centerLeft,
                                    padding:
                                        const EdgeInsets.only(left: 20),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          link.isFavorite
                                              ? Icons.bookmark_remove_rounded
                                              : Icons.bookmark_add_rounded,
                                          color: c.amber,
                                          size: 22,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          link.isFavorite
                                              ? 'Remove'
                                              : 'Favorite',
                                          style: TextStyle(
                                            color: c.amber,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  child: _LinkCard(link: link),
                                ),
                              );
                            },
                            childCount: links.length,
                          ),
                        ),
                      );
                    },
                    loading: () => SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (_, i) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _SkeletonCard(c: c),
                          ),
                          childCount: 4,
                        ),
                      ),
                    ),
                    error: (e, _) => SliverToBoxAdapter(
                      child: _ErrorState(c: c, error: e.toString()),
                    ),
                  ),
                ],
              ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// ── Hero Section ──────────────────────────────────────────────────────────────

class _HeroSection extends ConsumerWidget {
  final AppColorScheme c;
  const _HeroSection({required this.c});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalLinks = ref.watch(totalLinksCountProvider);
    final thisWeekLinks = ref.watch(thisWeekLinksCountProvider);
    final streakAsync = ref.watch(readingStreakProvider);

    final savedValue =
        totalLinks.maybeWhen(data: (n) => '$n', orElse: () => '—');
    final weekValue =
        thisWeekLinks.maybeWhen(data: (n) => '$n', orElse: () => '—');
    final streakValue =
        streakAsync.maybeWhen(data: (n) => '$n', orElse: () => '—');

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          top: -50,
          right: -70,
          child: _GlowOrb(color: c.accent, size: 280),
        ),
        Positioned(
          top: 60,
          right: 40,
          child: _GlowOrb(color: c.purple, size: 120),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _StatTile(
                    value: savedValue,
                    label: 'Saved',
                    accent: c.accent,
                    dimColor: c.accentDim,
                    icon: Icons.bookmark_rounded,
                    c: c,
                  ),
                  const SizedBox(width: 10),
                  _StatTile(
                    value: weekValue,
                    label: 'This week',
                    accent: c.green,
                    dimColor: c.greenDim,
                    icon: Icons.trending_up_rounded,
                    c: c,
                  ),
                  const SizedBox(width: 10),
                  _StatTile(
                    value: streakValue,
                    label: 'Streak',
                    accent: c.amber,
                    dimColor: c.amberDim,
                    icon: Icons.local_fire_department_rounded,
                    c: c,
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Hero Title Delegate ───────────────────────────────────────────────────────

class _HeroTitleDelegate extends SliverPersistentHeaderDelegate {
  final int wordIdx;
  final AppColorScheme c;

  const _HeroTitleDelegate({required this.wordIdx, required this.c});

  @override
  double get minExtent => 50.0;

  @override
  double get maxExtent => 118.0;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final t = (shrinkOffset / (maxExtent - minExtent)).clamp(0.0, 1.0);
    final expandedOpacity = (1.0 - t * 2.2).clamp(0.0, 1.0);
    final collapsedOpacity = ((t - 0.55) / 0.45).clamp(0.0, 1.0);
    final theme = Theme.of(context).textTheme;

    final expandedTextStyle = theme.displayLarge!.copyWith(
      fontSize: 38,
      fontWeight: FontWeight.w900,
      letterSpacing: -0.8,
      height: 1.1,
      color: c.textPrimary,
    );
    final collapsedTextStyle = theme.displayLarge!.copyWith(
      fontSize: 22,
      fontWeight: FontWeight.w900,
      letterSpacing: -0.6,
      height: 1.15,
      color: c.textPrimary,
    );

    return ColoredBox(
      color: c.background,
      child: Stack(
        children: [
          // Two-line expanded layout
          if (expandedOpacity > 0)
            Positioned.fill(
              child: Opacity(
                opacity: expandedOpacity,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Your Mind,', style: expandedTextStyle),
                      Flexible(
                        child: ClipRect(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 450),
                            layoutBuilder: (current, previous) => Stack(
                              alignment: Alignment.topLeft,
                              clipBehavior: Clip.hardEdge,
                              children: [...previous, if (current != null) current],
                            ),
                            transitionBuilder: _wordSlideTransition,
                            child: ShaderMask(
                              key: ValueKey('exp-$wordIdx'),
                              shaderCallback: (bounds) =>
                                  AppColors.brandGradient.createShader(bounds),
                              blendMode: BlendMode.srcIn,
                              child: Text(
                                _heroWords[wordIdx],
                                style: expandedTextStyle.copyWith(color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          // Single-line collapsed layout
          if (collapsedOpacity > 0)
            Positioned.fill(
              child: Opacity(
                opacity: collapsedOpacity,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text('Your Mind, ', style: collapsedTextStyle),
                      ClipRect(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 380),
                          layoutBuilder: (current, previous) => Stack(
                            alignment: Alignment.centerLeft,
                            clipBehavior: Clip.hardEdge,
                            children: [...previous, if (current != null) current],
                          ),
                          transitionBuilder: _wordSlideTransition,
                          child: ShaderMask(
                            key: ValueKey('col-$wordIdx'),
                            shaderCallback: (bounds) =>
                                AppColors.brandGradient.createShader(bounds),
                            blendMode: BlendMode.srcIn,
                            child: Text(
                              _heroWords[wordIdx],
                              style: collapsedTextStyle.copyWith(color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(_HeroTitleDelegate old) =>
      old.wordIdx != wordIdx || old.c != c;
}

// ── Spotlight Carousel ────────────────────────────────────────────────────────

class _SpotlightCarousel extends ConsumerStatefulWidget {
  const _SpotlightCarousel();

  @override
  ConsumerState<_SpotlightCarousel> createState() =>
      _SpotlightCarouselState();
}

class _SpotlightCarouselState extends ConsumerState<_SpotlightCarousel> {
  final _pc = PageController();
  int _page = 0;

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    final discoverDismissed = ref.watch(_discoverDismissedProvider);
    final nextReadDismissed = ref.watch(_nextReadDismissedProvider);
    final discoverLink = ref.watch(discoverLinkProvider).valueOrNull;
    final nextReadLink = ref.watch(nextReadProvider).valueOrNull;
    final reviewCount = ref.watch(reviewDueCountProvider).valueOrNull ?? 0;

    final pages = <Widget>[];

    if (!discoverDismissed && discoverLink != null) {
      pages.add(_DiscoverCard(link: discoverLink, c: c));
    }
    if (!nextReadDismissed && nextReadLink != null) {
      pages.add(_NextReadCard(link: nextReadLink, c: c));
    }
    if (reviewCount > 0) {
      pages.add(_ReviewPage(count: reviewCount, c: c));
    }

    if (pages.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          SizedBox(
            height: 215,
            child: PageView.builder(
              controller: _pc,
              onPageChanged: (i) => setState(() => _page = i),
              itemCount: pages.length,
              itemBuilder: (ctx, i) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: pages[i],
              ),
            ),
          ),
          if (pages.length > 1) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                pages.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: _page == i ? 18.0 : 6.0,
                  height: 6,
                  decoration: BoxDecoration(
                    color: _page == i
                        ? c.accent
                        : c.textHint.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Review page (in carousel) ─────────────────────────────────────────────────

class _ReviewPage extends StatelessWidget {
  final int count;
  final AppColorScheme c;
  const _ReviewPage({required this.count, required this.c});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return GestureDetector(
      onTap: () => context.push('/review'),
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              c.purple.withValues(alpha: 0.14),
              c.accent.withValues(alpha: 0.06),
            ],
          ),
          borderRadius: BorderRadius.circular(18),
          border:
              Border.all(color: c.purple.withValues(alpha: 0.30), width: 0.8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: c.purpleDim,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.psychology_rounded,
                          size: 10, color: c.purple),
                      const SizedBox(width: 5),
                      Text(
                        'REVIEW',
                        style: theme.labelSmall!.copyWith(
                          color: c.purple,
                          fontWeight: FontWeight.w700,
                          fontSize: 9,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Icon(Icons.arrow_forward_rounded, size: 16, color: c.purple),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              '$count ${count == 1 ? 'link' : 'links'}',
              style: theme.displaySmall!.copyWith(
                fontWeight: FontWeight.w800,
                color: c.purple,
                fontSize: 32,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'ready for review today',
              style: theme.bodyMedium!.copyWith(
                color: c.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Next Read Card ────────────────────────────────────────────────────────────

class _NextReadCard extends ConsumerWidget {
  final dynamic link;
  final AppColorScheme c;
  const _NextReadCard({required this.link, required this.c});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            c.green.withValues(alpha: 0.08),
            c.accent.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: c.green.withValues(alpha: 0.25), width: 0.8),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Container(
              width: 3,
              decoration: BoxDecoration(
                color: c.green,
                borderRadius:
                    const BorderRadius.horizontal(left: Radius.circular(16)),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: c.greenDim,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: c.green.withValues(alpha: 0.3),
                            width: 0.5),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.trending_up_rounded,
                              size: 10, color: c.green),
                          const SizedBox(width: 5),
                          Text(
                            'READ NEXT',
                            style: theme.labelSmall!.copyWith(
                              color: c.green,
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
                      onTap: () => ref
                          .read(_nextReadDismissedProvider.notifier)
                          .state = true,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: c.surfaceElevated,
                          borderRadius: BorderRadius.circular(8),
                          border:
                              Border.all(color: c.border, width: 0.5),
                        ),
                        child: Icon(Icons.close_rounded,
                            size: 14, color: c.textHint),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (link.favicon != null)
                      Container(
                        width: 32,
                        height: 32,
                        margin: const EdgeInsets.only(right: 10, top: 1),
                        decoration: BoxDecoration(
                          color: c.surfaceElevated,
                          borderRadius: BorderRadius.circular(8),
                          border:
                              Border.all(color: c.border, width: 0.5),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(7),
                          child: CachedNetworkImage(
                            imageUrl: link.favicon ?? '',
                            fit: BoxFit.cover,
                            errorWidget: (ctx, url, e) => Icon(
                                Icons.link_rounded,
                                size: 14,
                                color: c.textHint),
                          ),
                        ),
                      ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            link.title ?? '',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.titleSmall!.copyWith(
                              fontWeight: FontWeight.w600,
                              color: c.textPrimary,
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            link.domain ?? '',
                            style: theme.bodySmall!.copyWith(
                                color: c.textHint, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      final url = link.url as String;
                      context.push('/reader',
                          extra: {'url': url, 'linkId': link.id as int});
                      ref
                          .read(_nextReadDismissedProvider.notifier)
                          .state = true;
                    },
                    icon: Icon(Icons.open_in_browser_rounded,
                        size: 14, color: c.green),
                    label: Text(
                      'Open & Read',
                      style: TextStyle(color: c.green, fontSize: 13),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      side: BorderSide(
                          color: c.green.withValues(alpha: 0.4), width: 0.8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Glow Orb ──────────────────────────────────────────────────────────────────

class _GlowOrb extends StatelessWidget {
  final Color color;
  final double size;
  const _GlowOrb({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withValues(alpha: 0.10),
            color.withValues(alpha: 0.03),
            Colors.transparent,
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
    );
  }
}

// ── Stat Tile ─────────────────────────────────────────────────────────────────

class _StatTile extends StatelessWidget {
  final String value;
  final String label;
  final Color accent;
  final Color dimColor;
  final IconData icon;
  final AppColorScheme c;

  const _StatTile({
    required this.value,
    required this.label,
    required this.accent,
    required this.dimColor,
    required this.icon,
    required this.c,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: accent.withValues(alpha: 0.18),
            width: 0.8,
          ),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: dimColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 14, color: accent),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: theme.titleLarge!.copyWith(
                fontWeight: FontWeight.w700,
                color: accent,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              label,
              style: theme.labelSmall!.copyWith(
                color: c.textHint,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// ── Discover Card ─────────────────────────────────────────────────────────────

class _DiscoverCard extends ConsumerWidget {
  final dynamic link;
  final AppColorScheme c;
  const _DiscoverCard({required this.link, required this.c});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            c.accent.withValues(alpha: 0.10),
            c.purple.withValues(alpha: 0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.accentBorder, width: 0.8),
      ),
      child: Stack(
        children: [
          // Inner glow overlay
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 100,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(16)),
                gradient: LinearGradient(
                  colors: [
                    c.accent.withValues(alpha: 0.08),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Left accent bar
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Container(
              width: 3,
              decoration: BoxDecoration(
                gradient: AppColors.brandGradient,
                borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(16)),
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: c.accentDim,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: c.accentBorder, width: 0.5),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.auto_awesome_rounded,
                              size: 10, color: c.accent),
                          const SizedBox(width: 5),
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
                      onTap: () => ref
                          .read(_discoverDismissedProvider.notifier)
                          .state = true,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: c.surfaceElevated,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: c.border, width: 0.5),
                        ),
                        child: Icon(Icons.close_rounded,
                            size: 14, color: c.textHint),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (link.favicon != null)
                      Container(
                        width: 32,
                        height: 32,
                        margin: const EdgeInsets.only(right: 10, top: 1),
                        decoration: BoxDecoration(
                          color: c.surfaceElevated,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: c.border, width: 0.5),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(7),
                          child: CachedNetworkImage(
                            imageUrl: link.favicon ?? '',
                            fit: BoxFit.cover,
                            errorWidget: (ctx, url, e) => Icon(
                                Icons.link_rounded,
                                size: 14,
                                color: c.textHint),
                          ),
                        ),
                      ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            link.title ?? '',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.titleSmall!.copyWith(
                              fontWeight: FontWeight.w600,
                              color: c.textPrimary,
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            link.domain ?? '',
                            style: theme.bodySmall!.copyWith(
                                color: c.textHint, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          final url = link.url as String;
                          context.push('/reader',
                              extra: {
                                'url': url,
                                'linkId': link.id as int
                              });
                          ref
                              .read(_discoverDismissedProvider.notifier)
                              .state = true;
                        },
                        icon: Icon(Icons.open_in_browser_rounded,
                            size: 14, color: c.accent),
                        label: Text(
                          'Open & Read',
                          style: TextStyle(
                              color: c.accent, fontSize: 13),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding:
                              const EdgeInsets.symmetric(vertical: 9),
                          side: BorderSide(
                              color: c.accentBorder, width: 0.8),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


// ── Link Card ─────────────────────────────────────────────────────────────────

class _LinkCard extends ConsumerWidget {
  final LinkModel link;
  const _LinkCard({required this.link});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final theme = Theme.of(context).textTheme;

    return Material(
      color: c.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        splashColor: c.accent.withValues(alpha: 0.08),
        highlightColor: c.accent.withValues(alpha: 0.04),
        onTap: () {
          if (link.url.isEmpty) return;
          context.push('/reader', extra: {'url': link.url, 'linkId': link.id});
        },
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: c.border, width: 0.5),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Favicon
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
                  child: CachedNetworkImage(
                    imageUrl: link.favicon ?? '',
                    height: 34,
                    width: 34,
                    fit: BoxFit.cover,
                    errorWidget: (ctx2, url, e) => Icon(
                        Icons.link_rounded,
                        size: 16,
                        color: c.textHint),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title + tag
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            link.title,
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
                                horizontal: 7, vertical: 3),
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
                        Icon(Icons.language_rounded,
                            size: 11, color: c.textHint),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            link.domain ?? '',
                            overflow: TextOverflow.ellipsis,
                            style: theme.bodySmall!
                                .copyWith(color: c.textHint, fontSize: 11),
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
                        Icon(Icons.calendar_today_outlined,
                            size: 11, color: c.textHint),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat.MMMd().format(link.createdAt),
                          style: theme.bodySmall!
                              .copyWith(color: c.textHint, fontSize: 11),
                        ),
                        const Spacer(),
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => showLinkOptions(context, ref, link),
                          child: Icon(Icons.more_horiz_rounded,
                              size: 16, color: c.textSecondary),
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
                    height: 64,
                    width: 64,
                    fit: BoxFit.cover,
                    errorWidget: (ctx2, url, e) => const SizedBox(),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final AppColorScheme c;
  const _EmptyState({required this.c});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Lottie.asset(
            'assets/animations/empty_bookmark.json',
            width: 180,
            height: 180,
            repeat: true,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 4),
          Text(
            'Nothing saved yet',
            style: theme.titleMedium!.copyWith(
              fontWeight: FontWeight.w700,
              color: c.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tap + to save your first link',
            style: theme.bodySmall!.copyWith(color: c.textHint),
          ),
        ],
      ),
    );
  }
}

// ── Error State ───────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  final AppColorScheme c;
  final String error;
  const _ErrorState({required this.c, required this.error});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 40, 16, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.wifi_off_rounded, color: c.textHint, size: 32),
          const SizedBox(height: 12),
          Text('Could not load saves',
              style: theme.titleSmall!.copyWith(color: c.textPrimary)),
          const SizedBox(height: 4),
          Text(error,
              style: theme.bodySmall!.copyWith(color: c.textHint),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

// ── Skeleton Card ─────────────────────────────────────────────────────────────

class _SkeletonCard extends StatelessWidget {
  final AppColorScheme c;
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

class _Bone extends StatelessWidget {
  final double width, height, radius;
  final AppColorScheme c;
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
