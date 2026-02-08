import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/workout_exercise_model.dart';
import '../../../providers/database_providers.dart';
import '../../../data/localization/exercise_localization.dart';
import '../../../data/localization/body_part_localization.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/settings_provider.dart';
import '../../tutorial/providers/interactive_tutorial_provider.dart';
import '../../tutorial/models/tutorial_step.dart';
import 'set_row_widget.dart';
import 'exercise_history_dialog.dart';

/// Exercise card widget
class ExerciseCardWidget extends ConsumerStatefulWidget {
  final WorkoutExerciseModel exercise;
  final int exerciseIndex;
  final Function(int setIndex, double? weight, int? reps, int? durationSeconds, double? distance)
      onUpdateSet;
  final Function(int setIndex) onCopyFromPrevious;
  final VoidCallback onReproduceAll;
  final VoidCallback onAddSet;
  final Function(int setIndex) onDeleteSet;
  final VoidCallback onDeleteExercise;
  final Function(String? memo) onUpdateMemo;
  final GlobalKey? tutorialSetInputKey; // Key for tutorial step 3

  const ExerciseCardWidget({
    super.key,
    required this.exercise,
    required this.exerciseIndex,
    required this.onUpdateSet,
    required this.onCopyFromPrevious,
    required this.onReproduceAll,
    required this.onAddSet,
    required this.onDeleteSet,
    required this.onDeleteExercise,
    required this.onUpdateMemo,
    this.tutorialSetInputKey,
  });

  @override
  ConsumerState<ExerciseCardWidget> createState() => _ExerciseCardWidgetState();
}

class _ExerciseCardWidgetState extends ConsumerState<ExerciseCardWidget> {
  bool _isPreviousRecordExpanded = false;
  bool _isMemoExpanded = false;
  late TextEditingController _memoController;
  late FocusNode _memoFocusNode;
  bool _isComposing = false;

  @override
  void initState() {
    super.initState();
    _memoController = TextEditingController(text: widget.exercise.memo ?? '');
    _isMemoExpanded = (widget.exercise.memo?.isNotEmpty ?? false);
    _memoFocusNode = FocusNode();
    _memoFocusNode.addListener(_onMemoFocusChange);
  }

  @override
  void dispose() {
    _memoFocusNode.removeListener(_onMemoFocusChange);
    _memoFocusNode.dispose();
    _memoController.dispose();
    super.dispose();
  }

  void _onMemoFocusChange() {
    if (!_memoFocusNode.hasFocus && !_isComposing) {
      _saveMemo();
    }
  }

  void _saveMemo() {
    final text = _memoController.text;
    widget.onUpdateMemo(text.isEmpty ? null : text);
  }

