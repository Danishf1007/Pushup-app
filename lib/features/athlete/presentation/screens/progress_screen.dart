import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/entities.dart';
import '../providers/athlete_provider.dart';
import '../widgets/widgets.dart';

/// Detailed progress view screen for athletes.
///
/// Shows comprehensive statistics, streak information,
/// charts, and activity history.
class ProgressScreen extends ConsumerWidget {
  /// Creates a progress screen.
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);

    if (currentUser == null) {
      return const Scaffold(body: Center(child: LoadingIndicator()));
    }

    final statsAsync = ref.watch(athleteStatsStreamProvider(currentUser.id));
    final logsAsync = ref.watch(activityLogsStreamProvider(currentUser.id));
    final weeklyDataAsync = ref.watch(weeklyChartDataProvider(currentUser.id));
    final monthlyDataAsync = ref.watch(
      monthlyChartDataProvider(currentUser.id),
    );
    final typeDistributionAsync = ref.watch(
      workoutTypeDistributionProvider(currentUser.id),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Your Progress')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(athleteStatsStreamProvider(currentUser.id));
          ref.invalidate(activityLogsStreamProvider(currentUser.id));
          ref.invalidate(weeklyChartDataProvider(currentUser.id));
          ref.invalidate(monthlyChartDataProvider(currentUser.id));
          ref.invalidate(workoutTypeDistributionProvider(currentUser.id));
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStreakSection(statsAsync),
              const SizedBox(height: AppSpacing.xl),
              _buildOverallStats(statsAsync),
              const SizedBox(height: AppSpacing.xl),
              _buildWeeklyChart(weeklyDataAsync),
              const SizedBox(height: AppSpacing.xl),
              _buildMonthlyChart(monthlyDataAsync),
              const SizedBox(height: AppSpacing.xl),
              _buildWorkoutTypes(typeDistributionAsync),
              const SizedBox(height: AppSpacing.xl),
              _buildRecentActivities(logsAsync),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStreakSection(AsyncValue<AthleteStatsEntity> statsAsync) {
    return statsAsync.when(
      data: (stats) => _StreakCard(stats: stats),
      loading: () => _buildLoadingCard(height: 120),
      error: (e, _) => _buildErrorCard('Error loading streak data'),
    );
  }

  Widget _buildOverallStats(AsyncValue<AthleteStatsEntity> statsAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Overall Statistics', style: AppTextStyles.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        statsAsync.when(
          data: (stats) => Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _StatTile(
                      icon: Icons.fitness_center,
                      iconColor: AppColors.primary,
                      title: 'Total Workouts',
                      value: '${stats.totalWorkouts}',
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _StatTile(
                      icon: Icons.timer,
                      iconColor: AppColors.success,
                      title: 'Total Time',
                      value: stats.formattedTotalDuration,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: _StatTile(
                      icon: Icons.emoji_events,
                      iconColor: AppColors.warning,
                      title: 'Best Streak',
                      value: '${stats.longestStreak} days',
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _StatTile(
                      icon: Icons.speed,
                      iconColor: AppColors.info,
                      title: 'Avg. Duration',
                      value: _formatAvgDuration(stats),
                    ),
                  ),
                ],
              ),
            ],
          ),
          loading: () => _buildLoadingCard(height: 180),
          error: (e, _) => _buildErrorCard('Error loading statistics'),
        ),
      ],
    );
  }

  Widget _buildWeeklyChart(AsyncValue<List<int>> weeklyDataAsync) {
    return weeklyDataAsync.when(
      data: (data) => WeeklyActivityChart(weeklyData: data),
      loading: () => _buildLoadingCard(height: 250),
      error: (e, _) => _buildErrorCard('Error loading weekly chart'),
    );
  }

  Widget _buildMonthlyChart(
    AsyncValue<List<({int week, int workouts, int duration})>> monthlyDataAsync,
  ) {
    return monthlyDataAsync.when(
      data: (data) {
        final chartData = data
            .map(
              (d) => MonthlyDataPoint(
                week: d.week,
                workouts: d.workouts,
                duration: d.duration,
              ),
            )
            .toList();
        return MonthlyProgressChart(monthlyData: chartData);
      },
      loading: () => _buildLoadingCard(height: 250),
      error: (e, _) => _buildErrorCard('Error loading monthly chart'),
    );
  }

  Widget _buildWorkoutTypes(AsyncValue<Map<String, int>> distributionAsync) {
    return distributionAsync.when(
      data: (distribution) {
        final chartData = distribution.entries
            .map(
              (e) => ActivityTypeData(
                type: e.key,
                count: e.value,
                color: ActivityTypeColors.getColor(e.key),
              ),
            )
            .toList();
        return WorkoutTypeChart(data: chartData);
      },
      loading: () => _buildLoadingCard(height: 200),
      error: (e, _) => _buildErrorCard('Error loading workout types'),
    );
  }

  Widget _buildRecentActivities(AsyncValue<List<ActivityLogEntity>> logsAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Recent Activity', style: AppTextStyles.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        logsAsync.when(
          data: (logs) {
            if (logs.isEmpty) {
              return BaseCard(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.history,
                        size: 48,
                        color: AppColors.textSecondary.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'No activities logged yet',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Complete a workout to see it here',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return Column(
              children: logs.take(10).map((log) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: _ActivityHistoryItem(log: log),
                );
              }).toList(),
            );
          },
          loading: () => _buildLoadingCard(height: 200),
          error: (e, _) => _buildErrorCard('Error loading activities'),
        ),
      ],
    );
  }

  String _formatAvgDuration(AthleteStatsEntity stats) {
    if (stats.totalWorkouts == 0) return '0 min';
    final avg = stats.totalDuration ~/ stats.totalWorkouts;
    if (avg < 60) return '$avg min';
    final hours = avg ~/ 60;
    final mins = avg % 60;
    return '${hours}h ${mins}m';
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

class _StreakCard extends StatelessWidget {
  const _StreakCard({required this.stats});

  final AthleteStatsEntity stats;

  @override
  Widget build(BuildContext context) {
    final isActive = stats.currentStreak > 0;

    return BaseCard(
      backgroundColor: isActive ? AppColors.warning : AppColors.surface,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: (isActive ? AppColors.white : AppColors.warning)
                  .withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text('🔥', style: TextStyle(fontSize: isActive ? 32 : 24)),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${stats.currentStreak} Day Streak',
                  style: AppTextStyles.headlineSmall.copyWith(
                    color: isActive ? AppColors.white : AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  isActive
                      ? "You're on fire! Keep going!"
                      : 'Start a workout to begin your streak',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: isActive
                        ? AppColors.white.withValues(alpha: 0.8)
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;

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
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.xs),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: AppTextStyles.titleLarge.copyWith(
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

class _ActivityHistoryItem extends StatelessWidget {
  const _ActivityHistoryItem({required this.log});

  final ActivityLogEntity log;

  @override
  Widget build(BuildContext context) {
    return BaseCard(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _getEffortColor().withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.xs),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${log.completedAt.day}',
                  style: AppTextStyles.titleSmall.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _getMonthAbbr(log.completedAt.month),
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(log.activityName, style: AppTextStyles.titleSmall),
                Row(
                  children: [
                    Icon(
                      Icons.timer_outlined,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      log.formattedDuration,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _getEffortColor(),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      log.effortDescription,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: _getEffortColor(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (log.distance != null) ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  log.formattedDistance ?? '',
                  style: AppTextStyles.titleSmall.copyWith(
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  'km',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Color _getEffortColor() {
    if (log.effortLevel <= 3) return AppColors.success;
    if (log.effortLevel <= 6) return AppColors.warning;
    return AppColors.error;
  }

  String _getMonthAbbr(int month) {
    const months = [
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC',
    ];
    return months[month - 1];
  }
}
