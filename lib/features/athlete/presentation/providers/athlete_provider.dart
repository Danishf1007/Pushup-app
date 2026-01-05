import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../achievements/domain/entities/achievement_entity.dart';
import '../../../achievements/domain/repositories/achievement_repository.dart';
import '../../../achievements/presentation/providers/achievement_provider.dart';
import '../../../plans/domain/entities/entities.dart';
import '../../data/repositories/athlete_repository_impl.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/athlete_repository.dart';

/// Provider for the athlete repository.
final athleteRepositoryProvider = Provider<AthleteRepository>((ref) {
  return AthleteRepositoryImpl();
});

/// Stream provider for athlete stats.
final athleteStatsStreamProvider =
    StreamProvider.family<AthleteStatsEntity, String>((ref, athleteId) {
      final repository = ref.watch(athleteRepositoryProvider);
      return repository.watchAthleteStats(athleteId);
    });

/// Future provider for athlete stats.
final athleteStatsProvider = FutureProvider.family<AthleteStatsEntity, String>((
  ref,
  athleteId,
) async {
  final repository = ref.watch(athleteRepositoryProvider);
  return repository.getAthleteStats(athleteId);
});

/// Stream provider for activity logs.
final activityLogsStreamProvider =
    StreamProvider.family<List<ActivityLogEntity>, String>((ref, athleteId) {
      final repository = ref.watch(athleteRepositoryProvider);
      return repository.watchActivityLogs(athleteId);
    });

/// Stream provider for athlete's plan assignments.
final athletePlanAssignmentsProvider =
    StreamProvider.family<List<PlanAssignmentEntity>, String>((ref, athleteId) {
      final repository = ref.watch(athleteRepositoryProvider);
      return repository.watchAssignments(athleteId);
    });

/// Future provider for active assignment.
final activeAssignmentProvider =
    FutureProvider.family<PlanAssignmentEntity?, String>((
      ref,
      athleteId,
    ) async {
      final repository = ref.watch(athleteRepositoryProvider);
      return repository.getActiveAssignment(athleteId);
    });

/// Future provider for today's activities.
final todaysActivitiesProvider =
    FutureProvider.family<List<ActivityEntity>, String>((ref, athleteId) async {
      final repository = ref.watch(athleteRepositoryProvider);
      return repository.getTodaysActivities(athleteId);
    });

/// Future provider for upcoming activities.
final upcomingActivitiesProvider =
    FutureProvider.family<List<ActivityEntity>, String>((ref, athleteId) async {
      final repository = ref.watch(athleteRepositoryProvider);
      return repository.getUpcomingActivities(athleteId);
    });

/// State for activity logging operations.
sealed class ActivityLogState {
  const ActivityLogState();
}

class ActivityLogInitial extends ActivityLogState {
  const ActivityLogInitial();
}

class ActivityLogLoading extends ActivityLogState {
  const ActivityLogLoading();
}

class ActivityLogSuccess extends ActivityLogState {
  const ActivityLogSuccess({this.message, this.log, this.unlockedAchievements});
  final String? message;
  final ActivityLogEntity? log;
  final List<AchievementEntity>? unlockedAchievements;
}

class ActivityLogError extends ActivityLogState {
  const ActivityLogError(this.message);
  final String message;
}

/// Notifier for logging activities.
class ActivityLogNotifier extends StateNotifier<ActivityLogState> {
  ActivityLogNotifier(this._repository, this._achievementRepository)
    : super(const ActivityLogInitial());

  final AthleteRepository _repository;
  final AchievementRepository _achievementRepository;

  /// Logs a new activity from an entity.
  Future<bool> logActivity(ActivityLogEntity log) async {
    state = const ActivityLogLoading();

    try {
      final created = await _repository.logActivity(log);

      // Check for newly unlocked achievements
      List<AchievementEntity> unlockedAchievements = [];
      try {
        unlockedAchievements = await _achievementRepository
            .checkAndUpdateAchievements(log.athleteId);
      } catch (_) {
        // Achievement checking is not critical
      }

      state = ActivityLogSuccess(
        message: 'Activity logged successfully!',
        log: created,
        unlockedAchievements: unlockedAchievements.isNotEmpty
            ? unlockedAchievements
            : null,
      );
      return true;
    } catch (e) {
      state = ActivityLogError(e.toString());
      return false;
    }
  }

  /// Deletes an activity log.
  Future<bool> deleteLog(String logId) async {
    state = const ActivityLogLoading();

    try {
      await _repository.deleteActivityLog(logId);
      state = const ActivityLogSuccess(message: 'Activity deleted');
      return true;
    } catch (e) {
      state = ActivityLogError(e.toString());
      return false;
    }
  }

  /// Resets state to initial.
  void reset() {
    state = const ActivityLogInitial();
  }
}

/// Provider for activity log notifier.
final activityLogNotifierProvider =
    StateNotifierProvider<ActivityLogNotifier, ActivityLogState>((ref) {
      final repository = ref.watch(athleteRepositoryProvider);
      final achievementRepository = ref.watch(achievementRepositoryProvider);
      return ActivityLogNotifier(repository, achievementRepository);
    });

/// Provider to check if an activity is completed today.
final isActivityCompletedTodayProvider =
    FutureProvider.family<bool, ({String athleteId, String activityId})>((
      ref,
      params,
    ) async {
      final repository = ref.watch(athleteRepositoryProvider);
      return repository.isActivityCompletedToday(
        athleteId: params.athleteId,
        activityId: params.activityId,
      );
    });

/// Future provider for activities in an assignment.
final assignmentActivitiesProvider =
    FutureProvider.family<List<ActivityEntity>, String>((
      ref,
      assignmentId,
    ) async {
      final repository = ref.watch(athleteRepositoryProvider);
      return repository.getActivitiesForAssignment(assignmentId);
    });

/// Weekly workout data for chart (Mon-Sun counts).
final weeklyChartDataProvider = FutureProvider.family<List<int>, String>((
  ref,
  athleteId,
) async {
  final repository = ref.watch(athleteRepositoryProvider);
  return repository.getWeeklyWorkoutCounts(athleteId);
});

/// Monthly workout data for chart (past 4 weeks).
final monthlyChartDataProvider =
    FutureProvider.family<
      List<({int week, int workouts, int duration})>,
      String
    >((ref, athleteId) async {
      final repository = ref.watch(athleteRepositoryProvider);
      return repository.getMonthlyWorkoutData(athleteId);
    });

/// Workout type distribution data.
final workoutTypeDistributionProvider =
    FutureProvider.family<Map<String, int>, String>((ref, athleteId) async {
      final repository = ref.watch(athleteRepositoryProvider);
      return repository.getWorkoutTypeDistribution(athleteId);
    });
