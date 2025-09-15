import 'package:flutter/material.dart';

/// Design system colors based on the design tokens
/// These colors follow the design.json specification
class AppColors {
  AppColors._();

  // Primary Colors
  static const Color canvas = Color(0xFFF5F2F0);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color mutedSurface = Color(0xFFFBF9F8);
  static const Color backdrop = Color(0xFF0F0F10);
  static const Color primary = Color(0xFF0A0A0A);

  // Accent Colors
  static const Color accentBlue = Color(0xFF9FD6FF);
  static const Color accentGreen = Color(0xFF9CE29B);
  static const Color accentYellow = Color(0xFFFFDF7A);
  static const Color accentPurple = Color(0xFFD8C5FF);

  // Text Colors
  static const Color textPrimary = Color(0xFF111111);
  static const Color textSecondary = Color(0xFF6B6B6B);
  static const Color textTertiary = Color(0xFFA8A8A8);

  // UI Colors
  static const Color uiStroke = Color(0xFFE6E1DD);
  static const Color glass = Color(0x99FFFFFF); // rgba(255,255,255,0.6)
  static const Color danger = Color(0xFFFF6B6B);
  static const Color success = Color(0xFF21C17E);

  // Border Colors
  static const Color borderDefault = Color(0xFFE6E1DD);
  static const Color borderFocus = Color(0xFFC8E6FF);

  // Gradient Colors
  static const List<Color> blueGreenGradient = [accentBlue, accentGreen];
  static const List<Color> chartColors = [
    accentGreen,
    accentYellow,
    accentBlue,
    accentPurple,
  ];
}
