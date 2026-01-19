/// Workout exercise entity for exercises within a session
class WorkoutExerciseEntity {
  final int? id;
  final int sessionId; // workout_sessions.id
  final int exerciseId; // exercise_master.id
  final int orderIndex; // Display order within session (0, 1, 2, ...)
  final String? memo; // Memo for this exercise
  final int createdAt; // UNIX timestamp
  final int updatedAt; // UNIX timestamp

  const WorkoutExerciseEntity({
    this.id,
    required this.sessionId,
    required this.exerciseId,
    required this.orderIndex,
    this.memo,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create from database map
  factory WorkoutExerciseEntity.fromMap(Map<String, dynamic> map) {
    return WorkoutExerciseEntity(
      id: map['id'] as int?,
      sessionId: map['session_id'] as int,
      exerciseId: map['exercise_id'] as int,
      orderIndex: map['order_index'] as int,
      memo: map['memo'] as String?,
      createdAt: map['created_at'] as int,
      updatedAt: map['updated_at'] as int,
    );
  }

  /// Convert to database map
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'session_id': sessionId,
      'exercise_id': exerciseId,
      'order_index': orderIndex,
      'memo': memo,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  /// Copy with new values
  WorkoutExerciseEntity copyWith({
    int? id,
    int? sessionId,
    int? exerciseId,
    int? orderIndex,
    String? memo,
    int? createdAt,
    int? updatedAt,
  }) {
    return WorkoutExerciseEntity(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      exerciseId: exerciseId ?? this.exerciseId,
      orderIndex: orderIndex ?? this.orderIndex,
      memo: memo ?? this.memo,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'WorkoutExerciseEntity(id: $id, sessionId: $sessionId, exerciseId: $exerciseId, orderIndex: $orderIndex, memo: $memo, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is WorkoutExerciseEntity &&
        other.id == id &&
        other.sessionId == sessionId &&
        other.exerciseId == exerciseId &&
        other.orderIndex == orderIndex &&
        other.memo == memo &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        sessionId.hashCode ^
        exerciseId.hashCode ^
        orderIndex.hashCode ^
        memo.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode;
  }
}
