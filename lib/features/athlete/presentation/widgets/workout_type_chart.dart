import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/widgets.dart';

/// Data for activity type distribution.
class ActivityTypeData {
  /// Creates activity type data.
  const ActivityTypeData({
    required this.type,
    required this.count,
    required this.color,
  });

  /// Activity type name.
  final String type;

  /// Number of activities of this type.
  final int count;

  /// Color for this activity type.
  final Color color;
}

/// A pie chart showing workout type distribution.
///
/// Displays the breakdown of workouts by activity type.
class WorkoutTypeChart extends StatefulWidget {
  /// Creates a workout type chart.
  const WorkoutTypeChart({required this.data, super.key});

  /// Activity type distribution data.
  final List<ActivityTypeData> data;

  @override
  State<WorkoutTypeChart> createState() => _WorkoutTypeChartState();
}

class _WorkoutTypeChartState extends State<WorkoutTypeChart> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    if (widget.data.isEmpty) {
      return BaseCard(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.pie_chart_outline,
                size: 48,
                color: AppColors.textSecondary.withValues(alpha: 0.5),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'No workout data yet',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final total = widget.data.fold<int>(0, (sum, d) => sum + d.count);

    return BaseCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Workout Types', style: AppTextStyles.titleMedium),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 160,
                  child: PieChart(
                    PieChartData(
                      pieTouchData: PieTouchData(
                        touchCallback: (event, response) {
                          setState(() {
                            if (!event.isInterestedForInteractions ||
                                response == null ||
                                response.touchedSection == null) {
                              _touchedIndex = -1;
                              return;
                            }
                            _touchedIndex =
                                response.touchedSection!.touchedSectionIndex;
                          });
                        },
                      ),
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                      sections: _generateSections(total),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: widget.data.map((data) {
                    final percentage = (data.count / total * 100).toInt();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                      child: _buildLegendItem(
                        data.type,
                        data.count,
                        percentage,
                        data.color,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(
    String label,
    int count,
    int percentage,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.bodySmall,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(
          '$count ($percentage%)',
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  List<PieChartSectionData> _generateSections(int total) {
    return widget.data.asMap().entries.map((entry) {
      final index = entry.key;
      final data = entry.value;
      final isTouched = index == _touchedIndex;
      final percentage = data.count / total * 100;

      return PieChartSectionData(
        value: data.count.toDouble(),
        title: isTouched ? '${percentage.toInt()}%' : '',
        color: data.color,
        radius: isTouched ? 50 : 40,
        titleStyle: AppTextStyles.labelSmall.copyWith(
          color: AppColors.white,
          fontWeight: FontWeight.bold,
        ),
      );
    }).toList();
  }
}

/// Default activity type colors.
abstract class ActivityTypeColors {
  /// Color for cardio activities.
  static const Color cardio = AppColors.primary;

  /// Color for strength activities.
  static const Color strength = AppColors.success;

  /// Color for flexibility activities.
  static const Color flexibility = AppColors.info;

  /// Color for HIIT activities.
  static const Color hiit = AppColors.warning;

  /// Color for rest days.
  static const Color rest = AppColors.textSecondary;

  /// Color for custom activities.
  static const Color custom = Color(0xFF9C27B0);

  /// Gets color for activity type.
  static Color getColor(String type) {
    switch (type.toLowerCase()) {
      case 'cardio':
        return cardio;
      case 'strength':
        return strength;
      case 'flexibility':
        return flexibility;
      case 'hiit':
        return hiit;
      case 'rest':
        return rest;
      default:
        return custom;
    }
  }
}
