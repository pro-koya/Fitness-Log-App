import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/entities/routine_template_entity.dart';
import '../features/routine/models/routine_model.dart';
import 'database_providers.dart';
import 'settings_provider.dart';

/// Provider for routine list (all routines ordered by updated_at DESC)
final routineListProvider = FutureProvider<List<RoutineTemplateEntity>>((ref) async {
  ref.watch(databaseStateProvider);
  final dao = ref.watch(routineTemplateDaoProvider);
  return await dao.getAll();
});

/// Provider for routine detail with exercises and sets
final routineDetailProvider = FutureProvider.family<RoutineModel, int>((ref, routineId) async {
  final templateDao = ref.watch(routineTemplateDaoProvider);
  final exerciseDao = ref.watch(routineExerciseDaoProvider);
  final setDao = ref.watch(routineSetDaoProvider);
  final exerciseMasterDao = ref.watch(exerciseMasterDaoProvider);
  final unit = ref.watch(currentUnitProvider);
  final distanceUnit = ref.watch(currentDistanceUnitProvider);

  final template = await templateDao.getById(routineId);
  if (template == null) {
    throw Exception('Routine not found: $routineId');
  }

  final routineExercises = await exerciseDao.getByRoutineId(routineId);
  final exercises = <RoutineExerciseModel>[];

  for (final re in routineExercises) {
    final exerciseMaster = await exerciseMasterDao.getExerciseById(re.exerciseId);
    if (exerciseMaster == null) continue;

    final setEntities = await setDao.getByRoutineExerciseId(re.id!);
    final targetSets = setEntities
        .map((se) => RoutineSetModel.fromEntity(
              se,
              unit: unit,
              distanceUnit: distanceUnit,
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

  return RoutineModel(
    id: template.id,
    name: template.name,
    exercises: exercises,
    createdAt: template.createdAt,
    updatedAt: template.updatedAt,
  );
});
