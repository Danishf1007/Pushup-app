import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';

import '../../../../core/utils/logger.dart';
import '../../../plans/data/models/models.dart';
import '../../../plans/domain/entities/entities.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/athlete_repository.dart';
import '../models/models.dart';

/// Firebase implementation of [AthleteRepository].
class AthleteRepositoryImpl implements AthleteRepository {
  /// Creates a new [AthleteRepositoryImpl].
  AthleteRepositoryImpl({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _activityLogsRef =>
      _firestore.collection('activity_logs');

  CollectionReference<Map<String, dynamic>> get _statsRef =>
      _firestore.collection('athlete_stats');

  CollectionReference<Map<String, dynamic>> get _assignmentsRef =>
      _firestore.collection('plan_assignments');

  CollectionReference<Map<String, dynamic>> get _plansRef =>
      _firestore.collection('trainingPlans');

  // ============== Activity Logs ==============

  @override
  Future<ActivityLogEntity> logActivity(ActivityLogEntity log) async {
    try {
      AppLogger.info('Logging activity for athlete: ${log.athleteId}');

      final model = ActivityLogModel.fromEntity(log);
      final docRef = await _activityLogsRef.add(model.toJson());

      // Update stats after logging
      await updateStatsAfterActivity(
        athleteId: log.athleteId,
        duration: log.actualDuration,
      );

      // Update plan assignment completion rate
      await _updateAssignmentCompletionRate(log.assignmentId);

      AppLogger.success('Activity logged: ${docRef.id}');
      return log.copyWith(id: docRef.id);
    } catch (e) {
      AppLogger.error('Error logging activity: $e');
      rethrow;
    }
  }

  @override
  Future<List<ActivityLogEntity>> getActivityLogs(String athleteId) async {
    try {
      final snapshot = await _activityLogsRef
          .where('athleteId', isEqualTo: athleteId)
          .orderBy('completedAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => ActivityLogModel.fromFirestore(doc).toEntity())
          .toList();
    } catch (e) {
      AppLogger.error('Error fetching activity logs: $e');
      rethrow;
    }
  }

  @override
  Future<List<ActivityLogEntity>> getActivityLogsInRange({
    required String athleteId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final snapshot = await _activityLogsRef
          .where('athleteId', isEqualTo: athleteId)
          .where(
            'completedAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
          )
          .where(
            'completedAt',
            isLessThanOrEqualTo: Timestamp.fromDate(endDate),
          )
          .orderBy('completedAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => ActivityLogModel.fromFirestore(doc).toEntity())
          .toList();
    } catch (e) {
      AppLogger.error('Error fetching activity logs in range: $e');
      rethrow;
    }
  }

  @override
  Future<List<ActivityLogEntity>> getLogsForAssignment(
    String assignmentId,
  ) async {
    try {
      final snapshot = await _activityLogsRef
          .where('assignmentId', isEqualTo: assignmentId)
          .orderBy('completedAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => ActivityLogModel.fromFirestore(doc).toEntity())
          .toList();
    } catch (e) {
      AppLogger.error('Error fetching logs for assignment: $e');
      rethrow;
    }
  }

  @override
  Stream<List<ActivityLogEntity>> watchActivityLogs(String athleteId) {
    debugPrint('\n🔍 watchActivityLogs called for: $athleteId');

    return _activityLogsRef
        .where('athleteId', isEqualTo: athleteId)
        .limit(50)
        .snapshots()
        .map((snapshot) {
          debugPrint('   📦 Got ${snapshot.docs.length} activity log docs');

          final logs = snapshot.docs
              .map((doc) => ActivityLogModel.fromFirestore(doc).toEntity())
              .toList();
          // Sort in memory instead of using orderBy to avoid composite index
          logs.sort((a, b) => b.completedAt.compareTo(a.completedAt));

          debugPrint('   ✅ Returning ${logs.length} activity logs\n');
          return logs;
        });
  }

  @override
  Future<void> deleteActivityLog(String logId) async {
    try {
      // Get the log to find the assignment ID before deleting
      final logDoc = await _activityLogsRef.doc(logId).get();
      final assignmentId = logDoc.data()?['assignmentId'] as String?;

      await _activityLogsRef.doc(logId).delete();
      AppLogger.info('Activity log deleted: $logId');

      // Recalculate completion rate if we have the assignment ID
      if (assignmentId != null) {
        await _updateAssignmentCompletionRate(assignmentId);
      }
    } catch (e) {
      AppLogger.error('Error deleting activity log: $e');
      rethrow;
    }
  }

  // ============== Stats ==============

  @override
  Future<AthleteStatsEntity> getAthleteStats(String athleteId) async {
    try {
      final doc = await _statsRef.doc(athleteId).get();
      if (!doc.exists) {
        return AthleteStatsEntity(athleteId: athleteId);
      }
      return AthleteStatsModel.fromFirestore(doc).toEntity();
    } catch (e) {
      AppLogger.error('Error fetching athlete stats: $e');
      rethrow;
    }
  }

  @override
  Stream<AthleteStatsEntity> watchAthleteStats(String athleteId) {
    // Combine stats document stream with activity logs to compute weekly/monthly stats dynamically
    final statsStream = _statsRef.doc(athleteId).snapshots();
    final activityLogsStream = _activityLogsRef
        .where('athleteId', isEqualTo: athleteId)
        .snapshots();

    return Rx.combineLatest2<
      DocumentSnapshot<Map<String, dynamic>>,
      QuerySnapshot<Map<String, dynamic>>,
      AthleteStatsEntity
    >(statsStream, activityLogsStream, (statsDoc, logsSnapshot) {
      // Get base stats from document
      AthleteStatsEntity baseStats;
      if (!statsDoc.exists) {
        baseStats = AthleteStatsEntity(athleteId: athleteId);
      } else {
        baseStats = AthleteStatsModel.fromFirestore(statsDoc).toEntity();
      }

      // Compute weekly and monthly stats from activity logs
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final currentWeekStart = today.subtract(
        Duration(days: today.weekday - 1),
      );
      final currentMonthStart = DateTime(now.year, now.month, 1);

      int weeklyWorkouts = 0;
      int weeklyDuration = 0;
      int monthlyWorkouts = 0;
      int monthlyDuration = 0;

      for (final doc in logsSnapshot.docs) {
        final data = doc.data();
        final completedAt = (data['completedAt'] as Timestamp?)?.toDate();
        if (completedAt == null) continue;

        final logDate = DateTime(
          completedAt.year,
          completedAt.month,
          completedAt.day,
        );
        final logDuration = data['actualDuration'] as int? ?? 0;

        // Count weekly stats
        if (!logDate.isBefore(currentWeekStart)) {
          weeklyWorkouts++;
          weeklyDuration += logDuration;
        }

        // Count monthly stats
        if (!logDate.isBefore(currentMonthStart)) {
          monthlyWorkouts++;
          monthlyDuration += logDuration;
        }
      }

      // Return stats with computed weekly/monthly values
      return baseStats.copyWith(
        weeklyWorkouts: weeklyWorkouts,
        weeklyDuration: weeklyDuration,
        monthlyWorkouts: monthlyWorkouts,
        monthlyDuration: monthlyDuration,
      );
    });
  }

  @override
  Future<void> updateStatsAfterActivity({
    required String athleteId,
    required int duration,
  }) async {
    try {
      final statsDoc = _statsRef.doc(athleteId);
      final now = DateTime.now();

      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(statsDoc);

        int currentStreak = 0;
        int longestStreak = 0;
        DateTime? lastActivityDate;
        int totalWorkouts = 0;
        int totalDuration = 0;
        int weeklyWorkouts = 0;
        int weeklyDuration = 0;
        int monthlyWorkouts = 0;
        int monthlyDuration = 0;
        DateTime? weekStartDate;
        DateTime? monthStartDate;

        if (snapshot.exists) {
          final data = snapshot.data()!;
          currentStreak = data['currentStreak'] as int? ?? 0;
          longestStreak = data['longestStreak'] as int? ?? 0;
          lastActivityDate = (data['lastActivityDate'] as Timestamp?)?.toDate();
          totalWorkouts = data['totalWorkouts'] as int? ?? 0;
          totalDuration = data['totalDuration'] as int? ?? 0;
          weeklyWorkouts = data['weeklyWorkouts'] as int? ?? 0;
          weeklyDuration = data['weeklyDuration'] as int? ?? 0;
          monthlyWorkouts = data['monthlyWorkouts'] as int? ?? 0;
          monthlyDuration = data['monthlyDuration'] as int? ?? 0;
          weekStartDate = (data['weekStartDate'] as Timestamp?)?.toDate();
          monthStartDate = (data['monthStartDate'] as Timestamp?)?.toDate();
        }

        // Calculate the start of current week (Monday)
        final today = DateTime(now.year, now.month, now.day);
        final currentWeekStart = today.subtract(
          Duration(days: today.weekday - 1),
        );
        final currentMonthStart = DateTime(now.year, now.month, 1);

        // Reset weekly stats if we're in a new week
        if (weekStartDate == null || currentWeekStart.isAfter(weekStartDate)) {
          weeklyWorkouts = 0;
          weeklyDuration = 0;
          weekStartDate = currentWeekStart;
        }

        // Reset monthly stats if we're in a new month
        if (monthStartDate == null ||
            currentMonthStart.isAfter(monthStartDate)) {
          monthlyWorkouts = 0;
          monthlyDuration = 0;
          monthStartDate = currentMonthStart;
        }

        // Calculate new streak
        if (lastActivityDate != null) {
          final lastActivityDay = DateTime(
            lastActivityDate.year,
            lastActivityDate.month,
            lastActivityDate.day,
          );
          final daysDiff = today.difference(lastActivityDay).inDays;
          if (daysDiff == 0) {
            // Same day, streak unchanged
          } else if (daysDiff == 1) {
            // Consecutive day, increment streak
            currentStreak++;
          } else {
            // Streak broken, reset to 1
            currentStreak = 1;
          }
        } else {
          currentStreak = 1;
        }

        // Update longest streak if needed
        if (currentStreak > longestStreak) {
          longestStreak = currentStreak;
        }

        transaction.set(statsDoc, {
          'athleteId': athleteId,
          'currentStreak': currentStreak,
          'longestStreak': longestStreak,
          'lastActivityDate': Timestamp.fromDate(now),
          'totalWorkouts': totalWorkouts + 1,
          'totalDuration': totalDuration + duration,
          'weeklyWorkouts': weeklyWorkouts + 1,
          'weeklyDuration': weeklyDuration + duration,
          'monthlyWorkouts': monthlyWorkouts + 1,
          'monthlyDuration': monthlyDuration + duration,
          'weekStartDate': Timestamp.fromDate(weekStartDate!),
          'monthStartDate': Timestamp.fromDate(monthStartDate!),
        }, SetOptions(merge: true));
      });

      AppLogger.info('Stats updated for athlete: $athleteId');
    } catch (e) {
      AppLogger.error('Error updating stats: $e');
      rethrow;
    }
  }

  /// Updates the completion rate for a plan assignment based on logged activities.
  ///
  /// Calculates completion as: (unique completed activities / total activities) * 100
  Future<void> _updateAssignmentCompletionRate(String assignmentId) async {
    try {
      // Get the assignment to find the plan
      final assignmentDoc = await _assignmentsRef.doc(assignmentId).get();
      if (!assignmentDoc.exists) return;

      final assignmentData = assignmentDoc.data()!;
      final planId = assignmentData['planId'] as String;

      // Get all activities in the plan
      final planDoc = await _firestore
          .collection('trainingPlans')
          .doc(planId)
          .get();
      if (!planDoc.exists) return;

      final planData = planDoc.data()!;
      final activities = (planData['activities'] as List?) ?? [];
      final totalActivities = activities.length;

      if (totalActivities == 0) return; // Avoid division by zero

      // Get all logged activities for this assignment
      final logsSnapshot = await _activityLogsRef
          .where('assignmentId', isEqualTo: assignmentId)
          .get();

      // Count unique activities completed (by activityId)
      final completedActivityIds = <String>{};
      for (final log in logsSnapshot.docs) {
        final activityId = log.data()['activityId'] as String?;
        if (activityId != null) {
          completedActivityIds.add(activityId);
        }
      }

      // Calculate completion rate
      final completionRate = completedActivityIds.length / totalActivities;

      // Update the assignment
      await _assignmentsRef.doc(assignmentId).update({
        'completionRate': completionRate.clamp(0.0, 1.0),
      });

      AppLogger.info(
        'Updated completion rate for assignment $assignmentId: '
        '${(completionRate * 100).toStringAsFixed(1)}%',
      );
    } catch (e) {
      AppLogger.error('Error updating assignment completion rate: $e');
      // Don't rethrow - completion rate update is not critical
    }
  }

  // ============== Assigned Plans ==============

  @override
  Future<PlanAssignmentEntity?> getActiveAssignment(String athleteId) async {
    try {
      // Query only by athleteId to avoid composite index requirement
      final snapshot = await _assignmentsRef
          .where('athleteId', isEqualTo: athleteId)
          .get();

      // Filter for active status in memory
      final activeDocs = snapshot.docs
          .where((doc) => doc.data()['status'] == 'active')
          .toList();

      if (activeDocs.isEmpty) return null;
      return PlanAssignmentModel.fromFirestore(activeDocs.first).toEntity();
    } catch (e) {
      AppLogger.error('Error fetching active assignment: $e');
      rethrow;
    }
  }

  @override
  Future<List<PlanAssignmentEntity>> getAssignments(String athleteId) async {
    try {
      final snapshot = await _assignmentsRef
          .where('athleteId', isEqualTo: athleteId)
          .get();

      return snapshot.docs
          .map((doc) => PlanAssignmentModel.fromFirestore(doc).toEntity())
          .toList();
    } catch (e) {
      AppLogger.error('Error fetching assignments: $e');
      rethrow;
    }
  }

  @override
  Stream<List<PlanAssignmentEntity>> watchAssignments(String athleteId) {
    return _assignmentsRef
        .where('athleteId', isEqualTo: athleteId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => PlanAssignmentModel.fromFirestore(doc).toEntity())
              .toList(),
        );
  }

  @override
  Future<List<ActivityEntity>> getTodaysActivities(String athleteId) async {
    try {
      final assignment = await getActiveAssignment(athleteId);
      if (assignment == null) return [];

      final planDoc = await _plansRef.doc(assignment.planId).get();
      if (!planDoc.exists) return [];

      final plan = TrainingPlanModel.fromFirestore(planDoc).toEntity();
      final today = DateTime.now().weekday; // 1 = Monday, 7 = Sunday

      return plan.activities
          .where((activity) => activity.dayOfWeek == today)
          .toList();
    } catch (e) {
      AppLogger.error('Error fetching today\'s activities: $e');
      rethrow;
    }
  }

  @override
  Future<List<ActivityEntity>> getUpcomingActivities(String athleteId) async {
    try {
      final assignment = await getActiveAssignment(athleteId);
      if (assignment == null) return [];

      final planDoc = await _plansRef.doc(assignment.planId).get();
      if (!planDoc.exists) return [];

      final plan = TrainingPlanModel.fromFirestore(planDoc).toEntity();
      final today = DateTime.now().weekday;

      // Get activities for upcoming days (next 7 days)
      return plan.activities
          .where((activity) => activity.dayOfWeek > today)
          .take(5)
          .toList();
    } catch (e) {
      AppLogger.error('Error fetching upcoming activities: $e');
      rethrow;
    }
  }

  @override
  Future<bool> isActivityCompletedToday({
    required String athleteId,
    required String activityId,
  }) async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final snapshot = await _activityLogsRef
          .where('athleteId', isEqualTo: athleteId)
          .where('activityId', isEqualTo: activityId)
          .where(
            'completedAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
          )
          .where('completedAt', isLessThan: Timestamp.fromDate(endOfDay))
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      AppLogger.error('Error checking activity completion: $e');
      rethrow;
    }
  }

