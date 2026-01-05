import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/entities.dart';
import '../providers/plan_provider.dart';
import '../providers/plan_state.dart';
import '../widgets/widgets.dart';

/// Screen for creating or editing a training plan.
class CreateEditPlanScreen extends ConsumerStatefulWidget {
  /// Creates a new [CreateEditPlanScreen].
  const CreateEditPlanScreen({super.key, this.planId});

  /// Plan ID for editing. Null for creating a new plan.
  final String? planId;

  /// Whether this is editing an existing plan.
  bool get isEditing => planId != null;

  @override
  ConsumerState<CreateEditPlanScreen> createState() =>
      _CreateEditPlanScreenState();
}

class _CreateEditPlanScreenState extends ConsumerState<CreateEditPlanScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  int _durationDays = 7;
  bool _isTemplate = false;
  List<ActivityEntity> _activities = [];
  bool _isLoading = false;
  TrainingPlanEntity? _existingPlan;

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) {
      _loadExistingPlan();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingPlan() async {
    setState(() => _isLoading = true);

    try {
      final plan = await ref.read(planByIdProvider(widget.planId!).future);

      if (plan != null && mounted) {
        setState(() {
          _existingPlan = plan;
          _nameController.text = plan.name;
          _descriptionController.text = plan.description ?? '';
          _durationDays = plan.durationDays;
          _isTemplate = plan.isTemplate;
          _activities = List.from(plan.activities);
          _isLoading = false;
        });
      } else if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Plan not found')));
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading plan: $e')));
        context.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final planState = ref.watch(planProvider);
    final isSubmitting = planState is PlanLoading;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Plan' : 'Create Plan'),
      ),
      body: _isLoading
          ? const Center(child: LoadingIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  _buildPlanDetailsSection(),
                  const SizedBox(height: AppSpacing.lg),
                  _buildDurationSection(),
                  const SizedBox(height: AppSpacing.lg),
                  _buildActivitiesSection(),
                  const SizedBox(height: AppSpacing.xl),
                  _buildSaveButton(isSubmitting),
                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
    );
  }

  Widget _buildPlanDetailsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Plan Details',
          style: AppTextStyles.titleMedium.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        CustomTextField(
          label: 'Plan Name',
          controller: _nameController,
          hintText: 'e.g., Beginner Running Program',
          prefixIcon: Icons.fitness_center,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter a plan name';
            }
            if (value.length < 3) {
              return 'Name must be at least 3 characters';
            }
            return null;
          },
        ),
        const SizedBox(height: AppSpacing.md),
        CustomTextField(
          label: 'Description (Optional)',
          controller: _descriptionController,
          hintText: 'Describe what this plan is about...',
          prefixIcon: Icons.description_outlined,
          maxLines: 3,
        ),
        const SizedBox(height: AppSpacing.md),
        SwitchListTile(
          title: const Text('Save as Template'),
          subtitle: const Text('Reuse this plan for multiple athletes'),
          value: _isTemplate,
          onChanged: (value) => setState(() => _isTemplate = value),
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }

  Widget _buildDurationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Duration',
          style: AppTextStyles.titleMedium.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            _DurationChip(
              label: '1 Week',
              days: 7,
              isSelected: _durationDays == 7,
              onTap: () => setState(() => _durationDays = 7),
            ),
            _DurationChip(
              label: '2 Weeks',
              days: 14,
              isSelected: _durationDays == 14,
              onTap: () => setState(() => _durationDays = 14),
            ),
            _DurationChip(
              label: '4 Weeks',
              days: 28,
              isSelected: _durationDays == 28,
              onTap: () => setState(() => _durationDays = 28),
            ),
            _DurationChip(
              label: 'Custom',
              days: -1,
              isSelected: ![7, 14, 28].contains(_durationDays),
              onTap: _showCustomDurationDialog,
            ),
          ],
        ),
        if (![7, 14, 28].contains(_durationDays))
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Text(
              'Custom duration: $_durationDays days',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary),
            ),
          ),
      ],
    );
  }

  Widget _buildActivitiesSection() {
    final activitiesByDay = <int, List<ActivityEntity>>{};
    for (final activity in _activities) {
      activitiesByDay.putIfAbsent(activity.dayOfWeek, () => []).add(activity);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Activities',
              style: AppTextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton.icon(
              onPressed: _showAddActivityDialog,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Activity'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        if (_activities.isEmpty)
          _buildEmptyActivities()
        else
          ActivitiesByDayList(
            activitiesByDay: activitiesByDay,
            onActivityEdit: _editActivity,
            onActivityDelete: _deleteActivity,
          ),
      ],
    );
  }

  Widget _buildEmptyActivities() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.border, style: BorderStyle.solid),
      ),
      child: Column(
        children: [
          Icon(
            Icons.add_circle_outline,
            size: 48,
            color: AppColors.textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'No activities yet',
            style: AppTextStyles.titleSmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Add activities to build your training plan',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton.icon(
            onPressed: _showAddActivityDialog,
            icon: const Icon(Icons.add),
            label: const Text('Add First Activity'),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton(bool isSubmitting) {
    return PrimaryButton(
      text: widget.isEditing ? 'Update Plan' : 'Create Plan',
      onPressed: _activities.isEmpty ? null : _savePlan,
      isLoading: isSubmitting,
    );
  }

  void _showCustomDurationDialog() {
    int tempDays = _durationDays;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Custom Duration'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$tempDays days', style: AppTextStyles.headlineMedium),
            Slider(
              value: tempDays.toDouble(),
              min: 1,
              max: 90,
              divisions: 89,
              label: '$tempDays days',
              onChanged: (value) {
                tempDays = value.round();
                (context as Element).markNeedsBuild();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() => _durationDays = tempDays);
              Navigator.pop(context);
            },
            child: const Text('Set'),
          ),
        ],
      ),
    );
  }

  void _showAddActivityDialog() {
    _showActivityDialog();
  }

  void _editActivity(ActivityEntity activity) {
    _showActivityDialog(existingActivity: activity);
  }

  void _deleteActivity(ActivityEntity activity) {
    setState(() {
      _activities.removeWhere((a) => a.id == activity.id);
    });
  }

  void _showActivityDialog({ActivityEntity? existingActivity}) {
    final nameController = TextEditingController(
      text: existingActivity?.name ?? '',
    );
    final instructionsController = TextEditingController(
      text: existingActivity?.instructions ?? '',
    );
    String selectedType = existingActivity?.type ?? ActivityTypes.cardio;
    int selectedDay = existingActivity?.dayOfWeek ?? 1;
    int? duration = existingActivity?.targetDuration;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: AppSpacing.md,
            right: AppSpacing.md,
            top: AppSpacing.md,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                existingActivity != null ? 'Edit Activity' : 'Add Activity',
                style: AppTextStyles.titleLarge,
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Activity Name',
                  hintText: 'e.g., Morning Run',
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<String>(
                value: selectedType,
                decoration: const InputDecoration(labelText: 'Type'),
                items: ActivityTypes.all.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(ActivityTypes.displayName(type)),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setSheetState(() => selectedType = value);
                  }
                },
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<int>(
                value: selectedDay,
                decoration: const InputDecoration(labelText: 'Day of Week'),
                items: List.generate(7, (index) {
                  const days = [
                    'Monday',
                    'Tuesday',
                    'Wednesday',
                    'Thursday',
                    'Friday',
                    'Saturday',
                    'Sunday',
                  ];
                  return DropdownMenuItem(
                    value: index + 1,
                    child: Text(days[index]),
                  );
                }),
                onChanged: (value) {
                  if (value != null) {
                    setSheetState(() => selectedDay = value);
                  }
                },
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Duration (minutes)',
                  hintText: 'e.g., 30',
                ),
                controller: TextEditingController(
                  text: duration?.toString() ?? '',
                ),
                onChanged: (value) {
                  duration = int.tryParse(value);
                },
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: instructionsController,
                decoration: const InputDecoration(
                  labelText: 'Instructions (Optional)',
                  hintText: 'Add any notes or instructions...',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: SecondaryButton(
                      text: 'Cancel',
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: PrimaryButton(
                      text: existingActivity != null ? 'Update' : 'Add',
                      onPressed: () {
                        if (nameController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please enter an activity name'),
                            ),
                          );
                          return;
                        }

                        final activity = ActivityEntity(
                          id:
                              existingActivity?.id ??
                              DateTime.now().millisecondsSinceEpoch.toString(),
                          name: nameController.text,
                          type: selectedType,
                          dayOfWeek: selectedDay,
                          targetDuration: duration,
                          instructions: instructionsController.text.isNotEmpty
                              ? instructionsController.text
                              : null,
                          order:
                              existingActivity?.order ??
                              _activities
                                  .where((a) => a.dayOfWeek == selectedDay)
                                  .length,
                        );

                        setState(() {
                          if (existingActivity != null) {
                            final index = _activities.indexWhere(
                              (a) => a.id == existingActivity.id,
                            );
                            if (index >= 0) {
                              _activities[index] = activity;
                            }
                          } else {
                            _activities.add(activity);
                          }
                        });

                        Navigator.pop(context);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _savePlan() async {
    if (!_formKey.currentState!.validate()) return;
    if (_activities.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one activity')),
      );
      return;
    }

    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    bool success;

    if (widget.isEditing && _existingPlan != null) {
      final updatedPlan = _existingPlan!.copyWith(
        name: _nameController.text,
        description: _descriptionController.text.isNotEmpty
            ? _descriptionController.text
            : null,
        durationDays: _durationDays,
        isTemplate: _isTemplate,
        activities: _activities,
      );

      success = await ref.read(planProvider.notifier).updatePlan(updatedPlan);
    } else {
      success = await ref
          .read(planProvider.notifier)
          .createPlan(
            coachId: currentUser.id,
            name: _nameController.text,
            description: _descriptionController.text.isNotEmpty
                ? _descriptionController.text
                : null,
            durationDays: _durationDays,
            isTemplate: _isTemplate,
            activities: _activities,
          );
    }

    if (success && mounted) {
      // Invalidate the plans stream to force refresh
      ref.invalidate(plansStreamProvider);

      // Also invalidate the specific plan provider if editing
      if (widget.isEditing && widget.planId != null) {
        ref.invalidate(planByIdProvider(widget.planId!));
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isEditing
                ? 'Plan updated successfully'
                : 'Plan created successfully',
          ),
          backgroundColor: AppColors.success,
        ),
      );
      context.pop();
    }
  }
}

class _DurationChip extends StatelessWidget {
  const _DurationChip({
    required this.label,
    required this.days,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final int days;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.primary.withValues(alpha: 0.2),
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : AppColors.textPrimary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
}
