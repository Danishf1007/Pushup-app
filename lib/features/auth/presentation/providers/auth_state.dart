import 'package:equatable/equatable.dart';

import '../../domain/entities/user_entity.dart';

/// Represents the authentication state of the app.
sealed class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// Initial authentication state (checking auth status).
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// Currently checking authentication status.
class AuthLoading extends AuthState {
  const AuthLoading();
}

/// User is authenticated.
class AuthAuthenticated extends AuthState {
  const AuthAuthenticated(this.user);

  /// The authenticated user.
  final UserEntity user;

  @override
  List<Object?> get props => [user];
}

/// User is not authenticated.
class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

/// Authentication error occurred.
class AuthError extends AuthState {
  const AuthError(this.message);

  /// Error message.
  final String message;

  @override
  List<Object?> get props => [message];
}
