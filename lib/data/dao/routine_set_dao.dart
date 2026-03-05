import '../database/database_helper.dart';
import '../entities/routine_set_entity.dart';

/// DAO for routine_sets table
class RoutineSetDao {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// Get sets by routine exercise ID ordered by set_number
  Future<List<RoutineSetEntity>> getByRoutineExerciseId(
    int routineExerciseId,
  ) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'routine_sets',
      where: 'routine_exercise_id = ?',
      whereArgs: [routineExerciseId],
      orderBy: 'set_number ASC',
    );

    return maps.map((map) => RoutineSetEntity.fromMap(map)).toList();
  }

  /// Insert a single routine set
  Future<int> insert(RoutineSetEntity entity) async {
    final db = await _dbHelper.database;
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    return await db.insert(
      'routine_sets',
      entity.copyWith(createdAt: now, updatedAt: now).toMap(),
    );
  }

  /// Batch insert routine sets
  Future<void> insertAll(List<RoutineSetEntity> entities) async {
    final db = await _dbHelper.database;
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final batch = db.batch();

    for (final entity in entities) {
      batch.insert(
        'routine_sets',
        entity.copyWith(createdAt: now, updatedAt: now).toMap(),
      );
    }

    await batch.commit(noResult: true);
  }

  /// Delete all sets for a routine exercise
  Future<int> deleteByRoutineExerciseId(int routineExerciseId) async {
    final db = await _dbHelper.database;

    return await db.delete(
      'routine_sets',
      where: 'routine_exercise_id = ?',
      whereArgs: [routineExerciseId],
    );
  }
}
