import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/dao/set_record_dao.dart';
import '../../../data/dao/workout_exercise_dao.dart';
import '../../../providers/settings_provider.dart';
import '../../../utils/chart_aggregation.dart';

/// 並べ替えオプション
enum HistorySortOption {
  dateDesc,      // 日付（新しい順）- デフォルト
  dateAsc,       // 日付（古い順）
  weightDesc,    // 重量（重い順）
  weightAsc,     // 重量（軽い順）
  repsDesc,      // 回数（多い順）
  repsAsc,       // 回数（少ない順）
  timeDesc,      // 時間（長い順）
  timeAsc,       // 時間（短い順）
  distanceDesc,  // 距離（長い順）
  distanceAsc,   // 距離（短い順）
}

/// Query key for fetching workout history with sorting
class ExerciseHistoryQuery {
  final int exerciseId;
  final HistorySortOption sortOption;

  const ExerciseHistoryQuery({
    required this.exerciseId,
    required this.sortOption,
  });

  @override
  bool operator ==(Object other) {
    return other is ExerciseHistoryQuery &&
        other.exerciseId == exerciseId &&
        other.sortOption == sortOption;
  }

  @override
  int get hashCode => Object.hash(exerciseId, sortOption);
}

/// 種目ごとの並べ替え状態を管理
final exerciseHistorySortProvider = StateProvider.family<HistorySortOption, int>(
  (ref, exerciseId) => HistorySortOption.dateDesc,
);

/// グラフ表示期間
enum ProgressPeriod {
  oneWeek,
  oneMonth,
  threeMonths,
  sixMonths,
  oneYear,
  threeYears,
  fiveYears,
  all,
}

extension ProgressPeriodExtension on ProgressPeriod {
  /// Returns the start date for this period, or null for 'all'.
  DateTime? getStartDate() {
    final now = DateTime.now();
    switch (this) {
      case ProgressPeriod.oneWeek:
        return now.subtract(const Duration(days: 7));
      case ProgressPeriod.oneMonth:
        return DateTime(now.year, now.month - 1, now.day);
      case ProgressPeriod.threeMonths:
        return DateTime(now.year, now.month - 3, now.day);
      case ProgressPeriod.sixMonths:
        return DateTime(now.year, now.month - 6, now.day);
      case ProgressPeriod.oneYear:
        return DateTime(now.year - 1, now.month, now.day);
      case ProgressPeriod.threeYears:
        return DateTime(now.year - 3, now.month, now.day);
      case ProgressPeriod.fiveYears:
        return DateTime(now.year - 5, now.month, now.day);
      case ProgressPeriod.all:
        return null;
    }
  }

  String get label {
    switch (this) {
      case ProgressPeriod.oneWeek: return '1W';
      case ProgressPeriod.oneMonth: return '1M';
      case ProgressPeriod.threeMonths: return '3M';
      case ProgressPeriod.sixMonths: return '6M';
      case ProgressPeriod.oneYear: return '1Y';
      case ProgressPeriod.threeYears: return '3Y';
      case ProgressPeriod.fiveYears: return '5Y';
      case ProgressPeriod.all: return 'ALL';
    }
  }
}

/// 種目ごとのグラフ表示期間を管理（成長遷移グラフは開いた際デフォルト3ヶ月）
final exerciseProgressPeriodProvider = StateProvider.family<ProgressPeriod, int>(
  (ref, exerciseId) => ProgressPeriod.threeMonths,
);

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
  final ProgressPeriod period;

  const ExerciseProgressQuery({
    required this.exerciseId,
    required this.metric,
    this.period = ProgressPeriod.all,
  });

  @override
  bool operator ==(Object other) {
    return other is ExerciseProgressQuery &&
        other.exerciseId == exerciseId &&
        other.metric == metric &&
        other.period == period;
  }

  @override
  int get hashCode => Object.hash(exerciseId, metric, period);
}

