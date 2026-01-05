import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/achievements/presentation/screens/screens.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/providers/auth_state.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/welcome_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/profile_screen.dart';
import '../../features/athlete/presentation/screens/athlete_dashboard_screen.dart';
import '../../features/athlete/presentation/screens/log_activity_screen.dart';
import '../../features/athlete/presentation/screens/progress_screen.dart';
import '../../features/coach/presentation/screens/screens.dart';
import '../../features/dev/dev_seed_screen.dart';
import '../../features/notifications/presentation/screens/screens.dart';
import '../../features/messaging/presentation/screens/screens.dart';
import '../../features/plans/presentation/screens/screens.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/settings/presentation/screens/notification_settings_screen.dart';
import '../../features/settings/presentation/screens/help_support_screen.dart';
import '../../features/settings/presentation/screens/about_screen.dart';
import '../constants/app_constants.dart';
import 'route_names.dart';

/// Auth notifier for GoRouter refresh
class _AuthNotifier extends ChangeNotifier {
  _AuthNotifier(this._ref) {
    _ref.listen<AuthState>(authProvider, (previous, next) {
      // Only notify for meaningful auth state changes, not errors
      if (previous.runtimeType != next.runtimeType) {
        // Don't trigger router rebuild on error states
        if (next is! AuthError) {
          notifyListeners();
        }
      }
    });
  }

  final Ref _ref;
}

/// Provider for the app router.
///
/// This provider is used to access the GoRouter instance throughout the app.
final appRouterProvider = Provider<GoRouter>((ref) {
  final notifier = _AuthNotifier(ref);

  return GoRouter(
    initialLocation: RoutePaths.welcome,
    debugLogDiagnostics: true,
    refreshListenable: notifier,
    routes: _routes,
    errorBuilder: (context, state) => _ErrorScreen(error: state.error),
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final isLoading = authState is AuthLoading || authState is AuthInitial;
      final isAuthError = authState is AuthError;
      final isAuthenticated = authState is AuthAuthenticated;
      final isUnauthenticated = authState is AuthUnauthenticated;

      final isAuthRoute =
          state.matchedLocation == RoutePaths.login ||
          state.matchedLocation == RoutePaths.register ||
          state.matchedLocation == RoutePaths.welcome ||
          state.matchedLocation == RoutePaths.forgotPassword;

      // Allow dev routes to bypass auth
      final isDevRoute = state.matchedLocation.startsWith('/dev');

      // Don't redirect while loading
      if (isLoading) {
        return null;
      }

      // Allow dev routes without auth
      if (isDevRoute) {
        return null;
      }

      // Don't redirect if there's an auth error (stay on current page to show error)
      if (isAuthError) {
        return null;
      }

      // If not authenticated and trying to access protected route
      if (!isAuthenticated && !isAuthRoute) {
        return RoutePaths.welcome;
      }

      // If authenticated and trying to access auth route
      if (isAuthenticated && isAuthRoute) {
        final user = (authState as AuthAuthenticated).user;
        final destination = user.role == UserRole.coach
            ? RoutePaths.coachDashboard
            : RoutePaths.athleteDashboard;
        return destination;
      }

      return null;
    },
  );
});

