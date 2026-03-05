import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/dao/routine_template_dao.dart';
import '../../data/dao/routine_exercise_dao.dart';
import '../../data/dao/routine_set_dao.dart';
import '../../data/dao/workout_exercise_dao.dart';
import '../../data/dao/set_record_dao.dart';
import '../../data/localization/exercise_localization.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/routine_provider.dart';
import '../routine/services/routine_service.dart';
import 'models/workout_completion_result.dart';

/// Modal shown after workout is completed. Displays summary, exercise details, and muscle message.
class WorkoutCompletionModal extends ConsumerStatefulWidget {
  final WorkoutCompletionResult result;
  final VoidCallback onClose;

  const WorkoutCompletionModal({
    super.key,
    required this.result,
    required this.onClose,
  });

  static Future<void> show(
    BuildContext context, {
    required WorkoutCompletionResult result,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => WorkoutCompletionModal(
        result: result,
        onClose: () => Navigator.of(context).pop(),
      ),
    );
  }

  @override
  ConsumerState<WorkoutCompletionModal> createState() => _WorkoutCompletionModalState();
}

class _WorkoutCompletionModalState extends ConsumerState<WorkoutCompletionModal> {
  bool _routineSaved = false;

  String _formatDuration(int seconds) {
    if (seconds < 60) return '${seconds}秒';
    final m = seconds ~/ 60;
    final s = seconds % 60;
    if (s == 0) return '$m分';
    return '${m}分${s}秒';
  }

  String _formatDurationEn(int seconds) {
    if (seconds < 60) return '${seconds}s';
    final m = seconds ~/ 60;
    final s = seconds % 60;
    if (s == 0) return '$m min';
    return '${m}m ${s}s';
  }

  Future<void> _saveAsRoutine(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final nameController = TextEditingController();

    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.routineSaveAsRoutine),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: InputDecoration(
            labelText: l10n.routineNameLabel,
            hintText: l10n.routineNameHint,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancelButton),
          ),
          TextButton(
            onPressed: () {
              final text = nameController.text.trim();
              if (text.isNotEmpty) {
                Navigator.of(context).pop(text);
              }
            },
            child: Text(l10n.routineSave),
          ),
        ],
      ),
    );

    if (name != null && name.isNotEmpty && context.mounted) {
      final service = RoutineService(
        templateDao: RoutineTemplateDao(),
        routineExerciseDao: RoutineExerciseDao(),
        routineSetDao: RoutineSetDao(),
        workoutExerciseDao: WorkoutExerciseDao(),
        setRecordDao: SetRecordDao(),
      );

      await service.createFromSession(
        name: name,
        sessionId: widget.result.sessionId,
      );

      if (context.mounted) {
        ref.invalidate(routineListProvider);
        setState(() => _routineSaved = true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.routineSaved)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final unitLabel = widget.result.unit == 'kg' ? 'kg' : 'lb';
    final volumeStr = widget.result.totalVolume >= 1000
        ? '${(widget.result.totalVolume / 1000).toStringAsFixed(1)}k'
        : widget.result.totalVolume.toStringAsFixed(0);
    final isJa = Localizations.localeOf(context).languageCode == 'ja';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 560),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.fitness_center,
                size: 48,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 12),
              Text(
                l10n.workoutCompletionTitle,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                l10n.workoutCompletionSummary(
                  widget.result.exerciseCount,
                  widget.result.setCount,
                  volumeStr,
                  unitLabel,
                ),
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              if (widget.result.exerciseDetails.isNotEmpty) ...[
                const SizedBox(height: 12),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: widget.result.exerciseDetails.map((e) {
                        String line;
                        if (e.isTimeBased && e.topDurationSeconds != null) {
                          final dur = isJa
                              ? _formatDuration(e.topDurationSeconds!)
                              : _formatDurationEn(e.topDurationSeconds!);
                          line = l10n.workoutCompletionExerciseLineTime(
                            e.name,
                            e.setCount,
                            dur,
                          );
                        } else if (e.topWeight != null) {
                          line = l10n.workoutCompletionExerciseLine(
                            e.name,
                            e.setCount,
                            e.topWeight!.toStringAsFixed(
                                e.topWeight! >= 100 ? 0 : 1),
                            unitLabel,
                          );
                        } else {
                          line = '${e.name} ${e.setCount}${isJa ? 'セット' : ' sets'}';
                        }
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            line,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
              if (widget.result.achievedGoals.isNotEmpty) ...[
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    l10n.goalAchievedTitle,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                ),
                const SizedBox(height: 4),
                ...widget.result.achievedGoals.map((g) {
                  final displayName = ExerciseLocalization.getLocalizedName(
                    englishName: g.exerciseNameEn,
                    language: Localizations.localeOf(context).languageCode,
                    isStandard: g.isStandard,
                  );
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      l10n.goalAchievedMessage(displayName, g.valueStr),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  );
                }),
              ],
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primaryContainer
                      .withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  widget.result.message,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w500,
                      ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 12),
              if (!_routineSaved)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _saveAsRoutine(context),
                    icon: const Icon(Icons.repeat, size: 18),
                    label: Text(l10n.routineSaveAsRoutine),
                  ),
                ),
              if (_routineSaved)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check, size: 16, color: Colors.green.shade700),
                    const SizedBox(width: 4),
                    Text(
                      l10n.routineSaved,
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: widget.onClose,
                  child: Text(l10n.confirmButton),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
