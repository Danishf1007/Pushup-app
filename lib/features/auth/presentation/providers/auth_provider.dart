import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/push_notification_service.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_state.dart';

/// Provider for the [AuthRepository] implementation.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl();
});

/// Provider for the current user stream.
///
/// Listens to auth state changes and provides the current user.
final authStateChangesProvider = StreamProvider<UserEntity?>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return repository.authStateChanges();
});

/// Provider for the authentication state notifier.
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthNotifier(repository);
});

/// Provider for the current authenticated user.
///
/// Returns null if no user is signed in.
final currentUserProvider = Provider<UserEntity?>((ref) {
  final authState = ref.watch(authProvider);
  if (authState is AuthAuthenticated) {
    return authState.user;
  }
  return null;
});

/// Provider that checks if user is authenticated.
final isAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authProvider);
  return authState is AuthAuthenticated;
});

/// Provider that returns the current user's role.
final userRoleProvider = Provider<UserRole?>((ref) {
  final user = ref.watch(currentUserProvider);
  return user?.role;
});

/// Notifier for managing authentication state.
class AuthNotifier extends StateNotifier<AuthState> {
  /// Creates a new [AuthNotifier].
  AuthNotifier(this._repository) : super(const AuthInitial()) {
    _initialize();
  }

  final AuthRepository _repository;

  /// Initializes the auth state by checking current user.
  Future<void> _initialize() async {
    state = const AuthLoading();
    try {
      final user = await _repository.getCurrentUser();
      if (user != null) {
        // Set user for push notifications
        await PushNotificationService.instance.setUser(user.id);
        state = AuthAuthenticated(user);
      } else {
        state = const AuthUnauthenticated();
      }
    } catch (e) {
      state = const AuthUnauthenticated();
    }
  }

  /// Signs in with email and password.
  Future<bool> signInWithEmail({
    required String email,
    required String password,
  }) async {
    state = const AuthLoading();
    try {
      final user = await _repository.signInWithEmail(
        email: email,
        password: password,
      );
      // Set user for push notifications
      await PushNotificationService.instance.setUser(user.id);
      state = AuthAuthenticated(user);
      return true;
    } catch (e) {
      final errorMessage = e.toString().replaceAll('Exception: ', '');
      state = AuthError(errorMessage);
      return false;
    }
  }

  /// Signs up with email and password.
  Future<bool> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
    required UserRole role,
    String? coachId,
  }) async {
    state = const AuthLoading();
    try {
      final user = await _repository.signUpWithEmail(
        email: email,
        password: password,
        displayName: displayName,
        role: role,
        coachId: coachId,
      );
      // Set user for push notifications
      await PushNotificationService.instance.setUser(user.id);
      state = AuthAuthenticated(user);
      return true;
    } catch (e) {
      state = AuthError(e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }

  /// Signs out the current user.
  Future<void> signOut() async {
    state = const AuthLoading();
    try {
      // Clear user from push notifications
      await PushNotificationService.instance.clearUser();
      await _repository.signOut();
      state = const AuthUnauthenticated();
    } catch (e) {
      state = AuthError(e.toString().replaceAll('Exception: ', ''));
    }
  }

  /// Sends a password reset email.
  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      await _repository.sendPasswordResetEmail(email);
      return true;
    } catch (e) {
      state = AuthError(e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }

  /// Changes the user's password.
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _repository.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      return true;
    } catch (e) {
      state = AuthError(e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }

  /// Updates the user profile.
  Future<bool> updateProfile({
    String? displayName,
    String? profilePicture,
  }) async {
    if (state is! AuthAuthenticated) return false;

    try {
      final updatedUser = await _repository.updateProfile(
        displayName: displayName,
        profilePicture: profilePicture,
      );
      state = AuthAuthenticated(updatedUser);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Updates the athlete's coach ID.
  Future<void> updateCoachId(String coachId) async {
    if (state is! AuthAuthenticated) {
      throw Exception('User not authenticated');
    }

    final currentUser = (state as AuthAuthenticated).user;

    // Update in Firestore
    await _repository.updateCoachId(currentUser.id, coachId);

    // Refresh user data
    final updatedUser = await _repository.getCurrentUser();
    if (updatedUser != null) {
      state = AuthAuthenticated(updatedUser);
    }
  }

  /// Clears any error state and returns to unauthenticated.
  void clearError() {
    if (state is AuthError) {
      state = const AuthUnauthenticated();
    }
  }
}
