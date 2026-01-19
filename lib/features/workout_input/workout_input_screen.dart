import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/localization/exercise_localization.dart';
import '../../providers/database_providers.dart';
import '../../providers/settings_provider.dart';
import '../../providers/workout_session_provider.dart';
import '../../l10n/app_localizations.dart';
import 'providers/workout_input_provider.dart';
import 'widgets/exercise_card_widget.dart';
import 'widgets/exercise_selector_modal.dart';
import 'widgets/timer_icon_button.dart';

/// Workout input screen - most important screen
class WorkoutInputScreen extends ConsumerStatefulWidget {
  final int sessionId;

  const WorkoutInputScreen({
    super.key,
    required this.sessionId,
  });

  @override
  ConsumerState<WorkoutInputScreen> createState() =>
      _WorkoutInputScreenState();
}

class _WorkoutInputScreenState extends ConsumerState<WorkoutInputScreen> {
  String? _lastUnit;
  bool _hasInitialized = false;

  @override
  Widget build(BuildContext context) {
    final workoutState = ref.watch(workoutInputProvider(widget.sessionId));
    final currentUnit = ref.watch(currentUnitProvider);
    final settingsAsync = ref.watch(settingsProvider);
    
    // Wait for settings to load, then ensure exercises are loaded with correct unit
    settingsAsync.whenData((settings) {
      if (!_hasInitialized) {
        // First time: check if exercises need to be loaded with correct unit
        _hasInitialized = true;
        _lastUnit = currentUnit;
        
        // If exercises are already loaded, check if they have correct unit
        if (workoutState.exercises.isNotEmpty) {
          final firstSet = workoutState.exercises.first.sets.isNotEmpty
              ? workoutState.exercises.first.sets.first
              : null;
          if (firstSet != null && firstSet.unit != currentUnit) {
            // Unit mismatch: reload with correct unit
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                ref.read(workoutInputProvider(widget.sessionId).notifier).reloadExercises();
              }
            });
          }
        } else {
          // No exercises loaded yet, load them with correct unit
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              ref.read(workoutInputProvider(widget.sessionId).notifier).reloadExercises();
            }
          });
        }
      } else {
        // Reload exercises when unit changes
        if (_lastUnit != null && _lastUnit != currentUnit) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              ref.read(workoutInputProvider(widget.sessionId).notifier).reloadExercises();
            }
          });
        }
        _lastUnit = currentUnit;
      }
    });

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        // Save before leaving
        await _saveAndExit();
      },
      child: GestureDetector(
        onTap: () {
          // Dismiss keyboard when tapping outside input fields
          FocusScope.of(context).unfocus();
        },
        child: Scaffold(
          appBar: AppBar(
          title: const Text('Workout'),
          actions: [
            TimerIconButton(),
          ],
        ),
        body: workoutState.isLoading
            ? const Center(child: CircularProgressIndicator())
            : workoutState.exercises.isEmpty
                ? _buildEmptyState()
                : _buildExerciseList(workoutState),
          bottomNavigationBar: _buildBottomBar(),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.fitness_center,
            size: 80,
            color: Colors.grey,
          ),
          const SizedBox(height: 24),
          const Text(
            'Add an exercise to\nstart your workout',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showExerciseSelector,
            icon: const Icon(Icons.add),
            label: const Text('Add Exercise'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseList(WorkoutInputState workoutState) {
    return ListView.builder(
      padding: const EdgeInsets.all(16).copyWith(bottom: 100),
      itemCount: workoutState.exercises.length,
      itemBuilder: (context, index) {
        final exercise = workoutState.exercises[index];
        final notifier = ref.read(workoutInputProvider(widget.sessionId).notifier);

        return ExerciseCardWidget(
          exercise: exercise,
          exerciseIndex: index,
          onUpdateSet: (setIndex, weight, reps, durationSeconds, distance) {
            notifier.updateSet(index, setIndex,
                weight: weight, reps: reps, durationSeconds: durationSeconds, distance: distance);
          },
          onCopyFromPrevious: (setIndex) {
            notifier.copyFromPrevious(index, setIndex);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Copied from previous set'),
                duration: Duration(milliseconds: 800),
              ),
            );
          },
          onReproduceAll: () {
            notifier.reproduceAllSets(index);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Reproduced all sets from previous workout'),
                duration: Duration(milliseconds: 1200),
              ),
            );
          },
          onAddSet: () {
            notifier.addSet(index);
          },
          onDeleteSet: (setIndex) {
            notifier.deleteSet(index, setIndex);
          },
          onDeleteExercise: () {
            final currentLanguage = ref.read(currentLanguageProvider);
            final isStandard = exercise.exercise.isCustom == 0;
            final displayName = ExerciseLocalization.getLocalizedName(
              englishName: exercise.exercise.name,
              language: currentLanguage,
              isStandard: isStandard,
            );
            _showDeleteExerciseDialog(index, displayName);
          },
          onUpdateMemo: (memo) {
            notifier.updateMemo(index, memo);
          },
        );
      },
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Add exercise button
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _showExerciseSelector,
                icon: const Icon(Icons.add),
                label: const Text('Add Exercise'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Complete button
            Expanded(
              child: ElevatedButton(
                onPressed: _completeWorkout,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Complete'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showExerciseSelector() async {
    final exerciseMasterDao = ref.read(exerciseMasterDaoProvider);

    if (!mounted) return;

    final selectedId = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      builder: (context) => ExerciseSelectorModal(
        exerciseMasterDao: exerciseMasterDao,
      ),
    );

    if (selectedId != null) {
      final exercise = await exerciseMasterDao.getExerciseById(selectedId);
      if (exercise != null) {
        final notifier =
            ref.read(workoutInputProvider(widget.sessionId).notifier);
        await notifier.addExercise(exercise);
      }
    }
  }

  Future<void> _saveAndExit() async {
    // Final save to ensure any pending changes are persisted
    final notifier = ref.read(workoutInputProvider(widget.sessionId).notifier);
    await notifier.saveAll();

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _completeWorkout() async {
    // Save all sets
    final notifier = ref.read(workoutInputProvider(widget.sessionId).notifier);
    await notifier.saveAll();

    // Complete session
    final sessionNotifier = ref.read(workoutSessionNotifierProvider.notifier);
    await sessionNotifier.completeSession(widget.sessionId);

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _showDeleteExerciseDialog(
    int exerciseIndex,
    String exerciseName,
  ) async {
    final l10n = AppLocalizations.of(context)!;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteExerciseDialogTitle),
        content: Text(
          l10n.deleteExerciseDialogMessage(exerciseName),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancelButton),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: Text(l10n.deleteButton),
          ),
        ],
      ),
    );

    if (result == true) {
      final notifier = ref.read(workoutInputProvider(widget.sessionId).notifier);
      await notifier.deleteExercise(exerciseIndex);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.exerciseDeleted(exerciseName)),
            duration: const Duration(milliseconds: 1200),
          ),
        );
      }
    }
  }
}
