import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/localization/exercise_localization.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/settings_provider.dart';
import '../models/routine_model.dart';
import 'routine_set_row.dart';

/// Exercise card in routine editor (simplified version of ExerciseCardWidget)
class RoutineExerciseCard extends ConsumerWidget {
  final RoutineExerciseModel exerciseModel;
  final int exerciseIndex;
  final void Function(int exerciseIndex, int setIndex, {double? weight, int? reps, int? durationSeconds, double? distance}) onUpdateSet;
  final void Function(int exerciseIndex) onAddSet;
  final void Function(int exerciseIndex, int setIndex) onDeleteSet;
  final void Function(int exerciseIndex) onRemoveExercise;

  const RoutineExerciseCard({
    super.key,
    required this.exerciseModel,
    required this.exerciseIndex,
    required this.onUpdateSet,
    required this.onAddSet,
    required this.onDeleteSet,
    required this.onRemoveExercise,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final language = ref.watch(currentLanguageProvider);
    final exerciseName = ExerciseLocalization.getLocalizedName(
      englishName: exerciseModel.exercise.name,
      language: language,
      isStandard: exerciseModel.exercise.isCustom == 0,
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Exercise header
            Row(
              children: [
                Icon(
                  Icons.drag_handle,
                  color: Colors.grey[400],
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    exerciseName,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => onRemoveExercise(exerciseIndex),
                  color: Colors.grey,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Set rows
            ...exerciseModel.targetSets.asMap().entries.map((entry) {
              return RoutineSetRow(
                setModel: entry.value,
                exerciseIndex: exerciseIndex,
                setIndex: entry.key,
                onUpdate: onUpdateSet,
                onDelete: onDeleteSet,
              );
            }),

            // Add set button
            const SizedBox(height: 4),
            Center(
              child: TextButton.icon(
                onPressed: () => onAddSet(exerciseIndex),
                icon: const Icon(Icons.add, size: 18),
                label: Text(
                  l10n.addSetButton,
                  style: const TextStyle(fontSize: 13),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  minimumSize: Size.zero,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
