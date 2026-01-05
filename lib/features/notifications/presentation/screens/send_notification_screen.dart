import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart' show UserRole;
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../coach/presentation/providers/coach_provider.dart';
import '../../domain/entities/notification_entity.dart';
import '../providers/notification_provider.dart';

/// Screen for coaches to send notifications to athletes.
class SendNotificationScreen extends ConsumerStatefulWidget {
  /// Creates a send notification screen.
  const SendNotificationScreen({super.key, this.athleteId});

  /// Optional specific athlete ID to send to.
  final String? athleteId;

  @override
  ConsumerState<SendNotificationScreen> createState() =>
      _SendNotificationScreenState();
}

class _SendNotificationScreenState
    extends ConsumerState<SendNotificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();

  NotificationType _selectedType = NotificationType.motivation;
  final Set<String> _selectedAthletes = {};
  bool _selectAll = false;

  @override
  void initState() {
    super.initState();
    if (widget.athleteId != null) {
      _selectedAthletes.add(widget.athleteId!);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    if (currentUser == null) {
      return const Scaffold(body: Center(child: LoadingIndicator()));
    }

    final athletesAsync = ref.watch(athletesStreamProvider(currentUser.id));

    // Listen for operation state changes
    ref.listen<NotificationOperationState>(notificationNotifierProvider, (
      previous,
      next,
    ) {
      if (next is NotificationOperationSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.message ?? 'Notification sent!'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      } else if (next is NotificationOperationError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.message),
            backgroundColor: AppColors.error,
          ),
        );
      }
    });

    final operationState = ref.watch(notificationNotifierProvider);
    final isLoading = operationState is NotificationOperationLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Send Notification')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          children: [
            // Notification type selector
            _buildTypeSelector(),
            const SizedBox(height: AppSpacing.lg),

            // Recipient selector
            if (widget.athleteId == null) ...[
              _buildRecipientSelector(athletesAsync),
              const SizedBox(height: AppSpacing.lg),
            ] else ...[
              _buildSingleRecipient(athletesAsync),
              const SizedBox(height: AppSpacing.lg),
            ],

            // Title field
            CustomTextField(
              controller: _titleController,
              label: 'Title',
              hintText: 'Enter notification title',
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a title';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),

            // Message field
            CustomTextField(
              controller: _messageController,
              label: 'Message',
              hintText: 'Enter your message',
              maxLines: 4,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a message';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),

            // Quick templates
            _buildTemplates(),
            const SizedBox(height: AppSpacing.xl),

            // Send button
            PrimaryButton(
              text: 'Send Notification',
              onPressed: isLoading || _selectedAthletes.isEmpty
                  ? null
                  : () => _sendNotification(currentUser),
              isLoading: isLoading,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Notification Type', style: AppTextStyles.labelMedium),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            _TypeChip(
              label: 'Motivation',
              icon: Icons.favorite,
              color: AppColors.error,
              isSelected: _selectedType == NotificationType.motivation,
              onTap: () =>
                  setState(() => _selectedType = NotificationType.motivation),
            ),
            _TypeChip(
              label: 'Reminder',
              icon: Icons.alarm,
              color: AppColors.warning,
              isSelected: _selectedType == NotificationType.reminder,
              onTap: () =>
                  setState(() => _selectedType = NotificationType.reminder),
            ),
            _TypeChip(
              label: 'General',
              icon: Icons.notifications,
              color: AppColors.info,
              isSelected: _selectedType == NotificationType.system,
              onTap: () =>
                  setState(() => _selectedType = NotificationType.system),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecipientSelector(AsyncValue<List<UserEntity>> athletesAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Send To', style: AppTextStyles.labelMedium),
            athletesAsync.when(
              data: (athletes) => TextButton(
                onPressed: () {
                  setState(() {
                    _selectAll = !_selectAll;
                    if (_selectAll) {
                      _selectedAthletes.addAll(athletes.map((a) => a.id));
                    } else {
                      _selectedAthletes.clear();
                    }
                  });
                },
                child: Text(_selectAll ? 'Deselect All' : 'Select All'),
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        athletesAsync.when(
          data: (athletes) {
            if (athletes.isEmpty) {
              return BaseCard(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Center(
                  child: Text(
                    'No athletes found',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              );
            }
            return BaseCard(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Column(
                children: athletes.map((athlete) {
                  final isSelected = _selectedAthletes.contains(athlete.id);
                  return CheckboxListTile(
                    value: isSelected,
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          _selectedAthletes.add(athlete.id);
                        } else {
                          _selectedAthletes.remove(athlete.id);
                        }
                        _selectAll =
                            _selectedAthletes.length == athletes.length;
                      });
                    },
                    title: Text(athlete.displayName),
                    subtitle: Text(
                      athlete.email,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    secondary: CircleAvatar(
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      child: Text(
                        athlete.displayName.isNotEmpty
                            ? athlete.displayName[0].toUpperCase()
                            : '?',
                        style: AppTextStyles.titleSmall.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    activeColor: AppColors.primary,
                    checkboxShape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }).toList(),
              ),
            );
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: LoadingIndicator(),
            ),
          ),
          error: (e, _) => BaseCard(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Center(
              child: Text(
                'Error loading athletes',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.error,
                ),
              ),
            ),
          ),
        ),
        if (_selectedAthletes.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Text(
              '${_selectedAthletes.length} athlete(s) selected',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.primary,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSingleRecipient(AsyncValue<List<UserEntity>> athletesAsync) {
    return athletesAsync.when(
      data: (athletes) {
        final athlete = athletes.firstWhere(
          (a) => a.id == widget.athleteId,
          orElse: () => UserEntity(
            id: widget.athleteId!,
            email: '',
            displayName: 'Unknown Athlete',
            role: UserRole.athlete,
            createdAt: DateTime.now(),
          ),
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Send To', style: AppTextStyles.labelMedium),
            const SizedBox(height: AppSpacing.xs),
            BaseCard(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    child: Text(
                      athlete.displayName.isNotEmpty
                          ? athlete.displayName[0].toUpperCase()
                          : '?',
                      style: AppTextStyles.titleSmall.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          athlete.displayName,
                          style: AppTextStyles.titleSmall,
                        ),
                        Text(
                          athlete.email,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.check_circle, color: AppColors.success),
                ],
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: LoadingIndicator()),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildTemplates() {
    final templates = _selectedType == NotificationType.motivation
        ? NotificationTemplates.motivationalMessages
        : NotificationTemplates.reminderMessages;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quick Templates', style: AppTextStyles.labelMedium),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: templates.take(4).map((template) {
            return ActionChip(
              label: Text(
                template.length > 30
                    ? '${template.substring(0, 30)}...'
                    : template,
                style: AppTextStyles.labelSmall,
              ),
              onPressed: () {
                _messageController.text = template;
                if (_titleController.text.isEmpty) {
                  _titleController.text =
                      _selectedType == NotificationType.motivation
                      ? 'Keep Going! 💪'
                      : 'Workout Reminder';
                }
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Future<void> _sendNotification(UserEntity coach) async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedAthletes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one athlete'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final notifier = ref.read(notificationNotifierProvider.notifier);

    if (_selectedAthletes.length == 1) {
      await notifier.sendNotification(
        senderId: coach.id,
        receiverId: _selectedAthletes.first,
        type: _selectedType,
        title: _titleController.text.trim(),
        message: _messageController.text.trim(),
        senderName: coach.displayName,
      );
    } else {
      await notifier.sendBulkNotification(
        senderId: coach.id,
        receiverIds: _selectedAthletes.toList(),
        type: _selectedType,
        title: _titleController.text.trim(),
        message: _messageController.text.trim(),
        senderName: coach.displayName,
      );
    }
  }
}

/// Notification type selection chip.
class _TypeChip extends StatelessWidget {
  const _TypeChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.15) : AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.sm),
          border: Border.all(
            color: isSelected
                ? color
                : AppColors.textSecondary.withValues(alpha: 0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? color : AppColors.textSecondary,
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              label,
              style: AppTextStyles.labelMedium.copyWith(
                color: isSelected ? color : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
