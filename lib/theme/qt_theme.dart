import 'package:flutter/material.dart';

class QtColors {
  // Qt Creator Slate Dark Mode
  static const Color darkBg = Color(0xFF1E1F29);
  static const Color darkSurface = Color(0xFF282A36);
  static const Color darkHeader = Color(0xFF21222C);
  static const Color darkBorder = Color(0xFF383A4C);
  static const Color darkAccent = Color(0xFF6272A4);
  static const Color darkPrimary = Color(0xFF8BE9FD);
  static const Color darkSuccess = Color(0xFF50FA7B);
  static const Color darkWarning = Color(0xFFFFB86C);
  static const Color darkError = Color(0xFFFF5555);
  static const Color darkTextPrimary = Color(0xFFF8F8F2);
  static const Color darkTextSecondary = Color(0xFFA0A0B0);

  // Qt Fusion Light Mode
  static const Color lightBg = Color(0xFFF0F2F5);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightHeader = Color(0xFFE4E7EB);
  static const Color lightBorder = Color(0xFFCFD5DD);
  static const Color lightAccent = Color(0xFF0066CC);
  static const Color lightPrimary = Color(0xFF0052CC);
  static const Color lightSuccess = Color(0xFF28A745);
  static const Color lightWarning = Color(0xFFFD7E14);
  static const Color lightError = Color(0xFFDC3545);
  static const Color lightTextPrimary = Color(0xFF24292E);
  static const Color lightTextSecondary = Color(0xFF586069);
}

class QtTheme {
  static ThemeData getDarkTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: QtColors.darkBg,
      colorScheme: const ColorScheme.dark(
        primary: QtColors.darkAccent,
        secondary: QtColors.darkPrimary,
        surface: QtColors.darkSurface,
        background: QtColors.darkBg,
        error: QtColors.darkError,
      ),
      fontFamily: 'Roboto',
      cardTheme: CardThemeData(
        color: QtColors.darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: QtColors.darkBorder, width: 1),
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF21222C),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: QtColors.darkBorder, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: QtColors.darkBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: QtColors.darkPrimary, width: 1.5),
        ),
        labelStyle: const TextStyle(color: QtColors.darkTextSecondary, fontSize: 13),
        hintStyle: const TextStyle(color: QtColors.darkTextSecondary, fontSize: 13),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: QtColors.darkAccent,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: QtColors.darkTextPrimary,
          side: const BorderSide(color: QtColors.darkBorder, width: 1),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: QtColors.darkBorder,
        thickness: 1,
        space: 1,
      ),
    );
  }

  static ThemeData getLightTheme() {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: QtColors.lightBg,
      colorScheme: const ColorScheme.light(
        primary: QtColors.lightAccent,
        secondary: QtColors.lightPrimary,
        surface: QtColors.lightSurface,
        background: QtColors.lightBg,
        error: QtColors.lightError,
      ),
      fontFamily: 'Roboto',
      cardTheme: CardThemeData(
        color: QtColors.lightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: QtColors.lightBorder, width: 1),
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: QtColors.lightBorder, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: QtColors.lightBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: QtColors.lightAccent, width: 1.5),
        ),
        labelStyle: const TextStyle(color: QtColors.lightTextSecondary, fontSize: 13),
        hintStyle: const TextStyle(color: QtColors.lightTextSecondary, fontSize: 13),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: QtColors.lightAccent,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: QtColors.lightTextPrimary,
          side: const BorderSide(color: QtColors.lightBorder, width: 1),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: QtColors.lightBorder,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
