import 'package:equatable/equatable.dart';

import '../../../../core/constants/app_constants.dart';

/// Represents an assignment of a training plan to an athlete.
///
/// Tracks the relationship between a plan and an athlete,
/// including progress and status information.
class PlanAssignmentEntity extends Equatable {
  /// Creates a new [PlanAssignmentEntity].
  const PlanAssignmentEntity({
    required this.id,
    required this.planId,
    required this.athleteId,
    required this.coachId,
    required this.assignedAt,
    required this.startDate,
    this.endDate,
    this.status = AssignmentStatus.active,
    this.completionRate = 0.0,
    this.planName,
    this.athleteName,
  });

  /// Unique identifier for the assignment.
  final String id;

  /// ID of the training plan.
  final String planId;

  /// ID of the athlete.
  final String athleteId;

  /// ID of the coach who made the assignment.
  final String coachId;

  /// When the plan was assigned.
  final DateTime assignedAt;

  /// When the plan should start.
  final DateTime startDate;

  /// When the plan should end (optional).
  final DateTime? endDate;

  /// Current status of the assignment.
  final AssignmentStatus status;

  /// Completion rate (0.0 to 1.0).
  final double completionRate;

  /// Cached plan name for display (denormalized).
  final String? planName;

  /// Cached athlete name for display (denormalized).
  final String? athleteName;

  /// Creates a copy with optional new values.
  PlanAssignmentEntity copyWith({
    String? id,
    String? planId,
    String? athleteId,
    String? coachId,
    DateTime? assignedAt,
    DateTime? startDate,
    DateTime? endDate,
    AssignmentStatus? status,
    double? completionRate,
    String? planName,
    String? athleteName,
  }) {
    return PlanAssignmentEntity(
      id: id ?? this.id,
      planId: planId ?? this.planId,
      athleteId: athleteId ?? this.athleteId,
      coachId: coachId ?? this.coachId,
      assignedAt: assignedAt ?? this.assignedAt,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      completionRate: completionRate ?? this.completionRate,
      planName: planName ?? this.planName,
      athleteName: athleteName ?? this.athleteName,
    );
  }

  /// Whether this assignment is currently active.
  bool get isActive => status == AssignmentStatus.active;

  /// Whether this assignment is completed.
  bool get isCompleted => status == AssignmentStatus.completed;

  /// Completion percentage (0-100).
  int get completionPercentage => (completionRate * 100).round();

  /// Days remaining in the assignment.
  int? get daysRemaining {
    if (endDate == null) return null;
    final remaining = endDate!.difference(DateTime.now()).inDays;
    return remaining > 0 ? remaining : 0;
  }

  /// Days since the assignment started.
  int get daysSinceStart => DateTime.now().difference(startDate).inDays;

  /// Whether the assignment has started.
  bool get hasStarted => DateTime.now().isAfter(startDate);

  @override
  List<Object?> get props => [
    id,
    planId,
    athleteId,
    coachId,
    assignedAt,
    startDate,
    endDate,
    status,
    completionRate,
    planName,
    athleteName,
  ];
}
