import '../database/database_helper.dart';
import '../entities/exercise_goal_entity.dart';

/// DAO for exercise_goals table (Pro: per-exercise goals).
class ExerciseGoalDao {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<ExerciseGoalEntity?> getByExerciseId(int exerciseId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'exercise_goals',
      where: 'exercise_id = ?',
      whereArgs: [exerciseId],
    );
    if (maps.isEmpty) return null;
    return ExerciseGoalEntity.fromMap(maps.first);
  }

  /// All goals (for 目標一覧). Order: priority desc, then by exercise_id.
  Future<List<ExerciseGoalEntity>> getAll() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'exercise_goals',
      orderBy: 'priority DESC, exercise_id ASC',
    );
    return maps.map((m) => ExerciseGoalEntity.fromMap(Map<String, dynamic>.from(m))).toList();
  }

  Future<void> upsert(ExerciseGoalEntity entity) async {
    final db = await _dbHelper.database;
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final map = {
      'exercise_id': entity.exerciseId,
      'goal_type': entity.goalType,
      'goal_value': entity.goalValue,
      'deadline_ts': entity.deadlineTs,
      'priority': entity.priority,
      'updated_at': now,
    };
    final existing = await getByExerciseId(entity.exerciseId);
    if (existing != null) {
      await db.update(
        'exercise_goals',
        {...map, 'created_at': existing.createdAt},
        where: 'exercise_id = ?',
        whereArgs: [entity.exerciseId],
      );
    } else {
      await db.insert('exercise_goals', {
        ...map,
        'created_at': now,
      });
    }
  }

  Future<void> deleteByExerciseId(int exerciseId) async {
    final db = await _dbHelper.database;
    await db.delete(
      'exercise_goals',
      where: 'exercise_id = ?',
      whereArgs: [exerciseId],
    );
  }

  /// 全件削除（クラウド pull 時にサーバー側データで置き換えるため）
  Future<void> deleteAll() async {
    final db = await _dbHelper.database;
    await db.delete('exercise_goals');
  }
}