  @override
  Future<List<ActivityEntity>> getActivitiesForAssignment(
    String assignmentId,
  ) async {
    try {
      // Get the assignment
      final assignmentDoc = await _assignmentsRef.doc(assignmentId).get();
      if (!assignmentDoc.exists) {
        return [];
      }

      final assignment = PlanAssignmentModel.fromFirestore(
        assignmentDoc,
      ).toEntity();

      // Get the training plan
      final planDoc = await _plansRef.doc(assignment.planId).get();
      if (!planDoc.exists) {
        return [];
      }

      final plan = TrainingPlanModel.fromFirestore(planDoc).toEntity();
      return plan.activities;
    } catch (e) {
      AppLogger.error('Error fetching activities for assignment: $e');
      rethrow;
    }
  }

  // ============== Chart Data ==============

  @override
  Future<List<int>> getWeeklyWorkoutCounts(String athleteId) async {
    try {
      final now = DateTime.now();
      // Get Monday of current week
      final monday = now.subtract(Duration(days: now.weekday - 1));
      final startOfWeek = DateTime(monday.year, monday.month, monday.day);
      final endOfWeek = startOfWeek.add(const Duration(days: 7));

      final snapshot = await _activityLogsRef
          .where('athleteId', isEqualTo: athleteId)
          .where(
            'completedAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfWeek),
          )
          .where('completedAt', isLessThan: Timestamp.fromDate(endOfWeek))
          .get();

      // Initialize counts for Mon-Sun (0-6)
      final counts = List<int>.filled(7, 0);

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final completedAt = (data['completedAt'] as Timestamp).toDate();
        final dayIndex = completedAt.weekday - 1; // 0-6 for Mon-Sun
        counts[dayIndex]++;
      }

      return counts;
    } catch (e) {
      AppLogger.error('Error fetching weekly workout counts: $e');
      rethrow;
    }
  }

  @override
  Future<List<({int week, int workouts, int duration})>> getMonthlyWorkoutData(
    String athleteId,
  ) async {
    try {
      final now = DateTime.now();
      // Get data for the past 4 weeks
      final fourWeeksAgo = now.subtract(const Duration(days: 28));
      final startDate = DateTime(
        fourWeeksAgo.year,
        fourWeeksAgo.month,
        fourWeeksAgo.day,
      );

      final snapshot = await _activityLogsRef
          .where('athleteId', isEqualTo: athleteId)
          .where(
            'completedAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
          )
          .where('completedAt', isLessThan: Timestamp.fromDate(now))
          .get();

      // Group by week
      final weekData = <int, ({int workouts, int duration})>{};

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final completedAt = (data['completedAt'] as Timestamp).toDate();
        final duration = data['actualDuration'] as int? ?? 0;

        // Calculate which week (0-3, where 3 is current week)
        final daysSinceStart = completedAt.difference(startDate).inDays;
        final weekIndex = daysSinceStart ~/ 7;

        if (weekIndex >= 0 && weekIndex < 4) {
          final current = weekData[weekIndex];
          if (current != null) {
            weekData[weekIndex] = (
              workouts: current.workouts + 1,
              duration: current.duration + duration,
            );
          } else {
            weekData[weekIndex] = (workouts: 1, duration: duration);
          }
        }
      }

      // Convert to list with all 4 weeks
      return List.generate(4, (index) {
        final data = weekData[index];
        return (
          week: index + 1,
          workouts: data?.workouts ?? 0,
          duration: data?.duration ?? 0,
        );
      });
    } catch (e) {
      AppLogger.error('Error fetching monthly workout data: $e');
      rethrow;
    }
  }

  @override
  Future<Map<String, int>> getWorkoutTypeDistribution(String athleteId) async {
    try {
      // Get all activity logs for the athlete
      final logsSnapshot = await _activityLogsRef
          .where('athleteId', isEqualTo: athleteId)
          .get();

      final distribution = <String, int>{};

      // Get activity IDs from logs
      final activityIds = <String>{};
      for (final doc in logsSnapshot.docs) {
        final data = doc.data();
        final activityId = data['activityId'] as String?;
        if (activityId != null) {
          activityIds.add(activityId);
        }
      }

      // For now, count logs by activity type from the activity name pattern
      // In production, you'd want to store the activity type in the log
      for (final doc in logsSnapshot.docs) {
        final data = doc.data();
        final activityName = (data['activityName'] as String? ?? '')
            .toLowerCase();

        String type = 'custom';
        if (activityName.contains('run') || activityName.contains('cardio')) {
          type = 'Cardio';
        } else if (activityName.contains('strength') ||
            activityName.contains('push') ||
            activityName.contains('pull') ||
            activityName.contains('squat')) {
          type = 'Strength';
        } else if (activityName.contains('yoga') ||
            activityName.contains('stretch') ||
            activityName.contains('flex')) {
          type = 'Flexibility';
        } else if (activityName.contains('hiit') ||
            activityName.contains('interval')) {
          type = 'HIIT';
        } else {
          type = 'Other';
        }

        distribution[type] = (distribution[type] ?? 0) + 1;
      }

      return distribution;
    } catch (e) {
      AppLogger.error('Error fetching workout type distribution: $e');
      rethrow;
    }
  }
}
