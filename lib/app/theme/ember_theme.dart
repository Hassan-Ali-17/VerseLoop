import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class EmberColors {
  static const Color background = Color(0xFF111110);
  static const Color surface = Color(0xFF1B1B19);
  static const Color surfaceElevated = Color(0xFF242421);
  static const Color primary = Color(0xFFE87532);
  static const Color primaryHover = Color(0xFFF38A4B);
  static const Color textMain = Color(0xFFF4F0E8);
  static const Color textMuted = Color(0xFFA8A39A);
  static const Color border = Color(0xFF30302C);
  static const Color borderBright = Color(0xFF454540);
  
  static const Color success = Color(0xFF388E3C);
  static const Color warning = Color(0xFFFFA000);
  static const Color error = Color(0xFFE57373);

  static const Color badgeBg = Color(0xFF2A2A26);
  static const Color statusPending = Color(0xFFFFB74D);
  static const Color statusPreparing = Color(0xFF4FC3F7);
  static const Color statusReady = Color(0xFF81C784);
  static const Color statusCompleted = Color(0xFF90A4AE);
  static const Color statusCancelled = Color(0xFFE57373);
}

class EmberTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: EmberColors.background,
      colorScheme: const ColorScheme.dark(
        background: EmberColors.background,
        surface: EmberColors.surface,
        primary: EmberColors.primary,
        onPrimary: EmberColors.background,
        onSurface: EmberColors.textMain,
        error: EmberColors.error,
      ),
      fontFamily: GoogleFonts.inter().fontFamily,
      textTheme: TextTheme(
        displayLarge: GoogleFonts.playfairDisplay(
          fontSize: 36,
          fontWeight: FontWeight.bold,
          color: EmberColors.textMain,
          height: 1.2,
        ),
        displayMedium: GoogleFonts.playfairDisplay(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: EmberColors.textMain,
          height: 1.25,
        ),
        headlineLarge: GoogleFonts.playfairDisplay(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: EmberColors.textMain,
        ),
        headlineMedium: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: EmberColors.textMain,
        ),
        titleLarge: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: EmberColors.textMain,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: EmberColors.textMain,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 15,
          color: EmberColors.textMain,
          height: 1.4,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          color: EmberColors.textMuted,
          height: 1.4,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 12,
          color: EmberColors.textMuted,
        ),
        labelLarge: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: EmberColors.textMain,
          letterSpacing: 0.5,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: EmberColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: EmberColors.textMain),
      ),
      cardTheme: CardThemeData(
        color: EmberColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: EmberColors.border, width: 1),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: EmberColors.border,
        thickness: 1,
        space: 1,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: EmberColors.primary,
          foregroundColor: EmberColors.background,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            letterSpacing: 0.5,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: EmberColors.textMain,
          side: const BorderSide(color: EmberColors.border, width: 1),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: EmberColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: EmberColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: EmberColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: EmberColors.primary, width: 1.5),
        ),
        labelStyle: const TextStyle(color: EmberColors.textMuted),
        hintStyle: const TextStyle(color: EmberColors.textMuted),
      ),
    );
  }
}
