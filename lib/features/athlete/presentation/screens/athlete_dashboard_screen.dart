import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../achievements/presentation/providers/achievement_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../notifications/presentation/widgets/notification_badge.dart';
import '../../../plans/domain/entities/entities.dart';
import '../../domain/entities/entities.dart';
import '../providers/athlete_provider.dart';

/// Athlete Dashboard - Home screen for athletes.
///
/// Displays today's workout, progress overview, and quick actions.
class AthleteDashboardScreen extends ConsumerStatefulWidget {
  /// Creates an athlete dashboard screen.
  const AthleteDashboardScreen({super.key});

  @override
  ConsumerState<AthleteDashboardScreen> createState() =>
      _AthleteDashboardScreenState();
}

class _AthleteDashboardScreenState
    extends ConsumerState<AthleteDashboardScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hello${currentUser != null ? ", ${currentUser.displayName.split(' ').first}" : ""}! 👋',
              style: AppTextStyles.titleLarge,
            ),
            Text(
              _getGreetingMessage(),
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          // Messaging button for athletes
          IconButton(
            icon: const Icon(Icons.message_outlined),
            onPressed: () => context.push(RoutePaths.conversations),
            tooltip: 'Messages',
          ),
          if (currentUser != null)
            NotificationBadge(
              userId: currentUser.id,
              onTap: () => context.push(RoutePaths.notifications),
            ),
          IconButton(
            icon: const CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primary,
              child: Icon(Icons.person, size: 18, color: AppColors.white),
            ),
            onPressed: () => _onNavTap(3),
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onNavTap,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_outlined),
            activeIcon: Icon(Icons.assignment),
            label: 'Plans',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined),
            activeIcon: Icon(Icons.bar_chart),
            label: 'Progress',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  void _onNavTap(int index) {
    setState(() => _currentIndex = index);
  }

  String _getGreetingMessage() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return "Ready for today's workout?";
    } else if (hour < 18) {
      return 'Keep pushing through!';
    } else {
      return 'Finish the day strong!';
    }
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 1:
        return _buildPlansTab();
      case 2:
        return _buildProgressTab();
      case 3:
        return _buildProfileTab();
      default:
        return _buildHomeTab();
    }
  }

  Widget _buildHomeTab() {
    final currentUser = ref.watch(currentUserProvider);
    if (currentUser == null) {
      return const Center(child: LoadingIndicator());
    }

    final todaysActivitiesAsync = ref.watch(
      todaysActivitiesProvider(currentUser.id),
    );
    final statsAsync = ref.watch(athleteStatsStreamProvider(currentUser.id));
    final upcomingAsync = ref.watch(upcomingActivitiesProvider(currentUser.id));

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(todaysActivitiesProvider(currentUser.id));
        ref.invalidate(athleteStatsStreamProvider(currentUser.id));
        ref.invalidate(upcomingActivitiesProvider(currentUser.id));
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTodaysWorkout(todaysActivitiesAsync),
            const SizedBox(height: AppSpacing.lg),
            _buildProgressOverview(statsAsync),
            const SizedBox(height: AppSpacing.lg),
            _buildQuickStats(statsAsync),
            const SizedBox(height: AppSpacing.lg),
            _buildAchievementsPreview(currentUser.id),
            const SizedBox(height: AppSpacing.lg),
            _buildUpcomingWorkouts(upcomingAsync),
          ],
        ),
      ),
    );
  }

  Widget _buildTodaysWorkout(AsyncValue<List<ActivityEntity>> activitiesAsync) {
    return activitiesAsync.when(
      data: (activities) {
        if (activities.isEmpty) {
          return _buildNoWorkoutCard();
        }
        return _TodaysWorkoutCard(
          activities: activities,
          onStart: () => _navigateToWorkout(activities.first),
        );
      },
      loading: () => _buildLoadingWorkoutCard(),
      error: (e, _) => _buildNoWorkoutCard(),
    );
  }

  Widget _buildNoWorkoutCard() {
    return BaseCard(
      backgroundColor: AppColors.surfaceVariant,
      child: Column(
        children: [
          const Icon(
            Icons.check_circle_outline,
            size: 48,
            color: AppColors.success,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'No workouts scheduled today',
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Take a rest day or explore your plan',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingWorkoutCard() {
    return BaseCard(
      backgroundColor: AppColors.primary,
      borderColor: AppColors.primary,
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.fitness_center, color: AppColors.white),
              const SizedBox(width: AppSpacing.xs),
              Text(
                "TODAY'S WORKOUT",
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.white.withValues(alpha: 0.8),
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          const LoadingIndicator(color: AppColors.white),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }

  Widget _buildProgressOverview(AsyncValue<AthleteStatsEntity> statsAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('This Week', style: AppTextStyles.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        statsAsync.when(
          data: (stats) => Row(
            children: [
              Expanded(
                child: StatCard(
                  title: 'Workouts',
                  value: '${stats.weeklyWorkouts}',
                  icon: Icons.fitness_center,
                  iconColor: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: StatCard(
                  title: 'Duration',
                  value: stats.formattedWeeklyDuration,
                  icon: Icons.timer_outlined,
                  iconColor: AppColors.success,
                ),
              ),
            ],
          ),
          loading: () => Row(
            children: [
              Expanded(
                child: StatCard(
                  title: 'Workouts',
                  value: '--',
                  icon: Icons.fitness_center,
                  iconColor: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: StatCard(
                  title: 'Duration',
                  value: '--',
                  icon: Icons.timer_outlined,
                  iconColor: AppColors.success,
                ),
              ),
            ],
          ),
          error: (_, __) => const Text('Error loading stats'),
        ),
      ],
    );
  }

  Widget _buildQuickStats(AsyncValue<AthleteStatsEntity> statsAsync) {
    return statsAsync.when(
      data: (stats) => Row(
        children: [
          Expanded(
            child: InfoCard(
              label: 'Current Streak',
              value: '🔥 ${stats.currentStreak} days',
              icon: Icons.local_fire_department,
              iconColor: AppColors.warning,
            ),
          ),
        ],
      ),
      loading: () => Row(
        children: [
          Expanded(
            child: InfoCard(
              label: 'Current Streak',
              value: '🔥 -- days',
              icon: Icons.local_fire_department,
              iconColor: AppColors.warning,
            ),
          ),
        ],
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildAchievementsPreview(String athleteId) {
    final countsAsync = ref.watch(achievementCountsProvider(athleteId));

    return GestureDetector(
      onTap: () => context.push(RoutePaths.athleteAchievements),
      child: BaseCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFFFD700),
                    const Color(0xFFFFD700).withValues(alpha: 0.7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppSpacing.sm),
              ),
              child: const Icon(
                Icons.emoji_events,
                color: AppColors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Achievements', style: AppTextStyles.titleSmall),
                  countsAsync.when(
                    data: (counts) => Text(
                      '${counts.unlocked} of ${counts.total} unlocked',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    loading: () => Text(
                      'Loading...',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    error: (_, __) => Text(
                      'View achievements',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            countsAsync.when(
              data: (counts) => Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      value: counts.percentage / 100,
                      backgroundColor: AppColors.surface,
                      valueColor: const AlwaysStoppedAnimation(
                        Color(0xFFFFD700),
                      ),
                      strokeWidth: 4,
                    ),
                  ),
                  Text(
                    '${counts.percentage.toInt()}%',
                    style: AppTextStyles.labelSmall.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              loading: () => const SizedBox(
                width: 40,
                height: 40,
                child: LoadingIndicator(size: 24),
              ),
              error: (_, __) => const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingWorkouts(
    AsyncValue<List<ActivityEntity>> upcomingAsync,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Upcoming', style: AppTextStyles.titleMedium),
            TertiaryButton(text: 'View All', onPressed: () => _onNavTap(1)),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        upcomingAsync.when(
          data: (activities) {
            if (activities.isEmpty) {
              return BaseCard(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Center(
                  child: Text(
                    'No upcoming activities',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              );
            }
            return Column(
              children: activities.take(3).map((activity) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: _WorkoutListItem(
                    activity: activity,
                    onTap: () => _navigateToWorkout(activity),
                  ),
                );
              }).toList(),
            );
          },
          loading: () => const Center(child: LoadingIndicator()),
          error: (_, __) => const Text('Error loading upcoming workouts'),
        ),
      ],
    );
  }

  Widget _buildPlansTab() {
    final currentUser = ref.watch(currentUserProvider);
    if (currentUser == null) {
      return const Center(child: LoadingIndicator());
    }

    final assignmentsAsync = ref.watch(
      athletePlanAssignmentsProvider(currentUser.id),
    );

    return assignmentsAsync.when(
      data: (assignments) => _buildPlansList(assignments),
      loading: () => const Center(child: LoadingIndicator()),
      error: (e, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: AppSpacing.md),
            Text('Error loading plans: $e'),
          ],
        ),
      ),
    );
  }

  Widget _buildPlansList(List<PlanAssignmentEntity> assignments) {
    if (assignments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment_outlined,
              size: 64,
              color: AppColors.textSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No plans assigned yet',
              style: AppTextStyles.titleMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Your coach will assign plans to you',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: assignments.length,
      itemBuilder: (context, index) {
        final assignment = assignments[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: _AssignmentCard(assignment: assignment),
        );
      },
    );
  }

  Widget _buildProgressTab() {
    final currentUser = ref.watch(currentUserProvider);
    if (currentUser == null) {
      return const Center(child: LoadingIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Your Progress', style: AppTextStyles.headlineSmall),
          const SizedBox(height: AppSpacing.lg),
          _buildProgressStats(currentUser.id),
          const SizedBox(height: AppSpacing.lg),
          _buildRecentActivity(currentUser.id),
        ],
      ),
    );
  }

  Widget _buildProgressStats(String athleteId) {
    final statsAsync = ref.watch(athleteStatsStreamProvider(athleteId));

    return statsAsync.when(
      data: (stats) => Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _ProgressStatCard(
                  title: 'Total Workouts',
                  value: '${stats.totalWorkouts}',
                  icon: Icons.fitness_center,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _ProgressStatCard(
                  title: 'Total Time',
                  value: stats.formattedTotalDuration,
                  icon: Icons.timer,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _ProgressStatCard(
                  title: 'Current Streak',
                  value: '${stats.currentStreak} days',
                  icon: Icons.local_fire_department,
                  color: AppColors.warning,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _ProgressStatCard(
                  title: 'Best Streak',
                  value: '${stats.longestStreak} days',
                  icon: Icons.emoji_events,
                  color: AppColors.info,
                ),
              ),
            ],
          ),
        ],
      ),
      loading: () => const Center(child: LoadingIndicator()),
      error: (_, __) => const Text('Error loading stats'),
    );
  }

  Widget _buildRecentActivity(String athleteId) {
    final logsAsync = ref.watch(activityLogsStreamProvider(athleteId));

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
                        'No activity logged yet',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return Column(
              children: logs.take(5).map((log) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: _ActivityLogCard(log: log),
                );
              }).toList(),
            );
          },
          loading: () => const Center(child: LoadingIndicator()),
          error: (_, __) => const Text('Error loading activity'),
        ),
      ],
    );
  }

  Widget _buildProfileTab() {
    final currentUser = ref.watch(currentUserProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.xl),
          CircleAvatar(
            radius: 50,
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            child: Text(
              currentUser?.displayName.isNotEmpty == true
                  ? currentUser!.displayName[0].toUpperCase()
                  : 'A',
              style: AppTextStyles.displayMedium.copyWith(
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            currentUser?.displayName ?? 'Athlete',
            style: AppTextStyles.headlineSmall.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            currentUser?.email ?? '',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          // Coach Status Card
          if (currentUser != null) ...[
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          currentUser.coachId != null
                              ? Icons.check_circle
                              : Icons.link_outlined,
                          size: 20,
                          color: currentUser.coachId != null
                              ? AppColors.success
                              : AppColors.warning,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          currentUser.coachId != null
                              ? 'Linked to Coach'
                              : 'No Coach Linked',
                          style: AppTextStyles.labelMedium.copyWith(
                            color: currentUser.coachId != null
                                ? AppColors.success
                                : AppColors.warning,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    if (currentUser.coachId != null)
                      Text(
                        'Coach ID: ${currentUser.coachId}',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          fontFamily: 'monospace',
                        ),
                      )
                    else
                      Text(
                        'Link your account to a coach to receive training plans',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    const SizedBox(height: AppSpacing.md),
                    SecondaryButton(
                      text: currentUser.coachId != null
                          ? 'Change Coach'
                          : 'Link to Coach',
                      onPressed: () => _showLinkCoachDialog(currentUser),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
          _buildProfileOption(
            icon: Icons.person_outline,
            title: 'Edit Profile',
            onTap: () => context.push(RoutePaths.athleteProfile),
          ),
          _buildProfileOption(
            icon: Icons.settings_outlined,
            title: 'Settings',
            onTap: () => context.push(RoutePaths.settings),
          ),
          _buildProfileOption(
            icon: Icons.help_outline,
            title: 'Help & Support',
            onTap: () => context.push(RoutePaths.helpSupport),
          ),
          _buildProfileOption(
            icon: Icons.info_outline,
            title: 'About',
            onTap: () => context.push(RoutePaths.about),
          ),
          const SizedBox(height: AppSpacing.lg),
          SecondaryButton(
            text: 'Sign Out',
            icon: Icons.logout,
            onPressed: () => ref.read(authProvider.notifier).signOut(),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textSecondary),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  void _navigateToWorkout(ActivityEntity activity) {
    context.push(
      RoutePaths.athleteLogActivity.replaceFirst(':activityId', activity.id),
    );
  }

  void _showLinkCoachDialog(currentUser) {
    final coachCodeController = TextEditingController(
      text: currentUser.coachId ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          currentUser.coachId != null ? 'Change Coach' : 'Link to Coach',
          style: AppTextStyles.titleMedium,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter your coach\'s ID to link your account',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: coachCodeController,
              decoration: const InputDecoration(
                labelText: 'Coach ID',
                hintText: 'Paste coach ID here',
                prefixIcon: Icon(Icons.badge_outlined),
                border: OutlineInputBorder(),
              ),
              style: const TextStyle(fontFamily: 'monospace'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              coachCodeController.dispose();
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final coachId = coachCodeController.text.trim();
              if (coachId.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a coach ID'),
                    backgroundColor: AppColors.warning,
                  ),
                );
                return;
              }

              // Update coachId in Firestore
              try {
                await ref.read(authProvider.notifier).updateCoachId(coachId);
                coachCodeController.dispose();
                if (mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Successfully linked to coach!'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: ${e.toString()}'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            child: const Text('Link'),
          ),
        ],
      ),
    );
  }
}

// ============== Helper Widgets ==============

class _TodaysWorkoutCard extends StatelessWidget {
  const _TodaysWorkoutCard({required this.activities, required this.onStart});

  final List<ActivityEntity> activities;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final activity = activities.first;
    final totalDuration = activities.fold<int>(
      0,
      (sum, a) => sum + (a.targetDuration ?? 0),
    );

    return BaseCard(
      backgroundColor: AppColors.primary,
      borderColor: AppColors.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.fitness_center, color: AppColors.white),
              const SizedBox(width: AppSpacing.xs),
              Text(
                "TODAY'S WORKOUT",
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.white.withValues(alpha: 0.8),
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            activity.name,
            style: AppTextStyles.headlineMedium.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '$totalDuration min • ${activities.length} ${activities.length == 1 ? 'exercise' : 'exercises'}',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.white.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onStart,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.white,
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
              ),
              child: const Text('Start Workout'),
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkoutListItem extends StatelessWidget {
  const _WorkoutListItem({required this.activity, required this.onTap});

  final ActivityEntity activity;
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
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Icon(
                activity.typeIcon,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(activity.name, style: AppTextStyles.titleSmall),
                  Text(
                    '${activity.dayName} • ${activity.formattedDuration}',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

class _AssignmentCard extends ConsumerWidget {
  const _AssignmentCard({required this.assignment});

  final PlanAssignmentEntity assignment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusColor = assignment.isActive
        ? AppColors.success
        : AppColors.textSecondary;

    return GestureDetector(
      onTap: () => _showPlanDetails(context, ref),
      child: BaseCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.xs),
                  ),
                  child: Icon(Icons.assignment, color: statusColor),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        assignment.planName ?? 'Training Plan',
                        style: AppTextStyles.titleSmall,
                      ),
                      Text(
                        assignment.isActive ? 'In Progress' : 'Completed',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: assignment.completionPercentage / 100,
                      backgroundColor: AppColors.surface,
                      valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                      minHeight: 8,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '${assignment.completionPercentage.toInt()}%',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showPlanDetails(BuildContext context, WidgetRef ref) {
    final activitiesAsync = ref.read(
      assignmentActivitiesProvider(assignment.id),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textSecondary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            assignment.planName ?? 'Training Plan',
                            style: AppTextStyles.titleLarge,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            assignment.isActive
                                ? 'Active • ${assignment.completionPercentage.toInt()}% Complete'
                                : 'Completed ✓',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: assignment.isActive
                                  ? AppColors.success
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Activities list
              Expanded(
                child: activitiesAsync.when(
                  data: (activities) {
                    if (activities.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.fitness_center,
                              size: 48,
                              color: AppColors.textSecondary.withValues(
                                alpha: 0.5,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              'No activities in this plan',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.all(AppSpacing.md),
                      itemCount: activities.length,
                      itemBuilder: (context, index) {
                        final activity = activities[index];
                        return _PlanActivityItem(
                          activity: activity,
                          dayLabel: _getDayLabel(activity.dayOfWeek),
                        );
                      },
                    );
                  },
                  loading: () => const Center(child: LoadingIndicator()),
                  error: (_, __) => Center(
                    child: Text(
                      'Error loading activities',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getDayLabel(int dayOfWeek) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    if (dayOfWeek >= 1 && dayOfWeek <= 7) {
      return days[dayOfWeek - 1];
    }
    return 'Day $dayOfWeek';
  }
}

/// Activity item for plan details.
class _PlanActivityItem extends StatelessWidget {
  const _PlanActivityItem({required this.activity, required this.dayLabel});

  final ActivityEntity activity;
  final String dayLabel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: BaseCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.sm),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    dayLabel,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(activity.name, style: AppTextStyles.titleSmall),
                  const SizedBox(height: AppSpacing.xxs),
                  Row(
                    children: [
                      Icon(
                        Icons.timer_outlined,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${activity.targetDuration} min',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Icon(
                        Icons.category_outlined,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        activity.type,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressStatCard extends StatelessWidget {
  const _ProgressStatCard({
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
          Icon(icon, color: color, size: 24),
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

class _ActivityLogCard extends StatelessWidget {
  const _ActivityLogCard({required this.log});

  final ActivityLogEntity log;

  @override
  Widget build(BuildContext context) {
    return BaseCard(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: const Icon(Icons.check, color: AppColors.success, size: 20),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(log.activityName, style: AppTextStyles.titleSmall),
                Text(
                  '${log.formattedDuration} • ${log.effortDescription}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            _formatDate(log.completedAt),
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'Today';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${date.day}/${date.month}';
    }
  }
}
