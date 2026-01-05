/// Asset path constants for PushUp app.
///
/// All asset paths should be defined here.
abstract class AssetConstants {
  // ============== Base Paths ==============
  static const String _imagesPath = 'assets/images';
  static const String _iconsPath = 'assets/icons';

  // ============== Logo & Branding ==============
  static const String logo = '$_imagesPath/logo.png';
  static const String logoWhite = '$_imagesPath/logo_white.png';
  static const String appIcon = '$_imagesPath/app_icon.png';

  // ============== Onboarding / Welcome ==============
  static const String welcomeIllustration = '$_imagesPath/welcome.png';
  static const String coachIllustration = '$_imagesPath/coach.png';
  static const String athleteIllustration = '$_imagesPath/athlete.png';

  // ============== Empty States ==============
  static const String emptyWorkouts = '$_imagesPath/empty_workouts.png';
  static const String emptyAthletes = '$_imagesPath/empty_athletes.png';
  static const String emptyPlans = '$_imagesPath/empty_plans.png';
  static const String emptyProgress = '$_imagesPath/empty_progress.png';

  // ============== Success / Error States ==============
  static const String successIllustration = '$_imagesPath/success.png';
  static const String errorIllustration = '$_imagesPath/error.png';

  // ============== Achievement Badges ==============
  static const String badgeFirstWeek = '$_imagesPath/badges/first_week.png';
  static const String badgeTenWorkouts = '$_imagesPath/badges/ten_workouts.png';
  static const String badgeStreak5 = '$_imagesPath/badges/streak_5.png';
  static const String badgeStreak14 = '$_imagesPath/badges/streak_14.png';
  static const String badgeStreak30 = '$_imagesPath/badges/streak_30.png';

  // ============== Placeholder ==============
  static const String avatarPlaceholder = '$_imagesPath/avatar_placeholder.png';
  static const String exercisePlaceholder =
      '$_imagesPath/exercise_placeholder.png';

  // ============== Icons (SVG) ==============
  static const String iconDashboard = '$_iconsPath/dashboard.svg';
  static const String iconWorkout = '$_iconsPath/workout.svg';
  static const String iconProgress = '$_iconsPath/progress.svg';
  static const String iconProfile = '$_iconsPath/profile.svg';
  static const String iconAthletes = '$_iconsPath/athletes.svg';
  static const String iconPlans = '$_iconsPath/plans.svg';
  static const String iconNotification = '$_iconsPath/notification.svg';
  static const String iconFire = '$_iconsPath/fire.svg';
  static const String iconTrophy = '$_iconsPath/trophy.svg';
}
