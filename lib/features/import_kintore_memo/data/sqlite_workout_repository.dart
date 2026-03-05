import 'package:sqflite/sqflite.dart';
import '../../../data/database/database_helper.dart';
import '../../../data/entities/exercise_master_entity.dart';
import '../../../data/localization/exercise_localization.dart';
import '../domain/liftly_workout_import.dart';
import '../domain/workout_repository.dart';

/// SQLite を用いた WorkoutRepository の実装
class SqliteWorkoutRepository implements WorkoutRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  static const double _lbsToKg = 0.45359237;

  @override
  Future<bool> containsHash(String hash) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'import_source_hashes',
      where: 'source_hash = ?',
      whereArgs: [hash],
    );
    return result.isNotEmpty;
  }

  @override
  Future<ImportResult> saveImportedWorkouts(
    List<LiftlyWorkoutImport> workouts,
    String dedupHashPrefix,
  ) async {
    int sessionsCreated = 0;
    int setsCreated = 0;
    int exercisesCreated = 0;
    int skippedDuplicate = 0;

    // 同一日付でグルーピング（1セッション = 1日 = 複数種目）
    final byDate = <String, List<LiftlyWorkoutImport>>{};
    for (final w in workouts) {
      final key = '${w.workoutDate.year}-${w.workoutDate.month.toString().padLeft(2, '0')}-${w.workoutDate.day.toString().padLeft(2, '0')}';
      byDate.putIfAbsent(key, () => []).add(w);
    }

    final db = await _dbHelper.database;
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    await db.transaction((txn) async {
      for (final dateKey in byDate.keys) {
        final dayWorkouts = byDate[dateKey]!;
        if (dayWorkouts.isEmpty) continue;

        final first = dayWorkouts.first;
        final dateOnly = DateTime(
          first.workoutDate.year,
          first.workoutDate.month,
          first.workoutDate.day,
        );
        final timestamp = dateOnly.millisecondsSinceEpoch ~/ 1000;

        int? sessionId;
        var orderIndex = 0;

        for (final w in dayWorkouts) {
          // (date, exerciseName, setIndex, weight, reps) でハッシュを生成
          final hashes = <String>[];
          for (var i = 0; i < w.sets.length; i++) {
            final s = w.sets[i];
            hashes.add(_buildSetHash(
              dedupHashPrefix,
              w.workoutDate,
              w.exerciseName,
              i,
              s.weightKg,
              s.reps,
            ));
          }

          var allExist = true;
          for (final h in hashes) {
            final rows = await txn.query(
              'import_source_hashes',
              where: 'source_hash = ?',
              whereArgs: [h],
            );
            if (rows.isEmpty) {
              allExist = false;
              break;
            }
          }
          if (allExist && hashes.isNotEmpty) {
            skippedDuplicate += w.sets.length;
            continue;
          }

          var exercise = await _findExerciseByName(txn, w.exerciseName, w.bodyPart);
          if (exercise == null) {
            final id = await txn.insert(
              'exercise_master',
              {
                'name': w.exerciseName,
                'body_part': w.bodyPart ?? 'other',
                'is_custom': 1,
                'record_type': 'reps',
                'created_at': now,
                'updated_at': now,
              },
            );
            exercise = ExerciseMasterEntity(
              id: id,
              name: w.exerciseName,
              bodyPart: w.bodyPart,
              isCustom: 1,
              recordType: 'reps',
              createdAt: now,
              updatedAt: now,
            );
            exercisesCreated++;
          }

          if (sessionId == null) {
            sessionId = await txn.insert(
              'workout_sessions',
              {
                'status': 'completed',
                'started_at': timestamp,
                'completed_at': timestamp,
                'created_at': now,
                'updated_at': now,
              },
            );
            sessionsCreated++;
          }

          final workoutExerciseId = await txn.insert(
            'workout_exercises',
            {
              'session_id': sessionId,
              'exercise_id': exercise.id!,
              'order_index': orderIndex++,
              'memo': w.note,
              'created_at': now,
              'updated_at': now,
            },
          );

          var setIndex = 0;
          for (var i = 0; i < w.sets.length; i++) {
            final s = w.sets[i];
            final h = hashes[i];

            final existing = await txn.query(
              'import_source_hashes',
              where: 'source_hash = ?',
              whereArgs: [h],
            );
            if (existing.isNotEmpty) {
              skippedDuplicate++;
              continue;
            }

            final weightKg = s.weightKg ?? 0.0;
            final weightLb = weightKg / _lbsToKg;

            await txn.insert(
              'set_records',
              {
                'workout_exercise_id': workoutExerciseId,
                'session_id': sessionId,
                'exercise_id': exercise.id,
                'set_number': setIndex + 1,
                'weight_kg': weightKg,
                'weight_lb': weightLb,
                'reps': s.reps,
                'duration_seconds': null,
                'distance_meters': null,
                'created_at': now,
                'updated_at': now,
              },
            );
            setsCreated++;
            setIndex++;

            await txn.insert(
              'import_source_hashes',
              {
                'source_hash': h,
                'created_at': now,
              },
            );
          }
        }
      }
    });

    return ImportResult(
      sessionsCreated: sessionsCreated,
      setsCreated: setsCreated,
      exercisesCreated: exercisesCreated,
      skippedDuplicate: skippedDuplicate,
    );
  }

  String _buildSetHash(
    String prefix,
    DateTime date,
    String exerciseName,
    int setIndex,
    double? weight,
    int? reps,
  ) {
    final d = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final w = weight?.toStringAsFixed(2) ?? '0';
    final r = reps?.toString() ?? '0';
    return '$prefix|$d|$exerciseName|$setIndex|$w|$r';
  }

  @override
  Future<void> clearImportHashes(String dedupHashPrefix) async {
    final db = await _dbHelper.database;
    await db.delete(
      'import_source_hashes',
      where: 'source_hash LIKE ?',
      whereArgs: ['$dedupHashPrefix|%'],
    );
  }

  Future<ExerciseMasterEntity?> _findExerciseByName(
    Transaction txn,
    String name,
    String? bodyPart,
  ) async {
    // 1. まず完全一致で検索
    final rows = await txn.query(
      'exercise_master',
      where: 'name = ?',
      whereArgs: [name],
    );
    if (rows.isNotEmpty) return ExerciseMasterEntity.fromMap(rows.first);

    // 2. 日本語名→英語名に変換して検索（DBは英語名で保存されている）
    final englishName = ExerciseLocalization.getEnglishName(name);
    if (englishName != null) {
      final engRows = await txn.query(
        'exercise_master',
        where: 'name = ?',
        whereArgs: [englishName],
      );
      if (engRows.isNotEmpty) return ExerciseMasterEntity.fromMap(engRows.first);
    }

    return null;
  }
}
