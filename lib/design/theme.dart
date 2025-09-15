import 'package:flutter/material.dart';
import 'colors.dart';
import 'typography.dart';
import 'tokens.dart';

/// Custom theme extension for the app's design system
/// This allows us to access our design tokens through Theme.of(context).extension<AppTheme>()
class AppTheme extends ThemeExtension<AppTheme> {
  const AppTheme();

  @override
  AppTheme copyWith() => const AppTheme();

  @override
  AppTheme lerp(ThemeExtension<AppTheme>? other, double t) => const AppTheme();

  /// Main theme data for the app
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        primary: AppColors.primary,
        onPrimary: AppColors.surface,
        secondary: AppColors.accentBlue,
        onSecondary: AppColors.textPrimary,
        error: AppColors.danger,
        onError: AppColors.surface,
      ),
      scaffoldBackgroundColor: AppColors.canvas,
      fontFamily: AppTypography.bodyStyle.fontFamily,
      textTheme: TextTheme(
        displayLarge: AppTypography.displayLargeStyle.copyWith(
          color: AppColors.textPrimary,
        ),
        headlineLarge: AppTypography.h1Style.copyWith(
          color: AppColors.textPrimary,
        ),
        headlineMedium: AppTypography.h2Style.copyWith(
          color: AppColors.textPrimary,
        ),
        bodyLarge: AppTypography.bodyLargeStyle.copyWith(
          color: AppColors.textPrimary,
        ),
        bodyMedium: AppTypography.bodyStyle.copyWith(
          color: AppColors.textPrimary,
        ),
        bodySmall: AppTypography.bodySmallStyle.copyWith(
          color: AppColors.textSecondary,
        ),
        labelLarge: AppTypography.buttonStyle.copyWith(
          color: AppColors.textPrimary,
        ),
        labelMedium: AppTypography.labelStyle.copyWith(
          color: AppColors.textSecondary,
        ),
        labelSmall: AppTypography.captionStyle.copyWith(
          color: AppColors.textTertiary,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: AppTypography.h1Style.copyWith(
          color: AppColors.textPrimary,
        ),
        toolbarHeight: AppLayout.headerHeight,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.surface,
          minimumSize: const Size(
            double.infinity,
            AppSizes.primaryButtonHeight,
          ),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.lgRadius),
          textStyle: AppTypography.buttonStyle,
          elevation: 0,
          shadowColor: Colors.transparent,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.mutedSurface,
          foregroundColor: AppColors.textPrimary,
          minimumSize: const Size(
            double.infinity,
            AppSizes.secondaryButtonHeight,
          ),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.mdRadius),
          side: const BorderSide(color: AppColors.uiStroke, width: 1),
          textStyle: AppTypography.buttonStyle,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.mutedSurface,
        border: OutlineInputBorder(
          borderRadius: AppRadius.mdRadius,
          borderSide: const BorderSide(color: AppColors.uiStroke, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdRadius,
          borderSide: const BorderSide(color: AppColors.uiStroke, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdRadius,
          borderSide: const BorderSide(color: AppColors.borderFocus, width: 1),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdRadius,
          borderSide: const BorderSide(color: AppColors.danger, width: 1),
        ),
        contentPadding: AppSpacing.mdAll,
        hintStyle: AppTypography.bodyStyle.copyWith(
          color: AppColors.textTertiary,
        ),
        labelStyle: AppTypography.bodyStyle.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.mdRadius,
          side: const BorderSide(color: AppColors.uiStroke, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.primary,
        selectedItemColor: AppColors.surface,
        unselectedItemColor: AppColors.textTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      extensions: const [AppTheme()],
    );
  }
}
