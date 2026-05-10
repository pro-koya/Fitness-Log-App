import 'package:fitness_log_app/data/database/database_helper.dart';
import 'package:fitness_log_app/services/supabase_auth_service.dart';
import 'package:fitness_log_app/services/sync_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

const _userId = '00000000-0000-0000-0000-000000000001';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  tearDown(() async {
    await DatabaseHelper.instance.deleteDB();
  });

  test('push creates all rows once, then a second push is a no-op', () async {
    final db = await _freshDatabase();
    await _seedLocalDataset(db);
    final remote = FakeSyncRemoteStore();
    final service = _service(remote);

    expect(await service.syncNow(), isNull);

    expect(remote.count('exercise_master'), 1);
    expect(remote.count('exercise_goals'), 1);
    expect(remote.count('workout_sessions'), 1);
    expect(remote.count('workout_exercises'), 1);
    expect(remote.count('set_records'), 1);
    expect(remote.count('body_weight_records'), 1);

    final session = remote.single('workout_sessions');
    final workoutExercise = remote.single('workout_exercises');
    final set = remote.single('set_records');
    expect(workoutExercise['session_id'], session['id']);
    expect(set['workout_exercise_id'], workoutExercise['id']);
    expect(set['session_id'], session['id']);
    expect(remote.upsertedTables, containsAll(_syncTables));

    remote.clearLog();
    expect(await service.syncNow(), isNull);
    expect(remote.upsertLog, isEmpty);
    expect(remote.deleteLog, isEmpty);
  });

  test(
    'push sends only updated local rows and keeps remote IDs stable',
    () async {
      final db = await _freshDatabase();
      final ids = await _seedLocalDataset(db);
      final remote = FakeSyncRemoteStore();
      final service = _service(remote);
      expect(await service.syncNow(), isNull);

      final originalSetRemoteId = remote.single('set_records')['id'];
      remote.clearLog();

      await db.update(
        'set_records',
        {'weight_kg': 102.5, 'weight_lb': 225.97, 'updated_at': 2000},
        where: 'id = ?',
        whereArgs: [ids.setId],
      );

      expect(await service.syncNow(), isNull);

      expect(remote.upsertLog, hasLength(1));
      expect(remote.upsertLog.single.tableName, 'set_records');
      expect(remote.upsertLog.single.rows, hasLength(1));
      expect(remote.upsertLog.single.rows.single['id'], originalSetRemoteId);
      expect(remote.upsertLog.single.rows.single['weight_kg'], 102.5);
      expect(remote.deleteLog, isEmpty);
      expect(remote.single('set_records')['id'], originalSetRemoteId);
    },
  );

  test(
    'push propagates local deletions without replacing unchanged data',
    () async {
      final db = await _freshDatabase();
      final ids = await _seedLocalDataset(db);
      final remote = FakeSyncRemoteStore();
      final service = _service(remote);
      expect(await service.syncNow(), isNull);
      remote.clearLog();

      await db.delete('set_records', where: 'id = ?', whereArgs: [ids.setId]);
      await db.delete(
        'exercise_goals',
        where: 'id = ?',
        whereArgs: [ids.goalId],
      );
      await db.delete(
        'body_weight_records',
        where: 'id = ?',
        whereArgs: [ids.bodyWeightId],
      );

      expect(await service.syncNow(), isNull);

      expect(remote.count('set_records'), 0);
      expect(remote.count('exercise_goals'), 0);
      expect(remote.count('body_weight_records'), 0);
      expect(remote.count('exercise_master'), 1);
      expect(remote.count('workout_sessions'), 1);
      expect(remote.count('workout_exercises'), 1);
      expect(remote.upsertLog, isEmpty);
      expect(
        remote.deletedTables,
        containsAll(['set_records', 'exercise_goals', 'body_weight_records']),
      );
    },
  );

  test(
    'pull applies remote creates, updates, and deletes incrementally',
    () async {
      final db = await _freshDatabase();
      await _seedLocalDataset(db);
      final remote = FakeSyncRemoteStore();
      final service = _service(remote);
      expect(await service.syncNow(), isNull);

      final exerciseRemoteId = remote.single('exercise_master')['id'] as String;
      final setRemoteId = remote.single('set_records')['id'] as String;
      remote.replaceRow('exercise_master', exerciseRemoteId, {
        ...remote.single('exercise_master'),
        'name': 'Bench Press Updated',
        'updated_at': 3000,
      });
      remote.removeRow('set_records', setRemoteId);
      remote.putRow('body_weight_records', {
        'id': 'remote-body-weight-new',
        'user_id': _userId,
        'weight_kg': 71.0,
        'weight_lb': 156.53,
        'memo': 'remote create',
        'recorded_at': 11000,
        'created_at': 11000,
        'updated_at': 11000,
      });

      remote.clearLog();
      expect(await service.pullFromServer(), isNull);

      final exercises = await db.query('exercise_master');
      final sets = await db.query('set_records');
      final bodyWeights = await db.query(
        'body_weight_records',
        orderBy: 'recorded_at ASC',
      );
      expect(exercises.single['name'], 'Bench Press Updated');
      expect(sets, isEmpty);
      expect(bodyWeights, hasLength(2));
      expect(bodyWeights.last['memo'], 'remote create');
    },
  );

  test(
    'bootstrap maps existing full-sync cloud rows before diff updates',
    () async {
      final db = await _freshDatabase();
      final ids = await _seedLocalDataset(db);
      final remote = FakeSyncRemoteStore();
      await _seedMatchingRemoteDataset(remote);
      final service = _service(remote);

      expect(await service.syncNow(), isNull);

      expect(remote.upsertLog, isEmpty);
      expect(remote.deleteLog, isEmpty);
      expect(remote.count('exercise_master'), 1);
      expect(await _metadataCount(db), 6);

      remote.clearLog();
      await db.update(
        'exercise_master',
        {'name': 'Mapped Bench Press', 'updated_at': 4000},
        where: 'id = ?',
        whereArgs: [ids.exerciseId],
      );

      expect(await service.syncNow(), isNull);

      expect(remote.upsertLog, hasLength(1));
      expect(remote.upsertLog.single.tableName, 'exercise_master');
      expect(remote.count('exercise_master'), 1);
      expect(
        remote.single('exercise_master')['id'],
        'remote-exercise-existing',
      );
      expect(remote.single('exercise_master')['name'], 'Mapped Bench Press');
    },
  );
}

