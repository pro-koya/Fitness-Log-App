import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/dao/exercise_master_dao.dart';
import '../../data/entities/exercise_master_entity.dart';
import '../../l10n/app_localizations.dart';
import '../workout_input/widgets/exercise_selector_modal.dart';
import 'providers/routine_edit_provider.dart';
import 'widgets/routine_exercise_card.dart';

/// Screen for creating or editing a routine
class RoutineEditScreen extends ConsumerStatefulWidget {
  final int? routineId;

  const RoutineEditScreen({super.key, this.routineId});

  @override
  ConsumerState<RoutineEditScreen> createState() => _RoutineEditScreenState();
}

class _RoutineEditScreenState extends ConsumerState<RoutineEditScreen> {
  late TextEditingController _nameController;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final editState = ref.watch(routineEditProvider(widget.routineId));

    // Sync name controller once when data loads
    if (!_initialized && !editState.isLoading && editState.name.isNotEmpty) {
      _nameController.text = editState.name;
      _initialized = true;
    }
    // For new routine, mark as initialized immediately
    if (!_initialized && widget.routineId == null && !editState.isLoading) {
      _initialized = true;
    }

    if (editState.isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.routineCreateNew)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.routineId != null ? l10n.routineEdit : l10n.routineCreateNew),
        actions: [
          TextButton(
            onPressed: () => _save(context, ref),
            child: Text(
              l10n.routineSave,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Routine name input
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: l10n.routineNameLabel,
                hintText: l10n.routineNameHint,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                ref.read(routineEditProvider(widget.routineId).notifier).setName(value);
              },
            ),
          ),

          // Exercise list
          Expanded(
            child: editState.exercises.isEmpty
                ? Center(
                    child: Text(
                      l10n.routineExerciseRequired,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                    ),
                  )
                : ReorderableListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: editState.exercises.length,
                    onReorder: (oldIndex, newIndex) {
                      ref
                          .read(routineEditProvider(widget.routineId).notifier)
                          .reorderExercise(oldIndex, newIndex);
                    },
                    itemBuilder: (context, index) {
                      return RoutineExerciseCard(
                        key: ValueKey('exercise_${editState.exercises[index].exercise.id}_$index'),
                        exerciseModel: editState.exercises[index],
                        exerciseIndex: index,
                        onUpdateSet: (ei, si, {weight, reps, durationSeconds, distance}) {
                          ref
                              .read(routineEditProvider(widget.routineId).notifier)
                              .updateSet(ei, si,
                                  weight: weight,
                                  reps: reps,
                                  durationSeconds: durationSeconds,
                                  distance: distance);
                        },
                        onAddSet: (ei) {
                          ref
                              .read(routineEditProvider(widget.routineId).notifier)
                              .addSet(ei);
                        },
                        onDeleteSet: (ei, si) {
                          ref
                              .read(routineEditProvider(widget.routineId).notifier)
                              .deleteSet(ei, si);
                        },
                        onRemoveExercise: (ei) {
                          ref
                              .read(routineEditProvider(widget.routineId).notifier)
                              .removeExercise(ei);
                        },
                      );
                    },
                  ),
          ),

          // Add exercise button
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _addExercise(context, ref),
                icon: const Icon(Icons.add),
                label: Text(l10n.addExerciseButton),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addExercise(BuildContext context, WidgetRef ref) async {
    final exercise = await showModalBottomSheet<ExerciseMasterEntity>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.85,
        child: ExerciseSelectorModal(
          exerciseMasterDao: ExerciseMasterDao(),
        ),
      ),
    );

    if (exercise != null) {
      ref
          .read(routineEditProvider(widget.routineId).notifier)
          .addExercise(exercise);
    }
  }

  Future<void> _save(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final notifier = ref.read(routineEditProvider(widget.routineId).notifier);
    final state = ref.read(routineEditProvider(widget.routineId));

    if (state.name.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.routineNameRequired)),
      );
      return;
    }
    if (state.exercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.routineExerciseRequired)),
      );
      return;
    }

    final success = await notifier.save();
    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.routineSaved)),
      );
      Navigator.of(context).pop(true);
    }
  }
}
