import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../providers/notification_provider.dart';

/// A notification bell icon with an unread count badge.
class NotificationBadge extends ConsumerWidget {
  /// Creates a notification badge.
  const NotificationBadge({
    super.key,
    required this.userId,
    required this.onTap,
    this.iconColor,
    this.badgeColor,
  });

  /// The user ID to check notifications for.
  final String userId;

  /// Callback when the badge is tapped.
  final VoidCallback onTap;

  /// Optional icon color.
  final Color? iconColor;

  /// Optional badge background color.
  final Color? badgeColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCountAsync = ref.watch(unreadNotificationCountProvider(userId));

    return IconButton(
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(Icons.notifications_outlined, color: iconColor),
          unreadCountAsync.when(
            data: (count) {
              if (count == 0) return const SizedBox.shrink();
              return Positioned(
                right: -6,
                top: -6,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: badgeColor ?? AppColors.error,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    count > 99 ? '99+' : '$count',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      onPressed: onTap,
    );
  }
}
