import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/dao/workout_session_dao.dart';
import '../../../data/dao/workout_exercise_dao.dart';
import '../../../data/dao/set_record_dao.dart';
import '../../../data/dao/exercise_master_dao.dart';
import '../../../data/localization/exercise_localization.dart';
import '../../../providers/database_providers.dart';
import '../../../providers/settings_provider.dart';
import '../models/workout_detail_model.dart';

/// Provider for workout detail
final workoutDetailProvider = FutureProvider.family<WorkoutDetailModel?, int>(
  (ref, sessionId) async {
    final sessionDao = WorkoutSessionDao();
    final exerciseDao = WorkoutExerciseDao();
    final setDao = SetRecordDao();
    final masterDao = ExerciseMasterDao();
    // Watch database state to refresh when data is restored
    ref.watch(databaseStateProvider);
    // Watch language provider to recalculate when language changes
    final currentLanguage = ref.watch(currentLanguageProvider);

    // Get session
    final session = await sessionDao.getSessionById(sessionId);
    if (session == null) {
      return null;
    }

    // Get exercises for this session
    final workoutExercises = await exerciseDao.getExercisesBySessionId(
      sessionId,
    );

    // Get sets and exercise names for each exercise
    final exerciseDetails = <ExerciseDetailModel>[];
    for (final workoutExercise in workoutExercises) {
      // Get sets for this exercise
      final sets = await setDao.getSetsByWorkoutExerciseId(
        workoutExercise.id!,
      );

      // Get exercise name from master
      final master = await masterDao.getExerciseById(
        workoutExercise.exerciseId,
      );
      
      // Get localized exercise name
      String exerciseName = '';
      if (master != null) {
        final isStandard = master.isCustom == 0;
        exerciseName = ExerciseLocalization.getLocalizedName(
          englishName: master.name,
          language: currentLanguage,
          isStandard: isStandard,
        );
      }

      exerciseDetails.add(ExerciseDetailModel(
        exercise: workoutExercise,
        sets: sets,
        exerciseName: exerciseName,
        recordType: master?.recordType ?? 'reps',
      ));
    }

    return WorkoutDetailModel(
      session: session,
      exercises: exerciseDetails,
    );
  },
);
