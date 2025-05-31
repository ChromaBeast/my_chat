import 'package:flutter/material.dart';

class AppTheme {
  // Color palette
  static const Color backgroundDark = Color(0xFF0D0D0D);
  static const Color backgroundLight = Color(0xFFF2F2F2);
  static const Color surface = Color(0xFFF2F2F2);
  static const Color primary = Color(0xFF635EF2);
  static const Color primaryVariant = Color(0xFF4A44F2);
  static const Color secondary = Color(0xFFAAA7F2);
  static const Color onPrimary = Color(0xFFF2F2F2);
  static const Color onSurfaceDark = Color(0xFFF2F2F2);
  static const Color onSurfaceLight = Color(0xFF0D0D0D);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: 'Roboto',
      scaffoldBackgroundColor: const Color(0xFF141218),
      colorScheme: const ColorScheme.dark(
        surface: Color(0xFF141218),
        primary: Color(0xFFD0BCFF),
        primaryContainer: Color(0xFF4F378B),
        secondary: Color(0xFFCCC2DC),
        secondaryContainer: Color(0xFF4A4458),
        error: Color(0xFFF2B8B5),
        onPrimary: Color(0xFF381E72),
        onPrimaryContainer: Color(0xFFEADDFF),
        onSecondary: Color(0xFF332D41),
        onSecondaryContainer: Color(0xFFE8DEF8),
        onSurface: Color(0xFFE6E0E9),
        onSurfaceVariant: Color(0xFFCAC4D0),
        onError: Color(0xFF601410),
        onErrorContainer: Color(0xFFF9DEDC),
        outline: Color(0xFF938F99),
        outlineVariant: Color(0xFF49454F),
        inverseSurface: Color(0xFFE6E0E9),
        inversePrimary: Color(0xFF6750A4),
        shadow: Color(0xFF000000),
        surfaceContainerHighest: Color(0xFF49454F),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF141218),
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: Color(0xFFE6E0E9),
          fontWeight: FontWeight.w500,
          fontSize: 22,
          fontFamily: 'Roboto',
        ),
        iconTheme: IconThemeData(color: Color(0xFFE6E0E9)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF211F26),
        hintStyle: const TextStyle(
          color: Color(0xFFCAC4D0),
          fontFamily: 'Roboto',
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFD0BCFF),
          foregroundColor: const Color(0xFF381E72),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 16,
            fontFamily: 'Roboto',
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF211F26),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 0,
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(
          color: Color(0xFFE6E0E9),
          fontSize: 16,
          fontFamily: 'Roboto',
        ),
        bodyMedium: TextStyle(
          color: Color(0xFFCAC4D0),
          fontSize: 14,
          fontFamily: 'Roboto',
        ),
        titleLarge: TextStyle(
          color: Color(0xFFE6E0E9),
          fontWeight: FontWeight.w500,
          fontSize: 22,
          fontFamily: 'Roboto',
        ),
      ),
      dividerColor: const Color(0xFF938F99),
      shadowColor: const Color(0xFF000000),
      indicatorColor: const Color(0xFFE6E0E9),
      splashColor: const Color(0x40CCCCCC),
      highlightColor: const Color(0x40CCCCCC),
      hoverColor: const Color(0x0AFFFFFF),
      focusColor: const Color(0x1FFFFFFF),
      disabledColor: const Color(0x62FFFFFF),
      unselectedWidgetColor: const Color(0xB3FFFFFF),
      visualDensity: VisualDensity.compact,
    );
  }
}
