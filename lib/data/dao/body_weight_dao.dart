import '../database/database_helper.dart';
import '../entities/body_weight_entity.dart';

/// DAO for body_weight_records table
class BodyWeightDao {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// Insert a body weight record
  Future<int> insert(BodyWeightEntity entity) async {
    final db = await _dbHelper.database;
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return await db.insert(
      'body_weight_records',
      entity.copyWith(createdAt: now, updatedAt: now).toMap(),
    );
  }

  /// Update a body weight record
  Future<int> update(BodyWeightEntity entity) async {
    final db = await _dbHelper.database;
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return await db.update(
      'body_weight_records',
      entity.copyWith(updatedAt: now).toMap(),
      where: 'id = ?',
      whereArgs: [entity.id],
    );
  }

  /// Delete a body weight record
  Future<int> delete(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'body_weight_records',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Delete all body weight records (Pro sync: pull from server でローカル全削除時に使用)
  Future<int> deleteAll() async {
    final db = await _dbHelper.database;
    return await db.delete('body_weight_records', where: '1');
  }

  /// Get the latest record
  Future<BodyWeightEntity?> getLatest() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'body_weight_records',
      orderBy: 'recorded_at DESC',
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return BodyWeightEntity.fromMap(maps.first);
  }

  /// Get the previous record (second most recent)
  Future<BodyWeightEntity?> getPrevious() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'body_weight_records',
      orderBy: 'recorded_at DESC',
      limit: 1,
      offset: 1,
    );
    if (maps.isEmpty) return null;
    return BodyWeightEntity.fromMap(maps.first);
  }

  /// Get record by date (start of day timestamp)
  Future<BodyWeightEntity?> getByDate(int startOfDayTimestamp) async {
    final db = await _dbHelper.database;
    final endOfDay = startOfDayTimestamp + 86400; // +24 hours
    final maps = await db.query(
      'body_weight_records',
      where: 'recorded_at >= ? AND recorded_at < ?',
      whereArgs: [startOfDayTimestamp, endOfDay],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return BodyWeightEntity.fromMap(maps.first);
  }

  /// Get all records, optionally filtered by start timestamp
  Future<List<BodyWeightEntity>> getAll({int? startTimestamp}) async {
    final db = await _dbHelper.database;
    String? where;
    List<dynamic>? whereArgs;
    if (startTimestamp != null) {
      where = 'recorded_at >= ?';
      whereArgs = [startTimestamp];
    }
    final maps = await db.query(
      'body_weight_records',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'recorded_at ASC',
    );
    return maps.map((m) => BodyWeightEntity.fromMap(m)).toList();
  }

  /// Get all records descending (for history display)
  Future<List<BodyWeightEntity>> getAllDesc() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'body_weight_records',
      orderBy: 'recorded_at DESC',
    );
    return maps.map((m) => BodyWeightEntity.fromMap(m)).toList();
  }

  /// Get the first (oldest) record
  Future<BodyWeightEntity?> getFirst() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'body_weight_records',
      orderBy: 'recorded_at ASC',
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return BodyWeightEntity.fromMap(maps.first);
  }

  /// Get record count for a specific month
  Future<int> getCountThisMonth(int year, int month) async {
    final db = await _dbHelper.database;
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0, 23, 59, 59);
    final startTimestamp = startDate.millisecondsSinceEpoch ~/ 1000;
    final endTimestamp = endDate.millisecondsSinceEpoch ~/ 1000;

    final result = await db.rawQuery(
      '''
      SELECT COUNT(*) as cnt FROM body_weight_records
      WHERE recorded_at >= ? AND recorded_at <= ?
      ''',
      [startTimestamp, endTimestamp],
    );
    return result.first['cnt'] as int;
  }

  /// Get total record count
  Future<int> getCount() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as cnt FROM body_weight_records',
    );
    return result.first['cnt'] as int;
  }

  /// Get min weight
  Future<double?> getMin(String unitColumn) async {
    final db = await _dbHelper.database;
    final col = unitColumn == 'lb' ? 'weight_lb' : 'weight_kg';
    final result = await db.rawQuery(
      'SELECT MIN($col) as min_val FROM body_weight_records',
    );
    final val = result.first['min_val'];
    return val != null ? (val as num).toDouble() : null;
  }

  /// Get max weight
  Future<double?> getMax(String unitColumn) async {
    final db = await _dbHelper.database;
    final col = unitColumn == 'lb' ? 'weight_lb' : 'weight_kg';
    final result = await db.rawQuery(
      'SELECT MAX($col) as max_val FROM body_weight_records',
    );
    final val = result.first['max_val'];
    return val != null ? (val as num).toDouble() : null;
  }

  /// Get average body weight for a specific month (for monthly summary).
  /// Returns null if no records in that month.
  Future<double?> getAverageWeightForMonth(
    int year,
    int month,
    String unit,
  ) async {
    final db = await _dbHelper.database;
    final col = unit == 'lb' ? 'weight_lb' : 'weight_kg';
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0, 23, 59, 59);
    final startTimestamp = startDate.millisecondsSinceEpoch ~/ 1000;
    final endTimestamp = endDate.millisecondsSinceEpoch ~/ 1000;

    final result = await db.rawQuery(
      '''
      SELECT AVG($col) as avg_val FROM body_weight_records
      WHERE recorded_at >= ? AND recorded_at <= ?
      ''',
      [startTimestamp, endTimestamp],
    );
    final val = result.first['avg_val'];
    return val != null ? (val as num).toDouble() : null;
  }

  /// Get body weight change in a month (first record vs last record of the month)
  Future<double?> getMonthlyChange(int year, int month, String unit) async {
    final db = await _dbHelper.database;
    final col = unit == 'lb' ? 'weight_lb' : 'weight_kg';

    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0, 23, 59, 59);
    final startTimestamp = startDate.millisecondsSinceEpoch ~/ 1000;
    final endTimestamp = endDate.millisecondsSinceEpoch ~/ 1000;

    // Get first record of the month
    final firstMaps = await db.query(
      'body_weight_records',
      columns: [col],
      where: 'recorded_at >= ? AND recorded_at <= ?',
      whereArgs: [startTimestamp, endTimestamp],
      orderBy: 'recorded_at ASC',
      limit: 1,
    );

    // Get last record of the month
    final lastMaps = await db.query(
      'body_weight_records',
      columns: [col],
      where: 'recorded_at >= ? AND recorded_at <= ?',
      whereArgs: [startTimestamp, endTimestamp],
      orderBy: 'recorded_at DESC',
      limit: 1,
    );

    if (firstMaps.isEmpty || lastMaps.isEmpty) return null;

    final firstWeight = (firstMaps.first[col] as num).toDouble();
    final lastWeight = (lastMaps.first[col] as num).toDouble();
    return lastWeight - firstWeight;
  }
}
