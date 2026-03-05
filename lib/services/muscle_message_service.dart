import '../data/dao/exercise_master_dao.dart';
import '../data/dao/set_record_dao.dart';
import '../data/dao/workout_exercise_dao.dart';
import '../data/dao/workout_session_dao.dart';
import '../data/localization/exercise_localization.dart';
import '../features/workout_completion/models/workout_completion_result.dart';

/// Service for selecting muscle-themed messages and building completion summary.
class MuscleMessageService {
  final WorkoutSessionDao _sessionDao = WorkoutSessionDao();
  final SetRecordDao _setRecordDao = SetRecordDao();
  final WorkoutExerciseDao _workoutExerciseDao = WorkoutExerciseDao();
  final ExerciseMasterDao _exerciseMasterDao = ExerciseMasterDao();

  /// Build completion result for workout done screen (Proposal 1).
  /// Call after session is completed (DB status = completed).
  /// [achievedGoals] goals achieved in this session (shown in completion modal).
  Future<WorkoutCompletionResult> buildCompletionResult({
    required int sessionId,
    required String unit,
    String language = 'ja',
    List<GoalAchievedDisplay> achievedGoals = const [],
  }) async {
    final workoutExercises =
        await _workoutExerciseDao.getExercisesBySessionId(sessionId);
    final exerciseCount = workoutExercises.length;

    int setCount = 0;
    final List<ExerciseSummaryItem> details = [];

    for (final we in workoutExercises) {
      if (we.id == null) continue;

      final sets = await _setRecordDao.getSetsByWorkoutExerciseId(we.id!);
      final weightSets = sets.where((s) => s.reps != null && s.reps! > 0).toList();
      final timeSets = sets
          .where((s) =>
              s.durationSeconds != null && s.durationSeconds! > 0)
          .toList();
      final thisSetCount = weightSets.length + timeSets.length;
      setCount += thisSetCount;

      final master = await _exerciseMasterDao.getExerciseById(we.exerciseId);
      final name = master != null
          ? ExerciseLocalization.getLocalizedName(
              englishName: master.name,
              language: language,
              isStandard: master.isCustom == 0,
            )
          : '';

      final isTimeBased = master?.recordType == 'time';
      double? topWeight;
      int? topDuration;

      if (isTimeBased && timeSets.isNotEmpty) {
        topDuration = timeSets
            .map((s) => s.durationSeconds ?? 0)
            .reduce((a, b) => a > b ? a : b);
      } else if (weightSets.isNotEmpty) {
        topWeight = await _setRecordDao.getTopWeightForExerciseInSession(
          we.exerciseId,
          sessionId,
          unit,
        );
      }

      details.add(ExerciseSummaryItem(
        name: name,
        setCount: thisSetCount,
        topWeight: topWeight,
        topDurationSeconds: topDuration,
        isTimeBased: isTimeBased,
      ));
    }

    final totalVolume =
        await _setRecordDao.getTotalVolumeForSession(sessionId, unit);
    final streak = await _sessionDao.getCurrentStreak();
    final weeklyCount = await _sessionDao.countSessionsThisWeek();

    double? previousVolume;
    final sessions = await _sessionDao.getCompletedSessions(limit: 3);
    if (sessions.length >= 2) {
      final prevSessionId = sessions[1].id;
      if (prevSessionId != null) {
        previousVolume =
            await _setRecordDao.getTotalVolumeForSession(prevSessionId, unit);
      }
    }

    final message = _selectCompletionMessage(
      streak: streak,
      weeklyCount: weeklyCount,
      totalVolume: totalVolume,
      previousVolume: previousVolume,
      language: language,
    );

    return WorkoutCompletionResult(
      sessionId: sessionId,
      exerciseCount: exerciseCount,
      setCount: setCount,
      totalVolume: totalVolume,
      message: message,
      streak: streak,
      weeklyCount: weeklyCount,
      unit: unit,
      exerciseDetails: details,
      achievedGoals: achievedGoals,
    );
  }

  /// Select one message for completion screen. Priority order.
  String _selectCompletionMessage({
    required int streak,
    required int weeklyCount,
    required double totalVolume,
    double? previousVolume,
    String language = 'ja',
  }) {
    final isJa = language == 'ja';
    if (streak >= 2) {
      return isJa
          ? '$streak日連続。習慣、ついてきてる。'
          : '$streak days in a row. Your habit is sticking.';
    }
    if (weeklyCount >= 2) {
      return isJa
          ? '今週$weeklyCount回目。いいペース。'
          : '$weeklyCount workouts this week. Good pace.';
    }
    if (previousVolume != null &&
        previousVolume > 0 &&
        totalVolume > previousVolume) {
      return isJa
          ? '前回よりボリュームアップ。成長してる。'
          : 'More volume than last time. You\'re growing.';
    }
    return isJa
        ? '筋肉から: 今日もありがとう。また次もコツコツ。'
        : 'From your muscles: Thanks for today. Keep going.';
  }

}
