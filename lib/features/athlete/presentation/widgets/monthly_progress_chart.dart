import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/widgets.dart';

/// Data point for the monthly progress chart.
class MonthlyDataPoint {
  /// Creates a monthly data point.
  const MonthlyDataPoint({
    required this.week,
    required this.workouts,
    required this.duration,
  });

  /// Week number (1-4 or 1-5).
  final int week;

  /// Total workouts completed that week.
  final int workouts;

  /// Total duration in minutes that week.
  final int duration;
}

/// A line chart displaying monthly workout trends.
///
/// Shows workouts and duration over the past 4 weeks.
class MonthlyProgressChart extends StatefulWidget {
  /// Creates a monthly progress chart.
  const MonthlyProgressChart({required this.monthlyData, super.key});

  /// Weekly data points for the month.
  final List<MonthlyDataPoint> monthlyData;

  @override
  State<MonthlyProgressChart> createState() => _MonthlyProgressChartState();
}

class _MonthlyProgressChartState extends State<MonthlyProgressChart> {
  bool _showWorkouts = true;

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
              Text('Monthly Trends', style: AppTextStyles.titleMedium),
              _buildToggle(),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => AppColors.textPrimary,
                    tooltipPadding: const EdgeInsets.all(8),
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final value = spot.y.toInt();
                        final label = _showWorkouts
                            ? '$value workout${value != 1 ? 's' : ''}'
                            : '${value}min';
                        return LineTooltipItem(
                          'Week ${spot.x.toInt() + 1}\n$label',
                          AppTextStyles.labelSmall.copyWith(
                            color: AppColors.white,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: _calculateInterval(),
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: AppColors.textSecondary.withValues(alpha: 0.1),
                    strokeWidth: 1,
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
                      reservedSize: 40,
                      interval: _calculateInterval(),
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: widget.monthlyData.length - 1.0,
                minY: 0,
                maxY: _calculateMaxY(),
                lineBarsData: [_createLineData()],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggle() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildToggleButton('Workouts', _showWorkouts),
          _buildToggleButton('Duration', !_showWorkouts),
        ],
      ),
    );
  }

  Widget _buildToggleButton(String label, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _showWorkouts = label == 'Workouts';
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
        child: Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: isSelected ? AppColors.white : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  double _calculateMaxY() {
    if (widget.monthlyData.isEmpty) return 10;

    final values = _showWorkouts
        ? widget.monthlyData.map((d) => d.workouts)
        : widget.monthlyData.map((d) => d.duration);

    final maxValue = values.reduce((a, b) => a > b ? a : b);
    return (maxValue * 1.2).ceilToDouble();
  }

  double _calculateInterval() {
    final maxY = _calculateMaxY();
    if (maxY <= 10) return 2;
    if (maxY <= 50) return 10;
    if (maxY <= 100) return 20;
    return 50;
  }

  Widget _getBottomTitles(double value, TitleMeta meta) {
    return SideTitleWidget(
      meta: meta,
      child: Text(
        'W${value.toInt() + 1}',
        style: AppTextStyles.labelSmall.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _getLeftTitles(double value, TitleMeta meta) {
    if (value == value.roundToDouble()) {
      final label = _showWorkouts ? '${value.toInt()}' : '${value.toInt()}m';
      return SideTitleWidget(
        meta: meta,
        child: Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  LineChartBarData _createLineData() {
    final spots = widget.monthlyData.asMap().entries.map((entry) {
      final value = _showWorkouts
          ? entry.value.workouts.toDouble()
          : entry.value.duration.toDouble();
      return FlSpot(entry.key.toDouble(), value);
    }).toList();

    return LineChartBarData(
      spots: spots,
      isCurved: true,
      color: _showWorkouts ? AppColors.primary : AppColors.success,
      barWidth: 3,
      isStrokeCapRound: true,
      dotData: FlDotData(
        show: true,
        getDotPainter: (spot, percent, barData, index) {
          return FlDotCirclePainter(
            radius: 5,
            color: _showWorkouts ? AppColors.primary : AppColors.success,
            strokeWidth: 2,
            strokeColor: AppColors.white,
          );
        },
      ),
      belowBarData: BarAreaData(
        show: true,
        color: (_showWorkouts ? AppColors.primary : AppColors.success)
            .withValues(alpha: 0.1),
      ),
    );
  }
}
