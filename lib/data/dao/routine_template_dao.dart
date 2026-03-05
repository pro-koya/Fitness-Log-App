import '../database/database_helper.dart';
import '../entities/routine_template_entity.dart';

/// DAO for routine_templates table
class RoutineTemplateDao {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// Get all routines ordered by most recently updated
  Future<List<RoutineTemplateEntity>> getAll() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'routine_templates',
      orderBy: 'updated_at DESC',
    );

    return maps.map((map) => RoutineTemplateEntity.fromMap(map)).toList();
  }

  /// Get routine by ID
  Future<RoutineTemplateEntity?> getById(int id) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'routine_templates',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return RoutineTemplateEntity.fromMap(maps.first);
    }
    return null;
  }

  /// Insert routine template
  Future<int> insert(RoutineTemplateEntity entity) async {
    final db = await _dbHelper.database;
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    return await db.insert(
      'routine_templates',
      entity.copyWith(createdAt: now, updatedAt: now).toMap(),
    );
  }

  /// Update routine template
  Future<int> update(RoutineTemplateEntity entity) async {
    final db = await _dbHelper.database;
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    return await db.update(
      'routine_templates',
      entity.copyWith(updatedAt: now).toMap(),
      where: 'id = ?',
      whereArgs: [entity.id],
    );
  }

  /// Delete routine template (CASCADE deletes exercises and sets)
  Future<int> delete(int id) async {
    final db = await _dbHelper.database;

    return await db.delete(
      'routine_templates',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Get routine count
  Future<int> getCount() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM routine_templates',
    );
    return result.first['count'] as int;
  }
}
