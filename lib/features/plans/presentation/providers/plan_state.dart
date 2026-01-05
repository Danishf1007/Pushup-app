import 'package:equatable/equatable.dart';

import '../../domain/entities/entities.dart';

/// Base sealed class for plan-related states.
sealed class PlanState extends Equatable {
  const PlanState();

  @override
  List<Object?> get props => [];
}

/// Initial state before any data is loaded.
class PlanInitial extends PlanState {
  const PlanInitial();
}

/// Loading state while fetching data.
class PlanLoading extends PlanState {
  const PlanLoading();
}

/// State when plans are loaded successfully.
class PlansLoaded extends PlanState {
  const PlansLoaded(this.plans);

  final List<TrainingPlanEntity> plans;

  @override
  List<Object?> get props => [plans];
}

/// State when a single plan is loaded.
class PlanDetailLoaded extends PlanState {
  const PlanDetailLoaded(this.plan);

  final TrainingPlanEntity plan;

  @override
  List<Object?> get props => [plan];
}

/// State when plan operation succeeds.
class PlanOperationSuccess extends PlanState {
  const PlanOperationSuccess({this.message, this.plan});

  final String? message;
  final TrainingPlanEntity? plan;

  @override
  List<Object?> get props => [message, plan];
}

/// Error state with message.
class PlanError extends PlanState {
  const PlanError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

// ============== Assignment States ==============

/// Base sealed class for assignment-related states.
sealed class AssignmentState extends Equatable {
  const AssignmentState();

  @override
  List<Object?> get props => [];
}

/// Initial assignment state.
class AssignmentInitial extends AssignmentState {
  const AssignmentInitial();
}

/// Loading assignments.
class AssignmentLoading extends AssignmentState {
  const AssignmentLoading();
}

/// Assignments loaded successfully.
class AssignmentsLoaded extends AssignmentState {
  const AssignmentsLoaded(this.assignments);

  final List<PlanAssignmentEntity> assignments;

  @override
  List<Object?> get props => [assignments];
}

/// Single active assignment loaded.
class ActiveAssignmentLoaded extends AssignmentState {
  const ActiveAssignmentLoaded(this.assignment);

  final PlanAssignmentEntity? assignment;

  @override
  List<Object?> get props => [assignment];
}

/// Assignment operation succeeded.
class AssignmentOperationSuccess extends AssignmentState {
  const AssignmentOperationSuccess({this.message, this.assignment});

  final String? message;
  final PlanAssignmentEntity? assignment;

  @override
  List<Object?> get props => [message, assignment];
}

/// Assignment error.
class AssignmentError extends AssignmentState {
  const AssignmentError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
