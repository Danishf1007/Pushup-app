import 'package:cloud_firestore/cloud_firestore.dart';

/// Types of achievements that can be earned.
enum AchievementType {
  /// Streak achievements (consecutive days).
  streak,

  /// Workout count milestones.
  milestone,

  /// Duration-based achievements.
  duration,

  /// First-time achievements.
  first,

  /// Challenge completion.
  challenge,

  /// Perfect week (7 days in a row).
  perfectWeek,
}

/// Difficulty/tier of achievement.
enum AchievementTier {
  /// Easy to obtain.
  bronze,

  /// Moderate difficulty.
  silver,

  /// Challenging.
  gold,

  /// Expert level.
  platinum,
}

/// An achievement that can be earned by an athlete.
class AchievementEntity {
  /// Creates an achievement entity.
  const AchievementEntity({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.tier,
    required this.iconName,
    required this.requirement,
    this.unlockedAt,
    this.progress = 0,
  });

  /// Creates from Firestore document.
  factory AchievementEntity.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AchievementEntity(
      id: doc.id,
      name: data['name'] as String? ?? '',
      description: data['description'] as String? ?? '',
      type: AchievementType.values.firstWhere(
        (t) => t.name == data['type'],
        orElse: () => AchievementType.milestone,
      ),
      tier: AchievementTier.values.firstWhere(
        (t) => t.name == data['tier'],
        orElse: () => AchievementTier.bronze,
      ),
      iconName: data['iconName'] as String? ?? 'star',
      requirement: data['requirement'] as int? ?? 0,
      unlockedAt: (data['unlockedAt'] as Timestamp?)?.toDate(),
      progress: data['progress'] as int? ?? 0,
    );
  }

  /// Unique identifier.
  final String id;

  /// Display name of the achievement.
  final String name;

  /// Description of how to earn.
  final String description;

  /// Type of achievement.
  final AchievementType type;

  /// Tier/difficulty level.
  final AchievementTier tier;

  /// Icon name for display.
  final String iconName;

  /// Requirement value to unlock (e.g., 7 for 7-day streak).
  final int requirement;

  /// When the achievement was unlocked (null if not yet earned).
  final DateTime? unlockedAt;

  /// Current progress towards requirement.
  final int progress;

  /// Whether this achievement has been unlocked.
  bool get isUnlocked => unlockedAt != null;

  /// Progress percentage (0-100).
  double get progressPercent =>
      requirement > 0 ? (progress / requirement * 100).clamp(0, 100) : 0;

  /// Converts to Firestore map.
  Map<String, dynamic> toFirestore() => {
    'name': name,
    'description': description,
    'type': type.name,
    'tier': tier.name,
    'iconName': iconName,
    'requirement': requirement,
    'unlockedAt': unlockedAt != null ? Timestamp.fromDate(unlockedAt!) : null,
    'progress': progress,
  };

  /// Creates a copy with updated fields.
  AchievementEntity copyWith({
    String? id,
    String? name,
    String? description,
    AchievementType? type,
    AchievementTier? tier,
    String? iconName,
    int? requirement,
    DateTime? unlockedAt,
    int? progress,
  }) {
    return AchievementEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      tier: tier ?? this.tier,
      iconName: iconName ?? this.iconName,
      requirement: requirement ?? this.requirement,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      progress: progress ?? this.progress,
    );
  }
}

/// Predefined achievements available in the app.
class PredefinedAchievements {
  static const List<Map<String, dynamic>> all = [
    // Streak achievements
    {
      'id': 'streak_3',
      'name': 'Getting Started',
      'description': 'Complete workouts for 3 consecutive days',
      'type': 'streak',
      'tier': 'bronze',
      'iconName': 'local_fire_department',
      'requirement': 3,
    },
    {
      'id': 'streak_7',
      'name': 'Week Warrior',
      'description': 'Maintain a 7-day workout streak',
      'type': 'streak',
      'tier': 'silver',
      'iconName': 'local_fire_department',
      'requirement': 7,
    },
    {
      'id': 'streak_14',
      'name': 'Two Week Champion',
      'description': 'Maintain a 14-day workout streak',
      'type': 'streak',
      'tier': 'gold',
      'iconName': 'local_fire_department',
      'requirement': 14,
    },
    {
      'id': 'streak_30',
      'name': 'Monthly Master',
      'description': 'Maintain a 30-day workout streak',
      'type': 'streak',
      'tier': 'platinum',
      'iconName': 'local_fire_department',
      'requirement': 30,
    },

    // Milestone achievements
    {
      'id': 'workout_10',
      'name': 'First Steps',
      'description': 'Complete 10 workouts',
      'type': 'milestone',
      'tier': 'bronze',
      'iconName': 'fitness_center',
      'requirement': 10,
    },
    {
      'id': 'workout_25',
      'name': 'Dedicated Athlete',
      'description': 'Complete 25 workouts',
      'type': 'milestone',
      'tier': 'silver',
      'iconName': 'fitness_center',
      'requirement': 25,
    },
    {
      'id': 'workout_50',
      'name': 'Half Century',
      'description': 'Complete 50 workouts',
      'type': 'milestone',
      'tier': 'gold',
      'iconName': 'fitness_center',
      'requirement': 50,
    },
    {
      'id': 'workout_100',
      'name': 'Century Club',
      'description': 'Complete 100 workouts',
      'type': 'milestone',
      'tier': 'platinum',
      'iconName': 'fitness_center',
      'requirement': 100,
    },

    // Duration achievements
    {
      'id': 'duration_60',
      'name': 'Hour of Power',
      'description': 'Accumulate 60 minutes of workout time',
      'type': 'duration',
      'tier': 'bronze',
      'iconName': 'timer',
      'requirement': 60,
    },
    {
      'id': 'duration_300',
      'name': 'Five Hour Hero',
      'description': 'Accumulate 5 hours of workout time',
      'type': 'duration',
      'tier': 'silver',
      'iconName': 'timer',
      'requirement': 300,
    },
    {
      'id': 'duration_600',
      'name': 'Ten Hour Titan',
      'description': 'Accumulate 10 hours of workout time',
      'type': 'duration',
      'tier': 'gold',
      'iconName': 'timer',
      'requirement': 600,
    },

    // First achievements
    {
      'id': 'first_workout',
      'name': 'Welcome Aboard',
      'description': 'Complete your first workout',
      'type': 'first',
      'tier': 'bronze',
      'iconName': 'star',
      'requirement': 1,
    },
    {
      'id': 'first_plan_complete',
      'name': 'Plan Crusher',
      'description': 'Complete your first training plan',
      'type': 'first',
      'tier': 'silver',
      'iconName': 'assignment_turned_in',
      'requirement': 1,
    },

    // Perfect week
    {
      'id': 'perfect_week_1',
      'name': 'Perfect Week',
      'description': 'Complete workouts every day for a full week',
      'type': 'perfectWeek',
      'tier': 'gold',
      'iconName': 'emoji_events',
      'requirement': 1,
    },
    {
      'id': 'perfect_week_4',
      'name': 'Perfect Month',
      'description': 'Achieve 4 perfect weeks',
      'type': 'perfectWeek',
      'tier': 'platinum',
      'iconName': 'emoji_events',
      'requirement': 4,
    },
  ];
}
