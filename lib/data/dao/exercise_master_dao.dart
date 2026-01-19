import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../entities/exercise_master_entity.dart';

/// DAO for exercise_master table
class ExerciseMasterDao {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// Get all exercises
  Future<List<ExerciseMasterEntity>> getAllExercises() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'exercise_master',
      orderBy: 'name ASC',
    );

    return maps.map((map) => ExerciseMasterEntity.fromMap(map)).toList();
  }

  /// Get exercise by ID
  Future<ExerciseMasterEntity?> getExerciseById(int id) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'exercise_master',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return ExerciseMasterEntity.fromMap(maps.first);
    }
    return null;
  }

  /// Search exercises by name
  Future<List<ExerciseMasterEntity>> searchExercisesByName(String query) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'exercise_master',
      where: 'name LIKE ?',
      whereArgs: ['%$query%'],
      orderBy: 'name ASC',
    );

    return maps.map((map) => ExerciseMasterEntity.fromMap(map)).toList();
  }

  /// Get exercises by body part
  Future<List<ExerciseMasterEntity>> getExercisesByBodyPart(String bodyPart) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'exercise_master',
      where: 'body_part = ?',
      whereArgs: [bodyPart],
      orderBy: 'name ASC',
    );

    return maps.map((map) => ExerciseMasterEntity.fromMap(map)).toList();
  }

  /// Insert custom exercise
  Future<int> insertExercise(ExerciseMasterEntity exercise) async {
    final db = await _dbHelper.database;
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    return await db.insert(
      'exercise_master',
      exercise.copyWith(createdAt: now, updatedAt: now).toMap(),
    );
  }

  /// Update exercise
  Future<int> updateExercise(ExerciseMasterEntity exercise) async {
    final db = await _dbHelper.database;
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    return await db.update(
      'exercise_master',
      exercise.copyWith(updatedAt: now).toMap(),
      where: 'id = ?',
      whereArgs: [exercise.id],
    );
  }

  /// Delete exercise (only custom exercises)
  Future<int> deleteExercise(int id) async {
    final db = await _dbHelper.database;

    // Check if exercise is custom
    final exercise = await getExerciseById(id);
    if (exercise?.isCustom != 1) {
      throw Exception('Cannot delete standard exercise');
    }

    return await db.delete(
      'exercise_master',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Get standard exercises
  Future<List<ExerciseMasterEntity>> getStandardExercises() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'exercise_master',
      where: 'is_custom = ?',
      whereArgs: [0],
      orderBy: 'name ASC',
    );

    return maps.map((map) => ExerciseMasterEntity.fromMap(map)).toList();
  }

  /// Get custom exercises
  Future<List<ExerciseMasterEntity>> getCustomExercises() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'exercise_master',
      where: 'is_custom = ?',
      whereArgs: [1],
      orderBy: 'name ASC',
    );

    return maps.map((map) => ExerciseMasterEntity.fromMap(map)).toList();
  }
}
