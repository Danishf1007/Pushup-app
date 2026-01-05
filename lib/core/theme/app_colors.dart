import 'package:flutter/material.dart';

/// App color palette for PushUp.
///
/// All colors used in the app should be defined here.
/// Never use hardcoded colors in widgets - always reference this class.
abstract class AppColors {
  // ============== Primary Colors ==============
  /// Primary brand color - vibrant orange/coral
  static const Color primary = Color(0xFFFF6B35);
  static const Color primaryLight = Color(0xFFFF8A5C);
  static const Color primaryDark = Color(0xFFE55A2B);

  // ============== Secondary Colors ==============
  /// Secondary color - deep blue
  static const Color secondary = Color(0xFF2D3A4A);
  static const Color secondaryLight = Color(0xFF3D4D5F);
  static const Color secondaryDark = Color(0xFF1D2A3A);

  // ============== Accent Colors ==============
  /// Success green
  static const Color success = Color(0xFF4CAF50);
  static const Color successLight = Color(0xFF81C784);
  static const Color successDark = Color(0xFF388E3C);

  /// Warning yellow
  static const Color warning = Color(0xFFFFB300);
  static const Color warningLight = Color(0xFFFFCA28);
  static const Color warningDark = Color(0xFFFFA000);

  /// Error red
  static const Color error = Color(0xFFE53935);
  static const Color errorLight = Color(0xFFEF5350);
  static const Color errorDark = Color(0xFFC62828);

  /// Info blue
  static const Color info = Color(0xFF2196F3);
  static const Color infoLight = Color(0xFF64B5F6);
  static const Color infoDark = Color(0xFF1976D2);

  // ============== Neutral Colors ==============
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);

  /// Background colors
  static const Color backgroundLight = Color(0xFFF8F9FA);
  static const Color backgroundDark = Color(0xFF121212);

  /// Surface colors
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1E1E1E);

  /// Card colors
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color cardDark = Color(0xFF2C2C2C);

  // ============== Text Colors ==============
  /// Primary text
  static const Color textPrimaryLight = Color(0xFF212121);
  static const Color textPrimaryDark = Color(0xFFE0E0E0);

  /// Secondary text
  static const Color textSecondaryLight = Color(0xFF757575);
  static const Color textSecondaryDark = Color(0xFF9E9E9E);

  /// Disabled text
  static const Color textDisabledLight = Color(0xFFBDBDBD);
  static const Color textDisabledDark = Color(0xFF616161);

  // ============== Border Colors ==============
  static const Color borderLight = Color(0xFFE0E0E0);
  static const Color borderDark = Color(0xFF424242);

  // ============== Divider Colors ==============
  static const Color dividerLight = Color(0xFFEEEEEE);
  static const Color dividerDark = Color(0xFF373737);

  // ============== Status Indicator Colors ==============
  /// For athlete status tracking
  static const Color statusOnTrack = Color(
    0xFF4CAF50,
  ); // Green - 80%+ completion
  static const Color statusNeedsAttention = Color(
    0xFFFFB300,
  ); // Yellow - 50-80%
  static const Color statusFallingBehind = Color(0xFFE53935); // Red - <50%

  // ============== Gradient Colors ==============
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [secondary, secondaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ============== Convenience Getters (Light Theme Defaults) ==============
  /// These provide easy access to light theme colors for widgets
  static const Color surface = surfaceLight;
  static const Color surfaceVariant = Color(0xFFF5F5F5);
  static const Color textPrimary = textPrimaryLight;
  static const Color textSecondary = textSecondaryLight;
  static const Color textDisabled = textDisabledLight;
  static const Color border = borderLight;
  static const Color divider = dividerLight;
  static const Color background = backgroundLight;
  static const Color card = cardLight;
  static const Color shadow = Color(0xFF000000);
}
