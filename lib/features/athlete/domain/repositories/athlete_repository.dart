import '../../../plans/domain/entities/entities.dart';
import '../entities/entities.dart';

/// Repository interface for athlete workout operations.
///
/// Handles activity logging, progress tracking, and stats.
abstract class AthleteRepository {
  // ============== Activity Logs ==============

  /// Logs a completed activity.
  Future<ActivityLogEntity> logActivity(ActivityLogEntity log);

  /// Gets all activity logs for an athlete.
  Future<List<ActivityLogEntity>> getActivityLogs(String athleteId);

  /// Gets activity logs for a specific date range.
  Future<List<ActivityLogEntity>> getActivityLogsInRange({
    required String athleteId,
    required DateTime startDate,
    required DateTime endDate,
  });

  /// Gets activity logs for a specific assignment.
  Future<List<ActivityLogEntity>> getLogsForAssignment(String assignmentId);

  /// Stream of activity logs for real-time updates.
  Stream<List<ActivityLogEntity>> watchActivityLogs(String athleteId);

  /// Deletes an activity log.
  Future<void> deleteActivityLog(String logId);

  // ============== Stats ==============

  /// Gets athlete statistics.
  Future<AthleteStatsEntity> getAthleteStats(String athleteId);

  /// Stream of athlete stats for real-time updates.
  Stream<AthleteStatsEntity> watchAthleteStats(String athleteId);

  /// Updates athlete stats after logging activity.
  Future<void> updateStatsAfterActivity({
    required String athleteId,
    required int duration,
  });

  // ============== Assigned Plans ==============

  /// Gets active plan assignment for athlete.
  Future<PlanAssignmentEntity?> getActiveAssignment(String athleteId);

  /// Gets all plan assignments for athlete.
  Future<List<PlanAssignmentEntity>> getAssignments(String athleteId);

  /// Stream of plan assignments.
  Stream<List<PlanAssignmentEntity>> watchAssignments(String athleteId);

  /// Gets today's activities from active assignment.
  Future<List<ActivityEntity>> getTodaysActivities(String athleteId);

  /// Gets upcoming activities from active assignment.
  Future<List<ActivityEntity>> getUpcomingActivities(String athleteId);

  /// Checks if an activity is completed for today.
  Future<bool> isActivityCompletedToday({
    required String athleteId,
    required String activityId,
  });

  /// Gets all activities for an assignment.
  Future<List<ActivityEntity>> getActivitiesForAssignment(String assignmentId);

  // ============== Chart Data ==============

  /// Gets workout counts for each day of the current week (Mon-Sun).
  Future<List<int>> getWeeklyWorkoutCounts(String athleteId);

  /// Gets monthly workout data (past 4 weeks).
  Future<List<({int week, int workouts, int duration})>> getMonthlyWorkoutData(
    String athleteId,
  );

  /// Gets workout type distribution for the athlete.
  Future<Map<String, int>> getWorkoutTypeDistribution(String athleteId);
}
