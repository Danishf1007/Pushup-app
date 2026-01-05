import '../../domain/entities/activity_entity.dart';

/// Data model for [ActivityEntity] with Firestore serialization.
class ActivityModel {
  /// Creates a new [ActivityModel].
  const ActivityModel({
    required this.id,
    required this.name,
    required this.type,
    required this.dayOfWeek,
    this.targetDuration,
    this.instructions,
    this.order = 0,
  });

  final String id;
  final String name;
  final String type;
  final int dayOfWeek;
  final int? targetDuration;
  final String? instructions;
  final int order;

  /// Creates from a JSON map.
  factory ActivityModel.fromJson(Map<String, dynamic> json) {
    return ActivityModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      type: json['type'] as String? ?? ActivityTypes.custom,
      dayOfWeek: json['dayOfWeek'] as int? ?? 1,
      targetDuration: json['targetDuration'] as int?,
      instructions: json['instructions'] as String?,
      order: json['order'] as int? ?? 0,
    );
  }

  /// Creates from an entity.
  factory ActivityModel.fromEntity(ActivityEntity entity) {
    return ActivityModel(
      id: entity.id,
      name: entity.name,
      type: entity.type,
      dayOfWeek: entity.dayOfWeek,
      targetDuration: entity.targetDuration,
      instructions: entity.instructions,
      order: entity.order,
    );
  }

  /// Converts to a JSON map for Firestore.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'dayOfWeek': dayOfWeek,
      'targetDuration': targetDuration,
      'instructions': instructions,
      'order': order,
    };
  }

  /// Converts to an entity.
  ActivityEntity toEntity() {
    return ActivityEntity(
      id: id,
      name: name,
      type: type,
      dayOfWeek: dayOfWeek,
      targetDuration: targetDuration,
      instructions: instructions,
      order: order,
    );
  }
}
