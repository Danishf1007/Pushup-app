import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/entities/entities.dart';
import '../providers/plan_provider.dart';
import '../widgets/widgets.dart';

/// Screen displaying detailed information about a training plan.
class PlanDetailScreen extends ConsumerWidget {
  /// Creates a new [PlanDetailScreen].
  const PlanDetailScreen({super.key, required this.planId});

  /// The ID of the plan to display.
  final String planId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Use stream provider for real-time updates
    final planAsync = ref.watch(planStreamProvider(planId));

    return planAsync.when(
      data: (plan) {
        if (plan == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Plan Details')),
            body: const Center(child: Text('Plan not found')),
          );
        }
        return _PlanDetailContent(plan: plan);
      },
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Plan Details')),
        body: const Center(child: LoadingIndicator()),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(title: const Text('Plan Details')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: AppSpacing.md),
              Text('Error: $error'),
              const SizedBox(height: AppSpacing.md),
              SecondaryButton(
                text: 'Retry',
                onPressed: () => ref.invalidate(planStreamProvider(planId)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlanDetailContent extends ConsumerWidget {
  const _PlanDetailContent({required this.plan});

  final TrainingPlanEntity plan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text(plan.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Edit Plan',
            onPressed: () => context.push(
              RoutePaths.coachEditPlan.replaceFirst(':planId', plan.id),
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) => _handleMenuAction(context, ref, value),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'assign',
                child: ListTile(
                  leading: Icon(Icons.person_add),
                  title: Text('Assign to Athlete'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'duplicate',
                child: ListTile(
                  leading: Icon(Icons.copy),
                  title: Text('Duplicate Plan'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              if (!plan.isTemplate)
                const PopupMenuItem(
                  value: 'template',
                  child: ListTile(
                    leading: Icon(Icons.bookmark_add),
                    title: Text('Save as Template'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  leading: Icon(Icons.delete, color: AppColors.error),
                  title: Text(
                    'Delete Plan',
                    style: TextStyle(color: AppColors.error),
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOverviewCard(),
            const SizedBox(height: AppSpacing.lg),
            _buildStatsRow(),
            const SizedBox(height: AppSpacing.lg),
            _buildActivitiesSection(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(
          RoutePaths.coachAssignPlan.replaceFirst(':planId', plan.id),
        ),
        icon: const Icon(Icons.person_add),
        label: const Text('Assign Plan'),
      ),
    );
  }

  Widget _buildOverviewCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
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
                    size: 32,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plan.name,
                        style: AppTextStyles.headlineSmall.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
                            style: AppTextStyles.bodyMedium.copyWith(
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
            if (plan.description != null && plan.description!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              const Divider(),
              const SizedBox(height: AppSpacing.sm),
              Text(
                plan.description!,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.list_alt,
            label: 'Activities',
            value: '${plan.activityCount}',
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _StatCard(
            icon: Icons.timer,
            label: 'Total Time',
            value: _formatDuration(plan.totalDuration),
            color: AppColors.info,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _StatCard(
            icon: Icons.calendar_today,
            label: 'Duration',
            value: '${plan.durationDays}d',
            color: AppColors.success,
          ),
        ),
      ],
    );
  }

  Widget _buildActivitiesSection() {
    if (plan.activities.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.sports_gymnastics,
                  size: 48,
                  color: AppColors.textSecondary.withValues(alpha: 0.5),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'No activities yet',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Activities by Day',
          style: AppTextStyles.titleMedium.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        ActivitiesByDayList(activitiesByDay: plan.activitiesByDay),
      ],
    );
  }

  String _formatDuration(int minutes) {
    if (minutes == 0) return '0m';
    if (minutes < 60) return '${minutes}m';
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (mins == 0) return '${hours}h';
    return '${hours}h ${mins}m';
  }

  void _handleMenuAction(BuildContext context, WidgetRef ref, String action) {
    switch (action) {
      case 'assign':
        context.push(
          RoutePaths.coachAssignPlan.replaceFirst(':planId', plan.id),
        );
        break;
      case 'duplicate':
        _duplicatePlan(context, ref);
        break;
      case 'template':
        _saveAsTemplate(context, ref);
        break;
      case 'delete':
        _confirmDelete(context, ref);
        break;
    }
  }

  void _duplicatePlan(BuildContext context, WidgetRef ref) {
    // Navigate to create screen with pre-filled data would be handled
    // For now, just show a message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Duplicate feature coming soon')),
    );
  }

  void _saveAsTemplate(BuildContext context, WidgetRef ref) async {
    final updatedPlan = plan.copyWith(isTemplate: true);
    final success = await ref
        .read(planProvider.notifier)
        .updatePlan(updatedPlan);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'Saved as template' : 'Failed to save as template',
          ),
          backgroundColor: success ? AppColors.success : AppColors.error,
        ),
      );
    }
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Plan'),
        content: Text(
          'Are you sure you want to delete "${plan.name}"?\n\n'
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await ref
                  .read(planProvider.notifier)
                  .deletePlan(plan.id);
              if (context.mounted) {
                if (success) {
                  context.pop();
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success ? 'Plan deleted' : 'Failed to delete plan',
                    ),
                    backgroundColor: success
                        ? AppColors.success
                        : AppColors.error,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: AppSpacing.xs),
            Text(
              value,
              style: AppTextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
