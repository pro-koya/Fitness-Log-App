import '../data/models/backup_data.dart';
import 'backup_exceptions.dart';

/// CSV バックアップを BackupData に変換する
///
/// エクスポート形式（session_date, session_started_at, exercise_name, ...）をパースし、
/// 復元用の BackupData を構築する。
class BackupCsvParser {
  /// UTF-8 BOM を除去（Excel等で保存したCSVで先頭に付くことがある）
  static String _stripBom(String text) {
    const bom = '\uFEFF';
    if (text.startsWith(bom)) {
      return text.substring(bom.length);
    }
    return text;
  }

  /// CSV 文字列を BackupData に変換
  static BackupData parse(String csvString) {
    final normalized = _stripBom(csvString);
    final lines = _splitLines(normalized);
    if (lines.isEmpty || lines.first.trim().isEmpty) {
      throw BackupParseException('CSV file is empty');
    }

    final headerLine = lines.first.trim();
    final headerNormalized = headerLine.toLowerCase().replaceAll(' ', '');
    if (!headerNormalized.startsWith('session_date,')) {
      throw BackupParseException(
        'Invalid CSV format: expected header starting with "session_date,". Got: ${headerLine.length > 50 ? "${headerLine.substring(0, 50)}..." : headerLine}',
      );
    }

    final rows = <List<String>>[];
    for (var i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;
      final row = _parseCsvRow(lines[i]);
      if (row.length >= 8) {
        rows.add(row);
      }
    }

    if (rows.isEmpty) {
      throw BackupParseException(
        'CSV file has no valid data rows. Ensure columns: session_date, session_started_at, exercise_name, ... (at least 8 columns)',
      );
    }

    return _buildBackupData(rows);
  }

  static List<String> _splitLines(String text) {
    return text.split(RegExp(r'\r\n|\r|\n'));
  }

  static List<String> _parseCsvRow(String line) {
    final result = <String>[];
    var i = 0;
    while (i < line.length) {
      if (line[i] == '"') {
        final sb = StringBuffer();
        i++;
        while (i < line.length) {
          if (line[i] == '"') {
            if (i + 1 < line.length && line[i + 1] == '"') {
              sb.write('"');
              i += 2;
            } else {
              i++;
              break;
            }
          } else {
            sb.write(line[i]);
            i++;
          }
        }
        result.add(sb.toString());
      } else {
        final comma = line.indexOf(',', i);
        final end = comma < 0 ? line.length : comma;
        result.add(line.substring(i, end).trim());
        i = comma < 0 ? line.length : comma + 1;
      }
    }
    return result;
  }

