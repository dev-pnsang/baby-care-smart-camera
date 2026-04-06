import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'design_tokens.dart';

class AppTheme {
  AppTheme._();

  // Legacy aliases → design tokens
  static const Color primaryBlue = DesignTokens.babyBlue6;
  static const Color alertRed = DesignTokens.error6;
  static const Color surfaceColor = DesignTokens.neutral1;
  static const Color textDark = DesignTokens.neutral12;
  static const Color textLight = DesignTokens.neutral10;

  static const LinearGradient backgroundGradient =
      DesignTokens.screenBackgroundGradient;

  static const LinearGradient progressGradient =
      DesignTokens.progressNavyGradient;

  static List<BoxShadow> get neumorphicShadow => [
        BoxShadow(
          color: Colors.white.withOpacity(0.7),
          offset: const Offset(-4, -4),
          blurRadius: 8,
        ),
        BoxShadow(
          color: DesignTokens.babyBlue8.withOpacity(0.35),
          offset: const Offset(4, 4),
          blurRadius: 8,
        ),
      ];

  static List<BoxShadow> get innerGlow => [
        BoxShadow(
          color: DesignTokens.babyBlue5.withOpacity(0.35),
          offset: Offset.zero,
          blurRadius: 20,
          spreadRadius: -5,
        ),
      ];

  static const double borderRadius = 28.0;
  static const double streamRadius = 26.0;
  static const double cardRadius = 24.0;

  static Color get glassSurface =>
      DesignTokens.neutral1.withOpacity(0.92);

  /// Typography: Gotham Rounded spec → Nunito (rounded, Google Fonts).
  static TextTheme textTheme(ColorScheme colors) {
    final base = GoogleFonts.nunitoTextTheme();
    return base.copyWith(
      displayLarge: GoogleFonts.nunito(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        height: 1.2,
        color: colors.onSurface,
      ),
      displayMedium: GoogleFonts.nunito(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        height: 1.2,
        color: colors.onSurface,
      ),
      headlineLarge: GoogleFonts.nunito(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        height: 1.2,
        color: colors.onSurface,
      ),
      headlineMedium: GoogleFonts.nunito(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        height: 1.2,
        color: colors.onSurface,
      ),
      headlineSmall: GoogleFonts.nunito(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        height: 1.2,
        color: colors.onSurface,
      ),
      titleLarge: GoogleFonts.nunito(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        height: 1.2,
        color: colors.onSurface,
      ),
      titleMedium: GoogleFonts.nunito(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.2,
        color: colors.onSurface,
      ),
      bodyLarge: GoogleFonts.nunito(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.2,
        color: colors.onSurface,
      ),
      bodyMedium: GoogleFonts.nunito(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.2,
        color: colors.onSurface,
      ),
      bodySmall: GoogleFonts.nunito(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.2,
        color: colors.onSurfaceVariant,
      ),
      labelLarge: GoogleFonts.nunito(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        height: 1.2,
        color: colors.onSurface,
      ),
    );
  }

  static ThemeData lightTheme() {
    final colorScheme = ColorScheme.light(
      primary: DesignTokens.neutral12,
      onPrimary: Colors.white,
      secondary: DesignTokens.babyBlue5,
      onSecondary: DesignTokens.neutral12,
      surface: DesignTokens.neutral1,
      onSurface: DesignTokens.neutral12,
      onSurfaceVariant: DesignTokens.neutral10,
      error: DesignTokens.error6,
      onError: Colors.white,
      outline: DesignTokens.neutral8,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: textTheme(colorScheme),
      scaffoldBackgroundColor: DesignTokens.babyBlue2,
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: DesignTokens.neutral12,
        titleTextStyle: GoogleFonts.nunito(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: DesignTokens.neutral12,
          height: 1.2,
        ),
      ),
      cardTheme: CardTheme(
        elevation: 0,
        color: DesignTokens.babyBlue2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: DesignTokens.neutral3,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: DesignTokens.neutral12,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.nunito(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            height: 1.2,
          ),
        ),
      ),
    );
  }
}
