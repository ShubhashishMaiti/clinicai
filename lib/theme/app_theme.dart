// THEME LOCK: light — source: domain signal (healthcare/clinic = trust, clarity, bright environment)
// Scaffold.backgroundColor = AppTheme.backgroundLight — ALL screens

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Primary palette — Blue per spec
  static const Color primary = Color(0xFF2563EB);
  static const Color primaryContainer = Color(0xFFDBEAFE);
  static const Color accent = Color(0xFF3B82F6);
  static const Color accentLight = Color(0xFFEFF6FF);

  // Semantic colors
  static const Color success = Color(0xFF10B981);
  static const Color successContainer = Color(0xFFD1FAE5);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningContainer = Color(0xFFFEF3C7);
  static const Color error = Color(0xFFEF4444);
  static const Color errorContainer = Color(0xFFFEE2E2);
  static const Color rescheduled = Color(0xFFF59E0B);
  static const Color completed = Color(0xFF10B981);
  static const Color cancelled = Color(0xFFEF4444);
  static const Color scheduled = Color(0xFF2563EB);
  static const Color pending = Color(0xFF8B5CF6);

  // Light surfaces
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceVariantLight = Color(0xFFF0F5FF);
  static const Color backgroundLight = Color(0xFFF8FAFF);
  static const Color outlineLight = Color(0xFFCBD5E1);
  static const Color outlineVariantLight = Color(0xFFE2E8F0);
  static const Color onSurfaceLight = Color(0xFF0F172A);
  static const Color mutedLight = Color(0xFF64748B);

  // Dark surfaces
  static const Color surfaceDark = Color(0xFF1E293B);
  static const Color surfaceVariantDark = Color(0xFF0F172A);
  static const Color backgroundDark = Color(0xFF0F172A);
  static const Color outlineDark = Color(0xFF334155);
  static const Color outlineVariantDark = Color(0xFF1E293B);
  static const Color onSurfaceDark = Color(0xFFF1F5F9);
  static const Color mutedDark = Color(0xFF94A3B8);

  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.light(
      primary: primary,
      onPrimary: Colors.white,
      primaryContainer: primaryContainer,
      onPrimaryContainer: const Color(0xFF1E3A8A),
      secondary: accent,
      onSecondary: Colors.white,
      secondaryContainer: const Color(0xFFDBEAFE),
      onSecondaryContainer: const Color(0xFF1E3A8A),
      surface: surfaceLight,
      onSurface: onSurfaceLight,
      surfaceContainerHighest: surfaceVariantLight,
      onSurfaceVariant: mutedLight,
      error: error,
      onError: Colors.white,
      errorContainer: errorContainer,
      outline: outlineLight,
      outlineVariant: outlineVariantLight,
      inverseSurface: const Color(0xFF1E293B),
      onInverseSurface: const Color(0xFFF1F5F9),
    ),
    scaffoldBackgroundColor: backgroundLight,
    textTheme: GoogleFonts.soraTextTheme().copyWith(
      displayLarge: GoogleFonts.sora(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: onSurfaceLight,
      ),
      displayMedium: GoogleFonts.sora(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: onSurfaceLight,
      ),
      displaySmall: GoogleFonts.sora(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: onSurfaceLight,
      ),
      headlineLarge: GoogleFonts.sora(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: onSurfaceLight,
      ),
      headlineMedium: GoogleFonts.sora(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: onSurfaceLight,
      ),
      headlineSmall: GoogleFonts.sora(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: onSurfaceLight,
      ),
      titleLarge: GoogleFonts.sora(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: onSurfaceLight,
      ),
      titleMedium: GoogleFonts.sora(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: onSurfaceLight,
      ),
      titleSmall: GoogleFonts.sora(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: onSurfaceLight,
      ),
      bodyLarge: GoogleFonts.sora(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: onSurfaceLight,
      ),
      bodyMedium: GoogleFonts.sora(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: onSurfaceLight,
      ),
      bodySmall: GoogleFonts.sora(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: mutedLight,
      ),
      labelLarge: GoogleFonts.sora(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: onSurfaceLight,
      ),
      labelMedium: GoogleFonts.sora(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: mutedLight,
        letterSpacing: 0.3,
      ),
      labelSmall: GoogleFonts.sora(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        color: mutedLight,
        letterSpacing: 0.3,
      ),
    ),
    appBarTheme: AppBarThemeData(
      backgroundColor: surfaceLight,
      foregroundColor: onSurfaceLight,
      elevation: 0,
      scrolledUnderElevation: 1,
      shadowColor: outlineLight,
      titleTextStyle: GoogleFonts.sora(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: onSurfaceLight,
      ),
    ),
    cardTheme: CardThemeData(
      color: surfaceLight,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      margin: EdgeInsets.zero,
    ),
    inputDecorationTheme: InputDecorationThemeData(
      filled: true,
      fillColor: surfaceVariantLight,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: outlineLight, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: error, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: error, width: 2),
      ),
      labelStyle: GoogleFonts.sora(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: mutedLight,
      ),
      hintStyle: GoogleFonts.sora(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: mutedLight,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        textStyle: GoogleFonts.sora(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        textStyle: GoogleFonts.sora(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: surfaceLight,
      indicatorColor: primaryContainer,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return GoogleFonts.sora(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: primary,
          );
        }
        return GoogleFonts.sora(
          fontSize: 11,
          fontWeight: FontWeight.w400,
          color: mutedLight,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: primary, size: 22);
        }
        return const IconThemeData(color: mutedLight, size: 22);
      }),
      elevation: 2,
      shadowColor: outlineLight,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: surfaceVariantLight,
      selectedColor: primaryContainer,
      labelStyle: GoogleFonts.sora(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: onSurfaceLight,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      side: BorderSide.none,
    ),
    dividerTheme: const DividerThemeData(
      color: outlineVariantLight,
      thickness: 1,
      space: 0,
    ),
  );

  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.dark(
      primary: primary,
      onPrimary: Colors.white,
      primaryContainer: const Color(0xFF1E3A8A),
      onPrimaryContainer: const Color(0xFFDBEAFE),
      secondary: accent,
      onSecondary: Colors.white,
      secondaryContainer: const Color(0xFF1E3A8A),
      onSecondaryContainer: const Color(0xFFDBEAFE),
      surface: surfaceDark,
      onSurface: onSurfaceDark,
      surfaceContainerHighest: surfaceVariantDark,
      onSurfaceVariant: mutedDark,
      error: const Color(0xFFFCA5A5),
      onError: const Color(0xFF7F1D1D),
      errorContainer: const Color(0xFF7F1D1D),
      outline: outlineDark,
      outlineVariant: outlineVariantDark,
      inverseSurface: const Color(0xFFF1F5F9),
      onInverseSurface: const Color(0xFF1E293B),
    ),
    scaffoldBackgroundColor: backgroundDark,
    textTheme: GoogleFonts.soraTextTheme().copyWith(
      displayLarge: GoogleFonts.sora(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: onSurfaceDark,
      ),
      headlineLarge: GoogleFonts.sora(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: onSurfaceDark,
      ),
      headlineMedium: GoogleFonts.sora(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: onSurfaceDark,
      ),
      titleLarge: GoogleFonts.sora(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: onSurfaceDark,
      ),
      titleMedium: GoogleFonts.sora(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: onSurfaceDark,
      ),
      bodyLarge: GoogleFonts.sora(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: onSurfaceDark,
      ),
      bodyMedium: GoogleFonts.sora(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: onSurfaceDark,
      ),
      bodySmall: GoogleFonts.sora(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: mutedDark,
      ),
      labelLarge: GoogleFonts.sora(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: onSurfaceDark,
      ),
      labelMedium: GoogleFonts.sora(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: mutedDark,
        letterSpacing: 0.3,
      ),
    ),
    appBarTheme: AppBarThemeData(
      backgroundColor: surfaceDark,
      foregroundColor: onSurfaceDark,
      elevation: 0,
      scrolledUnderElevation: 1,
      shadowColor: outlineDark,
      titleTextStyle: GoogleFonts.sora(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: onSurfaceDark,
      ),
    ),
    cardTheme: CardThemeData(
      color: surfaceDark,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      margin: EdgeInsets.zero,
    ),
    inputDecorationTheme: InputDecorationThemeData(
      filled: true,
      fillColor: surfaceVariantDark,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: outlineDark, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: error, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: error, width: 2),
      ),
      labelStyle: GoogleFonts.sora(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: mutedDark,
      ),
      hintStyle: GoogleFonts.sora(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: mutedDark,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: surfaceDark,
      indicatorColor: const Color(0xFF1E3A8A),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return GoogleFonts.sora(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: primary,
          );
        }
        return GoogleFonts.sora(
          fontSize: 11,
          fontWeight: FontWeight.w400,
          color: mutedDark,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: primary, size: 22);
        }
        return const IconThemeData(color: mutedDark, size: 22);
      }),
    ),
  );
}
