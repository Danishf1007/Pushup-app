import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/logger.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../plans/data/models/models.dart';
import '../../../plans/domain/entities/entities.dart';
import '../../domain/repositories/coach_repository.dart';

/// Firebase implementation of [CoachRepository].
///
/// Handles coach-specific operations for managing athletes
/// and their plan assignments.
class CoachRepositoryImpl implements CoachRepository {
  /// Creates a new [CoachRepositoryImpl].
  CoachRepositoryImpl({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  /// Collection reference for users.
  CollectionReference<Map<String, dynamic>> get _usersRef =>
      _firestore.collection('users');

  /// Collection reference for plan assignments.
  CollectionReference<Map<String, dynamic>> get _assignmentsRef =>
      _firestore.collection('plan_assignments');

  @override
  Future<List<UserEntity>> getAthletesByCoach(String coachId) async {
    try {
      AppLogger.info('Fetching athletes for coach: $coachId');

      final snapshot = await _usersRef
          .where('coachId', isEqualTo: coachId)
          .where('role', isEqualTo: UserRole.athlete.name)
          .get();

      final athletes = snapshot.docs
          .map((doc) => UserModel.fromFirestore(doc).toEntity())
          .toList();

      AppLogger.success('Found ${athletes.length} athletes');
      return athletes;
    } catch (e) {
      AppLogger.error('Error fetching athletes: $e');
      rethrow;
    }
  }

  @override
  Stream<List<UserEntity>> watchAthletesByCoach(String coachId) {
    return _usersRef
        .where('coachId', isEqualTo: coachId)
        .where('role', isEqualTo: UserRole.athlete.name)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => UserModel.fromFirestore(doc).toEntity())
              .toList(),
        );
  }

  @override
  Future<UserEntity?> getAthleteById(String athleteId) async {
    try {
      final doc = await _usersRef.doc(athleteId).get();
      if (!doc.exists) return null;

      final model = UserModel.fromFirestore(doc);
      if (model.role != UserRole.athlete.name) return null;

      return model.toEntity();
    } catch (e) {
      AppLogger.error('Error fetching athlete: $e');
      rethrow;
    }
  }

  @override
  Future<void> assignAthleteToCoach({
    required String athleteId,
    required String coachId,
  }) async {
    try {
      AppLogger.info('Assigning athlete $athleteId to coach $coachId');

      await _usersRef.doc(athleteId).update({'coachId': coachId});

      AppLogger.success('Athlete assigned to coach');
    } catch (e) {
      AppLogger.error('Error assigning athlete: $e');
      rethrow;
    }
  }

  @override
  Future<void> removeAthleteFromCoach(String athleteId) async {
    try {
      AppLogger.info('Removing athlete $athleteId from coach');

      await _usersRef.doc(athleteId).update({'coachId': FieldValue.delete()});

      AppLogger.success('Athlete removed from coach');
    } catch (e) {
      AppLogger.error('Error removing athlete: $e');
      rethrow;
    }
  }

  @override
  Stream<List<PlanAssignmentEntity>> watchAthleteAssignments(String athleteId) {
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
  Future<PlanAssignmentEntity?> getAthleteAssignment({
    required String athleteId,
    required String planId,
  }) async {
    try {
      final snapshot = await _assignmentsRef
          .where('athleteId', isEqualTo: athleteId)
          .where('planId', isEqualTo: planId)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      return PlanAssignmentModel.fromFirestore(snapshot.docs.first).toEntity();
    } catch (e) {
      AppLogger.error('Error fetching assignment: $e');
      rethrow;
    }
  }
}