  static BackupData _buildBackupData(List<List<String>> rows) {
    final now = DateTime.now();
    final nowSec = now.millisecondsSinceEpoch ~/ 1000;

    final exerciseKeys = <String>{};
    final exerciseList = <Map<String, dynamic>>[];
    final exerciseIdMap = <String, int>{};

    final sessionKeys = <String>{};
    final sessionList = <Map<String, dynamic>>[];
    final sessionIdMap = <String, int>{};

    final workoutExerciseKeys = <String>{};
    final workoutExerciseList = <Map<String, dynamic>>[];
    final workoutExerciseIdMap = <String, int>{};
    var workoutExerciseIdCounter = 1;

    final setRecords = <Map<String, dynamic>>[];

    for (final row in rows) {
      final sessionDate = row.isNotEmpty ? row[0].trim() : '';
      final sessionStartedAt = row.length > 1 ? row[1].trim() : '';
      final exerciseName = row.length > 2 ? row[2].trim() : '';
      final bodyPart = row.length > 3 ? row[3].trim() : '';
      final setNumber = _parseInt(row.length > 4 ? row[4] : '1');
      final weightKg = _parseDouble(row.length > 5 ? row[5] : '0');
      final weightLb = _parseDouble(row.length > 6 ? row[6] : '0');
      final reps = _parseIntNullable(row.length > 7 ? row[7] : '');
      final durationSeconds = _parseIntNullable(row.length > 8 ? row[8] : '');
      final distanceMeters = _parseDoubleNullable(row.length > 9 ? row[9] : '');
      final memo = row.length > 10 ? row[10].trim() : '';

      if (sessionDate.isEmpty || exerciseName.isEmpty) {
        continue;
      }
      final effectiveStartedAt = sessionStartedAt.isNotEmpty ? sessionStartedAt : sessionDate;

      final exerciseKey = '$exerciseName|$bodyPart';
      if (!exerciseKeys.contains(exerciseKey)) {
        exerciseKeys.add(exerciseKey);
        final id = exerciseList.length + 1;
        exerciseIdMap[exerciseKey] = id;
        exerciseList.add({
          'id': id,
          'name': exerciseName,
          'body_part': bodyPart.isEmpty ? null : bodyPart,
          'is_custom': 1,
          'record_type': 'reps',
          'created_at': nowSec,
          'updated_at': nowSec,
        });
      }
      final exerciseId = exerciseIdMap[exerciseKey]!;

      final sessionKey = '$sessionDate|$effectiveStartedAt';
      if (!sessionKeys.contains(sessionKey)) {
        sessionKeys.add(sessionKey);
        final id = sessionList.length + 1;
        sessionIdMap[sessionKey] = id;
        final startedAt = _parseIso8601ToUnix(effectiveStartedAt) ?? _parseDateToUnix(sessionDate);
        final completedAt = _parseDateToUnix(sessionDate) ?? _parseIso8601ToUnix(effectiveStartedAt);
        sessionList.add({
          'id': id,
          'status': 'completed',
          'started_at': startedAt ?? nowSec,
          'completed_at': completedAt ?? startedAt ?? nowSec,
          'created_at': nowSec,
          'updated_at': nowSec,
        });
      }
      final sessionId = sessionIdMap[sessionKey]!;

      final weKey = '$sessionId|$exerciseId';
      int workoutExerciseId;
      if (!workoutExerciseKeys.contains(weKey)) {
        workoutExerciseKeys.add(weKey);
        workoutExerciseId = workoutExerciseIdCounter++;
        workoutExerciseIdMap[weKey] = workoutExerciseId;
        workoutExerciseList.add({
          'id': workoutExerciseId,
          'session_id': sessionId,
          'exercise_id': exerciseId,
          'order_index': workoutExerciseList.where((we) => we['session_id'] == sessionId).length,
          'memo': memo.isEmpty ? null : memo,
          'created_at': nowSec,
          'updated_at': nowSec,
        });
      } else {
        workoutExerciseId = workoutExerciseIdMap[weKey]!;
      }

      setRecords.add({
        'workout_exercise_id': workoutExerciseId,
        'session_id': sessionId,
        'exercise_id': exerciseId,
        'set_number': setNumber,
        'weight_kg': weightKg,
        'weight_lb': weightLb,
        'reps': reps,
        'duration_seconds': durationSeconds,
        'distance_meters': distanceMeters,
        'created_at': nowSec,
        'updated_at': nowSec,
      });
    }

    final content = BackupContent(
      exercises: exerciseList,
      workoutSessions: sessionList,
      workoutExercises: workoutExerciseList,
      workoutSets: setRecords,
      exerciseMemos: [],
      settings: null,
      bodyWeightRecords: [],
    );

    return BackupData(
      version: BackupData.currentVersion,
      createdAt: now,
      appVersion: '1.0',
      data: content,
    );
  }

  static int _parseInt(String s) {
    final n = int.tryParse(s.trim());
    return n ?? 1;
  }

  static int? _parseIntNullable(String s) {
    final t = s.trim();
    if (t.isEmpty) return null;
    return int.tryParse(t);
  }

  static double _parseDouble(String s) {
    final n = double.tryParse(s.trim());
    return n ?? 0;
  }

  static double? _parseDoubleNullable(String s) {
    final t = s.trim();
    if (t.isEmpty) return null;
    return double.tryParse(t);
  }

  static int? _parseIso8601ToUnix(String s) {
    try {
      final dt = DateTime.parse(s.trim());
      return dt.millisecondsSinceEpoch ~/ 1000;
    } catch (_) {
      return null;
    }
  }

  static int? _parseDateToUnix(String s) {
    final t = s.trim();
    if (t.isEmpty) return null;
    try {
      final parts = t.contains('-') ? t.split('-') : t.split(RegExp(r'[/.]'));
      if (parts.length >= 3) {
        final year = int.parse(parts[0].trim());
        final month = int.parse(parts[1].trim());
        final day = int.parse(parts[2].trim());
        final dt = DateTime.utc(year, month, day, 12, 0, 0);
        return dt.millisecondsSinceEpoch ~/ 1000;
      }
      final parsed = DateTime.parse(t);
      return parsed.millisecondsSinceEpoch ~/ 1000;
    } catch (_) {}
    return null;
  }
}
