import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/services/push_notification_service.dart';

/// Keys for notification preferences in SharedPreferences.
class NotificationPrefsKeys {
  static const String pushNotifications = 'pref_push_notifications';
  static const String workoutReminders = 'pref_workout_reminders';
  static const String planAssignments = 'pref_plan_assignments';
  static const String coachMessages = 'pref_coach_messages';
  static const String achievements = 'pref_achievements';
  static const String encouragement = 'pref_encouragement';
}

/// Provider for notification preferences.
final notificationPrefsProvider =
    StateNotifierProvider<NotificationPrefsNotifier, NotificationPrefs>((ref) {
      return NotificationPrefsNotifier();
    });

/// State for notification preferences.
class NotificationPrefs {
  const NotificationPrefs({
    this.pushNotifications = true,
    this.workoutReminders = true,
    this.planAssignments = true,
    this.coachMessages = true,
    this.achievements = true,
    this.encouragement = true,
    this.isLoading = false,
  });

  final bool pushNotifications;
  final bool workoutReminders;
  final bool planAssignments;
  final bool coachMessages;
  final bool achievements;
  final bool encouragement;
  final bool isLoading;

  NotificationPrefs copyWith({
    bool? pushNotifications,
    bool? workoutReminders,
    bool? planAssignments,
    bool? coachMessages,
    bool? achievements,
    bool? encouragement,
    bool? isLoading,
  }) {
    return NotificationPrefs(
      pushNotifications: pushNotifications ?? this.pushNotifications,
      workoutReminders: workoutReminders ?? this.workoutReminders,
      planAssignments: planAssignments ?? this.planAssignments,
      coachMessages: coachMessages ?? this.coachMessages,
      achievements: achievements ?? this.achievements,
      encouragement: encouragement ?? this.encouragement,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// Notifier for notification preferences.
class NotificationPrefsNotifier extends StateNotifier<NotificationPrefs> {
  NotificationPrefsNotifier()
    : super(const NotificationPrefs(isLoading: true)) {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      state = NotificationPrefs(
        pushNotifications:
            prefs.getBool(NotificationPrefsKeys.pushNotifications) ?? true,
        workoutReminders:
            prefs.getBool(NotificationPrefsKeys.workoutReminders) ?? true,
        planAssignments:
            prefs.getBool(NotificationPrefsKeys.planAssignments) ?? true,
        coachMessages:
            prefs.getBool(NotificationPrefsKeys.coachMessages) ?? true,
        achievements: prefs.getBool(NotificationPrefsKeys.achievements) ?? true,
        encouragement:
            prefs.getBool(NotificationPrefsKeys.encouragement) ?? true,
        isLoading: false,
      );
    } catch (e) {
      state = const NotificationPrefs(isLoading: false);
    }
  }

  Future<void> setPushNotifications(bool value) async {
    state = state.copyWith(pushNotifications: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(NotificationPrefsKeys.pushNotifications, value);

    // Also subscribe/unsubscribe from FCM topics
    if (value) {
      await PushNotificationService.instance.subscribeToTopic('all_users');
    } else {
      await PushNotificationService.instance.unsubscribeFromTopic('all_users');
    }
  }

  Future<void> setWorkoutReminders(bool value) async {
    state = state.copyWith(workoutReminders: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(NotificationPrefsKeys.workoutReminders, value);

    if (value) {
      await PushNotificationService.instance.subscribeToTopic(
        'workout_reminders',
      );
    } else {
      await PushNotificationService.instance.unsubscribeFromTopic(
        'workout_reminders',
      );
    }
  }

  Future<void> setPlanAssignments(bool value) async {
    state = state.copyWith(planAssignments: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(NotificationPrefsKeys.planAssignments, value);
  }

  Future<void> setCoachMessages(bool value) async {
    state = state.copyWith(coachMessages: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(NotificationPrefsKeys.coachMessages, value);
  }

  Future<void> setAchievements(bool value) async {
    state = state.copyWith(achievements: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(NotificationPrefsKeys.achievements, value);

    if (value) {
      await PushNotificationService.instance.subscribeToTopic('achievements');
    } else {
      await PushNotificationService.instance.unsubscribeFromTopic(
        'achievements',
      );
    }
  }

  Future<void> setEncouragement(bool value) async {
    state = state.copyWith(encouragement: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(NotificationPrefsKeys.encouragement, value);
  }

  Future<void> enableAll() async {
    await setPushNotifications(true);
    await setWorkoutReminders(true);
    await setPlanAssignments(true);
    await setCoachMessages(true);
    await setAchievements(true);
    await setEncouragement(true);
  }

  Future<void> disableAll() async {
    await setPushNotifications(false);
    await setWorkoutReminders(false);
    await setPlanAssignments(false);
    await setCoachMessages(false);
    await setAchievements(false);
    await setEncouragement(false);
  }
}

/// Screen for managing notification preferences.
class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(notificationPrefsProvider);

    if (prefs.isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Notification Settings')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'enable_all') {
                ref.read(notificationPrefsProvider.notifier).enableAll();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('All notifications enabled'),
                    backgroundColor: AppColors.success,
                  ),
                );
              } else if (value == 'disable_all') {
                ref.read(notificationPrefsProvider.notifier).disableAll();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('All notifications disabled'),
                    backgroundColor: AppColors.warning,
                  ),
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'enable_all',
                child: Row(
                  children: [
                    Icon(Icons.notifications_active, size: 20),
                    SizedBox(width: AppSpacing.sm),
                    Text('Enable All'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'disable_all',
                child: Row(
                  children: [
                    Icon(Icons.notifications_off, size: 20),
                    SizedBox(width: AppSpacing.sm),
                    Text('Disable All'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          // Master toggle
          _buildMasterToggle(context, ref, prefs),
          const SizedBox(height: AppSpacing.lg),

          // Notification types section
          _buildSectionHeader('Notification Types'),
          const SizedBox(height: AppSpacing.sm),

          _NotificationTile(
            icon: Icons.alarm,
            iconColor: AppColors.warning,
            title: 'Workout Reminders',
            subtitle: 'Daily reminders to complete your workout',
            value: prefs.workoutReminders,
            enabled: prefs.pushNotifications,
            onChanged: (value) {
              ref
                  .read(notificationPrefsProvider.notifier)
                  .setWorkoutReminders(value);
            },
          ),

          _NotificationTile(
            icon: Icons.assignment,
            iconColor: AppColors.info,
            title: 'New Plan Assignments',
            subtitle: 'When your coach assigns a new training plan',
            value: prefs.planAssignments,
            enabled: prefs.pushNotifications,
            onChanged: (value) {
              ref
                  .read(notificationPrefsProvider.notifier)
                  .setPlanAssignments(value);
            },
          ),

          _NotificationTile(
            icon: Icons.message,
            iconColor: AppColors.primary,
            title: 'Coach Messages',
            subtitle: 'Messages and updates from your coach',
            value: prefs.coachMessages,
            enabled: prefs.pushNotifications,
            onChanged: (value) {
              ref
                  .read(notificationPrefsProvider.notifier)
                  .setCoachMessages(value);
            },
          ),

          _NotificationTile(
            icon: Icons.emoji_events,
            iconColor: AppColors.warning,
            title: 'Achievements',
            subtitle: 'When you unlock new achievements',
            value: prefs.achievements,
            enabled: prefs.pushNotifications,
            onChanged: (value) {
              ref
                  .read(notificationPrefsProvider.notifier)
                  .setAchievements(value);
            },
          ),

          _NotificationTile(
            icon: Icons.favorite,
            iconColor: AppColors.error,
            title: 'Encouragement',
            subtitle: 'Motivational messages from your coach',
            value: prefs.encouragement,
            enabled: prefs.pushNotifications,
            onChanged: (value) {
              ref
                  .read(notificationPrefsProvider.notifier)
                  .setEncouragement(value);
            },
          ),

          const SizedBox(height: AppSpacing.xl),

          // Info card
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: AppColors.info),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'You can also manage notifications in your device settings.',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.info,
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

  Widget _buildMasterToggle(
    BuildContext context,
    WidgetRef ref,
    NotificationPrefs prefs,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: prefs.pushNotifications
            ? AppColors.primary.withValues(alpha: 0.1)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: prefs.pushNotifications
              ? AppColors.primary.withValues(alpha: 0.3)
              : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: prefs.pushNotifications
                  ? AppColors.primary
                  : AppColors.textSecondary,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Icon(
              prefs.pushNotifications
                  ? Icons.notifications_active
                  : Icons.notifications_off,
              color: AppColors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Push Notifications',
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  prefs.pushNotifications
                      ? 'Notifications are enabled'
                      : 'All notifications are disabled',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: prefs.pushNotifications,
            onChanged: (value) {
              ref
                  .read(notificationPrefsProvider.notifier)
                  .setPushNotifications(value);
            },
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: AppTextStyles.titleSmall.copyWith(
        color: AppColors.textSecondary,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

/// A tile for toggling a specific notification type.
class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final effectiveValue = enabled && value;
    final effectiveEnabled = enabled;

    return Opacity(
      opacity: effectiveEnabled ? 1.0 : 0.5,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: AppColors.border),
        ),
        child: SwitchListTile(
          secondary: Container(
            padding: const EdgeInsets.all(AppSpacing.xs),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          title: Text(
            title,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          value: effectiveValue,
          onChanged: effectiveEnabled ? onChanged : null,
          activeColor: AppColors.primary,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
        ),
      ),
    );
  }
}
