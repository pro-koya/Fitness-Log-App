import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../core/supabase_config.dart';
import '../data/dao/workout_session_dao.dart';
import '../data/dao/workout_exercise_dao.dart';
import '../data/dao/set_record_dao.dart';
import '../data/dao/exercise_master_dao.dart';
import '../data/dao/body_weight_dao.dart';
import '../data/dao/exercise_goal_dao.dart';
import '../data/dao/settings_dao.dart';
import '../data/entities/exercise_goal_entity.dart';
import '../data/entities/exercise_master_entity.dart';
import '../data/entities/workout_session_entity.dart';
import '../data/entities/workout_exercise_entity.dart';
import '../data/entities/set_record_entity.dart';
import '../data/entities/body_weight_entity.dart';
import 'supabase_auth_service.dart';

/// Pro 限定: ローカルデータを Supabase にアップロードする同期サービス。
/// 接続未設定または未ログイン時は何もしない。
class SyncService {
  /// Supabase の exercise_goals テーブル名。
  /// supabase_schema.sql で作成する場合は 'exercise_goals'（小文字・アンダースコア）。
  /// 手動で「Exercise Goals」という名前で作成した場合は 'Exercise Goals' に変更すること。
  static const String _tableExerciseGoals = 'exercise_goals';

  SyncService({
    required this.authService,
    SettingsDao? settingsDao,
  }) : _settingsDao = settingsDao ?? SettingsDao();

  final SupabaseAuthService authService;
  final SettingsDao _settingsDao;
  static const _uuid = Uuid();

  /// 1リクエストで挿入する最大件数（タイムアウト防止のためバッチ化）
  static const int _batchSize = 200;

