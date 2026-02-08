import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/entities/workout_session_entity.dart';
import '../features/home/models/recent_workout_item.dart';
import '../utils/feature_gate.dart';
import 'database_providers.dart';
import 'entitlement_provider.dart';

/// Provider for in-progress workout session
final inProgressSessionProvider =
    FutureProvider<WorkoutSessionEntity?>((ref) async {
  final dao = ref.watch(workoutSessionDaoProvider);
  return await dao.getInProgressSession();
});

/// Notifier for workout session management
class WorkoutSessionNotifier
    extends StateNotifier<AsyncValue<WorkoutSessionEntity?>> {
  WorkoutSessionNotifier(this.ref) : super(const AsyncValue.loading()) {
    _loadInProgressSession();
  }

  final Ref ref;

  Future<void> _loadInProgressSession() async {
    state = const AsyncValue.loading();
    try {
      final dao = ref.read(workoutSessionDaoProvider);
      final session = await dao.getInProgressSession();
      state = AsyncValue.data(session);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Create new workout session
  Future<int?> createNewSession() async {
    try {
      final dao = ref.read(workoutSessionDaoProvider);
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      final session = WorkoutSessionEntity(
        status: 'in_progress',
        startedAt: now,
        createdAt: now,
        updatedAt: now,
      );

      final sessionId = await dao.insertSession(session);
      await _loadInProgressSession();
      return sessionId;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      return null;
    }
  }

  /// Complete current session
  Future<void> completeSession(int sessionId) async {
    try {
      final dao = ref.read(workoutSessionDaoProvider);
      await dao.completeSession(sessionId);
      await _loadInProgressSession();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Delete session and all its data (exercises, set records). Used when ending tutorial.
  Future<void> deleteSession(int sessionId) async {
    try {
      final sessionDao = ref.read(workoutSessionDaoProvider);
      final exerciseDao = ref.read(workoutExerciseDaoProvider);
      final setRecordDao = ref.read(setRecordDaoProvider);
      final exercises = await exerciseDao.getExercisesBySessionId(sessionId);
      for (final ex in exercises) {
        await setRecordDao.deleteSetsByWorkoutExerciseId(ex.id!);
      }
      for (final ex in exercises) {
        await exerciseDao.deleteWorkoutExercise(ex.id!);
      }
      await sessionDao.deleteSession(sessionId);
      await _loadInProgressSession();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Update session start and end times
  Future<void> updateSessionTimes(
    int sessionId,
    int startedAt,
    int? completedAt,
  ) async {
    try {
      // Validation
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      if (startedAt > now) {
        throw Exception('Start time cannot be in the future');
      }

      if (completedAt != null) {
        if (completedAt > now) {
          throw Exception('End time cannot be in the future');
        }
        if (startedAt > completedAt) {
          throw Exception('Start time must be before end time');
        }
      }

      final dao = ref.read(workoutSessionDaoProvider);
      await dao.updateSessionTimes(sessionId, startedAt, completedAt);
      await _loadInProgressSession();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  /// Refresh in-progress session
  Future<void> refresh() async {
    await _loadInProgressSession();
  }
}

/// Provider for WorkoutSessionNotifier
final workoutSessionNotifierProvider = StateNotifierProvider<
    WorkoutSessionNotifier, AsyncValue<WorkoutSessionEntity?>>(
  (ref) => WorkoutSessionNotifier(ref),
);

/// Provider for recent completed workout sessions
final recentWorkoutsProvider =
    FutureProvider<List<WorkoutSessionEntity>>((ref) async {
  final dao = ref.watch(workoutSessionDaoProvider);
  return await dao.getCompletedSessions(limit: 10);
});

/// Provider for recent workouts with lock status
/// ホーム画面の履歴一覧で使用（ロック状態を含む）
final recentWorkoutItemsProvider =
    FutureProvider<List<RecentWorkoutItem>>((ref) async {
  final dao = ref.watch(workoutSessionDaoProvider);
  final entitlement = ref.watch(entitlementProvider);
  final gate = FeatureGate(entitlement);

  // ホーム画面では最大30件表示（ロック分も含む）
  final sessions = await dao.getCompletedSessions(limit: 30);

  return sessions.asMap().entries.map((entry) {
    final index = entry.key;
    final session = entry.value;
    return RecentWorkoutItem(
      session: session,
      globalIndex: index,
      isLocked: gate.isSessionLocked(index),
    );
  }).toList();
});
