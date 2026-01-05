import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../achievements/presentation/widgets/achievement_celebration_dialog.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../plans/domain/entities/entities.dart';
import '../../domain/entities/entities.dart';
import '../providers/athlete_provider.dart';

/// Screen for logging a completed workout activity.
///
/// Allows athletes to record duration, effort level, notes,
/// and optionally distance for cardio activities.
class LogActivityScreen extends ConsumerStatefulWidget {
  /// Creates a log activity screen.
  const LogActivityScreen({required this.activityId, super.key});

  /// The activity ID to log.
  final String activityId;

  @override
  ConsumerState<LogActivityScreen> createState() => _LogActivityScreenState();
}

class _LogActivityScreenState extends ConsumerState<LogActivityScreen> {
  final _formKey = GlobalKey<FormState>();
  final _durationController = TextEditingController();
  final _notesController = TextEditingController();
  final _distanceController = TextEditingController();

  int _effortLevel = 5;
  ActivityEntity? _activity;
  PlanAssignmentEntity? _assignment;

  @override
  void initState() {
    super.initState();
    _loadActivityDetails();
  }

  Future<void> _loadActivityDetails() async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    final assignmentsAsync = await ref.read(
      athletePlanAssignmentsProvider(currentUser.id).future,
    );

    // Find the activity in any assignment
    for (final assignment in assignmentsAsync) {
      final activities = await ref.read(
        assignmentActivitiesProvider(assignment.id).future,
      );
      final activity = activities
          .where((a) => a.id == widget.activityId)
          .firstOrNull;

      if (activity != null) {
        setState(() {
          _activity = activity;
          _assignment = assignment;
          _durationController.text = (activity.targetDuration ?? 30).toString();
        });
        break;
      }
    }
  }

  @override
  void dispose() {
    _durationController.dispose();
    _notesController.dispose();
    _distanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final logState = ref.watch(activityLogNotifierProvider);

    // Listen for success/error states
    ref.listen<ActivityLogState>(activityLogNotifierProvider, (_, state) async {
      if (state is ActivityLogSuccess) {
        _showSuccessMessage();

        // Show achievement celebration if any were unlocked
        if (state.unlockedAchievements != null &&
            state.unlockedAchievements!.isNotEmpty) {
          await AchievementCelebrationDialog.show(
            context,
            state.unlockedAchievements!,
          );
        }

        if (mounted) context.pop();
      } else if (state is ActivityLogError) {
        _showErrorMessage(state.message);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Log Workout'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: _activity == null
          ? const Center(child: LoadingIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.screenPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildActivityInfo(),
                    const SizedBox(height: AppSpacing.xl),
                    _buildDurationInput(),
                    const SizedBox(height: AppSpacing.lg),
                    _buildEffortSlider(),
                    if (_isCardioActivity()) ...[
                      const SizedBox(height: AppSpacing.lg),
                      _buildDistanceInput(),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    _buildNotesInput(),
                    const SizedBox(height: AppSpacing.xl),
                    _buildSubmitButton(logState),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildActivityInfo() {
    return BaseCard(
      backgroundColor: AppColors.primary,
      borderColor: AppColors.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_activity!.typeIcon, color: AppColors.white, size: 28),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _activity!.name,
                      style: AppTextStyles.titleLarge.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _activity!.dayName,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_activity!.instructions != null) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppColors.white.withValues(alpha: 0.8),
                    size: 18,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      _activity!.instructions!,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDurationInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Duration (minutes)', style: AppTextStyles.labelLarge),
        const SizedBox(height: AppSpacing.xs),
        TextFormField(
          controller: _durationController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.timer_outlined),
            hintText: 'Enter duration in minutes',
            suffixText: 'min',
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              borderSide: BorderSide.none,
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter duration';
            }
            final duration = int.tryParse(value);
            if (duration == null || duration <= 0) {
              return 'Please enter a valid duration';
            }
            if (duration > 480) {
              return 'Duration cannot exceed 8 hours';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildEffortSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Effort Level', style: AppTextStyles.labelLarge),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: _getEffortColor().withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Text(
                '$_effortLevel/10 - ${_getEffortLabel()}',
                style: AppTextStyles.labelMedium.copyWith(
                  color: _getEffortColor(),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: _getEffortColor(),
            inactiveTrackColor: AppColors.surface,
            thumbColor: _getEffortColor(),
            overlayColor: _getEffortColor().withValues(alpha: 0.2),
            valueIndicatorColor: _getEffortColor(),
          ),
          child: Slider(
            value: _effortLevel.toDouble(),
            min: 1,
            max: 10,
            divisions: 9,
            onChanged: (value) {
              setState(() => _effortLevel = value.round());
            },
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Easy',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              'Maximum',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDistanceInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Distance (optional)', style: AppTextStyles.labelLarge),
        const SizedBox(height: AppSpacing.xs),
        TextFormField(
          controller: _distanceController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.straighten),
            hintText: 'Enter distance',
            suffixText: 'km',
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              borderSide: BorderSide.none,
            ),
          ),
          validator: (value) {
            if (value != null && value.isNotEmpty) {
              final distance = double.tryParse(value);
              if (distance == null || distance <= 0) {
                return 'Please enter a valid distance';
              }
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildNotesInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Notes (optional)', style: AppTextStyles.labelLarge),
        const SizedBox(height: AppSpacing.xs),
        TextFormField(
          controller: _notesController,
          maxLines: 4,
          maxLength: 500,
          decoration: InputDecoration(
            prefixIcon: const Padding(
              padding: EdgeInsets.only(bottom: 60),
              child: Icon(Icons.note_outlined),
            ),
            hintText: 'How did the workout feel? Any observations?',
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton(ActivityLogState logState) {
    final isSubmitting = logState is ActivityLogLoading;

    return SizedBox(
      width: double.infinity,
      child: PrimaryButton(
        text: 'Log Workout',
        onPressed: isSubmitting ? null : _submitLog,
        isLoading: isSubmitting,
      ),
    );
  }

  bool _isCardioActivity() {
    if (_activity == null) return false;
    return _activity!.type == 'cardio' || _activity!.type == 'hiit';
  }

  Color _getEffortColor() {
    if (_effortLevel <= 3) return AppColors.success;
    if (_effortLevel <= 6) return AppColors.warning;
    return AppColors.error;
  }

  String _getEffortLabel() {
    if (_effortLevel <= 2) return 'Very Easy';
    if (_effortLevel <= 4) return 'Easy';
    if (_effortLevel <= 6) return 'Moderate';
    if (_effortLevel <= 8) return 'Hard';
    return 'Maximum';
  }

  Future<void> _submitLog() async {
    if (!_formKey.currentState!.validate()) return;
    if (_activity == null || _assignment == null) return;

    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    final duration = int.parse(_durationController.text);
    final distance = _distanceController.text.isNotEmpty
        ? double.tryParse(_distanceController.text)
        : null;
    final notes = _notesController.text.isNotEmpty
        ? _notesController.text
        : null;

    final log = ActivityLogEntity(
      id: const Uuid().v4(),
      athleteId: currentUser.id,
      assignmentId: _assignment!.id,
      activityId: _activity!.id,
      activityName: _activity!.name,
      completedAt: DateTime.now(),
      actualDuration: duration,
      distance: distance,
      effortLevel: _effortLevel,
      notes: notes,
      photoUrl: null,
      coachId: _assignment!.coachId,
    );

    await ref.read(activityLogNotifierProvider.notifier).logActivity(log);
  }

  void _showSuccessMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.white),
            SizedBox(width: AppSpacing.sm),
            Text('Workout logged successfully! 💪'),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: AppColors.white),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
      ),
    );
  }
}
