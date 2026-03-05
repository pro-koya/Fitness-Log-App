import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Event when a user achieves an exercise goal (Pro). UI shows SnackBar and clears.
class GoalAchievedEvent {
  final String exerciseName;
  final String valueStr;

  const GoalAchievedEvent({required this.exerciseName, required this.valueStr});
}

final goalAchievedEventProvider = StateProvider<GoalAchievedEvent?>((ref) => null);
