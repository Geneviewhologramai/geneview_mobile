import 'package:flutter/material.dart';

class ArtDecoTheme {
  // Optikai fekete: nulla fénykibocsátás OLED-en a tökéletes lebegéshez
  static const Color pureBlack = Color(0xFF000000);
  static const Color obsidianSurface = Color(0xFF0A0A0C);

  // Art Deco arany tónusok
  static const Color goldPrimary = Color(0xFFD4AF37);
  static const Color goldAccent = Color(0xFFFFD700);
  static const Color goldMuted = Color(0xFF8A7322);

  // Szöveg és jelölő színek
  static const Color textLight = Color(0xFFEDEDED);
  static const Color textMuted = Color(0xFF8E8E93);

  static ThemeData get themeData {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: pureBlack,
      primaryColor: goldPrimary,
      canvasColor: obsidianSurface,
      colorScheme: const ColorScheme.dark(
        primary: goldPrimary,
        secondary: goldAccent,
        surface: obsidianSurface,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: pureBlack,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: goldPrimary,
          fontSize: 18,
          letterSpacing: 2.0,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}