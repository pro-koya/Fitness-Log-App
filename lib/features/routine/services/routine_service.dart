import '../../../data/dao/routine_template_dao.dart';
import '../../../data/dao/routine_exercise_dao.dart';
import '../../../data/dao/routine_set_dao.dart';
import '../../../data/dao/workout_exercise_dao.dart';
import '../../../data/dao/set_record_dao.dart';
import '../../../data/entities/routine_template_entity.dart';
import '../../../data/entities/routine_exercise_entity.dart';
import '../../../data/entities/routine_set_entity.dart';

/// Service for routine operations (e.g., creating from a completed session)
class RoutineService {
  final RoutineTemplateDao _templateDao;
  final RoutineExerciseDao _routineExerciseDao;
  final RoutineSetDao _routineSetDao;
  final WorkoutExerciseDao _workoutExerciseDao;
  final SetRecordDao _setRecordDao;

  RoutineService({
    required RoutineTemplateDao templateDao,
    required RoutineExerciseDao routineExerciseDao,
    required RoutineSetDao routineSetDao,
    required WorkoutExerciseDao workoutExerciseDao,
    required SetRecordDao setRecordDao,
  })  : _templateDao = templateDao,
        _routineExerciseDao = routineExerciseDao,
        _routineSetDao = routineSetDao,
        _workoutExerciseDao = workoutExerciseDao,
        _setRecordDao = setRecordDao;

  /// Create a routine from a completed workout session
  Future<int> createFromSession({
    required String name,
    required int sessionId,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    // 1. Create the routine template
    final routineId = await _templateDao.insert(RoutineTemplateEntity(
      name: name,
      createdAt: now,
      updatedAt: now,
    ));

    // 2. Get all exercises from the session
    final workoutExercises = await _workoutExerciseDao.getExercisesBySessionId(sessionId);

    for (final we in workoutExercises) {
      // 3. Create routine exercise
      final routineExerciseId = await _routineExerciseDao.insert(
        RoutineExerciseEntity(
          routineId: routineId,
          exerciseId: we.exerciseId,
          orderIndex: we.orderIndex,
          createdAt: now,
          updatedAt: now,
        ),
      );

      // 4. Get sets for this exercise and create routine sets
      final sets = await _setRecordDao.getSetsByWorkoutExerciseId(we.id!);
      final routineSets = sets
          .map((s) => RoutineSetEntity(
                routineExerciseId: routineExerciseId,
                setNumber: s.setNumber,
                weightKg: s.weightKg,
                weightLb: s.weightLb,
                reps: s.reps,
                durationSeconds: s.durationSeconds,
                distanceMeters: s.distanceMeters,
                createdAt: now,
                updatedAt: now,
              ))
          .toList();

      if (routineSets.isNotEmpty) {
        await _routineSetDao.insertAll(routineSets);
      }
    }

    return routineId;
  }
}
