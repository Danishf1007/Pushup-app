import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/notification_repository_impl.dart';
import '../../domain/entities/notification_entity.dart';
import '../../domain/repositories/notification_repository.dart';

/// Provider for the notification repository.
final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepositoryImpl();
});

/// Stream provider for all notifications.
final notificationsProvider =
    StreamProvider.family<List<NotificationEntity>, String>((ref, userId) {
      final repository = ref.watch(notificationRepositoryProvider);
      return repository.watchNotifications(userId);
    });

/// Stream provider for unread notification count.
final unreadNotificationCountProvider = StreamProvider.family<int, String>((
  ref,
  userId,
) {
  final repository = ref.watch(notificationRepositoryProvider);
  return repository.watchUnreadCount(userId);
});

/// State for notification operations.
sealed class NotificationOperationState {
  const NotificationOperationState();
}

/// Initial state.
class NotificationOperationInitial extends NotificationOperationState {
  const NotificationOperationInitial();
}

/// Loading state.
class NotificationOperationLoading extends NotificationOperationState {
  const NotificationOperationLoading();
}

/// Success state.
class NotificationOperationSuccess extends NotificationOperationState {
  const NotificationOperationSuccess({this.message});
  final String? message;
}

/// Error state.
class NotificationOperationError extends NotificationOperationState {
  const NotificationOperationError(this.message);
  final String message;
}

/// Notifier for notification operations.
class NotificationNotifier extends StateNotifier<NotificationOperationState> {
  /// Creates the notifier.
  NotificationNotifier(this._repository)
    : super(const NotificationOperationInitial());

  final NotificationRepository _repository;

  /// Sends a notification to a single user.
  Future<bool> sendNotification({
    required String senderId,
    required String receiverId,
    required NotificationType type,
    required String title,
    required String message,
    String? senderName,
    Map<String, dynamic>? data,
  }) async {
    state = const NotificationOperationLoading();
    try {
      await _repository.sendNotification(
        senderId: senderId,
        receiverId: receiverId,
        type: type,
        title: title,
        message: message,
        senderName: senderName,
        data: data,
      );
      state = const NotificationOperationSuccess(message: 'Notification sent!');
      return true;
    } catch (e) {
      state = NotificationOperationError(e.toString());
      return false;
    }
  }

  /// Sends a notification to multiple users.
  Future<bool> sendBulkNotification({
    required String senderId,
    required List<String> receiverIds,
    required NotificationType type,
    required String title,
    required String message,
    String? senderName,
    Map<String, dynamic>? data,
  }) async {
    state = const NotificationOperationLoading();
    try {
      await _repository.sendBulkNotification(
        senderId: senderId,
        receiverIds: receiverIds,
        type: type,
        title: title,
        message: message,
        senderName: senderName,
        data: data,
      );
      state = NotificationOperationSuccess(
        message: 'Notification sent to ${receiverIds.length} athletes!',
      );
      return true;
    } catch (e) {
      state = NotificationOperationError(e.toString());
      return false;
    }
  }

  /// Marks a notification as read.
  Future<void> markAsRead(String notificationId) async {
    try {
      await _repository.markAsRead(notificationId);
    } catch (e) {
      // Silently fail for read status updates
    }
  }

  /// Marks all notifications as read.
  Future<void> markAllAsRead(String userId) async {
    try {
      await _repository.markAllAsRead(userId);
    } catch (e) {
      state = NotificationOperationError(e.toString());
    }
  }

  /// Deletes a notification.
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _repository.deleteNotification(notificationId);
    } catch (e) {
      state = NotificationOperationError(e.toString());
    }
  }

  /// Deletes all notifications.
  Future<void> deleteAllNotifications(String userId) async {
    state = const NotificationOperationLoading();
    try {
      await _repository.deleteAllNotifications(userId);
      state = const NotificationOperationSuccess(
        message: 'All notifications cleared',
      );
    } catch (e) {
      state = NotificationOperationError(e.toString());
    }
  }

  /// Resets the state.
  void reset() {
    state = const NotificationOperationInitial();
  }
}

/// Provider for notification notifier.
final notificationNotifierProvider =
    StateNotifierProvider<NotificationNotifier, NotificationOperationState>((
      ref,
    ) {
      final repository = ref.watch(notificationRepositoryProvider);
      return NotificationNotifier(repository);
    });
