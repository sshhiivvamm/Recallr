import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:recallr/theme/recallr_colors.dart';
import 'package:recallr/theme/recallr_textstyle.dart';

/// Knowledge Vault — ThemeData factory
/// Call AppTheme.dark() or AppTheme.light() in MaterialApp.
///
/// Example:
///   MaterialApp(
///     theme: AppTheme.light(),
///     darkTheme: AppTheme.dark(),
///     themeMode: ThemeMode.system,
///   )
abstract class AppTheme {
  AppTheme._();

  // ─────────────────────────────────────────────
  // PUBLIC FACTORIES
  // ─────────────────────────────────────────────

  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData light() => _build(Brightness.light);

  // ─────────────────────────────────────────────
  // CORE BUILDER
  // ─────────────────────────────────────────────

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final c = isDark ? AppColorScheme.dark() : AppColorScheme.light();

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: c.accent,
      onPrimary: isDark ? AppColors.navy900 : Colors.white,
      primaryContainer: c.accentDim,
      onPrimaryContainer: c.accent,
      secondary: c.purple,
      onSecondary: isDark ? AppColors.navy900 : Colors.white,
      secondaryContainer: c.purpleDim,
      onSecondaryContainer: c.purple,
      tertiary: c.green,
      onTertiary: isDark ? AppColors.navy900 : Colors.white,
      tertiaryContainer: c.greenDim,
      onTertiaryContainer: c.green,
      error: c.coral,
      onError: isDark ? AppColors.navy900 : Colors.white,
      errorContainer: c.coralDim,
      onErrorContainer: c.coral,
      surface: c.surface,
      onSurface: c.textPrimary,
      onSurfaceVariant: c.textSecondary,
      outline: c.border,
      outlineVariant: c.borderSoft,
      surfaceContainerHighest: c.surfaceElevated,
      surfaceContainerHigh: c.surfaceElevated,
      surfaceContainer: c.surface,
      surfaceContainerLow: c.background,
      surfaceContainerLowest: c.background,
    );

    // ── Status bar style ──
    final systemOverlayStyle = isDark
        ? SystemUiOverlayStyle.light.copyWith(
            statusBarColor: Colors.transparent,
            systemNavigationBarColor: c.navBackground,
          )
        : SystemUiOverlayStyle.dark.copyWith(
            statusBarColor: Colors.transparent,
            systemNavigationBarColor: c.navBackground,
          );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: c.background,
      fontFamily: 'SpaceGrotesk',

      // ── AppBar ──────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: c.background,
        foregroundColor: c.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: systemOverlayStyle,
        titleTextStyle: AppTypography.h3.copyWith(color: c.textPrimary),
        iconTheme: IconThemeData(color: c.textSecondary, size: 22),
      ),

      // ── Bottom nav bar ──────────────────────
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: c.navBackground,
        selectedItemColor: c.accent,
        unselectedItemColor: c.textHint,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: AppTypography.badge.copyWith(
          color: c.accent,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: AppTypography.badge.copyWith(color: c.textHint),
      ),

      // ── NavigationBar (M3) ───────────────────
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: c.navBackground,
        indicatorColor: c.accentDim,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: c.accent, size: 22);
          }
          return IconThemeData(color: c.textHint, size: 22);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppTypography.badge.copyWith(
              color: c.accent,
              fontWeight: FontWeight.w600,
            );
          }
          return AppTypography.badge.copyWith(color: c.textHint);
        }),
        elevation: 0,
        height: 64,
      ),

      // ── Cards ───────────────────────────────
      // cardTheme: CardTheme(
      //   color:        c.surface,
      //   elevation:    0,
      //   shape: RoundedRectangleBorder(
      //     borderRadius: BorderRadius.circular(14),
      //     side: BorderSide(color: c.border, width: 0.5),
      //   ),
      //   margin: const EdgeInsets.all(0),
      //   clipBehavior: Clip.antiAlias,
      // ),

      // ── ElevatedButton (primary CTA) ────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) return c.border;
            return c.accent;
          }),
          foregroundColor: WidgetStateProperty.all(
            isDark ? AppColors.navy900 : Colors.white,
          ),
          overlayColor: WidgetStateProperty.all(Colors.white.withOpacity(0.1)),
          elevation: WidgetStateProperty.all(0),
          shadowColor: WidgetStateProperty.all(Colors.transparent),
          textStyle: WidgetStateProperty.all(AppTypography.button),
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          ),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          minimumSize: WidgetStateProperty.all(const Size(double.infinity, 48)),
        ),
      ),

      // ── OutlinedButton (secondary) ──────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.all(c.textPrimary),
          side: WidgetStateProperty.all(
            BorderSide(color: c.borderSoft, width: 0.5),
          ),
          textStyle: WidgetStateProperty.all(
            AppTypography.button.copyWith(fontWeight: FontWeight.w500),
          ),
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          overlayColor: WidgetStateProperty.all(c.border),
        ),
      ),

      // ── TextButton ──────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.all(c.accent),
          textStyle: WidgetStateProperty.all(
            AppTypography.body.copyWith(fontWeight: FontWeight.w500),
          ),
          overlayColor: WidgetStateProperty.all(c.accentDim),
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
      ),

      // ── FAB ─────────────────────────────────
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: c.accent,
        foregroundColor: isDark ? AppColors.navy900 : Colors.white,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),

      // ── Input / TextField ───────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.inputFill,
        hintStyle: AppTypography.input.copyWith(color: c.textHint),
        labelStyle: AppTypography.caption.copyWith(color: c.textSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: c.inputBorder, width: 0.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: c.inputBorder, width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: c.accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: c.coral, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
      ),

      // ── Chip (category pills) ───────────────
      chipTheme: ChipThemeData(
        backgroundColor: c.surfaceElevated,
        selectedColor: c.accentDim,
        disabledColor: c.border,
        labelStyle: AppTypography.badge.copyWith(color: c.textSecondary),
        secondaryLabelStyle: AppTypography.badge.copyWith(color: c.accent),
        side: BorderSide(color: c.border, width: 0.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        elevation: 0,
      ),

      // ── Divider ─────────────────────────────
      dividerTheme: DividerThemeData(color: c.border, thickness: 0.5, space: 0),

      // ── ListTile ────────────────────────────
      listTileTheme: ListTileThemeData(
        tileColor: Colors.transparent,
        titleTextStyle: AppTypography.body.copyWith(color: c.textPrimary),
        subtitleTextStyle: AppTypography.bodySmall.copyWith(
          color: c.textSecondary,
        ),
        iconColor: c.textSecondary,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),

      // ── Icon ────────────────────────────────
      iconTheme: IconThemeData(color: c.textSecondary, size: 22),

      // ── Text ────────────────────────────────
      textTheme: TextTheme(
        displayLarge: AppTypography.h1.copyWith(color: c.textPrimary),
        displayMedium: AppTypography.h1.copyWith(
          color: c.textPrimary,
          fontSize: 28,
        ),
        displaySmall: AppTypography.h1.copyWith(
          color: c.textPrimary,
          fontSize: 24,
        ),
        headlineLarge: AppTypography.h2.copyWith(color: c.textPrimary),
        headlineMedium: AppTypography.h2.copyWith(
          color: c.textPrimary,
          fontSize: 20,
        ),
        headlineSmall: AppTypography.h3.copyWith(color: c.textPrimary),
        titleLarge: AppTypography.h3.copyWith(color: c.textPrimary),
        titleMedium: AppTypography.body.copyWith(
          color: c.textPrimary,
          fontWeight: FontWeight.w500,
        ),
        titleSmall: AppTypography.bodySmall.copyWith(
          color: c.textPrimary,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: AppTypography.body.copyWith(color: c.textPrimary),
        bodyMedium: AppTypography.body.copyWith(color: c.textSecondary),
        bodySmall: AppTypography.bodySmall.copyWith(color: c.textSecondary),
        labelLarge: AppTypography.button.copyWith(color: c.textPrimary),
        labelMedium: AppTypography.caption.copyWith(color: c.textSecondary),
        labelSmall: AppTypography.sectionLabel.copyWith(color: c.textHint),
      ),

      // ── SnackBar ────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? AppColors.navy700 : AppColors.navy900,
        contentTextStyle: AppTypography.body.copyWith(color: AppColors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        behavior: SnackBarBehavior.floating,
        elevation: 0,
      ),

      // ── BottomSheet ─────────────────────────
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        dragHandleColor: c.borderSoft,
        dragHandleSize: const Size(40, 4),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        elevation: 0,
        showDragHandle: true,
        modalBarrierColor: Colors.black.withOpacity(0.5),
      ),

      // ── Dialog ──────────────────────────────
      // dialogTheme: DialogTheme(
      //   backgroundColor:  c.surface,
      //   surfaceTintColor: Colors.transparent,
      //   elevation:        0,
      //   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      //   titleTextStyle: AppTypography.h3.copyWith(color: c.textPrimary),
      //   contentTextStyle: AppTypography.body.copyWith(color: c.textSecondary),
      // ),

      // ── Switch ──────────────────────────────
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return c.accent;
          return c.textHint;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return c.accentDim;
          return c.border;
        }),
      ),

      // ── Scrollbar ───────────────────────────
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStateProperty.all(c.borderSoft),
        thickness: WidgetStateProperty.all(3),
        radius: const Radius.circular(4),
      ),

      // ── Page transitions ────────────────────
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
    );
  }
}
