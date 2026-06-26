import 'dart:async';
import 'dart:math' show max, min;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:recallr/common/widgets.dart';
import 'package:recallr/core/services/share_intent_service.dart';
import 'package:recallr/theme/recallr_colors.dart';

class MainNavigation extends StatefulWidget {
  final Widget child;
  const MainNavigation({super.key, required this.child});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  StreamSubscription<String>? _shareSubscription;

  @override
  void initState() {
    super.initState();
    // Cold-start share intents are handled by the /share-intent route.
    // Here we only subscribe to the foreground/background stream.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _shareSubscription = ShareIntentService.urlStream.listen((url) {
        if (mounted) ReWid.openSaveSheet(context, initialUrl: url);
      });
    });
  }

  @override
  void dispose() {
    _shareSubscription?.cancel();
    super.dispose();
  }

  int _currentIndex(BuildContext context) {
    final loc = GoRouterState.of(context).uri.toString();
    if (loc.startsWith('/search')) return 1;
    if (loc.startsWith('/categories')) return 2;
    if (loc.startsWith('/profile')) return 3;
    return 0;
  }

  void _onTap(BuildContext context, int i) {
    switch (i) {
      case 0: context.go('/');           break;
      case 1: context.go('/search');     break;
      case 2: context.go('/categories'); break;
      case 3: context.go('/profile');    break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final index = _currentIndex(context);
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: _CustomNavBar(
        currentIndex: index,
        onTap: (i) => _onTap(context, i),
      ),
    );
  }
}

// ── Items config ──────────────────────────────────────────────────────────────

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem(this.icon, this.activeIcon, this.label);
}

const _kItems = [
  _NavItem(Icons.home_outlined,          Icons.auto_awesome_rounded, 'Home'),
  _NavItem(Icons.search_rounded,         Icons.search_rounded,       'Search'),
  _NavItem(Icons.grid_view_outlined,     Icons.grid_view_rounded,    'Library'),
  _NavItem(Icons.person_outline_rounded, Icons.person_rounded,       'Profile'),
];

const _kItemCount = 4;

// ── Custom nav bar (StatefulWidget so we can animate arch position) ───────────

class _CustomNavBar extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  const _CustomNavBar({required this.currentIndex, required this.onTap});

  @override
  State<_CustomNavBar> createState() => _CustomNavBarState();
}

