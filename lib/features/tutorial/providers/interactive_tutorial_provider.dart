import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/tutorial_step.dart';

/// State for interactive tutorial
class InteractiveTutorialState {
  final TutorialStep? currentStep;
  final Set<TutorialStep> completedSteps;
  final bool isActive;

  const InteractiveTutorialState({
    this.currentStep,
    this.completedSteps = const {},
    this.isActive = false,
  });

  InteractiveTutorialState copyWith({
    TutorialStep? currentStep,
    Set<TutorialStep>? completedSteps,
    bool? isActive,
  }) {
    return InteractiveTutorialState(
      currentStep: currentStep ?? this.currentStep,
      completedSteps: completedSteps ?? this.completedSteps,
      isActive: isActive ?? this.isActive,
    );
  }

  /// Check if a step is completed
  bool isStepCompleted(TutorialStep step) {
    return completedSteps.contains(step);
  }

  /// Check if tutorial is completed
  bool get isCompleted {
    return completedSteps.length >= TutorialStep.values.length;
  }
}

/// Notifier for interactive tutorial
class InteractiveTutorialNotifier
    extends StateNotifier<InteractiveTutorialState> {
  InteractiveTutorialNotifier() : super(const InteractiveTutorialState());

  /// Start tutorial from the first step
  void startTutorial() {
    state = InteractiveTutorialState(
      currentStep: TutorialStep.homeStartWorkout,
      completedSteps: const {},
      isActive: true,
    );
  }

  /// Complete current step and move to next
  void completeCurrentStep() {
    if (state.currentStep == null) return;

    final currentStep = state.currentStep!;
    final newCompletedSteps = {...state.completedSteps, currentStep};

    if (currentStep.isLastStep) {
      // Tutorial completed
      state = state.copyWith(
        currentStep: null,
        completedSteps: newCompletedSteps,
        isActive: false,
      );
    } else {
      // Move to next step
      final nextStep = currentStep.nextStep;
      state = state.copyWith(
        currentStep: nextStep,
        completedSteps: newCompletedSteps,
        isActive: true,
      );
    }
  }

  /// Complete current step and jump directly to target step (skipping intermediate steps)
  void completeStepAndJumpTo(TutorialStep targetStep) {
    if (state.currentStep == null) return;

    final currentStep = state.currentStep!;
    final newCompletedSteps = {...state.completedSteps, currentStep};

    state = state.copyWith(
      currentStep: targetStep,
      completedSteps: newCompletedSteps,
      isActive: true,
    );
  }

  /// Skip current step
  void skipCurrentStep() {
    if (state.currentStep == null) return;

    final currentStep = state.currentStep!;
    final newCompletedSteps = {...state.completedSteps, currentStep};

    if (currentStep.isLastStep) {
      // Tutorial completed
      state = state.copyWith(
        currentStep: null,
        completedSteps: newCompletedSteps,
        isActive: false,
      );
    } else {
      // Move to next step
      final nextStep = currentStep.nextStep;
      state = state.copyWith(
        currentStep: nextStep,
        completedSteps: newCompletedSteps,
        isActive: true,
      );
    }
  }

  /// Skip entire tutorial
  void skipTutorial() {
    state = const InteractiveTutorialState(
      currentStep: null,
      completedSteps: {},
      isActive: false,
    );
  }

  /// End tutorial (called when tutorial is completed)
  void endTutorial() {
    state = state.copyWith(
      currentStep: null,
      isActive: false,
    );
  }
}

/// Provider for interactive tutorial
final interactiveTutorialProvider =
    StateNotifierProvider<InteractiveTutorialNotifier, InteractiveTutorialState>(
  (ref) => InteractiveTutorialNotifier(),
);
