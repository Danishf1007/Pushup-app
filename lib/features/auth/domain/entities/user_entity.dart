import 'package:equatable/equatable.dart';

import '../../../../core/constants/app_constants.dart';

/// User entity representing a user in the domain layer.
///
/// This is a clean, immutable representation of a user
/// without any framework-specific dependencies.
class UserEntity extends Equatable {
  /// Creates a new [UserEntity].
  const UserEntity({
    required this.id,
    required this.email,
    required this.displayName,
    required this.role,
    this.profilePicture,
    this.coachId,
    required this.createdAt,
    this.lastActive,
    this.fcmToken,
  });

  /// Unique user identifier (Firebase UID).
  final String id;

  /// User's email address.
  final String email;

  /// User's display name.
  final String displayName;

  /// User's role (coach or athlete).
  final UserRole role;

  /// URL to user's profile picture.
  final String? profilePicture;

  /// Coach ID for athletes (null for coaches).
  final String? coachId;

  /// Timestamp when user was created.
  final DateTime createdAt;

  /// Timestamp of last activity.
  final DateTime? lastActive;

  /// Firebase Cloud Messaging token for push notifications.
  final String? fcmToken;

  /// Whether the user is a coach.
  bool get isCoach => role == UserRole.coach;

  /// Whether the user is an athlete.
  bool get isAthlete => role == UserRole.athlete;

  /// Creates a copy with modified fields.
  UserEntity copyWith({
    String? id,
    String? email,
    String? displayName,
    UserRole? role,
    String? profilePicture,
    String? coachId,
    DateTime? createdAt,
    DateTime? lastActive,
    String? fcmToken,
  }) {
    return UserEntity(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      profilePicture: profilePicture ?? this.profilePicture,
      coachId: coachId ?? this.coachId,
      createdAt: createdAt ?? this.createdAt,
      lastActive: lastActive ?? this.lastActive,
      fcmToken: fcmToken ?? this.fcmToken,
    );
  }

  @override
  List<Object?> get props => [
    id,
    email,
    displayName,
    role,
    profilePicture,
    coachId,
    createdAt,
    lastActive,
    fcmToken,
  ];
}
