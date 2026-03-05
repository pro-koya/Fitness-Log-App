import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/entities/exercise_goal_entity.dart';
import '../data/entities/exercise_master_entity.dart';
import 'database_providers.dart';

/// One goal with display info for 目標一覧.
class GoalListItem {
  final ExerciseGoalEntity goal;
  final String exerciseNameEn;
  final bool isStandard;
  final double? bestValue;

  const GoalListItem({
    required this.goal,
    required this.exerciseNameEn,
    required this.isStandard,
    this.bestValue,
  });

  /// 達成率 0–100 (null if no target or no best).
  int? get achievementPercent {
    if (goal.goalValue <= 0) return null;
    if (bestValue == null) return 0;
    final p = (bestValue! / goal.goalValue * 100).round();
    return p > 100 ? 100 : p;
  }
}

final allGoalsListProvider = FutureProvider.autoDispose<List<GoalListItem>>((ref) async {
  final goalDao = ref.read(exerciseGoalDaoProvider);
  final exerciseDao = ref.read(exerciseMasterDaoProvider);
  final setRecordDao = ref.read(setRecordDaoProvider);
  final goals = await goalDao.getAll();
  final list = <GoalListItem>[];
  for (final goal in goals) {
    final master = await exerciseDao.getExerciseById(goal.exerciseId);
    // 種目が削除済み・未同期などで存在しない場合はスキップ（カードに表示しない）
    if (master == null) continue;
    final nameEn = master.name;
    final isStandard = master.isCustom == 0;
    final best = await setRecordDao.getBestValueForExercise(goal.exerciseId, goal.goalType);
    list.add(GoalListItem(
      goal: goal,
      exerciseNameEn: nameEn,
      isStandard: isStandard,
      bestValue: best,
    ));
  }
  return list;
});

/// Exercises that have at least one completed set (for bulk goal registration).
/// Sorted by name.
final exercisesWithHistoryProvider =
    FutureProvider.autoDispose<List<ExerciseMasterEntity>>((ref) async {
  final setRecordDao = ref.read(setRecordDaoProvider);
  final exerciseDao = ref.read(exerciseMasterDaoProvider);
  final ids = await setRecordDao.getExerciseIdsWithHistory();
  final list = <ExerciseMasterEntity>[];
  for (final id in ids) {
    final master = await exerciseDao.getExerciseById(id);
    if (master != null) list.add(master);
  }
  list.sort((a, b) => a.name.compareTo(b.name));
  return list;
});

/// Exercises that have history and do NOT have a goal yet (for bulk registration only).
/// すでに目標が設定してある種目は一括登録の選択肢に含めない。
final exercisesWithHistoryWithoutGoalProvider =
    FutureProvider.autoDispose<List<ExerciseMasterEntity>>((ref) async {
  final setRecordDao = ref.read(setRecordDaoProvider);
  final exerciseDao = ref.read(exerciseMasterDaoProvider);
  final goalDao = ref.read(exerciseGoalDaoProvider);
  final idsWithHistory = await setRecordDao.getExerciseIdsWithHistory();
  final goals = await goalDao.getAll();
  final idsWithGoal = goals.map((g) => g.exerciseId).toSet();
  final idsWithoutGoal = idsWithHistory.where((id) => !idsWithGoal.contains(id)).toList();
  final list = <ExerciseMasterEntity>[];
  for (final id in idsWithoutGoal) {
    final master = await exerciseDao.getExerciseById(id);
    if (master != null) list.add(master);
  }
  list.sort((a, b) => a.name.compareTo(b.name));
  return list;
});
