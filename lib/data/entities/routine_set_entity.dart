/// Routine set entity for target sets within a routine exercise
class RoutineSetEntity {
  final int? id;
  final int routineExerciseId; // routine_exercises.id
  final int setNumber; // Set number (1, 2, 3, ...)
  final double weightKg; // Target weight in kg
  final double weightLb; // Target weight in lb
  final int? reps; // Target repetitions (null for time-based exercises)
  final int? durationSeconds; // Target duration in seconds (for time-based and cardio)
  final double? distanceMeters; // Target distance in meters (for cardio)
  final int createdAt; // UNIX timestamp
  final int updatedAt; // UNIX timestamp

  const RoutineSetEntity({
    this.id,
    required this.routineExerciseId,
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
      return distanceMeters! / 1609.344;
    }
  }

  /// Create from database map
  factory RoutineSetEntity.fromMap(Map<String, dynamic> map) {
    return RoutineSetEntity(
      id: map['id'] as int?,
      routineExerciseId: map['routine_exercise_id'] as int,
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
      'routine_exercise_id': routineExerciseId,
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
  RoutineSetEntity copyWith({
    int? id,
    int? routineExerciseId,
    int? setNumber,
    double? weightKg,
    double? weightLb,
    int? reps,
    int? durationSeconds,
    double? distanceMeters,
    int? createdAt,
    int? updatedAt,
  }) {
    return RoutineSetEntity(
      id: id ?? this.id,
      routineExerciseId: routineExerciseId ?? this.routineExerciseId,
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
    return 'RoutineSetEntity(id: $id, routineExerciseId: $routineExerciseId, setNumber: $setNumber, weightKg: $weightKg, weightLb: $weightLb, reps: $reps, durationSeconds: $durationSeconds, distanceMeters: $distanceMeters, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is RoutineSetEntity &&
        other.id == id &&
        other.routineExerciseId == routineExerciseId &&
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
        routineExerciseId.hashCode ^
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
