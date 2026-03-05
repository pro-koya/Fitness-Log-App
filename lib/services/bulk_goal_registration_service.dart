import '../data/dao/exercise_goal_dao.dart';
import '../data/dao/exercise_master_dao.dart';
import '../data/dao/set_record_dao.dart';
import '../data/entities/exercise_goal_entity.dart';
import '../data/entities/exercise_master_entity.dart';

/// Result of bulk goal registration.
class BulkGoalRegistrationResult {
  final int savedCount;
  final int skippedCount;

  const BulkGoalRegistrationResult({
    required this.savedCount,
    required this.skippedCount,
  });
}

/// Service to register goals in bulk: past best × coefficient per selected exercise.
class BulkGoalRegistrationService {
  BulkGoalRegistrationService({
    required SetRecordDao setRecordDao,
    required ExerciseMasterDao exerciseMasterDao,
    required ExerciseGoalDao exerciseGoalDao,
  })  : _setRecordDao = setRecordDao,
        _exerciseMasterDao = exerciseMasterDao,
        _exerciseGoalDao = exerciseGoalDao;

  final SetRecordDao _setRecordDao;
  final ExerciseMasterDao _exerciseMasterDao;
  final ExerciseGoalDao _exerciseGoalDao;

  /// For each selected exercise, determines goalType from recordType and history,
  /// computes goalValue = best × coefficient, then upserts the goal.
  /// Returns how many goals were saved and how many were skipped (no best value).
  Future<BulkGoalRegistrationResult> register({
    required List<int> exerciseIds,
    required double coefficient,
  }) async {
    int saved = 0;
    int skipped = 0;
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    for (final exerciseId in exerciseIds) {
      final master = await _exerciseMasterDao.getExerciseById(exerciseId);
      if (master == null) {
        skipped++;
        continue;
      }

      final goalType = await _resolveGoalType(master);
      if (goalType == null) {
        skipped++;
        continue;
      }

      final best = await _setRecordDao.getBestValueForExercise(exerciseId, goalType);
      if (best == null || best <= 0) {
        skipped++;
        continue;
      }

      final goalValue = _computeGoalValue(goalType, best, coefficient);
      if (goalValue <= 0) {
        skipped++;
        continue;
      }

      final existing = await _exerciseGoalDao.getByExerciseId(exerciseId);
      final entity = ExerciseGoalEntity(
        id: existing?.id,
        exerciseId: exerciseId,
        goalType: goalType,
        goalValue: goalValue,
        deadlineTs: null,
        priority: 2,
        createdAt: existing?.createdAt ?? now,
        updatedAt: now,
      );
      await _exerciseGoalDao.upsert(entity);
      saved++;
    }

    return BulkGoalRegistrationResult(savedCount: saved, skippedCount: skipped);
  }

  /// Resolves which goalType to use for this exercise based on recordType and which best exists.
  /// reps -> weight then volume then reps; time -> time; cardio -> time then distance.
  Future<String?> _resolveGoalType(ExerciseMasterEntity master) async {
    switch (master.recordType) {
      case 'reps':
        if (await _setRecordDao.getBestValueForExercise(master.id!, 'weight') != null) {
          return 'weight';
        }
        if (await _setRecordDao.getBestValueForExercise(master.id!, 'volume') != null) {
          return 'volume';
        }
        if (await _setRecordDao.getBestValueForExercise(master.id!, 'reps') != null) {
          return 'reps';
        }
        return null;
      case 'time':
        return (await _setRecordDao.getBestValueForExercise(master.id!, 'time')) != null
            ? 'time'
            : null;
      case 'cardio':
        if (await _setRecordDao.getBestValueForExercise(master.id!, 'time') != null) {
          return 'time';
        }
        if (await _setRecordDao.getBestValueForExercise(master.id!, 'distance') != null) {
          return 'distance';
        }
        return null;
      default:
        return null;
    }
  }

  double _computeGoalValue(String goalType, double best, double coefficient) {
    final value = best * coefficient;
    switch (goalType) {
      case 'weight':
      case 'volume':
        // 2.5 kg 単位で繰り上げ（キリの良い数値にする）
        return (value / 2.5).ceil() * 2.5;
      case 'reps':
      case 'time':
        return value.roundToDouble();
      case 'distance':
        return (value * 10).round() / 10;
      default:
        return value;
    }
  }
}
