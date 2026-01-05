import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../auth/domain/entities/user_entity.dart';
import '../../data/repositories/coach_repository_impl.dart';
import '../../domain/repositories/coach_repository.dart';

/// Provider for the coach repository.
final coachRepositoryProvider = Provider<CoachRepository>((ref) {
  return CoachRepositoryImpl();
});

/// Stream provider for athletes assigned to a coach.
///
/// Usage: `ref.watch(athletesStreamProvider(coachId))`
final athletesStreamProvider = StreamProvider.family<List<UserEntity>, String>((
  ref,
  coachId,
) {
  final repository = ref.watch(coachRepositoryProvider);
  return repository.watchAthletesByCoach(coachId);
});

/// Future provider to get a single athlete by ID.
///
/// Usage: `ref.watch(athleteByIdProvider(athleteId))`
final athleteByIdProvider = FutureProvider.family<UserEntity?, String>((
  ref,
  athleteId,
) async {
  final repository = ref.watch(coachRepositoryProvider);
  return repository.getAthleteById(athleteId);
});

/// State for athlete operations.
sealed class AthleteOperationState {
  const AthleteOperationState();
}

/// Initial state.
class AthleteOperationInitial extends AthleteOperationState {
  const AthleteOperationInitial();
}

/// Loading state.
class AthleteOperationLoading extends AthleteOperationState {
  const AthleteOperationLoading();
}

/// Success state.
class AthleteOperationSuccess extends AthleteOperationState {
  const AthleteOperationSuccess({this.message});
  final String? message;
}

/// Error state.
class AthleteOperationError extends AthleteOperationState {
  const AthleteOperationError(this.message);
  final String message;
}

/// Notifier for athlete operations.
class AthleteNotifier extends StateNotifier<AthleteOperationState> {
  AthleteNotifier(this._repository) : super(const AthleteOperationInitial());

  final CoachRepository _repository;

  /// Assigns an athlete to a coach.
  Future<bool> assignAthleteToCoach({
    required String athleteId,
    required String coachId,
  }) async {
    state = const AthleteOperationLoading();

    try {
      await _repository.assignAthleteToCoach(
        athleteId: athleteId,
        coachId: coachId,
      );
      state = const AthleteOperationSuccess(
        message: 'Athlete assigned successfully',
      );
      return true;
    } catch (e) {
      state = AthleteOperationError(e.toString());
      return false;
    }
  }

  /// Removes an athlete from a coach.
  Future<bool> removeAthleteFromCoach(String athleteId) async {
    state = const AthleteOperationLoading();

    try {
      await _repository.removeAthleteFromCoach(athleteId);
      state = const AthleteOperationSuccess(
        message: 'Athlete removed successfully',
      );
      return true;
    } catch (e) {
      state = AthleteOperationError(e.toString());
      return false;
    }
  }

  /// Resets the state to initial.
  void reset() {
    state = const AthleteOperationInitial();
  }
}

/// Provider for athlete operations notifier.
final athleteNotifierProvider =
    StateNotifierProvider<AthleteNotifier, AthleteOperationState>((ref) {
      final repository = ref.watch(coachRepositoryProvider);
      return AthleteNotifier(repository);
    });

/// Activity log entity for displaying recent activity.
class ActivityLog {
  final String id;
  final String athleteId;
  final String athleteName;
  final String activityName;
  final String activityType;
  final int duration;
  final int? reps;
  final DateTime completedAt;

  ActivityLog({
    required this.id,
    required this.athleteId,
    required this.athleteName,
    required this.activityName,
    required this.activityType,
    required this.duration,
    this.reps,
    required this.completedAt,
  });

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(completedAt);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  String get formattedDate {
    return DateFormat('MMM d, h:mm a').format(completedAt);
  }
}

/// Provider for streaming recent activity logs for a coach's athletes.
final recentActivityProvider = StreamProvider.family<List<ActivityLog>, String>((
  ref,
  coachId,
) async* {
  try {
    final firestore = FirebaseFirestore.instance;

    // Get coach's athletes
    final athletesSnapshot = await firestore
        .collection('users')
        .where('role', isEqualTo: 'athlete')
        .where('coachId', isEqualTo: coachId)
        .get();

    if (athletesSnapshot.docs.isEmpty) {
      yield [];
      return;
    }

    final athleteMap = {
      for (final doc in athletesSnapshot.docs)
        doc.id: doc.data()['displayName'] as String? ?? 'Unknown',
    };

    final athleteIds = athleteMap.keys.toList();

    // Firestore whereIn has a limit of 10 items, and also requires at least 1 item
    if (athleteIds.isEmpty) {
      yield [];
      return;
    }

    // Take only first 10 athletes if there are more (Firestore whereIn limit)
    final limitedAthleteIds = athleteIds.take(10).toList();

    // Stream activity logs for all athletes
    // Note: Avoid using orderBy with whereIn to prevent composite index requirement
    await for (final snapshot
        in firestore
            .collection('activity_logs')
            .where('athleteId', whereIn: limitedAthleteIds)
            .limit(50)
            .snapshots()) {
      final activities = snapshot.docs.map((doc) {
        final data = doc.data();
        final athleteId = data['athleteId'] as String;
        return ActivityLog(
          id: doc.id,
          athleteId: athleteId,
          athleteName: athleteMap[athleteId] ?? 'Unknown',
          activityName: data['activityName'] as String? ?? 'Activity',
          activityType: data['activityType'] as String? ?? 'strength',
          duration:
              data['actualDuration'] as int? ?? data['duration'] as int? ?? 0,
          reps: data['reps'] as int?,
          completedAt: (data['completedAt'] as Timestamp).toDate(),
        );
      }).toList();

      // Sort in memory to avoid composite index requirement
      activities.sort((a, b) => b.completedAt.compareTo(a.completedAt));

      // Return only the first 10 after sorting
      yield activities.take(10).toList();
    }
  } catch (e) {
    // Log the error for debugging
    debugPrint('Error fetching recent activity: $e');
    // Return empty list instead of throwing
    yield [];
  }
});