  /// 同期を実行（プッシュ: ローカル → サーバー）。Pro かつログイン済みであること。
  ///
  /// **削除の反映**: サーバー側の当該ユーザーデータをいったん全削除してから、
  /// 現在のローカルデータのみを挿入するため、ローカルで削除した種目・履歴は
  /// 次回同期時に Supabase からも削除される（完全同期）。
  ///
  /// **セット数**: 完了済みセッションの全 workout_exercises とその set_records を
  /// 漏れなく同期するため、セット数は正確に保存される。
  ///
  /// 戻り値: 成功時 null、失敗時エラーメッセージ。
  Future<String?> syncNow() async {
    const tag = '[Sync]';
    if (!SupabaseConfig.isConfigured) {
      debugPrint('$tag early return: Supabase not configured');
      return 'Supabase is not configured';
    }
    final userId = authService.currentUserId;
    if (userId == null) {
      debugPrint('$tag early return: Not signed in');
      return 'Not signed in';
    }

    debugPrint('$tag start syncNow userId=$userId');
    final client = Supabase.instance.client;
    try {
      // 削除分を反映するため、サーバー側を全削除してからローカルと一致させる
      debugPrint('$tag delete set_records');
      await client.from('set_records').delete().eq('user_id', userId);
      debugPrint('$tag delete workout_exercises');
      await client.from('workout_exercises').delete().eq('user_id', userId);
      debugPrint('$tag delete workout_sessions');
      await client.from('workout_sessions').delete().eq('user_id', userId);
      debugPrint('$tag delete body_weight_records');
      await client.from('body_weight_records').delete().eq('user_id', userId);
      debugPrint('$tag delete exercise_master');
      await client.from('exercise_master').delete().eq('user_id', userId);
      debugPrint('$tag delete $_tableExerciseGoals');
      await client.from(_tableExerciseGoals).delete().eq('user_id', userId);

      final exerciseDao = ExerciseMasterDao();
      final goalDao = ExerciseGoalDao();
      final sessionDao = WorkoutSessionDao();
      final workoutExerciseDao = WorkoutExerciseDao();
      final setRecordDao = SetRecordDao();
      final bodyWeightDao = BodyWeightDao();

      debugPrint('$tag load local data');
      final exercises = await exerciseDao.getAllExercises();
      final goals = await goalDao.getAll();
      // 完了済みセッションのみ同期（件数制限なし＝全件）。セット数は set_records を全件挿入で正確に保存
      final sessions = await sessionDao.getCompletedSessions();
      final bodyWeights = await bodyWeightDao.getAll();
      debugPrint('$tag local: exercises=${exercises.length} goals=${goals.length} sessions=${sessions.length} bodyWeights=${bodyWeights.length}');

      // exercise_master: バッチ挿入
      final exerciseIdMap = <int, String>{};
      try {
        debugPrint('$tag insert exercise_master (count=${exercises.length}) batch');
        final rows = <Map<String, dynamic>>[];
        for (final e in exercises) {
          if (e.id == null) continue;
          final id = _uuid.v4();
          exerciseIdMap[e.id!] = id;
          rows.add({
            'id': id,
            'user_id': userId,
            'name': e.name,
            'body_part': e.bodyPart,
            'is_custom': (e.isCustom != 0) ? 1 : 0,
            'record_type': e.recordType,
            'created_at': e.createdAt,
            'updated_at': e.updatedAt,
          });
        }
        await _insertInBatches(client, 'exercise_master', rows, tag);
        debugPrint('$tag exercise_master done inserted=${rows.length} mapSize=${exerciseIdMap.length}');
      } catch (e) {
        debugPrint('$tag exercise_master FAILED: $e');
        throw Exception('exercise_master insert: $e');
      }

      // exercise_goals: バッチ挿入（exercise_id はサーバー側 UUID にマップ）
      try {
        final goalRows = <Map<String, dynamic>>[];
        int goalsSkipped = 0;
        for (final g in goals) {
          final serverExerciseId = exerciseIdMap[g.exerciseId];
          if (serverExerciseId == null) {
            goalsSkipped++;
            if (goalsSkipped <= 3) {
              debugPrint('$tag exercise_goals SKIP goal exerciseId=${g.exerciseId} (not in exerciseIdMap)');
            }
            continue;
          }
          goalRows.add({
            'id': _uuid.v4(),
            'user_id': userId,
            'exercise_id': serverExerciseId,
            'goal_type': g.goalType,
            'goal_value': g.goalValue,
            'deadline_ts': g.deadlineTs,
            'priority': g.priority,
            'created_at': g.createdAt,
            'updated_at': g.updatedAt,
          });
        }
        if (goalsSkipped > 0) {
          debugPrint('$tag exercise_goals skipped $goalsSkipped goals (exercise_id not in map), toInsert=${goalRows.length}');
        }
        if (goalRows.isNotEmpty) {
          debugPrint('$tag insert exercise_goals (count=${goalRows.length}) batch');
          await _insertInBatches(client, _tableExerciseGoals, goalRows, tag);
        }
        debugPrint('$tag exercise_goals done inserted=${goalRows.length}');
      } catch (e) {
        debugPrint('$tag exercise_goals FAILED: $e');
        throw Exception('exercise_goals insert: $e');
      }

      // workout_sessions: バッチ挿入
      final sessionIdMap = <int, String>{};
      try {
        debugPrint('$tag insert workout_sessions (count=${sessions.length}) batch');
        final rows = <Map<String, dynamic>>[];
        for (final s in sessions) {
          if (s.id == null) continue;
          final id = _uuid.v4();
          sessionIdMap[s.id!] = id;
          rows.add({
            'id': id,
            'user_id': userId,
            'status': s.status,
            'started_at': s.startedAt,
            'completed_at': s.completedAt,
            'created_at': s.createdAt,
            'updated_at': s.updatedAt,
          });
        }
        await _insertInBatches(client, 'workout_sessions', rows, tag);
        debugPrint('$tag workout_sessions done inserted=${rows.length} mapSize=${sessionIdMap.length}');
      } catch (e) {
        debugPrint('$tag workout_sessions FAILED: $e');
        throw Exception('workout_sessions insert: $e');
      }

      // workout_exercises: リスト構築後にバッチ挿入
      final workoutExerciseIdMap = <int, String>{};
      try {
        final rows = <Map<String, dynamic>>[];
        int skippedWeNoExerciseId = 0;
        for (final s in sessions) {
          if (s.id == null) continue;
          final serverSessionId = sessionIdMap[s.id!]!;
          final weList = await workoutExerciseDao.getExercisesBySessionId(s.id!);
          for (final we in weList) {
            if (we.id == null) continue;
            final serverExerciseId = exerciseIdMap[we.exerciseId];
            if (serverExerciseId == null) {
              skippedWeNoExerciseId++;
              if (skippedWeNoExerciseId <= 3) {
                debugPrint('$tag workout_exercises SKIP localWeId=${we.id} exerciseId=${we.exerciseId} (not in exerciseIdMap)');
              }
              continue;
            }
            final id = _uuid.v4();
            workoutExerciseIdMap[we.id!] = id;
            rows.add({
              'id': id,
              'user_id': userId,
              'session_id': serverSessionId,
              'exercise_id': serverExerciseId,
              'order_index': we.orderIndex,
              'memo': we.memo,
              'created_at': we.createdAt,
              'updated_at': we.updatedAt,
            });
          }
        }
        debugPrint('$tag insert workout_exercises (count=${rows.length}) batch');
        await _insertInBatches(client, 'workout_exercises', rows, tag);
        debugPrint('$tag workout_exercises done inserted=${rows.length} skipped_no_exerciseId=$skippedWeNoExerciseId mapSize=${workoutExerciseIdMap.length}');
      } catch (e) {
        debugPrint('$tag workout_exercises FAILED: $e');
        throw Exception('workout_exercises insert: $e');
      }

      // set_records: リスト構築後にバッチ挿入
      try {
        final rows = <Map<String, dynamic>>[];
        int skippedSetsNullId = 0;
        for (final weEntry in workoutExerciseIdMap.entries) {
          final localWeId = weEntry.key;
          final serverWeId = weEntry.value;
          final sets = await setRecordDao.getSetsByWorkoutExerciseId(localWeId);
          for (final set in sets) {
            final serverSessionId = sessionIdMap[set.sessionId];
            final serverExerciseId = exerciseIdMap[set.exerciseId];
            if (serverSessionId == null || serverExerciseId == null) {
              skippedSetsNullId++;
              if (skippedSetsNullId <= 3) {
                debugPrint('$tag set_records SKIP sessionId=${set.sessionId} exerciseId=${set.exerciseId}');
              }
              continue;
            }
            final weightKg = set.weightKg.isNaN || !set.weightKg.isFinite
                ? 0.0
                : set.weightKg;
            final weightLb = set.weightLb.isNaN || !set.weightLb.isFinite
                ? 0.0
                : set.weightLb;
            rows.add({
              'id': _uuid.v4(),
              'user_id': userId,
              'workout_exercise_id': serverWeId,
              'session_id': serverSessionId,
              'exercise_id': serverExerciseId,
              'set_number': set.setNumber,
              'weight_kg': weightKg,
              'weight_lb': weightLb,
              'reps': set.reps,
              'duration_seconds': set.durationSeconds,
              'distance_meters': set.distanceMeters,
              'created_at': set.createdAt,
              'updated_at': set.updatedAt,
            });
          }
        }
        if (skippedSetsNullId > 0) {
          debugPrint('$tag set_records skipped total (null session/exercise id)=$skippedSetsNullId');
        }
        debugPrint('$tag insert set_records (count=${rows.length}) batch');
        await _insertInBatches(client, 'set_records', rows, tag);
        debugPrint('$tag set_records done inserted=${rows.length}');
      } catch (e) {
        debugPrint('$tag set_records FAILED: $e');
        throw Exception('set_records insert: $e');
      }

      // body_weight_records: バッチ挿入
      final bwRows = <Map<String, dynamic>>[];
      for (final bw in bodyWeights) {
        if (bw.id == null) continue;
        bwRows.add({
          'id': _uuid.v4(),
          'user_id': userId,
          'weight_kg': bw.weightKg,
          'weight_lb': bw.weightLb,
          'memo': bw.memo,
          'recorded_at': bw.recordedAt,
          'created_at': bw.createdAt,
          'updated_at': bw.updatedAt,
        });
      }
      if (bwRows.isNotEmpty) {
        debugPrint('$tag insert body_weight_records (count=${bwRows.length}) batch');
        await _insertInBatches(client, 'body_weight_records', bwRows, tag);
      }
      debugPrint('$tag body_weight_records done inserted=${bwRows.length}');

      debugPrint('$tag updateLastSyncedAt');
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      await _settingsDao.updateLastSyncedAt(now);
      debugPrint('$tag syncNow SUCCESS');
      return null;
    } catch (e, st) {
      debugPrint('$tag syncNow ERROR: $e');
      debugPrint('$tag stackTrace: $st');
      return e.toString();
    }
  }

