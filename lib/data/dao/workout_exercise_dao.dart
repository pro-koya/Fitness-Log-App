import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../entities/workout_exercise_entity.dart';

/// DAO for workout_exercises table
class WorkoutExerciseDao {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// Get workout exercise by ID
  Future<WorkoutExerciseEntity?> getWorkoutExerciseById(int id) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'workout_exercises',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return WorkoutExerciseEntity.fromMap(maps.first);
    }
    return null;
  }

  /// Get exercises by session ID
  Future<List<WorkoutExerciseEntity>> getExercisesBySessionId(
    int sessionId,
  ) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'workout_exercises',
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'order_index ASC',
    );

    return maps.map((map) => WorkoutExerciseEntity.fromMap(map)).toList();
  }

  /// Insert workout exercise
  Future<int> insertWorkoutExercise(WorkoutExerciseEntity exercise) async {
    final db = await _dbHelper.database;
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    return await db.insert(
      'workout_exercises',
      exercise.copyWith(createdAt: now, updatedAt: now).toMap(),
    );
  }

  /// Update workout exercise
  Future<int> updateWorkoutExercise(WorkoutExerciseEntity exercise) async {
    final db = await _dbHelper.database;
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    return await db.update(
      'workout_exercises',
      exercise.copyWith(updatedAt: now).toMap(),
      where: 'id = ?',
      whereArgs: [exercise.id],
    );
  }

  /// Delete workout exercise
  Future<int> deleteWorkoutExercise(int id) async {
    final db = await _dbHelper.database;

    return await db.delete(
      'workout_exercises',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Get next order index for a session
  Future<int> getNextOrderIndex(int sessionId) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      '''
      SELECT COALESCE(MAX(order_index), -1) + 1 as next_index
      FROM workout_exercises
      WHERE session_id = ?
      ''',
      [sessionId],
    );

    return result.first['next_index'] as int;
  }

  /// Update order indices for exercises in a session
  Future<void> updateOrderIndices(
    int sessionId,
    List<int> exerciseIds,
  ) async {
    final db = await _dbHelper.database;
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    await db.transaction((txn) async {
      for (int i = 0; i < exerciseIds.length; i++) {
        await txn.update(
          'workout_exercises',
          {
            'order_index': i,
            'updated_at': now,
          },
          where: 'id = ? AND session_id = ?',
          whereArgs: [exerciseIds[i], sessionId],
        );
      }
    });
  }

  /// Get latest workout exercise for a specific exercise in completed sessions
  Future<WorkoutExerciseEntity?> getLatestWorkoutExerciseForExercise(
    int exerciseId,
    int beforeTimestamp,
  ) async {
    final db = await _dbHelper.database;
    final maps = await db.rawQuery(
      '''
      SELECT we.*
      FROM workout_exercises we
      JOIN workout_sessions ws ON we.session_id = ws.id
      WHERE we.exercise_id = ?
        AND ws.status = 'completed'
        AND ws.completed_at < ?
      ORDER BY ws.completed_at DESC
      LIMIT 1
      ''',
      [exerciseId, beforeTimestamp],
    );

    if (maps.isNotEmpty) {
      return WorkoutExerciseEntity.fromMap(maps.first);
    }
    return null;
  }

  /// Update memo for a workout exercise
  Future<int> updateMemo(int workoutExerciseId, String? memo) async {
    final db = await _dbHelper.database;
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    return await db.update(
      'workout_exercises',
      {
        'memo': memo,
        'updated_at': now,
      },
      where: 'id = ?',
      whereArgs: [workoutExerciseId],
    );
  }

  /// Get memo history for a specific exercise (with dates)
  Future<List<Map<String, dynamic>>> getMemoHistoryForExercise(
    int exerciseId,
  ) async {
    final db = await _dbHelper.database;
    final maps = await db.rawQuery(
      '''
      SELECT we.memo, ws.completed_at as date
      FROM workout_exercises we
      JOIN workout_sessions ws ON we.session_id = ws.id
      WHERE we.exercise_id = ?
        AND ws.status = 'completed'
        AND we.memo IS NOT NULL
        AND we.memo != ''
      ORDER BY ws.completed_at DESC
      LIMIT 20
      ''',
      [exerciseId],
    );

    return maps;
  }

  /// Search memos by keyword
  Future<List<Map<String, dynamic>>> searchMemos(String keyword) async {
    final db = await _dbHelper.database;
    final searchPattern = '%$keyword%';
    final maps = await db.rawQuery(
      '''
      SELECT
        we.memo,
        we.exercise_id,
        em.name as exercise_name,
        em.is_custom,
        ws.completed_at as date
      FROM workout_exercises we
      JOIN workout_sessions ws ON we.session_id = ws.id
      JOIN exercise_master em ON we.exercise_id = em.id
      WHERE ws.status = 'completed'
        AND we.memo IS NOT NULL
        AND we.memo != ''
        AND we.memo LIKE ?
      ORDER BY ws.completed_at DESC
      LIMIT 50
      ''',
      [searchPattern],
    );

    return maps;
  }
}
