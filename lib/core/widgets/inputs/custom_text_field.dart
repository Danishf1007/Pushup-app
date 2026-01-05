import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';

/// Custom text field widget following PushUp design system.
///
/// Use for all text input fields throughout the app.
class CustomTextField extends StatefulWidget {
  /// Creates a custom text field.
  const CustomTextField({
    super.key,
    required this.label,
    this.controller,
    this.hintText,
    this.errorText,
    this.helperText,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixIconPressed,
    this.obscureText = false,
    this.enabled = true,
    this.readOnly = false,
    this.maxLines = 1,
    this.maxLength,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.focusNode,
    this.autofocus = false,
    this.textCapitalization = TextCapitalization.none,
  });

  /// Field label displayed above the input.
  final String label;

  /// Text editing controller.
  final TextEditingController? controller;

  /// Placeholder text.
  final String? hintText;

  /// Error message to display.
  final String? errorText;

  /// Helper text displayed below input.
  final String? helperText;

  /// Icon displayed at the start of input.
  final IconData? prefixIcon;

  /// Icon displayed at the end of input.
  final IconData? suffixIcon;

  /// Callback when suffix icon is pressed.
  final VoidCallback? onSuffixIconPressed;

  /// Whether to obscure text (for passwords).
  final bool obscureText;

  /// Whether the field is enabled.
  final bool enabled;

  /// Whether the field is read-only.
  final bool readOnly;

  /// Maximum number of lines.
  final int maxLines;

  /// Maximum character length.
  final int? maxLength;

  /// Keyboard type.
  final TextInputType? keyboardType;

  /// Text input action (done, next, etc.).
  final TextInputAction? textInputAction;

  /// Input formatters for validation.
  final List<TextInputFormatter>? inputFormatters;

  /// Validation function.
  final String? Function(String?)? validator;

  /// Callback when text changes.
  final ValueChanged<String>? onChanged;

  /// Callback when submitted.
  final ValueChanged<String>? onSubmitted;

  /// Callback when tapped.
  final VoidCallback? onTap;

  /// Focus node for managing focus.
  final FocusNode? focusNode;

  /// Whether to autofocus on build.
  final bool autofocus;

  /// Text capitalization behavior.
  final TextCapitalization textCapitalization;

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  late bool _obscureText;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    final hasError = widget.errorText != null && widget.errorText!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Label
        Text(
          widget.label,
          style: AppTextStyles.labelMedium.copyWith(
            color: hasError ? AppColors.error : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),

        // Text Field
        TextFormField(
          controller: widget.controller,
          focusNode: widget.focusNode,
          obscureText: _obscureText,
          enabled: widget.enabled,
          readOnly: widget.readOnly,
          maxLines: widget.obscureText ? 1 : widget.maxLines,
          maxLength: widget.maxLength,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          inputFormatters: widget.inputFormatters,
          validator: widget.validator,
          onChanged: widget.onChanged,
          onFieldSubmitted: widget.onSubmitted,
          onTap: widget.onTap,
          autofocus: widget.autofocus,
          textCapitalization: widget.textCapitalization,
          style: AppTextStyles.bodyLarge,
          decoration: InputDecoration(
            hintText: widget.hintText,
            hintStyle: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textSecondary,
            ),
            errorText: hasError ? widget.errorText : null,
            helperText: widget.helperText,
            helperMaxLines: 2,
            counterText: '',
            prefixIcon: widget.prefixIcon != null
                ? Icon(
                    widget.prefixIcon,
                    color: hasError ? AppColors.error : AppColors.textSecondary,
                    size: 22,
                  )
                : null,
            suffixIcon: _buildSuffixIcon(hasError),
            filled: true,
            fillColor: widget.enabled
                ? AppColors.surfaceLight
                : AppColors.surfaceLight.withValues(alpha: 0.5),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              borderSide: const BorderSide(color: AppColors.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              borderSide: const BorderSide(color: AppColors.error, width: 2),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              borderSide: BorderSide(
                color: AppColors.border.withValues(alpha: 0.5),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget? _buildSuffixIcon(bool hasError) {
    // Password visibility toggle
    if (widget.obscureText) {
      return IconButton(
        icon: Icon(
          _obscureText ? Icons.visibility_off : Icons.visibility,
          color: AppColors.textSecondary,
          size: 22,
        ),
        onPressed: () {
          setState(() {
            _obscureText = !_obscureText;
          });
        },
      );
    }

    // Custom suffix icon
    if (widget.suffixIcon != null) {
      return IconButton(
        icon: Icon(
          widget.suffixIcon,
          color: hasError ? AppColors.error : AppColors.textSecondary,
          size: 22,
        ),
        onPressed: widget.onSuffixIconPressed,
      );
    }

    return null;
  }
}

/// Password text field with visibility toggle.
class PasswordTextField extends StatelessWidget {
  /// Creates a password text field.
  const PasswordTextField({
    super.key,
    required this.label,
    this.controller,
    this.hintText,
    this.errorText,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.textInputAction,
    this.focusNode,
    this.autofocus = false,
  });

  /// Field label.
  final String label;

  /// Text editing controller.
  final TextEditingController? controller;

  /// Placeholder text.
  final String? hintText;

  /// Error message to display.
  final String? errorText;

  /// Validation function.
  final String? Function(String?)? validator;

  /// Callback when text changes.
  final ValueChanged<String>? onChanged;

  /// Callback when submitted.
  final ValueChanged<String>? onSubmitted;

  /// Text input action.
  final TextInputAction? textInputAction;

  /// Focus node.
  final FocusNode? focusNode;

  /// Whether to autofocus.
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      label: label,
      controller: controller,
      hintText: hintText ?? 'Enter your password',
      errorText: errorText,
      prefixIcon: Icons.lock_outline,
      obscureText: true,
      validator: validator,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      textInputAction: textInputAction,
      focusNode: focusNode,
      autofocus: autofocus,
    );
  }
}
