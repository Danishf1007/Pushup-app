import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/activity_log_entity.dart';

/// Data model for [ActivityLogEntity] with Firestore serialization.
class ActivityLogModel {
  /// Creates a new [ActivityLogModel].
  const ActivityLogModel({
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

  final String id;
  final String athleteId;
  final String assignmentId;
  final String activityId;
  final String activityName;
  final DateTime completedAt;
  final int actualDuration;
  final double? distance;
  final int effortLevel;
  final String? notes;
  final String? photoUrl;
  final String coachId;

  /// Creates from Firestore document.
  factory ActivityLogModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ActivityLogModel(
      id: doc.id,
      athleteId: data['athleteId'] as String? ?? '',
      assignmentId: data['assignmentId'] as String? ?? '',
      activityId: data['activityId'] as String? ?? '',
      activityName: data['activityName'] as String? ?? '',
      completedAt:
          (data['completedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      actualDuration: data['actualDuration'] as int? ?? 0,
      distance: (data['distance'] as num?)?.toDouble(),
      effortLevel: data['effortLevel'] as int? ?? 5,
      notes: data['notes'] as String?,
      photoUrl: data['photoUrl'] as String?,
      coachId: data['coachId'] as String? ?? '',
    );
  }

  /// Creates from entity.
  factory ActivityLogModel.fromEntity(ActivityLogEntity entity) {
    return ActivityLogModel(
      id: entity.id,
      athleteId: entity.athleteId,
      assignmentId: entity.assignmentId,
      activityId: entity.activityId,
      activityName: entity.activityName,
      completedAt: entity.completedAt,
      actualDuration: entity.actualDuration,
      distance: entity.distance,
      effortLevel: entity.effortLevel,
      notes: entity.notes,
      photoUrl: entity.photoUrl,
      coachId: entity.coachId,
    );
  }

  /// Converts to Firestore JSON.
  Map<String, dynamic> toJson() {
    return {
      'athleteId': athleteId,
      'assignmentId': assignmentId,
      'activityId': activityId,
      'activityName': activityName,
      'completedAt': Timestamp.fromDate(completedAt),
      'actualDuration': actualDuration,
      'distance': distance,
      'effortLevel': effortLevel,
      'notes': notes,
      'photoUrl': photoUrl,
      'coachId': coachId,
    };
  }

  /// Converts to entity.
  ActivityLogEntity toEntity() {
    return ActivityLogEntity(
      id: id,
      athleteId: athleteId,
      assignmentId: assignmentId,
      activityId: activityId,
      activityName: activityName,
      completedAt: completedAt,
      actualDuration: actualDuration,
      distance: distance,
      effortLevel: effortLevel,
      notes: notes,
      photoUrl: photoUrl,
      coachId: coachId,
    );
  }
}
