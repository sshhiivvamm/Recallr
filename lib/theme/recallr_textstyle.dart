import 'package:flutter/material.dart';
import'package:google_fonts/google_fonts.dart';

/// Knowledge Vault — Typography System
/// Typeface: Space Grotesk (Google Fonts)
/// Scale: H1/700 · H2/600 · H3/500 · Body/400 · Caption/600

abstract class AppTypography {
  AppTypography._();

  static const String _fontFamily = 'SpaceGrotesk';

  // ─────────────────────────────────────────────
  // TYPE SCALE
  // ─────────────────────────────────────────────

  /// H1 · Display · 32px / 700 · tracking -0.02em
  static final TextStyle h1 = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.64, // -0.02em × 32
    height: 1.15,
  );

  /// H2 · Headline · 24px / 600 · tracking -0.01em
  static const TextStyle h2 = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.24, // -0.01em × 24
    height: 1.2,
  );

  /// H3 · Title · 18px / 500
  static const TextStyle h3 = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
    height: 1.3,
  );

  /// Body · Regular · 14px / 400 · leading 1.5
  static const TextStyle body = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.5,
  );

  /// Body small · 12px / 400
  static const TextStyle bodySmall = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.5,
  );

  /// Caption · Tag / Label · 12px / 600 · tracking +0.05em · UPPERCASE
  static const TextStyle caption = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.6, // 0.05em × 12
    height: 1.0,
  );

  // ─────────────────────────────────────────────
  // COMPONENT SHORTCUTS
  // ─────────────────────────────────────────────

  /// Card title — H3 weight, slightly tighter
  static const TextStyle cardTitle = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.1,
    height: 1.35,
  );

  /// Card summary / body copy on cards
  static const TextStyle cardBody = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w300,
    letterSpacing: 0,
    height: 1.5,
  );

  /// Platform badge / tag pill text
  static const TextStyle badge = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.2,
    height: 1.0,
  );

  /// Screen greeting (e.g. "Good morning")
  static const TextStyle greeting = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.0,
  );

  /// Section label (all-caps tiny header)
  static const TextStyle sectionLabel = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 10,
    fontWeight: FontWeight.w600,
    letterSpacing: 2.0,
    height: 1.0,
  );

  /// Input field text
  static const TextStyle input = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.4,
  );

  /// Button label
  static const TextStyle button = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.2,
    height: 1.0,
  );

  /// Chat message text
  static const TextStyle chatMessage = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.5,
  );
}