import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/widgets.dart';

/// A bar chart displaying weekly workout activity.
///
/// Shows workouts completed per day for the current week.
class WeeklyActivityChart extends StatelessWidget {
  /// Creates a weekly activity chart.
  const WeeklyActivityChart({
    required this.weeklyData,
    this.targetPerDay = 1,
    super.key,
  });

  /// Workout counts for each day of the week (Mon-Sun).
  final List<int> weeklyData;

  /// Target workouts per day for comparison.
  final int targetPerDay;

  @override
  Widget build(BuildContext context) {
    return BaseCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('This Week', style: AppTextStyles.titleMedium),
              _buildLegend(),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: _calculateMaxY(),
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => AppColors.textPrimary,
                    tooltipPadding: const EdgeInsets.all(8),
                    tooltipMargin: 8,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final days = [
                        'Mon',
                        'Tue',
                        'Wed',
                        'Thu',
                        'Fri',
                        'Sat',
                        'Sun',
                      ];
                      return BarTooltipItem(
                        '${days[group.x]}\n${rod.toY.toInt()} workout${rod.toY.toInt() != 1 ? 's' : ''}',
                        AppTextStyles.labelSmall.copyWith(
                          color: AppColors.white,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: _getBottomTitles,
                      reservedSize: 30,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: _getLeftTitles,
                      reservedSize: 28,
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 1,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: AppColors.textSecondary.withValues(alpha: 0.1),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: _generateBarGroups(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          'Completed',
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  double _calculateMaxY() {
    final maxValue = weeklyData.reduce((a, b) => a > b ? a : b);
    return (maxValue < targetPerDay ? targetPerDay : maxValue) + 1.0;
  }

  Widget _getBottomTitles(double value, TitleMeta meta) {
    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final today = DateTime.now().weekday - 1;
    final isToday = value.toInt() == today;

    return SideTitleWidget(
      meta: meta,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: isToday
            ? BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              )
            : null,
        child: Text(
          days[value.toInt()],
          style: AppTextStyles.labelSmall.copyWith(
            color: isToday ? AppColors.primary : AppColors.textSecondary,
            fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _getLeftTitles(double value, TitleMeta meta) {
    if (value == value.roundToDouble()) {
      return SideTitleWidget(
        meta: meta,
        child: Text(
          value.toInt().toString(),
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  List<BarChartGroupData> _generateBarGroups() {
    final today = DateTime.now().weekday - 1;

    return List.generate(7, (index) {
      final value = index < weeklyData.length ? weeklyData[index] : 0;
      final isToday = index == today;
      final isFuture = index > today;

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: value.toDouble(),
            color: isFuture
                ? AppColors.textSecondary.withValues(alpha: 0.2)
                : isToday
                ? AppColors.primary
                : AppColors.primary.withValues(alpha: 0.7),
            width: 20,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
        ],
      );
    });
  }
}
