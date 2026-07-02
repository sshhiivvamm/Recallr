import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/repositrories/highlight/highlight_provider.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/sm2_service.dart';
import '../../../data/models/Highlight/highlight_model.dart';
import '../../../data/models/Link/link_model.dart';
import '../../../theme/recallr_colors.dart';
import '../../repositrories/link_providers/recent_links_provider.dart';

class ReReview extends ConsumerStatefulWidget {
  const ReReview({super.key});

  @override
  ConsumerState<ReReview> createState() => _ReReviewState();
}

class _ReReviewState extends ConsumerState<ReReview> {
  List<LinkModel>? _queue;
  int _current = 0;
  int _reviewed = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadQueue());
  }

  Future<void> _loadQueue() async {
    final queue = await ref.read(reviewQueueProvider.future);
    if (!mounted) return;
    setState(() {
      _queue = queue;
      _loading = false;
    });
  }

  Future<void> _rate(int quality) async {
    final link = _queue![_current];
    await Sm2Service.instance.review(link.id, quality);
    if (!mounted) return;
    setState(() {
      _reviewed++;
      _current++;
    });
    ref.invalidate(reviewQueueProvider);
    ref.invalidate(reviewDueCountProvider);

    // When the session ends, reschedule the daily notification with the
    // updated remaining-due count so tomorrow's message is specific.
    final remaining = _queue!.length - _current;
    if (remaining <= 0 && await NotificationService.instance.isEnabled()) {
      final stillDue = await ref.read(reviewDueCountProvider.future);
      await NotificationService.instance.rescheduleWithCount(stillDue);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final theme = Theme.of(context).textTheme;

    if (_loading) {
      return Scaffold(
        backgroundColor: c.background,
        body: Center(
          child: CircularProgressIndicator(color: c.accent, strokeWidth: 2),
        ),
      );
    }

    final queue = _queue ?? [];
    final done = queue.isEmpty || _current >= queue.length;

    return Scaffold(
      backgroundColor: c.background,
      body: Stack(
        children: [
          Positioned(
            top: -80, right: -60,
            child: _GlowOrb(color: c.purple, size: 260),
          ),
          Positioned(
            bottom: 100, left: -50,
            child: _GlowOrb(color: c.accent, size: 200),
          ),
          SafeArea(
            bottom: true,
            child: Column(
              children: [
                // ── Header ──────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => context.pop(),
                        child: Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                            color: c.surface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: c.border, width: 0.5),
                          ),
                          child: Icon(Icons.arrow_back_ios_new_rounded,
                              size: 15, color: c.textSecondary),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Review',
                            style: theme.titleMedium!.copyWith(
                              fontWeight: FontWeight.w800,
                              color: c.textPrimary,
                            ),
                          ),
                          if (!done && queue.isNotEmpty)
                            Text(
                              '${_current + 1} of ${queue.length}',
                              style: theme.labelSmall!
                                  .copyWith(color: c.textHint, fontSize: 10),
                            ),
                        ],
                      ),
                      const Spacer(),
                      if (!done && queue.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: c.purpleDim,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: c.purple.withValues(alpha: 0.30),
                                width: 0.5),
                          ),
                          child: Text(
                            '${queue.length - _current} left',
                            style: theme.labelSmall!.copyWith(
                              color: c.purple,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // ── Progress bar ─────────────────────────────────
                if (!done && queue.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _current / queue.length,
                        minHeight: 4,
                        backgroundColor: c.border,
                        valueColor: AlwaysStoppedAnimation(c.purple),
                      ),
                    ),
                  ),
                ],

                // ── Card deck or done ────────────────────────────
                Expanded(
                  child: done
                      ? _DoneState(
                          reviewed: _reviewed,
                          c: c,
                          theme: theme,
                          onClose: () => context.pop(),
                        )
                      : _CardDeck(
                          key: ValueKey(_current),
                          queue: queue,
                          current: _current,
                          c: c,
                          theme: theme,
                          onRate: _rate,
                        ),
                ),

                if (!done && queue.isNotEmpty) ...[
                  // ── Swipe hint ───────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(children: [
                          Icon(Icons.arrow_back_rounded,
                              size: 12, color: c.coral.withValues(alpha: 0.7)),
                          const SizedBox(width: 4),
                          Text('Forgot',
                              style: theme.labelSmall!.copyWith(
                                  color: c.coral.withValues(alpha: 0.7),
                                  fontSize: 10)),
                        ]),
                        Text('swipe to rate',
                            style: theme.labelSmall!
                                .copyWith(color: c.textHint, fontSize: 10)),
                        Row(children: [
                          Text('Easy',
                              style: theme.labelSmall!.copyWith(
                                  color: c.green.withValues(alpha: 0.7),
                                  fontSize: 10)),
                          const SizedBox(width: 4),
                          Icon(Icons.arrow_forward_rounded,
                              size: 12, color: c.green.withValues(alpha: 0.7)),
                        ]),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ── Rating buttons ───────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        _RatingButton(
                          icon: Icons.close_rounded,
                          label: 'Forgot',
                          sublabel: 'Tomorrow',
                          color: c.coral,
                          dimColor: c.coral.withValues(alpha: 0.10),
                          onTap: () => _rate(1),
                        ),
                        const SizedBox(width: 8),
                        _RatingButton(
                          icon: Icons.trending_down_rounded,
                          label: 'Hard',
                          sublabel: 'Soon',
                          color: c.amber,
                          dimColor: c.amberDim,
                          onTap: () => _rate(3),
                        ),
                        const SizedBox(width: 8),
                        _RatingButton(
                          icon: Icons.check_rounded,
                          label: 'Good',
                          sublabel: 'Few days',
                          color: c.accent,
                          dimColor: c.accentDim,
                          onTap: () => _rate(4),
                        ),
                        const SizedBox(width: 8),
                        _RatingButton(
                          icon: Icons.bolt_rounded,
                          label: 'Easy',
                          sublabel: 'Long break',
                          color: c.green,
                          dimColor: c.greenDim,
                          onTap: () => _rate(5),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
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
      width: size, height: size,
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

// ── Card Deck (staggered swipeable stack) ─────────────────────────────────────

class _CardDeck extends StatefulWidget {
  final List<LinkModel> queue;
  final int current;
  final AppColorScheme c;
  final TextTheme theme;
  final Future<void> Function(int quality) onRate;

  const _CardDeck({
    super.key,
    required this.queue,
    required this.current,
    required this.c,
    required this.theme,
    required this.onRate,
  });

  @override
  State<_CardDeck> createState() => _CardDeckState();
}

class _CardDeckState extends State<_CardDeck> with TickerProviderStateMixin {
  double _dx = 0;
  double _dy = 0;
  bool _animating = false;
  bool _lockH = false;
  bool _lockV = false;
  AnimationController? _activeCtrl;

  static const double _threshold = 80.0;

  @override
  void dispose() {
    _activeCtrl?.dispose();
    super.dispose();
  }

  void _onPanStart(DragStartDetails _) {
    if (_animating) return;
    _lockH = false;
    _lockV = false;
  }

  void _onPanUpdate(DragUpdateDetails d) {
    if (_animating) return;
    // Determine axis lock on first significant movement
    if (!_lockH && !_lockV) {
      if (d.delta.dx.abs() > d.delta.dy.abs() + 2) {
        _lockH = true;
      } else if (d.delta.dy.abs() > d.delta.dx.abs() + 2) {
        _lockV = true;
      }
    }
    if (!_lockH) return;
    setState(() {
      _dx += d.delta.dx;
      _dy += d.delta.dy * 0.25;
    });
  }

  void _onPanEnd(DragEndDetails d) {
    if (_animating || !_lockH) return;
    if (_dx.abs() >= _threshold) {
      _swipeOff(_dx > 0 ? 5 : 1);
    } else {
      _snapBack();
    }
  }

  void _snapBack() {
    _animating = true;
    final startDx = _dx;
    final startDy = _dy;
    _activeCtrl?.dispose();
    _activeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    final anim =
        CurvedAnimation(parent: _activeCtrl!, curve: Curves.elasticOut);
    anim.addListener(() {
      if (!mounted) return;
      setState(() {
        _dx = startDx + (0 - startDx) * anim.value;
        _dy = startDy + (0 - startDy) * anim.value;
      });
    });
    _activeCtrl!.addStatusListener((s) {
      if (s == AnimationStatus.completed && mounted) {
        setState(() {
          _dx = 0;
          _dy = 0;
          _animating = false;
        });
      }
    });
    _activeCtrl!.forward();
  }

  Future<void> _swipeOff(int quality) async {
    _animating = true;
    final startDx = _dx;
    final startDy = _dy;
    final screenW = MediaQuery.of(context).size.width;
    final targetDx = quality == 5 ? screenW * 1.6 : -screenW * 1.6;
    _activeCtrl?.dispose();
    _activeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    final anim =
        CurvedAnimation(parent: _activeCtrl!, curve: Curves.easeInCubic);
    anim.addListener(() {
      if (!mounted) return;
      setState(() {
        _dx = startDx + (targetDx - startDx) * anim.value;
        _dy = startDy + 50 * anim.value;
      });
    });
    await _activeCtrl!.forward();
    await widget.onRate(quality);
    if (mounted) {
      setState(() {
        _dx = 0;
        _dy = 0;
        _animating = false;
        _lockH = false;
        _lockV = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final queue = widget.queue;
    final current = widget.current;
    final c = widget.c;

    final progress = (_dx.abs() / _threshold).clamp(0.0, 1.0);
    final rotation = _dx / 700.0;
    final swipingRight = _dx > 10;
    final swipingLeft = _dx < -10;
    final overlayAlpha = ((_dx.abs() - 10) / 60).clamp(0.0, 0.80);
    final labelAlpha = ((_dx.abs() - 35) / 40).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          // ── Ghost card 2 (deepest) ──────────────────────────
          if (current + 2 < queue.length)
            IgnorePointer(
              child: Opacity(
                opacity: 0.45 + 0.30 * progress,
                child: Transform.scale(
                  alignment: Alignment.bottomCenter,
                  scale: 0.88 + 0.06 * progress,
                  child: Transform.translate(
                    offset: Offset(0, 20.0 - 10.0 * progress),
                    child: _GhostCard(c: c),
                  ),
                ),
              ),
            ),

          // ── Ghost card 1 (middle) ───────────────────────────
          if (current + 1 < queue.length)
            IgnorePointer(
              child: Opacity(
                opacity: 0.65 + 0.35 * progress,
                child: Transform.scale(
                  alignment: Alignment.bottomCenter,
                  scale: 0.94 + 0.06 * progress,
                  child: Transform.translate(
                    offset: Offset(0, 10.0 - 10.0 * progress),
                    child: _GhostCard(c: c),
                  ),
                ),
              ),
            ),

          // ── Top (draggable) card ────────────────────────────
          GestureDetector(
            onPanStart: _onPanStart,
            onPanUpdate: _onPanUpdate,
            onPanEnd: _onPanEnd,
            child: Transform.translate(
              offset: Offset(_dx, _dy),
              child: Transform.rotate(
              angle: rotation,
              alignment: Alignment.bottomCenter,
              child: Stack(
                children: [
                  // Card content
                  _ReviewCardContent(
                    key: ValueKey(queue[current].id),
                    link: queue[current],
                    c: c,
                    theme: widget.theme,
                    onRate: widget.onRate,
                  ),

                  // Swipe colour overlay
                  if (_dx.abs() > 10)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: Opacity(
                            opacity: overlayAlpha,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: swipingRight
                                      ? Alignment.centerLeft
                                      : Alignment.centerRight,
                                  end: swipingRight
                                      ? Alignment.centerRight
                                      : Alignment.centerLeft,
                                  colors: [
                                    (swipingRight ? c.green : c.coral)
                                        .withValues(alpha: 0.65),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                  // Swipe label (EASY / FORGOT)
                  if (_dx.abs() > 35)
                    Positioned(
                      top: 28,
                      left: swipingRight ? 20 : null,
                      right: swipingLeft ? 20 : null,
                      child: IgnorePointer(
                        child: Opacity(
                          opacity: labelAlpha,
                          child: Transform.rotate(
                            angle: swipingRight ? -0.18 : 0.18,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: swipingRight ? c.green : c.coral,
                                  width: 2.5,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                swipingRight ? 'EASY' : 'FORGOT',
                                style: TextStyle(
                                  color: swipingRight ? c.green : c.coral,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 18,
                                  letterSpacing: 1.5,
                                ),
                              ),
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
        ],
      ),
    );
  }
}

// ── Ghost Card (stagger depth effect) ────────────────────────────────────────

class _GhostCard extends StatelessWidget {
  final AppColorScheme c;
  const _GhostCard({required this.c});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: c.border, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: c.purple.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
    );
  }
}

// ── Review Card Content ───────────────────────────────────────────────────────

class _ReviewCardContent extends ConsumerStatefulWidget {
  final LinkModel link;
  final AppColorScheme c;
  final TextTheme theme;
  final Future<void> Function(int quality) onRate;

  const _ReviewCardContent({
    super.key,
    required this.link,
    required this.c,
    required this.theme,
    required this.onRate,
  });

  @override
  ConsumerState<_ReviewCardContent> createState() =>
      _ReviewCardContentState();
}

class _ReviewCardContentState extends ConsumerState<_ReviewCardContent>
    with SingleTickerProviderStateMixin {
  List<HighlightModel> _highlights = [];
  late AnimationController _entryCtrl;
  late Animation<double> _entryAnim;

  @override
  void initState() {
    super.initState();
    _loadHighlights();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    )..forward();
    _entryAnim =
        CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic);
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadHighlights() async {
    final list = await ref
        .read(highlightRepositoryProvider)
        .getByLinkId(widget.link.id);
    if (mounted) setState(() => _highlights = list);
  }

  static Color _highlightColor(String? css) {
    final m = RegExp(r'rgba\((\d+),(\d+),(\d+)').firstMatch(css ?? '');
    if (m == null) return const Color(0xFFFBBF24);
    return Color.fromARGB(255, int.parse(m.group(1)!),
        int.parse(m.group(2)!), int.parse(m.group(3)!));
  }

  @override
  Widget build(BuildContext context) {
    final link = widget.link;
    final c = widget.c;
    final theme = widget.theme;

    return FadeTransition(
      opacity: _entryAnim,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: c.border, width: 0.5),
          boxShadow: [
            BoxShadow(
              color: c.purple.withValues(alpha: 0.08),
              blurRadius: 28,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Source bar
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    c.purple.withValues(alpha: 0.10),
                    c.accent.withValues(alpha: 0.04),
                  ],
                ),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: c.surfaceElevated,
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(color: c.border, width: 0.5),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: link.favicon ?? '',
                        fit: BoxFit.cover,
                        errorWidget: (_, url, e) => Icon(
                            Icons.link_rounded, size: 14, color: c.textHint),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      link.domain ?? '',
                      style: theme.bodySmall!.copyWith(
                        color: c.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (link.tags.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: c.purpleDim,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        link.tags.first.name.toUpperCase(),
                        style: theme.labelSmall!.copyWith(
                          color: c.purple,
                          fontWeight: FontWeight.w700,
                          fontSize: 9,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Scrollable body
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      link.title,
                      style: theme.titleLarge!.copyWith(
                        fontWeight: FontWeight.w700,
                        color: c.textPrimary,
                        height: 1.35,
                        fontSize: 20,
                      ),
                    ),
                    if ((link.description ?? '').isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Text(
                        link.description!,
                        maxLines: 5,
                        overflow: TextOverflow.ellipsis,
                        style: theme.bodyMedium!.copyWith(
                          color: c.textSecondary,
                          height: 1.55,
                        ),
                      ),
                    ],
                    if ((link.notes ?? '').isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: c.surfaceElevated,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: c.border, width: 0.5),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.notes_rounded,
                                size: 14, color: c.textHint),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                link.notes!,
                                style: theme.bodySmall!.copyWith(
                                    color: c.textSecondary, height: 1.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (_highlights.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: c.surfaceElevated,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: c.border, width: 0.5),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              const Icon(Icons.format_color_text,
                                  size: 12, color: Color(0xFF38BDF8)),
                              const SizedBox(width: 6),
                              Text(
                                '${_highlights.length} highlight${_highlights.length == 1 ? '' : 's'}',
                                style: theme.labelSmall!
                                    .copyWith(color: c.textHint),
                              ),
                            ]),
                            const SizedBox(height: 10),
                            ..._highlights.take(3).map(
                                  (h) => Padding(
                                    padding:
                                        const EdgeInsets.only(bottom: 6),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          width: 3, height: 14,
                                          margin: const EdgeInsets.only(
                                              right: 8, top: 2),
                                          decoration: BoxDecoration(
                                            color: _highlightColor(
                                                h.colorHex),
                                            borderRadius:
                                                BorderRadius.circular(2),
                                          ),
                                        ),
                                        Expanded(
                                          child: Text(
                                            h.text,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: theme.bodySmall!.copyWith(
                                              color: c.textSecondary,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            if (_highlights.length > 3)
                              Text(
                                '+${_highlights.length - 3} more',
                                style: theme.labelSmall!.copyWith(
                                    color: c.textHint, fontSize: 10),
                              ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // Open to read footer
            GestureDetector(
              onTap: () async {
                await context.push<void>(
                  '/reader',
                  extra: {'url': link.url, 'linkId': link.id},
                );
                if (!context.mounted) return;
                final quality = await showModalBottomSheet<int>(
                  context: context,
                  backgroundColor: Colors.transparent,
                  builder: (_) => _RatingPrompt(
                    link: widget.link,
                    c: widget.c,
                    theme: widget.theme,
                  ),
                );
                if (quality != null) await widget.onRate(quality);
              },
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                decoration: BoxDecoration(
                  border:
                      Border(top: BorderSide(color: c.border, width: 0.5)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.open_in_new_rounded, size: 13, color: c.accent),
                    const SizedBox(width: 7),
                    Text(
                      'Open & read the full article',
                      style: theme.labelMedium!.copyWith(
                        color: c.accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Rating Button ─────────────────────────────────────────────────────────────

class _RatingButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  final Color color;
  final Color dimColor;
  final VoidCallback? onTap;

  const _RatingButton({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.color,
    required this.dimColor,
    required this.onTap,
  });

  @override
  State<_RatingButton> createState() => _RatingButtonState();
}

class _RatingButtonState extends State<_RatingButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return Expanded(
      child: Listener(
        onPointerDown: (_) => setState(() => _pressed = true),
        onPointerUp: (_) => setState(() => _pressed = false),
        onPointerCancel: (_) => setState(() => _pressed = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedScale(
            scale: _pressed ? 0.96 : 1.0,
            duration: const Duration(milliseconds: 100),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: _pressed
                    ? widget.color.withValues(alpha: 0.22)
                    : widget.dimColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: widget.color
                      .withValues(alpha: _pressed ? 0.55 : 0.22),
                  width: _pressed ? 1.0 : 0.8,
                ),
                boxShadow: _pressed
                    ? [
                        BoxShadow(
                          color: widget.color.withValues(alpha: 0.22),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : [],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 34, height: 34,
                    decoration: BoxDecoration(
                      color: widget.color
                          .withValues(alpha: _pressed ? 0.28 : 0.14),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(widget.icon, size: 17, color: widget.color),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    widget.label,
                    style: theme.titleSmall!.copyWith(
                      color: widget.color,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.sublabel,
                    style: theme.labelSmall!.copyWith(
                      color: widget.color.withValues(alpha: 0.60),
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Post-read Rating Prompt (bottom sheet) ────────────────────────────────────

class _RatingPrompt extends StatelessWidget {
  final LinkModel link;
  final AppColorScheme c;
  final TextTheme theme;

  const _RatingPrompt({
    required this.link,
    required this.c,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, 20 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: c.border, width: 0.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: c.borderSoft,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [c.purpleDim, c.accentDim],
                  ),
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(
                      color: c.purple.withValues(alpha: 0.25), width: 0.5),
                ),
                child: Icon(Icons.psychology_rounded, size: 18, color: c.purple),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'How well did you know this?',
                      style: theme.titleSmall!.copyWith(
                        fontWeight: FontWeight.w700,
                        color: c.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      link.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.bodySmall!
                          .copyWith(color: c.textHint, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _RatingButton(
                icon: Icons.close_rounded,
                label: 'Forgot',
                sublabel: 'Tomorrow',
                color: c.coral,
                dimColor: c.coral.withValues(alpha: 0.10),
                onTap: () => Navigator.of(context).pop(1),
              ),
              const SizedBox(width: 10),
              _RatingButton(
                icon: Icons.check_rounded,
                label: 'OK',
                sublabel: 'Few days',
                color: c.accent,
                dimColor: c.accentDim,
                onTap: () => Navigator.of(context).pop(4),
              ),
              const SizedBox(width: 10),
              _RatingButton(
                icon: Icons.bolt_rounded,
                label: 'Easy',
                sublabel: 'Long break',
                color: c.green,
                dimColor: c.greenDim,
                onTap: () => Navigator.of(context).pop(5),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Done State ────────────────────────────────────────────────────────────────

class _DoneState extends StatelessWidget {
  final int reviewed;
  final AppColorScheme c;
  final TextTheme theme;
  final VoidCallback onClose;

  const _DoneState({
    required this.reviewed,
    required this.c,
    required this.theme,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final hasReviewed = reviewed > 0;
    return Stack(
      children: [
        // Confetti overlay — plays once on session complete
        if (hasReviewed)
          Positioned.fill(
            child: IgnorePointer(
              child: Lottie.asset(
                'assets/animations/confetti.json',
                repeat: false,
                fit: BoxFit.cover,
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Lottie.asset(
                'assets/animations/success.json',
                width: 120,
                height: 120,
                repeat: false,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 8),
              Text(
                hasReviewed ? 'Session complete!' : 'All caught up!',
                style: theme.titleLarge!.copyWith(
                  fontWeight: FontWeight.w800,
                  color: c.textPrimary,
                  fontSize: 22,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                hasReviewed
                    ? 'You reviewed $reviewed ${reviewed == 1 ? 'link' : 'links'}.\nLinks due again will appear tomorrow.'
                    : 'No links are due right now.\nCome back later to keep your streak!',
                textAlign: TextAlign.center,
                style: theme.bodySmall!.copyWith(color: c.textHint, height: 1.6),
              ),
              const SizedBox(height: 36),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onClose,
                  icon: const Icon(Icons.home_rounded, size: 16),
                  label: const Text('Back to Home'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
