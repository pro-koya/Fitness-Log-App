import '../database/database_helper.dart';
import '../entities/set_record_entity.dart';

/// DAO for set_records table
class SetRecordDao {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// Get set record by ID
  Future<SetRecordEntity?> getSetRecordById(int id) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'set_records',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return SetRecordEntity.fromMap(maps.first);
    }
    return null;
  }

  /// Get sets by workout exercise ID
  Future<List<SetRecordEntity>> getSetsByWorkoutExerciseId(
    int workoutExerciseId,
  ) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'set_records',
      where: 'workout_exercise_id = ?',
      whereArgs: [workoutExerciseId],
      orderBy: 'set_number ASC',
    );

    return maps.map((map) => SetRecordEntity.fromMap(map)).toList();
  }

  /// Get sets by session ID
  Future<List<SetRecordEntity>> getSetsBySessionId(int sessionId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'set_records',
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'set_number ASC',
    );

    return maps.map((map) => SetRecordEntity.fromMap(map)).toList();
  }

  /// Get previous sets for an exercise (from latest completed session)
  Future<List<SetRecordEntity>> getPreviousSetsForExercise(
    int exerciseId,
    int beforeTimestamp,
  ) async {
    final db = await _dbHelper.database;
    final maps = await db.rawQuery(
      '''
      SELECT sr.*
      FROM set_records sr
      JOIN workout_sessions ws ON sr.session_id = ws.id
      WHERE sr.exercise_id = ?
        AND ws.status = 'completed'
        AND ws.completed_at < ?
      ORDER BY ws.completed_at DESC, sr.set_number ASC
      LIMIT 20
      ''',
      [exerciseId, beforeTimestamp],
    );

    if (maps.isEmpty) return [];

    // Get the latest session's sets only
    final latestSessionId = maps.first['session_id'] as int;
    return maps
        .where((map) => map['session_id'] == latestSessionId)
        .map((map) => SetRecordEntity.fromMap(map))
        .toList();
  }

  /// Insert set record
  Future<int> insertSetRecord(SetRecordEntity setRecord) async {
    final db = await _dbHelper.database;
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    return await db.insert(
      'set_records',
      setRecord.copyWith(createdAt: now, updatedAt: now).toMap(),
    );
  }

  /// Update set record
  Future<int> updateSetRecord(SetRecordEntity setRecord) async {
    final db = await _dbHelper.database;
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    return await db.update(
      'set_records',
      setRecord.copyWith(updatedAt: now).toMap(),
      where: 'id = ?',
      whereArgs: [setRecord.id],
    );
  }

  /// Delete set record
  Future<int> deleteSetRecord(int id) async {
    final db = await _dbHelper.database;

    return await db.delete(
      'set_records',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Delete all sets for a workout exercise
  Future<int> deleteSetsByWorkoutExerciseId(int workoutExerciseId) async {
    final db = await _dbHelper.database;

    return await db.delete(
      'set_records',
      where: 'workout_exercise_id = ?',
      whereArgs: [workoutExerciseId],
    );
  }

  /// Delete all set records (Pro sync: pull from server でローカル全削除時に使用)
  Future<int> deleteAll() async {
    final db = await _dbHelper.database;
    return await db.delete('set_records', where: '1');
  }

  /// Get max set number for a workout exercise
  Future<int> getMaxSetNumber(int workoutExerciseId) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      '''
      SELECT COALESCE(MAX(set_number), 0) as max_set_number
      FROM set_records
      WHERE workout_exercise_id = ?
      ''',
      [workoutExerciseId],
    );

    return result.first['max_set_number'] as int;
  }

  /// Get top weight for an exercise (for progress tracking)
  Future<double?> getTopWeightForExercise(
    int exerciseId,
    String unit,
  ) async {
    final db = await _dbHelper.database;

    // Select the appropriate weight column based on unit
    final weightColumn = unit == 'kg' ? 'weight_kg' : 'weight_lb';

    final result = await db.rawQuery(
      '''
      SELECT MAX(sr.$weightColumn) as top_weight
      FROM set_records sr
      JOIN workout_sessions ws ON sr.session_id = ws.id
      WHERE sr.exercise_id = ?
        AND ws.status = 'completed'
      ''',
      [exerciseId],
    );

    final topWeight = result.first['top_weight'];
    return topWeight != null ? (topWeight as num).toDouble() : null;
  }

  /// Get top weight for an exercise in a specific session
  Future<double?> getTopWeightForExerciseInSession(
    int exerciseId,
    int sessionId,
    String unit,
  ) async {
    final db = await _dbHelper.database;
    final weightColumn = unit == 'kg' ? 'weight_kg' : 'weight_lb';

    final result = await db.rawQuery(
      '''
      SELECT MAX($weightColumn) as top_weight
      FROM set_records
      WHERE exercise_id = ? AND session_id = ?
        AND reps > 0
      ''',
      [exerciseId, sessionId],
    );

    final val = result.first['top_weight'];
    return val != null ? (val as num).toDouble() : null;
  }

  /// Returns exercise IDs that have at least one set_record in a completed session.
  /// Used for bulk goal registration (only exercises with history can have goals calculated).
  Future<List<int>> getExerciseIdsWithHistory() async {
    final db = await _dbHelper.database;
    final maps = await db.rawQuery(
      '''
      SELECT DISTINCT sr.exercise_id
      FROM set_records sr
      JOIN workout_sessions ws ON sr.session_id = ws.id
      WHERE ws.status = 'completed'
      ORDER BY sr.exercise_id ASC
      ''',
    );
    return maps.map((m) => m['exercise_id'] as int).toList();
  }

  /// Get best value for an exercise across all completed sessions (for Pro goal progress).
  /// [goalType] one of: weight, reps, volume, time, distance.
  /// [includeSessionId] when set, this session's sets are included even if the session is not completed (for goal check right after save).
  /// Returns null if no sets. Weight in kg; volume = weight_kg*reps; time in seconds; distance in meters.
  Future<double?> getBestValueForExercise(
    int exerciseId,
    String goalType, {
    int? includeSessionId,
  }) async {
    final db = await _dbHelper.database;
    String expr;
    switch (goalType) {
      case 'weight':
        expr = 'MAX(sr.weight_kg)';
        break;
      case 'reps':
        expr = 'MAX(sr.reps)';
        break;
      case 'volume':
        expr = 'MAX(sr.weight_kg * sr.reps)';
        break;
      case 'time':
        expr = 'MAX(sr.duration_seconds)';
        break;
      case 'distance':
        expr = 'MAX(sr.distance_meters)';
        break;
      default:
        return null;
    }
    final String whereClause = includeSessionId != null
        ? 'sr.exercise_id = ? AND (ws.status = \'completed\' OR sr.session_id = ?)'
        : 'sr.exercise_id = ? AND ws.status = \'completed\'';
    final whereArgs = includeSessionId != null
        ? [exerciseId, includeSessionId]
        : [exerciseId];
    final result = await db.rawQuery(
      '''
      SELECT $expr as best_value
      FROM set_records sr
      JOIN workout_sessions ws ON sr.session_id = ws.id
      WHERE $whereClause
      ''',
      whereArgs,
    );
    final val = result.first['best_value'];
    if (val == null) return null;
    return (val as num).toDouble();
  }

  /// Get top duration (seconds) for a time-based exercise in a session
  Future<int?> getTopDurationForExerciseInSession(
    int exerciseId,
    int sessionId,
  ) async {
    final db = await _dbHelper.database;

    final result = await db.rawQuery(
      '''
      SELECT MAX(duration_seconds) as top_duration
      FROM set_records
      WHERE exercise_id = ? AND session_id = ?
        AND duration_seconds IS NOT NULL
        AND duration_seconds > 0
      ''',
      [exerciseId, sessionId],
    );

    final val = result.first['top_duration'];
    return val != null ? (val as num).toInt() : null;
  }

  /// Get total volume for a session (weight * reps, uses unit column)
  Future<double> getTotalVolumeForSession(int sessionId, String unit) async {
    final db = await _dbHelper.database;
    final weightColumn = unit == 'kg' ? 'weight_kg' : 'weight_lb';

    final result = await db.rawQuery(
      '''
      SELECT SUM($weightColumn * COALESCE(reps, 0)) as total_volume
      FROM set_records
      WHERE session_id = ?
        AND reps > 0
      ''',
      [sessionId],
    );

    final volume = result.first['total_volume'];
    return volume != null ? (volume as num).toDouble() : 0.0;
  }

  /// Get total volume for an exercise in a session
  Future<double> getTotalVolumeForExerciseInSession(
    int exerciseId,
    int sessionId,
  ) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      '''
      SELECT SUM(weight * reps) as total_volume
      FROM set_records
      WHERE exercise_id = ?
        AND session_id = ?
      ''',
      [exerciseId, sessionId],
    );

    final volume = result.first['total_volume'];
    return volume != null ? (volume as num).toDouble() : 0.0;
  }

  /// Get progress data for an exercise (date, top weight, total volume)
  /// Returns a list of maps with keys: date, topWeight, totalVolume
  /// Automatically uses the correct weight column based on unit
  Future<List<Map<String, dynamic>>> getProgressDataForExercise(
    int exerciseId,
    String unit, {
    int? startTimestamp,
  }) async {
    final db = await _dbHelper.database;

    // Select the appropriate weight column based on unit
    final weightColumn = unit == 'kg' ? 'weight_kg' : 'weight_lb';

    String dateFilter = '';
    final List<dynamic> args = [exerciseId];
    if (startTimestamp != null) {
      dateFilter = 'AND ws.completed_at >= ?';
      args.add(startTimestamp);
    }

    final maps = await db.rawQuery(
      '''
      SELECT
        ws.completed_at as date,
        MAX(sr.$weightColumn) as topWeight,
        SUM(sr.$weightColumn * sr.reps) as totalVolume
      FROM set_records sr
      JOIN workout_sessions ws ON sr.session_id = ws.id
      WHERE sr.exercise_id = ?
        AND ws.status = 'completed'
        $dateFilter
      GROUP BY ws.id
      ORDER BY ws.completed_at ASC
      ''',
      args,
    );

    return maps
        .map((map) => {
              'date': map['date'] as int,
              'topWeight': (map['topWeight'] as num?)?.toDouble() ?? 0.0,
              'totalVolume': (map['totalVolume'] as num?)?.toDouble() ?? 0.0,
            })
        .toList();
  }

  /// Get progress data for a time-based exercise (date, best duration, total duration)
  /// Returns a list of maps with keys: date, topDurationSeconds, totalDurationSeconds
  Future<List<Map<String, dynamic>>> getProgressDataForExerciseTime(
    int exerciseId, {
    int? startTimestamp,
  }) async {
    final db = await _dbHelper.database;

    String dateFilter = '';
    final List<dynamic> args = [exerciseId];
    if (startTimestamp != null) {
      dateFilter = 'AND ws.completed_at >= ?';
      args.add(startTimestamp);
    }

    final maps = await db.rawQuery(
      '''
      SELECT
        ws.completed_at as date,
        MAX(COALESCE(sr.duration_seconds, 0)) as topDurationSeconds,
        SUM(COALESCE(sr.duration_seconds, 0)) as totalDurationSeconds
      FROM set_records sr
      JOIN workout_sessions ws ON sr.session_id = ws.id
      WHERE sr.exercise_id = ?
        AND ws.status = 'completed'
        $dateFilter
      GROUP BY ws.id
      ORDER BY ws.completed_at ASC
      ''',
      args,
    );

    return maps
        .map((map) => {
              'date': map['date'] as int,
              'topDurationSeconds':
                  (map['topDurationSeconds'] as num?)?.toInt() ?? 0,
              'totalDurationSeconds':
                  (map['totalDurationSeconds'] as num?)?.toInt() ?? 0,
            })
        .toList();
  }

  /// Get progress data for a reps-based exercise (date, top reps, total reps)
  /// Returns a list of maps with keys: date, topReps, totalReps
  Future<List<Map<String, dynamic>>> getProgressDataForExerciseReps(
    int exerciseId, {
    int? startTimestamp,
  }) async {
    final db = await _dbHelper.database;

    String dateFilter = '';
    final List<dynamic> args = [exerciseId];
    if (startTimestamp != null) {
      dateFilter = 'AND ws.completed_at >= ?';
      args.add(startTimestamp);
    }

    final maps = await db.rawQuery(
      '''
      SELECT
        ws.completed_at as date,
        MAX(COALESCE(sr.reps, 0)) as topReps,
        SUM(COALESCE(sr.reps, 0)) as totalReps
      FROM set_records sr
      JOIN workout_sessions ws ON sr.session_id = ws.id
      WHERE sr.exercise_id = ?
        AND ws.status = 'completed'
        $dateFilter
      GROUP BY ws.id
      ORDER BY ws.completed_at ASC
      ''',
      args,
    );

    return maps
        .map((map) => {
              'date': map['date'] as int,
              'topReps': (map['topReps'] as num?)?.toInt() ?? 0,
              'totalReps': (map['totalReps'] as num?)?.toInt() ?? 0,
            })
        .toList();
  }

  /// Get best reps for each weight used in completed sessions.
  /// Returns a list of maps with keys: weight, maxReps
  /// Automatically uses the correct weight column based on unit.
  Future<List<Map<String, dynamic>>> getBestRepsByWeightForExercise(
    int exerciseId,
    String unit, {
    int? startTimestamp,
  }) async {
    final db = await _dbHelper.database;
    final weightColumn = unit == 'kg' ? 'weight_kg' : 'weight_lb';

    String dateFilter = '';
    final List<dynamic> args = [exerciseId];
    if (startTimestamp != null) {
      dateFilter = 'AND ws.completed_at >= ?';
      args.add(startTimestamp);
    }

    final maps = await db.rawQuery(
      '''
      SELECT
        ROUND(sr.$weightColumn, 1) as weight,
        MAX(COALESCE(sr.reps, 0)) as maxReps
      FROM set_records sr
      JOIN workout_sessions ws ON sr.session_id = ws.id
      WHERE sr.exercise_id = ?
        AND ws.status = 'completed'
        AND sr.reps > 0
        AND sr.$weightColumn > 0
        $dateFilter
      GROUP BY ROUND(sr.$weightColumn, 1)
      ORDER BY weight DESC
      ''',
      args,
    );

    return maps
        .map((map) => {
              'weight': (map['weight'] as num?)?.toDouble() ?? 0.0,
              'maxReps': (map['maxReps'] as num?)?.toInt() ?? 0,
            })
        .toList();
  }

  /// Get progress data for volume (weight * reps per set)
  /// Returns a list of maps with keys: date, maxVolume (max weight*reps per session), weight, reps
  /// Automatically uses the correct weight column based on unit
  Future<List<Map<String, dynamic>>> getProgressDataForExerciseVolume(
    int exerciseId,
    String unit, {
    int? startTimestamp,
  }) async {
    final db = await _dbHelper.database;

    // Select the appropriate weight column based on unit
    final weightColumn = unit == 'kg' ? 'weight_kg' : 'weight_lb';

    String dateFilter = '';
    final List<dynamic> args = [exerciseId];
    if (startTimestamp != null) {
      dateFilter = 'AND ws.completed_at >= ?';
      args.add(startTimestamp);
    }

    final maps = await db.rawQuery(
      '''
      SELECT
        ws.completed_at as date,
        MAX($weightColumn * COALESCE(sr.reps, 0)) as maxVolume
      FROM set_records sr
      JOIN workout_sessions ws ON sr.session_id = ws.id
      WHERE sr.exercise_id = ?
        AND ws.status = 'completed'
        AND sr.reps > 0
        $dateFilter
      GROUP BY ws.id
      ORDER BY ws.completed_at ASC
      ''',
      args,
    );

    // For each session, find the set with max volume and get its weight and reps
    final List<Map<String, dynamic>> result = [];
    for (final sessionMap in maps) {
      final sessionDate = sessionMap['date'] as int;
      final maxVolume = (sessionMap['maxVolume'] as num?)?.toDouble() ?? 0.0;

      // Find the set with max volume in this session (ORDER BY product DESC to avoid floating-point equality)
      final setMaps = await db.rawQuery(
        '''
        SELECT $weightColumn as weight, sr.reps
        FROM set_records sr
        JOIN workout_sessions ws ON sr.session_id = ws.id
        WHERE sr.exercise_id = ?
          AND ws.status = 'completed'
          AND ws.completed_at = ?
          AND sr.reps > 0
        ORDER BY ($weightColumn * sr.reps) DESC
        LIMIT 1
        ''',
        [exerciseId, sessionDate],
      );

      double? weight;
      int? reps;
      if (setMaps.isNotEmpty) {
        weight = (setMaps.first['weight'] as num?)?.toDouble();
        reps = setMaps.first['reps'] as int?;
      }

      result.add({
        'date': sessionDate,
        'maxVolume': maxVolume,
        'weight': weight,
        'reps': reps,
      });
    }

    return result;
  }

  /// Get all history sessions for an exercise (grouped by session, newest first)
  /// Returns a list of maps with session info and sets
  Future<List<Map<String, dynamic>>> getAllHistoryForExercise(
    int exerciseId,
    int beforeTimestamp, {
    int limit = 10,
  }) async {
    final db = await _dbHelper.database;

    // Get all completed sessions with sets for this exercise
    final sessionMaps = await db.rawQuery(
      '''
      SELECT DISTINCT
        ws.id as session_id,
        ws.completed_at
      FROM workout_sessions ws
      JOIN set_records sr ON sr.session_id = ws.id
      WHERE sr.exercise_id = ?
        AND ws.status = 'completed'
        AND ws.completed_at < ?
      ORDER BY ws.completed_at DESC
      LIMIT ?
      ''',
      [exerciseId, beforeTimestamp, limit],
    );

    // For each session, get all sets
    final List<Map<String, dynamic>> result = [];
    for (final sessionMap in sessionMaps) {
      final sessionId = sessionMap['session_id'] as int;
      final completedAt = sessionMap['completed_at'] as int;

      final setMaps = await db.query(
        'set_records',
        where: 'session_id = ? AND exercise_id = ?',
        whereArgs: [sessionId, exerciseId],
        orderBy: 'set_number ASC',
      );

      final sets = setMaps.map((map) => SetRecordEntity.fromMap(map)).toList();

      result.add({
        'sessionId': sessionId,
        'completedAt': completedAt,
        'sets': sets,
      });
    }

    return result;
  }

  /// Get total sets count for a month
  /// If bodyPart is provided, filter by body part. If null, return all sets.
  /// Includes both reps-based sets (reps > 0) and time-based sets (duration_seconds > 0)
  Future<int> getTotalSetsForMonth(
    int year,
    int month, {
    String? bodyPart,
  }) async {
    final db = await _dbHelper.database;

    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0, 23, 59, 59);
    final startTimestamp = startDate.millisecondsSinceEpoch ~/ 1000;
    final endTimestamp = endDate.millisecondsSinceEpoch ~/ 1000;

    String query = '''
      SELECT COUNT(*) as total_sets
      FROM set_records sr
      JOIN workout_sessions ws ON sr.session_id = ws.id
      JOIN exercise_master em ON sr.exercise_id = em.id
      WHERE ws.status = 'completed'
        AND ws.completed_at >= ?
        AND ws.completed_at <= ?
        AND sr.weight_kg >= 0
        AND (sr.reps > 0 OR sr.duration_seconds > 0)
    ''';

    final List<dynamic> args = [startTimestamp, endTimestamp];
    if (bodyPart != null) {
      query += ' AND em.body_part = ?';
      args.add(bodyPart);
    }

    final result = await db.rawQuery(query, args);

    return result.first['total_sets'] as int;
  }

  /// Get total volume for a month (weight * reps)
  /// If bodyPart is provided, filter by body part. If null, return all volume.
  Future<double> getTotalVolumeForMonth(
    int year,
    int month, {
    String? bodyPart,
  }) async {
    final db = await _dbHelper.database;

    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0, 23, 59, 59);
    final startTimestamp = startDate.millisecondsSinceEpoch ~/ 1000;
    final endTimestamp = endDate.millisecondsSinceEpoch ~/ 1000;

    String query = '''
      SELECT SUM(sr.weight_kg * sr.reps) as total_volume
      FROM set_records sr
      JOIN workout_sessions ws ON sr.session_id = ws.id
      JOIN exercise_master em ON sr.exercise_id = em.id
      WHERE ws.status = 'completed'
        AND ws.completed_at >= ?
        AND ws.completed_at <= ?
        AND sr.weight_kg >= 0
        AND sr.reps > 0
    ''';

    final List<dynamic> args = [startTimestamp, endTimestamp];
    if (bodyPart != null) {
      query += ' AND em.body_part = ?';
      args.add(bodyPart);
    }

    final result = await db.rawQuery(query, args);

    final volume = result.first['total_volume'];
    return volume != null ? (volume as num).toDouble() : 0.0;
  }

  /// Get total time for a month (sum of duration_seconds for time-based exercises)
  /// If bodyPart is provided, filter by body part. If null, return all time.
  /// Returns total time in seconds
  Future<int> getTotalTimeForMonth(
    int year,
    int month, {
    String? bodyPart,
  }) async {
    final db = await _dbHelper.database;

    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0, 23, 59, 59);
    final startTimestamp = startDate.millisecondsSinceEpoch ~/ 1000;
    final endTimestamp = endDate.millisecondsSinceEpoch ~/ 1000;

    String query = '''
      SELECT SUM(COALESCE(sr.duration_seconds, 0)) as total_time
      FROM set_records sr
      JOIN workout_sessions ws ON sr.session_id = ws.id
      JOIN exercise_master em ON sr.exercise_id = em.id
      WHERE ws.status = 'completed'
        AND ws.completed_at >= ?
        AND ws.completed_at <= ?
        AND sr.duration_seconds > 0
    ''';

    final List<dynamic> args = [startTimestamp, endTimestamp];
    if (bodyPart != null) {
      query += ' AND em.body_part = ?';
      args.add(bodyPart);
    }

    final result = await db.rawQuery(query, args);

    final totalTime = result.first['total_time'];
    return totalTime != null ? (totalTime as num).toInt() : 0;
  }

  /// Get progress data for cardio time (total duration per session)
  /// Returns a list of maps with keys: date, topDurationSeconds, totalDurationSeconds
  Future<List<Map<String, dynamic>>> getProgressDataForCardioTime(
    int exerciseId, {
    int? startTimestamp,
  }) async {
    final db = await _dbHelper.database;

    String dateFilter = '';
    final List<dynamic> args = [exerciseId];
    if (startTimestamp != null) {
      dateFilter = 'AND ws.completed_at >= ?';
      args.add(startTimestamp);
    }

    final maps = await db.rawQuery(
      '''
      SELECT
        ws.completed_at as date,
        SUM(COALESCE(sr.duration_seconds, 0)) as totalDurationSeconds
      FROM set_records sr
      JOIN workout_sessions ws ON sr.session_id = ws.id
      WHERE sr.exercise_id = ?
        AND ws.status = 'completed'
        $dateFilter
      GROUP BY ws.id
      ORDER BY ws.completed_at ASC
      ''',
      args,
    );

    return maps
        .map((map) => {
              'date': map['date'] as int,
              'totalDurationSeconds':
                  (map['totalDurationSeconds'] as num?)?.toInt() ?? 0,
            })
        .toList();
  }

  /// Get progress data for cardio distance (total distance per session)
  /// Returns a list of maps with keys: date, totalDistanceMeters
  Future<List<Map<String, dynamic>>> getProgressDataForCardioDistance(
    int exerciseId, {
    int? startTimestamp,
  }) async {
    final db = await _dbHelper.database;

    String dateFilter = '';
    final List<dynamic> args = [exerciseId];
    if (startTimestamp != null) {
      dateFilter = 'AND ws.completed_at >= ?';
      args.add(startTimestamp);
    }

    final maps = await db.rawQuery(
      '''
      SELECT
        ws.completed_at as date,
        SUM(COALESCE(sr.distance_meters, 0)) as totalDistanceMeters
      FROM set_records sr
      JOIN workout_sessions ws ON sr.session_id = ws.id
      WHERE sr.exercise_id = ?
        AND ws.status = 'completed'
        $dateFilter
      GROUP BY ws.id
      ORDER BY ws.completed_at ASC
      ''',
      args,
    );

    return maps
        .map((map) => {
              'date': map['date'] as int,
              'totalDistanceMeters':
                  (map['totalDistanceMeters'] as num?)?.toDouble() ?? 0.0,
            })
        .toList();
  }

  /// Get progress data for cardio speed (distance / time per session)
  /// Returns a list of maps with keys: date, speedKmPerHour
  /// Speed is calculated as: totalDistanceKm / totalHours
  Future<List<Map<String, dynamic>>> getProgressDataForCardioPace(
    int exerciseId, {
    int? startTimestamp,
  }) async {
    final db = await _dbHelper.database;

    String dateFilter = '';
    final List<dynamic> args = [exerciseId];
    if (startTimestamp != null) {
      dateFilter = 'AND ws.completed_at >= ?';
      args.add(startTimestamp);
    }

    final maps = await db.rawQuery(
      '''
      SELECT
        ws.completed_at as date,
        SUM(COALESCE(sr.duration_seconds, 0)) as totalDurationSeconds,
        SUM(COALESCE(sr.distance_meters, 0)) as totalDistanceMeters
      FROM set_records sr
      JOIN workout_sessions ws ON sr.session_id = ws.id
      WHERE sr.exercise_id = ?
        AND ws.status = 'completed'
        $dateFilter
      GROUP BY ws.id
      HAVING totalDistanceMeters > 0 AND totalDurationSeconds > 0
      ORDER BY ws.completed_at ASC
      ''',
      args,
    );

    return maps
        .map((map) {
          final totalSeconds =
              (map['totalDurationSeconds'] as num?)?.toDouble() ?? 0.0;
          final totalMeters =
              (map['totalDistanceMeters'] as num?)?.toDouble() ?? 0.0;

          // Calculate speed in km/h
          double speedKmPerHour = 0.0;
          if (totalSeconds > 0 && totalMeters > 0) {
            final totalKm = totalMeters / 1000.0;
            final totalHours = totalSeconds / 3600.0;
            speedKmPerHour = totalKm / totalHours;
          }

          return {
            'date': map['date'] as int,
            'speedKmPerHour': speedKmPerHour,
            'totalDurationSeconds': totalSeconds,
            'totalDistanceMeters': totalMeters,
          };
        })
        .toList();
  }

  /// Get total distance for a month (sum of distance_meters for cardio exercises)
  /// If bodyPart is provided, filter by body part. If null, return all distance.
  /// Returns total distance in meters
  Future<double> getTotalDistanceForMonth(
    int year,
    int month, {
    String? bodyPart,
  }) async {
    final db = await _dbHelper.database;

    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0, 23, 59, 59);
    final startTimestamp = startDate.millisecondsSinceEpoch ~/ 1000;
    final endTimestamp = endDate.millisecondsSinceEpoch ~/ 1000;

    String query = '''
      SELECT SUM(COALESCE(sr.distance_meters, 0)) as total_distance
      FROM set_records sr
      JOIN workout_sessions ws ON sr.session_id = ws.id
      JOIN exercise_master em ON sr.exercise_id = em.id
      WHERE ws.status = 'completed'
        AND ws.completed_at >= ?
        AND ws.completed_at <= ?
        AND sr.distance_meters > 0
    ''';

    final List<dynamic> args = [startTimestamp, endTimestamp];
    if (bodyPart != null) {
      query += ' AND em.body_part = ?';
      args.add(bodyPart);
    }

    final result = await db.rawQuery(query, args);

    final totalDistance = result.first['total_distance'];
    return totalDistance != null ? (totalDistance as num).toDouble() : 0.0;
  }

  /// Get most frequent exercises for a month (top 3)
  /// Returns a list of maps with exercise_id, exercise_name, and count
  /// If bodyPart is provided, filter by body part. If null, return all exercises.
  Future<List<Map<String, dynamic>>> getMostFrequentExercisesForMonth(
    int year,
    int month, {
    int limit = 3,
    String? bodyPart,
  }) async {
    final db = await _dbHelper.database;

    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0, 23, 59, 59);
    final startTimestamp = startDate.millisecondsSinceEpoch ~/ 1000;
    final endTimestamp = endDate.millisecondsSinceEpoch ~/ 1000;

    String query = '''
      SELECT
        sr.exercise_id,
        em.name as exercise_name,
        em.is_custom,
        COUNT(DISTINCT sr.session_id) as session_count,
        COUNT(*) as set_count
      FROM set_records sr
      JOIN workout_sessions ws ON sr.session_id = ws.id
      JOIN exercise_master em ON sr.exercise_id = em.id
      WHERE ws.status = 'completed'
        AND ws.completed_at >= ?
        AND ws.completed_at <= ?
    ''';

    final List<dynamic> args = [startTimestamp, endTimestamp];
    if (bodyPart != null) {
      query += ' AND em.body_part = ?';
      args.add(bodyPart);
    }

    query += '''
      GROUP BY sr.exercise_id, em.name, em.is_custom
      ORDER BY session_count DESC, set_count DESC
      LIMIT ?
    ''';

    args.add(limit);

    final maps = await db.rawQuery(query, args);

    return maps
        .map((map) => {
              'exerciseId': map['exercise_id'] as int,
              'exerciseName': map['exercise_name'] as String,
              'isCustom': map['is_custom'] as int,
              'sessionCount': map['session_count'] as int,
              'setCount': map['set_count'] as int,
            })
        .toList();
  }
}
