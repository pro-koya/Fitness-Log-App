import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/entities/exercise_goal_entity.dart';
import '../../../data/dao/set_record_dao.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/database_providers.dart';
import '../../../providers/exercise_goal_provider.dart';
import '../../../providers/settings_provider.dart';
import '../../../utils/duration_formatter.dart';
import '../../../utils/feature_gate.dart';
import 'goal_set_dialog.dart';

/// Shows goal progress or "Set goal" / Pro upsell. Used on ExerciseProgressScreen.
class ExerciseGoalSection extends ConsumerWidget {
  final int exerciseId;
  final String recordType;
  final String exerciseName;

  const ExerciseGoalSection({
    super.key,
    required this.exerciseId,
    required this.recordType,
    required this.exerciseName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gate = ref.watch(featureGateProvider);
    final goalAsync = ref.watch(exerciseGoalProvider(exerciseId));
    final unit = ref.watch(currentUnitProvider);

    if (!gate.canAccessExerciseGoals) {
      return _ProUpsellCard(l10n: AppLocalizations.of(context)!);
    }

    return goalAsync.when(
      data: (goal) {
        if (goal == null) {
          return _SetGoalCard(
            exerciseId: exerciseId,
            recordType: recordType,
            unit: unit,
            exerciseName: exerciseName,
          );
        }
        return _GoalProgressCard(
          exerciseId: exerciseId,
          goal: goal,
          unit: unit,
          recordType: recordType,
          exerciseName: exerciseName,
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _ProUpsellCard extends StatelessWidget {
  final AppLocalizations l10n;

  const _ProUpsellCard({required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.flag_outlined, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(child: Text(l10n.goalProUpsell, style: Theme.of(context).textTheme.bodyMedium)),
          ],
        ),
      ),
    );
  }
}

class _SetGoalCard extends ConsumerWidget {
  final int exerciseId;
  final String recordType;
  final String unit;
  final String exerciseName;

  const _SetGoalCard({
    required this.exerciseId,
    required this.recordType,
    required this.unit,
    required this.exerciseName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: InkWell(
        onTap: () async {
          final updated = await showDialog<bool>(
            context: context,
            builder: (ctx) => GoalSetDialog(
              exerciseId: exerciseId,
              recordType: recordType,
              unit: unit,
            ),
          );
          if (updated == true) ref.invalidate(exerciseGoalProvider(exerciseId));
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.flag_outlined, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(child: Text(l10n.goalSetTitle, style: Theme.of(context).textTheme.titleSmall)),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoalProgressCard extends ConsumerWidget {
  final int exerciseId;
  final ExerciseGoalEntity goal;
  final String unit;
  final String recordType;
  final String exerciseName;

  const _GoalProgressCard({
    required this.exerciseId,
    required this.goal,
    required this.unit,
    required this.recordType,
    required this.exerciseName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final languageCode = Localizations.localeOf(context).languageCode;
    return FutureBuilder<double?>(
      future: ref.read(setRecordDaoProvider).getBestValueForExercise(exerciseId, goal.goalType),
      builder: (context, snapshot) {
        final best = snapshot.data;
        final target = goal.goalValue;
        final achieved = best != null && best >= target;
        String displayText;
        if (achieved) {
          displayText = l10n.goalProgressPercent(100);
        } else if (best != null && target > 0) {
          final remaining = target - best;
          final valueStr = _formatValue(remaining, goal.goalType, unit, languageCode);
          displayText = l10n.goalProgressRemaining(valueStr);
        } else {
          final valueStr = _formatValue(target, goal.goalType, unit, languageCode);
          displayText = l10n.goalProgressRemaining(valueStr);
        }
        return Card(
          child: InkWell(
            onTap: () async {
              final updated = await showDialog<bool>(
                context: context,
                builder: (ctx) => GoalSetDialog(
                  exerciseId: exerciseId,
                  recordType: recordType,
                  unit: unit,
                  existing: goal,
                ),
              );
              if (updated == true) ref.invalidate(exerciseGoalProvider(exerciseId));
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    achieved ? Icons.emoji_events : Icons.flag_outlined,
                    color: achieved ? Colors.amber : Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(displayText, style: Theme.of(context).textTheme.titleSmall),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatValue(double v, String goalType, String unit, String languageCode) {
    if (goalType == 'weight') return '${v.toStringAsFixed(1)}$unit';
    if (goalType == 'reps') return v.toInt().toString();
    if (goalType == 'time') return formatDurationForGoal(v.toInt(), languageCode);
    if (goalType == 'volume') return v.toStringAsFixed(0);
    if (goalType == 'distance') return '${(v / 1000).toStringAsFixed(1)}km';
    return v.toString();
  }
}
