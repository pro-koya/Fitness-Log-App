/// Log of a goal achievement (for "今週達成した目標" on home).
class GoalAchievementEntity {
  final int? id;
  final int exerciseId;
  final String exerciseNameEn;
  final String goalType;
  final String goalValueDisplay;
  final int achievedAt;
  final bool isStandard;

  const GoalAchievementEntity({
    this.id,
    required this.exerciseId,
    required this.exerciseNameEn,
    required this.goalType,
    required this.goalValueDisplay,
    required this.achievedAt,
    this.isStandard = true,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'exercise_id': exerciseId,
        'exercise_name_en': exerciseNameEn,
        'goal_type': goalType,
        'goal_value_display': goalValueDisplay,
        'achieved_at': achievedAt,
        'is_standard': isStandard ? 1 : 0,
      };

  static GoalAchievementEntity fromMap(Map<String, dynamic> map) =>
      GoalAchievementEntity(
        id: map['id'] as int?,
        exerciseId: map['exercise_id'] as int,
        exerciseNameEn: map['exercise_name_en'] as String,
        goalType: map['goal_type'] as String,
        goalValueDisplay: map['goal_value_display'] as String,
        achievedAt: map['achieved_at'] as int,
        isStandard: (map['is_standard'] as int?) != 0,
      );
}
