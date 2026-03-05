import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/localization/exercise_localization.dart';
import '../../providers/database_providers.dart';
import '../../providers/settings_provider.dart';
import '../../providers/workout_session_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../services/muscle_message_service.dart';
import '../../services/review_prompt_service.dart';
import '../tutorial/providers/interactive_tutorial_provider.dart';
import '../tutorial/models/tutorial_step.dart';
import '../tutorial/widgets/tutorial_overlay.dart';
import '../workout_completion/workout_completion_modal.dart';
import 'providers/workout_input_provider.dart';
import 'widgets/exercise_card_widget.dart';
import 'widgets/exercise_selector_modal.dart';
import 'widgets/timer_icon_button.dart';
import '../routine/widgets/routine_selector_modal.dart';
import '../../data/entities/exercise_master_entity.dart';
import '../../data/entities/routine_template_entity.dart';

/// Workout input screen - most important screen
class WorkoutInputScreen extends ConsumerStatefulWidget {
  final int sessionId;
  final bool isTutorialMode;
  /// When starting a new session with a routine (loads routine as initial content)
  final int? routineId;
  /// When adding a routine to an existing in-progress session (appends to current)
  final int? addRoutineId;

  const WorkoutInputScreen({
    super.key,
    required this.sessionId,
    this.isTutorialMode = false,
    this.routineId,
    this.addRoutineId,
  });

  @override
  ConsumerState<WorkoutInputScreen> createState() =>
      _WorkoutInputScreenState();
}

class _WorkoutInputScreenState extends ConsumerState<WorkoutInputScreen> {
  String? _lastUnit;
  bool _hasInitialized = false;
  bool _routineLoaded = false;
  bool _addRoutineLoaded = false;
  int? _newlyAddedExerciseIndex;
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _addExerciseButtonKey = GlobalKey();
  final GlobalKey _setInputKey = GlobalKey();
  final GlobalKey _completeButtonKey = GlobalKey();
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

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

