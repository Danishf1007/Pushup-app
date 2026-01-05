import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';

/// Base card widget following PushUp design system.
///
/// Use as foundation for all card-based components.
class BaseCard extends StatelessWidget {
  /// Creates a base card.
  const BaseCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.backgroundColor,
    this.borderColor,
    this.borderRadius,
    this.elevation = 0,
  });

  /// Card content.
  final Widget child;

  /// Internal padding.
  final EdgeInsetsGeometry? padding;

  /// External margin.
  final EdgeInsetsGeometry? margin;

  /// Callback when card is tapped.
  final VoidCallback? onTap;

  /// Card background color.
  final Color? backgroundColor;

  /// Border color.
  final Color? borderColor;

  /// Border radius.
  final double? borderRadius;

  /// Card elevation.
  final double elevation;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      margin: margin,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.surface,
        borderRadius: BorderRadius.circular(
          borderRadius ?? AppSpacing.radiusMd,
        ),
        border: Border.all(color: borderColor ?? AppColors.border, width: 1),
        boxShadow: elevation > 0
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05 * elevation),
                  blurRadius: 4 * elevation,
                  offset: Offset(0, 2 * elevation),
                ),
              ]
            : null,
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(AppSpacing.md),
        child: child,
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(
          borderRadius ?? AppSpacing.radiusMd,
        ),
        child: card,
      );
    }

    return card;
  }
}

/// Info card for displaying labeled information.
class InfoCard extends StatelessWidget {
  /// Creates an info card.
  const InfoCard({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.iconColor,
    this.onTap,
  });

  /// Card label.
  final String label;

  /// Card value.
  final String value;

  /// Optional leading icon.
  final IconData? icon;

  /// Icon color.
  final Color? iconColor;

  /// Callback when tapped.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return BaseCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          if (icon != null) ...[
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: (iconColor ?? AppColors.primary).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Icon(
                icon,
                color: iconColor ?? AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(value, style: AppTextStyles.titleMedium),
              ],
            ),
          ),
          if (onTap != null)
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
        ],
      ),
    );
  }
}

/// Stat card for displaying metrics and statistics.
class StatCard extends StatelessWidget {
  /// Creates a stat card.
  const StatCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    this.icon,
    this.iconColor,
    this.trend,
    this.trendPositive = true,
  });

  /// Card title.
  final String title;

  /// Main value to display.
  final String value;

  /// Optional subtitle.
  final String? subtitle;

  /// Optional icon.
  final IconData? icon;

  /// Icon color.
  final Color? iconColor;

  /// Optional trend indicator (e.g., "+12%").
  final String? trend;

  /// Whether trend is positive.
  final bool trendPositive;

  @override
  Widget build(BuildContext context) {
    return BaseCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  color: iconColor ?? AppColors.textSecondary,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.xs),
              ],
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              if (trend != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                    vertical: AppSpacing.xxs,
                  ),
                  decoration: BoxDecoration(
                    color: (trendPositive ? AppColors.success : AppColors.error)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Text(
                    trend!,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: trendPositive
                          ? AppColors.success
                          : AppColors.error,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: AppTextStyles.headlineLarge.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: AppSpacing.xxs),
            Text(
              subtitle!,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
