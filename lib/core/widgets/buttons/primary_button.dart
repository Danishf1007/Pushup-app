import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// Primary button widget following PushUp design system.
///
/// Use for main CTAs and primary actions throughout the app.
class PrimaryButton extends StatelessWidget {
  /// Creates a primary button.
  const PrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.isDisabled = false,
    this.icon,
    this.width,
  });

  /// Button label text.
  final String text;

  /// Callback when button is pressed.
  final VoidCallback? onPressed;

  /// Whether to show loading indicator.
  final bool isLoading;

  /// Whether button is disabled.
  final bool isDisabled;

  /// Optional leading icon.
  final IconData? icon;

  /// Optional fixed width. If null, uses full width.
  final double? width;

  @override
  Widget build(BuildContext context) {
    final isEnabled = !isDisabled && !isLoading && onPressed != null;

    return SizedBox(
      width: width ?? double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: isEnabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.primary.withOpacity(0.5),
          disabledForegroundColor: Colors.white.withOpacity(0.7),
          elevation: 2,
          shadowColor: AppColors.primary.withOpacity(0.3),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 22, color: Colors.white),
                    const SizedBox(width: 10),
                  ],
                  Text(
                    text,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Secondary button widget for less prominent actions.
class SecondaryButton extends StatelessWidget {
  /// Creates a secondary button.
  const SecondaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.isDisabled = false,
    this.icon,
    this.width,
  });

  /// Button label text.
  final String text;

  /// Callback when button is pressed.
  final VoidCallback? onPressed;

  /// Whether to show loading indicator.
  final bool isLoading;

  /// Whether button is disabled.
  final bool isDisabled;

  /// Optional leading icon.
  final IconData? icon;

  /// Optional fixed width. If null, uses full width.
  final double? width;

  @override
  Widget build(BuildContext context) {
    final isEnabled = !isDisabled && !isLoading && onPressed != null;

    return SizedBox(
      width: width ?? double.infinity,
      height: 56,
      child: OutlinedButton(
        onPressed: isEnabled ? onPressed : null,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          backgroundColor: Colors.white,
          side: BorderSide(
            color: isEnabled
                ? AppColors.primary
                : AppColors.primary.withOpacity(0.5),
            width: 2,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: isLoading
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 22, color: AppColors.primary),
                    const SizedBox(width: 10),
                  ],
                  Text(
                    text,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Text button widget for tertiary actions.
class TertiaryButton extends StatelessWidget {
  /// Creates a tertiary/text button.
  const TertiaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isDisabled = false,
    this.icon,
  });

  /// Button label text.
  final String text;

  /// Callback when button is pressed.
  final VoidCallback? onPressed;

  /// Whether button is disabled.
  final bool isDisabled;

  /// Optional leading icon.
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final isEnabled = !isDisabled && onPressed != null;

    return TextButton(
      onPressed: isEnabled ? onPressed : null,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20, color: AppColors.primary),
            const SizedBox(width: 8),
          ],
          Text(
            text,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isEnabled
                  ? AppColors.primary
                  : AppColors.primary.withOpacity(0.5),
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
