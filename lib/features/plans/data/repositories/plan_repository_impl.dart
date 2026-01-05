import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/entities.dart';
import '../../domain/repositories/plan_repository.dart';
import '../models/models.dart';

/// Firebase implementation of [PlanRepository].
class PlanRepositoryImpl implements PlanRepository {
  /// Creates a new [PlanRepositoryImpl].
  PlanRepositoryImpl({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  /// Reference to the training plans collection.
  CollectionReference<Map<String, dynamic>> get _plansRef =>
      _firestore.collection('trainingPlans');

  /// Reference to the assignments collection.
  CollectionReference<Map<String, dynamic>> get _assignmentsRef =>
      _firestore.collection('plan_assignments');

  // ============== Training Plans ==============

  @override
  Future<TrainingPlanEntity> createPlan(TrainingPlanEntity plan) async {
    final model = TrainingPlanModel.fromEntity(plan);
    final docRef = await _plansRef.add(model.toJson());
    return plan.copyWith(id: docRef.id);
  }

  @override
  Future<TrainingPlanEntity> updatePlan(TrainingPlanEntity plan) async {
    final model = TrainingPlanModel.fromEntity(
      plan.copyWith(updatedAt: DateTime.now()),
    );

    final jsonData = model.toJson();

    await _plansRef.doc(plan.id).update(jsonData);

    return model.toEntity();
  }

  @override
  Future<void> deletePlan(String planId) async {
    await _plansRef.doc(planId).delete();
  }

  @override
  Future<TrainingPlanEntity?> getPlanById(String planId) async {
    final doc = await _plansRef.doc(planId).get();
    if (!doc.exists) return null;
    return TrainingPlanModel.fromFirestore(doc).toEntity();
  }

  @override
  Future<List<TrainingPlanEntity>> getPlansByCoach(String coachId) async {
    final query = await _plansRef.where('coachId', isEqualTo: coachId).get();

    return query.docs
        .map((doc) => TrainingPlanModel.fromFirestore(doc).toEntity())
        .toList();
  }

  @override
  Stream<List<TrainingPlanEntity>> watchPlansByCoach(String coachId) {
    return _plansRef
        .where('coachId', isEqualTo: coachId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => TrainingPlanModel.fromFirestore(doc).toEntity())
              .toList(),
        );
  }

  @override
  Future<List<TrainingPlanEntity>> getTemplatePlans(String coachId) async {
    final query = await _plansRef.where('coachId', isEqualTo: coachId).get();

    // Filter templates in memory to avoid composite index
    final templateDocs = query.docs
        .where((doc) => doc.data()['isTemplate'] == true)
        .toList();

    return templateDocs
        .map((doc) => TrainingPlanModel.fromFirestore(doc).toEntity())
        .toList();
  }

  // ============== Plan Assignments ==============

  @override
  Future<PlanAssignmentEntity> assignPlan(
    PlanAssignmentEntity assignment,
  ) async {
    final model = PlanAssignmentModel.fromEntity(assignment);
    final docRef = await _assignmentsRef.add(model.toJson());
    return assignment.copyWith(id: docRef.id);
  }

  @override
  Future<PlanAssignmentEntity> updateAssignment(
    PlanAssignmentEntity assignment,
  ) async {
    final model = PlanAssignmentModel.fromEntity(assignment);
    await _assignmentsRef.doc(assignment.id).update(model.toJson());
    return model.toEntity();
  }

  @override
  Future<void> cancelAssignment(String assignmentId) async {
    await _assignmentsRef.doc(assignmentId).update({'status': 'cancelled'});
  }

  @override
  Future<void> completeAssignment(String assignmentId) async {
    await _assignmentsRef.doc(assignmentId).update({
      'status': 'completed',
      'completionRate': 1.0,
    });
  }

  @override
  Future<List<PlanAssignmentEntity>> getAssignmentsByAthlete(
    String athleteId,
  ) async {
    final query = await _assignmentsRef
        .where('athleteId', isEqualTo: athleteId)
        .get();

    return query.docs
        .map((doc) => PlanAssignmentModel.fromFirestore(doc).toEntity())
        .toList();
  }

  @override
  Future<List<PlanAssignmentEntity>> getAssignmentsByCoach(
    String coachId,
  ) async {
    final query = await _assignmentsRef
        .where('coachId', isEqualTo: coachId)
        .get();

    return query.docs
        .map((doc) => PlanAssignmentModel.fromFirestore(doc).toEntity())
        .toList();
  }

  @override
  Future<PlanAssignmentEntity?> getActiveAssignment(String athleteId) async {
    final query = await _assignmentsRef
        .where('athleteId', isEqualTo: athleteId)
        .get();

    // Filter for active status in memory
    final activeDocs = query.docs
        .where((doc) => doc.data()['status'] == 'active')
        .toList();

    if (activeDocs.isEmpty) return null;
    return PlanAssignmentModel.fromFirestore(activeDocs.first).toEntity();
  }

  @override
  Stream<List<PlanAssignmentEntity>> watchAssignmentsByAthlete(
    String athleteId,
  ) {
    return _assignmentsRef
        .where('athleteId', isEqualTo: athleteId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => PlanAssignmentModel.fromFirestore(doc).toEntity())
              .toList(),
        );
  }

  @override
  Stream<List<PlanAssignmentEntity>> watchAssignmentsByCoach(String coachId) {
    return _assignmentsRef
        .where('coachId', isEqualTo: coachId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => PlanAssignmentModel.fromFirestore(doc).toEntity())
              .toList(),
        );
  }

  @override
  Future<void> updateCompletionRate(String assignmentId, double rate) async {
    await _assignmentsRef.doc(assignmentId).update({'completionRate': rate});
  }

  // ============== Activities ==============

  @override
  Future<void> addActivity(String planId, ActivityEntity activity) async {
    final doc = await _plansRef.doc(planId).get();
    if (!doc.exists) return;

    final model = ActivityModel.fromEntity(activity);
    await _plansRef.doc(planId).update({
      'activities': FieldValue.arrayUnion([model.toJson()]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> updateActivity(String planId, ActivityEntity activity) async {
    final doc = await _plansRef.doc(planId).get();
    if (!doc.exists) return;

    final plan = TrainingPlanModel.fromFirestore(doc).toEntity();
    final updatedActivities = plan.activities.map((a) {
      if (a.id == activity.id) return activity;
      return a;
    }).toList();

    await _plansRef.doc(planId).update({
      'activities': updatedActivities
          .map((a) => ActivityModel.fromEntity(a).toJson())
          .toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> removeActivity(String planId, String activityId) async {
    final doc = await _plansRef.doc(planId).get();
    if (!doc.exists) return;

    final plan = TrainingPlanModel.fromFirestore(doc).toEntity();
    final updatedActivities = plan.activities
        .where((a) => a.id != activityId)
        .toList();

    await _plansRef.doc(planId).update({
      'activities': updatedActivities
          .map((a) => ActivityModel.fromEntity(a).toJson())
          .toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> reorderActivities(
    String planId,
    List<ActivityEntity> activities,
  ) async {
    await _plansRef.doc(planId).update({
      'activities': activities
          .map((a) => ActivityModel.fromEntity(a).toJson())
          .toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
