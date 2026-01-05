import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Types of notifications in the app.
enum NotificationType {
  /// A new training plan was assigned.
  planAssigned,

  /// An athlete completed a workout.
  workoutCompleted,

  /// Motivational message from coach.
  motivation,

  /// Workout reminder.
  reminder,

  /// Achievement unlocked.
  achievement,

  /// General system notification.
  system,
}

/// A notification entity representing an in-app notification.
class NotificationEntity extends Equatable {
  /// Creates a notification entity.
  const NotificationEntity({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.type,
    required this.title,
    required this.message,
    required this.sentAt,
    this.readAt,
    this.data,
    this.senderName,
    this.senderAvatarUrl,
  });

  /// Creates from Firestore document.
  factory NotificationEntity.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationEntity(
      id: doc.id,
      senderId: data['senderId'] as String? ?? '',
      receiverId: data['receiverId'] as String? ?? '',
      type: NotificationType.values.firstWhere(
        (t) => t.name == data['type'],
        orElse: () => NotificationType.system,
      ),
      title: data['title'] as String? ?? '',
      message: data['message'] as String? ?? '',
      sentAt: (data['sentAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      readAt: (data['readAt'] as Timestamp?)?.toDate(),
      data: data['data'] as Map<String, dynamic>?,
      senderName: data['senderName'] as String?,
      senderAvatarUrl: data['senderAvatarUrl'] as String?,
    );
  }

  /// Unique identifier.
  final String id;

  /// ID of the user who sent the notification.
  final String senderId;

  /// ID of the user who receives the notification.
  final String receiverId;

  /// Type of notification.
  final NotificationType type;

  /// Notification title.
  final String title;

  /// Notification message body.
  final String message;

  /// When the notification was sent.
  final DateTime sentAt;

  /// When the notification was read (null if unread).
  final DateTime? readAt;

  /// Additional data payload.
  final Map<String, dynamic>? data;

  /// Display name of the sender.
  final String? senderName;

  /// Avatar URL of the sender.
  final String? senderAvatarUrl;

  /// Whether this notification has been read.
  bool get isRead => readAt != null;

  /// Converts to Firestore map.
  Map<String, dynamic> toFirestore() => {
    'senderId': senderId,
    'receiverId': receiverId,
    'type': type.name,
    'title': title,
    'message': message,
    'sentAt': Timestamp.fromDate(sentAt),
    'readAt': readAt != null ? Timestamp.fromDate(readAt!) : null,
    'data': data,
    'senderName': senderName,
    'senderAvatarUrl': senderAvatarUrl,
  };

  /// Creates a copy with updated fields.
  NotificationEntity copyWith({
    String? id,
    String? senderId,
    String? receiverId,
    NotificationType? type,
    String? title,
    String? message,
    DateTime? sentAt,
    DateTime? readAt,
    Map<String, dynamic>? data,
    String? senderName,
    String? senderAvatarUrl,
  }) {
    return NotificationEntity(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      sentAt: sentAt ?? this.sentAt,
      readAt: readAt ?? this.readAt,
      data: data ?? this.data,
      senderName: senderName ?? this.senderName,
      senderAvatarUrl: senderAvatarUrl ?? this.senderAvatarUrl,
    );
  }

  /// Gets the icon for this notification type.
  String get iconName {
    switch (type) {
      case NotificationType.planAssigned:
        return 'assignment';
      case NotificationType.workoutCompleted:
        return 'check_circle';
      case NotificationType.motivation:
        return 'favorite';
      case NotificationType.reminder:
        return 'alarm';
      case NotificationType.achievement:
        return 'emoji_events';
      case NotificationType.system:
        return 'notifications';
    }
  }

  /// Gets a human-readable time ago string.
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(sentAt);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${sentAt.day}/${sentAt.month}/${sentAt.year}';
    }
  }

  @override
  List<Object?> get props => [
    id,
    senderId,
    receiverId,
    type,
    title,
    message,
    sentAt,
    readAt,
    data,
  ];
}

/// Predefined notification templates for coaches.
class NotificationTemplates {
  /// Motivational message templates.
  static const List<String> motivationalMessages = [
    "You're doing amazing! Keep up the great work! 💪",
    "Every workout counts. Stay consistent and you'll see results!",
    "Remember why you started. You've got this!",
    "Your dedication is inspiring. Keep pushing forward!",
    "Small progress is still progress. Be proud of yourself!",
    "Today's effort is tomorrow's strength. Let's go!",
    "You're stronger than you think. Believe in yourself!",
    "Consistency beats perfection. Show up today!",
  ];

  /// Reminder templates.
  static const List<String> reminderMessages = [
    "Don't forget your workout today! Your goals are waiting.",
    "It's been a while since your last workout. Time to get moving!",
    "Your training plan misses you. Ready to jump back in?",
    "A quick workout is better than no workout. Let's do this!",
  ];
}
