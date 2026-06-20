import 'package:flutter/material.dart';

// ─── Color Palette ───────────────────────────────────────────
class AppColors {
  // Primary alchemist theme
  static const Color primary = Color(0xFF6C3FC5);
  static const Color primaryLight = Color(0xFF9B6EF3);
  static const Color primaryDark = Color(0xFF3E1A8A);

  // Accent gold / potion
  static const Color accent = Color(0xFFFFB800);
  static const Color accentLight = Color(0xFFFFD54F);
  static const Color accentDark = Color(0xFFE6A200);

  // Background gradients
  static const Color bgDarkTop = Color(0xFF0D0B1A);
  static const Color bgDarkMid = Color(0xFF1A1333);
  static const Color bgDarkBot = Color(0xFF12081F);

  // Surface & cards
  static const Color surface = Color(0xFF1E1636);
  static const Color surfaceLight = Color(0xFF2A2047);
  static const Color cardBorder = Color(0xFF3D2D6B);

  // Functional
  static const Color success = Color(0xFF00E676);
  static const Color error = Color(0xFFFF5252);
  static const Color warning = Color(0xFFFFAB40);
  static const Color info = Color(0xFF40C4FF);

  // Text
  static const Color textPrimary = Color(0xFFF5F0FF);
  static const Color textSecondary = Color(0xFFB8A9D4);
  static const Color textMuted = Color(0xFF7B6C99);

  // Potion colors
  static const Color potionRed = Color(0xFFFF4D6A);
  static const Color potionBlue = Color(0xFF4D8BFF);
  static const Color potionGreen = Color(0xFF4DFF88);
  static const Color potionPurple = Color(0xFFB44DFF);
  static const Color potionOrange = Color(0xFFFF8C4D);
  static const Color potionCyan = Color(0xFF4DFFEA);
  static const Color potionPink = Color(0xFFFF4DC4);
  static const Color potionYellow = Color(0xFFFFE44D);
}

// ─── Timing Constants ────────────────────────────────────────
class GameTiming {
  static const Duration memorizeBase = Duration(seconds: 5);
  static const Duration memorizePerItem = Duration(milliseconds: 800);
  static const Duration arrangePhaseDuration = Duration(seconds: 30);
  static const Duration filterPhaseDuration = Duration(seconds: 45);
  static const Duration resultShowDuration = Duration(seconds: 3);
  static const Duration countdownTick = Duration(seconds: 1);
  static const Duration cardFlipDuration = Duration(milliseconds: 400);
  static const Duration phaseTransitionDuration = Duration(milliseconds: 800);
  static const Duration particleLifetime = Duration(milliseconds: 1200);
}

// ─── Game Config ─────────────────────────────────────────────
class GameConfig {
  static const int maxLevels = 10;
  static const int baseScore = 1000;
  static const int timeBonus = 50;
  static const int perfectBonus = 500;
  static const int streakMultiplier = 2;

  static const int minPotions = 3;
  static const int maxPotions = 7;
  static const int minFilters = 2;
  static const int maxFilters = 5;
}

// ─── Sizing ──────────────────────────────────────────────────
class AppSizes {
  static const double borderRadius = 16.0;
  static const double borderRadiusLg = 24.0;
  static const double borderRadiusXl = 32.0;

  static const double paddingSm = 8.0;
  static const double paddingMd = 16.0;
  static const double paddingLg = 24.0;
  static const double paddingXl = 32.0;

  static const double iconSm = 20.0;
  static const double iconMd = 28.0;
  static const double iconLg = 40.0;

  static const double potionCardSize = 90.0;
  static const double filterButtonHeight = 56.0;
}

// ─── Filter Names (Indonesian) ──────────────────────────────
class FilterNames {
  static const Map<String, String> names = {
    'grayscale': 'Grayscale',
    'blur': 'Gaussian Blur',
    'sharpen': 'Sharpen',
    'edge_detection': 'Edge Detection',
    'brightness': 'Brightness',
    'contrast': 'Contrast',
    'invert': 'Invert',
    'threshold': 'Threshold',
    'sepia': 'Sepia',
    'emboss': 'Emboss',
  };
}