  /// サーバーからデータを取得してローカルを置き換える。成功時 null、失敗時エラーメッセージ。
  Future<String?> pullFromServer() async {
    const tag = '[Sync Pull]';
    if (!SupabaseConfig.isConfigured) {
      debugPrint('$tag early return: Supabase not configured');
      return 'Supabase is not configured';
    }
    final userId = authService.currentUserId;
    if (userId == null) {
      debugPrint('$tag early return: Not signed in');
      return 'Not signed in';
    }

    debugPrint('$tag start pullFromServer userId=$userId');
    final client = Supabase.instance.client;
    try {
      debugPrint('$tag fetch from server (with pagination to avoid 1000-row limit)');
      final exercisesList = await _fetchAllFromTable(client, 'exercise_master', userId);
      final sessionsList = await _fetchAllFromTable(client, 'workout_sessions', userId);
      final weList = await _fetchAllFromTable(client, 'workout_exercises', userId);
      final setList = await _fetchAllFromTable(client, 'set_records', userId);
      final bwList = await _fetchAllFromTable(client, 'body_weight_records', userId);
      final goalsList = await _fetchAllFromTable(client, _tableExerciseGoals, userId);

      debugPrint('$tag server: exercises=${exercisesList.length} sessions=${sessionsList.length} workout_exercises=${weList.length} set_records=${setList.length} body_weight=${bwList.length} goals=${goalsList.length}');

      final exerciseDao = ExerciseMasterDao();
      final sessionDao = WorkoutSessionDao();
      final workoutExerciseDao = WorkoutExerciseDao();
      final setRecordDao = SetRecordDao();
      final bodyWeightDao = BodyWeightDao();
      final goalDao = ExerciseGoalDao();

      debugPrint('$tag delete local (FK order)');
      await setRecordDao.deleteAll();
      await workoutExerciseDao.deleteAll();
      await sessionDao.deleteAll();
      await goalDao.deleteAll();
      await bodyWeightDao.deleteAll();
      await exerciseDao.deleteAll();

      final serverExerciseIdToLocal = <String, int>{};
      for (final row in exercisesList) {
        final id = row['id'] as String?;
        if (id == null) continue;
        final entity = ExerciseMasterEntity(
          id: null,
          name: row['name'] as String,
          bodyPart: row['body_part'] as String?,
          isCustom: _toInt(row['is_custom']) ?? 0,
          recordType: (row['record_type'] as String?) ?? 'reps',
          createdAt: _toInt(row['created_at']) ?? 0,
          updatedAt: _toInt(row['updated_at']) ?? 0,
        );
        final localId = await exerciseDao.insertExercise(entity);
        serverExerciseIdToLocal[id] = localId;
      }
      debugPrint('$tag exercise_master inserted ${serverExerciseIdToLocal.length}');

      for (final row in goalsList) {
        final exerciseIdRaw = row['exercise_id'];
        final exerciseId = exerciseIdRaw is String
            ? exerciseIdRaw
            : (exerciseIdRaw is num ? exerciseIdRaw.toString() : null);
        if (exerciseId == null || exerciseId.isEmpty) continue;
        final localExerciseId = serverExerciseIdToLocal[exerciseId];
        if (localExerciseId == null) continue;
        final entity = ExerciseGoalEntity(
          id: null,
          exerciseId: localExerciseId,
          goalType: row['goal_type'] as String,
          goalValue: _toDouble(row['goal_value']) ?? 0,
          deadlineTs: _toInt(row['deadline_ts']),
          priority: _toInt(row['priority']) ?? 2,
          createdAt: _toInt(row['created_at']) ?? 0,
          updatedAt: _toInt(row['updated_at']) ?? 0,
        );
        await goalDao.upsert(entity);
      }
      debugPrint('$tag exercise_goals inserted ${goalsList.length}');

      final serverSessionIdToLocal = <String, int>{};
      for (final row in sessionsList) {
        final id = row['id'] as String?;
        if (id == null) continue;
        final entity = WorkoutSessionEntity(
          id: null,
          status: row['status'] as String,
          startedAt: _toInt(row['started_at']) ?? 0,
          completedAt: _toInt(row['completed_at']),
          createdAt: _toInt(row['created_at']) ?? 0,
          updatedAt: _toInt(row['updated_at']) ?? 0,
        );
        final localId = await sessionDao.insertSession(entity);
        serverSessionIdToLocal[id] = localId;
      }
      debugPrint('$tag workout_sessions inserted ${serverSessionIdToLocal.length}');

      final serverWeIdToLocal = <String, int>{};
      for (final row in weList) {
        final id = row['id'] as String?;
        final sessionId = row['session_id'] as String?;
        final exerciseId = row['exercise_id'] as String?;
        if (id == null || sessionId == null || exerciseId == null) continue;
        final localSessionId = serverSessionIdToLocal[sessionId];
        final localExerciseId = serverExerciseIdToLocal[exerciseId];
        if (localSessionId == null || localExerciseId == null) continue;
        final entity = WorkoutExerciseEntity(
          id: null,
          sessionId: localSessionId,
          exerciseId: localExerciseId,
          orderIndex: _toInt(row['order_index']) ?? 0,
          memo: row['memo'] as String?,
          createdAt: _toInt(row['created_at']) ?? 0,
          updatedAt: _toInt(row['updated_at']) ?? 0,
        );
        final localId = await workoutExerciseDao.insertWorkoutExercise(entity);
        serverWeIdToLocal[id] = localId;
      }
      debugPrint('$tag workout_exercises inserted ${serverWeIdToLocal.length}');

      for (final row in setList) {
        final workoutExerciseId = row['workout_exercise_id'] as String?;
        final sessionId = row['session_id'] as String?;
        final exerciseId = row['exercise_id'] as String?;
        if (workoutExerciseId == null || sessionId == null || exerciseId == null) continue;
        final localWeId = serverWeIdToLocal[workoutExerciseId];
        final localSessionId = serverSessionIdToLocal[sessionId];
        final localExerciseId = serverExerciseIdToLocal[exerciseId];
        if (localWeId == null || localSessionId == null || localExerciseId == null) continue;
        final entity = SetRecordEntity(
          id: null,
          workoutExerciseId: localWeId,
          sessionId: localSessionId,
          exerciseId: localExerciseId,
          setNumber: _toInt(row['set_number']) ?? 0,
          weightKg: _toDouble(row['weight_kg']) ?? 0,
          weightLb: _toDouble(row['weight_lb']) ?? 0,
          reps: _toInt(row['reps']),
          durationSeconds: _toInt(row['duration_seconds']),
          distanceMeters: _toDouble(row['distance_meters']),
          createdAt: _toInt(row['created_at']) ?? 0,
          updatedAt: _toInt(row['updated_at']) ?? 0,
        );
        await setRecordDao.insertSetRecord(entity);
      }
      debugPrint('$tag set_records inserted ${setList.length}');

      for (final row in bwList) {
        if (row['id'] == null) continue;
        final entity = BodyWeightEntity(
          id: null,
          weightKg: _toDouble(row['weight_kg']) ?? 0,
          weightLb: _toDouble(row['weight_lb']) ?? 0,
          memo: row['memo'] as String?,
          recordedAt: _toInt(row['recorded_at']) ?? 0,
          createdAt: _toInt(row['created_at']) ?? 0,
          updatedAt: _toInt(row['updated_at']) ?? 0,
        );
        await bodyWeightDao.insert(entity);
      }
      debugPrint('$tag body_weight_records inserted ${bwList.length}');

      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      await _settingsDao.updateLastSyncedAt(now);
      debugPrint('$tag pullFromServer SUCCESS');
      return null;
    } catch (e, st) {
      debugPrint('$tag pullFromServer ERROR: $e');
      debugPrint('$tag stackTrace: $st');
      return e.toString();
    }
  }

