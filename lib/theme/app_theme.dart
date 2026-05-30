import 'package:flutter/material.dart';

class AppTheme {
  static const Color background  = Color(0xFF060D06);
  static const Color surface     = Color(0xFF0D1A0D);
  static const Color card        = Color(0xFF112211);
  static const Color primary     = Color(0xFF00E676);
  static const Color primaryDark = Color(0xFF00C853);
  static const Color accent      = Color(0xFF69FF47);
  static const Color neon        = Color(0xFF39FF14);
  static const Color purple      = Color(0xFF7C4DFF);
  static const Color blue        = Color(0xFF448AFF);
  static const Color textPrimary = Color(0xFFE8F5E9);
  static const Color textSecond  = Color(0xFF81C784);
  static const Color textHint    = Color(0xFF4CAF50);
  static const Color border      = Color(0xFF1B5E20);
  static const Color error       = Color(0xFFFF5252);
  static const Color gold        = Color(0xFFFFD740);

  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: background,
    colorScheme: const ColorScheme.dark(
      primary: primary,
      secondary: accent,
      surface: surface,
      error: error,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF080F08),
      elevation: 0,
      centerTitle: false,
      iconTheme: IconThemeData(color: primary),
    ),
    textTheme: const TextTheme(
      bodyLarge:  TextStyle(color: textPrimary, height: 1.6),
      bodyMedium: TextStyle(color: textSecond,  height: 1.6),
      labelLarge: TextStyle(color: primary, fontWeight: FontWeight.w600),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: background,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: border.withOpacity(0.6)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: primary, width: 1.5),
      ),
    ),
  );

  static BoxDecoration glassCard({Color? borderColor}) => BoxDecoration(
    borderRadius: BorderRadius.circular(20),
    color: surface,
    border: Border.all(color: (borderColor ?? primary).withOpacity(0.25), width: 1.2),
    boxShadow: [
      BoxShadow(
        color: (borderColor ?? primary).withOpacity(0.06),
        blurRadius: 20,
        spreadRadius: 1,
      ),
    ],
  );

  static BoxDecoration neonBorder({double radius = 20}) => BoxDecoration(
    borderRadius: BorderRadius.circular(radius),
    gradient: const LinearGradient(
      colors: [Color(0xFF0D2A0D), Color(0xFF1A3D1A)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    border: Border.all(color: primary.withOpacity(0.4), width: 1.5),
    boxShadow: [
      BoxShadow(color: primary.withOpacity(0.12), blurRadius: 16, spreadRadius: 2),
    ],
  );
}
