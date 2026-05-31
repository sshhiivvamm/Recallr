import 'package:flutter/material.dart';

/// Knowledge Vault — Color System

/// Usage:
///   AppColors.cyan          → raw Color value (use anywhere)
///   AppColors.of(context)   → theme-aware ColorScheme extension
///   context.colors          → shorthand via BuildContext extension
abstract class AppColors {
  AppColors._();

  // ─────────────────────────────────────────────
  // RAW PALETTE (theme-independent)
  // ─────────────────────────────────────────────

  /// Deep navy · Primary background (dark)
  static const Color navy900 = Color(0xFF0F172A);

  /// Slate · Surface / card background (dark)
  static const Color navy700 = Color(0xFF1E293B);

  /// Deep ocean · Elevated surface (dark)
  static const Color navy800 = Color(0xFF162032);

  /// Cyan · Primary accent · Interactive elements
  static const Color cyan = Color(0xFF38BDF8);

  /// Soft white · Primary text (dark mode)
  static const Color white = Color(0xFFF8FAFC);

  /// Emerald · Success / positive / AI actions
  static const Color green = Color(0xFF34D399);

  /// Violet · Tags / categories / chips
  static const Color purple = Color(0xFFA78BFA);

  /// Amber · Warnings / rediscover / highlights
  static const Color amber = Color(0xFFFBBF24);

  /// Coral · Error / destructive actions
  static const Color coral = Color(0xFFF87171);

  // ─── Derived alphas ───
  static const Color cyan10 = Color(0x1A38BDF8);   // 10%
  static const Color cyan15 = Color(0x2638BDF8);   // 15%
  static const Color cyan20 = Color(0x3338BDF8);   // 20%
  static const Color cyan30 = Color(0x4D38BDF8);   // 30%

  static const Color green10 = Color(0x1A34D399);
  static const Color purple10 = Color(0x1AA78BFA);
  static const Color amber10 = Color(0x1AFBBF24);
  static const Color coral10 = Color(0x1AF87171);

  // ─── Light-mode surfaces ───
  static const Color lightBg         = Color(0xFFF8FAFC); // page background
  static const Color lightSurface    = Color(0xFFFFFFFF); // cards
  static const Color lightSurface2   = Color(0xFFF1F5F9); // elevated cards
  static const Color lightBorder     = Color(0xFFE2E8F0); // subtle borders
  static const Color lightBorderSoft = Color(0xFFCBD5E1); // stronger borders

  // ─── Dark-mode surfaces ───
  static const Color darkBg          = navy900;            // page background
  static const Color darkSurface     = navy700;            // cards
  static const Color darkSurface2    = navy800;            // elevated cards
  static const Color darkBorder      = Color(0x1AFFFFFF);  // 10% white
  static const Color darkBorderSoft  = Color(0x26FFFFFF);  // 15% white

  // ─── Text scales ───
  static const Color darkText1  = white;                   // primary
  static const Color darkText2  = Color(0x99F8FAFC);       // 60% — secondary
  static const Color darkText3  = Color(0x4DF8FAFC);       // 30% — hints/caps

  static const Color lightText1 = Color(0xFF0F172A);       // primary
  static const Color lightText2 = Color(0xFF64748B);       // secondary
  static const Color lightText3 = Color(0xFF94A3B8);       // hints/caps

  // ─────────────────────────────────────────────
  // GRADIENTS
  // ─────────────────────────────────────────────

