import 'package:flutter/material.dart';

/// Signature for opening a bottom sheet.
typedef SheetOpener = Future<void> Function(
  BuildContext context, {
  required ValueChanged<double> onSheetTopY,
  required ValueChanged<Animation<double>> onSheetAnimation,
});

/// Wraps any page and overlays an animated FAB that:
/// - Opens a bottom sheet on tap
/// - Rotates into a × while the sheet is open
/// - Tracks the sheet's top edge while opening
/// - On close: detaches from sheet and drops to nav bar with a bounce
class SheetFabHost extends StatefulWidget {
  final Widget child;
  final SheetOpener openSheet;
  final String heroTag;

  const SheetFabHost({
    super.key,
    required this.child,
    required this.openSheet,
    this.heroTag = 'sheet_fab',
  });

  @override
  State<SheetFabHost> createState() => _SheetFabHostState();
}

class _SheetFabHostState extends State<SheetFabHost>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fabAnim;
  late final Animation<double> _fabSlide;
  late final Animation<double> _fabSpin;
  OverlayEntry? _fabEntry;
  bool _isOpen = false;
  double? _sheetTopY;
  Animation<double>? _routeAnim;

  // Listener reference so we can cleanly detach it
  void Function(AnimationStatus)? _routeStatusListener;

  @override
  void initState() {
    super.initState();
    _fabAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      reverseDuration: const Duration(milliseconds: 600),
    );
    _fabSlide = CurvedAnimation(
      parent: _fabAnim,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.bounceIn,
    );
    _fabSpin = CurvedAnimation(
      parent: _fabAnim,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeIn,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _insertFab());
  }

  void _insertFab() {
    if (!mounted) return;
    _fabEntry = OverlayEntry(builder: _buildFab);
    Overlay.of(context).insert(_fabEntry!);
  }

  @override
  void dispose() {
    _clearRouteAnim();
    _fabEntry?.remove();
    _fabEntry = null;
    _fabAnim.dispose();
    super.dispose();
  }

  void _clearRouteAnim() {
    if (_routeStatusListener != null) {
      _routeAnim?.removeStatusListener(_routeStatusListener!);
      _routeStatusListener = null;
    }
    _routeAnim = null;
  }

  /// Called when the route animation starts reversing (sheet is closing).
  /// Detaches from route tracking and starts the bounce-drop animation.
  void _onRoutReverse(AnimationStatus status) {
    if (status != AnimationStatus.reverse) return;
    _clearRouteAnim();
    _fabEntry?.markNeedsBuild();
    // Drop with bounce effect — runs concurrently with sheet close
    if (mounted) _fabAnim.reverse();
  }

  Future<void> _openSheet() async {
    if (_isOpen) return;
    setState(() => _isOpen = true);
    _fabEntry?.markNeedsBuild();

    _sheetTopY = null;
    _clearRouteAnim();
    _fabAnim.forward();

    final sheetFuture = widget.openSheet(
      context,
      onSheetTopY: (y) {
        _sheetTopY = y;
        _fabEntry?.markNeedsBuild();
      },
      onSheetAnimation: (anim) {
        _routeAnim = anim;
        _routeStatusListener = _onRoutReverse;
        _routeAnim!.addStatusListener(_routeStatusListener!);
        _fabEntry?.markNeedsBuild();
      },
    );

    // Reinsert overlay on top of the modal after it's pushed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _fabEntry?.remove();
        _fabEntry = OverlayEntry(builder: _buildFab);
        Overlay.of(context).insert(_fabEntry!);
      });
    });

    await sheetFuture;

    // Sheet fully dismissed — ensure route tracking is cleared and
    // bounce-drop animation has finished (or start it if sheet was
    // dismissed without going through reverse status, e.g. programmatic pop)
    _clearRouteAnim();
    _sheetTopY = null;
    if (mounted) {
      await _fabAnim.reverse(); // no-op if already at 0, waits if still bouncing
      if (mounted) {
        setState(() => _isOpen = false);
        _fabEntry?.markNeedsBuild();
      }
    }
  }

  Widget _buildFab(BuildContext ctx) {
    final Listenable listenable = _routeAnim != null
        ? Listenable.merge([_fabAnim, _routeAnim!])
        : _fabAnim;
    return AnimatedBuilder(
      animation: listenable,
      builder: (c, _) {
        final media = MediaQuery.of(c);
        final screenH = media.size.height;
        final baseBottom =
            media.padding.bottom + kBottomNavigationBarHeight + 16.0;

        const fabRadius = 20.0;
        double bottom;
        final scale = 1.0 - 0.28 * _fabSlide.value;

        if (_isOpen && _sheetTopY != null && _routeAnim != null) {
          // Track sheet edge exactly as it slides in (opening only).
          // BottomSheet: sheetTop(t) = screenH + (_sheetTopY - screenH) * t
          final currentTopY =
              screenH + (_sheetTopY! - screenH) * _routeAnim!.value;
          bottom = screenH - currentTopY - fabRadius;
        } else if (_isOpen) {
          // Fallback before route anim arrives OR during the bounce-drop
          // (_fabAnim is reversing, _routeAnim is null)
          bottom = baseBottom + screenH * 0.50 * _fabSlide.value;
        } else {
          bottom = baseBottom;
        }

        return Positioned(
          right: 20,
          bottom: bottom,
          child: Transform.scale(
            scale: scale,
            alignment: Alignment.bottomRight,
            child: FloatingActionButton(
              heroTag: widget.heroTag,
              onPressed: _isOpen ? () => Navigator.of(c).pop() : _openSheet,
              shape: const CircleBorder(),
              child: Transform.rotate(
                angle: _fabSpin.value * 0.7853981633,
                child: const Icon(Icons.add),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Mixin for sheet widgets to report their size + route animation to [SheetFabHost].
mixin SheetFabReporter<T extends StatefulWidget> on State<T> {
  ValueChanged<double>? get onSheetTopY;
  ValueChanged<Animation<double>>? get onSheetAnimation;

  @override
  void initState() {
    super.initState();
    if (onSheetTopY != null || onSheetAnimation != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final box = context.findRenderObject() as RenderBox?;
        if (box != null && onSheetTopY != null) {
          final screenH = MediaQuery.of(context).size.height;
          onSheetTopY!.call(screenH - box.size.height);
        }
        final anim = ModalRoute.of(context)?.animation;
        if (anim != null) onSheetAnimation?.call(anim);
      });
    }
  }
}
