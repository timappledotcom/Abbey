import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Parchment / Newspaper Palette
  static const Color _parchmentLight = Color(0xFFFDF6E3); // Solarized Light-ish
  static const Color _parchmentDark = Color(0xFFEEE8D5);
  static const Color _inkBlack = Color(0xFF2E2E2E);
  static const Color _inkGrey = Color(0xFF586E75);
  static const Color _accentSepia = Color(0xFFB58900);
  static const Color _paperTexture = Color(0xFFF5F1E6);

  static ThemeData get lightTheme {
    final baseTextTheme = GoogleFonts.latoTextTheme();
    final headingTextTheme = GoogleFonts.playfairDisplayTextTheme();

    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: _inkBlack,
        onPrimary: _parchmentLight,
        secondary: _accentSepia,
        onSecondary: _parchmentLight,
        error: Colors.redAccent,
        onError: Colors.white,
        surface: _paperTexture,
        onSurface: _inkBlack,
      ),
      scaffoldBackgroundColor: _paperTexture,
      textTheme: baseTextTheme.copyWith(
        displayLarge: headingTextTheme.displayLarge?.copyWith(color: _inkBlack),
        displayMedium: headingTextTheme.displayMedium?.copyWith(color: _inkBlack),
        displaySmall: headingTextTheme.displaySmall?.copyWith(color: _inkBlack),
        headlineLarge: headingTextTheme.headlineLarge?.copyWith(color: _inkBlack),
        headlineMedium: headingTextTheme.headlineMedium?.copyWith(color: _inkBlack),
        headlineSmall: headingTextTheme.headlineSmall?.copyWith(color: _inkBlack),
        titleLarge: headingTextTheme.titleLarge?.copyWith(color: _inkBlack),
        
        // Body text - Sans Serif as requested
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(
          color: _inkBlack,
          fontSize: 18,
          height: 1.6, // Better readability
        ),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(
          color: _inkBlack,
          fontSize: 16,
          height: 1.5,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: _paperTexture,
        foregroundColor: _inkBlack,
        elevation: 0,
        titleTextStyle: headingTextTheme.titleLarge?.copyWith(
          color: _inkBlack,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: const IconThemeData(color: _inkBlack),
      ),
      iconTheme: const IconThemeData(color: _inkGrey),
      dividerTheme: const DividerThemeData(
        color: _inkGrey,
        thickness: 0.5,
      ),
    );
  }
}
