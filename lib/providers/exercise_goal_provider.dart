import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/entities/exercise_goal_entity.dart';
import 'database_providers.dart';

/// Fetches the goal for an exercise (if any). Pro-only data.
final exerciseGoalProvider = FutureProvider.autoDispose.family<ExerciseGoalEntity?, int>(
  (ref, exerciseId) async {
    final dao = ref.watch(exerciseGoalDaoProvider);
    return dao.getByExerciseId(exerciseId);
  },
);