const _syncTables = [
  'exercise_master',
  'exercise_goals',
  'workout_sessions',
  'workout_exercises',
  'set_records',
  'body_weight_records',
];

SyncService _service(FakeSyncRemoteStore remote) {
  return SyncService(authService: _FakeAuthService(), remoteStore: remote);
}

Future<Database> _freshDatabase() async {
  await DatabaseHelper.instance.deleteDB();
  final db = await DatabaseHelper.instance.database;
  await db.delete('sync_metadata');
  await db.delete('set_records');
  await db.delete('workout_exercises');
  await db.delete('workout_sessions');
  await db.delete('exercise_goals');
  await db.delete('body_weight_records');
  await db.delete('exercise_master');
  return db;
}

Future<_LocalIds> _seedLocalDataset(Database db) async {
  final exerciseId = await db.insert('exercise_master', {
    'name': 'Bench Press',
    'body_part': 'chest',
    'is_custom': 0,
    'record_type': 'reps',
    'created_at': 1000,
    'updated_at': 1000,
  });
  final goalId = await db.insert('exercise_goals', {
    'exercise_id': exerciseId,
    'goal_type': 'weight',
    'goal_value': 120.0,
    'deadline_ts': 9000,
    'priority': 3,
    'created_at': 1001,
    'updated_at': 1001,
  });
  final sessionId = await db.insert('workout_sessions', {
    'status': 'completed',
    'started_at': 1010,
    'completed_at': 1200,
    'created_at': 1010,
    'updated_at': 1200,
  });
  final workoutExerciseId = await db.insert('workout_exercises', {
    'session_id': sessionId,
    'exercise_id': exerciseId,
    'order_index': 0,
    'memo': 'local memo',
    'created_at': 1020,
    'updated_at': 1020,
  });
  final setId = await db.insert('set_records', {
    'workout_exercise_id': workoutExerciseId,
    'session_id': sessionId,
    'exercise_id': exerciseId,
    'set_number': 1,
    'weight_kg': 100.0,
    'weight_lb': 220.46,
    'reps': 5,
    'duration_seconds': null,
    'distance_meters': null,
    'created_at': 1030,
    'updated_at': 1030,
  });
  final bodyWeightId = await db.insert('body_weight_records', {
    'weight_kg': 70.0,
    'weight_lb': 154.32,
    'memo': 'morning',
    'recorded_at': 10000,
    'created_at': 10000,
    'updated_at': 10000,
  });
  return _LocalIds(
    exerciseId: exerciseId,
    goalId: goalId,
    sessionId: sessionId,
    workoutExerciseId: workoutExerciseId,
    setId: setId,
    bodyWeightId: bodyWeightId,
  );
}

