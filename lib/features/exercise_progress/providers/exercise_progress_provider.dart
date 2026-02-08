import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/dao/set_record_dao.dart';
import '../../../data/dao/workout_exercise_dao.dart';
import '../../../providers/settings_provider.dart';

/// Model for exercise progress data point
class ExerciseProgressDataPoint {
  final DateTime date;
  final double topWeight;
  final double totalVolume;
  // For volume metric: weight and reps that achieved the max volume
  final double? weight;
  final int? reps;

  ExerciseProgressDataPoint({
    required this.date,
    required this.topWeight,
    required this.totalVolume,
    this.weight,
    this.reps,
  });
}

/// Query key for fetching progress data by metric.
/// metric: 'weight' | 'reps' | 'volume' | 'time' | 'cardio_time' | 'cardio_distance' | 'cardio_pace'
class ExerciseProgressQuery {
  final int exerciseId;
  final String metric;

  const ExerciseProgressQuery({
    required this.exerciseId,
    required this.metric,
  });

  @override
  bool operator ==(Object other) {
    return other is ExerciseProgressQuery &&
        other.exerciseId == exerciseId &&
        other.metric == metric;
  }

  @override
  int get hashCode => Object.hash(exerciseId, metric);
}

/// Provider for exercise progress data
final exerciseProgressProvider = FutureProvider.autoDispose.family<
    List<ExerciseProgressDataPoint>, ExerciseProgressQuery>(
  (ref, query) async {
    final setDao = SetRecordDao();

    // Get current unit from settings
    final settings = await ref.watch(settingsProvider.future);
    final unit = settings?.unit ?? 'kg';

    final List<Map<String, dynamic>> progressData;
    if (query.metric == 'time') {
      progressData =
          await setDao.getProgressDataForExerciseTime(query.exerciseId);
    } else if (query.metric == 'reps') {
      progressData =
          await setDao.getProgressDataForExerciseReps(query.exerciseId);
    } else if (query.metric == 'volume') {
      progressData = await setDao.getProgressDataForExerciseVolume(
        query.exerciseId,
        unit,
      );
    } else if (query.metric == 'cardio_time') {
      progressData =
          await setDao.getProgressDataForCardioTime(query.exerciseId);
    } else if (query.metric == 'cardio_distance') {
      progressData =
          await setDao.getProgressDataForCardioDistance(query.exerciseId);
    } else if (query.metric == 'cardio_pace') {
      progressData =
          await setDao.getProgressDataForCardioPace(query.exerciseId);
    } else {
      // 'weight'
      progressData = await setDao.getProgressDataForExercise(
        query.exerciseId,
        unit,
      );
    }

    // Convert to data points
    return progressData.map((data) {
      final timestamp = data['date'] as int;
      final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
      final double topWeight; // (chart value): weight OR reps OR volume OR seconds OR distance OR pace
      final double totalVolume; // (aux): total volume OR total reps OR total seconds
      if (query.metric == 'time') {
        topWeight = (data['topDurationSeconds'] as int).toDouble();
        totalVolume = (data['totalDurationSeconds'] as int).toDouble();
      } else if (query.metric == 'reps') {
        topWeight = (data['topReps'] as int).toDouble();
        totalVolume = (data['totalReps'] as int).toDouble();
      } else if (query.metric == 'volume') {
        topWeight = data['maxVolume'] as double;
        totalVolume = data['maxVolume'] as double; // Reuse for chart compatibility
      } else if (query.metric == 'cardio_time') {
        topWeight = (data['totalDurationSeconds'] as int).toDouble();
        totalVolume = topWeight;
      } else if (query.metric == 'cardio_distance') {
        // Store distance in meters, will be converted when displaying
        topWeight = data['totalDistanceMeters'] as double;
        totalVolume = topWeight;
      } else if (query.metric == 'cardio_pace') {
        // Speed in km/h
        topWeight = data['speedKmPerHour'] as double;
        totalVolume = topWeight;
      } else {
        topWeight = data['topWeight'] as double;
        totalVolume = data['totalVolume'] as double;
      }

      // For volume metric, include weight and reps
      if (query.metric == 'volume') {
        final weight = data['weight'] as double?;
        final reps = data['reps'] as int?;
        return ExerciseProgressDataPoint(
          date: date,
          topWeight: topWeight,
          totalVolume: totalVolume,
          weight: weight,
          reps: reps,
        );
      }

      return ExerciseProgressDataPoint(
        date: date,
        topWeight: topWeight,
        totalVolume: totalVolume,
      );
    }).toList();
  },
);

/// Model for memo history entry
class MemoHistoryEntry {
  final DateTime date;
  final String memo;

  MemoHistoryEntry({
    required this.date,
    required this.memo,
  });
}

/// Provider for exercise memo history
final exerciseMemoHistoryProvider = FutureProvider.autoDispose.family<
    List<MemoHistoryEntry>, int>(
  (ref, exerciseId) async {
    final exerciseDao = WorkoutExerciseDao();

    final memoData = await exerciseDao.getMemoHistoryForExercise(exerciseId);

    return memoData.map((data) {
      final timestamp = data['date'] as int;
      final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
      final memo = data['memo'] as String;

      return MemoHistoryEntry(
        date: date,
        memo: memo,
      );
    }).toList();
  },
);

/// Model for workout history entry (single session)
class WorkoutHistoryEntry {
  final int sessionId;
  final DateTime date;
  final List<WorkoutSetRecord> sets;

  WorkoutHistoryEntry({
    required this.sessionId,
    required this.date,
    required this.sets,
  });
}

/// Model for a set record in workout history
class WorkoutSetRecord {
  final int setNumber;
  final double? weightKg;
  final double? weightLb;
  final int? reps;
  final int? durationSeconds;
  final double? distanceMeters;

  WorkoutSetRecord({
    required this.setNumber,
    this.weightKg,
    this.weightLb,
    this.reps,
    this.durationSeconds,
    this.distanceMeters,
  });

  /// Get weight in specified unit
  double? getWeight(String unit) {
    if (unit == 'lb') return weightLb;
    return weightKg;
  }

  /// Get distance in specified unit
  double? getDistance(String distanceUnit) {
    if (distanceMeters == null) return null;
    if (distanceUnit == 'mile') {
      return distanceMeters! / 1609.34;
    }
    return distanceMeters! / 1000.0; // km
  }
}

/// Provider for exercise workout history
final exerciseWorkoutHistoryProvider = FutureProvider.autoDispose.family<
    List<WorkoutHistoryEntry>, int>(
  (ref, exerciseId) async {
    final setDao = SetRecordDao();

    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final historyData = await setDao.getAllHistoryForExercise(
      exerciseId,
      now,
      limit: 20,
    );

    return historyData.map((data) {
      final sessionId = data['sessionId'] as int;
      final timestamp = data['completedAt'] as int;
      final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
      final sets = (data['sets'] as List).map((setEntity) {
        final s = setEntity as dynamic;
        return WorkoutSetRecord(
          setNumber: s.setNumber,
          weightKg: s.weightKg,
          weightLb: s.weightLb,
          reps: s.reps,
          durationSeconds: s.durationSeconds,
          distanceMeters: s.distanceMeters,
        );
      }).toList();

      return WorkoutHistoryEntry(
        sessionId: sessionId,
        date: date,
        sets: sets,
      );
    }).toList();
  },
);
