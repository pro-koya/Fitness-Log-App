/// Routine exercise entity for exercises within a routine template
class RoutineExerciseEntity {
  final int? id;
  final int routineId; // routine_templates.id
  final int exerciseId; // exercise_master.id
  final int orderIndex; // Display order within routine (0, 1, 2, ...)
  final int createdAt; // UNIX timestamp
  final int updatedAt; // UNIX timestamp

  const RoutineExerciseEntity({
    this.id,
    required this.routineId,
    required this.exerciseId,
    required this.orderIndex,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create from database map
  factory RoutineExerciseEntity.fromMap(Map<String, dynamic> map) {
    return RoutineExerciseEntity(
      id: map['id'] as int?,
      routineId: map['routine_id'] as int,
      exerciseId: map['exercise_id'] as int,
      orderIndex: map['order_index'] as int,
      createdAt: map['created_at'] as int,
      updatedAt: map['updated_at'] as int,
    );
  }

  /// Convert to database map
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'routine_id': routineId,
      'exercise_id': exerciseId,
      'order_index': orderIndex,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  /// Copy with new values
  RoutineExerciseEntity copyWith({
    int? id,
    int? routineId,
    int? exerciseId,
    int? orderIndex,
    int? createdAt,
    int? updatedAt,
  }) {
    return RoutineExerciseEntity(
      id: id ?? this.id,
      routineId: routineId ?? this.routineId,
      exerciseId: exerciseId ?? this.exerciseId,
      orderIndex: orderIndex ?? this.orderIndex,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'RoutineExerciseEntity(id: $id, routineId: $routineId, exerciseId: $exerciseId, orderIndex: $orderIndex, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is RoutineExerciseEntity &&
        other.id == id &&
        other.routineId == routineId &&
        other.exerciseId == exerciseId &&
        other.orderIndex == orderIndex &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        routineId.hashCode ^
        exerciseId.hashCode ^
        orderIndex.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode;
  }
}
