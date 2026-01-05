import 'package:equatable/equatable.dart';

/// Represents streak and statistics for an athlete.
///
/// Tracks workout consistency and achievements.
class AthleteStatsEntity extends Equatable {
  /// Creates a new [AthleteStatsEntity].
  const AthleteStatsEntity({
    required this.athleteId,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastActivityDate,
    this.totalWorkouts = 0,
    this.totalDuration = 0,
    this.weeklyWorkouts = 0,
    this.weeklyDuration = 0,
    this.monthlyWorkouts = 0,
    this.monthlyDuration = 0,
  });

  /// The athlete's ID.
  final String athleteId;

  /// Current consecutive days with workouts.
  final int currentStreak;

  /// Longest streak ever achieved.
  final int longestStreak;

  /// Date of the last completed activity.
  final DateTime? lastActivityDate;

  /// Total number of completed workouts.
  final int totalWorkouts;

  /// Total workout duration in minutes.
  final int totalDuration;

  /// Workouts completed this week.
  final int weeklyWorkouts;

  /// Duration this week in minutes.
  final int weeklyDuration;

  /// Workouts completed this month.
  final int monthlyWorkouts;

  /// Duration this month in minutes.
  final int monthlyDuration;

  /// Creates a copy with modified fields.
  AthleteStatsEntity copyWith({
    String? athleteId,
    int? currentStreak,
    int? longestStreak,
    DateTime? lastActivityDate,
    int? totalWorkouts,
    int? totalDuration,
    int? weeklyWorkouts,
    int? weeklyDuration,
    int? monthlyWorkouts,
    int? monthlyDuration,
  }) {
    return AthleteStatsEntity(
      athleteId: athleteId ?? this.athleteId,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastActivityDate: lastActivityDate ?? this.lastActivityDate,
      totalWorkouts: totalWorkouts ?? this.totalWorkouts,
      totalDuration: totalDuration ?? this.totalDuration,
      weeklyWorkouts: weeklyWorkouts ?? this.weeklyWorkouts,
      weeklyDuration: weeklyDuration ?? this.weeklyDuration,
      monthlyWorkouts: monthlyWorkouts ?? this.monthlyWorkouts,
      monthlyDuration: monthlyDuration ?? this.monthlyDuration,
    );
  }

  /// Returns formatted total duration.
  String get formattedTotalDuration {
    if (totalDuration < 60) {
      return '$totalDuration min';
    }
    final hours = totalDuration ~/ 60;
    final minutes = totalDuration % 60;
    return minutes > 0 ? '${hours}h ${minutes}m' : '${hours}h';
  }

  /// Returns formatted weekly duration.
  String get formattedWeeklyDuration {
    if (weeklyDuration < 60) {
      return '$weeklyDuration min';
    }
    final hours = weeklyDuration ~/ 60;
    final minutes = weeklyDuration % 60;
    return minutes > 0 ? '${hours}h ${minutes}m' : '${hours}h';
  }

  /// Returns formatted monthly duration.
  String get formattedMonthlyDuration {
    if (monthlyDuration < 60) {
      return '$monthlyDuration min';
    }
    final hours = monthlyDuration ~/ 60;
    final minutes = monthlyDuration % 60;
    return minutes > 0 ? '${hours}h ${minutes}m' : '${hours}h';
  }

  /// Whether the athlete has been active today.
  bool get isActiveToday {
    if (lastActivityDate == null) return false;
    final now = DateTime.now();
    return lastActivityDate!.year == now.year &&
        lastActivityDate!.month == now.month &&
        lastActivityDate!.day == now.day;
  }

  @override
  List<Object?> get props => [
    athleteId,
    currentStreak,
    longestStreak,
    lastActivityDate,
    totalWorkouts,
    totalDuration,
    weeklyWorkouts,
    weeklyDuration,
    monthlyWorkouts,
    monthlyDuration,
  ];
}
