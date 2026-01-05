import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Data model for athlete performance metrics.
class AthletePerformance {
  /// Creates an athlete performance record.
  const AthletePerformance({
    required this.rank,
    required this.athleteId,
    required this.athleteName,
    required this.completionRate,
    required this.workoutsCompleted,
    required this.streak,
  });

  /// Ranking position.
  final int rank;

  /// Athlete's unique ID.
  final String athleteId;

  /// Athlete's display name.
  final String athleteName;

  /// Completion rate percentage (0-100).
  final double completionRate;

  /// Total workouts completed.
  final int workoutsCompleted;

  /// Current workout streak in days.
  final int streak;
}

/// Aggregated analytics data for a coach's athletes.
class CoachAnalytics {
  /// Creates coach analytics data.
  const CoachAnalytics({
    required this.totalAthletes,
    required this.activeThisWeek,
    required this.inactiveCount,
    required this.atRiskCount,
    required this.avgCompletionRate,
    required this.workoutsToday,
    required this.weeklyTeamActivity,
    required this.completionByAthlete,
    required this.topPerformers,
  });

  /// Total number of athletes managed by coach.
  final int totalAthletes;

  /// Athletes who have worked out in the past 3 days.
  final int activeThisWeek;

  /// Athletes inactive for 3-6 days.
  final int inactiveCount;

  /// Athletes inactive for 7+ days (at risk).
  final int atRiskCount;

  /// Average completion rate across all athletes.
  final double avgCompletionRate;

  /// Number of workouts completed today.
  final int workoutsToday;

  /// Workouts per day for the current week (Mon-Sun).
  final List<int> weeklyTeamActivity;

  /// Completion rate by athlete ID.
  final Map<String, double> completionByAthlete;

  /// Top performing athletes.
  final List<AthletePerformance> topPerformers;
}

