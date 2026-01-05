import '../entities/achievement_entity.dart';

/// Repository for achievement operations.
abstract class AchievementRepository {
  /// Gets all achievements for an athlete with their progress.
  Future<List<AchievementEntity>> getAchievements(String athleteId);

  /// Gets unlocked achievements for an athlete.
  Future<List<AchievementEntity>> getUnlockedAchievements(String athleteId);

  /// Checks and updates achievements based on current stats.
  Future<List<AchievementEntity>> checkAndUpdateAchievements(String athleteId);

  /// Unlocks a specific achievement for an athlete.
  Future<void> unlockAchievement(String athleteId, String achievementId);

  /// Gets newly unlocked achievements (for showing notifications).
  Future<List<AchievementEntity>> getNewlyUnlocked(String athleteId);

  /// Marks newly unlocked achievements as seen.
  Future<void> markAchievementsSeen(
    String athleteId,
    List<String> achievementIds,
  );

  /// Initializes achievements for a new athlete.
  Future<void> initializeAchievements(String athleteId);
}
