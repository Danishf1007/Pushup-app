import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/models.dart';
import '../../data/repositories/plan_repository_impl.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/plan_repository.dart';
import 'plan_state.dart';

/// Provider for the [PlanRepository] implementation.
final planRepositoryProvider = Provider<PlanRepository>((ref) {
  return PlanRepositoryImpl();
});

/// Provider for streaming plans by coach ID.
final plansStreamProvider =
    StreamProvider.family<List<TrainingPlanEntity>, String>((ref, coachId) {
      final repository = ref.watch(planRepositoryProvider);
      return repository.watchPlansByCoach(coachId);
    });

/// Provider for streaming assignments by coach ID.
final coachAssignmentsStreamProvider =
    StreamProvider.family<List<PlanAssignmentEntity>, String>((ref, coachId) {
      final repository = ref.watch(planRepositoryProvider);
      return repository.watchAssignmentsByCoach(coachId);
    });

/// Provider for streaming assignments by athlete ID.
final athleteAssignmentsStreamProvider =
    StreamProvider.family<List<PlanAssignmentEntity>, String>((ref, athleteId) {
      final repository = ref.watch(planRepositoryProvider);
      return repository.watchAssignmentsByAthlete(athleteId);
    });

/// Provider for the plan state notifier.
final planProvider = StateNotifierProvider<PlanNotifier, PlanState>((ref) {
  final repository = ref.watch(planRepositoryProvider);
  return PlanNotifier(repository);
});

/// Provider for fetching a single plan by ID (one-time fetch).
final planByIdProvider = FutureProvider.family<TrainingPlanEntity?, String>((
  ref,
  planId,
) async {
  final repository = ref.watch(planRepositoryProvider);
  return repository.getPlanById(planId);
});

/// Provider for streaming a single plan by ID (real-time updates).
final planStreamProvider = StreamProvider.family<TrainingPlanEntity?, String>((
  ref,
  planId,
) {
  final firestore = FirebaseFirestore.instance;
  return firestore.collection('trainingPlans').doc(planId).snapshots().map((
    doc,
  ) {
    if (!doc.exists) {
      return null;
    }
    return TrainingPlanModel.fromFirestore(doc).toEntity();
  });
});

/// Provider for active assignment by athlete ID.
final activeAssignmentProvider =
    FutureProvider.family<PlanAssignmentEntity?, String>((
      ref,
      athleteId,
    ) async {
      final repository = ref.watch(planRepositoryProvider);
      return repository.getActiveAssignment(athleteId);
    });

/// Notifier for managing plan operations.
class PlanNotifier extends StateNotifier<PlanState> {
  /// Creates a new [PlanNotifier].
  PlanNotifier(this._repository) : super(const PlanInitial());

  final PlanRepository _repository;

  /// Loads all plans for a coach.
  Future<void> loadPlans(String coachId) async {
    state = const PlanLoading();
    try {
      final plans = await _repository.getPlansByCoach(coachId);
      state = PlansLoaded(plans);
    } catch (e) {
      state = PlanError(_mapError(e));
    }
  }

  /// Loads a single plan by ID.
  Future<void> loadPlan(String planId) async {
    state = const PlanLoading();
    try {
      final plan = await _repository.getPlanById(planId);
      if (plan != null) {
        state = PlanDetailLoaded(plan);
      } else {
        state = const PlanError('Plan not found');
      }
    } catch (e) {
      state = PlanError(_mapError(e));
    }
  }

  /// Creates a new training plan.
  Future<bool> createPlan({
    required String coachId,
    required String name,
    String? description,
    int durationDays = 7,
    bool isTemplate = false,
    List<ActivityEntity> activities = const [],
  }) async {
    state = const PlanLoading();
    try {
      final plan = TrainingPlanEntity(
        id: '', // Will be set by Firestore
        coachId: coachId,
        name: name,
        description: description,
        durationDays: durationDays,
        activities: activities,
        createdAt: DateTime.now(),
        isTemplate: isTemplate,
      );

      final created = await _repository.createPlan(plan);
      state = PlanOperationSuccess(
        message: 'Plan created successfully',
        plan: created,
      );
      return true;
    } catch (e) {
      state = PlanError(_mapError(e));
      return false;
    }
  }

  /// Updates an existing training plan.
  Future<bool> updatePlan(TrainingPlanEntity plan) async {
    state = const PlanLoading();
    try {
      final updated = await _repository.updatePlan(plan);
      state = PlanOperationSuccess(
        message: 'Plan updated successfully',
        plan: updated,
      );
      return true;
    } catch (e) {
      state = PlanError(_mapError(e));
      return false;
    }
  }

