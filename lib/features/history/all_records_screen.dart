import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/dao/exercise_master_dao.dart';
import '../../data/dao/set_record_dao.dart';
import '../../data/dao/workout_exercise_dao.dart';
import '../../data/entities/set_record_entity.dart';
import '../../data/entities/workout_session_entity.dart';
import '../../data/localization/exercise_localization.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/database_providers.dart';
import '../../providers/settings_provider.dart';
import '../../providers/workout_session_provider.dart';
import '../../utils/date_formatter.dart';
import '../workout_detail/workout_detail_screen.dart';

/// 1セッション内の1種目サマリー（カード用）
class _SessionExerciseSummary {
  final String name;
  final int setCount;
  final String topDisplay;

  _SessionExerciseSummary({
    required this.name,
    required this.setCount,
    required this.topDisplay,
  });
}

/// セッションIDごとに種目サマリー一覧を取得するプロバイダー
final _sessionExerciseSummariesProvider =
    FutureProvider.family<List<_SessionExerciseSummary>, int>((ref, sessionId) async {
  final workoutExerciseDao = ref.read(workoutExerciseDaoProvider);
  final setRecordDao = ref.read(setRecordDaoProvider);
  final exerciseMasterDao = ref.read(exerciseMasterDaoProvider);
  final unit = ref.read(currentUnitProvider);
  final language = ref.read(currentLanguageProvider);

  final exercises = await workoutExerciseDao.getExercisesBySessionId(sessionId);
  final list = <_SessionExerciseSummary>[];

  for (final ex in exercises) {
    final master = await exerciseMasterDao.getExerciseById(ex.exerciseId);
    final englishName = master?.name ?? '?';
    final displayName = ExerciseLocalization.getLocalizedName(
      englishName: englishName,
      language: language,
      isStandard: (master?.isCustom ?? 1) == 0,
    );
    final sets = await setRecordDao.getSetsByWorkoutExerciseId(ex.id!);
    final recordType = master?.recordType ?? 'reps';

    String topDisplay = '';
    if (sets.isNotEmpty) {
      if (recordType == 'time') {
        final best = sets
            .where((s) => (s.durationSeconds ?? 0) > 0)
            .fold<SetRecordEntity?>(
              null,
              (best, s) =>
                  best == null ||
                          (s.durationSeconds ?? 0) >
                              (best.durationSeconds ?? 0)
                      ? s
                      : best,
            );
        if (best != null) {
          topDisplay = '${best.durationSeconds}秒';
        }
      } else if (recordType == 'cardio') {
        final withDistance =
            sets.where((s) => (s.distanceMeters ?? 0) > 0).toList();
        final withDuration =
            sets.where((s) => (s.durationSeconds ?? 0) > 0).toList();
        if (withDistance.isNotEmpty) {
          final totalM = withDistance.fold<double>(
              0, (sum, s) => sum + (s.distanceMeters ?? 0));
          topDisplay = '${(totalM / 1000).toStringAsFixed(1)}km';
        } else if (withDuration.isNotEmpty) {
          final totalSec = withDuration.fold<int>(
              0, (sum, s) => sum + (s.durationSeconds ?? 0));
          topDisplay = '${totalSec ~/ 60}分';
        }
      } else {
        // reps: 最大重量×回数のセット
        final best = sets
            .where((s) => (s.reps ?? 0) > 0)
            .fold<SetRecordEntity?>(null, (best, s) {
          if (best == null) return s;
          final w = s.getWeight(unit);
          final r = s.reps ?? 0;
          final bw = best.getWeight(unit);
          final br = best.reps ?? 0;
          return (w * r) >= (bw * br) ? s : best;
        });
        if (best != null) {
          final w = best.getWeight(unit);
          topDisplay = '${w.toStringAsFixed(1)}$unit × ${best.reps}回';
        }
      }
    }

    list.add(_SessionExerciseSummary(
      name: displayName,
      setCount: sets.length,
      topDisplay: topDisplay,
    ));
  }

  return list;
});

/// 全てのトレーニング記録を一覧表示する画面（新しい日付順・総回数表示）
class AllRecordsScreen extends ConsumerWidget {
  const AllRecordsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final sessionsAsync = ref.watch(allCompletedSessionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.allRecordsTitle),
      ),
      body: sessionsAsync.when(
        data: (sessions) {
          if (sessions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.fitness_center, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    l10n.noWorkoutHistory,
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _buildTotalCountCard(context, l10n, sessions.length),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final session = sessions[index];
                      return _buildSessionCard(
                        context,
                        ref,
                        l10n,
                        session,
                      );
                    },
                    childCount: sessions.length,
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Text(
            l10n.errorLoadingWorkouts,
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
      ),
    );
  }

  Widget _buildTotalCountCard(
    BuildContext context,
    AppLocalizations l10n,
    int count,
  ) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 32,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                l10n.totalWorkoutsCount(count),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionCard(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    WorkoutSessionEntity session,
  ) {
    final currentLanguage = ref.watch(currentLanguageProvider);
    final completedAt = session.completedAt != null
        ? DateTime.fromMillisecondsSinceEpoch(session.completedAt! * 1000)
        : null;

    final dateStr = completedAt != null
        ? DateFormatter.formatDate(completedAt, currentLanguage)
        : l10n.unknownDate;

    final timeStr = completedAt != null && session.completedAt != null
        ? _getSessionDuration(l10n, session.startedAt, session.completedAt!)
        : '';

    final sessionId = session.id!;
    final summariesAsync = ref.watch(_sessionExerciseSummariesProvider(sessionId));

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => WorkoutDetailScreen(sessionId: sessionId),
            ),
          ).then((_) {
            ref.invalidate(allCompletedSessionsProvider);
            ref.invalidate(_sessionExerciseSummariesProvider(sessionId));
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 32),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dateStr,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (timeStr.isNotEmpty)
                          Text(
                            timeStr,
                            style: TextStyle(
                                fontSize: 14, color: Colors.grey[600]),
                          ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                ],
              ),
              summariesAsync.when(
                data: (summaries) {
                  if (summaries.isEmpty) return const SizedBox.shrink();
                  const maxDisplay = 3;
                  final display = summaries.take(maxDisplay).toList();
                  final hasMore = summaries.length > maxDisplay;
                  return Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ...display.map(
                          (s) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    s.name,
                                    style: const TextStyle(fontSize: 13),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${s.setCount}${l10n.setsUnit}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                if (s.topDisplay.isNotEmpty) ...[
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      s.topDisplay,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[700],
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        if (hasMore)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              l10n.moreExercisesHint(summaries.length - maxDisplay),
                              style: TextStyle(
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                        const SizedBox(height: 6),
                        Text(
                          l10n.tapForDetailHint,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: SizedBox(
                    height: 20,
                    width: 80,
                    child: LinearProgressIndicator(),
                  ),
                ),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getSessionDuration(AppLocalizations l10n, int startedAt, int completedAt) {
    final start = DateTime.fromMillisecondsSinceEpoch(startedAt * 1000);
    final end = DateTime.fromMillisecondsSinceEpoch(completedAt * 1000);
    final duration = end.difference(start);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final durationStr = hours > 0
        ? l10n.durationHoursMinutes(hours, minutes)
        : l10n.durationMinutes(minutes);
    return l10n.durationLabel(durationStr);
  }
}
