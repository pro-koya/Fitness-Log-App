// Liftly インポート用の中間モデル
// KintoreMemo Realm → このモデル → Liftly DB

class LiftlyWorkoutImport {
  final DateTime workoutDate;
  final String exerciseName;
  final String? bodyPart;
  final List<LiftlySetEntry> sets;
  final String? note;

  const LiftlyWorkoutImport({
    required this.workoutDate,
    required this.exerciseName,
    this.bodyPart,
    required this.sets,
    this.note,
  });
}

class LiftlySetEntry {
  final double? weightKg;
  final int? reps;
  final String? memo;

  const LiftlySetEntry({
    this.weightKg,
    this.reps,
    this.memo,
  });
}
