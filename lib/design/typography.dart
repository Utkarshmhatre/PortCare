import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Typography design tokens based on design.json specification
/// Uses Inter font family with specified sizes and weights
class AppTypography {
  AppTypography._();

  // Font Family
  static TextStyle get _baseTextStyle => GoogleFonts.inter();

  // Font Sizes (in logical pixels)
  static const double displayLarge = 32.0;
  static const double h1 = 20.0;
  static const double h2 = 18.0;
  static const double bodyLarge = 16.0;
  static const double body = 14.0;
  static const double bodySmall = 12.0;
  static const double caption = 11.0;

  // Font Weights
  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight semibold = FontWeight.w600;
  static const FontWeight bold = FontWeight.w700;

  // Line Heights
  static const double displayLargeLineHeight = 40.0;
  static const double h1LineHeight = 28.0;
  static const double bodyLineHeight = 20.0;

  // Text Styles
  static TextStyle get displayLargeStyle => _baseTextStyle.copyWith(
    fontSize: displayLarge,
    fontWeight: semibold,
    height: displayLargeLineHeight / displayLarge,
  );

  static TextStyle get h1Style => _baseTextStyle.copyWith(
    fontSize: h1,
    fontWeight: semibold,
    height: h1LineHeight / h1,
  );

  static TextStyle get h2Style =>
      _baseTextStyle.copyWith(fontSize: h2, fontWeight: semibold);

  static TextStyle get bodyLargeStyle => _baseTextStyle.copyWith(
    fontSize: bodyLarge,
    fontWeight: regular,
    height: bodyLineHeight / bodyLarge,
  );

  static TextStyle get bodyStyle => _baseTextStyle.copyWith(
    fontSize: body,
    fontWeight: regular,
    height: bodyLineHeight / body,
  );

  static TextStyle get bodyMediumStyle => _baseTextStyle.copyWith(
    fontSize: body,
    fontWeight: medium,
    height: bodyLineHeight / body,
  );

  static TextStyle get bodySmallStyle =>
      _baseTextStyle.copyWith(fontSize: bodySmall, fontWeight: regular);

  static TextStyle get captionStyle =>
      _baseTextStyle.copyWith(fontSize: caption, fontWeight: regular);

  static TextStyle get buttonStyle =>
      _baseTextStyle.copyWith(fontSize: bodyLarge, fontWeight: semibold);

  static TextStyle get labelStyle =>
      _baseTextStyle.copyWith(fontSize: bodySmall, fontWeight: medium);
}
