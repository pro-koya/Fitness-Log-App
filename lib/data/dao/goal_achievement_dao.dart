import '../database/database_helper.dart';
import '../entities/goal_achievement_entity.dart';

/// DAO for goal_achievements table (log of achieved goals for home "今週達成した目標").
class GoalAchievementDao {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<void> insert(GoalAchievementEntity entity) async {
    final db = await _dbHelper.database;
    final map = entity.toMap();
    map.remove('id');
    await db.insert('goal_achievements', map);
  }

  /// Achievements in [startTs, endTs] (inclusive), newest first.
  Future<List<GoalAchievementEntity>> getByAchievedAtBetween(
    int startTs,
    int endTs,
  ) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'goal_achievements',
      where: 'achieved_at >= ? AND achieved_at <= ?',
      whereArgs: [startTs, endTs],
      orderBy: 'achieved_at DESC',
    );
    return maps.map((m) => GoalAchievementEntity.fromMap(Map<String, dynamic>.from(m))).toList();
  }
}
