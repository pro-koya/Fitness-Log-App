/// One achieved goal for display (localize exercise name in UI)
class GoalAchievedDisplay {
  final String exerciseNameEn;
  final String valueStr;
  final bool isStandard;

  const GoalAchievedDisplay({
    required this.exerciseNameEn,
    required this.valueStr,
    required this.isStandard,
  });
}

/// Result model for workout completion screen (Proposal 1)
class WorkoutCompletionResult {
  final int sessionId;
  final int exerciseCount;
  final int setCount;
  final double totalVolume;
  final String message;
  final int streak;
  final int weeklyCount;
  final String unit;
  final List<ExerciseSummaryItem> exerciseDetails;
  final List<GoalAchievedDisplay> achievedGoals;

  const WorkoutCompletionResult({
    required this.sessionId,
    required this.exerciseCount,
    required this.setCount,
    required this.totalVolume,
    required this.message,
    required this.streak,
    required this.weeklyCount,
    required this.unit,
    required this.exerciseDetails,
    this.achievedGoals = const [],
  });
}

/// Per-exercise summary for completion modal
class ExerciseSummaryItem {
  final String name;
  final int setCount;
  final double? topWeight;
  final int? topDurationSeconds;
  final bool isTimeBased;

  const ExerciseSummaryItem({
    required this.name,
    required this.setCount,
    this.topWeight,
    this.topDurationSeconds,
    this.isTimeBased = false,
  });
}