  /// Primary brand gradient · buttons, FAB, hero accents
  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [cyan, Color(0xFF60A5FA)], // cyan → blue-400
  );

  /// Rediscover banner gradient · gold shimmer surface
  static const LinearGradient rediscoverGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0x1AFBBF24), Color(0x0DA78BFA)], // amber → purple, both low opacity
  );

  /// Card inner glow · top-left accent on glassmorphic cards
  static const LinearGradient cardGlowGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0x0A38BDF8), Colors.transparent],
  );

  /// Avatar / category icon background
  static const LinearGradient avatarGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [cyan, Color(0xFF818CF8)], // cyan → indigo-400
  );

  // ─────────────────────────────────────────────
  // THEME-AWARE HELPER
  // ─────────────────────────────────────────────

  /// Returns [AppColorScheme] for the current brightness.
  static AppColorScheme of(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? AppColorScheme.dark() : AppColorScheme.light();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AppColorScheme — Semantic tokens (brightness-aware)
// ─────────────────────────────────────────────────────────────────────────────

/// Semantic color tokens that resolve to the correct value
/// for dark or light mode automatically.
///
/// Example:
///   final c = AppColors.of(context);
///   Container(color: c.surface)
///   Text('hello', style: TextStyle(color: c.textPrimary))
class AppColorScheme {
  const AppColorScheme._({
    required this.isDark,
    required this.background,
    required this.surface,
    required this.surfaceElevated,
    required this.border,
    required this.borderSoft,
    required this.textPrimary,
    required this.textSecondary,
    required this.textHint,
    required this.accent,
    required this.accentDim,
    required this.accentBorder,
    required this.green,
    required this.greenDim,
    required this.purple,
    required this.purpleDim,
    required this.amber,
    required this.amberDim,
    required this.coral,
    required this.coralDim,
    required this.inputFill,
    required this.inputBorder,
    required this.inputBorderFocused,
    required this.navBackground,
    required this.shimmerBase,
    required this.shimmerHighlight,
  });

  final bool isDark;

  // ── Surfaces ──
  final Color background;
  final Color surface;
  final Color surfaceElevated;
  final Color border;
  final Color borderSoft;

  // ── Text ──
  final Color textPrimary;
  final Color textSecondary;
  final Color textHint;

  // ── Accent (cyan) ──
  final Color accent;
  final Color accentDim;
  final Color accentBorder;

  // ── Semantic colors ──
  final Color green;
  final Color greenDim;
  final Color purple;
  final Color purpleDim;
  final Color amber;
  final Color amberDim;
  final Color coral;
  final Color coralDim;

  // ── Form controls ──
  final Color inputFill;
  final Color inputBorder;
  final Color inputBorderFocused;

  // ── Navigation ──
  final Color navBackground;

  // ── Shimmer / skeleton ──
  final Color shimmerBase;
  final Color shimmerHighlight;

  // ─── Dark mode ──────────────────────────────
  factory AppColorScheme.dark() => const AppColorScheme._(
    isDark: true,
    background:       AppColors.darkBg,
    surface:          AppColors.darkSurface,
    surfaceElevated:  AppColors.darkSurface2,
    border:           AppColors.darkBorder,
    borderSoft:       AppColors.darkBorderSoft,
    textPrimary:      AppColors.darkText1,
    textSecondary:    AppColors.darkText2,
    textHint:         AppColors.darkText3,
    accent:           AppColors.cyan,
    accentDim:        AppColors.cyan10,
    accentBorder:     AppColors.cyan20,
    green:            AppColors.green,
    greenDim:         AppColors.green10,
    purple:           AppColors.purple,
    purpleDim:        AppColors.purple10,
    amber:            AppColors.amber,
    amberDim:         AppColors.amber10,
    coral:            AppColors.coral,
    coralDim:         AppColors.coral10,
    inputFill:        AppColors.darkSurface,
    inputBorder:      AppColors.darkBorderSoft,
    inputBorderFocused: AppColors.cyan30,
    navBackground:    Color(0xF20F172A), // 95% navy
    shimmerBase:      Color(0xFF1E293B),
    shimmerHighlight: Color(0xFF2D3F55),
  );

  // ─── Light mode ─────────────────────────────
  factory AppColorScheme.light() => const AppColorScheme._(
    isDark: false,
    background:       AppColors.lightBg,
    surface:          AppColors.lightSurface,
    surfaceElevated:  AppColors.lightSurface2,
    border:           AppColors.lightBorder,
    borderSoft:       AppColors.lightBorderSoft,
    textPrimary:      AppColors.lightText1,
    textSecondary:    AppColors.lightText2,
    textHint:         AppColors.lightText3,
    accent:           Color(0xFF0EA5E9),  // sky-500 (more readable on white)
    accentDim:        Color(0x0F0EA5E9),
    accentBorder:     Color(0x290EA5E9),
    green:            Color(0xFF059669),  // emerald-600 (accessible on white)
    greenDim:         Color(0x0F059669),
    purple:           Color(0xFF7C3AED),  // violet-600
    purpleDim:        Color(0x0F7C3AED),
    amber:            Color(0xFFD97706),  // amber-600
    amberDim:         Color(0x0FD97706),
    coral:            Color(0xFFDC2626),  // red-600
    coralDim:         Color(0x0FDC2626),
    inputFill:        AppColors.lightSurface2,
    inputBorder:      AppColors.lightBorder,
    inputBorderFocused: Color(0x660EA5E9),
    navBackground:    Color(0xFAFFFFFF), // 98% white
    shimmerBase:      Color(0xFFE2E8F0),
    shimmerHighlight: Color(0xFFF8FAFC),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// BuildContext extension — convenience shorthand
// ─────────────────────────────────────────────────────────────────────────────

extension AppColorsContext on BuildContext {
  /// Shorthand: `context.colors.surface`
  AppColorScheme get colors => AppColors.of(this);

  /// Shorthand: `context.isDark`
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}