/// Provider for coach analytics data.
final coachAnalyticsProvider = FutureProvider.family<CoachAnalytics, String>((
  ref,
  coachId,
) async {
  final firestore = FirebaseFirestore.instance;

  try {
    // Get all athletes for this coach
    final athletesQuery = await firestore
        .collection('users')
        .where('coachId', isEqualTo: coachId)
        .get();

    // Filter to only athletes in memory
    final athletes = athletesQuery.docs
        .where((doc) => doc.data()['role'] == 'athlete')
        .toList();
    final totalAthletes = athletes.length;

    if (totalAthletes == 0) {
      return const CoachAnalytics(
        totalAthletes: 0,
        activeThisWeek: 0,
        inactiveCount: 0,
        atRiskCount: 0,
        avgCompletionRate: 0,
        workoutsToday: 0,
        weeklyTeamActivity: [0, 0, 0, 0, 0, 0, 0],
        completionByAthlete: {},
        topPerformers: [],
      );
    }

    // Calculate date ranges
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Get start of current week (Monday)
    final weekStart = today.subtract(Duration(days: today.weekday - 1));

    int activeThisWeek = 0;
    int inactiveCount = 0;
    int atRiskCount = 0;
    int workoutsToday = 0;
    double totalCompletionRate = 0;

    final weeklyActivity = List<int>.filled(7, 0);
    final completionByAthlete = <String, double>{};
    final performersList = <AthletePerformance>[];

    // Process each athlete
    for (final athleteDoc in athletes) {
      final athleteId = athleteDoc.id;
      final athleteData = athleteDoc.data();
      final athleteName =
          athleteData['displayName'] as String? ?? 'Unknown Athlete';

      // Fetch athlete's stats document
      final statsDoc = await firestore
          .collection('athlete_stats')
          .doc(athleteId)
          .get();

      DateTime? lastActive;
      int streak = 0;
      double completionRate = 0;
      int totalWorkouts = 0;

      if (statsDoc.exists) {
        final statsData = statsDoc.data()!;
        // Support both lastActivityDate and lastWorkoutDate field names
        lastActive =
            (statsData['lastActivityDate'] as Timestamp?)?.toDate() ??
            (statsData['lastWorkoutDate'] as Timestamp?)?.toDate();
        streak =
            statsData['currentStreak'] as int? ??
            statsData['streak'] as int? ??
            0;
        totalWorkouts = statsData['totalWorkouts'] as int? ?? 0;
      }

      // Determine activity status
      if (lastActive != null) {
        final daysSinceActive = today
            .difference(
              DateTime(lastActive.year, lastActive.month, lastActive.day),
            )
            .inDays;
        if (daysSinceActive <= 3) {
          activeThisWeek++;
        } else if (daysSinceActive <= 6) {
          inactiveCount++;
        } else {
          atRiskCount++;
        }
      } else {
        atRiskCount++; // Never active = at risk
      }

      // Fetch activity logs for this athlete (no date filter to avoid index requirement)
      final activityQuery = await firestore
          .collection('activity_logs')
          .where('athleteId', isEqualTo: athleteId)
          .get();

      // Filter in memory for this week's activities
      for (final activityDoc in activityQuery.docs) {
        final activityData = activityDoc.data();
        final completedAt = (activityData['completedAt'] as Timestamp).toDate();

        // Only count activities from this week
        if (completedAt.isAfter(weekStart.subtract(const Duration(days: 1))) &&
            completedAt.isBefore(today.add(const Duration(days: 1)))) {
          final dayIndex = completedAt.difference(weekStart).inDays;

          if (dayIndex >= 0 && dayIndex < 7) {
            weeklyActivity[dayIndex]++;
          }

          // Count today's workouts
          if (completedAt.year == today.year &&
              completedAt.month == today.month &&
              completedAt.day == today.day) {
            workoutsToday++;
          }
        }
      }

      // Get completion rate from active assignment (already calculated properly)
      final assignedPlansQuery = await firestore
          .collection('plan_assignments')
          .where('athleteId', isEqualTo: athleteId)
          .where('status', isEqualTo: 'active')
          .limit(1)
          .get();

      if (assignedPlansQuery.docs.isNotEmpty) {
        final assignmentData = assignedPlansQuery.docs.first.data();
        // Use the completion rate from the assignment (0.0 to 1.0)
        final rate =
            (assignmentData['completionRate'] as num?)?.toDouble() ?? 0.0;
        completionRate = (rate * 100).clamp(0, 100); // Convert to percentage
      }

      completionByAthlete[athleteId] = completionRate;
      totalCompletionRate += completionRate;

      // Add to performers list
      performersList.add(
        AthletePerformance(
          rank: 0,
          athleteId: athleteId,
          athleteName: athleteName,
          completionRate: completionRate,
          workoutsCompleted: totalWorkouts,
          streak: streak,
        ),
      );
    }

    // Sort performers by completion rate and streak, then assign ranks
    performersList.sort((a, b) {
      final rateCompare = b.completionRate.compareTo(a.completionRate);
      if (rateCompare != 0) return rateCompare;
      return b.streak.compareTo(a.streak);
    });

    final rankedPerformers = performersList.asMap().entries.map((entry) {
      return AthletePerformance(
        rank: entry.key + 1,
        athleteId: entry.value.athleteId,
        athleteName: entry.value.athleteName,
        completionRate: entry.value.completionRate,
        workoutsCompleted: entry.value.workoutsCompleted,
        streak: entry.value.streak,
      );
    }).toList();

    final avgCompletionRate = totalAthletes > 0
        ? totalCompletionRate / totalAthletes
        : 0.0;

    return CoachAnalytics(
      totalAthletes: totalAthletes,
      activeThisWeek: activeThisWeek,
      inactiveCount: inactiveCount,
      atRiskCount: atRiskCount,
      avgCompletionRate: avgCompletionRate,
      workoutsToday: workoutsToday,
      weeklyTeamActivity: weeklyActivity,
      completionByAthlete: completionByAthlete,
      topPerformers: rankedPerformers,
    );
  } catch (e) {
    // Return empty analytics on error rather than throwing
    return const CoachAnalytics(
      totalAthletes: 0,
      activeThisWeek: 0,
      inactiveCount: 0,
      atRiskCount: 0,
      avgCompletionRate: 0,
      workoutsToday: 0,
      weeklyTeamActivity: [0, 0, 0, 0, 0, 0, 0],
      completionByAthlete: {},
      topPerformers: [],
    );
  }
});
