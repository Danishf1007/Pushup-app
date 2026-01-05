import '../entities/entities.dart';

/// Repository interface for training plan operations.
///
/// Defines the contract for plan-related data operations.
/// Implementations handle the actual data source (Firebase, etc.).
abstract class PlanRepository {
  // ============== Training Plans ==============

  /// Creates a new training plan.
  Future<TrainingPlanEntity> createPlan(TrainingPlanEntity plan);

  /// Updates an existing training plan.
  Future<TrainingPlanEntity> updatePlan(TrainingPlanEntity plan);

  /// Deletes a training plan by ID.
  Future<void> deletePlan(String planId);

  /// Gets a training plan by ID.
  Future<TrainingPlanEntity?> getPlanById(String planId);

  /// Gets all training plans for a coach.
  Future<List<TrainingPlanEntity>> getPlansByCoach(String coachId);

  /// Stream of plans for a coach (real-time updates).
  Stream<List<TrainingPlanEntity>> watchPlansByCoach(String coachId);

  /// Gets template plans (reusable).
  Future<List<TrainingPlanEntity>> getTemplatePlans(String coachId);

  // ============== Plan Assignments ==============

  /// Assigns a plan to an athlete.
  Future<PlanAssignmentEntity> assignPlan(PlanAssignmentEntity assignment);

  /// Updates an assignment.
  Future<PlanAssignmentEntity> updateAssignment(
    PlanAssignmentEntity assignment,
  );

  /// Cancels/deletes an assignment.
  Future<void> cancelAssignment(String assignmentId);

  /// Marks an assignment as complete.
  Future<void> completeAssignment(String assignmentId);

  /// Gets assignments for a specific athlete.
  Future<List<PlanAssignmentEntity>> getAssignmentsByAthlete(String athleteId);

  /// Gets assignments made by a coach.
  Future<List<PlanAssignmentEntity>> getAssignmentsByCoach(String coachId);

  /// Gets the active assignment for an athlete.
  Future<PlanAssignmentEntity?> getActiveAssignment(String athleteId);

  /// Stream of assignments for an athlete (real-time updates).
  Stream<List<PlanAssignmentEntity>> watchAssignmentsByAthlete(
    String athleteId,
  );

  /// Stream of assignments for a coach (real-time updates).
  Stream<List<PlanAssignmentEntity>> watchAssignmentsByCoach(String coachId);

  /// Updates the completion rate for an assignment.
  Future<void> updateCompletionRate(String assignmentId, double rate);

  // ============== Activities ==============

  /// Adds an activity to a plan.
  Future<void> addActivity(String planId, ActivityEntity activity);

  /// Updates an activity in a plan.
  Future<void> updateActivity(String planId, ActivityEntity activity);

  /// Removes an activity from a plan.
  Future<void> removeActivity(String planId, String activityId);

  /// Reorders activities in a plan.
  Future<void> reorderActivities(
    String planId,
    List<ActivityEntity> activities,
  );
}
