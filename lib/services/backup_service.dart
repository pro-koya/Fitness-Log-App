import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../data/constants/standard_exercise_names.dart';
import '../data/models/backup_data.dart';
import '../data/database/database_helper.dart';
import 'backup_csv_converter.dart';
import 'backup_csv_parser.dart';
import 'backup_exceptions.dart';

export 'backup_exceptions.dart';

/// バックアップ出力形式
enum BackupFormat {
  json,
  csv,
}

/// バックアップサービス
///
/// アプリ内の全データをJSON形式でエクスポート/インポートする機能を提供
/// CSV形式のエクスポートもサポート（分析用、復元には使用不可）
class BackupService {
  final DatabaseHelper _dbHelper;

  BackupService(this._dbHelper);

  /// バックアップファイル名を生成
  String _generateFileName(BackupFormat format) {
    final now = DateTime.now();
    final formatter = DateFormat('yyyyMMdd_HHmmss');
    final ext = format == BackupFormat.json ? 'json' : 'csv';
    return 'fitness_log_backup_${formatter.format(now)}.$ext';
  }

  /// 全データをバックアップデータとして作成
  Future<BackupData> createBackup() async {
    final db = await _dbHelper.database;

    // 各テーブルからデータ取得
    final exercises = await db.query('exercise_master');
    final sessions = await db.query('workout_sessions');
    final workoutExercises = await db.query('workout_exercises');
    final sets = await db.query('set_records');
    final settingsList = await db.query('settings');
    final settings = settingsList.isNotEmpty ? settingsList.first : null;
    final bodyWeightRecords = await db.query('body_weight_records');

    // ルーティンデータ
    List<Map<String, dynamic>> routineTemplates = [];
    List<Map<String, dynamic>> routineExercises = [];
    List<Map<String, dynamic>> routineSets = [];
    try {
      routineTemplates = await db.query('routine_templates');
      routineExercises = await db.query('routine_exercises');
      routineSets = await db.query('routine_sets');
    } catch (_) {
      // テーブルがまだ存在しない場合は空リスト
    }

    // アプリバージョン取得
    String appVersion = '1.0.0';
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      appVersion = packageInfo.version;
    } catch (_) {
      // パッケージ情報が取得できない場合はデフォルト値を使用
    }

