import '../../../auth/domain/entities/user_entity.dart';
import '../../../plans/domain/entities/entities.dart';

/// Repository interface for coach-specific operations.
///
/// Handles operations related to managing athletes
/// and their assignments from a coach's perspective.
abstract class CoachRepository {
  /// Gets all athletes assigned to a coach.
  ///
  /// Returns a list of [UserEntity] representing athletes.
  Future<List<UserEntity>> getAthletesByCoach(String coachId);

  /// Stream of athletes assigned to a coach.
  ///
  /// Provides real-time updates when athletes are added or removed.
  Stream<List<UserEntity>> watchAthletesByCoach(String coachId);

  /// Gets a specific athlete by ID.
  Future<UserEntity?> getAthleteById(String athleteId);

  /// Assigns an athlete to a coach.
  ///
  /// Updates the athlete's coachId to link them to the coach.
  Future<void> assignAthleteToCoach({
    required String athleteId,
    required String coachId,
  });

  /// Removes an athlete from a coach.
  ///
  /// Clears the athlete's coachId.
  Future<void> removeAthleteFromCoach(String athleteId);

  /// Gets all plan assignments for an athlete.
  Stream<List<PlanAssignmentEntity>> watchAthleteAssignments(String athleteId);

  /// Gets athlete's assignment for a specific plan.
  Future<PlanAssignmentEntity?> getAthleteAssignment({
    required String athleteId,
    required String planId,
  });
}
