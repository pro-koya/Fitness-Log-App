import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import '../data/database/database_helper.dart';
import '../data/dao/settings_dao.dart';
import '../data/dao/exercise_master_dao.dart';
import '../data/dao/workout_session_dao.dart';
import '../data/dao/workout_exercise_dao.dart';
import '../data/dao/set_record_dao.dart';

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
