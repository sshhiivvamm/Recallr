import 'package:flutter/material.dart';

class AppFilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;
  final dynamic c;
  final TextTheme theme;

  const AppFilterChip({
    super.key,
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
    required this.c,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? c.accent : c.textSecondary;

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: active ? c.accentDim : c.surfaceElevated,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? c.accent : c.border,
            width: active ? 1 : 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: theme.labelSmall!.copyWith(
                color: color,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── CLEAR CHIP ─────────────────────────────

class ClearChip extends StatelessWidget {
  final int count;
  final VoidCallback onTap;
  final dynamic c;
  final TextTheme theme;

  const ClearChip({
    super.key,
    required this.count,
    required this.onTap,
    required this.c,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: c.coralDim,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: c.coral, width: 0.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.close_rounded, size: 12, color: c.coral),
            const SizedBox(width: 4),
            Text(
              'Clear $count',
              style: theme.labelSmall!.copyWith(
                color: c.coral,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── VIEW TOGGLE ────────────────────────────

class ViewToggleBtn extends StatelessWidget {
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final dynamic c;

  const ViewToggleBtn({
    super.key,
    required this.icon,
    required this.selected,
    required this.onTap,
    required this.c,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(7),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: selected ? c.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Icon(
          icon,
          size: 15,
          color: selected ? c.background : c.textSecondary,
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final dynamic c;
  final TextTheme theme;

  const EmptyState({
    super.key,
    required this.c,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: c.surfaceElevated,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.bookmark_border_rounded,
              size: 28,
              color: c.textHint,
            ),
          ),
          const SizedBox(height: 16),

          // 🧠 TITLE
          Text(
            'Start building your library',
            style: theme.titleMedium!.copyWith(
              fontWeight: FontWeight.w600,
              color: c.textPrimary,
            ),
          ),

          const SizedBox(height: 6),

          // 💬 MEANINGFUL TEXT
          Text(
            'Save links, articles, and ideas you want to revisit — all in one place.',
            style: theme.bodySmall!.copyWith(
              color: c.textHint,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 12),

          // 🚀 CTA (very important)
          Text(
            'Tap + to save your first link',
            style: theme.labelSmall!.copyWith(
              color: c.accent,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}


class SkeletonCard extends StatelessWidget {
  final dynamic c;

  const SkeletonCard({super.key, required this.c});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.border, width: 0.5),
      ),
      child: Row(
        children: [
          _bone(32, 32, 8),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _bone(double.infinity, 12, 4),
                const SizedBox(height: 6),
                _bone(120, 10, 4),
                const SizedBox(height: 8),
                _bone(double.infinity, 10, 4),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bone(double w, double h, double r) {
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: c.surfaceElevated,
        borderRadius: BorderRadius.circular(r),
      ),
    );
  }
}