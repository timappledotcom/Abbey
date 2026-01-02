import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'app_theme.g.dart';

enum AppThemeMode {
  light,
  dark,
  newspaper,
  parchment,
}

@riverpod
class ThemeNotifier extends _$ThemeNotifier {
  static const _themeKey = 'app_theme_mode';

  @override
  AppThemeMode build() {
    _loadTheme();
    return AppThemeMode.light;
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt(_themeKey) ?? 0;
    state = AppThemeMode.values[themeIndex];
  }

  Future<void> setTheme(AppThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeKey, mode.index);
  }
}

class AppTheme {
  // ========== LIGHT THEME ==========
  static ThemeData get lightTheme {
    final baseTextTheme = GoogleFonts.interTextTheme();

    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: Colors.grey[50],
      textTheme: baseTextTheme.copyWith(
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(
          fontSize: 18,
          height: 1.6,
        ),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(
          fontSize: 16,
          height: 1.5,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.grey[50],
        elevation: 0,
      ),
      dividerTheme: DividerThemeData(
        color: Colors.grey[300],
        thickness: 0.5,
      ),
    );
  }

  // ========== DARK THEME ==========
  static ThemeData get darkTheme {
    final baseTextTheme = GoogleFonts.interTextTheme(ThemeData.dark().textTheme);

    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: const Color(0xFF1A1A1A),
      textTheme: baseTextTheme.copyWith(
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(
          fontSize: 18,
          height: 1.6,
        ),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(
          fontSize: 16,
          height: 1.5,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1A1A1A),
        elevation: 0,
      ),
      dividerTheme: DividerThemeData(
        color: Colors.grey[800],
        thickness: 0.5,
      ),
    );
  }

  // ========== NEWSPAPER THEME ==========
  static ThemeData get newspaperTheme {
    final bodyTextTheme = GoogleFonts.sourceSerif4TextTheme();
    final headingTextTheme = GoogleFonts.playfairDisplayTextTheme();

    const background = Color(0xFFFAFAFA);
    const inkBlack = Color(0xFF1A1A1A);
    const inkGrey = Color(0xFF4A4A4A);

    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: inkBlack,
        onPrimary: background,
        secondary: Color(0xFF8B0000), // Dark red accent
        onSecondary: background,
        tertiary: inkGrey,
        onTertiary: background,
        error: Colors.redAccent,
        onError: Colors.white,
        surface: background,
        onSurface: inkBlack,
      ),
      scaffoldBackgroundColor: background,
      textTheme: bodyTextTheme.copyWith(
        displayLarge: headingTextTheme.displayLarge?.copyWith(
          color: inkBlack,
          fontWeight: FontWeight.bold,
        ),
        displayMedium: headingTextTheme.displayMedium?.copyWith(
          color: inkBlack,
          fontWeight: FontWeight.bold,
        ),
        displaySmall: headingTextTheme.displaySmall?.copyWith(
          color: inkBlack,
          fontWeight: FontWeight.bold,
        ),
        headlineLarge: headingTextTheme.headlineLarge?.copyWith(
          color: inkBlack,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: headingTextTheme.headlineMedium?.copyWith(
          color: inkBlack,
          fontWeight: FontWeight.bold,
        ),
        headlineSmall: headingTextTheme.headlineSmall?.copyWith(
          color: inkBlack,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: headingTextTheme.titleLarge?.copyWith(
          color: inkBlack,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: bodyTextTheme.bodyLarge?.copyWith(
          color: inkBlack,
          fontSize: 18,
          height: 1.7,
        ),
        bodyMedium: bodyTextTheme.bodyMedium?.copyWith(
          color: inkBlack,
          fontSize: 16,
          height: 1.6,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: inkBlack,
        elevation: 0,
        titleTextStyle: headingTextTheme.titleLarge?.copyWith(
          color: inkBlack,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: const IconThemeData(color: inkBlack),
      ),
      iconTheme: const IconThemeData(color: inkGrey),
      dividerTheme: const DividerThemeData(
        color: inkBlack,
        thickness: 1,
      ),
    );
  }

  // ========== PARCHMENT THEME ==========
  static ThemeData get parchmentTheme {
    final bodyTextTheme = GoogleFonts.ebGaramondTextTheme();
    final headingTextTheme = GoogleFonts.cinzelTextTheme();

    const parchmentLight = Color(0xFFF5E6C8);
    const parchmentMedium = Color(0xFFEDD9B4);
    const inkBrown = Color(0xFF3E2723);
    const inkSepia = Color(0xFF5D4037);
    const accentGold = Color(0xFFB8860B);

    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: inkBrown,
        onPrimary: parchmentLight,
        secondary: accentGold,
        onSecondary: parchmentLight,
        tertiary: inkSepia,
        onTertiary: parchmentLight,
        error: Color(0xFF8B0000),
        onError: parchmentLight,
        surface: parchmentLight,
        onSurface: inkBrown,
      ),
      scaffoldBackgroundColor: parchmentLight,
      textTheme: bodyTextTheme.copyWith(
        displayLarge: headingTextTheme.displayLarge?.copyWith(
          color: inkBrown,
          fontWeight: FontWeight.w600,
        ),
        displayMedium: headingTextTheme.displayMedium?.copyWith(
          color: inkBrown,
          fontWeight: FontWeight.w600,
        ),
        displaySmall: headingTextTheme.displaySmall?.copyWith(
          color: inkBrown,
          fontWeight: FontWeight.w600,
        ),
        headlineLarge: headingTextTheme.headlineLarge?.copyWith(
          color: inkBrown,
          fontWeight: FontWeight.w500,
        ),
        headlineMedium: headingTextTheme.headlineMedium?.copyWith(
          color: inkBrown,
          fontWeight: FontWeight.w500,
        ),
        headlineSmall: headingTextTheme.headlineSmall?.copyWith(
          color: inkBrown,
          fontWeight: FontWeight.w500,
        ),
        titleLarge: headingTextTheme.titleLarge?.copyWith(
          color: inkBrown,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: bodyTextTheme.bodyLarge?.copyWith(
          color: inkBrown,
          fontSize: 19,
          height: 1.7,
        ),
        bodyMedium: bodyTextTheme.bodyMedium?.copyWith(
          color: inkBrown,
          fontSize: 17,
          height: 1.6,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: parchmentMedium,
        foregroundColor: inkBrown,
        elevation: 0,
        titleTextStyle: headingTextTheme.titleLarge?.copyWith(
          color: inkBrown,
          fontWeight: FontWeight.w500,
        ),
        iconTheme: const IconThemeData(color: inkBrown),
      ),
      iconTheme: const IconThemeData(color: inkSepia),
      dividerTheme: const DividerThemeData(
        color: inkSepia,
        thickness: 0.5,
      ),
      cardTheme: CardThemeData(
        color: parchmentMedium.withOpacity(0.5),
        elevation: 0,
      ),
    );
  }

  // Helper to get theme by mode
  static ThemeData getTheme(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:
        return lightTheme;
      case AppThemeMode.dark:
        return darkTheme;
      case AppThemeMode.newspaper:
        return newspaperTheme;
      case AppThemeMode.parchment:
        return parchmentTheme;
    }
  }

  // Theme display names
  static String getThemeName(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:
        return 'Light';
      case AppThemeMode.dark:
        return 'Dark';
      case AppThemeMode.newspaper:
        return 'Newspaper';
      case AppThemeMode.parchment:
        return 'Parchment';
    }
  }

  // Theme icons
  static IconData getThemeIcon(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:
        return Icons.light_mode;
      case AppThemeMode.dark:
        return Icons.dark_mode;
      case AppThemeMode.newspaper:
        return Icons.article;
      case AppThemeMode.parchment:
        return Icons.history_edu;
    }
  }
}
