import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/entities.dart';
import '../providers/plan_provider.dart';
import '../widgets/widgets.dart';

/// Screen displaying all training plans for a coach.
class PlansListScreen extends ConsumerStatefulWidget {
  /// Creates a new [PlansListScreen].
  const PlansListScreen({super.key});

  @override
  ConsumerState<PlansListScreen> createState() => _PlansListScreenState();
}

class _PlansListScreenState extends ConsumerState<PlansListScreen> {
  String _searchQuery = '';
  bool _showTemplatesOnly = false;

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);

    if (currentUser == null) {
      return const Scaffold(body: Center(child: LoadingIndicator()));
    }

    final plansStream = ref.watch(plansStreamProvider(currentUser.id));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Training Plans'),
        actions: [
          IconButton(
            icon: Icon(
              _showTemplatesOnly ? Icons.bookmark : Icons.bookmark_border,
            ),
            tooltip: 'Show templates only',
            onPressed: () {
              setState(() => _showTemplatesOnly = !_showTemplatesOnly);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: plansStream.when(
              data: (plans) => _buildPlansList(plans),
              loading: () => const Center(child: LoadingIndicator()),
              error: (error, stack) => _buildError(error.toString()),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
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
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search plans...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => setState(() => _searchQuery = ''),
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          filled: true,
          fillColor: AppColors.surfaceVariant,
        ),
        onChanged: (value) => setState(() => _searchQuery = value),
      ),
    );
  }

  Widget _buildPlansList(List<TrainingPlanEntity> plans) {
    // Filter plans based on search and template filter
    var filteredPlans = plans;

    if (_searchQuery.isNotEmpty) {
      filteredPlans = filteredPlans
          .where(
            (plan) =>
                plan.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                (plan.description?.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ) ??
                    false),
          )
          .toList();
    }

    if (_showTemplatesOnly) {
      filteredPlans = filteredPlans.where((plan) => plan.isTemplate).toList();
    }

    if (filteredPlans.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () async {
        // Refresh by invalidating the stream provider
        ref.invalidate(plansStreamProvider);
      },
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        itemCount: filteredPlans.length,
        itemBuilder: (context, index) {
          final plan = filteredPlans[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: PlanCard(
              plan: plan,
              onTap: () => _navigateToPlanDetail(plan),
              onEdit: () => _navigateToEditPlan(plan),
              onDelete: () => _confirmDeletePlan(plan),
              onAssign: () => _navigateToAssignPlan(plan),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _showTemplatesOnly
                  ? Icons.bookmark_border
                  : Icons.fitness_center_outlined,
              size: 80,
              color: AppColors.textSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No plans match your search'
                  : _showTemplatesOnly
                  ? 'No template plans yet'
                  : 'No training plans yet',
              style: AppTextStyles.titleMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Try a different search term'
                  : 'Create your first plan to get started',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (_searchQuery.isEmpty && !_showTemplatesOnly) ...[
              const SizedBox(height: AppSpacing.lg),
              PrimaryButton(
                text: 'Create Plan',
                onPressed: () => context.push(RoutePaths.coachCreatePlan),
                width: 200,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: AppSpacing.md),
            Text('Error loading plans', style: AppTextStyles.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            SecondaryButton(
              text: 'Retry',
              onPressed: () => ref.invalidate(plansStreamProvider),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToPlanDetail(TrainingPlanEntity plan) {
    context.push(RoutePaths.coachPlanDetail.replaceFirst(':planId', plan.id));
  }

  void _navigateToEditPlan(TrainingPlanEntity plan) {
    context.push(RoutePaths.coachEditPlan.replaceFirst(':planId', plan.id));
  }

  void _navigateToAssignPlan(TrainingPlanEntity plan) {
    context.push(RoutePaths.coachAssignPlan.replaceFirst(':planId', plan.id));
  }

  void _confirmDeletePlan(TrainingPlanEntity plan) {
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
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deletePlan(plan);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deletePlan(TrainingPlanEntity plan) async {
    final success = await ref.read(planProvider.notifier).deletePlan(plan.id);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Plan deleted' : 'Failed to delete plan'),
          backgroundColor: success ? AppColors.success : AppColors.error,
        ),
      );
    }
  }
}