  /// Deletes a training plan.
  Future<bool> deletePlan(String planId) async {
    state = const PlanLoading();
    try {
      await _repository.deletePlan(planId);
      state = const PlanOperationSuccess(message: 'Plan deleted successfully');
      return true;
    } catch (e) {
      state = PlanError(_mapError(e));
      return false;
    }
  }

  /// Adds an activity to a plan.
  Future<bool> addActivity(String planId, ActivityEntity activity) async {
    try {
      await _repository.addActivity(planId, activity);
      return true;
    } catch (e) {
      state = PlanError(_mapError(e));
      return false;
    }
  }

  /// Updates an activity in a plan.
  Future<bool> updateActivity(String planId, ActivityEntity activity) async {
    try {
      await _repository.updateActivity(planId, activity);
      return true;
    } catch (e) {
      state = PlanError(_mapError(e));
      return false;
    }
  }

  /// Removes an activity from a plan.
  Future<bool> removeActivity(String planId, String activityId) async {
    try {
      await _repository.removeActivity(planId, activityId);
      return true;
    } catch (e) {
      state = PlanError(_mapError(e));
      return false;
    }
  }

  /// Clears any error state.
  void clearError() {
    if (state is PlanError) {
      state = const PlanInitial();
    }
  }

  /// Maps exceptions to user-friendly messages.
  String _mapError(dynamic e) {
    final message = e.toString();
    if (message.contains('permission-denied')) {
      return 'You do not have permission to perform this action';
    }
    if (message.contains('not-found')) {
      return 'The requested plan was not found';
    }
    if (message.contains('network')) {
      return 'Network error. Please check your connection';
    }
    return 'An error occurred. Please try again.';
  }
}

/// Notifier for managing plan assignments.
class AssignmentNotifier extends StateNotifier<AssignmentState> {
  /// Creates a new [AssignmentNotifier].
  AssignmentNotifier(this._repository) : super(const AssignmentInitial());

  final PlanRepository _repository;

  /// Assigns a plan to an athlete.
  Future<bool> assignPlan({
    required String planId,
    required String athleteId,
    required String coachId,
    required DateTime startDate,
    DateTime? endDate,
    String? planName,
    String? athleteName,
  }) async {
    state = const AssignmentLoading();
    try {
      final assignment = PlanAssignmentEntity(
        id: '', // Will be set by Firestore
        planId: planId,
        athleteId: athleteId,
        coachId: coachId,
        assignedAt: DateTime.now(),
        startDate: startDate,
        endDate: endDate,
        planName: planName,
        athleteName: athleteName,
      );

      final created = await _repository.assignPlan(assignment);
      state = AssignmentOperationSuccess(
        message: 'Plan assigned successfully',
        assignment: created,
      );
      return true;
    } catch (e) {
      state = AssignmentError(_mapError(e));
      return false;
    }
  }

  /// Cancels an assignment.
  Future<bool> cancelAssignment(String assignmentId) async {
    state = const AssignmentLoading();
    try {
      await _repository.cancelAssignment(assignmentId);
      state = const AssignmentOperationSuccess(message: 'Assignment cancelled');
      return true;
    } catch (e) {
      state = AssignmentError(_mapError(e));
      return false;
    }
  }

  /// Marks an assignment as complete.
  Future<bool> completeAssignment(String assignmentId) async {
    state = const AssignmentLoading();
    try {
      await _repository.completeAssignment(assignmentId);
      state = const AssignmentOperationSuccess(message: 'Assignment completed');
      return true;
    } catch (e) {
      state = AssignmentError(_mapError(e));
      return false;
    }
  }

  /// Updates completion rate for an assignment.
  Future<bool> updateCompletionRate(String assignmentId, double rate) async {
    try {
      await _repository.updateCompletionRate(assignmentId, rate);
      return true;
    } catch (e) {
      state = AssignmentError(_mapError(e));
      return false;
    }
  }

  /// Clears any error state.
  void clearError() {
    if (state is AssignmentError) {
      state = const AssignmentInitial();
    }
  }

  /// Maps exceptions to user-friendly messages.
  String _mapError(dynamic e) {
    final message = e.toString();
    if (message.contains('permission-denied')) {
      return 'You do not have permission to perform this action';
    }
    if (message.contains('not-found')) {
      return 'The requested assignment was not found';
    }
    return 'An error occurred. Please try again.';
  }
}

/// Provider for the assignment state notifier.
final assignmentProvider =
    StateNotifierProvider<AssignmentNotifier, AssignmentState>((ref) {
      final repository = ref.watch(planRepositoryProvider);
      return AssignmentNotifier(repository);
    });
