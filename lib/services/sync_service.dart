import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../core/supabase_config.dart';
import '../data/dao/settings_dao.dart';
import '../data/database/database_helper.dart';
import 'supabase_auth_service.dart';

typedef _JsonMap = Map<String, dynamic>;

abstract class SyncRemoteStore {
  Future<List<Map<String, dynamic>>> fetchAll(String tableName, String userId);

  Future<void> upsert(String tableName, List<Map<String, dynamic>> rows);

  Future<void> deleteIds(String tableName, List<String> ids);
}

class SupabaseSyncRemoteStore implements SyncRemoteStore {
  SupabaseSyncRemoteStore({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  @override
  Future<List<Map<String, dynamic>>> fetchAll(
    String tableName,
    String userId,
  ) async {
    const pageSize = 1000;
    final list = <Map<String, dynamic>>[];
    var from = 0;
    while (true) {
      final to = from + pageSize - 1;
      final page = await _client
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

  @override
  Future<void> upsert(String tableName, List<Map<String, dynamic>> rows) async {
    await _client.from(tableName).upsert(rows);
  }

  @override
  Future<void> deleteIds(String tableName, List<String> ids) async {
    await _client.from(tableName).delete().inFilter('id', ids);
  }
}

/// Pro 限定: ローカルデータと Supabase を同期するサービス。
/// 接続未設定または未ログイン時は何もしない。
class SyncService {
  static const String _tableExerciseGoals = 'exercise_goals';

  SyncService({
    required this.authService,
    SettingsDao? settingsDao,
    SyncRemoteStore? remoteStore,
  }) : _settingsDao = settingsDao ?? SettingsDao(),
       _remoteStore = remoteStore ?? SupabaseSyncRemoteStore();

  final SupabaseAuthService authService;
  final SettingsDao _settingsDao;
  final SyncRemoteStore _remoteStore;
  static const _uuid = Uuid();

  /// 1リクエストで送る最大件数（タイムアウト・ペイロード対策）
  static const int _batchSize = 200;

  static const List<String> _syncTables = [
    'exercise_master',
    _tableExerciseGoals,
    'workout_sessions',
    'workout_exercises',
    'set_records',
    'body_weight_records',
  ];

  static const List<String> _deleteOrder = [
    'set_records',
    'workout_exercises',
    _tableExerciseGoals,
    'workout_sessions',
    'body_weight_records',
    'exercise_master',
  ];

  static const List<String> _upsertOrder = [
    'exercise_master',
    'workout_sessions',
    _tableExerciseGoals,
    'workout_exercises',
    'set_records',
    'body_weight_records',
  ];

  /// 同期を実行（Push: ローカル → サーバー）。
  ///
  /// `sync_metadata` に保持したローカル行と Supabase UUID の対応を使い、
  /// 作成・更新は差分 upsert、削除は同期済みでローカルに存在しない行だけを
  /// 子テーブルから順に削除する。
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

    debugPrint('$tag start differential push userId=$userId');
    final db = await DatabaseHelper.instance.database;
    try {
      final local = await _loadLocalSyncData(db, completedOnly: true);
      var mappings = await _loadAllMappings(db);

      Map<String, List<_JsonMap>>? remoteSnapshot;
      if (await _mappingCount(db) == 0) {
        debugPrint('$tag bootstrap metadata from existing server rows');
        remoteSnapshot = await _fetchRemoteSnapshot(userId);
        await _bootstrapMappings(db, local, remoteSnapshot);
        mappings = await _loadAllMappings(db);
      }

      final remoteIds = _assignRemoteIds(local, mappings);
      await _deleteRemoteRowsMissingLocally(
        userId: userId,
        local: local,
        mappings: mappings,
        assignedRemoteIds: remoteIds,
        remoteSnapshot: remoteSnapshot,
        tag: tag,
      );

      for (final table in _upsertOrder) {
        final rows = _buildPushRows(table, local, remoteIds, userId);
        await _pushChangedRows(
          db: db,
          tableName: table,
          localRows: local.rowsFor(table),
          remoteRows: rows,
          mappings: mappings[table] ?? const {},
          tag: tag,
        );
      }

      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      await _settingsDao.updateLastSyncedAt(now);
      debugPrint('$tag differential push SUCCESS');
      return null;
    } catch (e, st) {
      debugPrint('$tag syncNow ERROR: $e');
      debugPrint('$tag stackTrace: $st');
      return e.toString();
    }
  }

  /// サーバーからデータを取得してローカルへ差分反映する。
  ///
  /// Pull はクラウドを正として、クラウドに存在しない同期対象ローカル行だけを削除し、
  /// サーバー側の作成・更新のみをローカルに upsert する。
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

    debugPrint('$tag start differential pull userId=$userId');
    final db = await DatabaseHelper.instance.database;
    try {
      final remote = await _fetchRemoteSnapshot(userId);
      var local = await _loadLocalSyncData(db, completedOnly: false);

      if (await _mappingCount(db) == 0) {
        debugPrint('$tag bootstrap metadata from matching local/server rows');
        await _bootstrapMappings(db, local, remote);
      }

      var mappings = await _loadAllMappings(db);
      await _deleteLocalRowsMissingRemotely(
        db: db,
        local: local,
        remoteSnapshot: remote,
        mappings: mappings,
        tag: tag,
      );

      local = await _loadLocalSyncData(db, completedOnly: false);
      mappings = await _loadAllMappings(db);
      final remoteToLocal = _remoteToLocalIds(mappings);

      for (final table in _upsertOrder) {
        await _pullTableRows(
          db: db,
          tableName: table,
          remoteRows: remote[table] ?? const [],
          remoteToLocal: remoteToLocal,
          mappingsByRemote: _mappingsByRemote(mappings[table] ?? const {}),
          tag: tag,
        );
      }

      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      await _settingsDao.updateLastSyncedAt(now);
      debugPrint('$tag differential pull SUCCESS');
      return null;
    } catch (e, st) {
      debugPrint('$tag pullFromServer ERROR: $e');
      debugPrint('$tag stackTrace: $st');
      return e.toString();
    }
  }

  Future<_LocalSyncData> _loadLocalSyncData(
    Database db, {
    required bool completedOnly,
  }) async {
    final exercises = await db.query('exercise_master', orderBy: 'id ASC');
    final goals = await db.query(_tableExerciseGoals, orderBy: 'id ASC');
    final sessions = await db.query(
      'workout_sessions',
      where: completedOnly ? 'status = ?' : null,
      whereArgs: completedOnly ? ['completed'] : null,
      orderBy: 'id ASC',
    );
    final sessionIds = sessions
        .map((row) => _toInt(row['id']))
        .whereType<int>()
        .toList();
    final workoutExercises = await _queryWhereIn(
      db,
      'workout_exercises',
      'session_id',
      sessionIds,
    );
    final workoutExerciseIds = workoutExercises
        .map((row) => _toInt(row['id']))
        .whereType<int>()
        .toList();
    final sets = await _queryWhereIn(
      db,
      'set_records',
      'workout_exercise_id',
      workoutExerciseIds,
    );
    final bodyWeights = await db.query(
      'body_weight_records',
      orderBy: 'id ASC',
    );

    return _LocalSyncData({
      'exercise_master': exercises,
      _tableExerciseGoals: goals,
      'workout_sessions': sessions,
      'workout_exercises': workoutExercises,
      'set_records': sets,
      'body_weight_records': bodyWeights,
    });
  }

  Future<List<_JsonMap>> _queryWhereIn(
    Database db,
    String tableName,
    String columnName,
    List<int> values,
  ) async {
    if (values.isEmpty) return [];
    final placeholders = List.filled(values.length, '?').join(',');
    return db.query(
      tableName,
      where: '$columnName IN ($placeholders)',
      whereArgs: values,
      orderBy: 'id ASC',
    );
  }

  Map<String, Map<int, String>> _assignRemoteIds(
    _LocalSyncData local,
    Map<String, Map<int, _SyncMapping>> mappings,
  ) {
    final result = <String, Map<int, String>>{};
    for (final table in _syncTables) {
      final tableMappings = mappings[table] ?? const <int, _SyncMapping>{};
      result[table] = {
        for (final row in local.rowsFor(table))
          if (_toInt(row['id']) != null)
            _toInt(row['id'])!:
                tableMappings[_toInt(row['id'])]?.remoteId ?? _uuid.v4(),
      };
    }
    return result;
  }

  List<_JsonMap> _buildPushRows(
    String table,
    _LocalSyncData local,
    Map<String, Map<int, String>> remoteIds,
    String userId,
  ) {
    final rows = <_JsonMap>[];
    for (final row in local.rowsFor(table)) {
      final localId = _toInt(row['id']);
      final remoteId = localId == null ? null : remoteIds[table]?[localId];
      if (localId == null || remoteId == null) continue;

      switch (table) {
        case 'exercise_master':
          rows.add({
            'id': remoteId,
            '_local_id': localId,
            'user_id': userId,
            'name': row['name'],
            'body_part': row['body_part'],
            'is_custom': _toInt(row['is_custom']) ?? 0,
            'record_type': row['record_type'] ?? 'reps',
            'created_at': _toInt(row['created_at']) ?? 0,
            'updated_at': _toInt(row['updated_at']) ?? 0,
          });
        case _tableExerciseGoals:
          final exerciseId = _toInt(row['exercise_id']);
          final remoteExerciseId = exerciseId == null
              ? null
              : remoteIds['exercise_master']?[exerciseId];
          if (remoteExerciseId == null) continue;
          rows.add({
            'id': remoteId,
            '_local_id': localId,
            'user_id': userId,
            'exercise_id': remoteExerciseId,
            'goal_type': row['goal_type'],
            'goal_value': _toDouble(row['goal_value']) ?? 0,
            'deadline_ts': _toInt(row['deadline_ts']),
            'priority': _toInt(row['priority']) ?? 2,
            'created_at': _toInt(row['created_at']) ?? 0,
            'updated_at': _toInt(row['updated_at']) ?? 0,
          });
        case 'workout_sessions':
          rows.add({
            'id': remoteId,
            '_local_id': localId,
            'user_id': userId,
            'status': row['status'],
            'started_at': _toInt(row['started_at']) ?? 0,
            'completed_at': _toInt(row['completed_at']),
            'created_at': _toInt(row['created_at']) ?? 0,
            'updated_at': _toInt(row['updated_at']) ?? 0,
          });
        case 'workout_exercises':
          final sessionId = _toInt(row['session_id']);
          final exerciseId = _toInt(row['exercise_id']);
          final remoteSessionId = sessionId == null
              ? null
              : remoteIds['workout_sessions']?[sessionId];
          final remoteExerciseId = exerciseId == null
              ? null
              : remoteIds['exercise_master']?[exerciseId];
          if (remoteSessionId == null || remoteExerciseId == null) continue;
          rows.add({
            'id': remoteId,
            '_local_id': localId,
            'user_id': userId,
            'session_id': remoteSessionId,
            'exercise_id': remoteExerciseId,
            'order_index': _toInt(row['order_index']) ?? 0,
            'memo': row['memo'],
            'created_at': _toInt(row['created_at']) ?? 0,
            'updated_at': _toInt(row['updated_at']) ?? 0,
          });
        case 'set_records':
          final workoutExerciseId = _toInt(row['workout_exercise_id']);
          final sessionId = _toInt(row['session_id']);
          final exerciseId = _toInt(row['exercise_id']);
          final remoteWorkoutExerciseId = workoutExerciseId == null
              ? null
              : remoteIds['workout_exercises']?[workoutExerciseId];
          final remoteSessionId = sessionId == null
              ? null
              : remoteIds['workout_sessions']?[sessionId];
          final remoteExerciseId = exerciseId == null
              ? null
              : remoteIds['exercise_master']?[exerciseId];
          if (remoteWorkoutExerciseId == null ||
              remoteSessionId == null ||
              remoteExerciseId == null) {
            continue;
          }
          rows.add({
            'id': remoteId,
            '_local_id': localId,
            'user_id': userId,
            'workout_exercise_id': remoteWorkoutExerciseId,
            'session_id': remoteSessionId,
            'exercise_id': remoteExerciseId,
            'set_number': _toInt(row['set_number']) ?? 0,
            'weight_kg': _finiteDouble(row['weight_kg']),
            'weight_lb': _finiteDouble(row['weight_lb']),
            'reps': _toInt(row['reps']),
            'duration_seconds': _toInt(row['duration_seconds']),
            'distance_meters': _toDouble(row['distance_meters']),
            'created_at': _toInt(row['created_at']) ?? 0,
            'updated_at': _toInt(row['updated_at']) ?? 0,
          });
        case 'body_weight_records':
          rows.add({
            'id': remoteId,
            '_local_id': localId,
            'user_id': userId,
            'weight_kg': _finiteDouble(row['weight_kg']),
            'weight_lb': _finiteDouble(row['weight_lb']),
            'memo': row['memo'],
            'recorded_at': _toInt(row['recorded_at']) ?? 0,
            'created_at': _toInt(row['created_at']) ?? 0,
            'updated_at': _toInt(row['updated_at']) ?? 0,
          });
      }
    }
    return rows;
  }

  Future<void> _pushChangedRows({
    required Database db,
    required String tableName,
    required List<_JsonMap> localRows,
    required List<_JsonMap> remoteRows,
    required Map<int, _SyncMapping> mappings,
    required String tag,
  }) async {
    final remoteByLocalId = {
      for (final row in remoteRows)
        if (_toInt(row['_local_id']) != null) _toInt(row['_local_id'])!: row,
    };
    final changed = <_JsonMap>[];
    final changedLocalRows = <_JsonMap>[];

    for (final localRow in localRows) {
      final localId = _toInt(localRow['id']);
      if (localId == null) continue;
      final builtRow = remoteByLocalId[localId];
      if (builtRow == null) continue;
      final updatedAt = _toInt(localRow['updated_at']);
      if (mappings[localId]?.lastSyncedUpdatedAt == updatedAt) continue;
      changed.add(builtRow);
      changedLocalRows.add(localRow);
    }

    if (changed.isEmpty) {
      debugPrint('$tag $tableName unchanged');
      return;
    }

    debugPrint('$tag upsert $tableName changed=${changed.length}');
    await _upsertInBatches(tableName, changed, tag);
    for (var i = 0; i < changed.length; i++) {
      final localId = _toInt(changedLocalRows[i]['id']);
      final remoteId = changed[i]['id'] as String?;
      if (localId == null || remoteId == null) continue;
      await _upsertMapping(
        db,
        tableName: tableName,
        localId: localId,
        remoteId: remoteId,
        lastSyncedUpdatedAt: _toInt(changedLocalRows[i]['updated_at']),
      );
    }
  }

  Future<void> _deleteRemoteRowsMissingLocally({
    required String userId,
    required _LocalSyncData local,
    required Map<String, Map<int, _SyncMapping>> mappings,
    required Map<String, Map<int, String>> assignedRemoteIds,
    required Map<String, List<_JsonMap>>? remoteSnapshot,
    required String tag,
  }) async {
    final db = await DatabaseHelper.instance.database;
    for (final table in _deleteOrder) {
      final localIds = local.localIdsFor(table);
      final idsToDelete = <String>{};

      for (final entry
          in (mappings[table] ?? const <int, _SyncMapping>{}).entries) {
        if (!localIds.contains(entry.key)) {
          idsToDelete.add(entry.value.remoteId);
        }
      }

      final remoteRows = remoteSnapshot?[table] ?? const <_JsonMap>[];
      if (remoteRows.isNotEmpty) {
        final expectedRemoteIds =
            assignedRemoteIds[table]?.values.toSet() ?? const <String>{};
        for (final row in remoteRows) {
          final remoteId = row['id'] as String?;
          if (remoteId != null && !expectedRemoteIds.contains(remoteId)) {
            idsToDelete.add(remoteId);
          }
        }
      }

      if (idsToDelete.isEmpty) continue;
      debugPrint('$tag delete $table missing=${idsToDelete.length}');
      await _deleteRemoteIds(table, idsToDelete.toList(), tag);
      await _deleteMappingsByRemoteIds(db, table, idsToDelete.toList());
    }
  }

  Future<void> _deleteLocalRowsMissingRemotely({
    required Database db,
    required _LocalSyncData local,
    required Map<String, List<_JsonMap>> remoteSnapshot,
    required Map<String, Map<int, _SyncMapping>> mappings,
    required String tag,
  }) async {
    for (final table in _deleteOrder) {
      final remoteIds = (remoteSnapshot[table] ?? const <_JsonMap>[])
          .map((row) => row['id'])
          .whereType<String>()
          .toSet();
      final idsToDelete = <int>{};

      for (final row in local.rowsFor(table)) {
        final localId = _toInt(row['id']);
        if (localId == null) continue;
        final mapping = mappings[table]?[localId];
        if (mapping == null || !remoteIds.contains(mapping.remoteId)) {
          idsToDelete.add(localId);
        }
      }

      if (idsToDelete.isEmpty) continue;
      debugPrint('$tag delete local $table missing=${idsToDelete.length}');
      await _deleteLocalIds(db, table, idsToDelete.toList());
      await _deleteMappingsByLocalIds(db, table, idsToDelete.toList());
    }
  }

  Future<void> _pullTableRows({
    required Database db,
    required String tableName,
    required List<_JsonMap> remoteRows,
    required Map<String, Map<String, int>> remoteToLocal,
    required Map<String, _SyncMapping> mappingsByRemote,
    required String tag,
  }) async {
    var changedCount = 0;
    for (final remoteRow in remoteRows) {
      final remoteId = remoteRow['id'] as String?;
      if (remoteId == null) continue;

      final localValues = _buildLocalPullRow(
        tableName,
        remoteRow,
        remoteToLocal,
      );
      if (localValues == null) continue;

      final mapping = mappingsByRemote[remoteId];
      int localId;
      final remoteUpdatedAt = _toInt(remoteRow['updated_at']);
      if (mapping != null) {
        localId = mapping.localId;
        if (mapping.lastSyncedUpdatedAt != remoteUpdatedAt) {
          final updated = await db.update(
            tableName,
            localValues,
            where: 'id = ?',
            whereArgs: [localId],
          );
          if (updated == 0) {
            localId = await db.insert(tableName, localValues);
          }
          changedCount++;
        }
      } else {
        localId = await db.insert(tableName, localValues);
        changedCount++;
      }

      remoteToLocal.putIfAbsent(tableName, () => {})[remoteId] = localId;
      await _upsertMapping(
        db,
        tableName: tableName,
        localId: localId,
        remoteId: remoteId,
        lastSyncedUpdatedAt: remoteUpdatedAt,
      );
    }
    debugPrint(
      '$tag $tableName pulled changed=$changedCount total=${remoteRows.length}',
    );
  }

  _JsonMap? _buildLocalPullRow(
    String table,
    _JsonMap row,
    Map<String, Map<String, int>> remoteToLocal,
  ) {
    switch (table) {
      case 'exercise_master':
        return {
          'name': row['name'],
          'body_part': row['body_part'],
          'is_custom': _toInt(row['is_custom']) ?? 0,
          'record_type': row['record_type'] ?? 'reps',
          'created_at': _toInt(row['created_at']) ?? 0,
          'updated_at': _toInt(row['updated_at']) ?? 0,
        };
      case _tableExerciseGoals:
        final exerciseId = row['exercise_id'] as String?;
        final localExerciseId = exerciseId == null
            ? null
            : remoteToLocal['exercise_master']?[exerciseId];
        if (localExerciseId == null) return null;
        return {
          'exercise_id': localExerciseId,
          'goal_type': row['goal_type'],
          'goal_value': _toDouble(row['goal_value']) ?? 0,
          'deadline_ts': _toInt(row['deadline_ts']),
          'priority': _toInt(row['priority']) ?? 2,
          'created_at': _toInt(row['created_at']) ?? 0,
          'updated_at': _toInt(row['updated_at']) ?? 0,
        };
      case 'workout_sessions':
        return {
          'status': row['status'],
          'started_at': _toInt(row['started_at']) ?? 0,
          'completed_at': _toInt(row['completed_at']),
          'created_at': _toInt(row['created_at']) ?? 0,
          'updated_at': _toInt(row['updated_at']) ?? 0,
        };
      case 'workout_exercises':
        final sessionId = row['session_id'] as String?;
        final exerciseId = row['exercise_id'] as String?;
        final localSessionId = sessionId == null
            ? null
            : remoteToLocal['workout_sessions']?[sessionId];
        final localExerciseId = exerciseId == null
            ? null
            : remoteToLocal['exercise_master']?[exerciseId];
        if (localSessionId == null || localExerciseId == null) return null;
        return {
          'session_id': localSessionId,
          'exercise_id': localExerciseId,
          'order_index': _toInt(row['order_index']) ?? 0,
          'memo': row['memo'],
          'created_at': _toInt(row['created_at']) ?? 0,
          'updated_at': _toInt(row['updated_at']) ?? 0,
        };
      case 'set_records':
        final workoutExerciseId = row['workout_exercise_id'] as String?;
        final sessionId = row['session_id'] as String?;
        final exerciseId = row['exercise_id'] as String?;
        final localWorkoutExerciseId = workoutExerciseId == null
            ? null
            : remoteToLocal['workout_exercises']?[workoutExerciseId];
        final localSessionId = sessionId == null
            ? null
            : remoteToLocal['workout_sessions']?[sessionId];
        final localExerciseId = exerciseId == null
            ? null
            : remoteToLocal['exercise_master']?[exerciseId];
        if (localWorkoutExerciseId == null ||
            localSessionId == null ||
            localExerciseId == null) {
          return null;
        }
        return {
          'workout_exercise_id': localWorkoutExerciseId,
          'session_id': localSessionId,
          'exercise_id': localExerciseId,
          'set_number': _toInt(row['set_number']) ?? 0,
          'weight_kg': _finiteDouble(row['weight_kg']),
          'weight_lb': _finiteDouble(row['weight_lb']),
          'reps': _toInt(row['reps']),
          'duration_seconds': _toInt(row['duration_seconds']),
          'distance_meters': _toDouble(row['distance_meters']),
          'created_at': _toInt(row['created_at']) ?? 0,
          'updated_at': _toInt(row['updated_at']) ?? 0,
        };
      case 'body_weight_records':
        return {
          'weight_kg': _finiteDouble(row['weight_kg']),
          'weight_lb': _finiteDouble(row['weight_lb']),
          'memo': row['memo'],
          'recorded_at': _toInt(row['recorded_at']) ?? 0,
          'created_at': _toInt(row['created_at']) ?? 0,
          'updated_at': _toInt(row['updated_at']) ?? 0,
        };
      default:
        return null;
    }
  }

  Future<Map<String, List<_JsonMap>>> _fetchRemoteSnapshot(
    String userId,
  ) async {
    final result = <String, List<_JsonMap>>{};
    for (final table in _syncTables) {
      result[table] = await _remoteStore.fetchAll(table, userId);
    }
    return result;
  }

  Future<void> _bootstrapMappings(
    Database db,
    _LocalSyncData local,
    Map<String, List<_JsonMap>> remote,
  ) async {
    await _bootstrapByKey(
      db,
      'exercise_master',
      local.rowsFor('exercise_master'),
      remote['exercise_master'] ?? const [],
      [
        (row, _) => [
          row['name'],
          row['body_part'],
          _toInt(row['is_custom']) ?? 0,
          row['record_type'] ?? 'reps',
          _toInt(row['created_at']) ?? 0,
        ].join('|'),
        (row, _) => [
          _toInt(row['is_custom']) ?? 0,
          row['record_type'] ?? 'reps',
          _toInt(row['created_at']) ?? 0,
        ].join('|'),
      ],
    );

    await _bootstrapByKey(
      db,
      'workout_sessions',
      local.rowsFor('workout_sessions'),
      remote['workout_sessions'] ?? const [],
      [
        (row, _) => [
          row['status'],
          _toInt(row['started_at']) ?? 0,
          _toInt(row['completed_at']) ?? 0,
          _toInt(row['created_at']) ?? 0,
        ].join('|'),
      ],
    );

    await _bootstrapByKey(
      db,
      'body_weight_records',
      local.rowsFor('body_weight_records'),
      remote['body_weight_records'] ?? const [],
      [
        (row, _) => [
          _toInt(row['recorded_at']) ?? 0,
          _toInt(row['created_at']) ?? 0,
        ].join('|'),
      ],
    );

    var mappings = await _loadAllMappings(db);
    var remoteToLocal = _remoteToLocalIds(mappings);

    await _bootstrapByKey(
      db,
      _tableExerciseGoals,
      local.rowsFor(_tableExerciseGoals),
      remote[_tableExerciseGoals] ?? const [],
      [
        (row, byRemote) {
          final exerciseId = row['exercise_id'];
          final localExerciseId = (exerciseId is String)
              ? (byRemote['exercise_master'] ??
                    const <String, int>{})[exerciseId]
              : _toInt(exerciseId);
          return localExerciseId == null ? null : '$localExerciseId';
        },
      ],
      remoteToLocal: remoteToLocal,
    );

    mappings = await _loadAllMappings(db);
    remoteToLocal = _remoteToLocalIds(mappings);

    await _bootstrapByKey(
      db,
      'workout_exercises',
      local.rowsFor('workout_exercises'),
      remote['workout_exercises'] ?? const [],
      [
        (row, byRemote) {
          final sessionId = row['session_id'];
          final exerciseId = row['exercise_id'];
          final localSessionId = (sessionId is String)
              ? (byRemote['workout_sessions'] ??
                    const <String, int>{})[sessionId]
              : _toInt(sessionId);
          final localExerciseId = (exerciseId is String)
              ? (byRemote['exercise_master'] ??
                    const <String, int>{})[exerciseId]
              : _toInt(exerciseId);
          if (localSessionId == null || localExerciseId == null) return null;
          return [
            localSessionId,
            localExerciseId,
            _toInt(row['order_index']) ?? 0,
            _toInt(row['created_at']) ?? 0,
          ].join('|');
        },
      ],
      remoteToLocal: remoteToLocal,
    );

    mappings = await _loadAllMappings(db);
    remoteToLocal = _remoteToLocalIds(mappings);

    await _bootstrapByKey(
      db,
      'set_records',
      local.rowsFor('set_records'),
      remote['set_records'] ?? const [],
      [
        (row, byRemote) {
          final workoutExerciseId = row['workout_exercise_id'];
          final localWorkoutExerciseId = (workoutExerciseId is String)
              ? (byRemote['workout_exercises'] ??
                    const <String, int>{})[workoutExerciseId]
              : _toInt(workoutExerciseId);
          if (localWorkoutExerciseId == null) return null;
          return [
            localWorkoutExerciseId,
            _toInt(row['set_number']) ?? 0,
            _toInt(row['created_at']) ?? 0,
          ].join('|');
        },
      ],
      remoteToLocal: remoteToLocal,
    );
  }

  Future<void> _bootstrapByKey(
    Database db,
    String tableName,
    List<_JsonMap> localRows,
    List<_JsonMap> remoteRows,
    List<
      String? Function(
        _JsonMap row,
        Map<String, Map<String, int>> remoteToLocal,
      )
    >
    keyBuilders, {
    Map<String, Map<String, int>> remoteToLocal = const {},
  }) async {
    final mappedLocalIds = <int>{};
    final mappedRemoteIds = <String>{};
    for (final keyBuilder in keyBuilders) {
      final localByKey = _uniqueRowsByKey(
        localRows.where((row) {
          final localId = _toInt(row['id']);
          return localId != null && !mappedLocalIds.contains(localId);
        }).toList(),
        keyBuilder,
        remoteToLocal,
      );
      final remoteByKey = _uniqueRowsByKey(
        remoteRows.where((row) {
          final remoteId = row['id'] as String?;
          return remoteId != null && !mappedRemoteIds.contains(remoteId);
        }).toList(),
        keyBuilder,
        remoteToLocal,
      );
      for (final entry in localByKey.entries) {
        final remoteRow = remoteByKey[entry.key];
        final remoteId = remoteRow?['id'] as String?;
        final localId = _toInt(entry.value['id']);
        if (remoteId == null || localId == null) continue;
        await _upsertMapping(
          db,
          tableName: tableName,
          localId: localId,
          remoteId: remoteId,
          lastSyncedUpdatedAt: _toInt(remoteRow?['updated_at']),
        );
        mappedLocalIds.add(localId);
        mappedRemoteIds.add(remoteId);
      }
    }
  }

  Map<String, _JsonMap> _uniqueRowsByKey(
    List<_JsonMap> rows,
    String? Function(_JsonMap row, Map<String, Map<String, int>> remoteToLocal)
    keyBuilder,
    Map<String, Map<String, int>> remoteToLocal,
  ) {
    final result = <String, _JsonMap>{};
    final duplicateKeys = <String>{};
    for (final row in rows) {
      final key = keyBuilder(row, remoteToLocal);
      if (key == null || key.isEmpty) continue;
      if (result.containsKey(key)) {
        duplicateKeys.add(key);
      } else {
        result[key] = row;
      }
    }
    for (final key in duplicateKeys) {
      result.remove(key);
    }
    return result;
  }

  Future<Map<String, Map<int, _SyncMapping>>> _loadAllMappings(
    Database db,
  ) async {
    final result = <String, Map<int, _SyncMapping>>{};
    final rows = await db.query('sync_metadata');
    for (final row in rows) {
      final mapping = _SyncMapping.fromMap(row);
      result.putIfAbsent(mapping.tableName, () => {})[mapping.localId] =
          mapping;
    }
    return result;
  }

  Map<String, Map<String, int>> _remoteToLocalIds(
    Map<String, Map<int, _SyncMapping>> mappings,
  ) {
    return {
      for (final entry in mappings.entries)
        entry.key: {
          for (final mapping in entry.value.values)
            mapping.remoteId: mapping.localId,
        },
    };
  }

  Map<String, _SyncMapping> _mappingsByRemote(Map<int, _SyncMapping> mappings) {
    return {for (final mapping in mappings.values) mapping.remoteId: mapping};
  }

  Future<int> _mappingCount(Database db) async {
    final result = await db.rawQuery(
      'SELECT COUNT(*) AS count FROM sync_metadata',
    );
    return _toInt(result.first['count']) ?? 0;
  }

  Future<void> _upsertMapping(
    Database db, {
    required String tableName,
    required int localId,
    required String remoteId,
    required int? lastSyncedUpdatedAt,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    await db.insert('sync_metadata', {
      'table_name': tableName,
      'local_id': localId,
      'remote_id': remoteId,
      'last_synced_updated_at': lastSyncedUpdatedAt,
      'created_at': now,
      'updated_at': now,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> _deleteLocalIds(
    Database db,
    String tableName,
    List<int> ids,
  ) async {
    for (var i = 0; i < ids.length; i += _batchSize) {
      final chunk = ids.sublist(i, (i + _batchSize).clamp(0, ids.length));
      final placeholders = List.filled(chunk.length, '?').join(',');
      await db.delete(
        tableName,
        where: 'id IN ($placeholders)',
        whereArgs: chunk,
      );
    }
  }

  Future<void> _deleteMappingsByLocalIds(
    Database db,
    String tableName,
    List<int> ids,
  ) async {
    if (ids.isEmpty) return;
    for (var i = 0; i < ids.length; i += _batchSize) {
      final chunk = ids.sublist(i, (i + _batchSize).clamp(0, ids.length));
      final placeholders = List.filled(chunk.length, '?').join(',');
      await db.delete(
        'sync_metadata',
        where: 'table_name = ? AND local_id IN ($placeholders)',
        whereArgs: [tableName, ...chunk],
      );
    }
  }

  Future<void> _deleteMappingsByRemoteIds(
    Database db,
    String tableName,
    List<String> ids,
  ) async {
    if (ids.isEmpty) return;
    for (var i = 0; i < ids.length; i += _batchSize) {
      final chunk = ids.sublist(i, (i + _batchSize).clamp(0, ids.length));
      final placeholders = List.filled(chunk.length, '?').join(',');
      await db.delete(
        'sync_metadata',
        where: 'table_name = ? AND remote_id IN ($placeholders)',
        whereArgs: [tableName, ...chunk],
      );
    }
  }

  Future<void> _deleteRemoteIds(
    String tableName,
    List<String> ids,
    String tag,
  ) async {
    for (var i = 0; i < ids.length; i += _batchSize) {
      final chunk = ids.sublist(i, (i + _batchSize).clamp(0, ids.length));
      await _remoteStore.deleteIds(tableName, chunk);
      debugPrint(
        '$tag $tableName batch ${i ~/ _batchSize + 1} deleted ${chunk.length}',
      );
    }
  }

  Future<void> _upsertInBatches(
    String tableName,
    List<_JsonMap> rows,
    String tag,
  ) async {
    if (rows.isEmpty) return;
    for (var i = 0; i < rows.length; i += _batchSize) {
      final end = (i + _batchSize).clamp(0, rows.length);
      final chunk = rows
          .sublist(i, end)
          .map((row) => Map<String, dynamic>.from(row)..remove('_local_id'))
          .toList();
      await _remoteStore.upsert(tableName, chunk);
      debugPrint(
        '$tag $tableName batch ${i ~/ _batchSize + 1} upserted ${chunk.length}',
      );
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

  static double _finiteDouble(dynamic v) {
    final value = _toDouble(v) ?? 0;
    return value.isFinite ? value : 0;
  }
}

class _LocalSyncData {
  const _LocalSyncData(this._rowsByTable);

  final Map<String, List<_JsonMap>> _rowsByTable;

  List<_JsonMap> rowsFor(String tableName) =>
      _rowsByTable[tableName] ?? const [];

  Set<int> localIdsFor(String tableName) {
    return rowsFor(
      tableName,
    ).map((row) => SyncService._toInt(row['id'])).whereType<int>().toSet();
  }
}

class _SyncMapping {
  const _SyncMapping({
    required this.tableName,
    required this.localId,
    required this.remoteId,
    required this.lastSyncedUpdatedAt,
  });

  final String tableName;
  final int localId;
  final String remoteId;
  final int? lastSyncedUpdatedAt;

  factory _SyncMapping.fromMap(_JsonMap map) {
    return _SyncMapping(
      tableName: map['table_name'] as String,
      localId: SyncService._toInt(map['local_id']) ?? 0,
      remoteId: map['remote_id'] as String,
      lastSyncedUpdatedAt: SyncService._toInt(map['last_synced_updated_at']),
    );
  }
}
