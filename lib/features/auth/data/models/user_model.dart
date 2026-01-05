import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/user_entity.dart';

/// User data model for Firestore serialization.
///
/// This model handles conversion between Firestore documents
/// and the domain [UserEntity].
class UserModel {
  /// Creates a new [UserModel].
  const UserModel({
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

  /// Unique user identifier.
  final String id;

  /// User's email address.
  final String email;

  /// User's display name.
  final String displayName;

  /// User's role as string.
  final String role;

  /// URL to profile picture.
  final String? profilePicture;

  /// Coach ID for athletes.
  final String? coachId;

  /// Account creation timestamp.
  final DateTime createdAt;

  /// Last activity timestamp.
  final DateTime? lastActive;

  /// FCM token for notifications.
  final String? fcmToken;

  /// Creates a [UserModel] from Firestore document.
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      email: data['email'] as String? ?? '',
      displayName: data['displayName'] as String? ?? '',
      role: data['role'] as String? ?? 'athlete',
      profilePicture: data['profilePicture'] as String?,
      coachId: data['coachId'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastActive: (data['lastActive'] as Timestamp?)?.toDate(),
      fcmToken: data['fcmToken'] as String?,
    );
  }

  /// Creates a [UserModel] from JSON map.
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '',
      role: json['role'] as String? ?? 'athlete',
      profilePicture: json['profilePicture'] as String?,
      coachId: json['coachId'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      lastActive: json['lastActive'] != null
          ? DateTime.parse(json['lastActive'] as String)
          : null,
      fcmToken: json['fcmToken'] as String?,
    );
  }

  /// Creates a [UserModel] from [UserEntity].
  factory UserModel.fromEntity(UserEntity entity) {
    return UserModel(
      id: entity.id,
      email: entity.email,
      displayName: entity.displayName,
      role: entity.role.name,
      profilePicture: entity.profilePicture,
      coachId: entity.coachId,
      createdAt: entity.createdAt,
      lastActive: entity.lastActive,
      fcmToken: entity.fcmToken,
    );
  }

  /// Converts to JSON map for Firestore.
  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'displayName': displayName,
      'role': role,
      'profilePicture': profilePicture,
      'coachId': coachId,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastActive': lastActive != null ? Timestamp.fromDate(lastActive!) : null,
      'fcmToken': fcmToken,
    };
  }

  /// Converts to [UserEntity] for domain layer.
  UserEntity toEntity() {
    return UserEntity(
      id: id,
      email: email,
      displayName: displayName,
      role: UserRole.values.firstWhere(
        (r) => r.name == role,
        orElse: () => UserRole.athlete,
      ),
      profilePicture: profilePicture,
      coachId: coachId,
      createdAt: createdAt,
      lastActive: lastActive,
      fcmToken: fcmToken,
    );
  }

  /// Creates a copy with modified fields.
  UserModel copyWith({
    String? id,
    String? email,
    String? displayName,
    String? role,
    String? profilePicture,
    String? coachId,
    DateTime? createdAt,
    DateTime? lastActive,
    String? fcmToken,
  }) {
    return UserModel(
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
}
