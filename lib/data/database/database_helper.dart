import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// Database helper for SQLite operations
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  /// Get database instance
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('fitness_log.db');
    return _database!;
  }

  /// Initialize database
  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 9,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  /// Create database tables
  Future<void> _createDB(Database db, int version) async {
    // 1. settings table
    await db.execute('''
      CREATE TABLE settings (
        id INTEGER PRIMARY KEY CHECK(id = 1),
        language TEXT NOT NULL DEFAULT 'en',
        unit TEXT NOT NULL DEFAULT 'kg',
        distance_unit TEXT NOT NULL DEFAULT 'km',
        entitlement TEXT NOT NULL DEFAULT 'free',
        theme_settings TEXT,
        setup_completed INTEGER NOT NULL DEFAULT 0,
        tutorial_completed INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    // 2. exercise_master table
    await db.execute('''
      CREATE TABLE exercise_master (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        body_part TEXT,
        is_custom INTEGER NOT NULL DEFAULT 0,
        record_type TEXT NOT NULL DEFAULT 'reps',
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_exercise_master_name ON exercise_master(name)
    ''');

    // 3. workout_sessions table
    await db.execute('''
      CREATE TABLE workout_sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        status TEXT NOT NULL CHECK(status IN ('in_progress', 'completed')),
        started_at INTEGER NOT NULL,
        completed_at INTEGER,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_workout_sessions_status_completed_at
        ON workout_sessions(status, completed_at)
    ''');

    // 4. workout_exercises table
    await db.execute('''
      CREATE TABLE workout_exercises (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id INTEGER NOT NULL,
        exercise_id INTEGER NOT NULL,
        order_index INTEGER NOT NULL,
        memo TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        FOREIGN KEY (session_id) REFERENCES workout_sessions(id) ON DELETE CASCADE,
        FOREIGN KEY (exercise_id) REFERENCES exercise_master(id)
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_workout_exercises_session_id_order
        ON workout_exercises(session_id, order_index)
    ''');

    await db.execute('''
      CREATE INDEX idx_workout_exercises_exercise_id
        ON workout_exercises(exercise_id)
    ''');

    // 5. set_records table (with dual unit support, duration, and distance)
    await db.execute('''
      CREATE TABLE set_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        workout_exercise_id INTEGER NOT NULL,
        session_id INTEGER NOT NULL,
        exercise_id INTEGER NOT NULL,
        set_number INTEGER NOT NULL,
        weight_kg REAL NOT NULL,
        weight_lb REAL NOT NULL,
        reps INTEGER,
        duration_seconds INTEGER,
        distance_meters REAL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        FOREIGN KEY (workout_exercise_id) REFERENCES workout_exercises(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_set_records_workout_exercise_id_set_number
        ON set_records(workout_exercise_id, set_number)
    ''');

    await db.execute('''
      CREATE INDEX idx_set_records_exercise_id_session_id
        ON set_records(exercise_id, session_id)
    ''');

    // Insert initial data
    await _insertInitialData(db);
  }

  /// Insert initial data
  Future<void> _insertInitialData(Database db) async {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    // 1. Insert default settings (setup_completed = 0 for new installs)
    await db.insert('settings', {
      'id': 1,
      'language': 'en',
      'unit': 'kg',
      'distance_unit': 'km',
      'entitlement': 'free',
      'theme_settings': null,
      'setup_completed': 0,
      'tutorial_completed': 0,
      'created_at': now,
      'updated_at': now,
    });

    // 2. Insert standard exercises (based on StandardExercise.md)
    final standardExercises = [
      // Chest
      {'name': 'Bench Press', 'body_part': 'chest', 'record_type': 'reps'},
      {'name': 'Incline Bench Press', 'body_part': 'chest', 'record_type': 'reps'},
      {'name': 'Dumbbell Bench Press', 'body_part': 'chest', 'record_type': 'reps'},
      {'name': 'Incline Dumbbell Bench Press', 'body_part': 'chest', 'record_type': 'reps'},
      {'name': 'Smith Press', 'body_part': 'chest', 'record_type': 'reps'},
      {'name': 'Incline Smith Press', 'body_part': 'chest', 'record_type': 'reps'},
      {'name': 'Dumbbell Fly', 'body_part': 'chest', 'record_type': 'reps'},
      {'name': 'Incline Dumbbell Fly', 'body_part': 'chest', 'record_type': 'reps'},
      {'name': 'Cable Fly', 'body_part': 'chest', 'record_type': 'reps'},
      {'name': 'Push-Up', 'body_part': 'chest', 'record_type': 'reps'},
      // Back
      {'name': 'Pull-Up', 'body_part': 'back', 'record_type': 'reps'},
      {'name': 'Lat Pulldown', 'body_part': 'back', 'record_type': 'reps'},
      {'name': 'Barbell Row', 'body_part': 'back', 'record_type': 'reps'},
      {'name': 'Dumbbell Row', 'body_part': 'back', 'record_type': 'reps'},
      {'name': 'Seated Row', 'body_part': 'back', 'record_type': 'reps'},
      {'name': 'Deadlift', 'body_part': 'back', 'record_type': 'reps'},
      // Legs
      {'name': 'Squat', 'body_part': 'legs', 'record_type': 'reps'},
      {'name': 'Leg Press', 'body_part': 'legs', 'record_type': 'reps'},
      {'name': 'Leg Extension', 'body_part': 'legs', 'record_type': 'reps'},
      {'name': 'Leg Curl', 'body_part': 'legs', 'record_type': 'reps'},
      {'name': 'Lunge', 'body_part': 'legs', 'record_type': 'reps'},
      {'name': 'Calf Raise', 'body_part': 'legs', 'record_type': 'reps'},
      // Shoulders
      {'name': 'Shoulder Press', 'body_part': 'shoulders', 'record_type': 'reps'},
      {'name': 'Smith Shoulder Press', 'body_part': 'shoulders', 'record_type': 'reps'},
      {'name': 'Dumbbell Shoulder Press', 'body_part': 'shoulders', 'record_type': 'reps'},
      {'name': 'Lateral Raise', 'body_part': 'shoulders', 'record_type': 'reps'},
      {'name': 'Incline Lateral Raise', 'body_part': 'shoulders', 'record_type': 'reps'},
      {'name': 'Front Raise', 'body_part': 'shoulders', 'record_type': 'reps'},
      {'name': 'Rear Delt Raise', 'body_part': 'shoulders', 'record_type': 'reps'},
      {'name': 'Arnold Press', 'body_part': 'shoulders', 'record_type': 'reps'},
      // Biceps
      {'name': 'Biceps Curl', 'body_part': 'biceps', 'record_type': 'reps'},
      {'name': 'Dumbbell Curl', 'body_part': 'biceps', 'record_type': 'reps'},
      {'name': 'Incline Dumbbell Curl', 'body_part': 'biceps', 'record_type': 'reps'},
      {'name': 'Barbell Curl', 'body_part': 'biceps', 'record_type': 'reps'},
      {'name': 'Hammer Curl', 'body_part': 'biceps', 'record_type': 'reps'},
      {'name': 'Preacher Curl', 'body_part': 'biceps', 'record_type': 'reps'},
      // Triceps
      {'name': 'Triceps Pushdown', 'body_part': 'triceps', 'record_type': 'reps'},
      {'name': 'Skull Crusher', 'body_part': 'triceps', 'record_type': 'reps'},
      {'name': 'French Press', 'body_part': 'triceps', 'record_type': 'reps'},
      {'name': 'Dips', 'body_part': 'triceps', 'record_type': 'reps'},
      {'name': 'Overhead Triceps Extension', 'body_part': 'triceps', 'record_type': 'reps'},
      // Abs
      {'name': 'Sit-Up', 'body_part': 'abs', 'record_type': 'reps'},
      {'name': 'Crunch', 'body_part': 'abs', 'record_type': 'reps'},
      {'name': 'Leg Raise', 'body_part': 'abs', 'record_type': 'reps'},
      {'name': 'Plank', 'body_part': 'abs', 'record_type': 'time'},
      {'name': 'Russian Twist', 'body_part': 'abs', 'record_type': 'reps'},
      // Cardio
      {'name': 'Running', 'body_part': 'cardio', 'record_type': 'cardio'},
      {'name': 'Walking', 'body_part': 'cardio', 'record_type': 'cardio'},
      {'name': 'Cycling', 'body_part': 'cardio', 'record_type': 'cardio'},
      {'name': 'Stationary Bike', 'body_part': 'cardio', 'record_type': 'cardio'},
      {'name': 'Treadmill', 'body_part': 'cardio', 'record_type': 'cardio'},
    ];

    for (final exercise in standardExercises) {
      await db.insert('exercise_master', {
        'name': exercise['name'],
        'body_part': exercise['body_part'],
        'is_custom': 0,
        'record_type': exercise['record_type'],
        'created_at': now,
        'updated_at': now,
      });
    }
  }

  /// Handle database upgrade
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Migration from version 1 to 2: Add dual unit support
      await _migrateToVersion2(db);
    }
    if (oldVersion < 3) {
      // Migration from version 2 to 3: Add memo field and update body parts
      await _migrateToVersion3(db);
    }
    if (oldVersion < 4) {
      // Migration from version 3 to 4: Add record_type and duration_seconds
      await _migrateToVersion4(db);
    }
    if (oldVersion < 5) {
      // Migration from version 4 to 5: Add cardio support (distance_meters, distance_unit)
      await _migrateToVersion5(db);
    }
    if (oldVersion < 6) {
      // Migration from version 5 to 6: Add entitlement and theme_settings for Pro/Free plan
      await _migrateToVersion6(db);
    }
    if (oldVersion < 7) {
      // Migration from version 6 to 7: Add setup_completed flag
      await _migrateToVersion7(db);
    }
    if (oldVersion < 8) {
      // Migration from version 7 to 8: Add new standard exercises from StandardExercise.md
      await _migrateToVersion8(db);
    }
    if (oldVersion < 9) {
      // Migration from version 8 to 9: Add tutorial_completed flag
      await _migrateToVersion9(db);
    }
  }

  /// Migrate to version 2 (dual unit support)
  Future<void> _migrateToVersion2(Database db) async {
    // Create new set_records table with dual unit columns
    await db.execute('''
      CREATE TABLE set_records_new (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        workout_exercise_id INTEGER NOT NULL,
        session_id INTEGER NOT NULL,
        exercise_id INTEGER NOT NULL,
        set_number INTEGER NOT NULL,
        weight_kg REAL NOT NULL,
        weight_lb REAL NOT NULL,
        reps INTEGER NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        FOREIGN KEY (workout_exercise_id) REFERENCES workout_exercises(id) ON DELETE CASCADE
      )
    ''');

    // Copy and convert data from old table
    final oldRecords = await db.query('set_records');
    for (final record in oldRecords) {
      final weight = (record['weight'] as num).toDouble();
      final unit = record['unit'] as String;

      // Calculate both kg and lb values
      double weightKg;
      double weightLb;

      if (unit == 'kg') {
        weightKg = weight;
        weightLb = weight * 2.20462;
      } else {
        // unit == 'lb'
        weightLb = weight;
        weightKg = weight / 2.20462;
      }

      await db.insert('set_records_new', {
        'id': record['id'],
        'workout_exercise_id': record['workout_exercise_id'],
        'session_id': record['session_id'],
        'exercise_id': record['exercise_id'],
        'set_number': record['set_number'],
        'weight_kg': weightKg,
        'weight_lb': weightLb,
        'reps': record['reps'],
        'created_at': record['created_at'],
        'updated_at': record['updated_at'],
      });
    }

    // Drop old table
    await db.execute('DROP TABLE set_records');

    // Rename new table
    await db.execute('ALTER TABLE set_records_new RENAME TO set_records');

    // Recreate indices
    await db.execute('''
      CREATE INDEX idx_set_records_workout_exercise_id_set_number
        ON set_records(workout_exercise_id, set_number)
    ''');

    await db.execute('''
      CREATE INDEX idx_set_records_exercise_id_session_id
        ON set_records(exercise_id, session_id)
    ''');
  }

  /// Migrate to version 3 (add memo field and update body parts)
  Future<void> _migrateToVersion3(Database db) async {
    // 1. Add memo column to workout_exercises table
    await db.execute('''
      ALTER TABLE workout_exercises ADD COLUMN memo TEXT
    ''');

    // 2. Update body_part for existing exercises from 'arms' to specific muscle groups
    // Update Barbell Curl to biceps
    await db.execute('''
      UPDATE exercise_master
      SET body_part = 'biceps'
      WHERE name = 'Barbell Curl' AND is_custom = 0
    ''');

    // Update Tricep Extension to triceps
    await db.execute('''
      UPDATE exercise_master
      SET body_part = 'triceps'
      WHERE name = 'Tricep Extension' AND is_custom = 0
    ''');

    // For any custom exercises with 'arms', set to 'other' as we can't automatically determine
    await db.execute('''
      UPDATE exercise_master
      SET body_part = 'other'
      WHERE body_part = 'arms' AND is_custom = 1
    ''');
  }

  /// Migrate to version 4 (add record_type to exercise_master and duration_seconds to set_records)
  Future<void> _migrateToVersion4(Database db) async {
    // 1. Add record_type column to exercise_master table
    await db.execute('''
      ALTER TABLE exercise_master ADD COLUMN record_type TEXT NOT NULL DEFAULT 'reps'
    ''');

    // 2. Add duration_seconds column to set_records table
    await db.execute('''
      ALTER TABLE set_records ADD COLUMN duration_seconds INTEGER
    ''');

    // 3. Update standard time-based exercises to 'time' record_type
    final timeBasedExercises = ['Plank', 'Side Plank', 'Wall Sit', 'Dead Hang'];
    for (final exerciseName in timeBasedExercises) {
      await db.execute('''
        UPDATE exercise_master
        SET record_type = 'time'
        WHERE name = ? AND is_custom = 0
      ''', [exerciseName]);
    }
  }

  /// Migrate to version 5 (add cardio support)
  Future<void> _migrateToVersion5(Database db) async {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    // 1. Add distance_unit column to settings table
    await db.execute('''
      ALTER TABLE settings ADD COLUMN distance_unit TEXT NOT NULL DEFAULT 'km'
    ''');

    // 2. Add distance_meters column to set_records table
    await db.execute('''
      ALTER TABLE set_records ADD COLUMN distance_meters REAL
    ''');

    // 3. Insert standard cardio exercises
    final cardioExercises = [
      {'name': 'Running', 'body_part': 'cardio', 'record_type': 'cardio'},
      {'name': 'Walking', 'body_part': 'cardio', 'record_type': 'cardio'},
      {'name': 'Cycling', 'body_part': 'cardio', 'record_type': 'cardio'},
      {'name': 'Rowing', 'body_part': 'cardio', 'record_type': 'cardio'},
      {'name': 'Jump Rope', 'body_part': 'cardio', 'record_type': 'cardio'},
      {'name': 'Swimming', 'body_part': 'cardio', 'record_type': 'cardio'},
      {'name': 'Elliptical', 'body_part': 'cardio', 'record_type': 'cardio'},
    ];

    for (final exercise in cardioExercises) {
      await db.insert('exercise_master', {
        'name': exercise['name'],
        'body_part': exercise['body_part'],
        'is_custom': 0,
        'record_type': exercise['record_type'],
        'created_at': now,
        'updated_at': now,
      });
    }
  }

  /// Migrate to version 6 (add entitlement and theme_settings for Pro/Free plan)
  Future<void> _migrateToVersion6(Database db) async {
    // 1. Add entitlement column to settings table
    await db.execute('''
      ALTER TABLE settings ADD COLUMN entitlement TEXT NOT NULL DEFAULT 'free'
    ''');

    // 2. Add theme_settings column to settings table
    await db.execute('''
      ALTER TABLE settings ADD COLUMN theme_settings TEXT
    ''');
  }

  /// Migrate to version 7 (add setup_completed flag)
  Future<void> _migrateToVersion7(Database db) async {
    // Add setup_completed column with default value 1 for existing users
    // (they have already used the app, so skip the initial setup)
    await db.execute('''
      ALTER TABLE settings ADD COLUMN setup_completed INTEGER NOT NULL DEFAULT 1
    ''');
  }

  /// Migrate to version 9 (add tutorial_completed flag)
  Future<void> _migrateToVersion9(Database db) async {
    // Add tutorial_completed column with default value 0 for existing users
    // (they need to complete the interactive tutorial)
    await db.execute('''
      ALTER TABLE settings ADD COLUMN tutorial_completed INTEGER NOT NULL DEFAULT 0
    ''');
  }

  /// Migrate to version 8 (add new standard exercises from StandardExercise.md)
  Future<void> _migrateToVersion8(Database db) async {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    // New exercises to add (only add if they don't exist)
    final newExercises = [
      // Chest
      {'name': 'Dumbbell Bench Press', 'body_part': 'chest', 'record_type': 'reps'},
      {'name': 'Incline Dumbbell Bench Press', 'body_part': 'chest', 'record_type': 'reps'},
      {'name': 'Smith Press', 'body_part': 'chest', 'record_type': 'reps'},
      {'name': 'Incline Smith Press', 'body_part': 'chest', 'record_type': 'reps'},
      {'name': 'Dumbbell Fly', 'body_part': 'chest', 'record_type': 'reps'},
      {'name': 'Incline Dumbbell Fly', 'body_part': 'chest', 'record_type': 'reps'},
      {'name': 'Cable Fly', 'body_part': 'chest', 'record_type': 'reps'},
      {'name': 'Push-Up', 'body_part': 'chest', 'record_type': 'reps'},
      // Back
      {'name': 'Pull-Up', 'body_part': 'back', 'record_type': 'reps'},
      {'name': 'Lat Pulldown', 'body_part': 'back', 'record_type': 'reps'},
      {'name': 'Dumbbell Row', 'body_part': 'back', 'record_type': 'reps'},
      {'name': 'Seated Row', 'body_part': 'back', 'record_type': 'reps'},
      // Legs
      {'name': 'Leg Extension', 'body_part': 'legs', 'record_type': 'reps'},
      {'name': 'Leg Curl', 'body_part': 'legs', 'record_type': 'reps'},
      {'name': 'Lunge', 'body_part': 'legs', 'record_type': 'reps'},
      {'name': 'Calf Raise', 'body_part': 'legs', 'record_type': 'reps'},
      // Shoulders
      {'name': 'Smith Shoulder Press', 'body_part': 'shoulders', 'record_type': 'reps'},
      {'name': 'Dumbbell Shoulder Press', 'body_part': 'shoulders', 'record_type': 'reps'},
      {'name': 'Incline Lateral Raise', 'body_part': 'shoulders', 'record_type': 'reps'},
      {'name': 'Front Raise', 'body_part': 'shoulders', 'record_type': 'reps'},
      {'name': 'Rear Delt Raise', 'body_part': 'shoulders', 'record_type': 'reps'},
      {'name': 'Arnold Press', 'body_part': 'shoulders', 'record_type': 'reps'},
      // Biceps
      {'name': 'Biceps Curl', 'body_part': 'biceps', 'record_type': 'reps'},
      {'name': 'Dumbbell Curl', 'body_part': 'biceps', 'record_type': 'reps'},
      {'name': 'Incline Dumbbell Curl', 'body_part': 'biceps', 'record_type': 'reps'},
      {'name': 'Hammer Curl', 'body_part': 'biceps', 'record_type': 'reps'},
      {'name': 'Preacher Curl', 'body_part': 'biceps', 'record_type': 'reps'},
      // Triceps
      {'name': 'Triceps Pushdown', 'body_part': 'triceps', 'record_type': 'reps'},
      {'name': 'Skull Crusher', 'body_part': 'triceps', 'record_type': 'reps'},
      {'name': 'French Press', 'body_part': 'triceps', 'record_type': 'reps'},
      {'name': 'Dips', 'body_part': 'triceps', 'record_type': 'reps'},
      {'name': 'Overhead Triceps Extension', 'body_part': 'triceps', 'record_type': 'reps'},
      // Abs
      {'name': 'Sit-Up', 'body_part': 'abs', 'record_type': 'reps'},
      {'name': 'Crunch', 'body_part': 'abs', 'record_type': 'reps'},
      {'name': 'Leg Raise', 'body_part': 'abs', 'record_type': 'reps'},
      {'name': 'Plank', 'body_part': 'abs', 'record_type': 'time'},
      {'name': 'Russian Twist', 'body_part': 'abs', 'record_type': 'reps'},
      // Cardio
      {'name': 'Stationary Bike', 'body_part': 'cardio', 'record_type': 'cardio'},
      {'name': 'Treadmill', 'body_part': 'cardio', 'record_type': 'cardio'},
    ];

    for (final exercise in newExercises) {
      // Check if exercise already exists
      final existing = await db.query(
        'exercise_master',
        where: 'name = ? AND is_custom = 0',
        whereArgs: [exercise['name']],
      );

      if (existing.isEmpty) {
        await db.insert('exercise_master', {
          'name': exercise['name'],
          'body_part': exercise['body_part'],
          'is_custom': 0,
          'record_type': exercise['record_type'],
          'created_at': now,
          'updated_at': now,
        });
      }
    }
  }

  /// Close database
  Future<void> close() async {
    final db = await instance.database;
    await db.close();
  }

  /// Reopen database connection
  /// ファイルピッカー使用後にreadonly状態になった場合に呼び出す
  Future<void> reopenDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
    _database = await _initDB('fitness_log.db');
  }

  /// Delete database (for testing)
  Future<void> deleteDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'fitness_log.db');
    await deleteDatabase(path);
    _database = null;
  }
}
