import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/achievement_entity.dart';
import '../../domain/repositories/achievement_repository.dart';

/// Firestore implementation of [AchievementRepository].
class AchievementRepositoryImpl implements AchievementRepository {
  /// Creates the repository with optional Firestore instance.
  AchievementRepositoryImpl({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _athleteAchievements(
    String athleteId,
  ) => _firestore
      .collection('athletes')
      .doc(athleteId)
      .collection('achievements');

  @override
  Future<List<AchievementEntity>> getAchievements(String athleteId) async {
    // First get the athlete's achievement progress
    final progressSnapshot = await _athleteAchievements(athleteId).get();
    final progressMap = <String, Map<String, dynamic>>{};

    for (final doc in progressSnapshot.docs) {
      progressMap[doc.id] = doc.data();
    }

    // Map predefined achievements with progress
    return PredefinedAchievements.all.map((achievement) {
      final id = achievement['id'] as String;
      final progress = progressMap[id];

      return AchievementEntity(
        id: id,
        name: achievement['name'] as String,
        description: achievement['description'] as String,
        type: AchievementType.values.firstWhere(
          (t) => t.name == achievement['type'],
          orElse: () => AchievementType.milestone,
        ),
        tier: AchievementTier.values.firstWhere(
          (t) => t.name == achievement['tier'],
          orElse: () => AchievementTier.bronze,
        ),
        iconName: achievement['iconName'] as String,
        requirement: achievement['requirement'] as int,
        progress: progress?['progress'] as int? ?? 0,
        unlockedAt: (progress?['unlockedAt'] as Timestamp?)?.toDate(),
      );
    }).toList();
  }

  @override
  Future<List<AchievementEntity>> getUnlockedAchievements(
    String athleteId,
  ) async {
    final all = await getAchievements(athleteId);
    return all.where((a) => a.isUnlocked).toList();
  }

  @override
  Future<List<AchievementEntity>> checkAndUpdateAchievements(
    String athleteId,
  ) async {
    // Get athlete stats
    final statsDoc = await _firestore
        .collection('athlete_stats')
        .doc(athleteId)
        .get();

    if (!statsDoc.exists) return [];

    final stats = statsDoc.data()!;
    final totalWorkouts = stats['totalWorkouts'] as int? ?? 0;
    final streak =
        stats['currentStreak'] as int? ?? stats['streak'] as int? ?? 0;
    final totalDuration = stats['totalDuration'] as int? ?? 0;
    final perfectWeeks = stats['perfectWeeks'] as int? ?? 0;

    // Get current achievements
    final achievements = await getAchievements(athleteId);
    final newlyUnlocked = <AchievementEntity>[];

    for (final achievement in achievements) {
      if (achievement.isUnlocked) continue; // Already unlocked

      int currentProgress = 0;
      bool shouldUnlock = false;

      switch (achievement.type) {
        case AchievementType.streak:
          currentProgress = streak;
          shouldUnlock = streak >= achievement.requirement;
          break;
        case AchievementType.milestone:
          currentProgress = totalWorkouts;
          shouldUnlock = totalWorkouts >= achievement.requirement;
          break;
        case AchievementType.duration:
          currentProgress = totalDuration;
          shouldUnlock = totalDuration >= achievement.requirement;
          break;
        case AchievementType.first:
          currentProgress = totalWorkouts >= 1 ? 1 : 0;
          shouldUnlock = totalWorkouts >= achievement.requirement;
          break;
        case AchievementType.perfectWeek:
          currentProgress = perfectWeeks;
          shouldUnlock = perfectWeeks >= achievement.requirement;
          break;
        case AchievementType.challenge:
          // Challenges handled separately
          continue;
      }

      // Update progress
      await _athleteAchievements(athleteId).doc(achievement.id).set({
        'progress': currentProgress,
        if (shouldUnlock) 'unlockedAt': FieldValue.serverTimestamp(),
        if (shouldUnlock) 'seen': false,
      }, SetOptions(merge: true));

      if (shouldUnlock) {
        newlyUnlocked.add(
          achievement.copyWith(
            progress: currentProgress,
            unlockedAt: DateTime.now(),
          ),
        );
      }
    }

    return newlyUnlocked;
  }

  @override
  Future<void> unlockAchievement(String athleteId, String achievementId) async {
    await _athleteAchievements(athleteId).doc(achievementId).set({
      'unlockedAt': FieldValue.serverTimestamp(),
      'seen': false,
    }, SetOptions(merge: true));
  }

  @override
  Future<List<AchievementEntity>> getNewlyUnlocked(String athleteId) async {
    // Query without composite index requirement
    final snapshot = await _athleteAchievements(athleteId).get();

    if (snapshot.docs.isEmpty) return [];

    // Filter in memory to avoid composite index
    final unseenUnlocked = snapshot.docs.where((doc) {
      final data = doc.data();
      return data['seen'] == false && data['unlockedAt'] != null;
    }).toList();

    if (unseenUnlocked.isEmpty) return [];

    final achievements = await getAchievements(athleteId);
    final unlockedIds = unseenUnlocked.map((d) => d.id).toSet();

    return achievements.where((a) => unlockedIds.contains(a.id)).toList();
  }

  @override
  Future<void> markAchievementsSeen(
    String athleteId,
    List<String> achievementIds,
  ) async {
    final batch = _firestore.batch();

    for (final id in achievementIds) {
      batch.update(_athleteAchievements(athleteId).doc(id), {'seen': true});
    }

    await batch.commit();
  }

  @override
  Future<void> initializeAchievements(String athleteId) async {
    // Create initial progress entries for all achievements
    final batch = _firestore.batch();

    for (final achievement in PredefinedAchievements.all) {
      final docRef = _athleteAchievements(
        athleteId,
      ).doc(achievement['id'] as String);
      batch.set(docRef, {
        'progress': 0,
        'unlockedAt': null,
        'seen': true,
      }, SetOptions(merge: true));
    }

    await batch.commit();
  }
}
