/// Entity for per-exercise goals (Pro feature).
/// goal_type: weight (kg), reps, volume (kg*reps), time (seconds), distance (meters).
/// priority: 1=low, 2=medium, 3=high (重要度).
class ExerciseGoalEntity {
  final int? id;
  final int exerciseId;
  final String goalType; // 'weight' | 'reps' | 'volume' | 'time' | 'distance'
  final double goalValue;
  final int? deadlineTs; // UNIX seconds, optional
  /// 1=low, 2=medium, 3=high
  final int priority;
  final int createdAt;
  final int updatedAt;

  const ExerciseGoalEntity({
    this.id,
    required this.exerciseId,
    required this.goalType,
    required this.goalValue,
    this.deadlineTs,
    this.priority = 2,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ExerciseGoalEntity.fromMap(Map<String, dynamic> map) {
    return ExerciseGoalEntity(
      id: map['id'] as int?,
      exerciseId: map['exercise_id'] as int,
      goalType: map['goal_type'] as String,
      goalValue: (map['goal_value'] as num).toDouble(),
      deadlineTs: map['deadline_ts'] as int?,
      priority: (map['priority'] as int?) ?? 2,
      createdAt: map['created_at'] as int,
      updatedAt: map['updated_at'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'exercise_id': exerciseId,
      'goal_type': goalType,
      'goal_value': goalValue,
      'deadline_ts': deadlineTs,
      'priority': priority,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
