import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/achievement_repository_impl.dart';
import '../../domain/entities/achievement_entity.dart';
import '../../domain/repositories/achievement_repository.dart';

/// Provider for the achievement repository.
final achievementRepositoryProvider = Provider<AchievementRepository>((ref) {
  return AchievementRepositoryImpl();
});

/// Provider for all achievements with progress.
final achievementsProvider =
    FutureProvider.family<List<AchievementEntity>, String>((ref, athleteId) {
      final repository = ref.watch(achievementRepositoryProvider);
      return repository.getAchievements(athleteId);
    });

/// Provider for unlocked achievements only.
final unlockedAchievementsProvider =
    FutureProvider.family<List<AchievementEntity>, String>((ref, athleteId) {
      final repository = ref.watch(achievementRepositoryProvider);
      return repository.getUnlockedAchievements(athleteId);
    });

/// Provider for newly unlocked achievements (for notifications).
final newlyUnlockedProvider =
    FutureProvider.family<List<AchievementEntity>, String>((ref, athleteId) {
      final repository = ref.watch(achievementRepositoryProvider);
      return repository.getNewlyUnlocked(athleteId);
    });

/// Provider for achievement counts.
final achievementCountsProvider =
    FutureProvider.family<AchievementCounts, String>((ref, athleteId) async {
      final achievements = await ref.watch(
        achievementsProvider(athleteId).future,
      );

      final unlocked = achievements.where((a) => a.isUnlocked).length;
      final total = achievements.length;

      return AchievementCounts(
        unlocked: unlocked,
        total: total,
        percentage: total > 0 ? unlocked / total * 100 : 0,
      );
    });

/// Achievement counts data class.
class AchievementCounts {
  /// Creates achievement counts.
  const AchievementCounts({
    required this.unlocked,
    required this.total,
    required this.percentage,
  });

  /// Number of unlocked achievements.
  final int unlocked;

  /// Total number of achievements.
  final int total;

  /// Percentage unlocked.
  final double percentage;
}

/// Notifier for checking and updating achievements.
class AchievementCheckerNotifier
    extends StateNotifier<AsyncValue<List<AchievementEntity>>> {
  /// Creates the notifier.
  AchievementCheckerNotifier(this._repository)
    : super(const AsyncValue.loading());

  final AchievementRepository _repository;

  /// Checks achievements and returns newly unlocked ones.
  Future<List<AchievementEntity>> checkAchievements(String athleteId) async {
    state = const AsyncValue.loading();
    try {
      final newlyUnlocked = await _repository.checkAndUpdateAchievements(
        athleteId,
      );
      state = AsyncValue.data(newlyUnlocked);
      return newlyUnlocked;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return [];
    }
  }

  /// Marks achievements as seen.
  Future<void> markSeen(String athleteId, List<String> achievementIds) async {
    await _repository.markAchievementsSeen(athleteId, achievementIds);
  }
}

/// Provider for achievement checker notifier.
final achievementCheckerProvider =
    StateNotifierProvider<
      AchievementCheckerNotifier,
      AsyncValue<List<AchievementEntity>>
    >((ref) {
      final repository = ref.watch(achievementRepositoryProvider);
      return AchievementCheckerNotifier(repository);
    });
