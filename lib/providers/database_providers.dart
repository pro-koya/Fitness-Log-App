import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import '../data/database/database_helper.dart';
import '../data/dao/settings_dao.dart';
import '../data/dao/exercise_master_dao.dart';
import '../data/dao/workout_session_dao.dart';
import '../data/dao/workout_exercise_dao.dart';
import '../data/dao/set_record_dao.dart';
import '../data/dao/body_weight_dao.dart';
import '../data/dao/exercise_goal_dao.dart';
import '../data/dao/goal_achievement_dao.dart';
import '../data/dao/routine_template_dao.dart';
import '../data/dao/routine_exercise_dao.dart';
import '../data/dao/routine_set_dao.dart';

/// Database state provider - increment to invalidate all dependent providers
/// Use ref.invalidate(databaseStateProvider) after restore to refresh all data
final databaseStateProvider = StateProvider<int>((ref) => 0);

/// Provider for database instance
final databaseProvider = FutureProvider<Database>((ref) async {
  return await DatabaseHelper.instance.database;
});

/// Provider for SettingsDao
final settingsDaoProvider = Provider<SettingsDao>((ref) {
  return SettingsDao();
});

/// Provider for ExerciseMasterDao
final exerciseMasterDaoProvider = Provider<ExerciseMasterDao>((ref) {
  return ExerciseMasterDao();
});

/// Provider for WorkoutSessionDao
final workoutSessionDaoProvider = Provider<WorkoutSessionDao>((ref) {
  return WorkoutSessionDao();
});

/// Provider for WorkoutExerciseDao
final workoutExerciseDaoProvider = Provider<WorkoutExerciseDao>((ref) {
  return WorkoutExerciseDao();
});

/// Provider for SetRecordDao
final setRecordDaoProvider = Provider<SetRecordDao>((ref) {
  return SetRecordDao();
});

/// Provider for BodyWeightDao
final bodyWeightDaoProvider = Provider<BodyWeightDao>((ref) {
  return BodyWeightDao();
});

/// Provider for ExerciseGoalDao
final exerciseGoalDaoProvider = Provider<ExerciseGoalDao>((ref) {
  return ExerciseGoalDao();
});

/// Provider for GoalAchievementDao
final goalAchievementDaoProvider = Provider<GoalAchievementDao>((ref) {
  return GoalAchievementDao();
});

/// Provider for RoutineTemplateDao
final routineTemplateDaoProvider = Provider<RoutineTemplateDao>((ref) {
  return RoutineTemplateDao();
});

/// Provider for RoutineExerciseDao
final routineExerciseDaoProvider = Provider<RoutineExerciseDao>((ref) {
  return RoutineExerciseDao();
});

/// Provider for RoutineSetDao
final routineSetDaoProvider = Provider<RoutineSetDao>((ref) {
  return RoutineSetDao();
});
