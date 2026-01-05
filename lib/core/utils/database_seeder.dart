import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Database seeder for populating test data.
///
/// This class seeds the Firestore database with sample coaches, athletes,
/// training plans, assignments, activity logs, and notifications.
///
/// The seeder creates realistic data by:
/// 1. Creating users (coaches and athletes)
/// 2. Creating training plans with activities
/// 3. Assigning plans to athletes
/// 4. Logging activities as if athletes completed them (this triggers stats calculation)
/// 5. The platform naturally calculates streaks and stats from activity logs
class DatabaseSeeder {
  DatabaseSeeder({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  // Test account password
  static const String testPassword = 'Test123!';

  // Store created IDs for reference
  final List<String> _coachIds = [];
  final List<String> _athleteIds = [];
  final Map<String, String> _athleteCoachMap = {};
  final List<String> _planIds = [];
  final Map<String, String> _athleteAssignmentMap =
      {}; // athleteId -> assignmentId

  // Define streak patterns for athletes
  // Key: athlete index, Value: list of days ago when they worked out
  final Map<int, List<int>> _athleteWorkoutPatterns = {};

  /// Seeds the entire database with test data.
  Future<SeedResult> seedAll() async {
    try {
      print('\n🌱 Starting comprehensive database seed...\n');

      // Seed in order of dependencies
      await _seedCoaches();

      if (_coachIds.isEmpty) {
        return SeedResult(
          success: false,
          message:
              'Failed to seed coaches. They may already exist. '
              'Please use "Clear All Data" first, then seed again.',
        );
      }

      await _seedAthletes();
      await _seedTrainingPlans();
      await _seedPlanAssignments();

      // Generate workout patterns for athletes
      _generateWorkoutPatterns();

      // Seed activity logs based on patterns - this is the KEY step
      // The platform will calculate stats from these logs
      await _seedActivityLogs();

      // Now calculate stats from the activity logs (natural flow)
      await _calculateStatsFromLogs();

      await _seedNotifications();
      await _seedConversations();

      return SeedResult(
        success: true,
        coachCount: _coachIds.length,
        athleteCount: _athleteIds.length,
        planCount: _planIds.length,
        message:
            'Database seeded successfully!\n'
            '${_coachIds.length} coaches, ${_athleteIds.length} athletes, '
            '${_planIds.length} plans created.\n'
            'Activity logs created with realistic workout patterns.',
      );
    } catch (e) {
      return SeedResult(
        success: false,
        message:
            'Seeding failed: ${e.toString()}\n\n'
            'Tip: Use "Clear All Data" first if accounts already exist.',
      );
    }
  }

  /// Recalculates stats for ALL athletes in the database.
  /// This is useful when stats are out of sync with activity logs.
  Future<SeedResult> recalculateAllAthleteStats() async {
    try {
      debugPrint('\n📊 Recalculating stats for all athletes...\n');

      // Get all athletes from the database
      final athletesSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'athlete')
          .get();

      if (athletesSnapshot.docs.isEmpty) {
        return SeedResult(
          success: false,
          message: 'No athletes found in the database.',
        );
      }

      int updatedCount = 0;

      for (final athleteDoc in athletesSnapshot.docs) {
        final athleteId = athleteDoc.id;
        final athleteName = athleteDoc.data()['displayName'] ?? 'Unknown';

        // Get all activity logs for this athlete
        final logsSnapshot = await _firestore
            .collection('activity_logs')
            .where('athleteId', isEqualTo: athleteId)
            .get();

        // Calculate week and month boundaries
        final today = DateTime.now();
        final todayDate = DateTime(today.year, today.month, today.day);
        final currentWeekStart = todayDate.subtract(
          Duration(days: todayDate.weekday - 1),
        );
        final currentMonthStart = DateTime(today.year, today.month, 1);

        if (logsSnapshot.docs.isEmpty) {
          // No activity logs, set default stats
          await _firestore.collection('athlete_stats').doc(athleteId).set({
            'athleteId': athleteId,
            'currentStreak': 0,
            'longestStreak': 0,
            'lastActivityDate': null,
            'totalWorkouts': 0,
            'totalDuration': 0,
            'weeklyWorkouts': 0,
            'weeklyDuration': 0,
            'monthlyWorkouts': 0,
            'monthlyDuration': 0,
            'weekStartDate': Timestamp.fromDate(currentWeekStart),
            'monthStartDate': Timestamp.fromDate(currentMonthStart),
            'updatedAt': FieldValue.serverTimestamp(),
          });
          debugPrint('   👤 $athleteName: No activity logs, reset to 0');
          updatedCount++;
          continue;
        }

        final logs = logsSnapshot.docs.map((doc) => doc.data()).toList();

        // Extract unique dates and calculate totals
        final logDates = <DateTime>[];
        int totalDuration = 0;
        int weeklyWorkouts = 0;
        int weeklyDuration = 0;
        int monthlyWorkouts = 0;
        int monthlyDuration = 0;

        for (final log in logs) {
          final completedAt = (log['completedAt'] as Timestamp).toDate();
          final dateOnly = DateTime(
            completedAt.year,
            completedAt.month,
            completedAt.day,
          );
          logDates.add(dateOnly);
          final logDuration = (log['actualDuration'] as int? ?? 0);
          totalDuration += logDuration;

          // Count weekly stats
          if (!dateOnly.isBefore(currentWeekStart)) {
            weeklyWorkouts++;
            weeklyDuration += logDuration;
          }

          // Count monthly stats
          if (!dateOnly.isBefore(currentMonthStart)) {
            monthlyWorkouts++;
            monthlyDuration += logDuration;
          }
        }

        final uniqueDates = logDates.toSet().toList()
          ..sort((a, b) => b.compareTo(a));
        final totalWorkouts = logs.length;

        // Calculate current streak
        int currentStreak = 0;

        if (uniqueDates.isNotEmpty) {
          final mostRecent = uniqueDates.first;
          final daysSinceLastActivity = todayDate.difference(mostRecent).inDays;

          if (daysSinceLastActivity <= 1) {
            currentStreak = 1;
            DateTime lastDate = mostRecent;

            for (var i = 1; i < uniqueDates.length; i++) {
              final diff = lastDate.difference(uniqueDates[i]).inDays;
              if (diff == 1) {
                currentStreak++;
                lastDate = uniqueDates[i];
              } else {
                break;
              }
            }
          }
        }

        // Calculate longest streak
        int longestStreak = 0;
        int tempStreak = 0;
        DateTime? lastDate;

        for (final date in uniqueDates.reversed) {
          if (lastDate == null) {
            tempStreak = 1;
          } else {
            final diff = date.difference(lastDate).inDays;
            if (diff == 1) {
              tempStreak++;
            } else {
              if (tempStreak > longestStreak) longestStreak = tempStreak;
              tempStreak = 1;
            }
          }
          lastDate = date;
        }
        if (tempStreak > longestStreak) longestStreak = tempStreak;

        debugPrint(
          '   👤 $athleteName: $totalWorkouts workouts, $currentStreak-day streak, $weeklyWorkouts this week',
        );

        // Save stats to Firestore
        await _firestore.collection('athlete_stats').doc(athleteId).set({
          'athleteId': athleteId,
          'currentStreak': currentStreak,
          'longestStreak': longestStreak,
          'lastActivityDate': Timestamp.fromDate(uniqueDates.first),
          'totalWorkouts': totalWorkouts,
          'totalDuration': totalDuration,
          'weeklyWorkouts': weeklyWorkouts,
          'weeklyDuration': weeklyDuration,
          'monthlyWorkouts': monthlyWorkouts,
          'monthlyDuration': monthlyDuration,
          'weekStartDate': Timestamp.fromDate(currentWeekStart),
          'monthStartDate': Timestamp.fromDate(currentMonthStart),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        updatedCount++;
      }

      return SeedResult(
        success: true,
        athleteCount: updatedCount,
        message: 'Stats recalculated for $updatedCount athletes.',
      );
    } catch (e) {
      return SeedResult(
        success: false,
        message: 'Failed to recalculate stats: ${e.toString()}',
      );
    }
  }

  /// Seeds 6 coach users (tripled from original 2).
  Future<void> _seedCoaches() async {
    print('👨‍🏫 Seeding coaches...');

    final coaches = [
      {
        'email': 'coach.mike@example.com',
        'displayName': 'Coach Mike Johnson',
        'role': 'coach',
      },
      {
        'email': 'coach.sarah@example.com',
        'displayName': 'Coach Sarah Williams',
        'role': 'coach',
      },
      {
        'email': 'coach.david@example.com',
        'displayName': 'Coach David Chen',
        'role': 'coach',
      },
      {
        'email': 'coach.emily@example.com',
        'displayName': 'Coach Emily Rodriguez',
        'role': 'coach',
      },
      {
        'email': 'coach.james@example.com',
        'displayName': 'Coach James Thompson',
        'role': 'coach',
      },
      {
        'email': 'coach.lisa@example.com',
        'displayName': 'Coach Lisa Martinez',
        'role': 'coach',
      },
    ];

    for (final coach in coaches) {
      try {
        final userCredential = await _auth.createUserWithEmailAndPassword(
          email: coach['email'] as String,
          password: testPassword,
        );

        await userCredential.user?.updateDisplayName(
          coach['displayName'] as String,
        );

        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          ...coach,
          'createdAt': FieldValue.serverTimestamp(),
          'lastActive': FieldValue.serverTimestamp(),
        });

        _coachIds.add(userCredential.user!.uid);
        await _auth.signOut();
        print('   ✅ Created: ${coach['displayName']}');
      } catch (e) {
        await _auth.signOut();

        // Check if user exists
        final existingUsers = await _firestore
            .collection('users')
            .where('email', isEqualTo: coach['email'])
            .limit(1)
            .get();

        if (existingUsers.docs.isNotEmpty) {
          _coachIds.add(existingUsers.docs.first.id);
          print('   ℹ️ Using existing: ${coach['displayName']}');
        } else {
          // Try to recreate
          try {
            final credential = await _auth.signInWithEmailAndPassword(
              email: coach['email'] as String,
              password: testPassword,
            );
            await credential.user?.delete();
            await _auth.signOut();

            final userCredential = await _auth.createUserWithEmailAndPassword(
              email: coach['email'] as String,
              password: testPassword,
            );

            await userCredential.user?.updateDisplayName(
              coach['displayName'] as String,
            );

            await _firestore
                .collection('users')
                .doc(userCredential.user!.uid)
                .set({
                  ...coach,
                  'createdAt': FieldValue.serverTimestamp(),
                  'lastActive': FieldValue.serverTimestamp(),
                });

            _coachIds.add(userCredential.user!.uid);
            await _auth.signOut();
            print('   ✅ Recreated: ${coach['displayName']}');
          } catch (_) {
            await _auth.signOut();
          }
        }
      }
    }

    print('   📊 Total coaches: ${_coachIds.length}\n');
  }

  /// Seeds 36 athletes (tripled from original 12) distributed across coaches.
  Future<void> _seedAthletes() async {
    print('🏃 Seeding athletes...');

    // 36 athletes - 6 per coach
    final athletes = [
      // Coach 0 - Mike Johnson's athletes (6)
      {
        'displayName': 'Alex Thompson',
        'email': 'alex.t@example.com',
        'coachIndex': 0,
      },
      {
        'displayName': 'Emma Wilson',
        'email': 'emma.w@example.com',
        'coachIndex': 0,
      },
      {
        'displayName': 'Ryan Davis',
        'email': 'ryan.d@example.com',
        'coachIndex': 0,
      },
      {
        'displayName': 'Olivia Martinez',
        'email': 'olivia.m@example.com',
        'coachIndex': 0,
      },
      {
        'displayName': 'Jake Wilson',
        'email': 'jake.w@example.com',
        'coachIndex': 0,
      },
      {
        'displayName': 'Mia Chen',
        'email': 'mia.c@example.com',
        'coachIndex': 0,
      },

      // Coach 1 - Sarah Williams' athletes (6)
      {
        'displayName': 'Liam Anderson',
        'email': 'liam.a@example.com',
        'coachIndex': 1,
      },
      {
        'displayName': 'Sophia Brown',
        'email': 'sophia.b@example.com',
        'coachIndex': 1,
      },
      {
        'displayName': 'Noah Taylor',
        'email': 'noah.t@example.com',
        'coachIndex': 1,
      },
      {
        'displayName': 'Ava Garcia',
        'email': 'ava.g@example.com',
        'coachIndex': 1,
      },
      {
        'displayName': 'Lucas White',
        'email': 'lucas.w@example.com',
        'coachIndex': 1,
      },
      {
        'displayName': 'Harper Lee',
        'email': 'harper.l@example.com',
        'coachIndex': 1,
      },

      // Coach 2 - David Chen's athletes (6)
      {
        'displayName': 'Mason Lee',
        'email': 'mason.l@example.com',
        'coachIndex': 2,
      },
      {
        'displayName': 'Isabella Kim',
        'email': 'isabella.k@example.com',
        'coachIndex': 2,
      },
      {
        'displayName': 'Ethan Park',
        'email': 'ethan.p@example.com',
        'coachIndex': 2,
      },
      {
        'displayName': 'Mia Nguyen',
        'email': 'mia.n@example.com',
        'coachIndex': 2,
      },
      {
        'displayName': 'Aiden Wang',
        'email': 'aiden.w@example.com',
        'coachIndex': 2,
      },
      {
        'displayName': 'Charlotte Zhao',
        'email': 'charlotte.z@example.com',
        'coachIndex': 2,
      },

      // Coach 3 - Emily Rodriguez's athletes (6)
      {
        'displayName': 'Benjamin Cruz',
        'email': 'ben.c@example.com',
        'coachIndex': 3,
      },
      {
        'displayName': 'Amelia Flores',
        'email': 'amelia.f@example.com',
        'coachIndex': 3,
      },
      {
        'displayName': 'Jackson Rivera',
        'email': 'jackson.r@example.com',
        'coachIndex': 3,
      },
      {
        'displayName': 'Evelyn Santos',
        'email': 'evelyn.s@example.com',
        'coachIndex': 3,
      },
      {
        'displayName': 'Sebastian Morales',
        'email': 'seb.m@example.com',
        'coachIndex': 3,
      },
      {
        'displayName': 'Aria Hernandez',
        'email': 'aria.h@example.com',
        'coachIndex': 3,
      },

      // Coach 4 - James Thompson's athletes (6)
      {
        'displayName': 'Henry Mitchell',
        'email': 'henry.m@example.com',
        'coachIndex': 4,
      },
      {
        'displayName': 'Scarlett Cooper',
        'email': 'scarlett.c@example.com',
        'coachIndex': 4,
      },
      {
        'displayName': 'Owen Brooks',
        'email': 'owen.b@example.com',
        'coachIndex': 4,
      },
      {
        'displayName': 'Luna Foster',
        'email': 'luna.f@example.com',
        'coachIndex': 4,
      },
      {
        'displayName': 'Elijah Reed',
        'email': 'elijah.r@example.com',
        'coachIndex': 4,
      },
      {
        'displayName': 'Chloe Murphy',
        'email': 'chloe.m@example.com',
        'coachIndex': 4,
      },

      // Coach 5 - Lisa Martinez's athletes (6)
      {
        'displayName': 'William Price',
        'email': 'william.p@example.com',
        'coachIndex': 5,
      },
      {
        'displayName': 'Grace Turner',
        'email': 'grace.t@example.com',
        'coachIndex': 5,
      },
      {
        'displayName': 'James Scott',
        'email': 'james.s@example.com',
        'coachIndex': 5,
      },
      {
        'displayName': 'Lily Adams',
        'email': 'lily.a@example.com',
        'coachIndex': 5,
      },
      {
        'displayName': 'Daniel Clark',
        'email': 'daniel.c@example.com',
        'coachIndex': 5,
      },
      {
        'displayName': 'Zoe Wright',
        'email': 'zoe.w@example.com',
        'coachIndex': 5,
      },
    ];

    for (var i = 0; i < athletes.length; i++) {
      final athlete = athletes[i];
      final coachIndex = athlete['coachIndex'] as int;

      if (coachIndex >= _coachIds.length) continue;
      final coachId = _coachIds[coachIndex];

      try {
        final userCredential = await _auth.createUserWithEmailAndPassword(
          email: athlete['email'] as String,
          password: testPassword,
        );

        await userCredential.user?.updateDisplayName(
          athlete['displayName'] as String,
        );

        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'email': athlete['email'],
          'displayName': athlete['displayName'],
          'role': 'athlete',
          'coachId': coachId,
          'createdAt': FieldValue.serverTimestamp(),
          'lastActive': FieldValue.serverTimestamp(),
        });

        _athleteIds.add(userCredential.user!.uid);
        _athleteCoachMap[userCredential.user!.uid] = coachId;
        await _auth.signOut();
      } catch (e) {
        await _auth.signOut();

        final existingUsers = await _firestore
            .collection('users')
            .where('email', isEqualTo: athlete['email'])
            .limit(1)
            .get();

        if (existingUsers.docs.isNotEmpty) {
          final uid = existingUsers.docs.first.id;
          _athleteIds.add(uid);
          _athleteCoachMap[uid] = coachId;
        } else {
          try {
            final credential = await _auth.signInWithEmailAndPassword(
              email: athlete['email'] as String,
              password: testPassword,
            );
            await credential.user?.delete();
            await _auth.signOut();

            final userCredential = await _auth.createUserWithEmailAndPassword(
              email: athlete['email'] as String,
              password: testPassword,
            );

            await userCredential.user?.updateDisplayName(
              athlete['displayName'] as String,
            );

            await _firestore
                .collection('users')
                .doc(userCredential.user!.uid)
                .set({
                  'email': athlete['email'],
                  'displayName': athlete['displayName'],
                  'role': 'athlete',
                  'coachId': coachId,
                  'createdAt': FieldValue.serverTimestamp(),
                  'lastActive': FieldValue.serverTimestamp(),
                });

            _athleteIds.add(userCredential.user!.uid);
            _athleteCoachMap[userCredential.user!.uid] = coachId;
            await _auth.signOut();
          } catch (_) {
            await _auth.signOut();
          }
        }
      }
    }

