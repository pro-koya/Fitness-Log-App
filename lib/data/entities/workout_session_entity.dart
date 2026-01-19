/// Workout session entity for training sessions
class WorkoutSessionEntity {
  final int? id;
  final String status; // 'in_progress' or 'completed'
  final int startedAt; // UNIX timestamp (session start time)
  final int? completedAt; // UNIX timestamp (session completion time, only for completed)
  final int createdAt; // UNIX timestamp
  final int updatedAt; // UNIX timestamp

  const WorkoutSessionEntity({
    this.id,
    required this.status,
    required this.startedAt,
    this.completedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create from database map
  factory WorkoutSessionEntity.fromMap(Map<String, dynamic> map) {
    return WorkoutSessionEntity(
      id: map['id'] as int?,
      status: map['status'] as String,
      startedAt: map['started_at'] as int,
      completedAt: map['completed_at'] as int?,
      createdAt: map['created_at'] as int,
      updatedAt: map['updated_at'] as int,
    );
  }

  /// Convert to database map
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'status': status,
      'started_at': startedAt,
      'completed_at': completedAt,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  /// Copy with new values
  WorkoutSessionEntity copyWith({
    int? id,
    String? status,
    int? startedAt,
    int? completedAt,
    int? createdAt,
    int? updatedAt,
  }) {
    return WorkoutSessionEntity(
      id: id ?? this.id,
      status: status ?? this.status,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Check if session is in progress
  bool get isInProgress => status == 'in_progress';

  /// Check if session is completed
  bool get isCompleted => status == 'completed';

  @override
  String toString() {
    return 'WorkoutSessionEntity(id: $id, status: $status, startedAt: $startedAt, completedAt: $completedAt, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is WorkoutSessionEntity &&
        other.id == id &&
        other.status == status &&
        other.startedAt == startedAt &&
        other.completedAt == completedAt &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        status.hashCode ^
        startedAt.hashCode ^
        completedAt.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode;
  }
}