/// All app routes
final List<RouteBase> _routes = [
  // ============== Auth Routes ==============
  GoRoute(
    path: RoutePaths.welcome,
    name: RouteNames.welcome,
    builder: (context, state) => const WelcomeScreen(),
  ),
  GoRoute(
    path: RoutePaths.login,
    name: RouteNames.login,
    builder: (context, state) => const LoginScreen(),
  ),
  GoRoute(
    path: RoutePaths.register,
    name: RouteNames.register,
    builder: (context, state) => const RegisterScreen(),
  ),
  GoRoute(
    path: RoutePaths.forgotPassword,
    name: RouteNames.forgotPassword,
    builder: (context, state) => const ForgotPasswordScreen(),
  ),

  // ============== Coach Routes ==============
  GoRoute(
    path: RoutePaths.coachDashboard,
    name: RouteNames.coachDashboard,
    builder: (context, state) => const CoachDashboardScreen(),
  ),
  GoRoute(
    path: RoutePaths.coachPlans,
    name: RouteNames.coachPlans,
    builder: (context, state) => const PlansListScreen(),
  ),
  GoRoute(
    path: RoutePaths.coachCreatePlan,
    name: RouteNames.coachCreatePlan,
    builder: (context, state) => const CreateEditPlanScreen(),
  ),
  GoRoute(
    path: RoutePaths.coachPlanDetail,
    name: RouteNames.coachPlanDetail,
    builder: (context, state) {
      final planId = state.pathParameters['planId']!;
      return PlanDetailScreen(planId: planId);
    },
  ),
  GoRoute(
    path: RoutePaths.coachEditPlan,
    name: RouteNames.coachEditPlan,
    builder: (context, state) {
      final planId = state.pathParameters['planId']!;
      return CreateEditPlanScreen(planId: planId);
    },
  ),
  GoRoute(
    path: RoutePaths.coachAthletes,
    name: RouteNames.coachAthletes,
    builder: (context, state) => const AthletesListScreen(),
  ),
  GoRoute(
    path: RoutePaths.coachAthleteDetail,
    name: RouteNames.coachAthleteDetail,
    builder: (context, state) {
      final athleteId = state.pathParameters['athleteId']!;
      return AthleteDetailScreen(athleteId: athleteId);
    },
  ),
  GoRoute(
    path: RoutePaths.coachAssignPlan,
    name: RouteNames.coachAssignPlan,
    builder: (context, state) {
      final planId = state.pathParameters['planId']!;
      return AssignPlanScreen(planId: planId);
    },
  ),
  GoRoute(
    path: RoutePaths.coachAnalytics,
    name: RouteNames.coachAnalytics,
    builder: (context, state) => const CoachAnalyticsScreen(),
  ),
  GoRoute(
    path: RoutePaths.coachProfile,
    name: RouteNames.coachProfile,
    builder: (context, state) => const ProfileScreen(),
  ),

  // ============== Athlete Routes ==============
  GoRoute(
    path: RoutePaths.athleteDashboard,
    name: RouteNames.athleteDashboard,
    builder: (context, state) => const AthleteDashboardScreen(),
  ),
  GoRoute(
    path: RoutePaths.athleteLogActivity,
    name: RouteNames.athleteLogActivity,
    builder: (context, state) {
      final activityId = state.pathParameters['activityId']!;
      return LogActivityScreen(activityId: activityId);
    },
  ),
  GoRoute(
    path: RoutePaths.athleteProgress,
    name: RouteNames.athleteProgress,
    builder: (context, state) => const ProgressScreen(),
  ),
  GoRoute(
    path: RoutePaths.athleteAchievements,
    name: RouteNames.athleteAchievements,
    builder: (context, state) => const AchievementsScreen(),
  ),
  GoRoute(
    path: RoutePaths.athleteProfile,
    name: RouteNames.athleteProfile,
    builder: (context, state) => const ProfileScreen(),
  ),

  // ============== Shared Routes ==============
  GoRoute(
    path: RoutePaths.notifications,
    name: RouteNames.notifications,
    builder: (context, state) => const NotificationCenterScreen(),
  ),
  GoRoute(
    path: RoutePaths.coachSendNotification,
    name: RouteNames.coachSendNotification,
    builder: (context, state) {
      final athleteId = state.pathParameters['athleteId'];
      return SendNotificationScreen(athleteId: athleteId);
    },
  ),

  // ============== Dev Routes ==============
  GoRoute(
    path: RoutePaths.devSeed,
    name: RouteNames.devSeed,
    builder: (context, state) => const DevSeedScreen(),
  ),

  // ============== Settings Routes ==============
  GoRoute(
    path: RoutePaths.settings,
    name: RouteNames.settings,
    builder: (context, state) => const SettingsScreen(),
  ),
  GoRoute(
    path: RoutePaths.notificationSettings,
    name: RouteNames.notificationSettings,
    builder: (context, state) => const NotificationSettingsScreen(),
  ),
  GoRoute(
    path: RoutePaths.helpSupport,
    name: RouteNames.helpSupport,
    builder: (context, state) => const HelpSupportScreen(),
  ),
  GoRoute(
    path: RoutePaths.about,
    name: RouteNames.about,
    builder: (context, state) => const AboutScreen(),
  ),

  // ============== Messaging Routes ==============
  GoRoute(
    path: RoutePaths.conversations,
    name: RouteNames.conversations,
    builder: (context, state) => const ConversationsScreen(),
  ),
  GoRoute(
    path: RoutePaths.chat,
    name: RouteNames.chat,
    builder: (context, state) {
      final conversationId = state.pathParameters['conversationId']!;
      return ChatScreen(conversationId: conversationId);
    },
  ),
];

/// Error screen shown when navigation fails.
class _ErrorScreen extends StatelessWidget {
  final Exception? error;

  const _ErrorScreen({this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Error')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Page not found',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              error?.toString() ?? 'Unknown error',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go(RoutePaths.welcome),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    );
  }
}
