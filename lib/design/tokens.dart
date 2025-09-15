import 'package:flutter/material.dart';

/// Spacing design tokens based on design.json specification
/// All values are in logical pixels and follow the 4-unit base system
class AppSpacing {
  AppSpacing._();

  // Base unit (4px)
  static const double unit = 4.0;

  // Spacing Scale
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;

  // Edge Insets shortcuts
  static const EdgeInsets xsAll = EdgeInsets.all(xs);
  static const EdgeInsets smAll = EdgeInsets.all(sm);
  static const EdgeInsets mdAll = EdgeInsets.all(md);
  static const EdgeInsets lgAll = EdgeInsets.all(lg);
  static const EdgeInsets xlAll = EdgeInsets.all(xl);
  static const EdgeInsets xxlAll = EdgeInsets.all(xxl);

  static const EdgeInsets xsHorizontal = EdgeInsets.symmetric(horizontal: xs);
  static const EdgeInsets smHorizontal = EdgeInsets.symmetric(horizontal: sm);
  static const EdgeInsets mdHorizontal = EdgeInsets.symmetric(horizontal: md);
  static const EdgeInsets lgHorizontal = EdgeInsets.symmetric(horizontal: lg);
  static const EdgeInsets xlHorizontal = EdgeInsets.symmetric(horizontal: xl);

  static const EdgeInsets xsVertical = EdgeInsets.symmetric(vertical: xs);
  static const EdgeInsets smVertical = EdgeInsets.symmetric(vertical: sm);
  static const EdgeInsets mdVertical = EdgeInsets.symmetric(vertical: md);
  static const EdgeInsets lgVertical = EdgeInsets.symmetric(vertical: lg);
  static const EdgeInsets xlVertical = EdgeInsets.symmetric(vertical: xl);
}

/// Border radius design tokens
class AppRadius {
  AppRadius._();

  static const double xs = 6.0;
  static const double sm = 12.0;
  static const double md = 18.0;
  static const double lg = 28.0;
  static const double pill = 999.0;

  // BorderRadius shortcuts
  static BorderRadius get xsRadius => BorderRadius.circular(xs);
  static BorderRadius get smRadius => BorderRadius.circular(sm);
  static BorderRadius get mdRadius => BorderRadius.circular(md);
  static BorderRadius get lgRadius => BorderRadius.circular(lg);
  static BorderRadius get pillRadius => BorderRadius.circular(pill);
}

/// Elevation and shadow design tokens
class AppElevation {
  AppElevation._();

  // Shadow configurations
  static List<BoxShadow> get none => [];

  static List<BoxShadow> get low => [
    BoxShadow(
      offset: const Offset(0, 4),
      blurRadius: 12,
      color: Colors.black.withOpacity(0.06),
    ),
  ];

  static List<BoxShadow> get medium => [
    BoxShadow(
      offset: const Offset(0, 8),
      blurRadius: 20,
      color: Colors.black.withOpacity(0.08),
    ),
  ];

  static List<BoxShadow> get high => [
    BoxShadow(
      offset: const Offset(0, 18),
      blurRadius: 40,
      color: Colors.black.withOpacity(0.12),
    ),
  ];
}

/// Layout design tokens
class AppLayout {
  AppLayout._();

  static const int columns = 4;
  static const double gutter = 16.0;
  static const double maxWidth = 412.0;
  static const double safePadding = 16.0;

  // Safe area paddings from design tokens
  static const EdgeInsets safeAreaPadding = EdgeInsets.only(
    top: 20.0,
    left: safePadding,
    right: safePadding,
    bottom: 24.0,
  );

  // App Shell specific measurements
  static const double bottomNavHeight = 72.0;
  static const double headerHeight = 72.0;
}

/// Component-specific sizes
class AppSizes {
  AppSizes._();

  // Button sizes
  static const double primaryButtonHeight = 52.0;
  static const double secondaryButtonHeight = 48.0;
  static const double iconButtonSize = 44.0;
  static const double backButtonSize = 40.0;

  // Input field sizes
  static const double inputFieldHeight = 56.0;
  static const double inputFieldPadding = 12.0;

  // Badge and indicator sizes
  static const double badgeSize = 18.0;
  static const double progressRingDefault = 220.0;
  static const double progressRingThickness = 14.0;

  // Calendar component sizes
  static const double calendarDayPillSize = 36.0;
  static const double calendarWeekGap = 8.0;

  // Chart component sizes
  static const double chartBarWidth = 8.0;
  static const double chartBarSpacing = 6.0;
  static const double chartLineStrokeWidth = 2.0;
  static const double chartPointRadius = 3.0;
  static const double chartHeightHint = 120.0;

  // Icon sizes
  static const double iconCircleSize = 44.0;

  // Touch targets (accessibility)
  static const double minTouchTarget = 44.0;
}
