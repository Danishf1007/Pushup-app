import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/plan_assignment_entity.dart';

/// Data model for [PlanAssignmentEntity] with Firestore serialization.
class PlanAssignmentModel {
  /// Creates a new [PlanAssignmentModel].
  const PlanAssignmentModel({
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

  final String id;
  final String planId;
  final String athleteId;
  final String coachId;
  final DateTime assignedAt;
  final DateTime startDate;
  final DateTime? endDate;
  final AssignmentStatus status;
  final double completionRate;
  final String? planName;
  final String? athleteName;

  /// Creates from a Firestore document.
  factory PlanAssignmentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return PlanAssignmentModel.fromJson(data, doc.id);
  }

  /// Creates from a JSON map with an optional ID.
  factory PlanAssignmentModel.fromJson(
    Map<String, dynamic> json, [
    String? id,
  ]) {
    return PlanAssignmentModel(
      id: id ?? json['id'] as String? ?? '',
      planId: json['planId'] as String? ?? '',
      athleteId: json['athleteId'] as String? ?? '',
      coachId: json['coachId'] as String? ?? '',
      assignedAt: _parseTimestamp(json['assignedAt']),
      startDate: _parseTimestamp(json['startDate']),
      endDate: json['endDate'] != null
          ? _parseTimestamp(json['endDate'])
          : null,
      status: _parseStatus(json['status']),
      completionRate: (json['completionRate'] as num?)?.toDouble() ?? 0.0,
      planName: json['planName'] as String?,
      athleteName: json['athleteName'] as String?,
    );
  }

  /// Creates from an entity.
  factory PlanAssignmentModel.fromEntity(PlanAssignmentEntity entity) {
    return PlanAssignmentModel(
      id: entity.id,
      planId: entity.planId,
      athleteId: entity.athleteId,
      coachId: entity.coachId,
      assignedAt: entity.assignedAt,
      startDate: entity.startDate,
      endDate: entity.endDate,
      status: entity.status,
      completionRate: entity.completionRate,
      planName: entity.planName,
      athleteName: entity.athleteName,
    );
  }

  /// Converts to a JSON map for Firestore.
  Map<String, dynamic> toJson() {
    return {
      'planId': planId,
      'athleteId': athleteId,
      'coachId': coachId,
      'assignedAt': Timestamp.fromDate(assignedAt),
      'startDate': Timestamp.fromDate(startDate),
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'status': status.value,
      'completionRate': completionRate,
      'planName': planName,
      'athleteName': athleteName,
    };
  }

  /// Converts to an entity.
  PlanAssignmentEntity toEntity() {
    return PlanAssignmentEntity(
      id: id,
      planId: planId,
      athleteId: athleteId,
      coachId: coachId,
      assignedAt: assignedAt,
      startDate: startDate,
      endDate: endDate,
      status: status,
      completionRate: completionRate,
      planName: planName,
      athleteName: athleteName,
    );
  }

  /// Helper to parse Firestore timestamps.
  static DateTime _parseTimestamp(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    } else if (value is DateTime) {
      return value;
    } else if (value is String) {
      return DateTime.parse(value);
    }
    return DateTime.now();
  }

  /// Helper to parse assignment status.
  static AssignmentStatus _parseStatus(dynamic value) {
    if (value is String) {
      return AssignmentStatus.values.firstWhere(
        (s) => s.value == value,
        orElse: () => AssignmentStatus.active,
      );
    }
    return AssignmentStatus.active;
  }
}
