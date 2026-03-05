import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/dao/body_weight_dao.dart';
import '../../../data/dao/workout_session_dao.dart';
import '../../../data/entities/body_weight_entity.dart';
import '../../../providers/database_providers.dart';
import '../../../providers/settings_provider.dart';
import '../../../utils/chart_aggregation.dart';
import '../../exercise_progress/providers/exercise_progress_provider.dart';

/// Period filter for body weight chart（体重遷移グラフは開いた際デフォルト1ヶ月）
final bodyWeightPeriodProvider = StateProvider<ProgressPeriod>(
  (ref) => ProgressPeriod.oneMonth,
);

/// Latest body weight record (for home screen card)
final latestBodyWeightProvider = FutureProvider.autoDispose<BodyWeightEntity?>((ref) async {
  ref.watch(databaseStateProvider);
  final dao = BodyWeightDao();
  return await dao.getLatest();
});

/// Previous body weight record (for home screen change arrow)
final previousBodyWeightProvider = FutureProvider.autoDispose<BodyWeightEntity?>((ref) async {
  ref.watch(databaseStateProvider);
  final dao = BodyWeightDao();
  return await dao.getPrevious();
});

/// Chart data for body weight (reuses ExerciseProgressDataPoint for ProgressChartWidget)
final bodyWeightChartProvider = FutureProvider.autoDispose<List<ExerciseProgressDataPoint>>((ref) async {
  ref.watch(databaseStateProvider);
  final period = ref.watch(bodyWeightPeriodProvider);
  final dao = BodyWeightDao();
  final settings = await ref.watch(settingsProvider.future);
  final unit = settings?.unit ?? 'kg';

  final startDate = period.getStartDate();
  final int? startTimestamp = startDate != null
      ? startDate.millisecondsSinceEpoch ~/ 1000
      : null;

  final records = await dao.getAll(startTimestamp: startTimestamp);

  final points = records.map((r) {
    final date = DateTime.fromMillisecondsSinceEpoch(r.recordedAt * 1000);
    final weight = r.getWeight(unit);
    return ExerciseProgressDataPoint(
      date: date,
      topWeight: weight,
      totalVolume: weight,
    );
  }).toList();

  final bucket = bodyWeightBucketForPeriod(period);
  return aggregateBodyWeight(points, bucket);
});

/// Summary statistics for body weight
class BodyWeightSummary {
  final int totalRecords;
  final double? currentWeight;
  final double? startingWeight;
  final double? totalChange;
  final double? minWeight;
  final double? maxWeight;
  // Monthly insight
  final int monthlyWorkoutCount;
  final double? monthlyWeightChange;

  const BodyWeightSummary({
    required this.totalRecords,
    this.currentWeight,
    this.startingWeight,
    this.totalChange,
    this.minWeight,
    this.maxWeight,
    required this.monthlyWorkoutCount,
    this.monthlyWeightChange,
  });
}

final bodyWeightSummaryProvider = FutureProvider.autoDispose<BodyWeightSummary>((ref) async {
  ref.watch(databaseStateProvider);
  final dao = BodyWeightDao();
  final settings = await ref.watch(settingsProvider.future);
  final unit = settings?.unit ?? 'kg';

  final count = await dao.getCount();
  final latest = await dao.getLatest();
  final first = await dao.getFirst();
  final minWeight = await dao.getMin(unit);
  final maxWeight = await dao.getMax(unit);

  double? currentWeight;
  double? startingWeight;
  double? totalChange;

  if (latest != null) {
    currentWeight = latest.getWeight(unit);
  }
  if (first != null) {
    startingWeight = first.getWeight(unit);
  }
  if (currentWeight != null && startingWeight != null) {
    totalChange = currentWeight - startingWeight;
  }

  // Monthly insight
  final now = DateTime.now();
  final workoutDao = WorkoutSessionDao();
  final monthlyWorkoutCount = await workoutDao.countSessionsInMonth(now.year, now.month);
  final monthlyWeightChange = await dao.getMonthlyChange(now.year, now.month, unit);

  return BodyWeightSummary(
    totalRecords: count,
    currentWeight: currentWeight,
    startingWeight: startingWeight,
    totalChange: totalChange,
    minWeight: minWeight,
    maxWeight: maxWeight,
    monthlyWorkoutCount: monthlyWorkoutCount,
    monthlyWeightChange: monthlyWeightChange,
  );
});

/// Body weight history (all records, newest first)
final bodyWeightHistoryProvider = FutureProvider.autoDispose<List<BodyWeightEntity>>((ref) async {
  ref.watch(databaseStateProvider);
  final dao = BodyWeightDao();
  return await dao.getAllDesc();
});