/// Provider for exercise progress data
final exerciseProgressProvider = FutureProvider.autoDispose.family<
    List<ExerciseProgressDataPoint>, ExerciseProgressQuery>(
  (ref, query) async {
    final setDao = SetRecordDao();

    // Get current unit from settings
    final settings = await ref.watch(settingsProvider.future);
    final unit = settings?.unit ?? 'kg';

    // Calculate start timestamp from period
    final startDate = query.period.getStartDate();
    final int? startTimestamp = startDate != null
        ? startDate.millisecondsSinceEpoch ~/ 1000
        : null;

    final List<Map<String, dynamic>> progressData;
    if (query.metric == 'time') {
      progressData = await setDao.getProgressDataForExerciseTime(
        query.exerciseId,
        startTimestamp: startTimestamp,
      );
    } else if (query.metric == 'reps') {
      progressData = await setDao.getProgressDataForExerciseReps(
        query.exerciseId,
        startTimestamp: startTimestamp,
      );
    } else if (query.metric == 'volume') {
      progressData = await setDao.getProgressDataForExerciseVolume(
        query.exerciseId,
        unit,
        startTimestamp: startTimestamp,
      );
    } else if (query.metric == 'cardio_time') {
      progressData = await setDao.getProgressDataForCardioTime(
        query.exerciseId,
        startTimestamp: startTimestamp,
      );
    } else if (query.metric == 'cardio_distance') {
      progressData = await setDao.getProgressDataForCardioDistance(
        query.exerciseId,
        startTimestamp: startTimestamp,
      );
    } else if (query.metric == 'cardio_pace') {
      progressData = await setDao.getProgressDataForCardioPace(
        query.exerciseId,
        startTimestamp: startTimestamp,
      );
    } else {
      // 'weight'
      progressData = await setDao.getProgressDataForExercise(
        query.exerciseId,
        unit,
        startTimestamp: startTimestamp,
      );
    }

    // Convert to data points
    final points = progressData.map((data) {
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

    final bucket = workoutBucketForPeriod(query.period);
    return aggregateWorkoutProgress(points, bucket);
  },
);

/// Model for memo history entry
class MemoHistoryEntry {
  final DateTime date;
  final String memo;
  // Workout data for sorting (from the same session)
  final double? maxWeight;
  final int? maxReps;
  final int? maxDuration;
  final double? totalDistance;

  MemoHistoryEntry({
    required this.date,
    required this.memo,
    this.maxWeight,
    this.maxReps,
    this.maxDuration,
    this.totalDistance,
  });
}

/// Provider for exercise memo history with sorting support
final exerciseMemoHistoryProvider = FutureProvider.autoDispose.family<
    List<MemoHistoryEntry>, ExerciseHistoryQuery>(
  (ref, query) async {
    final exerciseDao = WorkoutExerciseDao();
    final setDao = SetRecordDao();

    // Fetch memo history
    final memoData = await exerciseDao.getMemoHistoryForExercise(query.exerciseId);

    // Fetch workout history to get sorting data
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final historyData = await setDao.getAllHistoryForExercise(
      query.exerciseId,
      now,
      limit: 20,
    );

    // Create a map of date -> workout data for quick lookup
    final workoutDataByDate = <String, Map<String, dynamic>>{};
    for (final data in historyData) {
      final timestamp = data['completedAt'] as int;
      final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
      final dateKey = '${date.year}-${date.month}-${date.day}';
      final sets = (data['sets'] as List);

      // Calculate max values from sets
      double maxWeight = 0;
      int maxReps = 0;
      int maxDuration = 0;
      double totalDistance = 0;

      for (final setEntity in sets) {
        final s = setEntity as dynamic;
        final weight = (s.weightKg as double?) ?? 0;
        final reps = (s.reps as int?) ?? 0;
        final duration = (s.durationSeconds as int?) ?? 0;
        final distance = (s.distanceMeters as double?) ?? 0;

        if (weight > maxWeight) maxWeight = weight;
        if (reps > maxReps) maxReps = reps;
        if (duration > maxDuration) maxDuration = duration;
        totalDistance += distance;
      }

      workoutDataByDate[dateKey] = {
        'maxWeight': maxWeight,
        'maxReps': maxReps,
        'maxDuration': maxDuration,
        'totalDistance': totalDistance,
      };
    }

    final memos = memoData.map((data) {
      final timestamp = data['date'] as int;
      final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
      final memo = data['memo'] as String;
      final dateKey = '${date.year}-${date.month}-${date.day}';

      // Get workout data for this date
      final workoutData = workoutDataByDate[dateKey];

      return MemoHistoryEntry(
        date: date,
        memo: memo,
        maxWeight: workoutData?['maxWeight'] as double?,
        maxReps: workoutData?['maxReps'] as int?,
        maxDuration: workoutData?['maxDuration'] as int?,
        totalDistance: workoutData?['totalDistance'] as double?,
      );
    }).toList();

    // Apply sorting based on workout data
    return _sortMemoHistory(memos, query.sortOption);
  },
);

/// Sort memo history entries based on the selected option
/// Uses workout data from the same session for non-date sorting
List<MemoHistoryEntry> _sortMemoHistory(
  List<MemoHistoryEntry> memos,
  HistorySortOption sortOption,
) {
  final sorted = List<MemoHistoryEntry>.from(memos);

  switch (sortOption) {
    case HistorySortOption.dateDesc:
      sorted.sort((a, b) => b.date.compareTo(a.date));
      break;
    case HistorySortOption.dateAsc:
      sorted.sort((a, b) => a.date.compareTo(b.date));
      break;
    case HistorySortOption.weightDesc:
      sorted.sort((a, b) => (b.maxWeight ?? 0).compareTo(a.maxWeight ?? 0));
      break;
    case HistorySortOption.weightAsc:
      sorted.sort((a, b) => (a.maxWeight ?? 0).compareTo(b.maxWeight ?? 0));
      break;
    case HistorySortOption.repsDesc:
      sorted.sort((a, b) => (b.maxReps ?? 0).compareTo(a.maxReps ?? 0));
      break;
    case HistorySortOption.repsAsc:
      sorted.sort((a, b) => (a.maxReps ?? 0).compareTo(b.maxReps ?? 0));
      break;
    case HistorySortOption.timeDesc:
      sorted.sort((a, b) => (b.maxDuration ?? 0).compareTo(a.maxDuration ?? 0));
      break;
    case HistorySortOption.timeAsc:
      sorted.sort((a, b) => (a.maxDuration ?? 0).compareTo(b.maxDuration ?? 0));
      break;
    case HistorySortOption.distanceDesc:
      sorted.sort((a, b) => (b.totalDistance ?? 0).compareTo(a.totalDistance ?? 0));
      break;
    case HistorySortOption.distanceAsc:
      sorted.sort((a, b) => (a.totalDistance ?? 0).compareTo(b.totalDistance ?? 0));
      break;
  }

  return sorted;
}

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

/// Provider for exercise workout history with sorting support
final exerciseWorkoutHistoryProvider = FutureProvider.autoDispose.family<
    List<WorkoutHistoryEntry>, ExerciseHistoryQuery>(
  (ref, query) async {
    final setDao = SetRecordDao();

    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final historyData = await setDao.getAllHistoryForExercise(
      query.exerciseId,
      now,
      limit: 20,
    );

    final history = historyData.map((data) {
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

    // Apply sorting
    return _sortHistory(history, query.sortOption);
  },
);

/// Sort history entries based on the selected option
List<WorkoutHistoryEntry> _sortHistory(
  List<WorkoutHistoryEntry> history,
  HistorySortOption sortOption,
) {
  final sorted = List<WorkoutHistoryEntry>.from(history);

  switch (sortOption) {
    case HistorySortOption.dateDesc:
      sorted.sort((a, b) => b.date.compareTo(a.date));
      break;
    case HistorySortOption.dateAsc:
      sorted.sort((a, b) => a.date.compareTo(b.date));
      break;
    case HistorySortOption.weightDesc:
      sorted.sort((a, b) => _getMaxWeight(b).compareTo(_getMaxWeight(a)));
      break;
    case HistorySortOption.weightAsc:
      sorted.sort((a, b) => _getMaxWeight(a).compareTo(_getMaxWeight(b)));
      break;
    case HistorySortOption.repsDesc:
      sorted.sort((a, b) => _getMaxReps(b).compareTo(_getMaxReps(a)));
      break;
    case HistorySortOption.repsAsc:
      sorted.sort((a, b) => _getMaxReps(a).compareTo(_getMaxReps(b)));
      break;
    case HistorySortOption.timeDesc:
      sorted.sort((a, b) => _getMaxDuration(b).compareTo(_getMaxDuration(a)));
      break;
    case HistorySortOption.timeAsc:
      sorted.sort((a, b) => _getMaxDuration(a).compareTo(_getMaxDuration(b)));
      break;
    case HistorySortOption.distanceDesc:
      sorted.sort((a, b) => _getTotalDistance(b).compareTo(_getTotalDistance(a)));
      break;
    case HistorySortOption.distanceAsc:
      sorted.sort((a, b) => _getTotalDistance(a).compareTo(_getTotalDistance(b)));
      break;
  }

  return sorted;
}

/// Get maximum weight from a workout entry
double _getMaxWeight(WorkoutHistoryEntry entry) {
  if (entry.sets.isEmpty) return 0;
  return entry.sets
      .map((s) => s.weightKg ?? 0)
      .fold(0.0, (a, b) => a > b ? a : b);
}

/// Get maximum reps from a workout entry
int _getMaxReps(WorkoutHistoryEntry entry) {
  if (entry.sets.isEmpty) return 0;
  return entry.sets
      .map((s) => s.reps ?? 0)
      .fold(0, (a, b) => a > b ? a : b);
}

/// Get maximum duration from a workout entry
int _getMaxDuration(WorkoutHistoryEntry entry) {
  if (entry.sets.isEmpty) return 0;
  return entry.sets
      .map((s) => s.durationSeconds ?? 0)
      .fold(0, (a, b) => a > b ? a : b);
}

/// Get total distance from a workout entry
double _getTotalDistance(WorkoutHistoryEntry entry) {
  if (entry.sets.isEmpty) return 0;
  return entry.sets
      .map((s) => s.distanceMeters ?? 0)
      .fold(0.0, (a, b) => a + b);
}
