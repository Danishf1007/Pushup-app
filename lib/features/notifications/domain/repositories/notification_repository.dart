import '../entities/notification_entity.dart';

/// Repository for notification operations.
abstract class NotificationRepository {
  /// Gets all notifications for a user.
  Stream<List<NotificationEntity>> watchNotifications(String userId);

  /// Gets unread notification count.
  Stream<int> watchUnreadCount(String userId);

  /// Sends a notification to a user.
  Future<void> sendNotification({
    required String senderId,
    required String receiverId,
    required NotificationType type,
    required String title,
    required String message,
    String? senderName,
    Map<String, dynamic>? data,
  });

  /// Sends a notification to multiple users.
  Future<void> sendBulkNotification({
    required String senderId,
    required List<String> receiverIds,
    required NotificationType type,
    required String title,
    required String message,
    String? senderName,
    Map<String, dynamic>? data,
  });

  /// Marks a notification as read.
  Future<void> markAsRead(String notificationId);

  /// Marks all notifications as read for a user.
  Future<void> markAllAsRead(String userId);

  /// Deletes a notification.
  Future<void> deleteNotification(String notificationId);

  /// Deletes all notifications for a user.
  Future<void> deleteAllNotifications(String userId);

  /// Gets recent notifications (limited).
  Future<List<NotificationEntity>> getRecentNotifications(
    String userId, {
    int limit = 20,
  });
}
