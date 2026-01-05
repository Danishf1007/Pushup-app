import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_text_styles.dart';

/// App theme configuration for PushUp.
///
/// Contains both light and dark theme definitions.
/// All theme customizations should be made here.
abstract class AppTheme {
  // ============== Light Theme ==============
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: _lightColorScheme,
      scaffoldBackgroundColor: AppColors.backgroundLight,
      appBarTheme: _lightAppBarTheme,
      cardTheme: _lightCardTheme,
      elevatedButtonTheme: _elevatedButtonTheme,
      outlinedButtonTheme: _outlinedButtonTheme,
      textButtonTheme: _textButtonTheme,
      inputDecorationTheme: _lightInputDecorationTheme,
      bottomNavigationBarTheme: _lightBottomNavTheme,
      floatingActionButtonTheme: _fabTheme,
      dividerTheme: _lightDividerTheme,
      textTheme: _textTheme,
      iconTheme: const IconThemeData(
        color: AppColors.textPrimaryLight,
        size: AppSpacing.iconMedium,
      ),
    );
  }

  // ============== Dark Theme ==============
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: _darkColorScheme,
      scaffoldBackgroundColor: AppColors.backgroundDark,
      appBarTheme: _darkAppBarTheme,
      cardTheme: _darkCardTheme,
      elevatedButtonTheme: _elevatedButtonTheme,
      outlinedButtonTheme: _outlinedButtonTheme,
      textButtonTheme: _textButtonTheme,
      inputDecorationTheme: _darkInputDecorationTheme,
      bottomNavigationBarTheme: _darkBottomNavTheme,
      floatingActionButtonTheme: _fabTheme,
      dividerTheme: _darkDividerTheme,
      textTheme: _textTheme,
      iconTheme: const IconThemeData(
        color: AppColors.textPrimaryDark,
        size: AppSpacing.iconMedium,
      ),
    );
  }

  // ============== Color Schemes ==============
  static const ColorScheme _lightColorScheme = ColorScheme.light(
    primary: AppColors.primary,
    primaryContainer: AppColors.primaryLight,
    secondary: AppColors.secondary,
    secondaryContainer: AppColors.secondaryLight,
    surface: AppColors.surfaceLight,
    error: AppColors.error,
    onPrimary: AppColors.white,
    onSecondary: AppColors.white,
    onSurface: AppColors.textPrimaryLight,
    onError: AppColors.white,
  );

  static const ColorScheme _darkColorScheme = ColorScheme.dark(
    primary: AppColors.primary,
    primaryContainer: AppColors.primaryDark,
    secondary: AppColors.secondary,
    secondaryContainer: AppColors.secondaryDark,
    surface: AppColors.surfaceDark,
    error: AppColors.error,
    onPrimary: AppColors.white,
    onSecondary: AppColors.white,
    onSurface: AppColors.textPrimaryDark,
    onError: AppColors.white,
  );

  // ============== App Bar Themes ==============
  static const AppBarTheme _lightAppBarTheme = AppBarTheme(
    elevation: 0,
    centerTitle: true,
    backgroundColor: AppColors.surfaceLight,
    foregroundColor: AppColors.textPrimaryLight,
    iconTheme: IconThemeData(color: AppColors.textPrimaryLight),
    titleTextStyle: TextStyle(
      color: AppColors.textPrimaryLight,
      fontSize: 20,
      fontWeight: FontWeight.w600,
    ),
  );

  static const AppBarTheme _darkAppBarTheme = AppBarTheme(
    elevation: 0,
    centerTitle: true,
    backgroundColor: AppColors.surfaceDark,
    foregroundColor: AppColors.textPrimaryDark,
    iconTheme: IconThemeData(color: AppColors.textPrimaryDark),
    titleTextStyle: TextStyle(
      color: AppColors.textPrimaryDark,
      fontSize: 20,
      fontWeight: FontWeight.w600,
    ),
  );

  // ============== Card Themes ==============
  static const CardThemeData _lightCardTheme = CardThemeData(
    elevation: 2,
    color: AppColors.cardLight,
    shadowColor: Colors.black12,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(AppSpacing.radiusLarge)),
    ),
  );

  static const CardThemeData _darkCardTheme = CardThemeData(
    elevation: 2,
    color: AppColors.cardDark,
    shadowColor: Colors.black26,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(AppSpacing.radiusLarge)),
    ),
  );

  // ============== Button Themes ==============
  static final ElevatedButtonThemeData _elevatedButtonTheme =
      ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          minimumSize: const Size(
            double.infinity,
            AppSpacing.buttonHeightMedium,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          ),
          textStyle: AppTextStyles.buttonMedium,
        ),
      );

  static final OutlinedButtonThemeData _outlinedButtonTheme =
      OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          minimumSize: const Size(
            double.infinity,
            AppSpacing.buttonHeightMedium,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          ),
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          textStyle: AppTextStyles.buttonMedium,
        ),
      );

  static final TextButtonThemeData _textButtonTheme = TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: AppColors.primary,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      textStyle: AppTextStyles.buttonMedium,
    ),
  );

  // ============== Input Decoration Themes ==============
  static final InputDecorationTheme _lightInputDecorationTheme =
      InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceLight,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        labelStyle: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textSecondaryLight,
        ),
        hintStyle: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textDisabledLight,
        ),
        errorStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
      );

  static final InputDecorationTheme _darkInputDecorationTheme =
      InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceDark,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          borderSide: const BorderSide(color: AppColors.borderDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          borderSide: const BorderSide(color: AppColors.borderDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        labelStyle: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textSecondaryDark,
        ),
        hintStyle: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textDisabledDark,
        ),
        errorStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
      );

  // ============== Bottom Navigation Themes ==============
  static const BottomNavigationBarThemeData _lightBottomNavTheme =
      BottomNavigationBarThemeData(
        backgroundColor: AppColors.surfaceLight,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondaryLight,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      );

  static const BottomNavigationBarThemeData _darkBottomNavTheme =
      BottomNavigationBarThemeData(
        backgroundColor: AppColors.surfaceDark,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondaryDark,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      );

  // ============== FAB Theme ==============
  static final FloatingActionButtonThemeData _fabTheme =
      FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        elevation: 6,
        extendedPadding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 16,
        ),
        extendedTextStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      );

  // ============== Divider Themes ==============
  static const DividerThemeData _lightDividerTheme = DividerThemeData(
    color: AppColors.dividerLight,
    thickness: 1,
    space: AppSpacing.md,
  );

  static const DividerThemeData _darkDividerTheme = DividerThemeData(
    color: AppColors.dividerDark,
    thickness: 1,
    space: AppSpacing.md,
  );

  // ============== Text Theme ==============
  static const TextTheme _textTheme = TextTheme(
    displayLarge: AppTextStyles.displayLarge,
    displayMedium: AppTextStyles.displayMedium,
    displaySmall: AppTextStyles.displaySmall,
    headlineLarge: AppTextStyles.headlineLarge,
    headlineMedium: AppTextStyles.headlineMedium,
    headlineSmall: AppTextStyles.headlineSmall,
    titleLarge: AppTextStyles.titleLarge,
    titleMedium: AppTextStyles.titleMedium,
    titleSmall: AppTextStyles.titleSmall,
    bodyLarge: AppTextStyles.bodyLarge,
    bodyMedium: AppTextStyles.bodyMedium,
    bodySmall: AppTextStyles.bodySmall,
    labelLarge: AppTextStyles.labelLarge,
    labelMedium: AppTextStyles.labelMedium,
    labelSmall: AppTextStyles.labelSmall,
  );
}
