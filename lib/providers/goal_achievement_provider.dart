import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/entities/goal_achievement_entity.dart';
import 'database_providers.dart';

/// Start of current week (Monday 00:00:00) as unix timestamp.
int _startOfWeekTs() {
  final now = DateTime.now();
  final monday = now.subtract(Duration(days: now.weekday - 1));
  final start = DateTime(monday.year, monday.month, monday.day);
  return start.millisecondsSinceEpoch ~/ 1000;
}

/// End of "now" as unix timestamp.
int _nowTs() => DateTime.now().millisecondsSinceEpoch ~/ 1000;

/// Goals achieved this week (for home "今週達成した目標"). Pro only; gate in UI.
final goalsAchievedThisWeekProvider = FutureProvider.autoDispose<List<GoalAchievementEntity>>((ref) async {
  final dao = ref.watch(goalAchievementDaoProvider);
  final start = _startOfWeekTs();
  final end = _nowTs();
  return dao.getByAchievedAtBetween(start, end);
});
