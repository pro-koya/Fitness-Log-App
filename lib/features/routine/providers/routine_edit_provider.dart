import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/dao/routine_template_dao.dart';
import '../../../data/dao/routine_exercise_dao.dart';
import '../../../data/dao/routine_set_dao.dart';
import '../../../data/dao/exercise_master_dao.dart';
import '../../../data/entities/exercise_master_entity.dart';
import '../../../data/entities/routine_template_entity.dart';
import '../../../data/entities/routine_exercise_entity.dart';
import '../../../providers/database_providers.dart';
import '../../../providers/settings_provider.dart';
import '../models/routine_model.dart';

/// State for routine editing
class RoutineEditState {
  final String name;
  final List<RoutineExerciseModel> exercises;
  final bool isLoading;
  final String? error;

  const RoutineEditState({
    this.name = '',
    this.exercises = const [],
    this.isLoading = false,
    this.error,
  });

  RoutineEditState copyWith({
    String? name,
    List<RoutineExerciseModel>? exercises,
    bool? isLoading,
    String? error,
  }) {
    return RoutineEditState(
      name: name ?? this.name,
      exercises: exercises ?? this.exercises,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// StateNotifier for routine editing
class RoutineEditNotifier extends StateNotifier<RoutineEditState> {
  final RoutineTemplateDao _templateDao;
  final RoutineExerciseDao _exerciseDao;
  final RoutineSetDao _setDao;
  final ExerciseMasterDao _exerciseMasterDao;
  final String _unit;
  final String _distanceUnit;
  final int? _routineId;

  RoutineEditNotifier({
    required RoutineTemplateDao templateDao,
    required RoutineExerciseDao exerciseDao,
    required RoutineSetDao setDao,
    required ExerciseMasterDao exerciseMasterDao,
    required String unit,
    required String distanceUnit,
    required int? routineId,
  })  : _templateDao = templateDao,
        _exerciseDao = exerciseDao,
        _setDao = setDao,
        _exerciseMasterDao = exerciseMasterDao,
        _unit = unit,
        _distanceUnit = distanceUnit,
        _routineId = routineId,
        super(const RoutineEditState(isLoading: true)) {
    if (routineId != null) {
      _loadRoutine(routineId);
    } else {
      state = const RoutineEditState();
    }
  }

  Future<void> _loadRoutine(int routineId) async {
    try {
      final template = await _templateDao.getById(routineId);
      if (template == null) {
        state = const RoutineEditState(error: 'Routine not found');
        return;
      }

      final routineExercises = await _exerciseDao.getByRoutineId(routineId);
      final exercises = <RoutineExerciseModel>[];

      for (final re in routineExercises) {
        final exerciseMaster = await _exerciseMasterDao.getExerciseById(re.exerciseId);
        if (exerciseMaster == null) continue;

        final setEntities = await _setDao.getByRoutineExerciseId(re.id!);
        final targetSets = setEntities
            .map((se) => RoutineSetModel.fromEntity(
                  se,
                  unit: _unit,
                  distanceUnit: _distanceUnit,
                  recordType: exerciseMaster.recordType,
                ))
            .toList();

        exercises.add(RoutineExerciseModel(
          routineExerciseId: re.id,
          exercise: exerciseMaster,
          targetSets: targetSets,
          orderIndex: re.orderIndex,
        ));
      }

      state = RoutineEditState(
        name: template.name,
        exercises: exercises,
      );
    } catch (e) {
      state = RoutineEditState(error: e.toString());
    }
  }

  void setName(String name) {
    state = state.copyWith(name: name);
  }

  void addExercise(ExerciseMasterEntity exercise) {
    // Prevent duplicates
    if (state.exercises.any((e) => e.exercise.id == exercise.id)) return;

    final newExercise = RoutineExerciseModel(
      exercise: exercise,
      targetSets: [
        RoutineSetModel(
          setNumber: 1,
          unit: _unit,
          distanceUnit: _distanceUnit,
          recordType: exercise.recordType,
        ),
      ],
      orderIndex: state.exercises.length,
    );

    state = state.copyWith(
      exercises: [...state.exercises, newExercise],
    );
  }

  void removeExercise(int index) {
    final updated = [...state.exercises];
    updated.removeAt(index);
    // Re-index
    for (int i = 0; i < updated.length; i++) {
      updated[i] = updated[i].copyWith(orderIndex: i);
    }
    state = state.copyWith(exercises: updated);
  }

  void reorderExercise(int oldIndex, int newIndex) {
    final updated = [...state.exercises];
    if (newIndex > oldIndex) newIndex--;
    final item = updated.removeAt(oldIndex);
    updated.insert(newIndex, item);
    // Re-index
    for (int i = 0; i < updated.length; i++) {
      updated[i] = updated[i].copyWith(orderIndex: i);
    }
    state = state.copyWith(exercises: updated);
  }

  void addSet(int exerciseIndex) {
    final updated = [...state.exercises];
    final exercise = updated[exerciseIndex];
    final newSetNumber = exercise.targetSets.length + 1;

    // Copy values from last set if available
    RoutineSetModel newSet;
    if (exercise.targetSets.isNotEmpty) {
      final lastSet = exercise.targetSets.last;
      newSet = lastSet.copyWith(setNumber: newSetNumber);
    } else {
      newSet = RoutineSetModel(
        setNumber: newSetNumber,
        unit: _unit,
        distanceUnit: _distanceUnit,
        recordType: exercise.exercise.recordType,
      );
    }

    updated[exerciseIndex] = exercise.copyWith(
      targetSets: [...exercise.targetSets, newSet],
    );
    state = state.copyWith(exercises: updated);
  }

  void deleteSet(int exerciseIndex, int setIndex) {
    final updated = [...state.exercises];
    final exercise = updated[exerciseIndex];
    final sets = [...exercise.targetSets];
    sets.removeAt(setIndex);
    // Re-number
    for (int i = 0; i < sets.length; i++) {
      sets[i] = sets[i].copyWith(setNumber: i + 1);
    }
    updated[exerciseIndex] = exercise.copyWith(targetSets: sets);
    state = state.copyWith(exercises: updated);
  }

  void updateSet(
    int exerciseIndex,
    int setIndex, {
    double? weight,
    int? reps,
    int? durationSeconds,
    double? distance,
  }) {
    final updated = [...state.exercises];
    final exercise = updated[exerciseIndex];
    final sets = [...exercise.targetSets];
    sets[setIndex] = sets[setIndex].copyWith(
      weight: weight,
      reps: reps,
      durationSeconds: durationSeconds,
      distance: distance,
    );
    updated[exerciseIndex] = exercise.copyWith(targetSets: sets);
    state = state.copyWith(exercises: updated);
  }

  /// Save the routine to database
  Future<bool> save() async {
    if (state.name.trim().isEmpty) return false;
    if (state.exercises.isEmpty) return false;

    state = state.copyWith(isLoading: true);

    try {
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      int routineId;

      if (_routineId != null) {
        // Update existing
        await _templateDao.update(RoutineTemplateEntity(
          id: _routineId,
          name: state.name.trim(),
          createdAt: now,
          updatedAt: now,
        ));
        routineId = _routineId;
        // Delete old exercises (CASCADE deletes sets too)
        await _exerciseDao.deleteByRoutineId(routineId);
      } else {
        // Create new
        routineId = await _templateDao.insert(RoutineTemplateEntity(
          name: state.name.trim(),
          createdAt: now,
          updatedAt: now,
        ));
      }

      // Insert exercises and sets
      for (final exercise in state.exercises) {
        final exerciseId = await _exerciseDao.insert(RoutineExerciseEntity(
          routineId: routineId,
          exerciseId: exercise.exercise.id!,
          orderIndex: exercise.orderIndex,
          createdAt: now,
          updatedAt: now,
        ));

        final setEntities = exercise.targetSets
            .map((s) => s.toEntity(routineExerciseId: exerciseId))
            .toList();
        if (setEntities.isNotEmpty) {
          await _setDao.insertAll(setEntities);
        }
      }

      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }
}

/// Provider for routine editing (family by routineId, null for new)
final routineEditProvider = StateNotifierProvider.autoDispose
    .family<RoutineEditNotifier, RoutineEditState, int?>((ref, routineId) {
  return RoutineEditNotifier(
    templateDao: ref.watch(routineTemplateDaoProvider),
    exerciseDao: ref.watch(routineExerciseDaoProvider),
    setDao: ref.watch(routineSetDaoProvider),
    exerciseMasterDao: ref.watch(exerciseMasterDaoProvider),
    unit: ref.watch(currentUnitProvider),
    distanceUnit: ref.watch(currentDistanceUnitProvider),
    routineId: routineId,
  );
});
