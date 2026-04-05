import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const primary = Color(0xFF22C55E);
  static const primaryLight = Color(0xFF86EFAC);
  static const primaryDark = Color(0xFF16A34A);

  static const background = Color(0xFFF0FDF4);
  static const surface = Colors.white;

  static const cardNormal = Colors.white;
  static const cardSkip = Color(0xFFFBBF24);
  static const cardSteal = Color(0xFFEF4444);
  static const cardUndo = Color(0xFF3B82F6);
  static const cardWild = Color(0xFF8B5CF6);

  static const correctGreen = Color(0xFF22C55E);
  static const incorrectRed = Color(0xFFEF4444);

  static const textPrimary = Color(0xFF1A1A2E);
  static const textSecondary = Color(0xFF64748B);
  static const textOnPrimary = Colors.white;
}

class AppTheme {
  static final lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
    ),
    textTheme: GoogleFonts.nunitoTextTheme(),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        textStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 4,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  );

  static const greenGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      AppColors.primaryLight,
      AppColors.primary,
      AppColors.primaryDark,
    ],
  );
}
