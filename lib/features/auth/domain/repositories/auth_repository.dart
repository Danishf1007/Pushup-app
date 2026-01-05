import '../../../../core/constants/app_constants.dart';
import '../entities/user_entity.dart';

/// Abstract repository interface for authentication operations.
///
/// This defines the contract for authentication operations
/// that must be implemented by the data layer.
abstract class AuthRepository {
  /// Signs in a user with email and password.
  ///
  /// Returns the authenticated [UserEntity] on success.
  /// Throws an exception on failure.
  Future<UserEntity> signInWithEmail({
    required String email,
    required String password,
  });

  /// Signs in a user with Google OAuth.
  ///
  /// Returns the authenticated [UserEntity] on success.
  /// Throws an exception on failure.
  Future<UserEntity> signInWithGoogle();

  /// Creates a new user account with email and password.
  ///
  /// Returns the created [UserEntity] on success.
  /// Throws an exception on failure.
  Future<UserEntity> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
    required UserRole role,
    String? coachId,
  });

  /// Signs out the current user.
  Future<void> signOut();

  /// Sends a password reset email to the specified address.
  Future<void> sendPasswordResetEmail(String email);

  /// Changes the password for the current user.
  ///
  /// Requires the current password for verification.
  /// Throws an exception if current password is incorrect or update fails.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  /// Gets the currently authenticated user.
  ///
  /// Returns null if no user is signed in.
  Future<UserEntity?> getCurrentUser();

  /// Stream of authentication state changes.
  ///
  /// Emits the current user when auth state changes,
  /// or null when the user signs out.
  Stream<UserEntity?> authStateChanges();

  /// Updates the current user's profile.
  Future<UserEntity> updateProfile({
    String? displayName,
    String? profilePicture,
  });

  /// Updates the athlete's coach ID.
  Future<void> updateCoachId(String userId, String coachId);

  /// Updates the user's FCM token for push notifications.
  Future<void> updateFcmToken(String token);

  /// Deletes the current user's account.
  Future<void> deleteAccount();
}
