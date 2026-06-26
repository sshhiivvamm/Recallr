import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app_routes.dart';
import '../../../theme/recallr_colors.dart';

class ReOnboarding extends StatefulWidget {
  const ReOnboarding({super.key});

  @override
  State<ReOnboarding> createState() => _ReOnboardingState();
}

class _ReOnboardingState extends State<ReOnboarding>
    with TickerProviderStateMixin {
  final _pageCtrl = PageController();
  double _pageOffset = 0; // continuous 0..3 value from PageController
  int _currentPage = 0;

  // Master idle animation — drives background patterns + illustration floats
  late final AnimationController _idleCtrl = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  )..repeat(reverse: true);

  // Faster pulse — used for glow rings on welcome screen
  late final AnimationController _pulseCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat(reverse: true);

  // Slow rotate — background geometric shapes
  late final AnimationController _rotateCtrl = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 20),
  )..repeat();

  // Text-entry scale animation — fires on each page change
  late AnimationController _textEntryCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  )..forward();

  late Animation<double> _textScale = CurvedAnimation(
    parent: _textEntryCtrl,
    curve: Curves.easeOutBack,
  );

  late Animation<double> _textFade = CurvedAnimation(
    parent: _textEntryCtrl,
    curve: Curves.easeOut,
  );

  static const _pages = [
    _PageData(
      tag: 'WELCOME',
      title: 'Your Personal\nKnowledge Vault',
      subtitle: 'Save any link from anywhere.\nAccess everything you care about — forever.',
      illustrationType: _IllType.welcome,
    ),
    _PageData(
      tag: 'SAVE',
      title: 'One Tap,\nFull Metadata',
      subtitle: 'Paste a URL and Recallr auto-fetches the title, image and domain.\nNo typing needed.',
      illustrationType: _IllType.save,
    ),
    _PageData(
      tag: 'ORGANIZE',
      title: 'Everything\nIn Its Place',
      subtitle: 'Collections, tags, and instant search make every saved link easy to find.',
      illustrationType: _IllType.organize,
    ),
    _PageData(
      tag: 'REDISCOVER',
      title: 'Never Forget\nWhat You Saved',
      subtitle: 'Daily streaks and Discover Mode resurface your knowledge when you need it most.',
      illustrationType: _IllType.rediscover,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageCtrl.addListener(_onPageScroll);
  }

  void _onPageScroll() {
    final offset = _pageCtrl.page ?? 0;
    if (offset != _pageOffset) {
      setState(() => _pageOffset = offset);
    }
  }

  Future<void> _complete() async {
    onboardingDone = true; // update in-memory flag BEFORE navigating
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    if (mounted) context.go('/');
  }

  void _next() {
    if (_currentPage < _pages.length - 1) {
      _pageCtrl.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _complete();
    }
  }

  void _onPageChanged(int page) {
    setState(() => _currentPage = page);
    // Re-trigger text entry animation on each page change
    _textEntryCtrl.dispose();
    _textEntryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _textScale = CurvedAnimation(parent: _textEntryCtrl, curve: Curves.easeOutBack);
    _textFade  = CurvedAnimation(parent: _textEntryCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _pageCtrl
      ..removeListener(_onPageScroll)
      ..dispose();
    _idleCtrl.dispose();
    _pulseCtrl.dispose();
    _rotateCtrl.dispose();
    _textEntryCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _currentPage == _pages.length - 1;

    return Scaffold(
      backgroundColor: AppColors.navy900,
      body: Stack(
        children: [
          // ── Animated background canvas ──────────────────────────────────
          Positioned.fill(
            child: _BackgroundCanvas(
              idleAnim:   _idleCtrl,
              rotateAnim: _rotateCtrl,
              pulseAnim:  _pulseCtrl,
              pageOffset: _pageOffset,
            ),
          ),

          // ── Page views ──────────────────────────────────────────────────
          PageView.builder(
            controller: _pageCtrl,
            onPageChanged: _onPageChanged,
            itemCount: _pages.length,
            itemBuilder: (_, i) {
              // distance of this page from current scroll offset
              final dist = (_pageOffset - i).abs().clamp(0.0, 1.0);
              return _PageContent(
                data: _pages[i],
                idleAnim:    _idleCtrl,
                pulseAnim:   _pulseCtrl,
                pageOffset:  _pageOffset,
                pageIndex:   i,
                distFromCenter: dist,
                textScaleAnim: (i == _currentPage) ? _textScale : const AlwaysStoppedAnimation(1.0),
                textFadeAnim:  (i == _currentPage) ? _textFade  : const AlwaysStoppedAnimation(1.0),
              );
            },
          ),

          // ── Bottom controls ─────────────────────────────────────────────
          Positioned(
            left: 0, right: 0, bottom: 0,
            child: _BottomBar(
              currentPage: _currentPage,
              total:       _pages.length,
              isLast:      isLast,
              onNext:      _next,
              onSkip:      _complete,
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Animated background canvas
// ═════════════════════════════════════════════════════════════════════════════

class _BackgroundCanvas extends StatelessWidget {
  const _BackgroundCanvas({
    required this.idleAnim,
    required this.rotateAnim,
    required this.pulseAnim,
    required this.pageOffset,
  });
  final Animation<double> idleAnim;
  final Animation<double> rotateAnim;
  final Animation<double> pulseAnim;
  final double pageOffset;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return AnimatedBuilder(
      animation: Listenable.merge([idleAnim, rotateAnim, pulseAnim]),
      builder: (_, __) {
        final idle   = idleAnim.value;   // 0..1 sine-like
        final rotate = rotateAnim.value; // 0..1 full rotation progress
        final pulse  = pulseAnim.value;  // 0..1 fast pulse

        return Stack(
          children: [
            // ── Dot grid pattern (custom painter) ──────────────────────
            Positioned.fill(
              child: CustomPaint(
                painter: _DotGridPainter(
                  shift:     idle * 18,
                  pageShift: pageOffset * 30,
                  opacity:   0.18,
                ),
              ),
            ),

            // ── Large rotating hex outline top-right ───────────────────
            Positioned(
              top: -60 + idle * 24,
              right: -80,
              child: Transform.rotate(
                angle: rotate * 2 * math.pi,
                child: CustomPaint(
                  size: const Size(280, 280),
                  painter: _HexOutlinePainter(
                    color: AppColors.cyan.withOpacity(0.07 + pulse * 0.04),
                    strokeWidth: 1.2,
                  ),
                ),
              ),
            ),

            // ── Medium rotating hex outline bottom-left ────────────────
            Positioned(
              bottom: 80 + idle * 16,
              left: -100,
              child: Transform.rotate(
                angle: -rotate * 2 * math.pi * 0.7,
                child: CustomPaint(
                  size: const Size(220, 220),
                  painter: _HexOutlinePainter(
                    color: const Color(0xFFA78BFA).withOpacity(0.06 + pulse * 0.03),
                    strokeWidth: 1.0,
                  ),
                ),
              ),
            ),

            // ── Circle outline mid-screen ──────────────────────────────
            Positioned(
              top: size.height * 0.35 - idle * 20,
              left: -50,
              child: _AnimatedRing(
                size: 180,
                color: AppColors.cyan.withOpacity(0.05),
                borderWidth: 1,
              ),
            ),

            // ── Floating orb top-left (scales with idle) ──────────────
            Positioned(
              top: 30 + idle * 14,
              left: -40,
              child: _ScalingOrb(
                size: 200 + idle * 40,
                color: AppColors.cyan.withOpacity(0.055),
              ),
            ),

            // ── Floating orb bottom-right ──────────────────────────────
            Positioned(
              bottom: 60 - idle * 18,
              right: -60,
              child: _ScalingOrb(
                size: 260 + idle * 30,
                color: const Color(0xFF818CF8).withOpacity(0.045),
              ),
            ),

            // ── Small accent orb center-right (fast pulse) ────────────
            Positioned(
              top: size.height * 0.55 + idle * 10,
              right: 10,
              child: _ScalingOrb(
                size: 120 + pulse * 30,
                color: AppColors.cyan.withOpacity(0.035 + pulse * 0.02),
              ),
            ),

            // ── Scattered sparks at fixed positions ───────────────────
            ..._sparkPositions.map((s) => Positioned(
              left:  s.left,
              right: s.right,
              top:   s.top + (s.phase.isEven ? idle * s.travel : -idle * s.travel),
              child: _Spark(color: s.color.withOpacity(0.5 + idle * 0.4), size: s.size),
            )),
          ],
        );
      },
    );
  }

  static const _sparkPositions = [
    _SparkPos(left: 30,   top: 120, size: 5, travel: 14, phase: 0, color: AppColors.cyan),
    _SparkPos(right: 40,  top: 200, size: 4, travel: 10, phase: 1, color: Color(0xFFA78BFA)),
    _SparkPos(left: 80,   top: 320, size: 3, travel: 16, phase: 0, color: Color(0xFF60A5FA)),
    _SparkPos(right: 90,  top: 400, size: 5, travel: 12, phase: 1, color: AppColors.cyan),
    _SparkPos(left: 200,  top: 600, size: 4, travel: 18, phase: 0, color: Color(0xFFA78BFA)),
    _SparkPos(right: 60,  top: 650, size: 3, travel: 8,  phase: 1, color: Color(0xFF34D399)),
    _SparkPos(left: 50,   top: 750, size: 5, travel: 14, phase: 0, color: AppColors.cyan),
  ];
}

class _SparkPos {
  const _SparkPos({
    this.left, this.right, required this.top,
    required this.size, required this.travel,
    required this.phase, required this.color,
  });
  final double? left;
  final double? right;
  final double top;
  final double size;
  final double travel;
  final int phase;
  final Color color;
}

// ── Custom painters ──────────────────────────────────────────────────────────

class _DotGridPainter extends CustomPainter {
  const _DotGridPainter({
    required this.shift,
    required this.pageShift,
    required this.opacity,
  });
  final double shift;
  final double pageShift;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    const spacing = 28.0;
    const dotR    = 1.2;
    final paint   = Paint()..color = AppColors.cyan.withOpacity(opacity);

    final offsetX = (shift + pageShift) % spacing;
    final offsetY = shift % spacing;

    for (double x = -spacing + offsetX; x < size.width + spacing; x += spacing) {
      for (double y = -spacing + offsetY; y < size.height + spacing; y += spacing) {
        canvas.drawCircle(Offset(x, y), dotR, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DotGridPainter old) =>
      old.shift != shift || old.pageShift != pageShift;
}

class _HexOutlinePainter extends CustomPainter {
  const _HexOutlinePainter({required this.color, required this.strokeWidth});
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final cx = size.width / 2;
    final cy = size.height / 2;
    final r  = size.width / 2;

    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = math.pi / 6 + i * math.pi / 3;
      final px = cx + r * math.cos(angle);
      final py = cy + r * math.sin(angle);
      i == 0 ? path.moveTo(px, py) : path.lineTo(px, py);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_HexOutlinePainter old) => old.color != color;
}

// ═════════════════════════════════════════════════════════════════════════════
// Page content
// ═════════════════════════════════════════════════════════════════════════════

class _PageContent extends StatelessWidget {
  const _PageContent({
    required this.data,
    required this.idleAnim,
    required this.pulseAnim,
    required this.pageOffset,
    required this.pageIndex,
    required this.distFromCenter,
    required this.textScaleAnim,
    required this.textFadeAnim,
  });

  final _PageData data;
  final Animation<double> idleAnim;
  final Animation<double> pulseAnim;
  final double pageOffset;
  final int pageIndex;
  final double distFromCenter;
  final Animation<double> textScaleAnim;
  final Animation<double> textFadeAnim;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 0, 28, 160),
      child: Column(
        children: [
          SizedBox(height: MediaQuery.of(context).padding.top + 52),

          // ── Illustration ──────────────────────────────────────────────
          Expanded(
            flex: 5,
            child: Center(
              child: _Illustration(
                type:       data.illustrationType,
                idleAnim:   idleAnim,
                pulseAnim:  pulseAnim,
                pageOffset: pageOffset,
              ),
            ),
          ),

          const SizedBox(height: 36),

          // ── Tag + Title + Subtitle with animated scale ──────────────
          AnimatedBuilder(
            animation: Listenable.merge([textScaleAnim, textFadeAnim]),
            builder: (_, __) {
              final scale   = 0.82 + textScaleAnim.value * 0.18;
              final opacity = (textFadeAnim.value).clamp(0.0, 1.0);
              return Opacity(
                opacity: opacity,
                child: Transform.scale(
                  scale:     scale,
                  alignment: Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tag chip
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color:        AppColors.cyan.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.cyan.withOpacity(0.3)),
                        ),
                        child: Text(
                          data.tag,
                          style: const TextStyle(
                            fontFamily:   'SpaceGrotesk',
                            fontSize:     10,
                            fontWeight:   FontWeight.w700,
                            letterSpacing: 2.4,
                            color:        AppColors.cyan,
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Title
                      Text(
                        data.title,
                        style: const TextStyle(
                          fontFamily:   'SpaceGrotesk',
                          fontSize:     34,
                          fontWeight:   FontWeight.w700,
                          letterSpacing: -0.8,
                          height:       1.1,
                          color:        AppColors.white,
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Subtitle
                      Text(
                        data.subtitle,
                        style: TextStyle(
                          fontFamily: 'SpaceGrotesk',
                          fontSize:   15,
                          fontWeight: FontWeight.w400,
                          height:     1.6,
                          color:      AppColors.white.withOpacity(0.52),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Illustrations
// ═════════════════════════════════════════════════════════════════════════════

class _Illustration extends StatelessWidget {
  const _Illustration({
    required this.type,
    required this.idleAnim,
    required this.pulseAnim,
    required this.pageOffset,
  });
  final _IllType type;
  final Animation<double> idleAnim;
  final Animation<double> pulseAnim;
  final double pageOffset;

  @override
  Widget build(BuildContext context) {
    final asset = switch (type) {
      _IllType.welcome    => 'assets/animations/onboard_welcome.json',
      _IllType.save       => 'assets/animations/onboard_save.json',
      _IllType.organize   => 'assets/animations/onboard_organize.json',
      _IllType.rediscover => 'assets/animations/onboard_discover.json',
    };
    return Lottie.asset(
      asset,
      repeat: true,
      fit: BoxFit.contain,
    );
  }
}

// ── Welcome: "R" with orbital dots that react to page swipe ──────────────────

class _WelcomeIll extends StatelessWidget {
  const _WelcomeIll({
    required this.idleAnim,
    required this.pulseAnim,
    required this.pageOffset,
  });
  final Animation<double> idleAnim;
  final Animation<double> pulseAnim;
  final double pageOffset;

  // 8 orbital dots evenly spaced, with slow idle orbit + swipe scatter
  static const int _dotCount = 8;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([idleAnim, pulseAnim]),
      builder: (_, __) {
        final idle  = idleAnim.value;
        final pulse = pulseAnim.value;

        // How far are we from page 0? (0 = on welcome, 1 = fully on page 1)
        final swipe = pageOffset.clamp(0.0, 1.0);

        // Orbit radius expands as user swipes away
        final orbitR = 100.0 + swipe * 70;

        // Dots scatter outward + rotate as user swipes
        final angleBoost = swipe * math.pi * 0.6;

        // Core glow ring scales with pulse
        final glowSize = 220.0 + pulse * 16;

        return SizedBox(
          width: 300,
          height: 300,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outermost breathing ring
              _AnimatedRing(
                size:        glowSize + 40,
                color:       AppColors.cyan.withOpacity(0.06 + pulse * 0.05),
                borderWidth: 1,
              ),

              // Middle ring
              _AnimatedRing(
                size:        glowSize,
                color:       AppColors.cyan.withOpacity(0.10 + pulse * 0.06),
                borderWidth: 1.2,
              ),

              // Inner ring
              _AnimatedRing(
                size:        170,
                color:       AppColors.cyan.withOpacity(0.18),
                borderWidth: 1.5,
              ),

              // Orbital dots
              ..._buildOrbitalDots(orbitR, idle, angleBoost, swipe),

              // Core logo with animated glow
              Transform.scale(
                scale: 1.0 + idle * 0.04 + pulse * 0.025,
                child: Container(
                  width:  148,
                  height: 148,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(36),
                    boxShadow: [
                      BoxShadow(
                        color:      AppColors.cyan.withOpacity(0.30 + pulse * 0.25),
                        blurRadius: 40 + pulse * 20,
                        spreadRadius: 2 + pulse * 8,
                      ),
                      BoxShadow(
                        color:      const Color(0xFF60A5FA).withOpacity(0.18 + pulse * 0.10),
                        blurRadius: 22,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(36),
                    child: Image.asset(
                      'assets/icons/logo.png',
                      width:  148,
                      height: 148,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildOrbitalDots(
    double radius,
    double idle,
    double angleBoost,
    double swipe,
  ) {
    return List.generate(_dotCount, (i) {
      final baseAngle = (2 * math.pi / _dotCount) * i;
      // Slow orbital drift + swipe-driven angle boost
      final angle = baseAngle + idle * 0.4 + angleBoost;

      final cx = 150.0; // center of 300×300 stack
      final cy = 150.0;

      final x = cx + radius * math.cos(angle) - 5;
      final y = cy + radius * math.sin(angle) - 5;

      // Alternating colors + size varies by index
      final colors = [
        AppColors.cyan,
        const Color(0xFF60A5FA),
        const Color(0xFFA78BFA),
        AppColors.cyan,
        const Color(0xFF60A5FA),
        const Color(0xFF34D399),
        AppColors.cyan,
        const Color(0xFFA78BFA),
      ];
      final dotColor = colors[i % colors.length];
      final dotSize  = i % 3 == 0 ? 7.0 : (i % 3 == 1 ? 5.0 : 4.0);

      // Dots fade slightly as they scatter
      final opacity = (1.0 - swipe * 0.3).clamp(0.5, 1.0);

      return Positioned(
        left: x,
        top:  y,
        child: Opacity(
          opacity: opacity,
          child: Container(
            width:  dotSize,
            height: dotSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: dotColor,
              boxShadow: [
                BoxShadow(
                  color:      dotColor.withOpacity(0.7),
                  blurRadius: dotSize * 2.5,
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

// ── Save illustration ─────────────────────────────────────────────────────────

class _SaveIll extends StatelessWidget {
  const _SaveIll({required this.idleAnim});
  final Animation<double> idleAnim;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: idleAnim,
      builder: (_, __) {
        final t = idleAnim.value;
        return SizedBox(
          width: 300,
          height: 280,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Shadow card
              Positioned(
                top: 18 + t * 8,
                child: _GlassCard(width: 260, height: 80, opacity: 0.3, child: const SizedBox.shrink()),
              ),
              // URL input bar
              Positioned(
                top: 0,
                child: _GlassCard(
                  width: 284,
                  height: 54,
                  child: Row(
                    children: [
                      Container(
                        width: 28, height: 28,
                        decoration: BoxDecoration(
                          color: AppColors.cyan.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.link_rounded, color: AppColors.cyan, size: 16),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'youtube.com/watch?v=dQw4w9WgXcQ',
                          style: TextStyle(
                            fontFamily: 'SpaceGrotesk', fontSize: 11,
                            color: AppColors.white.withOpacity(0.4),
                            overflow: TextOverflow.ellipsis,
                          ),
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Result card floats up on idle
              Positioned(
                bottom: 0 - t * 10,
                child: _GlassCard(
                  width: 284,
                  height: 116,
                  accentBorder: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 42, height: 42,
                            decoration: BoxDecoration(
                              gradient: AppColors.brandGradient,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.play_circle_fill_rounded,
                                color: AppColors.navy900, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Never Gonna Give You Up',
                                  style: TextStyle(
                                    fontFamily: 'SpaceGrotesk', fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.white.withOpacity(0.9),
                                  ),
                                  maxLines: 1, overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'youtube.com',
                                  style: TextStyle(
                                    fontFamily: 'SpaceGrotesk', fontSize: 10,
                                    color: AppColors.cyan.withOpacity(0.8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              gradient: AppColors.brandGradient,
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: const Icon(Icons.bookmark_add_rounded,
                                color: AppColors.navy900, size: 16),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _TagChip(label: 'Music',       color: AppColors.cyan),
                          const SizedBox(width: 6),
                          _TagChip(label: 'Watch Later', color: const Color(0xFFA78BFA)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Organize illustration ─────────────────────────────────────────────────────

class _OrganizeIll extends StatelessWidget {
  const _OrganizeIll({required this.idleAnim});
  final Animation<double> idleAnim;

  static const _collections = [
    ('Design',   Icons.palette_rounded,      Color(0xFFA78BFA)),
    ('Dev',      Icons.code_rounded,          AppColors.cyan),
    ('Articles', Icons.article_rounded,       Color(0xFF34D399)),
    ('Videos',   Icons.play_circle_rounded,   Color(0xFFFBBF24)),
    ('Research', Icons.science_rounded,       Color(0xFF60A5FA)),
    ('Tools',    Icons.build_rounded,         Color(0xFFF87171)),
  ];

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: idleAnim,
      builder: (_, __) {
        final t = idleAnim.value;
        return SizedBox(
          width: 300,
          height: 280,
          child: Column(
            children: [
              Expanded(
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount:  3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing:  10,
                    childAspectRatio: 1.1,
                  ),
                  itemCount: _collections.length,
                  itemBuilder: (_, i) {
                    final (label, icon, color) = _collections[i];
                    // Each tile floats at different phase
                    final phase  = i * math.pi / 3;
                    final offset = math.sin(t * math.pi + phase) * 5;
                    // Also scales slightly
                    final scale  = 1.0 + math.sin(t * math.pi + phase) * 0.03;
                    return Transform.translate(
                      offset: Offset(0, offset),
                      child: Transform.scale(
                        scale: scale,
                        child: _CollectionTile(label: label, icon: icon, color: color),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _TagChip(label: '# flutter', color: AppColors.cyan),
                  const SizedBox(width: 6),
                  _TagChip(label: '# ai',      color: const Color(0xFFA78BFA)),
                  const SizedBox(width: 6),
                  _TagChip(label: '# ux',      color: const Color(0xFF34D399)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Rediscover illustration ───────────────────────────────────────────────────

class _RediscoverIll extends StatelessWidget {
  const _RediscoverIll({required this.idleAnim, required this.pulseAnim});
  final Animation<double> idleAnim;
  final Animation<double> pulseAnim;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([idleAnim, pulseAnim]),
      builder: (_, __) {
        final t     = idleAnim.value;
        final pulse = pulseAnim.value;
        return SizedBox(
          width: 300,
          height: 280,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Streak card (top, floats)
              Positioned(
                top: 0 + t * 6,
                child: _GlassCard(
                  width: 284,
                  height: 74,
                  child: Row(
                    children: [
                      Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFBBF24).withOpacity(0.14),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(child: Text('🔥', style: TextStyle(fontSize: 24))),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment:  MainAxisAlignment.center,
                        children: [
                          Text(
                            '12 Day Streak',
                            style: TextStyle(
                              fontFamily: 'SpaceGrotesk', fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.white.withOpacity(0.9),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Best: 21 days',
                            style: TextStyle(
                              fontFamily: 'SpaceGrotesk', fontSize: 11,
                              color: AppColors.white.withOpacity(0.38),
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Row(
                        children: List.generate(7, (i) => Container(
                          margin: const EdgeInsets.only(left: 3),
                          width: 8, height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: i < 5
                                ? const Color(0xFFFBBF24)
                                : AppColors.white.withOpacity(0.12),
                          ),
                        )),
                      ),
                    ],
                  ),
                ),
              ),

              // Rediscover card (bottom, pulsing border)
              Positioned(
                bottom: 0 - t * 6,
                child: Container(
                  width: 284,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFFBBF24).withOpacity(0.18 + pulse * 0.22),
                      width: 1,
                    ),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end:   Alignment.bottomRight,
                      colors: [Color(0x1AFBBF24), Color(0x0DA78BFA)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color:      const Color(0xFFFBBF24).withOpacity(0.06 + pulse * 0.06),
                        blurRadius: 24,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFBBF24), Color(0xFFF87171)],
                          ),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: const Icon(Icons.auto_awesome_rounded,
                            color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'REDISCOVER',
                              style: TextStyle(
                                fontFamily: 'SpaceGrotesk', fontSize: 9,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.8,
                                color: const Color(0xFFFBBF24).withOpacity(0.9),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Saved 30 days ago',
                              style: TextStyle(
                                fontFamily: 'SpaceGrotesk', fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.white.withOpacity(0.85),
                              ),
                            ),
                            Text(
                              'The Future of AI Design Systems',
                              style: TextStyle(
                                fontFamily: 'SpaceGrotesk', fontSize: 11,
                                color: AppColors.white.withOpacity(0.44),
                                overflow: TextOverflow.ellipsis,
                              ),
                              maxLines: 1,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Bottom bar
// ═════════════════════════════════════════════════════════════════════════════

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.currentPage,
    required this.total,
    required this.isLast,
    required this.onNext,
    required this.onSkip,
  });
  final int currentPage;
  final int total;
  final bool isLast;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: EdgeInsets.fromLTRB(
            28, 20, 28, 20 + MediaQuery.of(context).padding.bottom,
          ),
          decoration: BoxDecoration(
            color:  AppColors.navy900.withOpacity(0.72),
            border: Border(top: BorderSide(color: AppColors.white.withOpacity(0.06))),
          ),
          child: Row(
            children: [
              // Dot indicators (pill for active, small circle for inactive)
              Row(
                children: List.generate(total, (i) {
                  final active = i == currentPage;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 320),
                    curve:    Curves.easeInOutCubic,
                    margin:   const EdgeInsets.only(right: 6),
                    width:    active ? 26 : 7,
                    height:   7,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: active
                          ? AppColors.cyan
                          : AppColors.white.withOpacity(0.18),
                    ),
                  );
                }),
              ),

              const Spacer(),

              // Skip (hidden on last page)
              if (!isLast) ...[
                GestureDetector(
                  onTap: onSkip,
                  child: Text(
                    'Skip',
                    style: TextStyle(
                      fontFamily: 'SpaceGrotesk',
                      fontSize:   14,
                      fontWeight: FontWeight.w500,
                      color:      AppColors.white.withOpacity(0.36),
                    ),
                  ),
                ),
                const SizedBox(width: 18),
              ],

              // Next → `>` icon only  |  last page → "Get Started"
              GestureDetector(
                onTap: onNext,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 350),
                  width:    isLast ? null : 38,
                  height:   38,
                  padding:  isLast
                      ? const EdgeInsets.symmetric(horizontal: 16, vertical: 0)
                      : EdgeInsets.zero,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.cyan, Color(0xFF60A5FA)],
                    ),
                    borderRadius: BorderRadius.circular(11),
                    boxShadow: [
                      BoxShadow(
                        color:      AppColors.cyan.withOpacity(0.28),
                        blurRadius: 12,
                        offset:     const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Center(
                    child: isLast
                        ? const Text(
                            'Get Started',
                            style: TextStyle(
                              fontFamily:   'SpaceGrotesk',
                              fontSize:     12,
                              fontWeight:   FontWeight.w700,
                              color:        AppColors.navy900,
                              letterSpacing: 0.2,
                            ),
                          )
                        : const Icon(
                            Icons.chevron_right_rounded,
                            color: AppColors.navy900,
                            size:  20,
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Shared sub-widgets
// ═════════════════════════════════════════════════════════════════════════════

class _AnimatedRing extends StatelessWidget {
  const _AnimatedRing({required this.size, required this.color, required this.borderWidth});
  final double size;
  final Color color;
  final double borderWidth;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: borderWidth),
      ),
    );
  }
}

class _ScalingOrb extends StatelessWidget {
  const _ScalingOrb({required this.size, required this.color});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({
    required this.width,
    required this.height,
    required this.child,
    this.opacity = 1.0,
    this.accentBorder = false,
  });
  final double width;
  final double height;
  final Widget child;
  final double opacity;
  final bool accentBorder;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: Container(
        width: width, height: height,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.navy700.withOpacity(0.88),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: accentBorder
                ? AppColors.cyan.withOpacity(0.3)
                : AppColors.white.withOpacity(0.08),
          ),
          boxShadow: [
            BoxShadow(
              color:      Colors.black.withOpacity(0.28),
              blurRadius: 20,
              offset:     const Offset(0, 8),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color:        color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'SpaceGrotesk',
          fontSize:   11,
          fontWeight: FontWeight.w600,
          color:      color.withOpacity(0.9),
        ),
      ),
    );
  }
}

class _CollectionTile extends StatelessWidget {
  const _CollectionTile({required this.label, required this.icon, required this.color});
  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color:        AppColors.navy700.withOpacity(0.9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.white.withOpacity(0.07)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'SpaceGrotesk',
              fontSize:   10,
              fontWeight: FontWeight.w600,
              color:      AppColors.white.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}

class _Spark extends StatelessWidget {
  const _Spark({required this.color, required this.size});
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [BoxShadow(color: color.withOpacity(0.55), blurRadius: size * 2.2)],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Data types
// ═════════════════════════════════════════════════════════════════════════════

enum _IllType { welcome, save, organize, rediscover }

class _PageData {
  const _PageData({
    required this.tag,
    required this.title,
    required this.subtitle,
    required this.illustrationType,
  });
  final String tag;
  final String title;
  final String subtitle;
  final _IllType illustrationType;
}
