import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../athlete/presentation/providers/athlete_provider.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/providers/auth_state.dart';
import '../../../messaging/presentation/providers/message_provider.dart';
import '../../../plans/domain/entities/entities.dart';
import '../../../plans/presentation/providers/plan_provider.dart';
import '../providers/coach_provider.dart';

/// Screen displaying detailed information about an athlete.
///
/// Shows athlete profile, assigned plans, and activity history.
class AthleteDetailScreen extends ConsumerWidget {
  /// Creates an athlete detail screen.
  const AthleteDetailScreen({super.key, required this.athleteId});

  /// The ID of the athlete to display.
  final String athleteId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final athleteAsync = ref.watch(athleteByIdProvider(athleteId));

    return athleteAsync.when(
      data: (athlete) {
        if (athlete == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Athlete not found')),
          );
        }
        return _AthleteDetailContent(athlete: athlete);
      },
      loading: () => Scaffold(
        appBar: AppBar(),
        body: const Center(child: LoadingIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: AppSpacing.md),
              Text('Error: $e'),
            ],
          ),
        ),
      ),
    );
  }
}

class _AthleteDetailContent extends ConsumerWidget {
  const _AthleteDetailContent({required this.athlete});

  final UserEntity athlete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assignmentsAsync = ref.watch(
      athleteAssignmentsStreamProvider(athlete.id),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(athlete.displayName),
        actions: [
          IconButton(
            icon: const Icon(Icons.message_outlined),
            onPressed: () => _startConversation(context, ref),
            tooltip: 'Message',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'assign':
                  _showAssignPlanDialog(context, ref);
                  break;
                case 'remove':
                  _confirmRemoveAthlete(context, ref);
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'assign',
                child: Row(
                  children: [
                    Icon(Icons.assignment_add, size: 20),
                    SizedBox(width: AppSpacing.sm),
                    Text('Assign Plan'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'remove',
                child: Row(
                  children: [
                    Icon(Icons.person_remove, size: 20, color: AppColors.error),
                    SizedBox(width: AppSpacing.sm),
                    Text('Remove', style: TextStyle(color: AppColors.error)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileCard(),
            const SizedBox(height: AppSpacing.lg),
            _buildStatsRow(),
            const SizedBox(height: AppSpacing.lg),
            _buildAssignedPlansSection(context, ref, assignmentsAsync),
            const SizedBox(height: AppSpacing.lg),
            _buildActivitySection(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAssignPlanDialog(context, ref),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.assignment_add, color: AppColors.white),
        label: Text(
          'Assign Plan',
          style: AppTextStyles.buttonMedium.copyWith(color: AppColors.white),
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    final initials = athlete.displayName.isNotEmpty
        ? athlete.displayName
              .split(' ')
              .take(2)
              .map((e) => e.isNotEmpty ? e[0].toUpperCase() : '')
              .join()
        : 'A';

    final lastActive = athlete.lastActive;
    String lastActiveText;
    if (lastActive == null) {
      lastActiveText = 'Never active';
    } else {
      final difference = DateTime.now().difference(lastActive);
      if (difference.inMinutes < 5) {
        lastActiveText = 'Active now';
      } else if (difference.inHours < 1) {
        lastActiveText = 'Active ${difference.inMinutes}m ago';
      } else if (difference.inHours < 24) {
        lastActiveText = 'Active ${difference.inHours}h ago';
      } else {
        lastActiveText = 'Active ${difference.inDays} days ago';
      }
    }

    return BaseCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            child: athlete.profilePicture != null
                ? ClipOval(
                    child: Image.network(
                      athlete.profilePicture!,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                    ),
                  )
                : Text(
                    initials,
                    style: AppTextStyles.headlineSmall.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  athlete.displayName,
                  style: AppTextStyles.headlineSmall.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  athlete.email,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xxs,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.xs),
                  ),
                  child: Text(
                    lastActiveText,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.success,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Consumer(
      builder: (context, ref, child) {
        final statsAsync = ref.watch(athleteStatsProvider(athlete.id));
        final assignmentsAsync = ref.watch(
          athleteAssignmentsStreamProvider(athlete.id),
        );

        return statsAsync.when(
          data: (stats) {
            final assignmentsCount = assignmentsAsync.maybeWhen(
              data: (assignments) => assignments.length,
              orElse: () => 0,
            );

            return Row(
              children: [
                Expanded(
                  child: StatCard(
                    title: 'Workouts',
                    value: stats.totalWorkouts.toString(),
                    icon: Icons.fitness_center,
                    iconColor: AppColors.primary,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: StatCard(
                    title: 'Streak',
                    value: '${stats.currentStreak} 🔥',
                    icon: Icons.local_fire_department,
                    iconColor: AppColors.warning,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: StatCard(
                    title: 'Plans',
                    value: assignmentsCount.toString(),
                    icon: Icons.assignment,
                    iconColor: AppColors.info,
                  ),
                ),
              ],
            );
          },
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
                  title: 'Streak',
                  value: '--',
                  icon: Icons.local_fire_department,
                  iconColor: AppColors.warning,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: StatCard(
                  title: 'Plans',
                  value: '--',
                  icon: Icons.assignment,
                  iconColor: AppColors.info,
                ),
              ),
            ],
          ),
          error: (_, __) => Row(
            children: [
              Expanded(
                child: StatCard(
                  title: 'Workouts',
                  value: '0',
                  icon: Icons.fitness_center,
                  iconColor: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: StatCard(
                  title: 'Streak',
                  value: '0',
                  icon: Icons.local_fire_department,
                  iconColor: AppColors.warning,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: StatCard(
                  title: 'Plans',
                  value: '0',
                  icon: Icons.assignment,
                  iconColor: AppColors.info,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAssignedPlansSection(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<PlanAssignmentEntity>> assignmentsAsync,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Assigned Plans', style: AppTextStyles.titleMedium),
            TertiaryButton(
              text: 'View All',
              onPressed: () {
                // TODO: Navigate to all assignments
              },
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        assignmentsAsync.when(
          data: (assignments) {
            if (assignments.isEmpty) {
              return BaseCard(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  children: [
                    Icon(
                      Icons.assignment_outlined,
                      size: 48,
                      color: AppColors.textSecondary.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'No plans assigned yet',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    SecondaryButton(
                      text: 'Assign Plan',
                      onPressed: () => _showAssignPlanDialog(context, ref),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: assignments.take(3).map((assignment) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Consumer(
                    builder: (context, ref, child) {
                      // Check if the plan still exists
                      final planAsync = ref.watch(
                        planStreamProvider(assignment.planId),
                      );
                      final planExists = planAsync.value != null;
                      final plan = planAsync.value;

                      // Use plan name from the actual plan if assignment doesn't have it
                      final displayName = assignment.planName ?? plan?.name;

                      return _AssignmentCard(
                        assignment: assignment,
                        planExists: planExists,
                        planName: displayName,
                        onTap: () {
                          if (!planExists) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'This plan is no longer available',
                                ),
                                backgroundColor: AppColors.error,
                                duration: Duration(seconds: 2),
                              ),
                            );
                            return;
                          }
                          context.push(
                            RoutePaths.coachPlanDetail.replaceFirst(
                              ':planId',
                              assignment.planId,
                            ),
                          );
                        },
                        onUnassign: () =>
                            _confirmUnassignPlan(context, ref, assignment),
                        onComplete: () =>
                            _confirmCompletePlan(context, ref, assignment),
                      );
                    },
                  ),
                );
              }).toList(),
            );
          },
          loading: () => const Center(child: LoadingIndicator()),
          error: (e, _) => Center(child: Text('Error loading plans: $e')),
        ),
      ],
    );
  }

  Widget _buildActivitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Recent Activity', style: AppTextStyles.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        BaseCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              Icon(
                Icons.history,
                size: 48,
                color: AppColors.textSecondary.withValues(alpha: 0.5),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Activity history coming soon',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _startConversation(BuildContext context, WidgetRef ref) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    // Get or create conversation
    final conversation = await ref
        .read(messageProvider.notifier)
        .getOrCreateConversation(
          userId1: currentUser.id,
          userId2: athlete.id,
          userName1: currentUser.displayName,
          userName2: athlete.displayName,
        );

    if (conversation != null && context.mounted) {
      context.push(
        RoutePaths.chat.replaceAll(':conversationId', conversation.id),
      );
    }
  }

  void _showAssignPlanDialog(BuildContext context, WidgetRef ref) async {
    final authState = ref.read(authProvider);
    if (authState is! AuthAuthenticated) return;

    final plansAsync = ref.watch(plansStreamProvider(authState.user.id));

    await plansAsync.when(
      data: (plans) async {
        if (plans.isEmpty) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('You need to create a training plan first'),
                backgroundColor: AppColors.warning,
              ),
            );
          }
          return;
        }

        if (!context.mounted) return;

        final selectedPlan = await showDialog<TrainingPlanEntity>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Assign Plan to ${athlete.displayName}'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: plans.length,
                itemBuilder: (context, index) {
                  final plan = plans[index];
                  return ListTile(
                    leading: const Icon(
                      Icons.assignment,
                      color: AppColors.primary,
                    ),
                    title: Text(plan.name),
                    subtitle: Text(
                      '${plan.durationDays} days • ${plan.activities.length} activities',
                    ),
                    onTap: () => Navigator.pop(context, plan),
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ],
          ),
        );

        if (selectedPlan != null && context.mounted) {
          try {
            final now = DateTime.now();

            await ref
                .read(assignmentProvider.notifier)
                .assignPlan(
                  planId: selectedPlan.id,
                  athleteId: athlete.id,
                  coachId: authState.user.id,
                  startDate: now,
                  endDate: now.add(Duration(days: selectedPlan.durationDays)),
                  planName: selectedPlan.name,
                  athleteName: athlete.displayName,
                  coachName: authState.user.displayName,
                );

            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '${selectedPlan.name} assigned to ${athlete.displayName}',
                  ),
                  backgroundColor: AppColors.success,
                ),
              );
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error: $e'),
                  backgroundColor: AppColors.error,
                ),
              );
            }
          }
        }
      },
      loading: () {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Loading plans...')));
        }
      },
      error: (e, _) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error loading plans: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
    );
  }

  void _confirmUnassignPlan(
    BuildContext context,
    WidgetRef ref,
    PlanAssignmentEntity assignment,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unassign Plan'),
        content: Text(
          'Are you sure you want to unassign this plan from ${athlete.displayName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            onPressed: () async {
              Navigator.pop(context);
              final success = await ref
                  .read(assignmentProvider.notifier)
                  .cancelAssignment(assignment.id);

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Plan unassigned successfully'
                          : 'Failed to unassign plan',
                    ),
                    backgroundColor: success
                        ? AppColors.success
                        : AppColors.error,
                  ),
                );
              }
            },
            child: const Text('Unassign'),
          ),
        ],
      ),
    );
  }

  void _confirmCompletePlan(
    BuildContext context,
    WidgetRef ref,
    PlanAssignmentEntity assignment,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark Plan as Complete'),
        content: Text(
          'Mark this plan as completed for ${athlete.displayName}?\n\nThis will keep the plan in their history but mark it as finished.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.success),
            onPressed: () async {
              Navigator.pop(context);
              final success = await ref
                  .read(assignmentProvider.notifier)
                  .completeAssignment(assignment.id);

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Plan marked as complete! 🎉'
                          : 'Failed to complete plan',
                    ),
                    backgroundColor: success
                        ? AppColors.success
                        : AppColors.error,
                  ),
                );
              }
            },
            child: const Text('Mark Complete'),
          ),
        ],
      ),
    );
  }

  void _confirmRemoveAthlete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Athlete'),
        content: Text(
          'Are you sure you want to remove ${athlete.displayName} from your team?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref
                  .read(athleteNotifierProvider.notifier)
                  .removeAthleteFromCoach(athlete.id);
              if (context.mounted) {
                context.pop();
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}

class _AssignmentCard extends StatelessWidget {
  const _AssignmentCard({
    required this.assignment,
    required this.onTap,
    required this.onUnassign,
    required this.onComplete,
    required this.planExists,
    this.planName,
  });

  final PlanAssignmentEntity assignment;
  final VoidCallback onTap;
  final VoidCallback onUnassign;
  final VoidCallback onComplete;
  final bool planExists;
  final String? planName;

  @override
  Widget build(BuildContext context) {
    final progress = assignment.completionPercentage;
    final statusColor = assignment.isActive
        ? AppColors.success
        : AppColors.textSecondary;

    return GestureDetector(
      onTap: onTap,
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
                        planName ??
                            'Plan #${assignment.planId.substring(0, 6)}',
                        style: AppTextStyles.titleSmall.copyWith(
                          decoration: !planExists
                              ? TextDecoration.lineThrough
                              : null,
                          color: !planExists ? AppColors.textSecondary : null,
                        ),
                      ),
                      Text(
                        !planExists
                            ? 'Plan no longer available'
                            : (assignment.isActive
                                  ? 'In Progress'
                                  : 'Completed'),
                        style: AppTextStyles.bodySmall.copyWith(
                          color: !planExists
                              ? AppColors.textSecondary
                              : statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
                // Only show actions if plan is active
                if (assignment.isActive) ...[
                  IconButton(
                    icon: const Icon(Icons.check_circle_outline, size: 20),
                    color: AppColors.success,
                    tooltip: 'Mark as complete',
                    onPressed: onComplete,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    color: AppColors.error,
                    tooltip: 'Unassign plan',
                    onPressed: onUnassign,
                  ),
                ],
                const Icon(Icons.chevron_right, color: AppColors.textSecondary),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress / 100,
                      backgroundColor: AppColors.surface,
                      valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                      minHeight: 8,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '${progress.toInt()}%',
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
}
