import '../../../data/entities/exercise_master_entity.dart';
import '../../../data/entities/workout_exercise_entity.dart';
import '../../../data/entities/set_record_entity.dart';

/// Model for workout exercise with sets and previous records
class WorkoutExerciseModel {
  final int? workoutExerciseId; // workout_exercises.id
  final ExerciseMasterEntity exercise; // Exercise master data
  final List<SetRecordModel> sets; // Current sets
  final List<SetRecordEntity> previousSets; // Previous session sets
  final String? memo; // Memo for this exercise

  WorkoutExerciseModel({
    this.workoutExerciseId,
    required this.exercise,
    required this.sets,
    this.previousSets = const [],
    this.memo,
  });

  WorkoutExerciseModel copyWith({
    int? workoutExerciseId,
    ExerciseMasterEntity? exercise,
    List<SetRecordModel>? sets,
    List<SetRecordEntity>? previousSets,
    String? memo,
  }) {
    return WorkoutExerciseModel(
      workoutExerciseId: workoutExerciseId ?? this.workoutExerciseId,
      exercise: exercise ?? this.exercise,
      sets: sets ?? this.sets,
      previousSets: previousSets ?? this.previousSets,
      memo: memo ?? this.memo,
    );
  }
}

/// Model for set record (for editing)
class SetRecordModel {
  final int? id; // set_records.id (null if not saved yet)
  final int setNumber;
  final double? weight;
  final int? reps;
  final int? durationSeconds; // For time-based and cardio exercises
  final double? distance; // For cardio exercises (in current distance unit)
  final String unit; // Weight unit: 'kg' or 'lb'
  final String distanceUnit; // Distance unit: 'km' or 'mile'
  final String recordType; // 'reps', 'time', or 'cardio'

  SetRecordModel({
    this.id,
    required this.setNumber,
    this.weight,
    this.reps,
    this.durationSeconds,
    this.distance,
    required this.unit,
    this.distanceUnit = 'km',
    this.recordType = 'reps',
  });

  SetRecordModel copyWith({
    int? id,
    int? setNumber,
    double? weight,
    int? reps,
    int? durationSeconds,
    double? distance,
    String? unit,
    String? distanceUnit,
    String? recordType,
  }) {
    return SetRecordModel(
      id: id ?? this.id,
      setNumber: setNumber ?? this.setNumber,
      weight: weight ?? this.weight,
      reps: reps ?? this.reps,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      distance: distance ?? this.distance,
      unit: unit ?? this.unit,
      distanceUnit: distanceUnit ?? this.distanceUnit,
      recordType: recordType ?? this.recordType,
    );
  }

  /// Convert to SetRecordEntity for database
  SetRecordEntity toEntity({
    required int workoutExerciseId,
    required int sessionId,
    required int exerciseId,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final weightValue = weight ?? 0.0;

    // Calculate both kg and lb values
    final weightKg = unit == 'kg' ? weightValue : weightValue / 2.20462;
    final weightLb = unit == 'lb' ? weightValue : weightValue * 2.20462;

    // Calculate distance in meters for storage
    double? distanceMeters;
    if (recordType == 'cardio' && distance != null) {
      if (distanceUnit == 'km') {
        distanceMeters = distance! * 1000.0;
      } else {
        // Convert miles to meters (1 mile = 1609.344 meters)
        distanceMeters = distance! * 1609.344;
      }
    }

    return SetRecordEntity(
      id: id,
      workoutExerciseId: workoutExerciseId,
      sessionId: sessionId,
      exerciseId: exerciseId,
      setNumber: setNumber,
      weightKg: weightKg,
      weightLb: weightLb,
      // NOTE: Older DBs migrated from v2 had `reps INTEGER NOT NULL`.
      // To keep backward compatibility, store 0 for time-based/cardio sets.
      reps: recordType == 'reps' ? reps : 0,
      durationSeconds: (recordType == 'time' || recordType == 'cardio') ? durationSeconds : null,
      distanceMeters: distanceMeters,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Check if this set has valid data
  /// weight >= 0 allows bodyweight exercises (0kg)
  bool get isValid {
    if (recordType == 'time') {
      // Weight is optional for time-based exercises (e.g., plank without added weight).
      if (weight != null && weight! < 0) return false;
      return durationSeconds != null && durationSeconds! > 0;
    } else if (recordType == 'cardio') {
      // For cardio: time is required, distance is optional
      return durationSeconds != null && durationSeconds! > 0;
    } else {
      if (weight == null || weight! < 0) return false;
      return reps != null && reps! > 0;
    }
  }
}
