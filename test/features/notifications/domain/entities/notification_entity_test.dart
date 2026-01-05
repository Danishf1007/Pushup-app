import 'package:flutter_test/flutter_test.dart';
import 'package:pushup_app/features/notifications/domain/entities/notification_entity.dart';

void main() {
  group('NotificationEntity', () {
    group('constructor', () {
      test('should create NotificationEntity with required fields', () {
        final notification = NotificationEntity(
          id: 'notif-123',
          senderId: 'coach-123',
          receiverId: 'athlete-456',
          type: NotificationType.motivation,
          title: 'Great Job!',
          message: 'Keep up the good work!',
          sentAt: DateTime(2024, 6, 15, 10, 30),
        );

        expect(notification.id, 'notif-123');
        expect(notification.senderId, 'coach-123');
        expect(notification.receiverId, 'athlete-456');
        expect(notification.type, NotificationType.motivation);
        expect(notification.title, 'Great Job!');
        expect(notification.message, 'Keep up the good work!');
        expect(notification.sentAt, DateTime(2024, 6, 15, 10, 30));
      });

      test('should create NotificationEntity with optional fields', () {
        final notification = NotificationEntity(
          id: 'notif-123',
          senderId: 'coach-123',
          receiverId: 'athlete-456',
          type: NotificationType.planAssigned,
          title: 'New Plan',
          message: 'You have a new training plan!',
          sentAt: DateTime(2024, 6, 15, 10, 30),
          readAt: DateTime(2024, 6, 15, 11, 0),
          data: {'planId': 'plan-789'},
          senderName: 'Coach Smith',
          senderAvatarUrl: 'https://example.com/avatar.jpg',
        );

        expect(notification.readAt, DateTime(2024, 6, 15, 11, 0));
        expect(notification.data, {'planId': 'plan-789'});
        expect(notification.senderName, 'Coach Smith');
        expect(notification.senderAvatarUrl, 'https://example.com/avatar.jpg');
      });
    });

    group('isRead', () {
      test('should return false when readAt is null', () {
        final notification = NotificationEntity(
          id: 'notif-123',
          senderId: 'coach-123',
          receiverId: 'athlete-456',
          type: NotificationType.motivation,
          title: 'Test',
          message: 'Test message',
          sentAt: DateTime(2024, 6, 15),
        );

        expect(notification.isRead, isFalse);
      });

      test('should return true when readAt is set', () {
        final notification = NotificationEntity(
          id: 'notif-123',
          senderId: 'coach-123',
          receiverId: 'athlete-456',
          type: NotificationType.motivation,
          title: 'Test',
          message: 'Test message',
          sentAt: DateTime(2024, 6, 15),
          readAt: DateTime(2024, 6, 15, 12, 0),
        );

        expect(notification.isRead, isTrue);
      });
    });

    group('NotificationType', () {
      test('should have all expected types', () {
        expect(NotificationType.values.length, 6);
        expect(
          NotificationType.values,
          contains(NotificationType.planAssigned),
        );
        expect(
          NotificationType.values,
          contains(NotificationType.workoutCompleted),
        );
        expect(NotificationType.values, contains(NotificationType.motivation));
        expect(NotificationType.values, contains(NotificationType.reminder));
        expect(NotificationType.values, contains(NotificationType.achievement));
        expect(NotificationType.values, contains(NotificationType.system));
      });
    });

    group('toFirestore', () {
      test('should convert to Firestore map correctly', () {
        final notification = NotificationEntity(
          id: 'notif-123',
          senderId: 'coach-123',
          receiverId: 'athlete-456',
          type: NotificationType.motivation,
          title: 'Great Job!',
          message: 'Keep up the good work!',
          sentAt: DateTime(2024, 6, 15, 10, 30),
          senderName: 'Coach Smith',
        );

        final map = notification.toFirestore();

        expect(map['senderId'], 'coach-123');
        expect(map['receiverId'], 'athlete-456');
        expect(map['type'], 'motivation');
        expect(map['title'], 'Great Job!');
        expect(map['message'], 'Keep up the good work!');
        expect(map['senderName'], 'Coach Smith');
      });

      test('should handle null optional fields', () {
        final notification = NotificationEntity(
          id: 'notif-123',
          senderId: 'system',
          receiverId: 'athlete-456',
          type: NotificationType.system,
          title: 'System Update',
          message: 'New features available!',
          sentAt: DateTime(2024, 6, 15),
        );

        final map = notification.toFirestore();

        expect(map['readAt'], isNull);
        expect(map['data'], isNull);
        expect(map['senderName'], isNull);
        expect(map['senderAvatarUrl'], isNull);
      });
    });

    group('copyWith', () {
      late NotificationEntity original;

      setUp(() {
        original = NotificationEntity(
          id: 'notif-123',
          senderId: 'coach-123',
          receiverId: 'athlete-456',
          type: NotificationType.motivation,
          title: 'Original Title',
          message: 'Original message',
          sentAt: DateTime(2024, 6, 15),
        );
      });

      test('should copy with new readAt', () {
        final readTime = DateTime(2024, 6, 15, 12, 0);
        final copied = original.copyWith(readAt: readTime);

        expect(copied.readAt, readTime);
        expect(copied.isRead, isTrue);
        expect(copied.id, original.id);
        expect(copied.title, original.title);
      });

      test('should copy with new title and message', () {
        final copied = original.copyWith(
          title: 'New Title',
          message: 'New message',
        );

        expect(copied.title, 'New Title');
        expect(copied.message, 'New message');
        expect(copied.type, original.type);
      });
    });

    group('equality', () {
      test('two notifications with same values should be equal', () {
        final sentAt = DateTime(2024, 6, 15, 10, 30);

        final notif1 = NotificationEntity(
          id: 'notif-123',
          senderId: 'coach-123',
          receiverId: 'athlete-456',
          type: NotificationType.motivation,
          title: 'Test',
          message: 'Test message',
          sentAt: sentAt,
        );

        final notif2 = NotificationEntity(
          id: 'notif-123',
          senderId: 'coach-123',
          receiverId: 'athlete-456',
          type: NotificationType.motivation,
          title: 'Test',
          message: 'Test message',
          sentAt: sentAt,
        );

        expect(notif1, equals(notif2));
        expect(notif1.hashCode, equals(notif2.hashCode));
      });

      test('two notifications with different ids should not be equal', () {
        final sentAt = DateTime(2024, 6, 15, 10, 30);

        final notif1 = NotificationEntity(
          id: 'notif-123',
          senderId: 'coach-123',
          receiverId: 'athlete-456',
          type: NotificationType.motivation,
          title: 'Test',
          message: 'Test message',
          sentAt: sentAt,
        );

        final notif2 = NotificationEntity(
          id: 'notif-456',
          senderId: 'coach-123',
          receiverId: 'athlete-456',
          type: NotificationType.motivation,
          title: 'Test',
          message: 'Test message',
          sentAt: sentAt,
        );

        expect(notif1, isNot(equals(notif2)));
      });
    });
  });

  group('NotificationTemplates', () {
    test('should have motivational messages', () {
      expect(NotificationTemplates.motivationalMessages, isNotEmpty);
      expect(NotificationTemplates.motivationalMessages.length, greaterThan(0));
    });

    test('should have reminder messages', () {
      expect(NotificationTemplates.reminderMessages, isNotEmpty);
      expect(NotificationTemplates.reminderMessages.length, greaterThan(0));
    });

    test('motivational messages should be non-empty strings', () {
      for (final message in NotificationTemplates.motivationalMessages) {
        expect(message, isNotEmpty);
        expect(message.length, greaterThan(10));
      }
    });

    test('reminder messages should be non-empty strings', () {
      for (final message in NotificationTemplates.reminderMessages) {
        expect(message, isNotEmpty);
        expect(message.length, greaterThan(10));
      }
    });
  });
}
