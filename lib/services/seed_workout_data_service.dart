import 'dart:math';
import '../data/dao/exercise_master_dao.dart';
import '../data/dao/workout_exercise_dao.dart';
import '../data/dao/workout_session_dao.dart';
import '../data/dao/set_record_dao.dart';
import '../data/database/unit_converter.dart';
import '../data/entities/exercise_master_entity.dart';
import '../data/entities/workout_exercise_entity.dart';
import '../data/entities/workout_session_entity.dart';
import '../data/entities/set_record_entity.dart';

/// グラフ動作確認用に、各種目の筋トレ履歴データを登録するサービス。
/// デバッグビルドでのみ利用想定。
class SeedWorkoutDataService {
  SeedWorkoutDataService({
    ExerciseMasterDao? exerciseMasterDao,
    WorkoutSessionDao? workoutSessionDao,
    WorkoutExerciseDao? workoutExerciseDao,
    SetRecordDao? setRecordDao,
  })  : _exerciseMasterDao = exerciseMasterDao ?? ExerciseMasterDao(),
        _workoutSessionDao = workoutSessionDao ?? WorkoutSessionDao(),
        _workoutExerciseDao = workoutExerciseDao ?? WorkoutExerciseDao(),
        _setRecordDao = setRecordDao ?? SetRecordDao();

  final ExerciseMasterDao _exerciseMasterDao;
  final WorkoutSessionDao _workoutSessionDao;
  final WorkoutExerciseDao _workoutExerciseDao;
  final SetRecordDao _setRecordDao;

  final _random = Random(42); // 固定シードで再現可能に

  /// 各種目に対して、過去約5年分の履歴を登録する。
  /// 1M / 3M / 6M / 1Y / 3Y / 5Y の各期間でグラフにポイントが乗るようにする。
  Future<int> seedAllExercises() async {
    final exercises = await _exerciseMasterDao.getAllExercises();
    if (exercises.isEmpty) return 0;

    int sessionCount = 0;
    // 過去約5年分をカバー: 約20〜24回/種目（約2〜3ヶ月に1回ペース）
    const sessionsPerExercise = 24;
    final now = DateTime.now();

    for (final exercise in exercises) {
      final count = await _seedExercise(
        exercise,
        sessionsPerExercise: sessionsPerExercise,
        endDate: now,
      );
      sessionCount += count;
    }

    return sessionCount;
  }

  /// 1種目分の履歴を登録する。
  Future<int> _seedExercise(
    ExerciseMasterEntity exercise, {
    required int sessionsPerExercise,
    required DateTime endDate,
  }) async {
    final exerciseId = exercise.id!;
    final recordType = exercise.recordType;
    int count = 0;

    // 過去約5年から endDate まで均等に日付を配置
    final startDate = endDate.subtract(const Duration(days: 5 * 365));
    final stepDays = (endDate.difference(startDate).inDays / (sessionsPerExercise - 1)).floor();

    for (int i = 0; i < sessionsPerExercise; i++) {
      final sessionDate = startDate.add(Duration(days: i * stepDays));
      if (sessionDate.isAfter(endDate)) continue;

      final completedAt = sessionDate.millisecondsSinceEpoch ~/ 1000;
      final startedAt = completedAt - 45 * 60; // 45分前から開始

      final session = WorkoutSessionEntity(
        id: null,
        status: 'completed',
        startedAt: startedAt,
        completedAt: completedAt,
        createdAt: startedAt,
        updatedAt: completedAt,
      );
      final sessionId = await _workoutSessionDao.insertSession(session);

      final workoutExercise = WorkoutExerciseEntity(
        id: null,
        sessionId: sessionId,
        exerciseId: exerciseId,
        orderIndex: 0,
        memo: null,
        createdAt: startedAt,
        updatedAt: completedAt,
      );
      final workoutExerciseId = await _workoutExerciseDao.insertWorkoutExercise(workoutExercise);

      final sets = _generateSetsForRecordType(
        recordType: recordType,
        sessionId: sessionId,
        workoutExerciseId: workoutExerciseId,
        exerciseId: exerciseId,
        completedAt: completedAt,
        sessionIndex: i,
        totalSessions: sessionsPerExercise,
      );

      for (final setEntity in sets) {
        await _setRecordDao.insertSetRecord(setEntity);
      }
      count++;
    }

    return count;
  }

  List<SetRecordEntity> _generateSetsForRecordType({
    required String recordType,
    required int sessionId,
    required int workoutExerciseId,
    required int exerciseId,
    required int completedAt,
    required int sessionIndex,
    required int totalSessions,
  }) {
    if (recordType == 'cardio') {
      return _generateCardioSets(
        sessionId: sessionId,
        workoutExerciseId: workoutExerciseId,
        exerciseId: exerciseId,
        completedAt: completedAt,
        sessionIndex: sessionIndex,
        totalSessions: totalSessions,
      );
    }
    if (recordType == 'time') {
      return _generateTimeSets(
        sessionId: sessionId,
        workoutExerciseId: workoutExerciseId,
        exerciseId: exerciseId,
        completedAt: completedAt,
        sessionIndex: sessionIndex,
        totalSessions: totalSessions,
      );
    }
    // 'reps' (筋トレ)
    return _generateRepsSets(
      sessionId: sessionId,
      workoutExerciseId: workoutExerciseId,
      exerciseId: exerciseId,
      completedAt: completedAt,
      sessionIndex: sessionIndex,
      totalSessions: totalSessions,
    );
  }

