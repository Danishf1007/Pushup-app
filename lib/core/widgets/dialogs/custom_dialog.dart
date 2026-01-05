import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../buttons/primary_button.dart';

/// Custom dialog widget following PushUp design system.
///
/// Base dialog for all modal dialogs in the app.
class CustomDialog extends StatelessWidget {
  /// Creates a custom dialog.
  const CustomDialog({
    super.key,
    required this.title,
    this.content,
    this.contentWidget,
    this.primaryButtonText,
    this.primaryButtonOnPressed,
    this.secondaryButtonText,
    this.secondaryButtonOnPressed,
    this.icon,
    this.iconColor,
    this.isDismissible = true,
  });

  /// Dialog title.
  final String title;

  /// Text content.
  final String? content;

  /// Custom content widget.
  final Widget? contentWidget;

  /// Primary button text.
  final String? primaryButtonText;

  /// Primary button callback.
  final VoidCallback? primaryButtonOnPressed;

  /// Secondary button text.
  final String? secondaryButtonText;

  /// Secondary button callback.
  final VoidCallback? secondaryButtonOnPressed;

  /// Optional header icon.
  final IconData? icon;

  /// Icon color.
  final Color? iconColor;

  /// Whether dialog can be dismissed by tapping outside.
  final bool isDismissible;

  /// Shows the dialog.
  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    String? content,
    Widget? contentWidget,
    String? primaryButtonText,
    VoidCallback? primaryButtonOnPressed,
    String? secondaryButtonText,
    VoidCallback? secondaryButtonOnPressed,
    IconData? icon,
    Color? iconColor,
    bool isDismissible = true,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: isDismissible,
      builder: (context) => CustomDialog(
        title: title,
        content: content,
        contentWidget: contentWidget,
        primaryButtonText: primaryButtonText,
        primaryButtonOnPressed: primaryButtonOnPressed,
        secondaryButtonText: secondaryButtonText,
        secondaryButtonOnPressed: secondaryButtonOnPressed,
        icon: icon,
        iconColor: iconColor,
        isDismissible: isDismissible,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            if (icon != null) ...[
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: (iconColor ?? AppColors.primary).withValues(
                    alpha: 0.1,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: iconColor ?? AppColors.primary,
                  size: 28,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],

            // Title
            Text(
              title,
              style: AppTextStyles.titleLarge,
              textAlign: TextAlign.center,
            ),

            // Content
            if (content != null || contentWidget != null) ...[
              const SizedBox(height: AppSpacing.sm),
              contentWidget ??
                  Text(
                    content!,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
            ],

            // Buttons
            if (primaryButtonText != null || secondaryButtonText != null) ...[
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  if (secondaryButtonText != null)
                    Expanded(
                      child: SecondaryButton(
                        text: secondaryButtonText!,
                        onPressed:
                            secondaryButtonOnPressed ??
                            () => Navigator.of(context).pop(),
                      ),
                    ),
                  if (secondaryButtonText != null && primaryButtonText != null)
                    const SizedBox(width: AppSpacing.sm),
                  if (primaryButtonText != null)
                    Expanded(
                      child: PrimaryButton(
                        text: primaryButtonText!,
                        onPressed: primaryButtonOnPressed,
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Confirmation dialog for destructive or important actions.
class ConfirmationDialog extends StatelessWidget {
  /// Creates a confirmation dialog.
  const ConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmText = 'Confirm',
    this.cancelText = 'Cancel',
    this.isDestructive = false,
    this.onConfirm,
  });

  /// Dialog title.
  final String title;

  /// Dialog message.
  final String message;

  /// Confirm button text.
  final String confirmText;

  /// Cancel button text.
  final String cancelText;

  /// Whether this is a destructive action.
  final bool isDestructive;

  /// Callback when confirmed.
  final VoidCallback? onConfirm;

  /// Shows the confirmation dialog.
  static Future<bool?> show({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    bool isDestructive = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: title,
        message: message,
        confirmText: confirmText,
        cancelText: cancelText,
        isDestructive: isDestructive,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Warning Icon
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: (isDestructive ? AppColors.error : AppColors.warning)
                    .withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isDestructive ? Icons.delete_outline : Icons.warning_amber,
                color: isDestructive ? AppColors.error : AppColors.warning,
                size: 28,
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Title
            Text(
              title,
              style: AppTextStyles.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),

            // Message
            Text(
              message,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: SecondaryButton(
                    text: cancelText,
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: SizedBox(
                    height: AppSpacing.buttonHeightLarge,
                    child: ElevatedButton(
                      onPressed: () {
                        onConfirm?.call();
                        Navigator.of(context).pop(true);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDestructive
                            ? AppColors.error
                            : AppColors.primary,
                        foregroundColor: AppColors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusMd,
                          ),
                        ),
                      ),
                      child: Text(
                        confirmText,
                        style: AppTextStyles.buttonLarge,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