        // When opened from tutorial "記録開始", advance from step 1 to step 2 here so the overlay stays on home until this screen is shown (no mysterious flash).
        if (widget.isTutorialMode) {
          final step = ref.read(interactiveTutorialProvider).currentStep;
          if (step == TutorialStep.homeStartWorkout) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                ref.read(interactiveTutorialProvider.notifier).completeCurrentStep();
              }
            });
          }
        }

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
          // Add routine to current session (append, do not overwrite)
          if (widget.addRoutineId != null && !_addRoutineLoaded) {
            _addRoutineLoaded = true;
            WidgetsBinding.instance.addPostFrameCallback((_) async {
              if (mounted) {
                await ref.read(workoutInputProvider(widget.sessionId).notifier).loadFromRoutine(widget.addRoutineId!);
              }
            });
          }
        } else {
          // No exercises loaded yet, load them with correct unit
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            if (mounted) {
              await ref.read(workoutInputProvider(widget.sessionId).notifier).reloadExercises();
              // Load routine exercises if routineId is provided (new session)
              if (widget.routineId != null && !_routineLoaded) {
                _routineLoaded = true;
                if (mounted) {
                  await ref.read(workoutInputProvider(widget.sessionId).notifier).loadFromRoutine(widget.routineId!);
                }
              }
              // Add routine to current session (append)
              if (widget.addRoutineId != null && !_addRoutineLoaded) {
                _addRoutineLoaded = true;
                if (mounted) {
                  await ref.read(workoutInputProvider(widget.sessionId).notifier).loadFromRoutine(widget.addRoutineId!);
                }
              }
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
          title: Text(AppLocalizations.of(context)!.workoutInputTitle),
          actions: [
            IconButton(
              icon: const Icon(Icons.repeat, size: 22),
              tooltip: AppLocalizations.of(context)!.routineLoadIntoWorkout,
              onPressed: () => _loadRoutineIntoWorkout(context, ref),
            ),
            TimerIconButton(),
          ],
        ),
        body: Stack(
          children: [
            // In tutorial step 2, show empty state immediately (no loading) so user goes straight to "種目を追加"
            _shouldShowLoading(workoutState)
                ? const Center(child: CircularProgressIndicator())
                : workoutState.exercises.isEmpty
                    ? _buildEmptyState()
                    : _buildExerciseList(workoutState),
            // Tutorial overlay
            _buildTutorialOverlay(context, ref, workoutState),
          ],
        ),
          bottomNavigationBar: _buildBottomBar(),
        ),
      ),
    );
  }

  /// During tutorial step 2 (add exercise), show empty state immediately so user sees "種目を追加" without a loading step.
  bool _shouldShowLoading(WorkoutInputState workoutState) {
    if (!workoutState.isLoading) return false;
    if (widget.isTutorialMode && workoutState.exercises.isEmpty) return false;
    return true;
  }

  Widget _buildEmptyState() {
    final l10n = AppLocalizations.of(context)!;
    final tutorialState = ref.watch(interactiveTutorialProvider);
    final isStep2Active = tutorialState.isActive &&
        tutorialState.currentStep == TutorialStep.workoutAddExercise;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.fitness_center,
              size: 80,
              color: Colors.grey,
            ),
            const SizedBox(height: 24),
            Text(
              l10n.workoutEmptyStateHint,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              key: isStep2Active ? _addExerciseButtonKey : null,
              onPressed: () async {
                if (isStep2Active) {
                  ref.read(interactiveTutorialProvider.notifier).completeCurrentStep();
                }
                await _showExerciseSelector();
              },
              icon: const Icon(Icons.add),
              label: Text(l10n.addExerciseButton),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseList(WorkoutInputState workoutState) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16).copyWith(bottom: 100),
      itemCount: workoutState.exercises.length,
      itemBuilder: (context, index) {
        final exercise = workoutState.exercises[index];
        final notifier = ref.read(workoutInputProvider(widget.sessionId).notifier);

        final tutorialState = ref.watch(interactiveTutorialProvider);
        final isStep3Active = tutorialState.isActive &&
            tutorialState.currentStep == TutorialStep.workoutInputSet &&
            index == 0;

        // Auto-focus the newly added exercise
        final shouldAutoFocus = _newlyAddedExerciseIndex == index;
        if (shouldAutoFocus) {
          // Clear after building so it only fires once
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() => _newlyAddedExerciseIndex = null);
            }
          });
        }

        return ExerciseCardWidget(
          exercise: exercise,
          exerciseIndex: index,
          autoFocus: shouldAutoFocus,
          tutorialSetInputKey: isStep3Active ? _setInputKey : null,
          onUpdateSet: (setIndex, weight, reps, durationSeconds, distance) {
            notifier.updateSet(index, setIndex,
                weight: weight, reps: reps, durationSeconds: durationSeconds, distance: distance);
          },
          onCopyFromPrevious: (setIndex) {
            notifier.copyFromPrevious(index, setIndex);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Set duplicated'),
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
              child: Builder(
                builder: (context) {
                  final tutorialState = ref.watch(interactiveTutorialProvider);
                  final isStep6Active = tutorialState.isActive &&
                      tutorialState.currentStep == TutorialStep.workoutComplete;
                  return ElevatedButton(
                    key: isStep6Active ? _completeButtonKey : null,
                    onPressed: _completeWorkout,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Complete'),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadRoutineIntoWorkout(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final routine = await showModalBottomSheet<RoutineTemplateEntity>(
      context: context,
      builder: (context) => const RoutineSelectorModal(),
    );

    if (routine == null || !context.mounted) return;

    // Confirm if exercises already exist
    final workoutState = ref.read(workoutInputProvider(widget.sessionId));
    if (workoutState.exercises.isNotEmpty) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          content: Text(l10n.routineLoadConfirm),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.cancelButton),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l10n.confirmButton),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    await ref
        .read(workoutInputProvider(widget.sessionId).notifier)
        .loadFromRoutine(routine.id!);
  }

  Future<void> _showExerciseSelector() async {
    final exerciseMasterDao = ref.read(exerciseMasterDaoProvider);
    final tutorialState = ref.watch(interactiveTutorialProvider);
    final isStep2Active = tutorialState.isActive &&
        tutorialState.currentStep == TutorialStep.workoutAddExercise;

    if (!mounted) return;

    final exercise = await showModalBottomSheet<ExerciseMasterEntity>(
      context: context,
      isScrollControlled: true,
      builder: (context) => ExerciseSelectorModal(
        exerciseMasterDao: exerciseMasterDao,
        isTutorialMode: isStep2Active,
      ),
    );

    if (exercise != null) {
        final notifier =
            ref.read(workoutInputProvider(widget.sessionId).notifier);
        final added = await notifier.addExercise(exercise);

        if (!mounted) return;
        if (!added) {
          final l10n = AppLocalizations.of(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n?.exerciseAlreadyAdded ?? 'Already added'),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }

        // Track the newly added exercise index for auto-focus and scroll
        final workoutState = ref.read(workoutInputProvider(widget.sessionId));
        setState(() {
          _newlyAddedExerciseIndex = workoutState.exercises.length - 1;
        });

        // Scroll to the newly added exercise
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });

        // Complete step 2 when exercise is added
        if (isStep2Active) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              ref.read(interactiveTutorialProvider.notifier).completeCurrentStep();
            }
          });
        }
    }
  }

  Widget _buildTutorialOverlay(
    BuildContext context,
    WidgetRef ref,
    WorkoutInputState workoutState,
  ) {
    final tutorialState = ref.watch(interactiveTutorialProvider);
    final currentLanguage = ref.watch(currentLanguageProvider);
    final isJapanese = currentLanguage == 'ja';

    // Check if tutorial was just completed
    if (tutorialState.isCompleted && tutorialState.currentStep == null) {
      // Save tutorial completion
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (mounted) {
          await ref.read(settingsNotifierProvider.notifier).markTutorialCompleted();
          ref.read(interactiveTutorialProvider.notifier).endTutorial();
        }
      });
      return const SizedBox.shrink();
    }

    if (!tutorialState.isActive) {
      return const SizedBox.shrink();
    }

    // Step 2: Add exercise button (empty state). In tutorial we show empty state immediately so !isLoading is not required.
    if (tutorialState.currentStep == TutorialStep.workoutAddExercise &&
        workoutState.exercises.isEmpty &&
        (!workoutState.isLoading || widget.isTutorialMode)) {
      return Positioned.fill(
        child: TutorialOverlay(
          targetKey: _addExerciseButtonKey,
          tooltipMessage: isJapanese
              ? '種目を追加しましょう'
              : 'Add an exercise to start',
          onSkip: () {
            ref.read(interactiveTutorialProvider.notifier).skipTutorial();
          },
        ),
      );
    }

    // Step 3: Input set (when exercise exists)
    if (tutorialState.currentStep == TutorialStep.workoutInputSet &&
        workoutState.exercises.isNotEmpty) {
      return Positioned.fill(
        child: TutorialOverlay(
          targetKey: _setInputKey,
          tooltipMessage: isJapanese
              ? '重量と回数を入力しましょう'
              : 'Enter weight and reps',
          onSkip: () {
            ref.read(interactiveTutorialProvider.notifier).skipTutorial();
          },
        ),
      );
    }

    // Step 6: Complete button (after set input)
    if (tutorialState.currentStep == TutorialStep.workoutComplete &&
        workoutState.exercises.isNotEmpty) {
      return Positioned.fill(
        child: TutorialOverlay(
          targetKey: _completeButtonKey,
          tooltipMessage: isJapanese
              ? '記録完了をタップしましょう'
              : 'Tap Complete to finish',
          onSkip: () {
            ref.read(interactiveTutorialProvider.notifier).skipTutorial();
          },
        ),
      );
    }

    return const SizedBox.shrink();
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
    // Use isTutorialMode so we always do tutorial completion (delete session, etc.) when this screen was opened in tutorial mode,
    // even if tutorial state was reset (e.g. after hot reload).
    final isTutorialMode = widget.isTutorialMode;
    final tutorialState = ref.read(interactiveTutorialProvider);
    final isTutorialActive = tutorialState.isActive;

    if (isTutorialMode || isTutorialActive) {
      // Remove tutorial overlay first so the completion dialog is not blocked
      ref.read(interactiveTutorialProvider.notifier).endTutorial();
      // Yield to next frame so overlay removal runs, then show dialog (OK button must be tappable)
      await Future<void>.delayed(Duration.zero);
      final l10n = AppLocalizations.of(context)!;
      bool? confirmed;
      if (mounted) {
        confirmed = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: Text(l10n.tutorialCompletionTitle),
            content: Text(l10n.tutorialCompletionMessage),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(l10n.confirmButton),
              ),
            ],
          ),
        );
      }
      if (!mounted || confirmed != true) return;

      // Delete tutorial session and all its data so "記録中の続き" does not appear and tutorial data is removed
      final sessionNotifier = ref.read(workoutSessionNotifierProvider.notifier);
      await sessionNotifier.deleteSession(widget.sessionId);

      if (!mounted) return;
      await ref.read(settingsNotifierProvider.notifier).markTutorialCompleted();
      // Invalidate workout input cache for this session so it doesn't hold stale data
      ref.invalidate(workoutInputProvider(widget.sessionId));

      if (mounted) {
        Navigator.of(context).pop();
      }
      return;
    }

    // Normal flow: save and complete session
    final notifier = ref.read(workoutInputProvider(widget.sessionId).notifier);
    await notifier.saveAll();

    final achievedGoals = ref.read(workoutInputProvider(widget.sessionId)).achievedGoalsInLastSave;

    final sessionNotifier = ref.read(workoutSessionNotifierProvider.notifier);
    await sessionNotifier.completeSession(widget.sessionId);

    if (!mounted) return;

    // Show completion modal (muscle message + summary + achieved goals)
    final unit = ref.read(currentUnitProvider);
    final lang = ref.read(currentLanguageProvider);
    final completionResult = await MuscleMessageService().buildCompletionResult(
      sessionId: widget.sessionId,
      unit: unit,
      language: lang,
      achievedGoals: achievedGoals,
    );

    if (!mounted) return;
    await WorkoutCompletionModal.show(context, result: completionResult);

    if (mounted) {
      final reviewService = ReviewPromptService();
      final newCount = await reviewService.incrementCompletionCount();
      if (newCount >= 3 && !(await reviewService.hasAlreadyShownPrompt())) {
        await reviewService.markPromptShown();
        if (!mounted) return;
        final l10n = AppLocalizations.of(context)!;
        final writeReview = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(l10n.reviewPromptTitle),
            content: Text(l10n.reviewPromptMessage),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text(l10n.reviewPromptLater),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: Text(l10n.reviewPromptWriteReview),
              ),
            ],
          ),
        );
        if (writeReview == true) {
          await reviewService.requestReview();
        }
      }
      ref.invalidate(recentWorkoutItemsProvider);
      ref.invalidate(recentWorkoutsProvider);
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
