/// Set record entity for individual sets (with dual unit support)
class SetRecordEntity {
  final int? id;
  final int workoutExerciseId; // workout_exercises.id
  final int sessionId; // workout_sessions.id (denormalized for performance)
  final int exerciseId; // exercise_master.id (denormalized for performance)
  final int setNumber; // Set number (1, 2, 3, ...)
  final double weightKg; // Weight in kg
  final double weightLb; // Weight in lb
  final int? reps; // Repetitions (null for time-based exercises)
  final int? durationSeconds; // Duration in seconds (for time-based and cardio exercises)
  final double? distanceMeters; // Distance in meters (for cardio exercises)
  final int createdAt; // UNIX timestamp
  final int updatedAt; // UNIX timestamp

  const SetRecordEntity({
    this.id,
    required this.workoutExerciseId,
    required this.sessionId,
    required this.exerciseId,
    required this.setNumber,
    required this.weightKg,
    required this.weightLb,
    this.reps,
    this.durationSeconds,
    this.distanceMeters,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Get weight in specified unit
  double getWeight(String unit) {
    return unit == 'kg' ? weightKg : weightLb;
  }

  /// Get distance in specified unit (km or mile)
  double? getDistance(String distanceUnit) {
    if (distanceMeters == null) return null;
    if (distanceUnit == 'km') {
      return distanceMeters! / 1000.0;
    } else {
      // Convert meters to miles (1 mile = 1609.344 meters)
      return distanceMeters! / 1609.344;
    }
  }

  /// Convenience getter for backward compatibility (returns kg)
  double get weight => weightKg;

  /// Convenience getter for backward compatibility (returns 'kg')
  String get unit => 'kg';

  /// Create from database map
  factory SetRecordEntity.fromMap(Map<String, dynamic> map) {
    return SetRecordEntity(
      id: map['id'] as int?,
      workoutExerciseId: map['workout_exercise_id'] as int,
      sessionId: map['session_id'] as int,
      exerciseId: map['exercise_id'] as int,
      setNumber: map['set_number'] as int,
      weightKg: (map['weight_kg'] as num).toDouble(),
      weightLb: (map['weight_lb'] as num).toDouble(),
      reps: map['reps'] as int?,
      durationSeconds: map['duration_seconds'] as int?,
      distanceMeters: map['distance_meters'] != null
          ? (map['distance_meters'] as num).toDouble()
          : null,
      createdAt: map['created_at'] as int,
      updatedAt: map['updated_at'] as int,
    );
  }

  /// Convert to database map
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'workout_exercise_id': workoutExerciseId,
      'session_id': sessionId,
      'exercise_id': exerciseId,
      'set_number': setNumber,
      'weight_kg': weightKg,
      'weight_lb': weightLb,
      'reps': reps,
      'duration_seconds': durationSeconds,
      'distance_meters': distanceMeters,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  /// Copy with new values
  SetRecordEntity copyWith({
    int? id,
    int? workoutExerciseId,
    int? sessionId,
    int? exerciseId,
    int? setNumber,
    double? weightKg,
    double? weightLb,
    int? reps,
    int? durationSeconds,
    double? distanceMeters,
    int? createdAt,
    int? updatedAt,
  }) {
    return SetRecordEntity(
      id: id ?? this.id,
      workoutExerciseId: workoutExerciseId ?? this.workoutExerciseId,
      sessionId: sessionId ?? this.sessionId,
      exerciseId: exerciseId ?? this.exerciseId,
      setNumber: setNumber ?? this.setNumber,
      weightKg: weightKg ?? this.weightKg,
      weightLb: weightLb ?? this.weightLb,
      reps: reps ?? this.reps,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'SetRecordEntity(id: $id, workoutExerciseId: $workoutExerciseId, sessionId: $sessionId, exerciseId: $exerciseId, setNumber: $setNumber, weightKg: $weightKg, weightLb: $weightLb, reps: $reps, durationSeconds: $durationSeconds, distanceMeters: $distanceMeters, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is SetRecordEntity &&
        other.id == id &&
        other.workoutExerciseId == workoutExerciseId &&
        other.sessionId == sessionId &&
        other.exerciseId == exerciseId &&
        other.setNumber == setNumber &&
        other.weightKg == weightKg &&
        other.weightLb == weightLb &&
        other.reps == reps &&
        other.durationSeconds == durationSeconds &&
        other.distanceMeters == distanceMeters &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        workoutExerciseId.hashCode ^
        sessionId.hashCode ^
        exerciseId.hashCode ^
        setNumber.hashCode ^
        weightKg.hashCode ^
        weightLb.hashCode ^
        reps.hashCode ^
        durationSeconds.hashCode ^
        distanceMeters.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode;
  }
}