class _CustomNavBarState extends State<_CustomNavBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _archAnim;
  double _prevFraction = 0.0;

  double _fractionForIndex(int i) =>
      (i + 0.5) / _kItemCount; // 0.125, 0.375, 0.625, 0.875

  @override
  void initState() {
    super.initState();
    _prevFraction = _fractionForIndex(widget.currentIndex);
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _archAnim = AlwaysStoppedAnimation(_prevFraction);
  }

  @override
  void didUpdateWidget(_CustomNavBar old) {
    super.didUpdateWidget(old);
    if (old.currentIndex != widget.currentIndex) {
      final target = _fractionForIndex(widget.currentIndex);
      _archAnim = Tween<double>(
        begin: _prevFraction,
        end: target,
      ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOutCubic));
      _prevFraction = target;
      _ctrl
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final barHeight = 64.0 + bottomPad;

    return RepaintBoundary(
      child: SizedBox(
        height: barHeight,
        child: AnimatedBuilder(
          animation: _archAnim,
          builder: (context, _) {
            return CustomPaint(
              painter: _NavBgPainter(
                bgColor: c.navBackground,
                accentColor: c.accent,
                archFraction: _archAnim.value,
              ),
              child: Padding(
                padding: EdgeInsets.only(bottom: bottomPad),
                child: Row(
                  children: List.generate(
                    _kItemCount,
                    (i) => Expanded(
                      child: _NavTile(
                        item: _kItems[i],
                        isActive: widget.currentIndex == i,
                        accentColor: c.accent,
                        activeColor: c.textPrimary,
                        inactiveColor: c.textHint,
                        onTap: () => widget.onTap(i),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ── Nav tile ──────────────────────────────────────────────────────────────────

class _NavTile extends StatelessWidget {
  final _NavItem item;
  final bool isActive;
  final Color accentColor;
  final Color activeColor;
  final Color inactiveColor;
  final VoidCallback onTap;

  const _NavTile({
    required this.item,
    required this.isActive,
    required this.accentColor,
    required this.activeColor,
    required this.inactiveColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox.expand(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Glow + icon
              SizedBox(
                width: 48,
                height: 40,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Radial glow (only active)
                    if (isActive)
                      Container(
                        width: 48,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            colors: [
                              accentColor.withValues(alpha: 0.25),
                              accentColor.withValues(alpha: 0.0),
                            ],
                          ),
                        ),
                      ),
                    // Icon
                    Icon(
                      isActive ? item.activeIcon : item.icon,
                      size: isActive ? 26 : 22,
                      color: isActive ? activeColor : inactiveColor,
                      shadows: isActive
                          ? [
                              Shadow(
                                color: accentColor.withValues(alpha: 0.9),
                                blurRadius: 14,
                              ),
                            ]
                          : null,
                    ),
                  ],
                ),
              ),

              // Label (only active)
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 200),
                crossFadeState: isActive
                    ? CrossFadeState.showFirst
                    : CrossFadeState.showSecond,
                firstChild: Text(
                  item.label,
                  style: TextStyle(
                    color: activeColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                    shadows: [
                      Shadow(
                        color: accentColor.withValues(alpha: 0.8),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
                secondChild: const SizedBox(height: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Background painter ────────────────────────────────────────────────────────

class _NavBgPainter extends CustomPainter {
  final Color bgColor;
  final Color accentColor;

  /// 0..1 fraction across the bar width where the arch peak sits
  final double archFraction;

  const _NavBgPainter({
    required this.bgColor,
    required this.accentColor,
    required this.archFraction,
  });

  // Arch geometry constants
  static const double _archH    = 14.0; // how tall the arch rises
  static const double _halfSpan = 52.0; // half-width of the arch footprint

  /// Builds the top-edge path (arch + flat sides).
  Path _topEdgePath(Size size) {
    final cx = archFraction * size.width; // peak x
    final left  = cx - _halfSpan;
    final right = cx + _halfSpan;

    final path = Path();

    // Left flat section
    path.moveTo(0, _archH);
    path.lineTo(max(0.0, left), _archH);

    // Left rise — cubic bezier into peak
    path.cubicTo(
      cx - _halfSpan * 0.55, _archH,
      cx - _halfSpan * 0.35, 0,
      cx, 0,
    );

    // Right drop — cubic bezier from peak
    path.cubicTo(
      cx + _halfSpan * 0.35, 0,
      cx + _halfSpan * 0.55, _archH,
      min(size.width, right), _archH,
    );

    // Right flat section
    path.lineTo(size.width, _archH);

    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final topEdge = _topEdgePath(size);

    // ── Filled background ────────────────────────────
    final fill = Path.from(topEdge)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(fill, Paint()..color = bgColor);

    // ── Accent glow stroke along arch ────────────────
    final cx = archFraction * size.width;
    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..shader = LinearGradient(
        colors: [
          Colors.transparent,
          accentColor.withValues(alpha: 0.4),
          accentColor.withValues(alpha: 0.95),
          accentColor.withValues(alpha: 0.4),
          Colors.transparent,
        ],
        stops: const [0.0, 0.3, 0.5, 0.7, 1.0],
        // Gradient is always centred on the arch peak
        begin: Alignment(
          ((cx - _halfSpan * 1.4) / size.width) * 2 - 1,
          0,
        ),
        end: Alignment(
          ((cx + _halfSpan * 1.4) / size.width) * 2 - 1,
          0,
        ),
      ).createShader(Rect.fromLTWH(0, 0, size.width, _archH));

    canvas.drawPath(topEdge, glowPaint);
  }

  @override
  bool shouldRepaint(_NavBgPainter old) =>
      old.archFraction != archFraction ||
      old.bgColor != bgColor ||
      old.accentColor != accentColor;
}
