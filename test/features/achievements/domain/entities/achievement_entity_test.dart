import 'package:flutter_test/flutter_test.dart';
import 'package:pushup_app/features/achievements/domain/entities/achievement_entity.dart';

void main() {
  group('AchievementEntity', () {
    group('constructor', () {
      test('should create AchievementEntity with required fields', () {
        const achievement = AchievementEntity(
          id: 'ach-123',
          name: 'First Workout',
          description: 'Complete your first workout',
          type: AchievementType.first,
          tier: AchievementTier.bronze,
          iconName: 'fitness_center',
          requirement: 1,
        );

        expect(achievement.id, 'ach-123');
        expect(achievement.name, 'First Workout');
        expect(achievement.description, 'Complete your first workout');
        expect(achievement.type, AchievementType.first);
        expect(achievement.tier, AchievementTier.bronze);
        expect(achievement.iconName, 'fitness_center');
        expect(achievement.requirement, 1);
      });

      test('should have default progress of 0', () {
        const achievement = AchievementEntity(
          id: 'ach-123',
          name: 'Test',
          description: 'Test',
          type: AchievementType.milestone,
          tier: AchievementTier.bronze,
          iconName: 'star',
          requirement: 10,
        );

        expect(achievement.progress, 0);
      });
    });

    group('isUnlocked', () {
      test('should return false when unlockedAt is null', () {
        const achievement = AchievementEntity(
          id: 'ach-123',
          name: 'Test',
          description: 'Test',
          type: AchievementType.milestone,
          tier: AchievementTier.bronze,
          iconName: 'star',
          requirement: 10,
        );

        expect(achievement.isUnlocked, isFalse);
      });

      test('should return true when unlockedAt is set', () {
        final achievement = AchievementEntity(
          id: 'ach-123',
          name: 'Test',
          description: 'Test',
          type: AchievementType.milestone,
          tier: AchievementTier.bronze,
          iconName: 'star',
          requirement: 10,
          unlockedAt: DateTime(2024, 6, 15),
        );

        expect(achievement.isUnlocked, isTrue);
      });
    });

    group('progressPercent', () {
      test('should return 0 when progress is 0', () {
        const achievement = AchievementEntity(
          id: 'ach-123',
          name: 'Test',
          description: 'Test',
          type: AchievementType.streak,
          tier: AchievementTier.silver,
          iconName: 'star',
          requirement: 7,
          progress: 0,
        );

        expect(achievement.progressPercent, 0);
      });

      test('should return 50 when progress is half', () {
        const achievement = AchievementEntity(
          id: 'ach-123',
          name: 'Test',
          description: 'Test',
          type: AchievementType.streak,
          tier: AchievementTier.silver,
          iconName: 'star',
          requirement: 10,
          progress: 5,
        );

        expect(achievement.progressPercent, 50);
      });

      test('should return 100 when progress equals requirement', () {
        const achievement = AchievementEntity(
          id: 'ach-123',
          name: 'Test',
          description: 'Test',
          type: AchievementType.streak,
          tier: AchievementTier.silver,
          iconName: 'star',
          requirement: 7,
          progress: 7,
        );

        expect(achievement.progressPercent, 100);
      });

      test('should clamp at 100 when progress exceeds requirement', () {
        const achievement = AchievementEntity(
          id: 'ach-123',
          name: 'Test',
          description: 'Test',
          type: AchievementType.streak,
          tier: AchievementTier.silver,
          iconName: 'star',
          requirement: 7,
          progress: 10,
        );

        expect(achievement.progressPercent, 100);
      });

      test('should return 0 when requirement is 0', () {
        const achievement = AchievementEntity(
          id: 'ach-123',
          name: 'Test',
          description: 'Test',
          type: AchievementType.first,
          tier: AchievementTier.bronze,
          iconName: 'star',
          requirement: 0,
          progress: 5,
        );

        expect(achievement.progressPercent, 0);
      });
    });

    group('AchievementType', () {
      test('should have all expected types', () {
        expect(AchievementType.values.length, 6);
        expect(AchievementType.values, contains(AchievementType.streak));
        expect(AchievementType.values, contains(AchievementType.milestone));
        expect(AchievementType.values, contains(AchievementType.duration));
        expect(AchievementType.values, contains(AchievementType.first));
        expect(AchievementType.values, contains(AchievementType.challenge));
        expect(AchievementType.values, contains(AchievementType.perfectWeek));
      });
    });

    group('AchievementTier', () {
      test('should have all expected tiers', () {
        expect(AchievementTier.values.length, 4);
        expect(AchievementTier.values, contains(AchievementTier.bronze));
        expect(AchievementTier.values, contains(AchievementTier.silver));
        expect(AchievementTier.values, contains(AchievementTier.gold));
        expect(AchievementTier.values, contains(AchievementTier.platinum));
      });
    });

    group('copyWith', () {
      late AchievementEntity original;

      setUp(() {
        original = const AchievementEntity(
          id: 'ach-123',
          name: 'Original',
          description: 'Original desc',
          type: AchievementType.milestone,
          tier: AchievementTier.bronze,
          iconName: 'star',
          requirement: 10,
          progress: 5,
        );
      });

      test('should copy with new progress', () {
        final copied = original.copyWith(progress: 8);

        expect(copied.progress, 8);
        expect(copied.id, original.id);
        expect(copied.name, original.name);
      });

      test('should copy with unlockedAt', () {
        final unlockDate = DateTime(2024, 6, 15);
        final copied = original.copyWith(unlockedAt: unlockDate);

        expect(copied.unlockedAt, unlockDate);
        expect(copied.isUnlocked, isTrue);
      });

      test('should copy with new tier', () {
        final copied = original.copyWith(tier: AchievementTier.gold);

        expect(copied.tier, AchievementTier.gold);
      });
    });

    group('toFirestore', () {
      test('should convert to Firestore map', () {
        final achievement = AchievementEntity(
          id: 'ach-123',
          name: 'Test Achievement',
          description: 'Test description',
          type: AchievementType.streak,
          tier: AchievementTier.gold,
          iconName: 'streak',
          requirement: 7,
          progress: 3,
          unlockedAt: DateTime(2024, 6, 15),
        );

        final map = achievement.toFirestore();

        expect(map['name'], 'Test Achievement');
        expect(map['description'], 'Test description');
        expect(map['type'], 'streak');
        expect(map['tier'], 'gold');
        expect(map['iconName'], 'streak');
        expect(map['requirement'], 7);
        expect(map['progress'], 3);
        expect(map['unlockedAt'], isNotNull);
      });

      test('should handle null unlockedAt', () {
        const achievement = AchievementEntity(
          id: 'ach-123',
          name: 'Test',
          description: 'Test',
          type: AchievementType.milestone,
          tier: AchievementTier.bronze,
          iconName: 'star',
          requirement: 10,
        );

        final map = achievement.toFirestore();

        expect(map['unlockedAt'], isNull);
      });
    });
  });
}
