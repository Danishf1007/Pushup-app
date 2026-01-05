/// Spacing constants used throughout the PushUp app.
///
/// Use these constants for consistent spacing across all widgets.
/// Never use hardcoded spacing values in widgets.
abstract class AppSpacing {
  // ============== Base Unit ==============
  /// Base spacing unit (4.0)
  static const double unit = 4.0;

  // ============== Standard Spacing ==============
  /// Extra extra small spacing (4.0)
  static const double xxs = 4.0;

  /// Extra small spacing (8.0)
  static const double xs = 8.0;

  /// Small spacing (12.0)
  static const double sm = 12.0;

  /// Medium spacing (16.0) - Default
  static const double md = 16.0;

  /// Large spacing (24.0)
  static const double lg = 24.0;

  /// Extra large spacing (32.0)
  static const double xl = 32.0;

  /// Extra extra large spacing (48.0)
  static const double xxl = 48.0;

  /// Extra extra extra large spacing (64.0)
  static const double xxxl = 64.0;

  // ============== Screen Padding ==============
  /// Horizontal screen padding
  static const double screenPaddingHorizontal = 16.0;

  /// Vertical screen padding
  static const double screenPaddingVertical = 24.0;

  // ============== Card Padding ==============
  /// Card internal padding
  static const double cardPadding = 16.0;

  /// Card margin
  static const double cardMargin = 8.0;

  // ============== Button Sizing ==============
  /// Button height - small
  static const double buttonHeightSmall = 36.0;

  /// Button height - medium
  static const double buttonHeightMedium = 44.0;

  /// Button height - large
  static const double buttonHeightLarge = 52.0;

  // ============== Input Sizing ==============
  /// Text field height
  static const double textFieldHeight = 56.0;

  // ============== Icon Sizing ==============
  /// Icon size - small
  static const double iconSmall = 16.0;

  /// Icon size - medium
  static const double iconMedium = 24.0;

  /// Icon size - large
  static const double iconLarge = 32.0;

  /// Icon size - extra large
  static const double iconXLarge = 48.0;

  // ============== Border Radius ==============
  /// Border radius - small
  static const double radiusSmall = 4.0;

  /// Border radius - medium
  static const double radiusMedium = 8.0;

  /// Border radius - large
  static const double radiusLarge = 12.0;

  /// Border radius - extra large
  static const double radiusXLarge = 16.0;

  /// Border radius - circular (for avatars)
  static const double radiusCircular = 999.0;

  // ============== Avatar Sizing ==============
  /// Avatar size - small
  static const double avatarSmall = 32.0;

  /// Avatar size - medium
  static const double avatarMedium = 48.0;

  /// Avatar size - large
  static const double avatarLarge = 64.0;

  /// Avatar size - extra large
  static const double avatarXLarge = 96.0;

  // ============== Bottom Navigation ==============
  /// Bottom navigation bar height
  static const double bottomNavHeight = 80.0;

  // ============== App Bar ==============
  /// App bar height
  static const double appBarHeight = 56.0;

  // ============== Convenience Aliases ==============
  /// Screen padding (default horizontal)
  static const double screenPadding = screenPaddingHorizontal;

  /// Short aliases for border radius
  static const double radiusSm = radiusSmall;
  static const double radiusMd = radiusMedium;
  static const double radiusLg = radiusLarge;
  static const double radiusXl = radiusXLarge;
}