    print('   📊 Total athletes: ${_athleteIds.length}\n');
  }

  /// Seeds 12 training plans (tripled from original 4).
  Future<void> _seedTrainingPlans() async {
    print('📋 Seeding training plans...');

    if (_coachIds.isEmpty) {
      throw Exception(
        'No coaches found. Please clear database first and try again.',
      );
    }

    final planTemplates = [
      {
        'name': 'Beginner Push-Up Program',
        'description':
            'A 4-week program to build foundational push-up strength. Perfect for those just starting their fitness journey.',
        'durationDays': 28,
        'isTemplate': true,
        'activities': _generateActivities([
          'Wall Push-Ups',
          'Knee Push-Ups',
          'Incline Push-Ups',
          'Standard Push-Ups',
          'Core Workout',
          'Rest & Stretch',
        ]),
      },
      {
        'name': 'Intermediate Strength Builder',
        'description':
            'Build strength with varied push-up variations. Designed for athletes ready to push their limits.',
        'durationDays': 21,
        'isTemplate': true,
        'activities': _generateActivities([
          'Diamond Push-Ups',
          'Wide Push-Ups',
          'Decline Push-Ups',
          'Explosive Push-Ups',
          'Pike Push-Ups',
          'Mixed Variation Circuit',
        ]),
      },
      {
        'name': 'Advanced Push-Up Challenge',
        'description':
            'Intense program for experienced athletes. Prepare to be challenged!',
        'durationDays': 14,
        'isTemplate': true,
        'activities': _generateActivities([
          'One-Arm Push-Up Prep',
          'Clap Push-Ups',
          'Archer Push-Ups',
          'Plyo Push-Ups',
          'Push-Up Ladder',
          'Full Body Recovery',
        ]),
      },
      {
        'name': 'Quick Morning Routine',
        'description':
            'Short daily push-up routine for busy schedules. Just 10-15 minutes a day!',
        'durationDays': 7,
        'isTemplate': true,
        'activities': _generateActivities([
          'Morning Push-Ups',
          'Quick Core',
          'Arm Circles',
          'Plank Hold',
          'Cool Down Stretch',
        ]),
      },
      {
        'name': 'Endurance Builder',
        'description':
            'Focus on high-rep endurance training. Build stamina and muscular endurance.',
        'durationDays': 21,
        'isTemplate': false,
        'activities': _generateActivities([
          'High Rep Sets',
          'Timed Hold',
          'Slow Motion Push-Ups',
          'AMRAP Challenge',
          'Active Recovery',
        ]),
      },
      {
        'name': 'Power & Explosiveness',
        'description':
            'Develop explosive power with plyometric push-up variations.',
        'durationDays': 14,
        'isTemplate': true,
        'activities': _generateActivities([
          'Box Push-Ups',
          'Clap Push-Ups',
          'Superman Push-Ups',
          'Explosive Decline',
          'Power Finisher',
        ]),
      },
      {
        'name': 'Core Integration Program',
        'description':
            'Combine push-ups with core exercises for total upper body development.',
        'durationDays': 28,
        'isTemplate': true,
        'activities': _generateActivities([
          'Push-Up to Plank',
          'Mountain Climbers',
          'Spiderman Push-Ups',
          'T-Push-Ups',
          'Core Blast',
          'Recovery Yoga',
        ]),
      },
      {
        'name': 'Muscle Confusion',
        'description':
            'Constantly vary your routine to prevent plateaus and maximize gains.',
        'durationDays': 21,
        'isTemplate': false,
        'activities': _generateActivities([
          'Random Mix Day 1',
          'Random Mix Day 2',
          'Random Mix Day 3',
          'Surprise Challenge',
          'Flexibility Focus',
        ]),
      },
      {
        'name': 'Competition Prep',
        'description':
            'Prepare for push-up competitions with progressive overload training.',
        'durationDays': 42,
        'isTemplate': true,
        'activities': _generateActivities([
          'Max Rep Test',
          'Progressive Sets',
          'Speed Rounds',
          'Technique Refinement',
          'Mental Prep',
          'Competition Simulation',
        ]),
      },
      {
        'name': 'Injury Prevention',
        'description':
            'Safe and gradual progression focusing on proper form and shoulder health.',
        'durationDays': 28,
        'isTemplate': true,
        'activities': _generateActivities([
          'Shoulder Warm-Up',
          'Controlled Push-Ups',
          'Rotator Cuff Work',
          'Mobility Drills',
          'Cool Down Protocol',
        ]),
      },
      {
        'name': 'Home Workout Special',
        'description':
            'No equipment needed - perfect for home workouts anywhere.',
        'durationDays': 14,
        'isTemplate': true,
        'activities': _generateActivities([
          'Bodyweight Basics',
          'Living Room Circuit',
          'Stair Push-Ups',
          'Chair Dips Combo',
          'Floor Finisher',
        ]),
      },
      {
        'name': 'Athletic Performance',
        'description':
            'Sports-specific push-up training for athletes in any discipline.',
        'durationDays': 21,
        'isTemplate': true,
        'activities': _generateActivities([
          'Dynamic Warm-Up',
          'Sport-Specific Drills',
          'Power Development',
          'Agility Integration',
          'Recovery Protocol',
        ]),
      },
    ];

    // Distribute plans across coaches (2 plans per coach)
    for (var i = 0; i < _coachIds.length; i++) {
      final coachId = _coachIds[i];

      // Each coach gets 2 plans
      for (var j = 0; j < 2; j++) {
        final templateIndex = (i * 2 + j) % planTemplates.length;
        final planData = planTemplates[templateIndex];

        final docRef = await _firestore.collection('trainingPlans').add({
          'coachId': coachId,
          'name': planData['name'],
          'description': planData['description'],
          'durationDays': planData['durationDays'],
          'isTemplate': planData['isTemplate'],
          'activities': planData['activities'],
          'createdAt': FieldValue.serverTimestamp(),
        });
        _planIds.add(docRef.id);
      }
    }

    print('   📊 Total plans: ${_planIds.length}\n');
  }

  /// Helper to generate activities with unique IDs.
  List<Map<String, dynamic>> _generateActivities(List<String> names) {
    final types = ['strength', 'cardio', 'flexibility', 'recovery'];
    return names.asMap().entries.map((entry) {
      final index = entry.key;
      final name = entry.value;
      return {
        'id':
            '${DateTime.now().millisecondsSinceEpoch}_${name.hashCode}_$index',
        'name': name,
        'type': types[index % types.length],
        'dayOfWeek': (index % 7) + 1,
        'targetDuration': 15 + (index * 5) % 20, // 15-30 minutes
        'order': index,
      };
    }).toList();
  }

  /// Seeds plan assignments linking athletes to plans.
  Future<void> _seedPlanAssignments() async {
    print('🔗 Seeding plan assignments...');

    if (_athleteIds.isEmpty || _planIds.isEmpty) return;

    for (var i = 0; i < _athleteIds.length; i++) {
      final athleteId = _athleteIds[i];
      final coachId = _athleteCoachMap[athleteId]!;

      // Get a plan from the coach
      final coachPlans = await _firestore
          .collection('trainingPlans')
          .where('coachId', isEqualTo: coachId)
          .limit(1)
          .get();

      if (coachPlans.docs.isNotEmpty) {
        final plan = coachPlans.docs.first;
        final planData = plan.data();
        final athleteDoc = await _firestore
            .collection('users')
            .doc(athleteId)
            .get();
        final athleteName = athleteDoc.data()?['displayName'] ?? 'Athlete';

        // Vary start dates for realism
        final startDate = DateTime.now().subtract(Duration(days: 10 + (i % 5)));
        final endDate = startDate.add(
          Duration(days: planData['durationDays'] as int),
        );

        final assignmentDoc = await _firestore
            .collection('plan_assignments')
            .add({
              'planId': plan.id,
              'athleteId': athleteId,
              'coachId': coachId,
              'assignedAt': FieldValue.serverTimestamp(),
              'startDate': Timestamp.fromDate(startDate),
              'endDate': Timestamp.fromDate(endDate),
              'status': 'active',
              'completionRate': 0.0, // Will be calculated from activity logs
              'planName': planData['name'],
              'athleteName': athleteName,
            });

        _athleteAssignmentMap[athleteId] = assignmentDoc.id;
      }
    }

    print('   📊 Total assignments: ${_athleteAssignmentMap.length}\n');
  }

  /// Generates realistic workout patterns for each athlete.
  ///
  /// Creates varied patterns spanning 3-4 weeks with different consistency levels:
  /// - Super consistent athletes: 90%+ workout days
  /// - Consistent athletes: 70-85% workout days
  /// - Moderate athletes: 50-65% workout days
  /// - Inconsistent athletes: 30-45% workout days
  /// - New/struggling athletes: 1-3 day streaks only
  void _generateWorkoutPatterns() {
    print('📅 Generating workout patterns (3-4 weeks of data)...');

    for (var i = 0; i < _athleteIds.length; i++) {
      List<int> workoutDays;

      if (i == 0) {
        // Athlete 0: Brand new, only 1 day streak (just started today)
        workoutDays = [0];
      } else if (i == 1) {
        // Athlete 1: Struggling, 1 day streak with a few old attempts
        workoutDays = [0, 5, 12, 18]; // Today, then gaps
      } else if (i == 2) {
        // Athlete 2: Building momentum, 3 day streak
        workoutDays = [
          0,
          1,
          2,
          7,
          8,
          14,
          15,
          16,
        ]; // Recent 3-day + older attempts
      } else if (i % 7 == 0) {
        // Every 7th: Super consistent (90%+) - almost daily for 4 weeks
        workoutDays = [
          0,
          1,
          2,
          3,
          4,
          5,
          6,
          7,
          8,
          9,
          10,
          12,
          13,
          14,
          15,
          16,
          17,
          19,
          20,
          21,
          22,
          23,
          24,
          26,
          27,
        ];
      } else if (i % 5 == 0) {
        // Every 5th: Very consistent (80%) - 7 day current streak
        workoutDays = [
          0,
          1,
          2,
          3,
          4,
          5,
          6,
          8,
          9,
          10,
          12,
          13,
          14,
          16,
          17,
          18,
          20,
          21,
          23,
          24,
        ];
      } else if (i % 4 == 0) {
        // Every 4th: Good consistency (70%) - 6 day streak
        workoutDays = [
          0,
          1,
          2,
          3,
          4,
          5,
          7,
          8,
          10,
          11,
          13,
          14,
          16,
          18,
          19,
          21,
          23,
        ];
      } else if (i % 3 == 0) {
        // Every 3rd: Moderate (60%) - 5 day streak with breaks
        workoutDays = [0, 1, 2, 3, 4, 7, 8, 10, 12, 14, 17, 19, 21, 24];
      } else if (i % 2 == 0) {
        // Every 2nd: Average (50%) - some gaps, 4 day streak
        workoutDays = [0, 1, 2, 3, 6, 8, 10, 13, 15, 18, 21, 24];
      } else {
        // Odd athletes: Inconsistent (40%) - 5 day streak but spotty history
        workoutDays = [0, 1, 2, 3, 4, 9, 12, 16, 20, 25];
      }

      _athleteWorkoutPatterns[i] = workoutDays;
    }

    print(
      '   📊 Patterns generated for ${_athleteWorkoutPatterns.length} athletes\n',
    );
  }

  /// Seeds activity logs based on workout patterns.
  /// This simulates athletes logging their workouts naturally.
  Future<void> _seedActivityLogs() async {
    print('📝 Seeding activity logs (simulating athlete workout logging)...\n');

    if (_athleteIds.isEmpty || _athleteAssignmentMap.isEmpty) {
      print('   ⚠️  No athletes or assignments found');
      return;
    }

    int totalLogs = 0;

    for (var i = 0; i < _athleteIds.length; i++) {
      final athleteId = _athleteIds[i];
      final workoutDays = _athleteWorkoutPatterns[i] ?? [0, 1, 2, 3, 4];

      final userDoc = await _firestore.collection('users').doc(athleteId).get();
      final athleteName = userDoc.data()?['displayName'] ?? 'Unknown';
      final assignmentId = _athleteAssignmentMap[athleteId];

      if (assignmentId == null) continue;

      // Get the assignment and plan
      final assignmentDoc = await _firestore
          .collection('plan_assignments')
          .doc(assignmentId)
          .get();
      if (!assignmentDoc.exists) continue;

      final assignmentData = assignmentDoc.data()!;
      final planId = assignmentData['planId'] as String;
      final coachId = assignmentData['coachId'] as String;

      final planDoc = await _firestore
          .collection('trainingPlans')
          .doc(planId)
          .get();
      if (!planDoc.exists) continue;

      final planData = planDoc.data()!;
      final activities = (planData['activities'] as List?) ?? [];
      if (activities.isEmpty) continue;

      // Calculate current streak from consecutive days starting from today
      int currentStreak = 0;
      for (var day in workoutDays) {
        if (day == currentStreak) {
          currentStreak++;
        } else {
          break;
        }
      }

      // Calculate approximate completion percentage
      final approxCompletion = ((workoutDays.length / 20) * 100)
          .clamp(0, 100)
          .toInt();
      print(
        '   👤 $athleteName: ${workoutDays.length} workouts, $currentStreak-day streak, ~$approxCompletion% completion',
      );

      // Create activity logs for each workout day
      for (var j = 0; j < workoutDays.length; j++) {
        final daysAgo = workoutDays[j];
        final activity =
            activities[j % activities.length] as Map<String, dynamic>;

        final logDate = DateTime.now().subtract(Duration(days: daysAgo));
        final baseDuration = activity['targetDuration'] as int? ?? 20;

        // Simulate realistic workout data
        await _firestore.collection('activity_logs').add({
          'athleteId': athleteId,
          'assignmentId': assignmentId,
          'activityId': activity['id'] as String,
          'activityName': activity['name'] as String,
          'completedAt': Timestamp.fromDate(logDate),
          'actualDuration': baseDuration + (j % 10) - 5, // ±5 min variation
          'distance': activity['type'] == 'cardio' ? 1.5 + (j * 0.3) : null,
          'effortLevel': 5 + (j % 5), // 5-9 effort
          'notes': _getRandomNote(j),
          'photoUrl': null,
          'coachId': coachId,
        });

        totalLogs++;
      }

      // Calculate realistic completion rate based on actual expected workouts
      // Plans have activities per week, so 4 weeks = 4x the weekly activities
      final planActivitiesCount = activities.length; // Activities per week
      final expectedWorkoutsIn4Weeks =
          planActivitiesCount * 4; // 4 weeks of workouts
      final actualWorkouts = workoutDays.length;
      final completionRate = (actualWorkouts / expectedWorkoutsIn4Weeks).clamp(
        0.0,
        1.0,
      );

      await _firestore.collection('plan_assignments').doc(assignmentId).update({
        'completionRate': completionRate,
      });
    }

    print('\n   📊 Total activity logs created: $totalLogs\n');
  }

  /// Returns a random workout note.
  String? _getRandomNote(int index) {
    final notes = [
      'Felt great today! 💪',
      'Pushed through the burn!',
      'Getting stronger every day',
      'Form was on point',
      'Need to work on endurance',
      'Personal best today!',
      'Tired but finished strong',
      'Coach\'s tips really helped',
      null, // No note sometimes
      null,
      null,
    ];
    return notes[index % notes.length];
  }

  /// Calculates athlete stats from activity logs.
  /// This mimics how the platform naturally calculates stats.
  Future<void> _calculateStatsFromLogs() async {
    print('📊 Calculating athlete stats from activity logs...\n');

    for (final athleteId in _athleteIds) {
      final userDoc = await _firestore.collection('users').doc(athleteId).get();
      final athleteName = userDoc.data()?['displayName'] ?? 'Unknown';

      // Get all activity logs for this athlete
      final logsSnapshot = await _firestore
          .collection('activity_logs')
          .where('athleteId', isEqualTo: athleteId)
          .get();

      if (logsSnapshot.docs.isEmpty) continue;

      final logs = logsSnapshot.docs.map((doc) => doc.data()).toList();

      // Extract unique dates and calculate totals
      final logDates = <DateTime>[];
      int totalDuration = 0;

      // Calculate week and month boundaries
      final today = DateTime.now();
      final todayDate = DateTime(today.year, today.month, today.day);
      final currentWeekStart = todayDate.subtract(
        Duration(days: todayDate.weekday - 1),
      );
      final currentMonthStart = DateTime(today.year, today.month, 1);

      int weeklyWorkouts = 0;
      int weeklyDuration = 0;
      int monthlyWorkouts = 0;
      int monthlyDuration = 0;

      for (final log in logs) {
        final completedAt = (log['completedAt'] as Timestamp).toDate();
        final dateOnly = DateTime(
          completedAt.year,
          completedAt.month,
          completedAt.day,
        );
        logDates.add(dateOnly);
        final logDuration = (log['actualDuration'] as int? ?? 0);
        totalDuration += logDuration;

        // Count weekly stats
        if (!dateOnly.isBefore(currentWeekStart)) {
          weeklyWorkouts++;
          weeklyDuration += logDuration;
        }

        // Count monthly stats
        if (!dateOnly.isBefore(currentMonthStart)) {
          monthlyWorkouts++;
          monthlyDuration += logDuration;
        }
      }

      final uniqueDates = logDates.toSet().toList()
        ..sort((a, b) => b.compareTo(a));
      final totalWorkouts = logs.length;

      // Calculate current streak
      int currentStreak = 0;

      if (uniqueDates.isNotEmpty) {
        final mostRecent = uniqueDates.first;
        final daysSinceLastActivity = todayDate.difference(mostRecent).inDays;

        if (daysSinceLastActivity <= 1) {
          currentStreak = 1;
          DateTime lastDate = mostRecent;

          for (var i = 1; i < uniqueDates.length; i++) {
            final diff = lastDate.difference(uniqueDates[i]).inDays;
            if (diff == 1) {
              currentStreak++;
              lastDate = uniqueDates[i];
            } else {
              break;
            }
          }
        }
      }

      // Calculate longest streak
      int longestStreak = 0;
      int tempStreak = 0;
      DateTime? lastDate;

      for (final date in uniqueDates.reversed) {
        if (lastDate == null) {
          tempStreak = 1;
        } else {
          final diff = date.difference(lastDate).inDays;
          if (diff == 1) {
            tempStreak++;
          } else {
            if (tempStreak > longestStreak) longestStreak = tempStreak;
            tempStreak = 1;
          }
        }
        lastDate = date;
      }
      if (tempStreak > longestStreak) longestStreak = tempStreak;

      print(
        '   👤 $athleteName: $totalWorkouts workouts, $currentStreak-day streak, $weeklyWorkouts this week',
      );

      // Save stats to Firestore
      await _firestore.collection('athlete_stats').doc(athleteId).set({
        'athleteId': athleteId,
        'currentStreak': currentStreak,
        'longestStreak': longestStreak,
        'lastActivityDate': Timestamp.fromDate(uniqueDates.first),
        'totalWorkouts': totalWorkouts,
        'totalDuration': totalDuration,
        'weeklyWorkouts': weeklyWorkouts,
        'weeklyDuration': weeklyDuration,
        'monthlyWorkouts': monthlyWorkouts,
        'monthlyDuration': monthlyDuration,
        'weekStartDate': Timestamp.fromDate(currentWeekStart),
        'monthStartDate': Timestamp.fromDate(currentMonthStart),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    print('\n   ✅ Stats calculated for all athletes\n');
  }

  /// Seeds notifications for users.
  Future<void> _seedNotifications() async {
    print('🔔 Seeding notifications...');

    if (_coachIds.isEmpty || _athleteIds.isEmpty) return;

    int notificationCount = 0;

    for (var i = 0; i < _athleteIds.length; i++) {
      final athleteId = _athleteIds[i];
      final coachId = _athleteCoachMap[athleteId]!;
      final coachDoc = await _firestore.collection('users').doc(coachId).get();
      final coachName = coachDoc.data()?['displayName'] ?? 'Coach';

      // Welcome notification for all athletes
      await _firestore.collection('notifications').add({
        'senderId': coachId,
        'receiverId': athleteId,
        'type': 'welcome',
        'title': 'Welcome to the Team! 🎉',
        'message':
            '$coachName has added you to their team. Let\'s get started!',
        'sentAt': Timestamp.fromDate(
          DateTime.now().subtract(Duration(days: 7 + i)),
        ),
        'readAt': i % 2 == 0 ? Timestamp.now() : null,
        'senderName': coachName,
      });
      notificationCount++;

      // Plan assigned notification
      if (i % 2 == 0) {
        await _firestore.collection('notifications').add({
          'senderId': coachId,
          'receiverId': athleteId,
          'type': 'plan_assigned',
          'title': 'New Training Plan Assigned! 📋',
          'message':
              '$coachName has assigned you a new training plan. Check it out!',
          'sentAt': Timestamp.fromDate(
            DateTime.now().subtract(Duration(days: 3 + (i % 4))),
          ),
          'readAt': null,
          'senderName': coachName,
        });
        notificationCount++;
      }

      // Encouragement notifications
      if (i % 3 == 0) {
        await _firestore.collection('notifications').add({
          'senderId': coachId,
          'receiverId': athleteId,
          'type': 'encouragement',
          'title': 'Keep It Up! 💪',
          'message':
              'Great progress this week! Keep pushing towards your goals!',
          'sentAt': Timestamp.fromDate(
            DateTime.now().subtract(const Duration(days: 1)),
          ),
          'readAt': null,
          'senderName': coachName,
        });
        notificationCount++;
      }

      // Reminder notifications
      if (i % 4 == 0) {
        await _firestore.collection('notifications').add({
          'senderId': coachId,
          'receiverId': athleteId,
          'type': 'reminder',
          'title': 'Workout Reminder ⏰',
          'message': 'Don\'t forget to complete today\'s workout!',
          'sentAt': Timestamp.fromDate(
            DateTime.now().subtract(const Duration(hours: 6)),
          ),
          'readAt': null,
          'senderName': coachName,
        });
        notificationCount++;
      }
    }

    print('   📊 Total notifications: $notificationCount\n');
  }

  /// Seeds conversations between coaches and athletes.
  Future<void> _seedConversations() async {
    print('💬 Seeding conversations...');

    if (_coachIds.isEmpty || _athleteIds.isEmpty) return;

    int conversationCount = 0;
    int messageCount = 0;

    for (final athleteId in _athleteIds) {
      final coachId = _athleteCoachMap[athleteId];
      if (coachId == null) continue;

      final athleteDoc = await _firestore
          .collection('users')
          .doc(athleteId)
          .get();
      final coachDoc = await _firestore.collection('users').doc(coachId).get();

      final athleteName = athleteDoc.data()?['displayName'] ?? 'Athlete';
      final coachName = coachDoc.data()?['displayName'] ?? 'Coach';

      // Create conversation
      final conversationRef = await _firestore.collection('conversations').add({
        'participantIds': [coachId, athleteId],
        'participantNames': {coachId: coachName, athleteId: athleteName},
        'lastMessage': null,
        'lastMessageAt': null,
        'unreadCounts': {coachId: 0, athleteId: 0},
        'createdAt': FieldValue.serverTimestamp(),
      });
      conversationCount++;

      // Add sample messages for some conversations
      if (conversationCount % 3 == 0) {
        final messages = [
          {
            'senderId': coachId,
            'receiverId': athleteId,
            'content':
                'Welcome to the team, $athleteName! Ready to crush some workouts? 💪',
            'senderName': coachName,
            'sentAt': Timestamp.fromDate(
              DateTime.now().subtract(const Duration(days: 6)),
            ),
            'readAt': Timestamp.fromDate(
              DateTime.now().subtract(const Duration(days: 5, hours: 20)),
            ),
          },
          {
            'senderId': athleteId,
            'receiverId': coachId,
            'content':
                'Thanks Coach! Really excited to get started. Any tips for beginners?',
            'senderName': athleteName,
            'sentAt': Timestamp.fromDate(
              DateTime.now().subtract(const Duration(days: 5, hours: 18)),
            ),
            'readAt': Timestamp.fromDate(
              DateTime.now().subtract(const Duration(days: 5, hours: 16)),
            ),
          },
          {
            'senderId': coachId,
            'receiverId': athleteId,
            'content':
                'Focus on form first, speed will come later. Take your rest days seriously!',
            'senderName': coachName,
            'sentAt': Timestamp.fromDate(
              DateTime.now().subtract(const Duration(days: 5, hours: 15)),
            ),
            'readAt': Timestamp.fromDate(
              DateTime.now().subtract(const Duration(days: 5, hours: 10)),
            ),
          },
          {
            'senderId': athleteId,
            'receiverId': coachId,
            'content':
                'Got it! Just finished today\'s workout. Feeling the burn! 🔥',
            'senderName': athleteName,
            'sentAt': Timestamp.fromDate(
              DateTime.now().subtract(const Duration(days: 2)),
            ),
            'readAt': Timestamp.fromDate(
              DateTime.now().subtract(const Duration(days: 1, hours: 20)),
            ),
          },
          {
            'senderId': coachId,
            'receiverId': athleteId,
            'content':
                'That\'s what I like to hear! Keep up the great work! 🏆',
            'senderName': coachName,
            'sentAt': Timestamp.fromDate(
              DateTime.now().subtract(const Duration(days: 1, hours: 18)),
            ),
            'readAt': null,
          },
        ];

        for (final message in messages) {
          await conversationRef.collection('messages').add(message);
          messageCount++;
        }

        await conversationRef.update({
          'lastMessage': messages.last['content'],
          'lastMessageAt': messages.last['sentAt'],
          'unreadCounts': {coachId: 0, athleteId: 1},
        });
      }
    }

    print('   📊 Total conversations: $conversationCount');
    print('   📊 Total messages: $messageCount\n');
  }

  /// Clears all data from database and deletes test Auth accounts.
  Future<void> clearAllData() async {
    print('\n🗑️ Clearing all data...\n');

    // Delete all Firestore documents
    final collections = [
      'users',
      'trainingPlans',
      'plan_assignments',
      'activity_logs',
      'athlete_stats',
      'notifications',
      'conversations',
    ];

    for (final collection in collections) {
      final snapshot = await _firestore.collection(collection).get();
      print(
        '   Deleting ${snapshot.docs.length} documents from $collection...',
      );
      for (final doc in snapshot.docs) {
        // For conversations, also delete subcollections
        if (collection == 'conversations') {
          final messages = await doc.reference.collection('messages').get();
          for (final msg in messages.docs) {
            await msg.reference.delete();
          }
        }
        await doc.reference.delete();
      }
    }

    // Delete test Firebase Auth accounts
    final testEmails = [
      // Coaches
      'coach.mike@example.com',
      'coach.sarah@example.com',
      'coach.david@example.com',
      'coach.emily@example.com',
      'coach.james@example.com',
      'coach.lisa@example.com',
      // Athletes (expanded list)
      'alex.t@example.com',
      'emma.w@example.com',
      'ryan.d@example.com',
      'olivia.m@example.com',
      'jake.w@example.com',
      'mia.c@example.com',
      'liam.a@example.com',
      'sophia.b@example.com',
      'noah.t@example.com',
      'ava.g@example.com'
          'lucas.w@example.com',
      'harper.l@example.com',
      'mason.l@example.com',
      'isabella.k@example.com',
      'ethan.p@example.com',
      'mia.n@example.com',
      'aiden.w@example.com',
      'charlotte.z@example.com',
      'ben.c@example.com',
      'amelia.f@example.com',
      'jackson.r@example.com',
      'evelyn.s@example.com',
      'seb.m@example.com',
      'aria.h@example.com',
      'henry.m@example.com',
      'scarlett.c@example.com',
      'owen.b@example.com',
      'luna.f@example.com',
      'elijah.r@example.com',
      'chloe.m@example.com',
      'william.p@example.com',
      'grace.t@example.com',
      'james.s@example.com',
      'lily.a@example.com',
      'daniel.c@example.com',
      'zoe.w@example.com',
    ];

    print('\n   Deleting Auth accounts...');
    for (final email in testEmails) {
      try {
        final credential = await _auth.signInWithEmailAndPassword(
          email: email,
          password: testPassword,
        );
        await credential.user?.delete();
        await _auth.signOut();
      } catch (e) {
        await _auth.signOut();
      }
    }

    print('\n✅ All data cleared!\n');
  }
}

/// Result of a database seeding operation.
class SeedResult {
  const SeedResult({
    required this.success,
    this.coachCount = 0,
    this.athleteCount = 0,
    this.planCount = 0,
    this.message,
  });

  final bool success;
  final int coachCount;
  final int athleteCount;
  final int planCount;
  final String? message;
}
