import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/entities/exercise_master_entity.dart';
import '../../../data/entities/set_record_entity.dart';
import '../../../data/entities/workout_exercise_entity.dart';
import '../../../providers/database_providers.dart';
import '../../../providers/settings_provider.dart';
import '../models/workout_exercise_model.dart';

/// State for workout input
class WorkoutInputState {
  final int sessionId;
  final List<WorkoutExerciseModel> exercises;
  final bool isLoading;
  final String? error;

  const WorkoutInputState({
    required this.sessionId,
    this.exercises = const [],
    this.isLoading = false,
    this.error,
  });

  WorkoutInputState copyWith({
    int? sessionId,
    List<WorkoutExerciseModel>? exercises,
    bool? isLoading,
    String? error,
  }) {
    return WorkoutInputState(
      sessionId: sessionId ?? this.sessionId,
      exercises: exercises ?? this.exercises,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notifier for workout input
class WorkoutInputNotifier extends StateNotifier<WorkoutInputState> {
  WorkoutInputNotifier(this.ref, int sessionId)
      : super(WorkoutInputState(sessionId: sessionId));

  final Ref ref;

  /// Timer for debounced auto-save
  Timer? _autoSaveTimer;

  /// Debounce duration for auto-save (500ms)
  static const _autoSaveDelay = Duration(milliseconds: 500);

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    super.dispose();
  }

  /// Schedule auto-save with debounce
  void _scheduleAutoSave() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(_autoSaveDelay, () {
      _autoSave();
    });
  }

  /// Auto-save to database (silent, no error UI)
  Future<void> _autoSave() async {
    try {
      await saveAll();
    } catch (e) {
      // Silent failure for auto-save - user can still complete workout
    }
  }

  /// Reload exercises (public method to reload when unit changes)
  Future<void> reloadExercises() async {
    await _loadExercises();
  }

  /// Load exercises for current session
  Future<void> _loadExercises() async {
    state = state.copyWith(isLoading: true);

    try {
      final workoutExerciseDao = ref.read(workoutExerciseDaoProvider);
      final setRecordDao = ref.read(setRecordDaoProvider);
      final exerciseMasterDao = ref.read(exerciseMasterDaoProvider);
      final currentUnit = ref.read(currentUnitProvider);
      final currentDistanceUnit = ref.read(currentDistanceUnitProvider);

      // Get workout exercises for this session
      final workoutExercises =
          await workoutExerciseDao.getExercisesBySessionId(state.sessionId);

      // Build models
      final List<WorkoutExerciseModel> models = [];

      for (final we in workoutExercises) {
        // Get exercise master
        final exercise = await exerciseMasterDao.getExerciseById(we.exerciseId);
        if (exercise == null) continue;

        // Get sets for this workout exercise
        final sets = await setRecordDao.getSetsByWorkoutExerciseId(we.id!);

        // Get previous sets (from last completed session)
        final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        final previousSets =
            await setRecordDao.getPreviousSetsForExercise(we.exerciseId, now);

        // Convert to models with current unit
        final setModels = sets
            .map((s) => SetRecordModel(
                  id: s.id,
                  setNumber: s.setNumber,
                  weight: s.getWeight(currentUnit), // Use current unit
                  reps: s.reps,
                  durationSeconds: s.durationSeconds,
                  distance: s.getDistance(currentDistanceUnit), // Use current distance unit
                  unit: currentUnit, // Use current unit
                  distanceUnit: currentDistanceUnit,
                  recordType: exercise.recordType,
                ))
            .toList();

        models.add(WorkoutExerciseModel(
          workoutExerciseId: we.id,
          exercise: exercise,
          sets: setModels,
          previousSets: previousSets,
          memo: we.memo,
        ));
      }

      state = state.copyWith(exercises: models, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  /// Add exercise to session
  Future<void> addExercise(ExerciseMasterEntity exercise) async {
    try {
      final workoutExerciseDao = ref.read(workoutExerciseDaoProvider);
      final setRecordDao = ref.read(setRecordDaoProvider);
      final currentUnit = ref.read(currentUnitProvider);
      final currentDistanceUnit = ref.read(currentDistanceUnitProvider);

      // Get next order index
      final orderIndex =
          await workoutExerciseDao.getNextOrderIndex(state.sessionId);

      // Create workout exercise
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final workoutExerciseId = await workoutExerciseDao.insertWorkoutExercise(
        WorkoutExerciseEntity(
          sessionId: state.sessionId,
          exerciseId: exercise.id!,
          orderIndex: orderIndex,
          createdAt: now,
          updatedAt: now,
        ),
      );

      // Get previous sets
      final previousSets =
          await setRecordDao.getPreviousSetsForExercise(exercise.id!, now);

      // Create initial set (empty)
      final initialSet = SetRecordModel(
        setNumber: 1,
        unit: currentUnit,
        distanceUnit: currentDistanceUnit,
        recordType: exercise.recordType,
      );

      // Add to state
      final newExercise = WorkoutExerciseModel(
        workoutExerciseId: workoutExerciseId,
        exercise: exercise,
        sets: [initialSet],
        previousSets: previousSets,
      );

      state = state.copyWith(
        exercises: [...state.exercises, newExercise],
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Add set to exercise
  void addSet(int exerciseIndex) {
    if (exerciseIndex >= state.exercises.length) return;

    final exercise = state.exercises[exerciseIndex];
    final currentUnit = ref.read(currentUnitProvider);
    final currentDistanceUnit = ref.read(currentDistanceUnitProvider);
    final newSetNumber = exercise.sets.length + 1;

    final newSet = SetRecordModel(
      setNumber: newSetNumber,
      unit: currentUnit,
      distanceUnit: currentDistanceUnit,
      recordType: exercise.exercise.recordType,
    );

    final updatedExercise = exercise.copyWith(
      sets: [...exercise.sets, newSet],
    );

    final updatedExercises = [...state.exercises];
    updatedExercises[exerciseIndex] = updatedExercise;

    state = state.copyWith(exercises: updatedExercises);
    _scheduleAutoSave();
  }

  /// Update set data
  void updateSet(int exerciseIndex, int setIndex,
      {double? weight, int? reps, int? durationSeconds, double? distance}) {
    if (exerciseIndex >= state.exercises.length) return;

    final exercise = state.exercises[exerciseIndex];
    if (setIndex >= exercise.sets.length) return;

    final set = exercise.sets[setIndex];
    final updatedSet = set.copyWith(
      weight: weight ?? set.weight,
      reps: reps ?? set.reps,
      durationSeconds: durationSeconds ?? set.durationSeconds,
      distance: distance ?? set.distance,
    );

    final updatedSets = [...exercise.sets];
    updatedSets[setIndex] = updatedSet;

    final updatedExercise = exercise.copyWith(sets: updatedSets);

    final updatedExercises = [...state.exercises];
    updatedExercises[exerciseIndex] = updatedExercise;

    state = state.copyWith(exercises: updatedExercises);
    _scheduleAutoSave();
  }

  /// Copy current set and add as new row (duplicate the set at setIndex)
  void copyFromPrevious(int exerciseIndex, int setIndex) {
    if (exerciseIndex >= state.exercises.length) return;

    final exercise = state.exercises[exerciseIndex];
    if (setIndex >= exercise.sets.length) return;

    // Get the current set to copy
    final currentSet = exercise.sets[setIndex];

    // Create new set with current set's values
    final newSetNumber = exercise.sets.length + 1;
    final newSet = SetRecordModel(
      setNumber: newSetNumber,
      weight: currentSet.weight,
      reps: currentSet.reps,
      durationSeconds: currentSet.durationSeconds,
      distance: currentSet.distance,
      unit: currentSet.unit,
      distanceUnit: currentSet.distanceUnit,
      recordType: currentSet.recordType,
    );

    final updatedExercise = exercise.copyWith(
      sets: [...exercise.sets, newSet],
    );

    final updatedExercises = [...state.exercises];
    updatedExercises[exerciseIndex] = updatedExercise;

    state = state.copyWith(exercises: updatedExercises);
    _scheduleAutoSave();
  }

  /// Reproduce all sets from previous
  void reproduceAllSets(int exerciseIndex) {
    if (exerciseIndex >= state.exercises.length) return;

    final exercise = state.exercises[exerciseIndex];
    if (exercise.previousSets.isEmpty) return;

    final currentUnit = ref.read(currentUnitProvider);
    final currentDistanceUnit = ref.read(currentDistanceUnitProvider);

    // Create sets from previous (convert to current unit)
    final newSets = exercise.previousSets
        .asMap()
        .entries
        .map((entry) => SetRecordModel(
              setNumber: entry.key + 1,
              weight: entry.value.getWeight(currentUnit), // Convert to current unit
              reps: entry.value.reps,
              durationSeconds: entry.value.durationSeconds,
              distance: entry.value.getDistance(currentDistanceUnit), // Convert to current distance unit
              unit: currentUnit,
              distanceUnit: currentDistanceUnit,
              recordType: exercise.exercise.recordType,
            ))
        .toList();

    final updatedExercise = exercise.copyWith(sets: newSets);

    final updatedExercises = [...state.exercises];
    updatedExercises[exerciseIndex] = updatedExercise;

    state = state.copyWith(exercises: updatedExercises);
    _scheduleAutoSave();
  }

  /// Delete set
  void deleteSet(int exerciseIndex, int setIndex) {
    if (exerciseIndex >= state.exercises.length) return;

    final exercise = state.exercises[exerciseIndex];
    if (setIndex >= exercise.sets.length || exercise.sets.length <= 1) return;

    final updatedSets = [...exercise.sets];
    updatedSets.removeAt(setIndex);

    // Renumber sets
    for (int i = 0; i < updatedSets.length; i++) {
      updatedSets[i] = updatedSets[i].copyWith(setNumber: i + 1);
    }

    final updatedExercise = exercise.copyWith(sets: updatedSets);

    final updatedExercises = [...state.exercises];
    updatedExercises[exerciseIndex] = updatedExercise;

    state = state.copyWith(exercises: updatedExercises);
    _scheduleAutoSave();
  }

  /// Delete exercise from workout
  Future<void> deleteExercise(int exerciseIndex) async {
    if (exerciseIndex >= state.exercises.length) return;

    final exercise = state.exercises[exerciseIndex];
    if (exercise.workoutExerciseId == null) return;

    try {
      final workoutExerciseDao = ref.read(workoutExerciseDaoProvider);
      final setRecordDao = ref.read(setRecordDaoProvider);

      // Delete all sets for this exercise
      await setRecordDao
          .deleteSetsByWorkoutExerciseId(exercise.workoutExerciseId!);

      // Delete the workout exercise
      await workoutExerciseDao.deleteWorkoutExercise(exercise.workoutExerciseId!);

      // Remove from state
      final updatedExercises = [...state.exercises];
      updatedExercises.removeAt(exerciseIndex);

      state = state.copyWith(exercises: updatedExercises);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Update memo for an exercise
  Future<void> updateMemo(int exerciseIndex, String? memo) async {
    if (exerciseIndex >= state.exercises.length) return;

    final exercise = state.exercises[exerciseIndex];
    if (exercise.workoutExerciseId == null) return;

    try {
      final workoutExerciseDao = ref.read(workoutExerciseDaoProvider);

      // Update memo in database
      await workoutExerciseDao.updateMemo(exercise.workoutExerciseId!, memo);

      // Update in state
      final updatedExercise = exercise.copyWith(memo: memo);
      final updatedExercises = [...state.exercises];
      updatedExercises[exerciseIndex] = updatedExercise;

      state = state.copyWith(exercises: updatedExercises);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Save all sets to database
  Future<void> saveAll() async {
    try {
      final setRecordDao = ref.read(setRecordDaoProvider);
      final workoutExerciseDao = ref.read(workoutExerciseDaoProvider);

      for (final exercise in state.exercises) {
        if (exercise.workoutExerciseId == null) continue;

        // Save memo
        await workoutExerciseDao.updateMemo(
          exercise.workoutExerciseId!,
          exercise.memo,
        );

        // Delete existing sets
        await setRecordDao
            .deleteSetsByWorkoutExerciseId(exercise.workoutExerciseId!);

        // Insert new sets
        for (final set in exercise.sets) {
          if (!set.isValid) continue;

          await setRecordDao.insertSetRecord(
            set.toEntity(
              workoutExerciseId: exercise.workoutExerciseId!,
              sessionId: state.sessionId,
              exerciseId: exercise.exercise.id!,
            ),
          );
        }
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

/// Provider for workout input
final workoutInputProvider = StateNotifierProvider.family<
    WorkoutInputNotifier, WorkoutInputState, int>(
  (ref, sessionId) => WorkoutInputNotifier(ref, sessionId),
);
