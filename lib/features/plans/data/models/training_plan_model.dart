import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/entities.dart';
import 'activity_model.dart';

/// Data model for [TrainingPlanEntity] with Firestore serialization.
class TrainingPlanModel {
  /// Creates a new [TrainingPlanModel].
  const TrainingPlanModel({
    required this.id,
    required this.coachId,
    required this.name,
    this.description,
    required this.durationDays,
    required this.activities,
    required this.createdAt,
    this.updatedAt,
    this.isTemplate = false,
  });

  final String id;
  final String coachId;
  final String name;
  final String? description;
  final int durationDays;
  final List<ActivityModel> activities;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isTemplate;

  /// Creates from a Firestore document.
  factory TrainingPlanModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return TrainingPlanModel.fromJson(data, doc.id);
  }

  /// Creates from a JSON map with an optional ID.
  factory TrainingPlanModel.fromJson(Map<String, dynamic> json, [String? id]) {
    final activitiesJson = json['activities'] as List<dynamic>? ?? [];

    return TrainingPlanModel(
      id: id ?? json['id'] as String? ?? '',
      coachId: json['coachId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      durationDays: json['durationDays'] as int? ?? 7,
      activities: activitiesJson
          .map((a) => ActivityModel.fromJson(a as Map<String, dynamic>))
          .toList(),
      createdAt: _parseTimestamp(json['createdAt']),
      updatedAt: json['updatedAt'] != null
          ? _parseTimestamp(json['updatedAt'])
          : null,
      isTemplate: json['isTemplate'] as bool? ?? false,
    );
  }

  /// Creates from an entity.
  factory TrainingPlanModel.fromEntity(TrainingPlanEntity entity) {
    return TrainingPlanModel(
      id: entity.id,
      coachId: entity.coachId,
      name: entity.name,
      description: entity.description,
      durationDays: entity.durationDays,
      activities: entity.activities
          .map((a) => ActivityModel.fromEntity(a))
          .toList(),
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      isTemplate: entity.isTemplate,
    );
  }

  /// Converts to a JSON map for Firestore.
  Map<String, dynamic> toJson() {
    return {
      'coachId': coachId,
      'name': name,
      'description': description,
      'durationDays': durationDays,
      'activities': activities.map((a) => a.toJson()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'isTemplate': isTemplate,
    };
  }

  /// Converts to an entity.
  TrainingPlanEntity toEntity() {
    return TrainingPlanEntity(
      id: id,
      coachId: coachId,
      name: name,
      description: description,
      durationDays: durationDays,
      activities: activities.map((a) => a.toEntity()).toList(),
      createdAt: createdAt,
      updatedAt: updatedAt,
      isTemplate: isTemplate,
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
}
