import '../database/database_helper.dart';
import '../entities/routine_exercise_entity.dart';

/// DAO for routine_exercises table
class RoutineExerciseDao {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// Get exercises by routine ID ordered by order_index
  Future<List<RoutineExerciseEntity>> getByRoutineId(int routineId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'routine_exercises',
      where: 'routine_id = ?',
      whereArgs: [routineId],
      orderBy: 'order_index ASC',
    );

    return maps.map((map) => RoutineExerciseEntity.fromMap(map)).toList();
  }

  /// Insert routine exercise
  Future<int> insert(RoutineExerciseEntity entity) async {
    final db = await _dbHelper.database;
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    return await db.insert(
      'routine_exercises',
      entity.copyWith(createdAt: now, updatedAt: now).toMap(),
    );
  }

  /// Delete all exercises for a routine
  Future<int> deleteByRoutineId(int routineId) async {
    final db = await _dbHelper.database;

    return await db.delete(
      'routine_exercises',
      where: 'routine_id = ?',
      whereArgs: [routineId],
    );
  }

  /// Get next order index for a routine
  Future<int> getNextOrderIndex(int routineId) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT MAX(order_index) as max_index FROM routine_exercises WHERE routine_id = ?',
      [routineId],
    );

    final maxIndex = result.first['max_index'] as int?;
    return (maxIndex ?? -1) + 1;
  }
}
