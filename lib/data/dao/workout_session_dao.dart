import '../database/database_helper.dart';
import '../entities/workout_session_entity.dart';

/// DAO for workout_sessions table
class WorkoutSessionDao {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// Get session by ID
  Future<WorkoutSessionEntity?> getSessionById(int id) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'workout_sessions',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return WorkoutSessionEntity.fromMap(maps.first);
    }
    return null;
  }

  /// Get in-progress session
  Future<WorkoutSessionEntity?> getInProgressSession() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'workout_sessions',
      where: 'status = ?',
      whereArgs: ['in_progress'],
      orderBy: 'started_at DESC',
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return WorkoutSessionEntity.fromMap(maps.first);
    }
    return null;
  }

  /// Get completed sessions
  Future<List<WorkoutSessionEntity>> getCompletedSessions({
    int? limit,
    int? offset,
  }) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'workout_sessions',
      where: 'status = ?',
      whereArgs: ['completed'],
      orderBy: 'completed_at DESC',
      limit: limit,
      offset: offset,
    );

    return maps.map((map) => WorkoutSessionEntity.fromMap(map)).toList();
  }

  /// Get sessions by date range
  Future<List<WorkoutSessionEntity>> getSessionsByDateRange({
    required int startTimestamp,
    required int endTimestamp,
  }) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'workout_sessions',
      where: 'status = ? AND completed_at >= ? AND completed_at <= ?',
      whereArgs: ['completed', startTimestamp, endTimestamp],
      orderBy: 'completed_at DESC',
    );

    return maps.map((map) => WorkoutSessionEntity.fromMap(map)).toList();
  }

  /// Insert session
  Future<int> insertSession(WorkoutSessionEntity session) async {
    final db = await _dbHelper.database;
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    return await db.insert(
      'workout_sessions',
      session.copyWith(createdAt: now, updatedAt: now).toMap(),
    );
  }

  /// Update session
  Future<int> updateSession(WorkoutSessionEntity session) async {
    final db = await _dbHelper.database;
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    return await db.update(
      'workout_sessions',
      session.copyWith(updatedAt: now).toMap(),
      where: 'id = ?',
      whereArgs: [session.id],
    );
  }

  /// Complete session
  /// Only updates completed_at if session is not already completed
  Future<int> completeSession(int sessionId) async {
    final db = await _dbHelper.database;
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    // Check if session is already completed
    final session = await getSessionById(sessionId);
    if (session != null && session.status == 'completed') {
      // Already completed, only update updated_at
      return await db.update(
        'workout_sessions',
        {
          'updated_at': now,
        },
        where: 'id = ?',
        whereArgs: [sessionId],
      );
    }

    // Not completed yet, set status and completed_at
    return await db.update(
      'workout_sessions',
      {
        'status': 'completed',
        'completed_at': now,
        'updated_at': now,
      },
      where: 'id = ?',
      whereArgs: [sessionId],
    );
  }

  /// Update session start and end times
  Future<int> updateSessionTimes(
    int sessionId,
    int startedAt,
    int? completedAt,
  ) async {
    final db = await _dbHelper.database;
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    return await db.update(
      'workout_sessions',
      {
        'started_at': startedAt,
        'completed_at': completedAt,
        'updated_at': now,
      },
      where: 'id = ?',
      whereArgs: [sessionId],
    );
  }

  /// Delete session
  Future<int> deleteSession(int id) async {
    final db = await _dbHelper.database;

    return await db.delete(
      'workout_sessions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Count sessions in current month
  Future<int> countSessionsInMonth(int year, int month) async {
    final db = await _dbHelper.database;

    // Calculate start and end timestamps for the month
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0, 23, 59, 59);
    final startTimestamp = startDate.millisecondsSinceEpoch ~/ 1000;
    final endTimestamp = endDate.millisecondsSinceEpoch ~/ 1000;

    final result = await db.rawQuery(
      '''
      SELECT COUNT(*) as count
      FROM workout_sessions
      WHERE status = 'completed'
        AND completed_at >= ?
        AND completed_at <= ?
      ''',
      [startTimestamp, endTimestamp],
    );

    return result.first['count'] as int;
  }

  /// Get latest completed session before a given timestamp
  Future<WorkoutSessionEntity?> getLatestCompletedSessionBefore(
    int timestamp,
  ) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'workout_sessions',
      where: 'status = ? AND completed_at < ?',
      whereArgs: ['completed', timestamp],
      orderBy: 'completed_at DESC',
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return WorkoutSessionEntity.fromMap(maps.first);
    }
    return null;
  }

  /// Get workouts for a specific month
  Future<List<WorkoutSessionEntity>> getWorkoutsForMonth(
    int year,
    int month,
  ) async {
    final db = await _dbHelper.database;

    // Calculate start and end timestamps for the month
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0, 23, 59, 59);
    final startTimestamp = startDate.millisecondsSinceEpoch ~/ 1000;
    final endTimestamp = endDate.millisecondsSinceEpoch ~/ 1000;

    final maps = await db.query(
      'workout_sessions',
      where: 'status = ? AND completed_at >= ? AND completed_at <= ?',
      whereArgs: ['completed', startTimestamp, endTimestamp],
      orderBy: 'completed_at DESC',
    );

    return maps.map((map) => WorkoutSessionEntity.fromMap(map)).toList();
  }

  /// Get current workout streak (consecutive days)
  /// Returns the number of consecutive days the user has worked out
  /// Workouts are considered consecutive if they're within 2 days of each other
  Future<int> getCurrentStreak() async {
    final db = await _dbHelper.database;

    // Get all completed sessions in descending order (newest first)
    final maps = await db.query(
      'workout_sessions',
      where: 'status = ?',
      whereArgs: ['completed'],
      orderBy: 'completed_at DESC',
    );

    if (maps.isEmpty) return 0;

    final sessions =
        maps.map((map) => WorkoutSessionEntity.fromMap(map)).toList();

    int streak = 0;
    DateTime? previousDate;

    for (var session in sessions) {
      if (session.completedAt == null) continue;

      final completedAt = DateTime.fromMillisecondsSinceEpoch(
        session.completedAt! * 1000,
      );

      // Normalize to date only (ignore time)
      final currentDate = DateTime(
        completedAt.year,
        completedAt.month,
        completedAt.day,
      );

      if (previousDate == null) {
        // First session in the streak
        streak = 1;
        previousDate = currentDate;
      } else {
        final daysDiff = previousDate.difference(currentDate).inDays;

        if (daysDiff <= 2) {
          // Within 2 days, continue the streak
          // Only count if it's a different day
          if (daysDiff > 0) {
            streak++;
          }
          previousDate = currentDate;
        } else {
          // Streak broken
          break;
        }
      }
    }

    return streak;
  }

  /// Get total training duration for a month (in minutes)
  Future<int> getTotalDurationForMonth(int year, int month) async {
    final db = await _dbHelper.database;

    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0, 23, 59, 59);
    final startTimestamp = startDate.millisecondsSinceEpoch ~/ 1000;
    final endTimestamp = endDate.millisecondsSinceEpoch ~/ 1000;

    final result = await db.rawQuery(
      '''
      SELECT SUM(completed_at - started_at) as total_duration
      FROM workout_sessions
      WHERE status = 'completed'
        AND completed_at >= ?
        AND completed_at <= ?
        AND started_at IS NOT NULL
      ''',
      [startTimestamp, endTimestamp],
    );

    final totalSeconds = result.first['total_duration'];
    if (totalSeconds == null) return 0;

    // Convert seconds to minutes
    return ((totalSeconds as num) / 60).round();
  }

  /// Get weekly workout counts for a month
  /// Returns a list of maps with week number and count
  Future<List<Map<String, int>>> getWeeklyCountsForMonth(
    int year,
    int month,
  ) async {
    final db = await _dbHelper.database;

    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0, 23, 59, 59);
    final startTimestamp = startDate.millisecondsSinceEpoch ~/ 1000;
    final endTimestamp = endDate.millisecondsSinceEpoch ~/ 1000;

    final maps = await db.query(
      'workout_sessions',
      where: 'status = ? AND completed_at >= ? AND completed_at <= ?',
      whereArgs: ['completed', startTimestamp, endTimestamp],
      orderBy: 'completed_at ASC',
    );

    // Group by week
    final Map<int, int> weekCounts = {};
    for (var map in maps) {
      final completedAt = map['completed_at'] as int;
      final date = DateTime.fromMillisecondsSinceEpoch(completedAt * 1000);

      // Calculate week number (1-5) within the month
      final weekOfMonth = ((date.day - 1) ~/ 7) + 1;

      weekCounts[weekOfMonth] = (weekCounts[weekOfMonth] ?? 0) + 1;
    }

    // Convert to list format
    final result = <Map<String, int>>[];
    for (int week = 1; week <= 5; week++) {
      result.add({
        'week': week,
        'count': weekCounts[week] ?? 0,
      });
    }

    return result;
  }
}
