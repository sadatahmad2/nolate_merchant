import 'package:flutter/material.dart';

class AppColors {
  // Dark Premium Backgrounds
  static const Color background    = Color(0xFF080C18);
  static const Color surface       = Color(0xFF0F1629);
  static const Color surfaceLight  = Color(0xFF161D35);

  // Vibrant Accents
  static const Color electricBlue  = Color(0xFF4F8EF7);
  static const Color blueGlow      = Color(0xFF2563EB);
  static const Color emeraldGreen  = Color(0xFF10D9A0);
  static const Color purpleAccent  = Color(0xFFA78BFA);
  static const Color premiumGold   = Color(0xFFFBBF24);
  static const Color coral         = Color(0xFFFF6B6B);
  static const Color danger        = Color(0xFFEF4444);
  static const Color warning       = Color(0xFFF59E0B);

  // Glass Effect
  static const Color glassWhite    = Color(0x14FFFFFF); // 8% white
  static const Color glassBorder   = Color(0x22FFFFFF); // 13% white
  static const Color glassWhiteHover = Color(0x22FFFFFF);

  // Text Colors
  static const Color textPrimary   = Colors.white;
  static const Color textSecondary = Color(0xFF8892A4);
  static const Color textMuted     = Color(0xFF4D5A6E);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF4F8EF7), Color(0xFF7C3AED)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient greenGradient = LinearGradient(
    colors: [Color(0xFF10D9A0), Color(0xFF059669)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFFBBF24), Color(0xFFD97706)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient purpleGradient = LinearGradient(
    colors: [Color(0xFFA78BFA), Color(0xFF7C3AED)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [Color(0xFF080C18), Color(0xFF0D1428), Color(0xFF080C18)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
