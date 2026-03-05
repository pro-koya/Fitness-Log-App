import '../features/exercise_progress/providers/exercise_progress_provider.dart';

/// X軸の集約単位（グラフの1点が表す期間）
enum ChartXAxisBucket {
  day,
  twoDays,
  week,
  twoWeeks,
  month,
  threeMonths,
  fourMonths,
}

extension ChartXAxisBucketExtension on ChartXAxisBucket {
  /// 日付が属するバケットの開始日を返す（UTC日付で比較用）
  DateTime bucketStart(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    switch (this) {
      case ChartXAxisBucket.day:
        return d;
      case ChartXAxisBucket.twoDays:
        final epochDays = d.millisecondsSinceEpoch ~/ 86400000;
        final bucket = (epochDays ~/ 2) * 2;
        return DateTime.fromMillisecondsSinceEpoch(bucket * 86400000);
      case ChartXAxisBucket.week:
        final weekday = d.weekday;
        return d.subtract(Duration(days: weekday - 1));
      case ChartXAxisBucket.twoWeeks:
        final epochDays = d.millisecondsSinceEpoch ~/ 86400000;
        final bucket = (epochDays ~/ 14) * 14;
        return DateTime.fromMillisecondsSinceEpoch(bucket * 86400000);
      case ChartXAxisBucket.month:
        return DateTime(d.year, d.month, 1);
      case ChartXAxisBucket.threeMonths:
        final quarterMonth = ((d.month - 1) ~/ 3) * 3 + 1;
        return DateTime(d.year, quarterMonth, 1);
      case ChartXAxisBucket.fourMonths:
        final fourMonth = ((d.month - 1) ~/ 4) * 4 + 1;
        return DateTime(d.year, fourMonth, 1);
    }
  }
}

/// 筋トレ成長グラフ用: 期間ごとのX軸バケット
ChartXAxisBucket workoutBucketForPeriod(ProgressPeriod period) {
  switch (period) {
    case ProgressPeriod.oneWeek:
    case ProgressPeriod.oneMonth:
      return ChartXAxisBucket.day;
    case ProgressPeriod.threeMonths:
    case ProgressPeriod.sixMonths:
      return ChartXAxisBucket.week;
    case ProgressPeriod.oneYear:
      return ChartXAxisBucket.month;
    case ProgressPeriod.threeYears:
      return ChartXAxisBucket.threeMonths;
    case ProgressPeriod.fiveYears:
      return ChartXAxisBucket.fourMonths;
    case ProgressPeriod.all:
      return ChartXAxisBucket.month;
  }
}

/// 体重グラフ用: 期間ごとのX軸バケット
ChartXAxisBucket bodyWeightBucketForPeriod(ProgressPeriod period) {
  switch (period) {
    case ProgressPeriod.oneWeek:
      return ChartXAxisBucket.day;
    case ProgressPeriod.oneMonth:
      return ChartXAxisBucket.twoDays;
    case ProgressPeriod.threeMonths:
      return ChartXAxisBucket.week;
    case ProgressPeriod.sixMonths:
      return ChartXAxisBucket.twoWeeks;
    case ProgressPeriod.oneYear:
      return ChartXAxisBucket.month;
    case ProgressPeriod.threeYears:
      return ChartXAxisBucket.threeMonths;
    case ProgressPeriod.fiveYears:
      return ChartXAxisBucket.fourMonths;
    case ProgressPeriod.all:
      return ChartXAxisBucket.month;
  }
}

/// 筋トレ成長: バケット内で max(topWeight) を取る
List<ExerciseProgressDataPoint> aggregateWorkoutProgress(
  List<ExerciseProgressDataPoint> points,
  ChartXAxisBucket bucket,
) {
  if (bucket == ChartXAxisBucket.day || points.isEmpty) return points;

  final map = <int, ExerciseProgressDataPoint>{};
  for (final p in points) {
    final start = bucket.bucketStart(p.date);
    final key = start.millisecondsSinceEpoch;
    final existing = map[key];
    if (existing == null || p.topWeight > existing.topWeight) {
      map[key] = ExerciseProgressDataPoint(
        date: start,
        topWeight: p.topWeight,
        totalVolume: p.totalVolume,
        weight: p.weight,
        reps: p.reps,
      );
    }
  }

  final list = map.values.toList();
  list.sort((a, b) => a.date.compareTo(b.date));
  return list;
}

/// 体重: バケット内で最後の記録（日付が新しい方）を取る
List<ExerciseProgressDataPoint> aggregateBodyWeight(
  List<ExerciseProgressDataPoint> points,
  ChartXAxisBucket bucket,
) {
  if (bucket == ChartXAxisBucket.day || points.isEmpty) return points;

  final map = <int, ExerciseProgressDataPoint>{};
  for (final p in points) {
    final start = bucket.bucketStart(p.date);
    final key = start.millisecondsSinceEpoch;
    final existing = map[key];
    if (existing == null || p.date.isAfter(existing.date)) {
      map[key] = p;
    }
  }

  final list = map.values.toList();
  list.sort((a, b) => a.date.compareTo(b.date));
  return list;
}