Future<void> _seedMatchingRemoteDataset(FakeSyncRemoteStore remote) async {
  remote.putRow('exercise_master', {
    'id': 'remote-exercise-existing',
    'user_id': _userId,
    'name': 'Bench Press',
    'body_part': 'chest',
    'is_custom': 0,
    'record_type': 'reps',
    'created_at': 1000,
    'updated_at': 1000,
  });
  remote.putRow('exercise_goals', {
    'id': 'remote-goal-existing',
    'user_id': _userId,
    'exercise_id': 'remote-exercise-existing',
    'goal_type': 'weight',
    'goal_value': 120.0,
    'deadline_ts': 9000,
    'priority': 3,
    'created_at': 1001,
    'updated_at': 1001,
  });
  remote.putRow('workout_sessions', {
    'id': 'remote-session-existing',
    'user_id': _userId,
    'status': 'completed',
    'started_at': 1010,
    'completed_at': 1200,
    'created_at': 1010,
    'updated_at': 1200,
  });
  remote.putRow('workout_exercises', {
    'id': 'remote-workout-exercise-existing',
    'user_id': _userId,
    'session_id': 'remote-session-existing',
    'exercise_id': 'remote-exercise-existing',
    'order_index': 0,
    'memo': 'local memo',
    'created_at': 1020,
    'updated_at': 1020,
  });
  remote.putRow('set_records', {
    'id': 'remote-set-existing',
    'user_id': _userId,
    'workout_exercise_id': 'remote-workout-exercise-existing',
    'session_id': 'remote-session-existing',
    'exercise_id': 'remote-exercise-existing',
    'set_number': 1,
    'weight_kg': 100.0,
    'weight_lb': 220.46,
    'reps': 5,
    'duration_seconds': null,
    'distance_meters': null,
    'created_at': 1030,
    'updated_at': 1030,
  });
  remote.putRow('body_weight_records', {
    'id': 'remote-body-weight-existing',
    'user_id': _userId,
    'weight_kg': 70.0,
    'weight_lb': 154.32,
    'memo': 'morning',
    'recorded_at': 10000,
    'created_at': 10000,
    'updated_at': 10000,
  });
}

Future<int> _metadataCount(Database db) async {
  final rows = await db.rawQuery('SELECT COUNT(*) AS count FROM sync_metadata');
  return rows.single['count'] as int;
}

class _FakeAuthService extends SupabaseAuthService {
  @override
  String? get currentUserId => _userId;
}

class _LocalIds {
  const _LocalIds({
    required this.exerciseId,
    required this.goalId,
    required this.sessionId,
    required this.workoutExerciseId,
    required this.setId,
    required this.bodyWeightId,
  });

  final int exerciseId;
  final int goalId;
  final int sessionId;
  final int workoutExerciseId;
  final int setId;
  final int bodyWeightId;
}

class FakeSyncRemoteStore implements SyncRemoteStore {
  final Map<String, Map<String, Map<String, dynamic>>> _tables = {};
  final upsertLog = <_RemoteWrite>[];
  final deleteLog = <_RemoteDelete>[];

  @override
  Future<List<Map<String, dynamic>>> fetchAll(
    String tableName,
    String userId,
  ) async {
    final rows = _tables[tableName]?.values ?? const Iterable.empty();
    return rows
        .where((row) => row['user_id'] == userId)
        .map((row) => Map<String, dynamic>.from(row))
        .toList()
      ..sort((a, b) => (a['id'] as String).compareTo(b['id'] as String));
  }

  @override
  Future<void> upsert(String tableName, List<Map<String, dynamic>> rows) async {
    upsertLog.add(_RemoteWrite(tableName, rows));
    for (final row in rows) {
      putRow(tableName, row);
    }
  }

  @override
  Future<void> deleteIds(String tableName, List<String> ids) async {
    deleteLog.add(_RemoteDelete(tableName, ids));
    for (final id in ids) {
      _tables[tableName]?.remove(id);
    }
  }

  void putRow(String tableName, Map<String, dynamic> row) {
    final id = row['id'] as String;
    _tables.putIfAbsent(tableName, () => {})[id] = Map<String, dynamic>.from(
      row,
    );
  }

  void replaceRow(String tableName, String id, Map<String, dynamic> row) {
    _tables.putIfAbsent(tableName, () => {})[id] = Map<String, dynamic>.from(
      row,
    );
  }

  void removeRow(String tableName, String id) {
    _tables[tableName]?.remove(id);
  }

  int count(String tableName) => _tables[tableName]?.length ?? 0;

  Map<String, dynamic> single(String tableName) {
    return Map<String, dynamic>.from(_tables[tableName]!.values.single);
  }

  Iterable<String> get upsertedTables =>
      upsertLog.map((entry) => entry.tableName);

  Iterable<String> get deletedTables =>
      deleteLog.map((entry) => entry.tableName);

  void clearLog() {
    upsertLog.clear();
    deleteLog.clear();
  }
}

class _RemoteWrite {
  _RemoteWrite(this.tableName, List<Map<String, dynamic>> rows)
    : rows = rows.map((row) => Map<String, dynamic>.from(row)).toList();

  final String tableName;
  final List<Map<String, dynamic>> rows;
}

class _RemoteDelete {
  _RemoteDelete(this.tableName, List<String> ids) : ids = List.of(ids);

  final String tableName;
  final List<String> ids;
}
