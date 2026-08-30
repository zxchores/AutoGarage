import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../domain/models.dart';

class AppColors {
  static const bg = Color(0xFF0B0D10);
  static const surface = Color(0xFF141820);
  static const card = Color(0xFF1C212C);
  static const line = Color(0xFF2A3140);
  static const orange = Color(0xFFFF6A00);
  static const gold = Color(0xFFEAB308);
  static const text = Color(0xFFF4F1EA);
  static const mute = Color(0xFF9AA3B5);

  static Color rarity(Rarity value) => switch (value) {
        Rarity.common => const Color(0xFF8B93A7),
        Rarity.rare => const Color(0xFF3B82F6),
        Rarity.epic => const Color(0xFFA855F7),
        Rarity.legendary => gold,
      };
}

ThemeData buildTheme() {
  final base = ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.bg,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.orange,
      secondary: AppColors.gold,
      surface: AppColors.surface,
    ),
  );
  final text = GoogleFonts.dmSansTextTheme(base.textTheme).apply(
    bodyColor: AppColors.text,
    displayColor: AppColors.text,
  );
  return base.copyWith(
    textTheme: text.copyWith(
      headlineLarge: GoogleFonts.orbitron(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: AppColors.text,
        letterSpacing: 1.2,
      ),
      headlineMedium: GoogleFonts.orbitron(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: AppColors.text,
      ),
      titleLarge: GoogleFonts.orbitron(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.text,
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.card,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.orange, width: 1.4),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.card,
      contentTextStyle: GoogleFonts.dmSans(color: AppColors.text),
    ),
  );
}
