/// General application constants.
///
/// All app-wide constants should be defined here.
abstract class AppConstants {
  /// Application name
  static const String appName = 'PushUp';

  /// Application version
  static const String appVersion = '1.0.0';

  /// Minimum password length
  static const int minPasswordLength = 8;

  /// Maximum plan name length
  static const int maxPlanNameLength = 100;

  /// Maximum activity note length
  static const int maxNoteLength = 500;

  /// Default animation duration
  static const Duration defaultAnimationDuration = Duration(milliseconds: 300);

  /// Snackbar display duration
  static const Duration snackbarDuration = Duration(seconds: 3);

  /// Debounce duration for search
  static const Duration searchDebounceDuration = Duration(milliseconds: 500);

  /// Session timeout duration
  static const Duration sessionTimeout = Duration(hours: 24);

  /// Maximum effort level (1-10 scale)
  static const int maxEffortLevel = 10;

  /// Minimum effort level
  static const int minEffortLevel = 1;

  /// Days in a week
  static const int daysInWeek = 7;

  /// Streak threshold (days without activity before streak breaks)
  static const int streakThresholdDays = 1;

  /// Status thresholds for athlete tracking
  static const double statusOnTrackThreshold = 0.8; // 80%+
  static const double statusNeedsAttentionThreshold = 0.5; // 50-80%
  // Below 50% is "falling behind"
}

/// User role constants
enum UserRole {
  coach('coach'),
  athlete('athlete');

  const UserRole(this.value);
  final String value;

  static UserRole fromString(String value) {
    return UserRole.values.firstWhere(
      (role) => role.value == value,
      orElse: () => UserRole.athlete,
    );
  }
}

/// Activity status constants
enum ActivityStatus {
  notStarted('not_started'),
  inProgress('in_progress'),
  completed('completed'),
  missed('missed');

  const ActivityStatus(this.value);
  final String value;
}

/// Plan assignment status
enum AssignmentStatus {
  active('active'),
  completed('completed'),
  cancelled('cancelled');

  const AssignmentStatus(this.value);
  final String value;
}

/// Notification types
enum NotificationType {
  planAssigned('plan_assigned'),
  workoutCompleted('workout_completed'),
  motivation('motivation'),
  reminder('reminder');

  const NotificationType(this.value);
  final String value;
}
