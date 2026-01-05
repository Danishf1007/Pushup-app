import 'package:equatable/equatable.dart';

import 'activity_entity.dart';

/// Represents a training plan created by a coach.
///
/// A training plan contains multiple activities scheduled across
/// different days of the week, designed for athletes to follow.
class TrainingPlanEntity extends Equatable {
  /// Creates a new [TrainingPlanEntity].
  const TrainingPlanEntity({
    required this.id,
    required this.coachId,
    required this.name,
    this.description,
    required this.durationDays,
    required this.activities,
    required this.createdAt,
    this.updatedAt,
    this.isTemplate = false,
  });

  /// Unique identifier for the plan.
  final String id;

  /// ID of the coach who created this plan.
  final String coachId;

  /// Name of the training plan.
  final String name;

  /// Optional description of the plan.
  final String? description;

  /// Duration of the plan in days.
  final int durationDays;

  /// List of activities in this plan.
  final List<ActivityEntity> activities;

  /// When the plan was created.
  final DateTime createdAt;

  /// When the plan was last updated.
  final DateTime? updatedAt;

  /// Whether this is a reusable template.
  final bool isTemplate;

  /// Creates a copy with optional new values.
  TrainingPlanEntity copyWith({
    String? id,
    String? coachId,
    String? name,
    String? description,
    int? durationDays,
    List<ActivityEntity>? activities,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isTemplate,
  }) {
    return TrainingPlanEntity(
      id: id ?? this.id,
      coachId: coachId ?? this.coachId,
      name: name ?? this.name,
      description: description ?? this.description,
      durationDays: durationDays ?? this.durationDays,
      activities: activities ?? this.activities,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isTemplate: isTemplate ?? this.isTemplate,
    );
  }

  /// Returns the number of activities in this plan.
  int get activityCount => activities.length;

  /// Returns the total duration of all activities in minutes.
  int get totalDuration {
    return activities.fold<int>(
      0,
      (sum, activity) => sum + (activity.targetDuration ?? 0),
    );
  }

  /// Returns activities grouped by day of week.
  Map<int, List<ActivityEntity>> get activitiesByDay {
    final grouped = <int, List<ActivityEntity>>{};
    for (final activity in activities) {
      grouped.putIfAbsent(activity.dayOfWeek, () => []).add(activity);
    }
    // Sort activities within each day by order
    for (final dayActivities in grouped.values) {
      dayActivities.sort((a, b) => a.order.compareTo(b.order));
    }
    return grouped;
  }

  /// Returns true if the plan has activities for all 7 days.
  bool get isWeeklyPlan {
    final daysWithActivities = activities.map((a) => a.dayOfWeek).toSet();
    return daysWithActivities.length == 7;
  }

  /// Formatted duration display.
  String get formattedDuration {
    if (durationDays == 7) return '1 week';
    if (durationDays == 14) return '2 weeks';
    if (durationDays == 21) return '3 weeks';
    if (durationDays == 28) return '4 weeks';
    if (durationDays % 7 == 0) return '${durationDays ~/ 7} weeks';
    return '$durationDays days';
  }

  @override
  List<Object?> get props => [
    id,
    coachId,
    name,
    description,
    durationDays,
    activities,
    createdAt,
    updatedAt,
    isTemplate,
  ];
}
