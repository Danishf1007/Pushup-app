import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../plans/domain/entities/entities.dart';
import '../../../plans/presentation/providers/plan_provider.dart';
import '../providers/coach_provider.dart';

/// Screen for assigning a training plan to athletes.
///
/// Allows coaches to select athletes and set the assignment date range.
class AssignPlanScreen extends ConsumerStatefulWidget {
  /// Creates an assign plan screen.
  const AssignPlanScreen({super.key, required this.planId});

  /// The ID of the plan to assign.
  final String planId;

  @override
  ConsumerState<AssignPlanScreen> createState() => _AssignPlanScreenState();
}

class _AssignPlanScreenState extends ConsumerState<AssignPlanScreen> {
  final Set<String> _selectedAthleteIds = {};
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final planAsync = ref.watch(planByIdProvider(widget.planId));
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Assign Plan')),
      body: planAsync.when(
        data: (plan) {
          if (plan == null) {
            return const Center(child: Text('Plan not found'));
          }
          if (currentUser == null) {
            return const Center(child: LoadingIndicator());
          }
          return _buildContent(plan, currentUser.id);
        },
        loading: () => const Center(child: LoadingIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildContent(TrainingPlanEntity plan, String coachId) {
    final athletesAsync = ref.watch(athletesStreamProvider(coachId));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPlanSummary(plan),
          const SizedBox(height: AppSpacing.lg),
          _buildDateSelection(plan),
          const SizedBox(height: AppSpacing.lg),
          _buildAthletesSelection(athletesAsync),
        ],
      ),
    );
  }

  Widget _buildPlanSummary(TrainingPlanEntity plan) {
    return BaseCard(
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
                Text(plan.name, style: AppTextStyles.titleSmall),
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
        ],
      ),
    );
  }

  Widget _buildDateSelection(TrainingPlanEntity plan) {
    // Auto-calculate end date based on plan duration
    final suggestedEndDate = _startDate.add(Duration(days: plan.durationDays));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Schedule', style: AppTextStyles.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        BaseCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: [
              _buildDateRow(
                label: 'Start Date',
                date: _startDate,
                onTap: () => _selectDate(isStartDate: true),
              ),
              const Divider(height: AppSpacing.lg),
              _buildDateRow(
                label: 'End Date',
                date: _endDate ?? suggestedEndDate,
                isAutoCalculated: _endDate == null,
                onTap: () => _selectDate(isStartDate: false),
              ),
            ],
          ),
        ),
        if (_endDate == null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            'End date auto-calculated from plan duration',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDateRow({
    required String label,
    required DateTime date,
    required VoidCallback onTap,
    bool isAutoCalculated = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Icon(Icons.calendar_today, color: AppColors.textSecondary, size: 20),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Row(
                  children: [
                    Text(_formatDate(date), style: AppTextStyles.bodyLarge),
                    if (isAutoCalculated) ...[
                      const SizedBox(width: AppSpacing.xs),
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
                          'Auto',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.info,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const Icon(Icons.edit, color: AppColors.textSecondary, size: 18),
        ],
      ),
    );
  }

  Widget _buildAthletesSelection(AsyncValue<List<UserEntity>> athletesAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Select Athletes', style: AppTextStyles.titleMedium),
            if (_selectedAthleteIds.isNotEmpty)
              Text(
                '${_selectedAthleteIds.length} selected',
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.primary,
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        athletesAsync.when(
          data: (athletes) {
            if (athletes.isEmpty) {
              return BaseCard(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  children: [
                    Icon(
                      Icons.people_outline,
                      size: 48,
                      color: AppColors.textSecondary.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'No athletes available',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: athletes.map((athlete) {
                final isSelected = _selectedAthleteIds.contains(athlete.id);
                return _AthleteSelectionTile(
                  athlete: athlete,
                  isSelected: isSelected,
                  onChanged: (selected) {
                    setState(() {
                      if (selected == true) {
                        _selectedAthleteIds.add(athlete.id);
                      } else {
                        _selectedAthleteIds.remove(athlete.id);
                      }
                    });
                  },
                );
              }).toList(),
            );
          },
          loading: () => const Center(child: LoadingIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.md,
        bottom: MediaQuery.of(context).padding.bottom + AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_selectedAthleteIds.length} athletes selected',
                  style: AppTextStyles.titleSmall,
                ),
                Text(
                  _selectedAthleteIds.isEmpty
                      ? 'Select at least one athlete'
                      : 'Ready to assign',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: _selectedAthleteIds.isEmpty
                        ? AppColors.warning
                        : AppColors.success,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: PrimaryButton(
              text: _isSubmitting ? 'Assigning...' : 'Assign Plan',
              onPressed: _selectedAthleteIds.isEmpty || _isSubmitting
                  ? null
                  : _assignPlan,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate({required bool isStartDate}) async {
    final initialDate = isStartDate ? _startDate : (_endDate ?? DateTime.now());
    final firstDate = isStartDate ? DateTime.now() : _startDate;
    final lastDate = DateTime.now().add(const Duration(days: 365));

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (pickedDate != null) {
      setState(() {
        if (isStartDate) {
          _startDate = pickedDate;
          // Reset end date if it's now before start date
          if (_endDate != null && _endDate!.isBefore(_startDate)) {
            _endDate = null;
          }
        } else {
          _endDate = pickedDate;
        }
      });
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  Future<void> _assignPlan() async {
    if (_selectedAthleteIds.isEmpty) return;

    setState(() => _isSubmitting = true);

    try {
      final planAsync = ref.read(planByIdProvider(widget.planId));
      final plan = planAsync.valueOrNull;
      if (plan == null) throw Exception('Plan not found');

      final currentUser = ref.read(currentUserProvider);
      if (currentUser == null) throw Exception('User not authenticated');

      final endDate =
          _endDate ?? _startDate.add(Duration(days: plan.durationDays));

      // Create assignments for all selected athletes
      for (final athleteId in _selectedAthleteIds) {
        final assignment = PlanAssignmentEntity(
          id: '', // Will be set by Firestore
          planId: widget.planId,
          athleteId: athleteId,
          coachId: currentUser.id,
          assignedAt: DateTime.now(),
          startDate: _startDate,
          endDate: endDate,
          status: AssignmentStatus.active,
          completionRate: 0,
        );

        await ref.read(planRepositoryProvider).assignPlan(assignment);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Plan assigned to ${_selectedAthleteIds.length} athlete${_selectedAthleteIds.length > 1 ? 's' : ''}',
            ),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error assigning plan: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}

/// Tile for selecting an athlete.
class _AthleteSelectionTile extends StatelessWidget {
  const _AthleteSelectionTile({
    required this.athlete,
    required this.isSelected,
    required this.onChanged,
  });

  final UserEntity athlete;
  final bool isSelected;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    final initials = athlete.displayName.isNotEmpty
        ? athlete.displayName
              .split(' ')
              .take(2)
              .map((e) => e.isNotEmpty ? e[0].toUpperCase() : '')
              .join()
        : 'A';

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: BaseCard(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              child: Text(
                initials,
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(athlete.displayName, style: AppTextStyles.bodyLarge),
                  Text(
                    athlete.email,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Checkbox(
              value: isSelected,
              onChanged: onChanged,
              activeColor: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}
