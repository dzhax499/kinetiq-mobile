import 'package:flutter/material.dart';

class AppTheme {
  // === Brand Colors ===
  static const Color primaryCyan = Color(0xFF00F5FF);
  static const Color secondaryPink = Color(0xFFFF006E);
  static const Color accentPurple = Color(0xFF8B5CF6);
  static const Color accentGreen = Color(0xFF00E676);
  static const Color accentYellow = Color(0xFFFFD600);
  static const Color accentOrange = Color(0xFFFF6D00);

  // === Background Colors ===
  static const Color bgDark = Color(0xFF0A0E27);
  static const Color bgCard = Color(0xFF1A1F3A);
  static const Color bgCardLight = Color(0xFF252B4D);
  static const Color bgOverlay = Color(0x80000000);

  // === Text Colors ===
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B8D1);
  static const Color textMuted = Color(0xFF6B7394);

  // === Score Threshold Colors ===
  static const Color scoreLow = Color(0xFFFF4444);
  static const Color scoreMedium = Color(0xFFFFBB33);
  static const Color scoreHigh = Color(0xFF99CC00);
  static const Color scorePerfect = Color(0xFF00E676);

  // === Gradients ===
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryCyan, accentPurple],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [secondaryPink, accentOrange],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient bgGradient = LinearGradient(
    colors: [Color(0xFF0A0E27), Color(0xFF151A3A), Color(0xFF0A0E27)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient scoreGradient = LinearGradient(
    colors: [scoreLow, scoreMedium, scoreHigh, scorePerfect],
    stops: [0.0, 0.3, 0.6, 1.0],
  );

  // === Shadows ===
  static List<BoxShadow> neonGlow(Color color, {double blur = 20}) {
    return [
      BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: blur, spreadRadius: 2),
      BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: blur * 2, spreadRadius: 4),
    ];
  }

  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.3),
      blurRadius: 16,
      offset: const Offset(0, 8),
    ),
  ];

  // === Border Radius ===
  static const double radiusSm = 8;
  static const double radiusMd = 16;
  static const double radiusLg = 24;
  static const double radiusXl = 32;

  // === Glass Morphism ===
  static BoxDecoration glassDecoration({
    Color? borderColor,
    double borderRadius = radiusMd,
  }) {
    return BoxDecoration(
      color: bgCard.withValues(alpha: 0.7),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: borderColor ?? Colors.white.withValues(alpha: 0.1),
        width: 1,
      ),
      boxShadow: cardShadow,
    );
  }

  // === ThemeData ===
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bgDark,
      colorScheme: const ColorScheme.dark(
        primary: primaryCyan,
        secondary: secondaryPink,
        surface: bgCard,
        onPrimary: bgDark,
        onSecondary: Colors.white,
        onSurface: textPrimary,
      ),
      fontFamily: 'Outfit',
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 48,
          fontWeight: FontWeight.w800,
          color: textPrimary,
          letterSpacing: -1,
        ),
        displayMedium: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 36,
          fontWeight: FontWeight.w700,
          color: textPrimary,
          letterSpacing: -0.5,
        ),
        displaySmall: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        headlineMedium: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleLarge: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleMedium: TextStyle(
          fontFamily: 'Inter',
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
        bodyLarge: TextStyle(
          fontFamily: 'Inter',
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: textSecondary,
        ),
        bodyMedium: TextStyle(
          fontFamily: 'Inter',
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: textSecondary,
        ),
        labelLarge: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          letterSpacing: 0.5,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryCyan,
          foregroundColor: bgDark,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Outfit',
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryCyan,
          side: const BorderSide(color: primaryCyan, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Outfit',
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        iconTheme: IconThemeData(color: textPrimary),
      ),
      cardTheme: CardThemeData(
        color: bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
        elevation: 0,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: primaryCyan,
        inactiveTrackColor: bgCardLight,
        thumbColor: primaryCyan,
        overlayColor: primaryCyan.withValues(alpha: 0.2),
        trackHeight: 6,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: bgCardLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: primaryCyan, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        hintStyle: const TextStyle(color: textMuted),
      ),
    );
  }

  // === Helper to get score color ===
  static Color getScoreColor(double score) {
    if (score < 30) return scoreLow;
    if (score < 60) return scoreMedium;
    if (score < 85) return scoreHigh;
    return scorePerfect;
  }

  static String getScoreLabel(double score) {
    if (score < 30) return 'Kurang Mirip';
    if (score < 60) return 'Cukup Mirip';
    if (score < 85) return 'Mirip!';
    return 'Sangat Mirip!';
  }
}
