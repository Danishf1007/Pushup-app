import 'package:flutter_test/flutter_test.dart';
import 'package:pushup_app/core/constants/app_constants.dart';
import 'package:pushup_app/features/auth/domain/entities/user_entity.dart';

void main() {
  group('UserEntity', () {
    group('constructor', () {
      test('should create UserEntity with required fields', () {
        final user = UserEntity(
          id: 'user-123',
          email: 'test@example.com',
          displayName: 'Test User',
          role: UserRole.athlete,
          createdAt: DateTime(2024, 1, 1),
        );

        expect(user.id, 'user-123');
        expect(user.email, 'test@example.com');
        expect(user.displayName, 'Test User');
        expect(user.role, UserRole.athlete);
        expect(user.createdAt, DateTime(2024, 1, 1));
      });

      test('should create UserEntity with optional fields', () {
        final user = UserEntity(
          id: 'user-123',
          email: 'test@example.com',
          displayName: 'Test User',
          role: UserRole.athlete,
          createdAt: DateTime(2024, 1, 1),
          profilePicture: 'https://example.com/avatar.jpg',
          coachId: 'coach-456',
          lastActive: DateTime(2024, 6, 15),
          fcmToken: 'fcm-token-123',
        );

        expect(user.profilePicture, 'https://example.com/avatar.jpg');
        expect(user.coachId, 'coach-456');
        expect(user.lastActive, DateTime(2024, 6, 15));
        expect(user.fcmToken, 'fcm-token-123');
      });
    });

    group('role checks', () {
      test('isCoach returns true for coach role', () {
        final coach = UserEntity(
          id: 'coach-123',
          email: 'coach@example.com',
          displayName: 'Coach Smith',
          role: UserRole.coach,
          createdAt: DateTime(2024, 1, 1),
        );

        expect(coach.isCoach, isTrue);
        expect(coach.isAthlete, isFalse);
      });

      test('isAthlete returns true for athlete role', () {
        final athlete = UserEntity(
          id: 'athlete-123',
          email: 'athlete@example.com',
          displayName: 'John Doe',
          role: UserRole.athlete,
          createdAt: DateTime(2024, 1, 1),
        );

        expect(athlete.isAthlete, isTrue);
        expect(athlete.isCoach, isFalse);
      });
    });

    group('copyWith', () {
      late UserEntity original;

      setUp(() {
        original = UserEntity(
          id: 'user-123',
          email: 'original@example.com',
          displayName: 'Original User',
          role: UserRole.athlete,
          createdAt: DateTime(2024, 1, 1),
        );
      });

      test('should copy with new email', () {
        final copied = original.copyWith(email: 'new@example.com');

        expect(copied.email, 'new@example.com');
        expect(copied.id, original.id);
        expect(copied.displayName, original.displayName);
        expect(copied.role, original.role);
      });

      test('should copy with new role', () {
        final copied = original.copyWith(role: UserRole.coach);

        expect(copied.role, UserRole.coach);
        expect(copied.isCoach, isTrue);
      });

      test('should copy with all fields unchanged if no params', () {
        final copied = original.copyWith();

        expect(copied, equals(original));
      });

      test('should copy with multiple fields', () {
        final copied = original.copyWith(
          displayName: 'Updated User',
          fcmToken: 'new-token',
        );

        expect(copied.displayName, 'Updated User');
        expect(copied.fcmToken, 'new-token');
        expect(copied.email, original.email);
      });
    });

    group('equality', () {
      test('two UserEntities with same values should be equal', () {
        final user1 = UserEntity(
          id: 'user-123',
          email: 'test@example.com',
          displayName: 'Test User',
          role: UserRole.athlete,
          createdAt: DateTime(2024, 1, 1),
        );

        final user2 = UserEntity(
          id: 'user-123',
          email: 'test@example.com',
          displayName: 'Test User',
          role: UserRole.athlete,
          createdAt: DateTime(2024, 1, 1),
        );

        expect(user1, equals(user2));
        expect(user1.hashCode, equals(user2.hashCode));
      });

      test('two UserEntities with different ids should not be equal', () {
        final user1 = UserEntity(
          id: 'user-123',
          email: 'test@example.com',
          displayName: 'Test User',
          role: UserRole.athlete,
          createdAt: DateTime(2024, 1, 1),
        );

        final user2 = UserEntity(
          id: 'user-456',
          email: 'test@example.com',
          displayName: 'Test User',
          role: UserRole.athlete,
          createdAt: DateTime(2024, 1, 1),
        );

        expect(user1, isNot(equals(user2)));
      });
    });
  });
}
