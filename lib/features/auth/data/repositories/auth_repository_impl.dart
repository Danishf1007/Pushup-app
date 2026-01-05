import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/user_model.dart';

/// Firebase implementation of [AuthRepository].
///
/// Handles all authentication operations using Firebase Auth
/// and stores user data in Firestore.
class AuthRepositoryImpl implements AuthRepository {
  /// Creates a new [AuthRepositoryImpl].
  AuthRepositoryImpl({FirebaseAuth? firebaseAuth, FirebaseFirestore? firestore})
    : _auth = firebaseAuth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  /// Collection reference for users.
  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  @override
  Future<UserEntity> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      AppLogger.info('Attempting sign in for: $email');

      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (credential.user == null) {
        throw Exception('Sign in failed: No user returned');
      }

      final user = await _getUserFromFirestore(credential.user!.uid);
      AppLogger.success('User signed in: ${user.email}');
      return user;
    } on FirebaseAuthException catch (e) {
      AppLogger.error('Firebase Auth Error: ${e.code}');
      throw _mapFirebaseAuthError(e);
    } catch (e) {
      AppLogger.error('Sign in error: $e');
      rethrow;
    }
  }

  @override
  Future<UserEntity> signInWithGoogle() async {
    // TODO: Implement Google Sign In
    throw UnimplementedError('Google Sign In not yet implemented');
  }

  @override
  Future<UserEntity> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
    required UserRole role,
    String? coachId,
  }) async {
    try {
      AppLogger.info('Creating account for: $email as ${role.name}');

      // Create Firebase Auth user
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (credential.user == null) {
        throw Exception('Sign up failed: No user returned');
      }

      // Update display name in Firebase Auth
      await credential.user!.updateDisplayName(displayName);

      // Create user model
      final userModel = UserModel(
        id: credential.user!.uid,
        email: email.trim(),
        displayName: displayName,
        role: role.name,
        coachId: coachId, // Set coachId if provided (for athletes)
        createdAt: DateTime.now(),
        lastActive: DateTime.now(),
      );

      // Store in Firestore
      await _usersCollection.doc(credential.user!.uid).set(userModel.toJson());

      AppLogger.success('User created: ${userModel.email}');
      return userModel.toEntity();
    } on FirebaseAuthException catch (e) {
      AppLogger.error('Firebase Auth Error: ${e.code}');
      throw _mapFirebaseAuthError(e);
    } catch (e) {
      AppLogger.error('Sign up error: $e');
      rethrow;
    }
  }

  @override
  Future<void> signOut() async {
    try {
      AppLogger.info('Signing out user');
      await _auth.signOut();
      AppLogger.success('User signed out');
    } catch (e) {
      AppLogger.error('Sign out error: $e');
      rethrow;
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      AppLogger.info('Sending password reset email to: $email');
      await _auth.sendPasswordResetEmail(email: email.trim());
      AppLogger.success('Password reset email sent');
    } on FirebaseAuthException catch (e) {
      AppLogger.error('Firebase Auth Error: ${e.code}');
      throw _mapFirebaseAuthError(e);
    } catch (e) {
      AppLogger.error('Password reset error: $e');
      rethrow;
    }
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null || user.email == null) {
        throw Exception('No user is currently signed in');
      }

      AppLogger.info('Changing password for user: ${user.email}');

      // Re-authenticate user with current password
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);

      // Update to new password
      await user.updatePassword(newPassword);
      AppLogger.success('Password changed successfully');
    } on FirebaseAuthException catch (e) {
      AppLogger.error('Firebase Auth Error: ${e.code}');
      throw _mapFirebaseAuthError(e);
    } catch (e) {
      AppLogger.error('Change password error: $e');
      rethrow;
    }
  }

  @override
  Future<UserEntity?> getCurrentUser() async {
    try {
      final firebaseUser = _auth.currentUser;
      if (firebaseUser == null) {
        return null;
      }
      return await _getUserFromFirestore(firebaseUser.uid);
    } catch (e) {
      AppLogger.error('Get current user error: $e');
      // If user document not found, sign out the orphaned Auth user
      if (e.toString().contains('User document not found')) {
        AppLogger.warning('Signing out user with missing Firestore document');
        await _auth.signOut();
      }
      return null;
    }
  }

  @override
  Stream<UserEntity?> authStateChanges() {
    return _auth.authStateChanges().asyncMap((firebaseUser) async {
      if (firebaseUser == null) {
        return null;
      }
      try {
        return await _getUserFromFirestore(firebaseUser.uid);
      } catch (e) {
        AppLogger.error(
          'Auth state change error: $e',
        ); // If user document not found, sign out the orphaned Auth user
        if (e.toString().contains('User document not found')) {
          AppLogger.warning('Signing out user with missing Firestore document');
          await _auth.signOut();
        }
        return null;
      }
    });
  }

  @override
  Future<UserEntity> updateProfile({
    String? displayName,
    String? profilePicture,
  }) async {
    try {
      final firebaseUser = _auth.currentUser;
      if (firebaseUser == null) {
        throw Exception('No user signed in');
      }

      final updates = <String, dynamic>{
        'lastActive': FieldValue.serverTimestamp(),
      };

      if (displayName != null) {
        updates['displayName'] = displayName;
        await firebaseUser.updateDisplayName(displayName);
      }

      if (profilePicture != null) {
        updates['profilePicture'] = profilePicture;
        await firebaseUser.updatePhotoURL(profilePicture);
      }

      await _usersCollection.doc(firebaseUser.uid).update(updates);

      return await _getUserFromFirestore(firebaseUser.uid);
    } catch (e) {
      AppLogger.error('Update profile error: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateFcmToken(String token) async {
    try {
      final firebaseUser = _auth.currentUser;
      if (firebaseUser == null) {
        return;
      }

      await _usersCollection.doc(firebaseUser.uid).update({
        'fcmToken': token,
        'lastActive': FieldValue.serverTimestamp(),
      });

      AppLogger.debug('FCM token updated');
    } catch (e) {
      AppLogger.error('Update FCM token error: $e');
    }
  }

  @override
  Future<void> updateCoachId(String userId, String coachId) async {
    try {
      await _usersCollection.doc(userId).update({
        'coachId': coachId,
        'lastActive': FieldValue.serverTimestamp(),
      });
      AppLogger.success('Coach ID updated for user: $userId');
    } catch (e) {
      AppLogger.error('Update coach ID error: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteAccount() async {
    try {
      final firebaseUser = _auth.currentUser;
      if (firebaseUser == null) {
        throw Exception('No user signed in');
      }

      // Delete Firestore document
      await _usersCollection.doc(firebaseUser.uid).delete();

      // Delete Firebase Auth account
      await firebaseUser.delete();

      AppLogger.success('Account deleted');
    } catch (e) {
      AppLogger.error('Delete account error: $e');
      rethrow;
    }
  }

  /// Gets user data from Firestore.
  Future<UserEntity> _getUserFromFirestore(String uid) async {
    final doc = await _usersCollection.doc(uid).get();

    if (!doc.exists) {
      throw Exception('User document not found');
    }

    return UserModel.fromFirestore(doc).toEntity();
  }

  /// Maps Firebase Auth exceptions to user-friendly messages.
  Exception _mapFirebaseAuthError(FirebaseAuthException e) {
    switch (e.code) {
      // Sign-in errors
      case 'user-not-found':
        return Exception('No account found with this email');
      case 'wrong-password':
        return Exception('Incorrect password');
      case 'invalid-credential':
        return Exception(
          'Invalid email or password. Please check your credentials and try again',
        );
      case 'invalid-email':
        return Exception('Invalid email address');
      case 'user-disabled':
        return Exception('This account has been disabled');

      // Sign-up errors
      case 'email-already-in-use':
        return Exception('An account already exists with this email');
      case 'weak-password':
        return Exception(
          'Password is too weak. Please use at least 6 characters',
        );
      case 'operation-not-allowed':
        return Exception('Email/password accounts are not enabled');

      // General errors
      case 'too-many-requests':
        return Exception('Too many attempts. Please try again later');
      case 'network-request-failed':
        return Exception('Network error. Please check your connection');
      case 'requires-recent-login':
        return Exception('Please sign in again to complete this action');
      case 'account-exists-with-different-credential':
        return Exception(
          'An account already exists with the same email but different sign-in credentials',
        );

      // Default
      default:
        return Exception(
          e.message ?? 'An authentication error occurred. Please try again',
        );
    }
  }
}
