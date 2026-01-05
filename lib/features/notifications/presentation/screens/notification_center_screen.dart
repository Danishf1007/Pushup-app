import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/notification_entity.dart';
import '../providers/notification_provider.dart';

/// Notification Center Screen.
///
/// Displays all notifications for the current user with
/// options to mark as read and delete.
class NotificationCenterScreen extends ConsumerWidget {
  /// Creates a notification center screen.
  const NotificationCenterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    if (currentUser == null) {
      return const Scaffold(body: Center(child: LoadingIndicator()));
    }

    final notificationsAsync = ref.watch(notificationsProvider(currentUser.id));
    final unreadCountAsync = ref.watch(
      unreadNotificationCountProvider(currentUser.id),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          unreadCountAsync.when(
            data: (count) => count > 0
                ? TextButton(
                    onPressed: () => _markAllAsRead(ref, currentUser.id),
                    child: Text(
                      'Mark all read',
                      style: AppTextStyles.labelMedium.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'clear_all') {
                _showClearAllDialog(context, ref, currentUser.id);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'clear_all',
                child: Row(
                  children: [
                    Icon(Icons.delete_sweep, size: 20),
                    SizedBox(width: AppSpacing.xs),
                    Text('Clear all'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: notificationsAsync.when(
        data: (notifications) {
          if (notifications.isEmpty) {
            return _buildEmptyState();
          }
          return _buildNotificationList(context, ref, notifications);
        },
        loading: () => const Center(child: LoadingIndicator()),
        error: (e, _) => Center(
          child: Text(
            'Error loading notifications',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off_outlined,
            size: 80,
            color: AppColors.textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'No notifications',
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            "You're all caught up!",
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationList(
    BuildContext context,
    WidgetRef ref,
    List<NotificationEntity> notifications,
  ) {
    // Group notifications by date
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));

    final todayNotifications = <NotificationEntity>[];
    final yesterdayNotifications = <NotificationEntity>[];
    final olderNotifications = <NotificationEntity>[];

    for (final notification in notifications) {
      if (_isSameDay(notification.sentAt, today)) {
        todayNotifications.add(notification);
      } else if (_isSameDay(notification.sentAt, yesterday)) {
        yesterdayNotifications.add(notification);
      } else {
        olderNotifications.add(notification);
      }
    }

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      children: [
        if (todayNotifications.isNotEmpty) ...[
          _buildSectionHeader('Today'),
          ...todayNotifications.map(
            (n) => _NotificationTile(
              notification: n,
              onTap: () => _onNotificationTap(context, ref, n),
              onDismiss: () => _deleteNotification(ref, n.id),
            ),
          ),
        ],
        if (yesterdayNotifications.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          _buildSectionHeader('Yesterday'),
          ...yesterdayNotifications.map(
            (n) => _NotificationTile(
              notification: n,
              onTap: () => _onNotificationTap(context, ref, n),
              onDismiss: () => _deleteNotification(ref, n.id),
            ),
          ),
        ],
        if (olderNotifications.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          _buildSectionHeader('Earlier'),
          ...olderNotifications.map(
            (n) => _NotificationTile(
              notification: n,
              onTap: () => _onNotificationTap(context, ref, n),
              onDismiss: () => _deleteNotification(ref, n.id),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs, top: AppSpacing.xs),
      child: Text(
        title,
        style: AppTextStyles.labelMedium.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  void _onNotificationTap(
    BuildContext context,
    WidgetRef ref,
    NotificationEntity notification,
  ) {
    // Mark as read
    if (!notification.isRead) {
      ref
          .read(notificationNotifierProvider.notifier)
          .markAsRead(notification.id);
    }

    // Navigate based on notification type
    // For now, just mark as read
    // TODO: Add navigation based on notification.data
  }

  void _markAllAsRead(WidgetRef ref, String userId) {
    ref.read(notificationNotifierProvider.notifier).markAllAsRead(userId);
  }

  void _deleteNotification(WidgetRef ref, String notificationId) {
    ref
        .read(notificationNotifierProvider.notifier)
        .deleteNotification(notificationId);
  }

  void _showClearAllDialog(BuildContext context, WidgetRef ref, String userId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear all notifications?'),
        content: const Text(
          'This will permanently delete all your notifications.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref
                  .read(notificationNotifierProvider.notifier)
                  .deleteAllNotifications(userId);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }
}

/// Individual notification tile widget.
class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.notification,
    required this.onTap,
    required this.onDismiss,
  });

  final NotificationEntity notification;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.md),
        color: AppColors.error,
        child: const Icon(Icons.delete, color: AppColors.white),
      ),
      onDismissed: (_) => onDismiss(),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.xs),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: notification.isRead
                ? AppColors.surface
                : AppColors.primary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(AppSpacing.sm),
            border: Border.all(
              color: notification.isRead
                  ? AppColors.surface
                  : AppColors.primary.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildIcon(),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: AppTextStyles.titleSmall.copyWith(
                              fontWeight: notification.isRead
                                  ? FontWeight.normal
                                  : FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          notification.timeAgo,
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.message,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (notification.senderName != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'From ${notification.senderName}',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (!notification.isRead) ...[
                const SizedBox(width: AppSpacing.xs),
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon() {
    final iconData = _getIconData();
    final iconColor = _getIconColor();

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.xs),
      ),
      child: Icon(iconData, color: iconColor, size: 20),
    );
  }

  IconData _getIconData() {
    switch (notification.type) {
      case NotificationType.planAssigned:
        return Icons.assignment;
      case NotificationType.workoutCompleted:
        return Icons.check_circle;
      case NotificationType.motivation:
        return Icons.favorite;
      case NotificationType.reminder:
        return Icons.alarm;
      case NotificationType.achievement:
        return Icons.emoji_events;
      case NotificationType.system:
        return Icons.notifications;
    }
  }

  Color _getIconColor() {
    switch (notification.type) {
      case NotificationType.planAssigned:
        return AppColors.info;
      case NotificationType.workoutCompleted:
        return AppColors.success;
      case NotificationType.motivation:
        return AppColors.error;
      case NotificationType.reminder:
        return AppColors.warning;
      case NotificationType.achievement:
        return const Color(0xFFFFD700);
      case NotificationType.system:
        return AppColors.textSecondary;
    }
  }
}
