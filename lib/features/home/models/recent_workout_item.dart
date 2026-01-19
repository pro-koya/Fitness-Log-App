import '../../../data/entities/workout_session_entity.dart';

/// 履歴一覧に表示するワークアウトアイテム
///
/// [session] ワークアウトセッション
/// [globalIndex] 全completedセッション内での0-indexedの位置（新しい順）
/// [isLocked] Freeユーザーで20件目以降の場合はtrue
class RecentWorkoutItem {
  final WorkoutSessionEntity session;
  final int globalIndex;
  final bool isLocked;

  const RecentWorkoutItem({
    required this.session,
    required this.globalIndex,
    required this.isLocked,
  });
}
