import 'package:flutter/material.dart';

/// Shayan Pharma Guide's visual identity — one place for colors,
/// gradients and shared styling helpers so every screen looks like
/// part of the same app instead of a patchwork of one-off styles.
class AppColors {
  AppColors._();

  static const Color teal = Color(0xFF0F6E56);
  static const Color tealLight = Color(0xFF29B597);
  static const Color purple = Color(0xFF6C4CE0);
  static const Color purpleLight = Color(0xFF9D7CF2);
  static const Color amber = Color(0xFFFFB020);
  static const Color coral = Color(0xFFFF6E6E);
  static const Color skyBlue = Color(0xFF3AA0FF);

  static const Color night = Color(0xFF0B1220);
  static const Color night2 = Color(0xFF14213A);

  /// A rotating set of vibrant gradients used to color folder cards so
  /// the dashboard reads as lively rather than a flat list.
  static const List<List<Color>> cardGradients = [
    [Color(0xFF0F6E56), Color(0xFF29B597)],
    [Color(0xFF6C4CE0), Color(0xFF9D7CF2)],
    [Color(0xFFFF6E6E), Color(0xFFFFB020)],
    [Color(0xFF3AA0FF), Color(0xFF6C4CE0)],
    [Color(0xFFFFB020), Color(0xFFFF6E6E)],
    [Color(0xFF29B597), Color(0xFF3AA0FF)],
  ];

  static List<Color> gradientFor(String seed) {
    final idx = seed.codeUnits.fold<int>(0, (a, b) => a + b) %
        cardGradients.length;
    return cardGradients[idx];
  }
}

class AppTheme {
  AppTheme._();

  static ThemeData light() {
    final base = ThemeData(
      colorSchemeSeed: AppColors.teal,
      useMaterial3: true,
      brightness: Brightness.light,
    );
    return base.copyWith(
      scaffoldBackgroundColor: const Color(0xFFF5F7FB),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      textTheme: base.textTheme.apply(fontFamily: 'Roboto'),
    );
  }

  /// Shared decoration for every text field across the auth screens —
  /// rounded, floating label, soft fill, icon on the left.
  static InputDecoration fieldDecoration({
    required String label,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    OutlineInputBorder border(Color color, double width) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: color, width: width),
        );

    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.white70),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white.withOpacity(0.08),
      labelStyle: const TextStyle(color: Colors.white70),
      floatingLabelStyle: const TextStyle(color: AppColors.tealLight),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      enabledBorder: border(Colors.white.withOpacity(0.18), 1.2),
      focusedBorder: border(AppColors.tealLight, 1.8),
      errorBorder: border(AppColors.coral, 1.4),
      focusedErrorBorder: border(AppColors.coral, 1.8),
      errorStyle: const TextStyle(color: AppColors.coral),
    );
  }
}