  @override
  void didUpdateWidget(ExerciseCardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only update controller if memo changed externally (not from user input)
    // and focus is not on the memo field
    if (oldWidget.exercise.memo != widget.exercise.memo &&
        !_memoFocusNode.hasFocus) {
      _memoController.text = widget.exercise.memo ?? '';
      _isMemoExpanded = (widget.exercise.memo?.isNotEmpty ?? false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currentLanguage = ref.watch(currentLanguageProvider);
    final currentUnit = ref.watch(currentUnitProvider);
    final isStandard = widget.exercise.exercise.isCustom == 0;
    final displayName = ExerciseLocalization.getLocalizedName(
      englishName: widget.exercise.exercise.name,
      language: currentLanguage,
      isStandard: isStandard,
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Exercise name and body part
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (widget.exercise.exercise.bodyPart != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          BodyPartLocalization.getLocalizedName(
                            widget.exercise.exercise.bodyPart!,
                            currentLanguage,
                          ),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: widget.onDeleteExercise,
                  color: Colors.grey.shade600,
                  tooltip: l10n.deleteExerciseTooltip,
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Previous record
            _buildPreviousRecord(context, currentUnit, l10n),

            const Divider(height: 24),

            // Sets
            ...widget.exercise.sets.asMap().entries.map((entry) {
              final setIndex = entry.key;
              final set = entry.value;
              // Can duplicate if current set has any values
              final canDuplicate = set.weight != null ||
                  set.reps != null ||
                  (set.durationSeconds != null && set.durationSeconds! > 0) ||
                  set.distance != null;

              // Use tutorial key for first set if provided
              final setKey = setIndex == 0 && widget.tutorialSetInputKey != null
                  ? widget.tutorialSetInputKey!
                  : ValueKey('set_${widget.exercise.workoutExerciseId}_$setIndex');

              return SetRowWidget(
                key: setKey,
                set: set,
                canDuplicate: canDuplicate,
                canDelete: widget.exercise.sets.length > 1,
                onUpdate: (weight, reps, durationSeconds, distance) {
                  widget.onUpdateSet(setIndex, weight, reps, durationSeconds, distance);
                  // When step 3 (input set) is active and user has entered both weight and reps, jump to step 6 (complete button)
                  if (setIndex == 0 && widget.tutorialSetInputKey != null) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      final tutorialNotifier = ref.read(interactiveTutorialProvider.notifier);
                      final tutorialState = ref.read(interactiveTutorialProvider);
                      if (tutorialState.isActive &&
                          tutorialState.currentStep == TutorialStep.workoutInputSet &&
                          weight != null &&
                          reps != null) {
                        tutorialNotifier.completeStepAndJumpTo(TutorialStep.workoutComplete);
                      }
                    });
                  }
                },
                onDuplicate: () => widget.onCopyFromPrevious(setIndex),
                onDelete: () => widget.onDeleteSet(setIndex),
              );
            }),

            const SizedBox(height: 8),

            // Memo section
            _buildMemoSection(l10n),

            const SizedBox(height: 8),

            // Add set button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: widget.onAddSet,
                icon: const Icon(Icons.add, size: 20),
                label: Text(l10n.addSetButton),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemoSection(AppLocalizations l10n) {
    final hasMemo = widget.exercise.memo?.isNotEmpty ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Memo header (collapsible)
        InkWell(
          onTap: () {
            setState(() {
              _isMemoExpanded = !_isMemoExpanded;
            });
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Icon(
                  Icons.note_outlined,
                  size: 18,
                  color: hasMemo ? Colors.blue : Colors.grey.shade600,
                ),
                const SizedBox(width: 6),
                Text(
                  l10n.memoLabel,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: hasMemo ? Colors.blue : Colors.grey.shade700,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  _isMemoExpanded ? Icons.expand_less : Icons.expand_more,
                  size: 20,
                  color: Colors.grey.shade600,
                ),
              ],
            ),
          ),
        ),

        // Memo input field (expandable)
        if (_isMemoExpanded)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: TextField(
              controller: _memoController,
              focusNode: _memoFocusNode,
              maxLines: 3,
              maxLength: 500,
              decoration: InputDecoration(
                hintText: l10n.memoPlaceholder,
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              style: const TextStyle(fontSize: 14),
              onTapOutside: (_) {
                _memoFocusNode.unfocus();
              },
            ),
          ),
      ],
    );
  }

  Widget _buildPreviousRecord(BuildContext context, String currentUnit, AppLocalizations l10n) {
    final currentDistanceUnit = ref.watch(currentDistanceUnitProvider);
    final isCardio = widget.exercise.exercise.recordType == 'cardio';

    if (widget.exercise.previousSets.isEmpty) {
      return Row(
        children: [
          Text(
            l10n.previousRecordNone,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const Spacer(),
          OutlinedButton(
            onPressed: null, // Disabled
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            child: Text(l10n.reproducePreviousButton,
                style: const TextStyle(fontSize: 12)),
          ),
        ],
      );
    }

    final previousSets = widget.exercise.previousSets;
    final shouldCollapse = previousSets.length >= 3;

    // Determine which sets to show
    final setsToShow = shouldCollapse && !_isPreviousRecordExpanded
        ? previousSets.take(2).toList()
        : previousSets;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Previous sets display
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            Text(
              '${l10n.previousLabel} ',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
            ...setsToShow.asMap().entries.map((entry) {
              final index = entry.key;
              final set = entry.value;

              // Format based on record type
              String valueStr;
              if (isCardio) {
                // Cardio: time + distance
                final minutes = (set.durationSeconds ?? 0) ~/ 60;
                final seconds = (set.durationSeconds ?? 0) % 60;
                final timeStr = minutes > 0
                    ? '${minutes}m${seconds}s'
                    : '${seconds}s';
                final distance = set.getDistance(currentDistanceUnit);
                final distanceStr = distance != null
                    ? '${distance.toStringAsFixed(2)}$currentDistanceUnit'
                    : '';
                valueStr = distanceStr.isNotEmpty ? '$timeStr / $distanceStr' : timeStr;
              } else if (set.durationSeconds != null && set.durationSeconds! > 0) {
                // Time-based: weight + duration
                final weight = set.getWeight(currentUnit);
                final weightStr = weight == weight.toInt()
                    ? weight.toInt().toString()
                    : weight.toStringAsFixed(1);
                final minutes = set.durationSeconds! ~/ 60;
                final seconds = set.durationSeconds! % 60;
                final timeStr = minutes > 0
                    ? '${minutes}m${seconds}s'
                    : '${seconds}s';
                valueStr = '$weightStr$currentUnit×$timeStr';
              } else {
                // Reps-based: weight + reps
                final weight = set.getWeight(currentUnit);
                final weightStr = weight == weight.toInt()
                    ? weight.toInt().toString()
                    : weight.toStringAsFixed(1);
                valueStr = '$weightStr$currentUnit×${set.reps ?? 0}';
              }
              return Text(
                isCardio
                    ? '$valueStr${index < setsToShow.length - 1 ? ' /' : ''}'
                    : '$valueStr${index < setsToShow.length - 1 ? ' /' : ''}',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              );
            }),
            // Show expand/collapse button if needed
            if (shouldCollapse)
              InkWell(
                onTap: () {
                  setState(() {
                    _isPreviousRecordExpanded = !_isPreviousRecordExpanded;
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    _isPreviousRecordExpanded
                        ? l10n.showLess
                        : l10n.showMoreSets(previousSets.length - 2),
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // View history button
            OutlinedButton.icon(
              onPressed: _showHistoryDialog,
              icon: const Icon(Icons.history, size: 16),
              label: Text(l10n.historyButton, style: const TextStyle(fontSize: 12)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
            const SizedBox(width: 8),
            // Reproduce previous button
            OutlinedButton(
              onPressed: widget.onReproduceAll,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              child: Text(l10n.reproducePreviousButton,
                  style: const TextStyle(fontSize: 12)),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _showHistoryDialog() async {
    final setRecordDao = ref.read(setRecordDaoProvider);
    final currentLanguage = ref.read(currentLanguageProvider);
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    try {
      final historyData = await setRecordDao.getAllHistoryForExercise(
        widget.exercise.exercise.id!,
        now,
        limit: 10,
      );

      if (!mounted) return;

      final isStandard = widget.exercise.exercise.isCustom == 0;
      final displayName = ExerciseLocalization.getLocalizedName(
        englishName: widget.exercise.exercise.name,
        language: currentLanguage,
        isStandard: isStandard,
      );

      showDialog(
        context: context,
        builder: (context) => ExerciseHistoryDialog(
          exerciseName: displayName,
          historyData: historyData,
          recordType: widget.exercise.exercise.recordType,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading history: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
