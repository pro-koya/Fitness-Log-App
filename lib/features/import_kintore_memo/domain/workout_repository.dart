import 'liftly_workout_import.dart';

/// ワークアウト保存の抽象インターフェース
/// SQLite / Supabase / Firebase 等に差し替え可能
abstract class WorkoutRepository {
  /// インポートされたワークアウトを保存
  /// 重複は除外して返す
  Future<ImportResult> saveImportedWorkouts(
    List<LiftlyWorkoutImport> workouts,
    String dedupHashPrefix,
  );

  /// ハッシュが既に取り込み済みか
  Future<bool> containsHash(String hash);

  /// 指定プレフィックスのインポートハッシュをクリア（再インポート用）
  Future<void> clearImportHashes(String dedupHashPrefix);
}

class ImportResult {
  final int sessionsCreated;
  final int setsCreated;
  final int exercisesCreated;
  final int skippedDuplicate;

  const ImportResult({
    required this.sessionsCreated,
    required this.setsCreated,
    required this.exercisesCreated,
    required this.skippedDuplicate,
  });
}
