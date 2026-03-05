import '../data/models/backup_data.dart';

/// バックアップデータを CSV 形式に変換する
///
/// 分析用にフラットな形式で出力。復元には使用しない。
class BackupCsvConverter {
  /// BackupData を CSV 文字列に変換
  ///
  /// 1行 = 1セット記録。完了済みセッションのみ含む。
  static String toCsv(BackupData backup) {
    final lines = <String>[];
    lines.add(_header);

    final sessionMap = {
      for (final s in backup.data.workoutSessions) s['id']: s,
    };
    final exerciseMap = {
      for (final e in backup.data.exercises) e['id']: e,
    };
    final workoutExerciseMap = <int, Map<String, dynamic>>{};
    for (final we in backup.data.workoutExercises) {
      workoutExerciseMap[we['id'] as int] = we;
    }

    for (final set in backup.data.workoutSets) {
      final sessionId = set['session_id'] as int?;
      final exerciseId = set['exercise_id'] as int?;
      final workoutExerciseId = set['workout_exercise_id'] as int?;

      final session = sessionId != null ? sessionMap[sessionId] : null;
      if (session == null || session['status'] != 'completed') continue;

      final exercise = exerciseId != null ? exerciseMap[exerciseId] : null;
      final workoutExercise =
          workoutExerciseId != null ? workoutExerciseMap[workoutExerciseId] : null;

      final sessionDate = _formatDate(session['completed_at']);
      final sessionStartedAt = _formatTimestamp(session['started_at']);
      final exerciseName = exercise?['name'] as String? ?? '';
      final bodyPart = exercise?['body_part'] as String? ?? '';
      final setNumber = set['set_number'] ?? '';
      final weightKg = set['weight_kg'] ?? '';
      final weightLb = set['weight_lb'] ?? '';
      final reps = set['reps'] ?? '';
      final durationSeconds = set['duration_seconds'] ?? '';
      final distanceMeters = set['distance_meters'] ?? '';
      final memo = workoutExercise?['memo'] as String? ?? '';

      final row = [
        sessionDate,
        sessionStartedAt,
        exerciseName,
        bodyPart,
        setNumber.toString(),
        weightKg.toString(),
        weightLb.toString(),
        reps.toString(),
        durationSeconds.toString(),
        distanceMeters.toString(),
        memo,
      ].map(_escapeCsvField).join(',');

      lines.add(row);
    }

    return lines.join('\n');
  }

  static const _header =
      'session_date,session_started_at,exercise_name,body_part,set_number,weight_kg,weight_lb,reps,duration_seconds,distance_meters,memo';

  static String _formatDate(dynamic completedAt) {
    if (completedAt == null) return '';
    if (completedAt is int) {
      final dt = DateTime.fromMillisecondsSinceEpoch(completedAt * 1000);
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    }
    return '';
  }

  static String _formatTimestamp(dynamic value) {
    if (value == null) return '';
    if (value is int) {
      final dt = DateTime.fromMillisecondsSinceEpoch(value * 1000);
      return dt.toIso8601String();
    }
    return '';
  }

  static String _escapeCsvField(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }
}
