import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/entities.dart';

/// A card widget displaying training plan information.
///
/// Used in both the plans list and plan selection screens.
class PlanCard extends StatelessWidget {
  /// Creates a new [PlanCard].
  const PlanCard({
    super.key,
    required this.plan,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.onAssign,
    this.showActions = true,
    this.isSelected = false,
  });

  /// The training plan to display.
  final TrainingPlanEntity plan;

  /// Callback when the card is tapped.
  final VoidCallback? onTap;

  /// Callback when edit is pressed.
  final VoidCallback? onEdit;

  /// Callback when delete is pressed.
  final VoidCallback? onDelete;

  /// Callback when assign is pressed.
  final VoidCallback? onAssign;

  /// Whether to show action buttons.
  final bool showActions;

  /// Whether this card is selected (for selection mode).
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        side: isSelected
            ? const BorderSide(color: AppColors.primary, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: AppSpacing.sm),
              _buildStats(),
              if (plan.description != null && plan.description!.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                _buildDescription(),
              ],
              if (showActions) ...[
                const SizedBox(height: AppSpacing.md),
                _buildActions(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          child: const Icon(
            Icons.fitness_center,
            color: AppColors.primary,
            size: 24,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                plan.name,
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  if (plan.isTemplate) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xs,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.info.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Template',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.info,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                  ],
                  Text(
                    plan.formattedDuration,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (isSelected)
          const Icon(Icons.check_circle, color: AppColors.primary, size: 24),
      ],
    );
  }

  Widget _buildStats() {
    return Row(
      children: [
        _StatChip(
          icon: Icons.list_alt,
          label: '${plan.activityCount} activities',
        ),
        const SizedBox(width: AppSpacing.sm),
        _StatChip(
          icon: Icons.timer_outlined,
          label: _formatTotalDuration(plan.totalDuration),
        ),
      ],
    );
  }

  Widget _buildDescription() {
    return Text(
      plan.description!,
      style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (onAssign != null)
          TextButton.icon(
            onPressed: onAssign,
            icon: const Icon(Icons.person_add_outlined, size: 18),
            label: const Text('Assign'),
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
          ),
        if (onEdit != null)
          IconButton(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined, size: 20),
            color: AppColors.textSecondary,
            tooltip: 'Edit',
          ),
        if (onDelete != null)
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline, size: 20),
            color: AppColors.error,
            tooltip: 'Delete',
          ),
      ],
    );
  }

  String _formatTotalDuration(int minutes) {
    if (minutes == 0) return 'No duration';
    if (minutes < 60) return '$minutes min total';
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (mins == 0) return '${hours}h total';
    return '${hours}h ${mins}m total';
  }
}

/// Small chip showing a stat with an icon.
class _StatChip extends StatelessWidget {
  const _StatChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
