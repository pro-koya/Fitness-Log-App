/// Standard exercise names and seed data for backup restore.
/// Aligns with DatabaseHelper seed so backup import can prefer standard exercises.
class StandardExerciseNames {
  StandardExerciseNames._();

  /// Canonical list: same order and names as DatabaseHelper._insertInitialData seed.
  static const List<Map<String, String>> seedRows = [
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
    {'name': 'Pull-Up', 'body_part': 'back', 'record_type': 'reps'},
    {'name': 'Lat Pulldown', 'body_part': 'back', 'record_type': 'reps'},
    {'name': 'Barbell Row', 'body_part': 'back', 'record_type': 'reps'},
    {'name': 'Dumbbell Row', 'body_part': 'back', 'record_type': 'reps'},
    {'name': 'Seated Row', 'body_part': 'back', 'record_type': 'reps'},
    {'name': 'Deadlift', 'body_part': 'back', 'record_type': 'reps'},
    {'name': 'Squat', 'body_part': 'legs', 'record_type': 'reps'},
    {'name': 'Leg Press', 'body_part': 'legs', 'record_type': 'reps'},
    {'name': 'Leg Extension', 'body_part': 'legs', 'record_type': 'reps'},
    {'name': 'Leg Curl', 'body_part': 'legs', 'record_type': 'reps'},
    {'name': 'Lunge', 'body_part': 'legs', 'record_type': 'reps'},
    {'name': 'Calf Raise', 'body_part': 'legs', 'record_type': 'reps'},
    {'name': 'Shoulder Press', 'body_part': 'shoulders', 'record_type': 'reps'},
    {'name': 'Smith Shoulder Press', 'body_part': 'shoulders', 'record_type': 'reps'},
    {'name': 'Dumbbell Shoulder Press', 'body_part': 'shoulders', 'record_type': 'reps'},
    {'name': 'Lateral Raise', 'body_part': 'shoulders', 'record_type': 'reps'},
    {'name': 'Incline Lateral Raise', 'body_part': 'shoulders', 'record_type': 'reps'},
    {'name': 'Front Raise', 'body_part': 'shoulders', 'record_type': 'reps'},
    {'name': 'Rear Delt Raise', 'body_part': 'shoulders', 'record_type': 'reps'},
    {'name': 'Arnold Press', 'body_part': 'shoulders', 'record_type': 'reps'},
    {'name': 'Biceps Curl', 'body_part': 'biceps', 'record_type': 'reps'},
    {'name': 'Dumbbell Curl', 'body_part': 'biceps', 'record_type': 'reps'},
    {'name': 'Incline Dumbbell Curl', 'body_part': 'biceps', 'record_type': 'reps'},
    {'name': 'Barbell Curl', 'body_part': 'biceps', 'record_type': 'reps'},
    {'name': 'Hammer Curl', 'body_part': 'biceps', 'record_type': 'reps'},
    {'name': 'Preacher Curl', 'body_part': 'biceps', 'record_type': 'reps'},
    {'name': 'Triceps Pushdown', 'body_part': 'triceps', 'record_type': 'reps'},
    {'name': 'Skull Crusher', 'body_part': 'triceps', 'record_type': 'reps'},
    {'name': 'French Press', 'body_part': 'triceps', 'record_type': 'reps'},
    {'name': 'Dips', 'body_part': 'triceps', 'record_type': 'reps'},
    {'name': 'Overhead Triceps Extension', 'body_part': 'triceps', 'record_type': 'reps'},
    {'name': 'Sit-Up', 'body_part': 'abs', 'record_type': 'reps'},
    {'name': 'Crunch', 'body_part': 'abs', 'record_type': 'reps'},
    {'name': 'Leg Raise', 'body_part': 'abs', 'record_type': 'reps'},
    {'name': 'Plank', 'body_part': 'abs', 'record_type': 'time'},
    {'name': 'Russian Twist', 'body_part': 'abs', 'record_type': 'reps'},
    {'name': 'Running', 'body_part': 'cardio', 'record_type': 'cardio'},
    {'name': 'Walking', 'body_part': 'cardio', 'record_type': 'cardio'},
    {'name': 'Cycling', 'body_part': 'cardio', 'record_type': 'cardio'},
    {'name': 'Stationary Bike', 'body_part': 'cardio', 'record_type': 'cardio'},
    {'name': 'Treadmill', 'body_part': 'cardio', 'record_type': 'cardio'},
  ];

  static String _normalize(String name) {
    return name.trim().toLowerCase().replaceAll('-', ' ').replaceAll(RegExp(r'\s+'), ' ');
  }

  /// Normalized canonical names for lookup.
  static final Set<String> _normalizedCanonical = {
    for (final row in seedRows) _normalize(row['name']!),
  };

  /// Aliases (normalized) that map to normalized canonical name. Backup may use legacy names.
  static const Map<String, String> _aliases = {
    'pull up': 'pull up',
    'tricep extension': 'overhead triceps extension',
    'dumbbell press': 'dumbbell bench press',
  };

  /// Returns true if [name] (after normalization) matches a standard exercise or alias.
  static bool isStandardExerciseName(String name) {
    final n = _normalize(name);
    if (_normalizedCanonical.contains(n)) return true;
    return _aliases.containsKey(n);
  }

  /// Returns the canonical standard name for display/insert, or null if not standard.
  /// Used to pick which standard row to use when backup name is an alias.
  static String? canonicalNameForBackup(String backupName) {
    final n = _normalize(backupName);
    if (_normalizedCanonical.contains(n)) {
      for (final row in seedRows) {
        if (_normalize(row['name']!) == n) return row['name'];
      }
    }
    final aliasTarget = _aliases[n];
    if (aliasTarget != null) {
      for (final row in seedRows) {
        if (_normalize(row['name']!) == aliasTarget) return row['name'];
      }
    }
    return null;
  }
}
