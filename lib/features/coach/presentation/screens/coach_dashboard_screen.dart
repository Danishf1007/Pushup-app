import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../notifications/presentation/widgets/notification_badge.dart';
import '../../../plans/domain/entities/entities.dart';
import '../../../plans/presentation/providers/plan_provider.dart';
import '../providers/coach_provider.dart';

/// Coach Dashboard - Home screen for coaches.
///
/// Displays athlete overview, training plans, and quick actions.
class CoachDashboardScreen extends ConsumerStatefulWidget {
  /// Creates a coach dashboard screen.
  const CoachDashboardScreen({super.key});

  @override
  ConsumerState<CoachDashboardScreen> createState() =>
      _CoachDashboardScreenState();
}

class _CoachDashboardScreenState extends ConsumerState<CoachDashboardScreen> {
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
              'Welcome${currentUser != null ? ", ${currentUser.displayName.split(' ').first}" : ""}! 💪',
              style: AppTextStyles.titleLarge,
            ),
            Text(
              'Manage your athletes',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
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
              backgroundColor: AppColors.secondary,
              child: Icon(Icons.person, size: 18, color: AppColors.white),
            ),
            onPressed: () => context.push(RoutePaths.coachProfile),
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: _currentIndex == 2
          ? FloatingActionButton.extended(
              onPressed: () => context.push(RoutePaths.coachCreatePlan),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 6,
              extendedPadding: const EdgeInsets.symmetric(horizontal: 20),
              icon: const Icon(Icons.add, size: 24),
              label: const Text(
                'New Plan',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
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
            icon: Icon(Icons.people_outline),
            activeIcon: Icon(Icons.people),
            label: 'Athletes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_outlined),
            activeIcon: Icon(Icons.assignment),
            label: 'Plans',
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

  Widget _buildBody() {
    switch (_currentIndex) {
      case 1:
        return _buildAthletesTab();
      case 2:
        return _buildPlansTab();
      case 3:
        return _buildProfileTab();
      default:
        return _buildHomeTab();
    }
  }

  void _onNavTap(int index) {
    setState(() => _currentIndex = index);
  }

  Widget _buildHomeTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildQuickStats(),
          const SizedBox(height: AppSpacing.lg),
          _buildActiveAthletes(),
          const SizedBox(height: AppSpacing.lg),
          _buildTrainingPlans(),
          const SizedBox(height: AppSpacing.lg),
          _buildRecentActivity(),
        ],
      ),
    );
  }

  Widget _buildAthletesTab() {
    final currentUser = ref.watch(currentUserProvider);
    if (currentUser == null) {
      return const Center(child: LoadingIndicator());
    }

    final athletesAsync = ref.watch(athletesStreamProvider(currentUser.id));

    return athletesAsync.when(
      data: (athletes) => _buildAthletesList(athletes),
      loading: () => const Center(child: LoadingIndicator()),
      error: (e, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: AppSpacing.md),
            Text('Error loading athletes: $e'),
            const SizedBox(height: AppSpacing.md),
            SecondaryButton(
              text: 'Retry',
              onPressed: () => ref.invalidate(athletesStreamProvider),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAthletesList(List<UserEntity> athletes) {
    if (athletes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: AppColors.textSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No athletes yet',
              style: AppTextStyles.titleMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Athletes who join your team will appear here',
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
      itemCount: athletes.length,
      itemBuilder: (context, index) {
        final athlete = athletes[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: _SimpleAthleteCard(
            athlete: athlete,
            onTap: () => context.push(
              RoutePaths.coachAthleteDetail.replaceFirst(
                ':athleteId',
                athlete.id,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlansTab() {
    final currentUser = ref.watch(currentUserProvider);
    if (currentUser == null) {
      return const Center(child: LoadingIndicator());
    }

    final plansAsync = ref.watch(plansStreamProvider(currentUser.id));

    return plansAsync.when(
      data: (plans) => _buildPlansList(plans),
      loading: () => const Center(child: LoadingIndicator()),
      error: (e, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: AppSpacing.md),
            Text('Error loading plans: $e'),
            const SizedBox(height: AppSpacing.md),
            SecondaryButton(
              text: 'Retry',
              onPressed: () => ref.invalidate(plansStreamProvider),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlansList(List<TrainingPlanEntity> plans) {
    if (plans.isEmpty) {
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
              'No training plans yet',
              style: AppTextStyles.titleMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Create your first plan to get started',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            PrimaryButton(
              text: 'Create Plan',
              onPressed: () => context.push(RoutePaths.coachCreatePlan),
              width: 180,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: plans.length,
      itemBuilder: (context, index) {
        final plan = plans[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: _SimplePlanCard(
            plan: plan,
            onTap: () => context.push(
              RoutePaths.coachPlanDetail.replaceFirst(':planId', plan.id),
            ),
          ),
        );
      },
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
                  : 'C',
              style: AppTextStyles.displayMedium.copyWith(
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            currentUser?.displayName ?? 'Coach',
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
          // Coach ID Card
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
                        const Icon(
                          Icons.badge_outlined,
                          size: 20,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          'Your Coach ID',
                          style: AppTextStyles.labelMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.sm,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Text(
                              currentUser.id,
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        IconButton(
                          onPressed: () {
                            Clipboard.setData(
                              ClipboardData(text: currentUser.id),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Coach ID copied to clipboard!'),
                                duration: Duration(seconds: 2),
                                backgroundColor: AppColors.success,
                              ),
                            );
                          },
                          icon: const Icon(Icons.copy, size: 20),
                          style: IconButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Share this ID with athletes so they can link their account to you',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
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

  Widget _buildQuickStats() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: StatCard(
                title: 'Active Athletes',
                value: '12',
                icon: Icons.people,
                iconColor: AppColors.primary,
                trend: '+2',
                trendPositive: true,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: StatCard(
                title: 'Active Plans',
                value: '8',
                icon: Icons.assignment,
                iconColor: AppColors.success,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        GestureDetector(
          onTap: () => context.push(RoutePaths.coachAnalytics),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.1),
                  AppColors.secondary.withValues(alpha: 0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppSpacing.sm),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppSpacing.xs),
                  ),
                  child: const Icon(
                    Icons.analytics_outlined,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Analytics Dashboard',
                        style: AppTextStyles.titleSmall,
                      ),
                      Text(
                        'View detailed team performance',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: AppColors.primary,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActiveAthletes() {
    final currentUser = ref.watch(currentUserProvider);
    if (currentUser == null) {
      return const SizedBox.shrink();
    }

    final athletesAsync = ref.watch(athletesStreamProvider(currentUser.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Athletes', style: AppTextStyles.titleMedium),
            TertiaryButton(
              text: 'View All',
              onPressed: () => _onNavTap(1), // Switch to Athletes tab
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        athletesAsync.when(
          data: (athletes) {
            if (athletes.isEmpty) {
              return Container(
                height: 100,
                alignment: Alignment.center,
                child: Text(
                  'No athletes assigned yet',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              );
            }
            return SizedBox(
              height: 100,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: athletes.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(width: AppSpacing.sm),
                itemBuilder: (context, index) {
                  final athlete = athletes[index];
                  return _AthleteAvatar(
                    name: athlete.displayName.isNotEmpty
                        ? athlete.displayName
                        : 'Athlete',
                    status: 'Active',
                    statusColor: AppColors.success,
                  );
                },
              ),
            );
          },
          loading: () => const SizedBox(
            height: 100,
            child: Center(child: LoadingIndicator()),
          ),
          error: (_, __) => Container(
            height: 100,
            alignment: Alignment.center,
            child: Text(
              'Error loading athletes',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTrainingPlans() {
    final currentUser = ref.watch(currentUserProvider);
    if (currentUser == null) {
      return const SizedBox.shrink();
    }

    final plansAsync = ref.watch(plansStreamProvider(currentUser.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Training Plans', style: AppTextStyles.titleMedium),
            TertiaryButton(
              text: 'View All',
              onPressed: () => _onNavTap(2), // Switch to Plans tab
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        plansAsync.when(
          data: (plans) {
            if (plans.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppSpacing.sm),
                  border: Border.all(color: AppColors.border),
                ),
                child: Center(
                  child: Text(
                    'No training plans yet',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              );
            }
            // Show first 2 plans
            final displayPlans = plans.take(2).toList();
            return Column(
              children: displayPlans.map((plan) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: _PlanCard(
                    title: plan.name,
                    athletes: 0, // Could query assignments count
                    duration: plan.formattedDuration,
                    color: AppColors.primary,
                  ),
                );
              }).toList(),
            );
          },
          loading: () => const Center(child: LoadingIndicator()),
          error: (_, __) => Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Text(
              'Error loading plans',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentActivity() {
    final currentUser = ref.watch(currentUserProvider);
    if (currentUser == null) return const SizedBox.shrink();

    final activitiesAsync = ref.watch(recentActivityProvider(currentUser.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Recent Activity', style: AppTextStyles.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        activitiesAsync.when(
          data: (activities) {
            if (activities.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppSpacing.sm),
                  border: Border.all(color: AppColors.border),
                ),
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
                        'No recent activity',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Activity from your athletes will appear here',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: activities.length > 5 ? 5 : activities.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                final activity = activities[index];
                return Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppSpacing.sm),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _getActivityColor(
                            activity.activityType,
                          ).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          _getActivityIcon(activity.activityType),
                          color: _getActivityColor(activity.activityType),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              activity.athleteName,
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${activity.activityName} • ${activity.duration} min${activity.reps != null ? " • ${activity.reps} reps" : ""}',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        activity.timeAgo,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: LoadingIndicator()),
          error: (_, __) => Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSpacing.sm),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              'Error loading activity',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }

  IconData _getActivityIcon(String type) {
    switch (type) {
      case 'strength':
        return Icons.fitness_center;
      case 'cardio':
        return Icons.directions_run;
      case 'flexibility':
        return Icons.self_improvement;
      case 'recovery':
        return Icons.spa;
      default:
        return Icons.fitness_center;
    }
  }

  Color _getActivityColor(String type) {
    switch (type) {
      case 'strength':
        return AppColors.primary;
      case 'cardio':
        return AppColors.success;
      case 'flexibility':
        return AppColors.warning;
      case 'recovery':
        return AppColors.info;
      default:
        return AppColors.primary;
    }
  }
}

class _AthleteAvatar extends StatelessWidget {
  const _AthleteAvatar({
    required this.name,
    required this.status,
    required this.statusColor,
  });

  final String name;
  final String status;
  final Color statusColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: AppColors.primary.withValues(alpha: 0.2),
              child: Text(
                name.split(' ').map((e) => e[0]).take(2).join(),
                style: AppTextStyles.titleMedium.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.white, width: 2),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(name, style: AppTextStyles.labelSmall),
      ],
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.title,
    required this.athletes,
    required this.duration,
    required this.color,
  });

  final String title;
  final int athletes;
  final String duration;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return BaseCard(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 48,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.titleSmall),
                Text(
                  '$athletes athletes • $duration',
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
    );
  }
}

/// Simple plan card for displaying in the plans list tab.
class _SimplePlanCard extends StatelessWidget {
  const _SimplePlanCard({required this.plan, required this.onTap});

  final TrainingPlanEntity plan;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: BaseCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.xs),
              ),
              child: const Icon(Icons.assignment, color: AppColors.primary),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          plan.name,
                          style: AppTextStyles.titleSmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (plan.isTemplate)
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
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    '${plan.activityCount} activities • ${plan.durationDays} days',
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

/// Simple athlete card for displaying in the athletes list tab.
class _SimpleAthleteCard extends StatelessWidget {
  const _SimpleAthleteCard({required this.athlete, required this.onTap});

  final UserEntity athlete;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final initials = athlete.displayName.isNotEmpty
        ? athlete.displayName
              .split(' ')
              .take(2)
              .map((e) => e.isNotEmpty ? e[0].toUpperCase() : '')
              .join()
        : 'A';

    final lastActive = athlete.lastActive;
    String lastActiveText;
    Color statusColor;

    if (lastActive == null) {
      lastActiveText = 'Never active';
      statusColor = AppColors.textSecondary;
    } else {
      final difference = DateTime.now().difference(lastActive);
      if (difference.inHours < 24) {
        lastActiveText = 'Active today';
        statusColor = AppColors.success;
      } else if (difference.inDays < 7) {
        lastActiveText = 'Active ${difference.inDays}d ago';
        statusColor = AppColors.warning;
      } else {
        lastActiveText = 'Inactive';
        statusColor = AppColors.textSecondary;
      }
    }

    return GestureDetector(
      onTap: onTap,
      child: BaseCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              child: Text(
                initials,
                style: AppTextStyles.titleSmall.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    athlete.displayName,
                    style: AppTextStyles.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        lastActiveText,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: statusColor,
                        ),
                      ),
                    ],
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

// ignore: unused_element - reserved for future activity feed feature
class _ActivityItem extends StatelessWidget {
  const _ActivityItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.time,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String time;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.bodyMedium),
                Text(
                  time,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
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
