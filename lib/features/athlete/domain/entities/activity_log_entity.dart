import 'package:equatable/equatable.dart';

/// Represents a logged workout activity by an athlete.
///
/// Records the completion of an activity with timing,
/// effort level, and optional notes.
class ActivityLogEntity extends Equatable {
  /// Creates a new [ActivityLogEntity].
  const ActivityLogEntity({
    required this.id,
    required this.athleteId,
    required this.assignmentId,
    required this.activityId,
    required this.activityName,
    required this.completedAt,
    required this.actualDuration,
    this.distance,
    required this.effortLevel,
    this.notes,
    this.photoUrl,
    required this.coachId,
  });

  /// Unique identifier for this log entry.
  final String id;

  /// ID of the athlete who completed the activity.
  final String athleteId;

  /// ID of the plan assignment this activity belongs to.
  final String assignmentId;

  /// ID of the specific activity that was completed.
  final String activityId;

  /// Name of the activity for display purposes.
  final String activityName;

  /// When the activity was completed.
  final DateTime completedAt;

  /// Actual duration in minutes.
  final int actualDuration;

  /// Distance covered (for running, cycling, etc.).
  final double? distance;

  /// Effort level from 1-10.
  final int effortLevel;

  /// Optional notes about the workout.
  final String? notes;

  /// Optional photo URL documenting the workout.
  final String? photoUrl;

  /// ID of the coach who assigned the plan.
  final String coachId;

  /// Creates a copy with modified fields.
  ActivityLogEntity copyWith({
    String? id,
    String? athleteId,
    String? assignmentId,
    String? activityId,
    String? activityName,
    DateTime? completedAt,
    int? actualDuration,
    double? distance,
    int? effortLevel,
    String? notes,
    String? photoUrl,
    String? coachId,
  }) {
    return ActivityLogEntity(
      id: id ?? this.id,
      athleteId: athleteId ?? this.athleteId,
      assignmentId: assignmentId ?? this.assignmentId,
      activityId: activityId ?? this.activityId,
      activityName: activityName ?? this.activityName,
      completedAt: completedAt ?? this.completedAt,
      actualDuration: actualDuration ?? this.actualDuration,
      distance: distance ?? this.distance,
      effortLevel: effortLevel ?? this.effortLevel,
      notes: notes ?? this.notes,
      photoUrl: photoUrl ?? this.photoUrl,
      coachId: coachId ?? this.coachId,
    );
  }

  /// Returns formatted duration string.
  String get formattedDuration {
    if (actualDuration < 60) {
      return '$actualDuration min';
    }
    final hours = actualDuration ~/ 60;
    final minutes = actualDuration % 60;
    return minutes > 0 ? '${hours}h ${minutes}m' : '${hours}h';
  }

  /// Returns effort level description.
  String get effortDescription {
    if (effortLevel <= 3) return 'Easy';
    if (effortLevel <= 5) return 'Moderate';
    if (effortLevel <= 7) return 'Hard';
    if (effortLevel <= 9) return 'Very Hard';
    return 'Maximum';
  }

  /// Returns formatted distance string.
  String? get formattedDistance {
    if (distance == null) return null;
    if (distance! < 1) {
      return '${(distance! * 1000).toInt()}m';
    }
    return '${distance!.toStringAsFixed(1)}km';
  }

  @override
  List<Object?> get props => [
    id,
    athleteId,
    assignmentId,
    activityId,
    activityName,
    completedAt,
    actualDuration,
    distance,
    effortLevel,
    notes,
    photoUrl,
    coachId,
  ];
}