  /// 筋トレ（重量×回数）用セットを生成。期間経過でわずかに progression するようにする。
  List<SetRecordEntity> _generateRepsSets({
    required int sessionId,
    required int workoutExerciseId,
    required int exerciseId,
    required int completedAt,
    required int sessionIndex,
    required int totalSessions,
  }) {
    final progress = (sessionIndex + 1) / totalSessions;
    final baseWeight = 20.0 + progress * 30.0 + _random.nextDouble() * 5;
    final baseReps = 8 + _random.nextInt(5);

    final weightKg = (baseWeight * 10).round() / 10.0;
    final weightLb = UnitConverter.kgToLb(weightKg);

    return [
      _setRecord(
        workoutExerciseId: workoutExerciseId,
        sessionId: sessionId,
        exerciseId: exerciseId,
        setNumber: 1,
        weightKg: weightKg * 0.9,
        weightLb: UnitConverter.kgToLb(weightKg * 0.9),
        reps: baseReps - 1,
        completedAt: completedAt,
      ),
      _setRecord(
        workoutExerciseId: workoutExerciseId,
        sessionId: sessionId,
        exerciseId: exerciseId,
        setNumber: 2,
        weightKg: weightKg,
        weightLb: weightLb,
        reps: baseReps,
        completedAt: completedAt,
      ),
      _setRecord(
        workoutExerciseId: workoutExerciseId,
        sessionId: sessionId,
        exerciseId: exerciseId,
        setNumber: 3,
        weightKg: weightKg * 0.95,
        weightLb: UnitConverter.kgToLb(weightKg * 0.95),
        reps: baseReps - 2,
        completedAt: completedAt,
      ),
    ];
  }

  /// 時間系（プランク等）用セットを生成。
  List<SetRecordEntity> _generateTimeSets({
    required int sessionId,
    required int workoutExerciseId,
    required int exerciseId,
    required int completedAt,
    required int sessionIndex,
    required int totalSessions,
  }) {
    final progress = (sessionIndex + 1) / totalSessions;
    final baseSeconds = 30 + (progress * 60).toInt() + _random.nextInt(20);

    return [
      _setRecord(
        workoutExerciseId: workoutExerciseId,
        sessionId: sessionId,
        exerciseId: exerciseId,
        setNumber: 1,
        weightKg: 0,
        weightLb: 0,
        durationSeconds: baseSeconds,
        completedAt: completedAt,
      ),
      _setRecord(
        workoutExerciseId: workoutExerciseId,
        sessionId: sessionId,
        exerciseId: exerciseId,
        setNumber: 2,
        weightKg: 0,
        weightLb: 0,
        durationSeconds: baseSeconds - 5,
        completedAt: completedAt,
      ),
    ];
  }

  /// カーディオ用セットを生成（時間 + 距離）。
  List<SetRecordEntity> _generateCardioSets({
    required int sessionId,
    required int workoutExerciseId,
    required int exerciseId,
    required int completedAt,
    required int sessionIndex,
    required int totalSessions,
  }) {
    final progress = (sessionIndex + 1) / totalSessions;
    final durationSeconds = 600 + (progress * 600).toInt() + _random.nextInt(300);
    final distanceMeters = 1000.0 + progress * 3000 + _random.nextDouble() * 500;

    return [
      _setRecord(
        workoutExerciseId: workoutExerciseId,
        sessionId: sessionId,
        exerciseId: exerciseId,
        setNumber: 1,
        weightKg: 0,
        weightLb: 0,
        durationSeconds: durationSeconds,
        distanceMeters: distanceMeters,
        completedAt: completedAt,
      ),
    ];
  }

  SetRecordEntity _setRecord({
    required int workoutExerciseId,
    required int sessionId,
    required int exerciseId,
    required int setNumber,
    required double weightKg,
    required double weightLb,
    int? reps,
    int? durationSeconds,
    double? distanceMeters,
    required int completedAt,
  }) {
    return SetRecordEntity(
      id: null,
      workoutExerciseId: workoutExerciseId,
      sessionId: sessionId,
      exerciseId: exerciseId,
      setNumber: setNumber,
      weightKg: weightKg,
      weightLb: weightLb,
      reps: reps,
      durationSeconds: durationSeconds,
      distanceMeters: distanceMeters,
      createdAt: completedAt,
      updatedAt: completedAt,
    );
  }
}
