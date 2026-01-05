import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/coach_analytics_provider.dart';

/// Coach Analytics Dashboard.
///
/// Displays comprehensive analytics about athletes' progress,
/// completion rates, and engagement metrics.
class CoachAnalyticsScreen extends ConsumerWidget {
  /// Creates a coach analytics screen.
  const CoachAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    if (currentUser == null) {
      return const Scaffold(body: Center(child: LoadingIndicator()));
    }

    final analyticsAsync = ref.watch(coachAnalyticsProvider(currentUser.id));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(coachAnalyticsProvider(currentUser.id));
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(coachAnalyticsProvider(currentUser.id));
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildOverviewCards(analyticsAsync),
              const SizedBox(height: AppSpacing.xl),
              _buildWeeklyActivityChart(analyticsAsync),
              const SizedBox(height: AppSpacing.xl),
              _buildAthleteStatusSection(analyticsAsync),
              const SizedBox(height: AppSpacing.xl),
              _buildCompletionRateChart(analyticsAsync),
              const SizedBox(height: AppSpacing.xl),
              _buildTopPerformers(analyticsAsync, context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewCards(AsyncValue<CoachAnalytics> analyticsAsync) {
    return analyticsAsync.when(
      data: (analytics) => Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _OverviewCard(
                  title: 'Total Athletes',
                  value: '${analytics.totalAthletes}',
                  icon: Icons.people,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _OverviewCard(
                  title: 'Active This Week',
                  value: '${analytics.activeThisWeek}',
                  icon: Icons.trending_up,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _OverviewCard(
                  title: 'Avg Completion',
                  value: '${analytics.avgCompletionRate.toInt()}%',
                  icon: Icons.check_circle_outline,
                  color: AppColors.info,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _OverviewCard(
                  title: 'Workouts Today',
                  value: '${analytics.workoutsToday}',
                  icon: Icons.fitness_center,
                  color: AppColors.warning,
                ),
              ),
            ],
          ),
        ],
      ),
      loading: () =>
          const SizedBox(height: 180, child: Center(child: LoadingIndicator())),
      error: (e, _) => BaseCard(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Center(
          child: Text(
            'Error loading analytics',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error),
          ),
        ),
      ),
    );
  }

  Widget _buildWeeklyActivityChart(AsyncValue<CoachAnalytics> analyticsAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Team Activity (This Week)', style: AppTextStyles.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        analyticsAsync.when(
          data: (analytics) => BaseCard(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: _calculateMaxY(analytics.weeklyTeamActivity),
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) => AppColors.textPrimary,
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
                          '${days[group.x]}: ${rod.toY.toInt()} workouts',
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
                        getTitlesWidget: (value, meta) {
                          const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                          return SideTitleWidget(
                            meta: meta,
                            child: Text(
                              days[value.toInt()],
                              style: AppTextStyles.labelSmall,
                            ),
                          );
                        },
                        reservedSize: 30,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        getTitlesWidget: (value, meta) {
                          if (value == value.roundToDouble()) {
                            return SideTitleWidget(
                              meta: meta,
                              child: Text(
                                '${value.toInt()}',
                                style: AppTextStyles.labelSmall,
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
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
                  barGroups: _generateBarGroups(analytics.weeklyTeamActivity),
                ),
              ),
            ),
          ),
          loading: () => _buildLoadingCard(height: 250),
          error: (e, _) => _buildErrorCard('Error loading chart'),
        ),
      ],
    );
  }

  double _calculateMaxY(List<int> data) {
    if (data.isEmpty) return 5;
    final maxValue = data.reduce((a, b) => a > b ? a : b);
    return (maxValue + 2).toDouble();
  }

  List<BarChartGroupData> _generateBarGroups(List<int> data) {
    final today = DateTime.now().weekday - 1;
    return List.generate(7, (index) {
      final value = index < data.length ? data[index] : 0;
      final isFuture = index > today;

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: value.toDouble(),
            color: isFuture
                ? AppColors.textSecondary.withValues(alpha: 0.2)
                : AppColors.primary,
            width: 16,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildAthleteStatusSection(AsyncValue<CoachAnalytics> analyticsAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Athlete Status', style: AppTextStyles.titleMedium),
            analyticsAsync.when(
              data: (analytics) => Row(
                children: [
                  _StatusBadge(
                    count: analytics.activeThisWeek,
                    color: AppColors.success,
                    label: 'Active',
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  _StatusBadge(
                    count: analytics.inactiveCount,
                    color: AppColors.warning,
                    label: 'Inactive',
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  _StatusBadge(
                    count: analytics.atRiskCount,
                    color: AppColors.error,
                    label: 'At Risk',
                  ),
                ],
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        analyticsAsync.when(
          data: (analytics) => BaseCard(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              children: [
                _buildStatusBar(
                  'Active',
                  analytics.activeThisWeek,
                  analytics.totalAthletes,
                  AppColors.success,
                ),
                const SizedBox(height: AppSpacing.sm),
                _buildStatusBar(
                  'Inactive (3+ days)',
                  analytics.inactiveCount,
                  analytics.totalAthletes,
                  AppColors.warning,
                ),
                const SizedBox(height: AppSpacing.sm),
                _buildStatusBar(
                  'At Risk (7+ days)',
                  analytics.atRiskCount,
                  analytics.totalAthletes,
                  AppColors.error,
                ),
              ],
            ),
          ),
          loading: () => _buildLoadingCard(height: 120),
          error: (e, _) => _buildErrorCard('Error loading status'),
        ),
      ],
    );
  }

  Widget _buildStatusBar(String label, int count, int total, Color color) {
    final percentage = total > 0 ? count / total : 0.0;

    return Row(
      children: [
        Expanded(flex: 2, child: Text(label, style: AppTextStyles.bodySmall)),
        Expanded(
          flex: 3,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: AppColors.surface,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        SizedBox(
          width: 40,
          child: Text(
            '$count',
            style: AppTextStyles.labelMedium.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  Widget _buildCompletionRateChart(AsyncValue<CoachAnalytics> analyticsAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Completion Rates', style: AppTextStyles.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        analyticsAsync.when(
          data: (analytics) {
            if (analytics.completionByAthlete.isEmpty) {
              return BaseCard(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Center(
                  child: Text(
                    'No completion data yet',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              );
            }

            return BaseCard(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: SizedBox(
                height: 200,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 50,
                    sections: _generateCompletionSections(analytics),
                    pieTouchData: PieTouchData(enabled: true),
                  ),
                ),
              ),
            );
          },
          loading: () => _buildLoadingCard(height: 250),
          error: (e, _) => _buildErrorCard('Error loading completion rates'),
        ),
      ],
    );
  }

  List<PieChartSectionData> _generateCompletionSections(
    CoachAnalytics analytics,
  ) {
    // Group athletes by completion rate ranges
    int excellent = 0; // 80-100%
    int good = 0; // 50-79%
    int needsWork = 0; // < 50%

    for (final entry in analytics.completionByAthlete.entries) {
      final rate = entry.value;
      if (rate >= 80) {
        excellent++;
      } else if (rate >= 50) {
        good++;
      } else {
        needsWork++;
      }
    }

    final total = excellent + good + needsWork;
    if (total == 0) return [];

    return [
      if (excellent > 0)
        PieChartSectionData(
          value: excellent.toDouble(),
          title: '${(excellent / total * 100).toInt()}%',
          color: AppColors.success,
          radius: 45,
          titleStyle: AppTextStyles.labelSmall.copyWith(
            color: AppColors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      if (good > 0)
        PieChartSectionData(
          value: good.toDouble(),
          title: '${(good / total * 100).toInt()}%',
          color: AppColors.warning,
          radius: 45,
          titleStyle: AppTextStyles.labelSmall.copyWith(
            color: AppColors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      if (needsWork > 0)
        PieChartSectionData(
          value: needsWork.toDouble(),
          title: '${(needsWork / total * 100).toInt()}%',
          color: AppColors.error,
          radius: 45,
          titleStyle: AppTextStyles.labelSmall.copyWith(
            color: AppColors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
    ];
  }

  Widget _buildTopPerformers(
    AsyncValue<CoachAnalytics> analyticsAsync,
    BuildContext context,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Top Performers', style: AppTextStyles.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        analyticsAsync.when(
          data: (analytics) {
            if (analytics.topPerformers.isEmpty) {
              return BaseCard(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Center(
                  child: Text(
                    'No performers yet',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              );
            }

            return Column(
              children: analytics.topPerformers.take(5).map((performer) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: _PerformerCard(
                    performer: performer,
                    onTap: () {
                      context.push(
                        RoutePaths.coachAthleteDetail.replaceFirst(
                          ':athleteId',
                          performer.athleteId,
                        ),
                      );
                    },
                  ),
                );
              }).toList(),
            );
          },
          loading: () => _buildLoadingCard(height: 200),
          error: (e, _) => _buildErrorCard('Error loading performers'),
        ),
      ],
    );
  }

  Widget _buildLoadingCard({required double height}) {
    return BaseCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: SizedBox(
        height: height,
        child: const Center(child: LoadingIndicator()),
      ),
    );
  }

  Widget _buildErrorCard(String message) {
    return BaseCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Center(
        child: Text(
          message,
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error),
        ),
      ),
    );
  }
}

// ============== Helper Widgets ==============

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return BaseCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.xs),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: AppTextStyles.headlineSmall.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.count,
    required this.color,
    required this.label,
  });

  final int count;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.xs),
      ),
      child: Text(
        '$count $label',
        style: AppTextStyles.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _PerformerCard extends StatelessWidget {
  const _PerformerCard({required this.performer, required this.onTap});

  final AthletePerformance performer;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: BaseCard(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _getMedalColor().withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.xs),
              ),
              child: Center(
                child: Text(_getMedal(), style: const TextStyle(fontSize: 20)),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(performer.athleteName, style: AppTextStyles.titleSmall),
                  Row(
                    children: [
                      Icon(
                        Icons.local_fire_department,
                        size: 14,
                        color: AppColors.warning,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${performer.streak} day streak',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${performer.completionRate.toInt()}%',
                  style: AppTextStyles.titleSmall.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${performer.workoutsCompleted} workouts',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(width: AppSpacing.xs),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  String _getMedal() {
    switch (performer.rank) {
      case 1:
        return '🥇';
      case 2:
        return '🥈';
      case 3:
        return '🥉';
      default:
        return '${performer.rank}';
    }
  }

  Color _getMedalColor() {
    switch (performer.rank) {
      case 1:
        return AppColors.warning;
      case 2:
        return AppColors.textSecondary;
      case 3:
        return const Color(0xFFCD7F32);
      default:
        return AppColors.primary;
    }
  }
}
