import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'app_radii.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

export '../../core/theme/app_theme.dart';

/// Sahyān Application Theme configuration.
/// Applies the standardized Plus Jakarta Sans typography and organic Forest palette.
abstract class AppTheme {
  static ThemeData get lightTheme {
    final baseTextTheme = GoogleFonts.plusJakartaSansTextTheme();
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.canvasLight,
      colorScheme: const ColorScheme.light(
        primary: AppColors.brand,
        onPrimary: AppColors.white,
        secondary: AppColors.brandBright,
        onSecondary: AppColors.white,
        surface: AppColors.cardLight,
        onSurface: AppColors.ink,
        error: AppColors.error,
        onError: AppColors.white,
      ),
      textTheme: baseTextTheme.copyWith(
        displayLarge: AppTypography.displayHero,
        headlineLarge: AppTypography.pageTitle,
        headlineMedium: AppTypography.sectionHeader,
        titleMedium: AppTypography.fieldLabel,
        titleSmall: AppTypography.cardTitle,
        bodyLarge: AppTypography.bodyLarge,
        bodyMedium: AppTypography.bodyMedium,
        bodySmall: AppTypography.secondary,
        labelLarge: AppTypography.button,
        labelSmall: AppTypography.caption,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.canvasLight,
        foregroundColor: AppColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.sectionHeader,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.brand,
          foregroundColor: AppColors.white,
          elevation: 0,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
          textStyle: AppTypography.button,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.brand,
          minimumSize: const Size(double.infinity, 50),
          side: const BorderSide(color: AppColors.brand, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
          textStyle: AppTypography.button.copyWith(color: AppColors.brand),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.cardLight,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.base,
          vertical: AppSpacing.md,
        ),
        hintStyle: AppTypography.secondary,
        labelStyle: AppTypography.secondary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: const BorderSide(color: AppColors.brand, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: const BorderSide(color: AppColors.error),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.cardLight,
        selectedItemColor: AppColors.brand,
        unselectedItemColor: AppColors.mutedLight,
        elevation: 8,
        type: BottomNavigationBarType.fixed,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.cardLight,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
        ),
      ),
      extensions: const <ThemeExtension<dynamic>>[SahyanThemeTokens.light],
    );
  }

  static ThemeData get darkTheme {
    final baseTextTheme = GoogleFonts.plusJakartaSansTextTheme(
      ThemeData(brightness: Brightness.dark).textTheme,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.darkBg,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.brandBright,
        onPrimary: AppColors.white,
        secondary: AppColors.mint,
        onSecondary: AppColors.darkBg,
        surface: AppColors.darkSurface,
        onSurface: AppColors.darkText,
        error: AppColors.error,
        onError: AppColors.white,
      ),
      textTheme: baseTextTheme.copyWith(
        displayLarge: AppTypography.displayHero.copyWith(
          color: AppColors.darkText,
        ),
        headlineLarge: AppTypography.pageTitle.copyWith(
          color: AppColors.darkText,
        ),
        headlineMedium: AppTypography.sectionHeader.copyWith(
          color: AppColors.darkText,
        ),
        titleMedium: AppTypography.fieldLabel.copyWith(
          color: AppColors.darkText,
        ),
        titleSmall: AppTypography.cardTitle.copyWith(color: AppColors.darkText),
        bodyLarge: AppTypography.bodyLarge.copyWith(color: AppColors.darkText),
        bodyMedium: AppTypography.bodyMedium.copyWith(
          color: AppColors.darkText,
        ),
        bodySmall: AppTypography.secondary.copyWith(color: AppColors.darkMuted),
        labelLarge: AppTypography.button.copyWith(color: AppColors.white),
        labelSmall: AppTypography.caption.copyWith(color: AppColors.darkMuted),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.darkBg,
        foregroundColor: AppColors.darkText,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.sectionHeader.copyWith(
          color: AppColors.darkText,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.brandBright,
          foregroundColor: AppColors.white,
          elevation: 0,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
          textStyle: AppTypography.button,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.mint,
          minimumSize: const Size(double.infinity, 50),
          side: const BorderSide(color: AppColors.mint, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
          textStyle: AppTypography.button.copyWith(color: AppColors.mint),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
          side: const BorderSide(color: AppColors.darkSurfaceHigh, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.base,
          vertical: AppSpacing.md,
        ),
        hintStyle: AppTypography.secondary.copyWith(color: AppColors.darkMuted),
        labelStyle: AppTypography.secondary.copyWith(
          color: AppColors.darkMuted,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: const BorderSide(color: AppColors.darkSurfaceHigh),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: const BorderSide(color: AppColors.darkSurfaceHigh),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: const BorderSide(color: AppColors.mint, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: const BorderSide(color: AppColors.error),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.darkSurface,
        selectedItemColor: AppColors.mint,
        unselectedItemColor: AppColors.darkMuted,
        elevation: 8,
        type: BottomNavigationBarType.fixed,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.darkSurfaceHigh,
        thickness: 1,
        space: 1,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.darkSurface,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
        ),
      ),
      extensions: const <ThemeExtension<dynamic>>[SahyanThemeTokens.dark],
    );
  }
}

/// 2026 Semantic Tokens exposed via ThemeExtension
class SahyanThemeTokens extends ThemeExtension<SahyanThemeTokens> {
  final Color brand;
  final Color brandBright;
  final Color ink;
  final Color mint;
  final Color marigold;
  final Color marigoldText;
  final Color canvas;
  final Color card;
  final Color muted;
  final Color error;
  final Color errorText;
  final Color border;
  final Color glassFill;
  final Color glassBorder;
  final Color surfaceHigh;

  const SahyanThemeTokens({
    required this.brand,
    required this.brandBright,
    required this.ink,
    required this.mint,
    required this.marigold,
    required this.marigoldText,
    required this.canvas,
    required this.card,
    required this.muted,
    required this.error,
    required this.errorText,
    required this.border,
    required this.glassFill,
    required this.glassBorder,
    required this.surfaceHigh,
  });

  static const light = SahyanThemeTokens(
    brand: AppColors.brand,
    brandBright: AppColors.brandBright,
    ink: AppColors.ink,
    mint: AppColors.mint,
    marigold: AppColors.marigold,
    marigoldText: AppColors.marigoldText,
    canvas: AppColors.canvasLight,
    card: AppColors.cardLight,
    muted: AppColors.mutedLight,
    error: AppColors.error,
    errorText: AppColors.errorText,
    border: AppColors.border,
    glassFill: AppColors.glassFillLight,
    glassBorder: AppColors.glassHighlight,
    surfaceHigh: AppColors.surfaceContainerHigh,
  );

  static const dark = SahyanThemeTokens(
    brand: AppColors.brand,
    brandBright: AppColors.brandBright,
    ink: AppColors.darkText,
    mint: AppColors.darkAccent,
    marigold: AppColors.darkMarigold,
    marigoldText: AppColors.darkMarigold,
    canvas: AppColors.darkBg,
    card: AppColors.darkSurface,
    muted: AppColors.darkMuted,
    error: AppColors.error,
    errorText: AppColors.error,
    border: AppColors.darkSurfaceHigh,
    glassFill: AppColors.glassFillDark,
    glassBorder: AppColors.glassHighlightDark,
    surfaceHigh: AppColors.darkSurfaceHigh,
  );

  @override
  SahyanThemeTokens copyWith({
    Color? brand,
    Color? brandBright,
    Color? ink,
    Color? mint,
    Color? marigold,
    Color? marigoldText,
    Color? canvas,
    Color? card,
    Color? muted,
    Color? error,
    Color? errorText,
    Color? border,
    Color? glassFill,
    Color? glassBorder,
    Color? surfaceHigh,
  }) {
    return SahyanThemeTokens(
      brand: brand ?? this.brand,
      brandBright: brandBright ?? this.brandBright,
      ink: ink ?? this.ink,
      mint: mint ?? this.mint,
      marigold: marigold ?? this.marigold,
      marigoldText: marigoldText ?? this.marigoldText,
      canvas: canvas ?? this.canvas,
      card: card ?? this.card,
      muted: muted ?? this.muted,
      error: error ?? this.error,
      errorText: errorText ?? this.errorText,
      border: border ?? this.border,
      glassFill: glassFill ?? this.glassFill,
      glassBorder: glassBorder ?? this.glassBorder,
      surfaceHigh: surfaceHigh ?? this.surfaceHigh,
    );
  }

  @override
  SahyanThemeTokens lerp(ThemeExtension<SahyanThemeTokens>? other, double t) {
    if (other is! SahyanThemeTokens) return this;
    return SahyanThemeTokens(
      brand: Color.lerp(brand, other.brand, t) ?? brand,
      brandBright: Color.lerp(brandBright, other.brandBright, t) ?? brandBright,
      ink: Color.lerp(ink, other.ink, t) ?? ink,
      mint: Color.lerp(mint, other.mint, t) ?? mint,
      marigold: Color.lerp(marigold, other.marigold, t) ?? marigold,
      marigoldText:
          Color.lerp(marigoldText, other.marigoldText, t) ?? marigoldText,
      canvas: Color.lerp(canvas, other.canvas, t) ?? canvas,
      card: Color.lerp(card, other.card, t) ?? card,
      muted: Color.lerp(muted, other.muted, t) ?? muted,
      error: Color.lerp(error, other.error, t) ?? error,
      errorText: Color.lerp(errorText, other.errorText, t) ?? errorText,
      border: Color.lerp(border, other.border, t) ?? border,
      glassFill: Color.lerp(glassFill, other.glassFill, t) ?? glassFill,
      glassBorder: Color.lerp(glassBorder, other.glassBorder, t) ?? glassBorder,
      surfaceHigh: Color.lerp(surfaceHigh, other.surfaceHigh, t) ?? surfaceHigh,
    );
  }
}

extension SahyanThemeContext on BuildContext {
  SahyanThemeTokens get sahyanTokens =>
      Theme.of(this).extension<SahyanThemeTokens>() ??
      (Theme.of(this).brightness == Brightness.dark
          ? SahyanThemeTokens.dark
          : SahyanThemeTokens.light);

  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}
