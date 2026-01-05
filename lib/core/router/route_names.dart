/// Route name constants for PushUp app.
///
/// All route names should be defined here for type-safe navigation.
abstract class RouteNames {
  // ============== Auth Routes ==============
  static const String welcome = 'welcome';
  static const String login = 'login';
  static const String register = 'register';
  static const String forgotPassword = 'forgot-password';

  // ============== Coach Routes ==============
  static const String coachDashboard = 'coach-dashboard';
  static const String coachAthletes = 'coach-athletes';
  static const String coachAthleteDetail = 'coach-athlete-detail';
  static const String coachAnalytics = 'coach-analytics';
  static const String coachPlans = 'coach-plans';
  static const String coachPlanDetail = 'coach-plan-detail';
  static const String coachCreatePlan = 'coach-create-plan';
  static const String coachEditPlan = 'coach-edit-plan';
  static const String coachProfile = 'coach-profile';
  static const String coachAssignPlan = 'coach-assign-plan';
  static const String coachSendNotification = 'coach-send-notification';

  // ============== Athlete Routes ==============
  static const String athleteDashboard = 'athlete-dashboard';
  static const String athleteWorkouts = 'athlete-workouts';
  static const String athleteWorkoutDetail = 'athlete-workout-detail';
  static const String athleteLogActivity = 'athlete-log-activity';
  static const String athleteProgress = 'athlete-progress';
  static const String athleteProfile = 'athlete-profile';
  static const String athleteAchievements = 'athlete-achievements';

  // ============== Shared Routes ==============
  static const String notifications = 'notifications';
  static const String settings = 'settings';
  static const String helpSupport = 'help-support';
  static const String about = 'about';
  static const String devSeed = 'dev-seed';
  static const String conversations = 'conversations';
  static const String chat = 'chat';
}

/// Route paths for GoRouter configuration.
abstract class RoutePaths {
  // ============== Auth Paths ==============
  static const String welcome = '/welcome';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';

  // ============== Coach Paths ==============
  static const String coachDashboard = '/coach';
  static const String coachAthletes = '/coach/athletes';
  static const String coachAthleteDetail = '/coach/athletes/:athleteId';
  static const String coachAnalytics = '/coach/analytics';
  static const String coachPlans = '/coach/plans';
  static const String coachPlanDetail = '/coach/plans/:planId';
  static const String coachCreatePlan = '/coach/plans/create';
  static const String coachEditPlan = '/coach/plans/:planId/edit';
  static const String coachProfile = '/coach/profile';
  static const String coachAssignPlan = '/coach/plans/:planId/assign';
  static const String coachSendNotification =
      '/coach/athletes/:athleteId/notify';

  // ============== Athlete Paths ==============
  static const String athleteDashboard = '/athlete';
  static const String athleteWorkouts = '/athlete/workouts';
  static const String athleteWorkoutDetail = '/athlete/workouts/:activityId';
  static const String athleteLogActivity = '/athlete/workouts/:activityId/log';
  static const String athleteProgress = '/athlete/progress';
  static const String athleteProfile = '/athlete/profile';
  static const String athleteAchievements = '/athlete/achievements';

  // ============== Shared Paths ==============
  static const String notifications = '/notifications';
  static const String settings = '/settings';
  static const String helpSupport = '/help-support';
  static const String about = '/about';
  static const String devSeed = '/dev/seed';
  static const String conversations = '/messages';
  static const String chat = '/messages/:conversationId';
}
