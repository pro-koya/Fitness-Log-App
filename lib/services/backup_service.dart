import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../data/models/backup_data.dart';
import '../data/database/database_helper.dart';

/// バックアップサービス
///
/// アプリ内の全データをJSON形式でエクスポート/インポートする機能を提供
class BackupService {
  final DatabaseHelper _dbHelper;

  BackupService(this._dbHelper);

  /// バックアップファイル名を生成
  String _generateFileName() {
    final now = DateTime.now();
    final formatter = DateFormat('yyyyMMdd_HHmmss');
    return 'fitness_log_backup_${formatter.format(now)}.json';
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
      ),
    );
  }

  /// バックアップをファイルに保存
  ///
  /// ファイルパスを返す。ユーザーは「ファイル」アプリから共有・転送できる
  Future<String> exportBackup() async {
    final backup = await createBackup();
    final jsonString = backup.toJsonString();

    // ドキュメントディレクトリに保存（ユーザーがアクセス可能）
    final docDir = await getApplicationDocumentsDirectory();
    final fileName = _generateFileName();
    final file = File('${docDir.path}/$fileName');
    await file.writeAsString(jsonString);

    // クリップボードにもJSONをコピー（小さいデータの場合の代替手段）
    if (jsonString.length < 100000) {
      await Clipboard.setData(ClipboardData(text: jsonString));
    }

    return file.path;
  }

  /// バックアップをドキュメントディレクトリに保存
  ///
  /// iOS の「ファイル」アプリからアクセス可能
  /// ファイルパスを返す
  Future<String> exportToDocuments() async {
    final backup = await createBackup();
    final jsonString = backup.toJsonString();
    final fileName = _generateFileName();

    // ドキュメントディレクトリに保存
    final docDir = await getApplicationDocumentsDirectory();
    final file = File('${docDir.path}/$fileName');
    await file.writeAsString(jsonString);

    return file.path;
  }

  /// ファイルを選択してバックアップデータを読み込む
  ///
  /// ユーザーがキャンセルした場合は null を返す
  /// ファイル形式が不正な場合は [BackupParseException] をスロー
  Future<BackupData?> pickAndParseBackup() async {
    // FileType.any を使用（custom はシミュレーターでサポートされていない）
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
    );

    // iOSでファイルピッカー使用後にデータベースがreadonly状態になる問題を回避
    // ファイル選択後（キャンセル含む）、データベース接続を再確立
    await _dbHelper.reopenDatabase();

    if (result == null || result.files.isEmpty) {
      return null;
    }

    final file = result.files.first;

    // ファイル名で .json チェック
    if (!file.name.endsWith('.json')) {
      throw BackupParseException('Please select a .json backup file');
    }

    String jsonString;

    // iOS/Android: bytes が利用可能な場合はそれを使用
    if (file.bytes != null) {
      jsonString = utf8.decode(file.bytes!);
    } else if (file.path != null) {
      // デスクトップ: パスからファイルを読み込む
      final fileOnDisk = File(file.path!);
      jsonString = await fileOnDisk.readAsString();
    } else {
      throw BackupParseException('Could not read backup file');
    }

    try {
      final backup = BackupData.fromJsonString(jsonString);

      // バージョン互換性チェック
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
  /// 既存データを全て削除して、バックアップデータで置き換える
  Future<void> restore(BackupData backup) async {
    // ファイルピッカー使用後にreadonly状態になる問題を回避するため、
    // 復元前にデータベース接続を再確立
    await _dbHelper.reopenDatabase();

    final db = await _dbHelper.database;

    // トランザクションで一括復元（エラー時はロールバック）
    await db.transaction((txn) async {
      // 1. 既存データを削除（外部キー制約に注意して順番に削除）
      await txn.delete('set_records');
      await txn.delete('workout_exercises');
      await txn.delete('workout_sessions');
      await txn.delete('exercise_master');

      // 2. 種目データを挿入
      for (final exercise in backup.data.exercises) {
        await txn.insert('exercise_master', exercise);
      }

      // 3. セッションデータを挿入
      for (final session in backup.data.workoutSessions) {
        await txn.insert('workout_sessions', session);
      }

      // 4. ワークアウト種目データを挿入
      for (final we in backup.data.workoutExercises) {
        await txn.insert('workout_exercises', we);
      }

      // 5. セット記録データを挿入
      for (final set in backup.data.workoutSets) {
        await txn.insert('set_records', set);
      }

      // 6. 設定を更新（存在する場合）
      if (backup.data.settings != null) {
        await txn.delete('settings');
        await txn.insert('settings', backup.data.settings!);
      }
    });
  }
}

/// バックアップファイルのパースエラー
class BackupParseException implements Exception {
  final String message;
  BackupParseException(this.message);

  @override
  String toString() => message;
}

/// バックアップバージョンの互換性エラー
class BackupVersionException implements Exception {
  final String message;
  BackupVersionException(this.message);

  @override
  String toString() => message;
}

/// BackupService の Provider
final backupServiceProvider = Provider<BackupService>((ref) {
  return BackupService(DatabaseHelper.instance);
});
