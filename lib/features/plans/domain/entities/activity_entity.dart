import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Represents a single training activity within a plan.
///
/// Activities are the building blocks of training plans, defining
/// specific exercises or workouts to be performed on particular days.
class ActivityEntity extends Equatable {
  /// Creates a new [ActivityEntity].
  const ActivityEntity({
    required this.id,
    required this.name,
    required this.type,
    required this.dayOfWeek,
    this.targetDuration,
    this.instructions,
    this.order = 0,
  });

  /// Unique identifier for the activity.
  final String id;

  /// Name of the activity (e.g., "Morning Run", "Push-ups").
  final String name;

  /// Type of activity (e.g., "cardio", "strength", "flexibility").
  final String type;

  /// Day of week (1 = Monday, 7 = Sunday).
  final int dayOfWeek;

  /// Target duration in minutes.
  final int? targetDuration;

  /// Instructions or notes for the activity.
  final String? instructions;

  /// Order of activity within the day (for sorting).
  final int order;

  /// Creates a copy with optional new values.
  ActivityEntity copyWith({
    String? id,
    String? name,
    String? type,
    int? dayOfWeek,
    int? targetDuration,
    String? instructions,
    int? order,
  }) {
    return ActivityEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      targetDuration: targetDuration ?? this.targetDuration,
      instructions: instructions ?? this.instructions,
      order: order ?? this.order,
    );
  }

  /// Returns the day name for this activity.
  String get dayName {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return days[(dayOfWeek - 1).clamp(0, 6)];
  }

  /// Returns a formatted duration string.
  String get formattedDuration {
    if (targetDuration == null) return 'No target';
    if (targetDuration! < 60) return '$targetDuration min';
    final hours = targetDuration! ~/ 60;
    final mins = targetDuration! % 60;
    return mins > 0 ? '${hours}h ${mins}m' : '${hours}h';
  }

  /// Returns the appropriate icon for the activity type.
  IconData get typeIcon {
    switch (type) {
      case ActivityTypes.cardio:
        return Icons.directions_run;
      case ActivityTypes.strength:
        return Icons.fitness_center;
      case ActivityTypes.flexibility:
        return Icons.self_improvement;
      case ActivityTypes.hiit:
        return Icons.whatshot;
      case ActivityTypes.rest:
        return Icons.hotel;
      case ActivityTypes.custom:
      default:
        return Icons.sports;
    }
  }

  @override
  List<Object?> get props => [
    id,
    name,
    type,
    dayOfWeek,
    targetDuration,
    instructions,
    order,
  ];
}

/// Activity type constants.
abstract class ActivityTypes {
  static const String cardio = 'cardio';
  static const String strength = 'strength';
  static const String flexibility = 'flexibility';
  static const String hiit = 'hiit';
  static const String rest = 'rest';
  static const String custom = 'custom';

  /// All available activity types.
  static const List<String> all = [
    cardio,
    strength,
    flexibility,
    hiit,
    rest,
    custom,
  ];

  /// Display names for activity types.
  static String displayName(String type) {
    switch (type) {
      case cardio:
        return 'Cardio';
      case strength:
        return 'Strength';
      case flexibility:
        return 'Flexibility';
      case hiit:
        return 'HIIT';
      case rest:
        return 'Rest Day';
      case custom:
        return 'Custom';
      default:
        return type;
    }
  }
}