  static int? _toInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return null;
  }

  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is num) return v.toDouble();
    return null;
  }

  /// PostgREST のデフォルト 1000 件制限を超えて全件取得する（range でページング）
  static Future<List<Map<String, dynamic>>> _fetchAllFromTable(
    SupabaseClient client,
    String tableName,
    String userId,
  ) async {
    const pageSize = 1000;
    final list = <Map<String, dynamic>>[];
    var from = 0;
    while (true) {
      final to = from + pageSize - 1;
      final page = await client
          .from(tableName)
          .select()
          .eq('user_id', userId)
          .order('id', ascending: true)
          .range(from, to);
      final rows = List<Map<String, dynamic>>.from(page);
      list.addAll(rows);
      if (rows.length < pageSize) break;
      from += pageSize;
    }
    return list;
  }

  /// リストを _batchSize 件ずつに分割して insert する（タイムアウト・ペイロード対策）
  Future<void> _insertInBatches(
    SupabaseClient client,
    String tableName,
    List<Map<String, dynamic>> rows,
    String tag,
  ) async {
    if (rows.isEmpty) return;
    for (var i = 0; i < rows.length; i += _batchSize) {
      final end = (i + _batchSize).clamp(0, rows.length);
      final chunk = rows.sublist(i, end);
      await client.from(tableName).insert(chunk);
      debugPrint('$tag $tableName batch ${i ~/ _batchSize + 1} inserted ${chunk.length}');
    }
  }
}