    return BackupData(
      version: BackupData.currentVersion,
      createdAt: DateTime.now(),
      appVersion: appVersion,
      data: BackupContent(
        exercises: exercises.map((e) => Map<String, dynamic>.from(e)).toList(),
        workoutSessions: sessions.map((e) => Map<String, dynamic>.from(e)).toList(),
        workoutExercises: workoutExercises.map((e) => Map<String, dynamic>.from(e)).toList(),
        workoutSets: sets.map((e) => Map<String, dynamic>.from(e)).toList(),
        exerciseMemos: [], // メモは workout_exercises の memo カラムに含まれる
        settings: settings != null ? Map<String, dynamic>.from(settings) : null,
        bodyWeightRecords: bodyWeightRecords.map((e) => Map<String, dynamic>.from(e)).toList(),
        routineTemplates: routineTemplates.map((e) => Map<String, dynamic>.from(e)).toList(),
        routineExercises: routineExercises.map((e) => Map<String, dynamic>.from(e)).toList(),
        routineSets: routineSets.map((e) => Map<String, dynamic>.from(e)).toList(),
      ),
    );
  }

  /// バックアップをユーザーが選択した場所に保存
  ///
  /// [format] で JSON または CSV を指定。JSON は復元用、CSV は分析用。
  /// ネイティブのファイル保存ダイアログを表示し、ユーザーが保存先を選択する。
  /// キャンセル時は null を返す。
  Future<String?> exportBackup({required BackupFormat format}) async {
    final backup = await createBackup();
    final String content;
    if (format == BackupFormat.json) {
      content = backup.toJsonString();
    } else {
      content = BackupCsvConverter.toCsv(backup);
    }
    final bytes = Uint8List.fromList(utf8.encode(content));
    final fileName = _generateFileName(format);

    final result = await FilePicker.platform.saveFile(
      dialogTitle: 'Save Backup',
      fileName: fileName,
      type: FileType.any,
      bytes: bytes,
    );

    // iOSでファイルピッカー使用後にデータベースがreadonly状態になる問題を回避
    await _dbHelper.reopenDatabase();

    return result;
  }

  /// ファイルを選択してバックアップデータを読み込む
  ///
  /// ユーザーがキャンセルした場合は null を返す
  /// ファイル形式が不正な場合は [BackupParseException] をスロー
  Future<BackupData?> pickAndParseBackup() async {
    // FileType.any を使用（custom はシミュレーターでサポートされていない）
    // withData: true で iOS Files アプリから選択した際も bytes を取得可能にする
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      withData: true,
    );

    // iOSでファイルピッカー使用後にデータベースがreadonly状態になる問題を回避
    // ファイル選択後（キャンセル含む）、データベース接続を再確立
    await _dbHelper.reopenDatabase();

    if (result == null || result.files.isEmpty) {
      return null;
    }

    final file = result.files.first;

    // ファイル名で .json / .csv を判定
    final isJson = file.name.toLowerCase().endsWith('.json');
    final isCsv = file.name.toLowerCase().endsWith('.csv');
    if (!isJson && !isCsv) {
      throw BackupParseException('Please select a .json or .csv backup file');
    }

    String content;

    // iOS/Android: bytes が利用可能な場合はそれを使用
    if (file.bytes != null) {
      content = utf8.decode(file.bytes!);
    } else if (file.path != null) {
      // デスクトップ: パスからファイルを読み込む
      final fileOnDisk = File(file.path!);
      content = await fileOnDisk.readAsString();
    } else {
      throw BackupParseException('Could not read backup file');
    }

    try {
      if (isCsv) {
        return BackupCsvParser.parse(content);
      }

      final backup = BackupData.fromJsonString(content);

      // バージョン互換性チェック（JSON のみ）
      if (!backup.isCompatible) {
        throw BackupVersionException(
          'Backup version ${backup.version} is not compatible with current version ${BackupData.currentVersion}',
        );
      }

      return backup;
    } on FormatException catch (e) {
      throw BackupParseException('Invalid JSON format: ${e.message}');
    } catch (e) {
      if (e is BackupParseException || e is BackupVersionException) {
        rethrow;
      }
      throw BackupParseException('Failed to parse backup file: $e');
    }
  }

  /// バックアップからデータを復元
  ///
  /// 既存データを全て削除して、バックアップデータで置き換える。
  /// 標準種目と同じ名前の種目は標準種目を優先し、筋トレ記録の exercise_id を標準にマッピングする。
  Future<void> restore(BackupData backup) async {
    await _dbHelper.reopenDatabase();

    final db = await _dbHelper.database;

    await db.transaction((txn) async {
      await txn.delete('set_records');
      await txn.delete('workout_exercises');
      await txn.delete('workout_sessions');
      await txn.delete('exercise_goals');
      await txn.delete('goal_achievements');
      await txn.delete('exercise_master');
      await txn.delete('body_weight_records');

      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      // 1. 標準種目を挿入し、name -> id を構築
      final standardNameToId = <String, int>{};
      for (final row in StandardExerciseNames.seedRows) {
        final id = await txn.insert('exercise_master', {
          'name': row['name'],
          'body_part': row['body_part'],
          'is_custom': 0,
          'record_type': row['record_type'],
          'created_at': now,
          'updated_at': now,
        });
        standardNameToId[row['name']!] = id;
      }

      // 2. バックアップ種目ごとに標準ならマップ、そうでなければカスタム挿入
      final backupExerciseIdToTargetId = <int, int>{};
      for (final exercise in backup.data.exercises) {
        final backupId = exercise['id'] as int?;
        if (backupId == null) continue;

        final name = (exercise['name'] as String? ?? '').trim();
        final canonical = StandardExerciseNames.canonicalNameForBackup(name);
        if (canonical != null) {
          final standardId = standardNameToId[canonical];
          if (standardId != null) {
            backupExerciseIdToTargetId[backupId] = standardId;
            continue;
          }
        }

        final newId = await txn.insert('exercise_master', {
          'name': name.isEmpty ? 'Unknown' : name,
          'body_part': exercise['body_part'],
          'is_custom': 1,
          'record_type': exercise['record_type'] ?? 'reps',
          'created_at': exercise['created_at'] ?? now,
          'updated_at': exercise['updated_at'] ?? now,
        });
        backupExerciseIdToTargetId[backupId] = newId;
      }

      // 3. セッションを挿入し、旧 session_id -> 新 id を構築
      final backupSessionIdToNewId = <int, int>{};
      for (final session in backup.data.workoutSessions) {
        final oldId = session['id'] as int?;
        final newId = await txn.insert('workout_sessions', {
          'status': 'completed',
          'started_at': session['started_at'],
          'completed_at': session['completed_at'],
          'created_at': session['created_at'] ?? now,
          'updated_at': session['updated_at'] ?? now,
        });
        if (oldId != null) backupSessionIdToNewId[oldId] = newId;
      }

      // 4. ワークアウト種目を挿入し、旧 workout_exercise id -> 新 id を構築
      final backupWeIdToNewId = <int, int>{};
      for (final we in backup.data.workoutExercises) {
        final oldWeId = we['id'] as int?;
        final oldSessionId = we['session_id'] as int?;
        final oldExerciseId = we['exercise_id'] as int?;
        final newSessionId = oldSessionId != null ? backupSessionIdToNewId[oldSessionId] : null;
        final newExerciseId = oldExerciseId != null ? backupExerciseIdToTargetId[oldExerciseId] : null;
        if (newSessionId == null || newExerciseId == null) continue;

        final newWeId = await txn.insert('workout_exercises', {
          'session_id': newSessionId,
          'exercise_id': newExerciseId,
          'order_index': we['order_index'] ?? 0,
          'memo': we['memo'],
          'created_at': we['created_at'] ?? now,
          'updated_at': we['updated_at'] ?? now,
        });
        if (oldWeId != null) backupWeIdToNewId[oldWeId] = newWeId;
      }

      // 5. セット記録を挿入（exercise_id, session_id, workout_exercise_id をマッピング）
      for (final set in backup.data.workoutSets) {
        final oldWeId = set['workout_exercise_id'] as int?;
        final oldSessionId = set['session_id'] as int?;
        final oldExerciseId = set['exercise_id'] as int?;
        final newWeId = oldWeId != null ? backupWeIdToNewId[oldWeId] : null;
        final newSessionId = oldSessionId != null ? backupSessionIdToNewId[oldSessionId] : null;
        final newExerciseId = oldExerciseId != null ? backupExerciseIdToTargetId[oldExerciseId] : null;
        if (newWeId == null || newSessionId == null || newExerciseId == null) continue;

        await txn.insert('set_records', {
          'workout_exercise_id': newWeId,
          'session_id': newSessionId,
          'exercise_id': newExerciseId,
          'set_number': set['set_number'] ?? 1,
          'weight_kg': set['weight_kg'] ?? 0,
          'weight_lb': set['weight_lb'] ?? 0,
          'reps': set['reps'],
          'duration_seconds': set['duration_seconds'],
          'distance_meters': set['distance_meters'],
          'created_at': set['created_at'] ?? now,
          'updated_at': set['updated_at'] ?? now,
        });
      }

      if (backup.data.settings != null) {
        await txn.delete('settings');
        await txn.insert('settings', backup.data.settings!);
      }

      for (final record in backup.data.bodyWeightRecords) {
        await txn.insert('body_weight_records', record);
      }

      // 7. ルーティンデータを復元
      try {
        await txn.delete('routine_sets');
        await txn.delete('routine_exercises');
        await txn.delete('routine_templates');
      } catch (_) {
        // テーブルがまだ存在しない場合は無視
      }

      if (backup.data.routineTemplates.isNotEmpty) {
        final backupRoutineIdToNewId = <int, int>{};
        for (final rt in backup.data.routineTemplates) {
          final oldId = rt['id'] as int?;
          final newId = await txn.insert('routine_templates', {
            'name': rt['name'] ?? '',
            'created_at': rt['created_at'] ?? now,
            'updated_at': rt['updated_at'] ?? now,
          });
          if (oldId != null) backupRoutineIdToNewId[oldId] = newId;
        }

        final backupRoutineExIdToNewId = <int, int>{};
        for (final re in backup.data.routineExercises) {
          final oldId = re['id'] as int?;
          final oldRoutineId = re['routine_id'] as int?;
          final oldExerciseId = re['exercise_id'] as int?;
          final newRoutineId = oldRoutineId != null ? backupRoutineIdToNewId[oldRoutineId] : null;
          final newExerciseId = oldExerciseId != null ? backupExerciseIdToTargetId[oldExerciseId] : null;
          if (newRoutineId == null || newExerciseId == null) continue;

          final newId = await txn.insert('routine_exercises', {
            'routine_id': newRoutineId,
            'exercise_id': newExerciseId,
            'order_index': re['order_index'] ?? 0,
            'created_at': re['created_at'] ?? now,
            'updated_at': re['updated_at'] ?? now,
          });
          if (oldId != null) backupRoutineExIdToNewId[oldId] = newId;
        }

        for (final rs in backup.data.routineSets) {
          final oldReId = rs['routine_exercise_id'] as int?;
          final newReId = oldReId != null ? backupRoutineExIdToNewId[oldReId] : null;
          if (newReId == null) continue;

          await txn.insert('routine_sets', {
            'routine_exercise_id': newReId,
            'set_number': rs['set_number'] ?? 1,
            'weight_kg': rs['weight_kg'] ?? 0,
            'weight_lb': rs['weight_lb'] ?? 0,
            'reps': rs['reps'],
            'duration_seconds': rs['duration_seconds'],
            'distance_meters': rs['distance_meters'],
            'created_at': rs['created_at'] ?? now,
            'updated_at': rs['updated_at'] ?? now,
          });
        }
      }
    });
  }
}

/// BackupService の Provider
final backupServiceProvider = Provider<BackupService>((ref) {
  return BackupService(DatabaseHelper.instance);
});
