import '../../../data/entities/exercise_master_entity.dart';
import '../../../data/entities/routine_set_entity.dart';

/// Full routine with exercises and their target sets
class RoutineModel {
  final int? id;
  final String name;
  final List<RoutineExerciseModel> exercises;
  final int createdAt;
  final int updatedAt;

  RoutineModel({
    this.id,
    required this.name,
    required this.exercises,
    required this.createdAt,
    required this.updatedAt,
  });

  RoutineModel copyWith({
    int? id,
    String? name,
    List<RoutineExerciseModel>? exercises,
    int? createdAt,
    int? updatedAt,
  }) {
    return RoutineModel(
      id: id ?? this.id,
      name: name ?? this.name,
      exercises: exercises ?? this.exercises,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Exercise within a routine with its target sets
class RoutineExerciseModel {
  final int? routineExerciseId;
  final ExerciseMasterEntity exercise;
  final List<RoutineSetModel> targetSets;
  final int orderIndex;

  RoutineExerciseModel({
    this.routineExerciseId,
    required this.exercise,
    required this.targetSets,
    required this.orderIndex,
  });

  RoutineExerciseModel copyWith({
    int? routineExerciseId,
    ExerciseMasterEntity? exercise,
    List<RoutineSetModel>? targetSets,
    int? orderIndex,
  }) {
    return RoutineExerciseModel(
      routineExerciseId: routineExerciseId ?? this.routineExerciseId,
      exercise: exercise ?? this.exercise,
      targetSets: targetSets ?? this.targetSets,
      orderIndex: orderIndex ?? this.orderIndex,
    );
  }
}

/// Target set within a routine exercise
class RoutineSetModel {
  final int setNumber;
  final double? weight; // in current user unit
  final int? reps;
  final int? durationSeconds;
  final double? distance; // in current distance unit
  final String unit; // 'kg' or 'lb'
  final String distanceUnit; // 'km' or 'mile'
  final String recordType; // 'reps', 'time', or 'cardio'

  RoutineSetModel({
    required this.setNumber,
    this.weight,
    this.reps,
    this.durationSeconds,
    this.distance,
    required this.unit,
    this.distanceUnit = 'km',
    this.recordType = 'reps',
  });

  RoutineSetModel copyWith({
    int? setNumber,
    double? weight,
    int? reps,
    int? durationSeconds,
    double? distance,
    String? unit,
    String? distanceUnit,
    String? recordType,
  }) {
    return RoutineSetModel(
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

  /// Create from RoutineSetEntity with unit conversion
  factory RoutineSetModel.fromEntity(
    RoutineSetEntity entity, {
    required String unit,
    required String distanceUnit,
    required String recordType,
  }) {
    return RoutineSetModel(
      setNumber: entity.setNumber,
      weight: entity.getWeight(unit),
      reps: entity.reps,
      durationSeconds: entity.durationSeconds,
      distance: entity.getDistance(distanceUnit),
      unit: unit,
      distanceUnit: distanceUnit,
      recordType: recordType,
    );
  }

  /// Convert to RoutineSetEntity for database
  RoutineSetEntity toEntity({required int routineExerciseId}) {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final weightValue = weight ?? 0.0;

    final weightKg = unit == 'kg' ? weightValue : weightValue / 2.20462;
    final weightLb = unit == 'lb' ? weightValue : weightValue * 2.20462;

    double? distanceMeters;
    if (recordType == 'cardio' && distance != null) {
      if (distanceUnit == 'km') {
        distanceMeters = distance! * 1000.0;
      } else {
        distanceMeters = distance! * 1609.344;
      }
    }

    return RoutineSetEntity(
      routineExerciseId: routineExerciseId,
      setNumber: setNumber,
      weightKg: weightKg,
      weightLb: weightLb,
      reps: recordType == 'reps' ? reps : (recordType == 'time' || recordType == 'cardio' ? 0 : reps),
      durationSeconds: (recordType == 'time' || recordType == 'cardio') ? durationSeconds : null,
      distanceMeters: distanceMeters,
      createdAt: now,
      updatedAt: now,
    );
  }
}
