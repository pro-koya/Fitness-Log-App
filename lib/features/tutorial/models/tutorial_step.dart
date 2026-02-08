/// Tutorial step model
enum TutorialStep {
  /// Step 1: Home screen - Start workout button
  homeStartWorkout,

  /// Step 2: Workout input screen - Add exercise
  workoutAddExercise,

  /// Step 3: Workout input screen - Input set (weight and reps)
  workoutInputSet,

  /// Step 4: Workout input screen - Copy previous record
  workoutCopyPrevious,

  /// Step 5: Workout input screen - Timer feature
  workoutTimer,

  /// Step 6: Workout input screen - Complete workout
  workoutComplete,
}

extension TutorialStepExtension on TutorialStep {
  /// Get step index (0-based)
  int get index {
    switch (this) {
      case TutorialStep.homeStartWorkout:
        return 0;
      case TutorialStep.workoutAddExercise:
        return 1;
      case TutorialStep.workoutInputSet:
        return 2;
      case TutorialStep.workoutCopyPrevious:
        return 3;
      case TutorialStep.workoutTimer:
        return 4;
      case TutorialStep.workoutComplete:
        return 5;
    }
  }

  /// Get total number of steps
  static int get totalSteps => TutorialStep.values.length;

  /// Get next step (null if this is the last step)
  TutorialStep? get nextStep {
    final currentIndex = index;
    if (currentIndex >= TutorialStep.values.length - 1) {
      return null;
    }
    return TutorialStep.values[currentIndex + 1];
  }

  /// Check if this is the last step
  bool get isLastStep => index >= TutorialStep.values.length - 1;
}
