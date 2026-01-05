import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/athlete_stats_entity.dart';

/// Data model for [AthleteStatsEntity] with Firestore serialization.
class AthleteStatsModel {
  /// Creates a new [AthleteStatsModel].
  const AthleteStatsModel({
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

  final String athleteId;
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastActivityDate;
  final int totalWorkouts;
  final int totalDuration;
  final int weeklyWorkouts;
  final int weeklyDuration;
  final int monthlyWorkouts;
  final int monthlyDuration;

  /// Creates from Firestore document.
  factory AthleteStatsModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) {
      return AthleteStatsModel(athleteId: doc.id);
    }
    return AthleteStatsModel(
      athleteId: doc.id,
      currentStreak: data['currentStreak'] as int? ?? 0,
      longestStreak: data['longestStreak'] as int? ?? 0,
      lastActivityDate: (data['lastActivityDate'] as Timestamp?)?.toDate(),
      totalWorkouts: data['totalWorkouts'] as int? ?? 0,
      totalDuration: data['totalDuration'] as int? ?? 0,
      weeklyWorkouts: data['weeklyWorkouts'] as int? ?? 0,
      weeklyDuration: data['weeklyDuration'] as int? ?? 0,
      monthlyWorkouts: data['monthlyWorkouts'] as int? ?? 0,
      monthlyDuration: data['monthlyDuration'] as int? ?? 0,
    );
  }

  /// Creates from entity.
  factory AthleteStatsModel.fromEntity(AthleteStatsEntity entity) {
    return AthleteStatsModel(
      athleteId: entity.athleteId,
      currentStreak: entity.currentStreak,
      longestStreak: entity.longestStreak,
      lastActivityDate: entity.lastActivityDate,
      totalWorkouts: entity.totalWorkouts,
      totalDuration: entity.totalDuration,
      weeklyWorkouts: entity.weeklyWorkouts,
      weeklyDuration: entity.weeklyDuration,
      monthlyWorkouts: entity.monthlyWorkouts,
      monthlyDuration: entity.monthlyDuration,
    );
  }

  /// Converts to Firestore JSON.
  Map<String, dynamic> toJson() {
    return {
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'lastActivityDate': lastActivityDate != null
          ? Timestamp.fromDate(lastActivityDate!)
          : null,
      'totalWorkouts': totalWorkouts,
      'totalDuration': totalDuration,
      'weeklyWorkouts': weeklyWorkouts,
      'weeklyDuration': weeklyDuration,
      'monthlyWorkouts': monthlyWorkouts,
      'monthlyDuration': monthlyDuration,
    };
  }

  /// Converts to entity.
  AthleteStatsEntity toEntity() {
    return AthleteStatsEntity(
      athleteId: athleteId,
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      lastActivityDate: lastActivityDate,
      totalWorkouts: totalWorkouts,
      totalDuration: totalDuration,
      weeklyWorkouts: weeklyWorkouts,
      weeklyDuration: weeklyDuration,
      monthlyWorkouts: monthlyWorkouts,
      monthlyDuration: monthlyDuration,
    );
  }
}
