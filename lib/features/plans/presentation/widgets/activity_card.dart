import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/activity_entity.dart';

/// A card widget displaying activity information.
///
/// Used in plan details, workout lists, and activity editing.
class ActivityCard extends StatelessWidget {
  /// Creates a new [ActivityCard].
  const ActivityCard({
    super.key,
    required this.activity,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.isCompleted = false,
    this.showDayLabel = true,
    this.trailing,
  });

  /// The activity to display.
  final ActivityEntity activity;

  /// Callback when the card is tapped.
  final VoidCallback? onTap;

  /// Callback when edit is pressed.
  final VoidCallback? onEdit;

  /// Callback when delete is pressed.
  final VoidCallback? onDelete;

  /// Whether this activity is completed (for athlete view).
  final bool isCompleted;

  /// Whether to show the day label.
  final bool showDayLabel;

  /// Optional trailing widget.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: isCompleted ? AppColors.success.withValues(alpha: 0.05) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        side: BorderSide(
          color: isCompleted
              ? AppColors.success.withValues(alpha: 0.3)
              : AppColors.border,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Row(
            children: [
              _buildTypeIcon(),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: _buildContent()),
              if (trailing != null) trailing!,
              if (onEdit != null || onDelete != null) _buildActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeIcon() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: _getTypeColor().withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Icon(_getTypeIcon(), color: _getTypeColor(), size: 20),
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                activity.name,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  decoration: isCompleted ? TextDecoration.lineThrough : null,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isCompleted)
              const Icon(
                Icons.check_circle,
                color: AppColors.success,
                size: 18,
              ),
          ],
        ),
        const SizedBox(height: 2),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xs,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: _getTypeColor().withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                ActivityTypes.displayName(activity.type),
                style: AppTextStyles.labelSmall.copyWith(
                  color: _getTypeColor(),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (activity.targetDuration != null) ...[
              const SizedBox(width: AppSpacing.xs),
              Text(
                activity.formattedDuration,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
            if (showDayLabel) ...[
              const SizedBox(width: AppSpacing.xs),
              Text(
                '• ${activity.dayName}',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
        if (activity.instructions != null &&
            activity.instructions!.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            activity.instructions!,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }

  Widget _buildActions() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (onEdit != null)
          IconButton(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined, size: 18),
            color: AppColors.textSecondary,
            visualDensity: VisualDensity.compact,
            tooltip: 'Edit',
          ),
        if (onDelete != null)
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline, size: 18),
            color: AppColors.error,
            visualDensity: VisualDensity.compact,
            tooltip: 'Delete',
          ),
      ],
    );
  }

  IconData _getTypeIcon() {
    switch (activity.type) {
      case ActivityTypes.cardio:
        return Icons.directions_run;
      case ActivityTypes.strength:
        return Icons.fitness_center;
      case ActivityTypes.flexibility:
        return Icons.self_improvement;
      case ActivityTypes.hiit:
        return Icons.flash_on;
      case ActivityTypes.rest:
        return Icons.hotel;
      default:
        return Icons.sports;
    }
  }

  Color _getTypeColor() {
    switch (activity.type) {
      case ActivityTypes.cardio:
        return AppColors.error;
      case ActivityTypes.strength:
        return AppColors.primary;
      case ActivityTypes.flexibility:
        return Colors.purple;
      case ActivityTypes.hiit:
        return Colors.orange;
      case ActivityTypes.rest:
        return AppColors.success;
      default:
        return AppColors.info;
    }
  }
}

/// A grouped list of activities by day.
class ActivitiesByDayList extends StatelessWidget {
  /// Creates a new [ActivitiesByDayList].
  const ActivitiesByDayList({
    super.key,
    required this.activitiesByDay,
    this.onActivityTap,
    this.onActivityEdit,
    this.onActivityDelete,
    this.completedActivityIds = const {},
  });

  /// Activities grouped by day of week.
  final Map<int, List<ActivityEntity>> activitiesByDay;

  /// Callback when an activity is tapped.
  final void Function(ActivityEntity)? onActivityTap;

  /// Callback when edit is pressed on an activity.
  final void Function(ActivityEntity)? onActivityEdit;

  /// Callback when delete is pressed on an activity.
  final void Function(ActivityEntity)? onActivityDelete;

  /// Set of completed activity IDs.
  final Set<String> completedActivityIds;

  @override
  Widget build(BuildContext context) {
    final sortedDays = activitiesByDay.keys.toList()..sort();

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sortedDays.length,
      itemBuilder: (context, index) {
        final day = sortedDays[index];
        final activities = activitiesByDay[day]!;

        return _DaySection(
          dayOfWeek: day,
          activities: activities,
          onActivityTap: onActivityTap,
          onActivityEdit: onActivityEdit,
          onActivityDelete: onActivityDelete,
          completedActivityIds: completedActivityIds,
        );
      },
    );
  }
}

class _DaySection extends StatelessWidget {
  const _DaySection({
    required this.dayOfWeek,
    required this.activities,
    this.onActivityTap,
    this.onActivityEdit,
    this.onActivityDelete,
    this.completedActivityIds = const {},
  });

  final int dayOfWeek;
  final List<ActivityEntity> activities;
  final void Function(ActivityEntity)? onActivityTap;
  final void Function(ActivityEntity)? onActivityEdit;
  final void Function(ActivityEntity)? onActivityDelete;
  final Set<String> completedActivityIds;

  static const _dayNames = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  @override
  Widget build(BuildContext context) {
    final dayName = _dayNames[(dayOfWeek - 1).clamp(0, 6)];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Text(
            dayName,
            style: AppTextStyles.titleSmall.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ...activities.map(
          (activity) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: ActivityCard(
              activity: activity,
              onTap: onActivityTap != null
                  ? () => onActivityTap!(activity)
                  : null,
              onEdit: onActivityEdit != null
                  ? () => onActivityEdit!(activity)
                  : null,
              onDelete: onActivityDelete != null
                  ? () => onActivityDelete!(activity)
                  : null,
              isCompleted: completedActivityIds.contains(activity.id),
              showDayLabel: false,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
      ],
    );
  }
}
