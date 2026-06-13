import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/entities/exercise_master_entity.dart';
import '../../data/localization/exercise_localization.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/database_providers.dart';
import '../../providers/goal_list_provider.dart';
import '../../providers/settings_provider.dart';
import '../../utils/date_formatter.dart';
import '../../utils/duration_formatter.dart';
import '../../utils/feature_gate.dart';
import '../exercise_progress/exercise_progress_screen.dart';
import '../exercise_progress/widgets/goal_set_dialog.dart';
import 'widgets/bulk_goal_edit_modal.dart';
import 'widgets/bulk_goal_select_modal.dart';
import 'widgets/goal_set_exercise_selector_modal.dart';

/// 目標一覧: 設定した目標を達成率・重要度付きで一覧表示（Pro）。
class GoalListScreen extends ConsumerWidget {
  const GoalListScreen({super.key});

  /// 目標を設定フロー: 種目選択モーダル → 目標設定ダイアログ
  static Future<void> _openSetGoalFlow(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    final selected = await showModalBottomSheet<ExerciseMasterEntity>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => const GoalSetExerciseSelectorModal(),
    );
    if (selected == null || selected.id == null || !context.mounted) return;
    final unit = ref.read(currentUnitProvider);
    final goalDao = ref.read(exerciseGoalDaoProvider);
    final existing = await goalDao.getByExerciseId(selected.id!);
    if (!context.mounted) return;
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => GoalSetDialog(
        exerciseId: selected.id!,
        recordType: selected.recordType,
        unit: unit,
        existing: existing,
      ),
    );
    if (saved == true) {
      ref.invalidate(allGoalsListProvider);
    }
  }

  /// 一括で目標を設定フロー: 目標未設定の種目あり確認 → 種目選択モーダル（コース＋チェック）
  static Future<void> _openBulkGoalFlow(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    final listWithoutGoal = await ref.read(exercisesWithHistoryWithoutGoalProvider.future);
    if (listWithoutGoal.isEmpty) {
      if (!context.mounted) return;
      final setRecordDao = ref.read(setRecordDaoProvider);
      final idsWithHistory = await setRecordDao.getExerciseIdsWithHistory();
      if (!context.mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(
            idsWithHistory.isEmpty ? l10n.bulkGoalNoHistoryTitle : l10n.bulkGoalSetTitle,
          ),
          content: Text(
            idsWithHistory.isEmpty
                ? l10n.bulkGoalNoHistoryMessage
                : l10n.bulkGoalNoTargetsToSetMessage,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(l10n.confirmButton),
            ),
          ],
        ),
      );
      return;
    }
    if (!context.mounted) return;
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => const BulkGoalSelectModal(),
    );
    if (result == true) {
      ref.invalidate(allGoalsListProvider);
    }
  }

  /// 目標の一括編集フロー: 既存目標をチェックで選択 → 削除 or 再計算
  static Future<void> _openBulkEditFlow(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => const BulkGoalEditModal(),
    );
    if (result == true) {
      ref.invalidate(allGoalsListProvider);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final gate = ref.watch(featureGateProvider);
    final lang = ref.watch(currentLanguageProvider);

    if (!gate.canAccessExerciseGoals) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.goalListTitle)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.flag_outlined, size: 64, color: Theme.of(context).colorScheme.primary),
                const SizedBox(height: 16),
                Text(
                  l10n.goalProUpsell,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final async = ref.watch(allGoalsListProvider);
    final unit = ref.watch(currentUnitProvider);
    final distanceUnit = ref.watch(currentDistanceUnitProvider);
    final theme = Theme.of(context);
    final appBarForeground = theme.appBarTheme.foregroundColor ?? theme.colorScheme.onPrimary;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.goalListTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => _openSetGoalFlow(context, ref, l10n),
            icon: Icon(Icons.add, size: 20, color: appBarForeground),
            label: Text(
              l10n.goalSetTitle,
              style: TextStyle(color: appBarForeground, fontSize: 14),
            ),
          ),
          TextButton.icon(
            onPressed: () => _openBulkGoalFlow(context, ref, l10n),
            icon: Icon(Icons.playlist_add_check, size: 20, color: appBarForeground),
            label: Text(
              l10n.bulkGoalButtonLabel,
              style: TextStyle(color: appBarForeground, fontSize: 14),
            ),
          ),
          TextButton.icon(
            onPressed: () => _openBulkEditFlow(context, ref, l10n),
            icon: Icon(Icons.edit_note, size: 20, color: appBarForeground),
            label: Text(
              l10n.bulkGoalEditButtonLabel,
              style: TextStyle(color: appBarForeground, fontSize: 14),
            ),
          ),
        ],
      ),
      body: async.when(
        data: (list) {
          if (list.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.flag_outlined, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    l10n.goalListEmpty,
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final item = list[index];
              final displayName = item.exerciseNameEn.isEmpty
                  ? '${l10n.goalTargetLabel} (ID: ${item.goal.exerciseId})'
                  : ExerciseLocalization.getLocalizedName(
                      englishName: item.exerciseNameEn,
                      language: lang,
                      isStandard: item.isStandard,
                    );
              final goalTypeLabel = _goalTypeLabel(item.goal.goalType, l10n);
              final priorityLabel = _priorityLabel(item.goal.priority, l10n);
              final percent = item.achievementPercent;
              final valueWithUnit = _formatGoalValue(item, unit, distanceUnit, lang);
              final deadlineStr = item.goal.deadlineTs != null
                  ? DateFormatter.formatShortDate(
                      DateTime.fromMillisecondsSinceEpoch(item.goal.deadlineTs! * 1000),
                      lang,
                    )
                  : null;
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ExerciseProgressScreen(
                          exerciseId: item.goal.exerciseId,
                          exerciseName: displayName,
                        ),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                displayName,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ),
                            _PriorityChip(label: priorityLabel, priority: item.goal.priority),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${l10n.goalTargetLabel}: $goalTypeLabel $valueWithUnit',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    deadlineStr != null
                                        ? '${l10n.goalDueLabel}: $deadlineStr'
                                        : '${l10n.goalDueLabel}: —',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  l10n.goalAchievementRateLabel,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  percent != null
                                      ? l10n.goalProgressPercent(percent)
                                      : '—',
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: percent != null && percent >= 100
                                            ? Colors.green.shade700
                                            : null,
                                      ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.grey.shade600),
                const SizedBox(height: 12),
                Text(
                  l10n.errorLoadFailed,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _goalTypeLabel(String type, AppLocalizations l10n) {
    switch (type) {
      case 'weight': return l10n.goalTypeWeight;
      case 'reps': return l10n.goalTypeReps;
      case 'volume': return l10n.goalTypeVolume;
      case 'time': return l10n.goalTypeTime;
      case 'distance': return l10n.goalTypeDistance;
      default: return type;
    }
  }

  static String _priorityLabel(int priority, AppLocalizations l10n) {
    if (priority >= 3) return l10n.goalPriorityHigh;
    if (priority == 2) return l10n.goalPriorityMedium;
    return l10n.goalPriorityLow;
  }

  static String _formatGoalValue(GoalListItem item, String unit, String distanceUnit, String language) {
    final g = item.goal;
    if (g.goalType == 'time') {
      return formatDurationForGoal(g.goalValue.toInt(), language);
    }
    if (g.goalType == 'distance') {
      final km = g.goalValue / 1000;
      final display = distanceUnit == 'mile' ? km / 1.609 : km;
      final suffix = distanceUnit == 'mile' ? ' mile' : ' km';
      return '${display.toStringAsFixed(1)}$suffix';
    }
    if (g.goalType == 'weight' || g.goalType == 'volume') {
      final v = unit == 'lb' ? g.goalValue * 2.20462 : g.goalValue;
      final numStr = v == v.truncateToDouble()
          ? v.toInt().toString()
          : v.toStringAsFixed(1);
      return '$numStr$unit';
    }
    return g.goalValue.toInt().toString();
  }
}

class _PriorityChip extends StatelessWidget {
  final String label;
  final int priority;

  const _PriorityChip({required this.label, required this.priority});

  @override
  Widget build(BuildContext context) {
    Color color;
    if (priority >= 3) color = Colors.orange.shade700;
    else if (priority == 2) color = Colors.blue.shade700;
    else color = Colors.grey.shade600;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: color,
            ),
      ),
    );
  }
}
