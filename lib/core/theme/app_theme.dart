import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.electricBlue,
        secondary: AppColors.emeraldGreen,
        surface: AppColors.surface,
        error: AppColors.coral,
      ),
      textTheme: GoogleFonts.interTextTheme(
        ThemeData.dark().textTheme.copyWith(
          displayLarge: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, letterSpacing: -0.5),
          displayMedium: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, letterSpacing: -0.5),
          headlineLarge: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, letterSpacing: -0.3),
          headlineMedium: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, letterSpacing: -0.3),
          headlineSmall: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
          titleLarge: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
          titleMedium: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500),
          bodyLarge: const TextStyle(color: AppColors.textPrimary, height: 1.6),
          bodyMedium: const TextStyle(color: AppColors.textSecondary, height: 1.5),
          bodySmall: const TextStyle(color: AppColors.textMuted),
          labelLarge: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, letterSpacing: 0.3),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        titleTextStyle: GoogleFonts.inter(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.electricBlue,
          foregroundColor: Colors.white,
          shadowColor: AppColors.electricBlue.withOpacity(0.4),
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
          textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.2),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: const BorderSide(color: AppColors.glassBorder, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.glassWhite,
        hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 15),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.glassBorder, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.glassBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.electricBlue, width: 1.5),
        ),
      ),
    );
  }
}
