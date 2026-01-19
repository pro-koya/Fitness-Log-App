import '../../../data/entities/workout_session_entity.dart';
import '../../../data/entities/workout_exercise_entity.dart';
import '../../../data/entities/set_record_entity.dart';
import '../../../utils/date_formatter.dart';

/// Model for displaying workout detail
class WorkoutDetailModel {
  final WorkoutSessionEntity session;
  final List<ExerciseDetailModel> exercises;

  WorkoutDetailModel({
    required this.session,
    required this.exercises,
  });

  /// Get formatted session time (e.g., "14:32 - 15:45")
  String getFormattedSessionTime() {
    if (session.startedAt == null || session.completedAt == null) {
      return '';
    }

    final startTime = DateTime.fromMillisecondsSinceEpoch(
      session.startedAt! * 1000,
    );
    final endTime = DateTime.fromMillisecondsSinceEpoch(
      session.completedAt! * 1000,
    );

    final startStr = '${startTime.hour.toString().padLeft(2, '0')}:'
        '${startTime.minute.toString().padLeft(2, '0')}';
    final endStr = '${endTime.hour.toString().padLeft(2, '0')}:'
        '${endTime.minute.toString().padLeft(2, '0')}';

    return '$startStr - $endStr';
  }

  /// Get formatted date (from session completed_at)
  String getFormattedDate() {
    if (session.completedAt == null) {
      return '';
    }

    final date = DateTime.fromMillisecondsSinceEpoch(
      session.completedAt! * 1000,
    );

    return '${date.year}年${date.month}月${date.day}日';
  }

  /// Get total exercise count
  int get totalExercises => exercises.length;

  /// Get total set count
  int get totalSets =>
      exercises.fold(0, (sum, exercise) => sum + exercise.sets.length);
}

/// Model for each exercise in workout detail
class ExerciseDetailModel {
  final WorkoutExerciseEntity exercise;
  final List<SetRecordEntity> sets;
  final String exerciseName;
  final String recordType;

  ExerciseDetailModel({
    required this.exercise,
    required this.sets,
    required this.exerciseName,
    this.recordType = 'reps',
  });

  /// Get memo for this exercise
  String? get memo => exercise.memo;

  /// Get formatted sets string (e.g., "40kg×10 / 40kg×10 / 35kg×12" or "0kg×1m30s")
  /// unit: 'kg' or 'lb', distanceUnit: 'km' or 'mile'
  String getFormattedSets(String unit, {String distanceUnit = 'km'}) {
    if (sets.isEmpty) {
      return '';
    }

    return sets
        .map((set) {
          // Cardio: show time/distance format (e.g., "30m/3km" or "30m" or "3km")
          if (recordType == 'cardio') {
            return _formatCardioSet(set, distanceUnit);
          }

          final weight = set.getWeight(unit);
          final weightStr =
              weight.toStringAsFixed(weight == weight.toInt() ? 0 : 1);

          // Format value as reps or duration
          String valueStr;
          if (set.durationSeconds != null && set.durationSeconds! > 0) {
            final minutes = set.durationSeconds! ~/ 60;
            final seconds = set.durationSeconds! % 60;
            valueStr = minutes > 0 ? '${minutes}m${seconds}s' : '${seconds}s';
          } else {
            valueStr = '${set.reps ?? 0}';
          }

          return '$weightStr$unit×$valueStr';
        })
        .join(' / ');
  }

  /// Format cardio set (time/distance)
  String _formatCardioSet(SetRecordEntity set, String distanceUnit) {
    final hasDuration = set.durationSeconds != null && set.durationSeconds! > 0;
    final hasDistance = set.distanceMeters != null && set.distanceMeters! > 0;

    String timeStr = '';
    if (hasDuration) {
      final totalMinutes = set.durationSeconds! ~/ 60;
      final seconds = set.durationSeconds! % 60;
      if (totalMinutes >= 60) {
        final hours = totalMinutes ~/ 60;
        final minutes = totalMinutes % 60;
        timeStr = '${hours}h${minutes}m';
      } else if (totalMinutes > 0) {
        timeStr = seconds > 0 ? '${totalMinutes}m${seconds}s' : '${totalMinutes}m';
      } else {
        timeStr = '${seconds}s';
      }
    }

    String distStr = '';
    if (hasDistance) {
      final distance = set.getDistance(distanceUnit);
      if (distance != null) {
        // Format distance: show as integer if whole number, otherwise 2 decimals
        distStr = distance == distance.toInt()
            ? '${distance.toInt()}$distanceUnit'
            : '${distance.toStringAsFixed(2)}$distanceUnit';
      }
    }

    // Combine time and distance
    if (timeStr.isNotEmpty && distStr.isNotEmpty) {
      return '$timeStr/$distStr';
    } else if (timeStr.isNotEmpty) {
      return timeStr;
    } else if (distStr.isNotEmpty) {
      return distStr;
    } else {
      return '-';
    }
  }

  /// Get set count
  int get setCount => sets.length;
}
