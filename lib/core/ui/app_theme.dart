import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:traininpink_onboarding/core/ui/tokens.dart';

abstract final class AppFonts {
  static const latin = 'Poppins';
  static const arabic = 'IBMPlexSansArabic';
}

abstract final class AppTheme {
  /// Arabic gets its own typeface and metrics rather than falling back:
  /// taller line height for its ascenders and dots, and no negative
  /// letter spacing, which would break the joins of a cursive script.
  static ThemeData forLanguage(String languageCode) {
    final isArabic = languageCode == 'ar';
    final family = isArabic ? AppFonts.arabic : AppFonts.latin;
    // Each falls back to the other, so an Arabic name typed in the English
    // UI (or a Latin email in the Arabic UI) still renders in a brand font.
    final fallback = [if (isArabic) AppFonts.latin else AppFonts.arabic];
    final tracking = isArabic ? 0.0 : -0.4;
    final tight = isArabic ? 1.45 : 1.18;
    final relaxed = isArabic ? 1.65 : 1.45;

    TextStyle style(
      double size,
      FontWeight weight, {
      double? height,
      double letterSpacing = 0,
      Color color = AppColors.ink,
    }) => TextStyle(
      fontFamily: family,
      fontFamilyFallback: fallback,
      fontSize: size,
      fontWeight: weight,
      height: height ?? relaxed,
      letterSpacing: letterSpacing,
      color: color,
    );

    final textTheme = TextTheme(
      displaySmall: style(
        34,
        FontWeight.w600,
        height: tight,
        letterSpacing: tracking * 2,
      ),
      headlineMedium: style(
        28,
        FontWeight.w600,
        height: tight,
        letterSpacing: tracking * 1.5,
      ),
      headlineSmall: style(
        22,
        FontWeight.w600,
        height: tight,
        letterSpacing: tracking,
      ),
      titleLarge: style(18, FontWeight.w600, height: tight),
      titleMedium: style(16.5, FontWeight.w400),
      bodyLarge: style(16, FontWeight.w400, color: AppColors.inkMuted),
      bodyMedium: style(14.5, FontWeight.w400, color: AppColors.inkMuted),
      bodySmall: style(13, FontWeight.w400, color: AppColors.inkMuted),
      labelLarge: style(17, FontWeight.w600, height: 1.2),
      labelMedium: style(13.5, FontWeight.w500, height: 1.3),
      labelSmall: style(12, FontWeight.w600, height: 1.2, letterSpacing: 0.2),
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: family,
      fontFamilyFallback: fallback,
      textTheme: textTheme,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.primarySoft,
        onSurface: AppColors.ink,
        error: AppColors.error,
        outline: AppColors.border,
      ),
      // No Material ink ripples: the flow is built for iPhone, and pressed
      // states are handled by each component.
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: AppColors.primary,
        selectionColor: AppColors.primary.withValues(alpha: 0.18),
        selectionHandleColor: AppColors.primary,
      ),
      cupertinoOverrideTheme: const CupertinoThemeData(
        primaryColor: AppColors.primary,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}
