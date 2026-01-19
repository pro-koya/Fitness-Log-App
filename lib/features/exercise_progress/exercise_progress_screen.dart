import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/localization/exercise_localization.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/database_providers.dart';
import '../../providers/settings_provider.dart';
import '../../utils/date_formatter.dart';
import 'providers/exercise_progress_provider.dart';
import 'widgets/progress_chart_widget.dart';
import '../workout_input/widgets/timer_icon_button.dart';

class ExerciseProgressScreen extends ConsumerWidget {
  final int exerciseId;
  final String exerciseName; // Kept for backward compatibility, but will be overridden

  const ExerciseProgressScreen({
    super.key,
    required this.exerciseId,
    required this.exerciseName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);
    
    // Get exercise name with translation
    final exerciseNameAsync = ref.watch(_exerciseNameProvider(exerciseId));
    final recordTypeAsync = ref.watch(_exerciseRecordTypeProvider(exerciseId));

    return Scaffold(
      appBar: AppBar(
        title: exerciseNameAsync.when(
          data: (name) => Text(name),
          loading: () => Text(exerciseName), // Fallback to passed name
          error: (error, _) => Text(exerciseName), // Fallback to passed name
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          TimerIconButton(),
        ],
      ),
      body: settingsAsync.when(
        data: (settings) {
          final unit = settings?.unit ?? 'kg';
          final recordType = recordTypeAsync.asData?.value ?? 'reps';
          return _buildContent(
            context,
            ref,
            unit,
            recordType: recordType,
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error loading settings: $error')),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    String unit,
    {required String recordType}
  ) {
    final l10n = AppLocalizations.of(context)!;
    final isTimeMode = recordType == 'time';
    final isCardioMode = recordType == 'cardio';
    final distanceUnit = ref.watch(currentDistanceUnitProvider);

    Widget buildMetricSection({
      required String chartMode,
    }) {
      final progressAsync = ref.watch(
        exerciseProgressProvider(
          ExerciseProgressQuery(exerciseId: exerciseId, metric: chartMode),
        ),
      );

      return progressAsync.when(
        data: (progressData) {
          if (progressData.isEmpty) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Text(
                l10n.noDataForExercise,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ProgressChartWidget(
                dataPoints: progressData,
                unit: unit,
                chartMode: chartMode,
                distanceUnit: distanceUnit,
              ),
              const SizedBox(height: 32),
              _buildSummaryStats(
                context,
                progressData,
                unit,
                chartMode: chartMode,
                distanceUnit: distanceUnit,
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
      );
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isCardioMode) ...[
              // Cardio: Time, Distance, Pace tabs
              DefaultTabController(
                length: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TabBar(
                      labelColor: Theme.of(context).colorScheme.primary,
                      tabs: [
                        Tab(text: l10n.timeTab),
                        Tab(text: l10n.distanceTab),
                        Tab(text: l10n.paceTab),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 520,
                      child: TabBarView(
                        children: [
                          buildMetricSection(chartMode: 'cardio_time'),
                          buildMetricSection(chartMode: 'cardio_distance'),
                          buildMetricSection(chartMode: 'cardio_pace'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (isTimeMode) ...[
              buildMetricSection(
                chartMode: 'time',
              ),
            ] else ...[
              DefaultTabController(
                length: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TabBar(
                      labelColor: Theme.of(context).colorScheme.primary,
                      tabs: [
                        Tab(text: l10n.weightTab),
                        Tab(text: l10n.repsTab),
                        Tab(text: l10n.volumeTab),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 520,
                      child: TabBarView(
                        children: [
                          buildMetricSection(
                            chartMode: 'weight',
                          ),
                          buildMetricSection(
                            chartMode: 'reps',
                          ),
                          buildMetricSection(
                            chartMode: 'volume',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Memo history section
            const SizedBox(height: 32),
            _MemoHistorySection(exerciseId: exerciseId),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryStats(
    BuildContext context,
    List<ExerciseProgressDataPoint> progressData,
    String unit,
    {required String chartMode, String distanceUnit = 'km'}
  ) {
    final l10n = AppLocalizations.of(context)!;
    final isJapanese = Localizations.localeOf(context).languageCode == 'ja';
    final latestWeight = progressData.last.topWeight;
    final firstWeight = progressData.first.topWeight;
    final improvement = latestWeight - firstWeight;
    final improvementPercent = firstWeight > 0
        ? (improvement / firstWeight * 100).toStringAsFixed(1)
        : '0.0';

    String formatSeconds(double secondsValue) {
      final totalSeconds = secondsValue.round();
      if (totalSeconds <= 0) return '0s';
      final minutes = totalSeconds ~/ 60;
      final seconds = totalSeconds % 60;
      if (minutes <= 0) return '${seconds}s';
      return '${minutes}m${seconds.toString().padLeft(2, '0')}s';
    }

    String formatReps(double repsValue) => repsValue.round().toString();

    String formatDistance(double meters) {
      // Convert meters to km or mile
      double distance;
      if (distanceUnit == 'mile') {
        distance = meters / 1609.34;
      } else {
        distance = meters / 1000.0;
      }

      if (distance == distance.toInt()) {
        return '${distance.toInt()}$distanceUnit';
      }
      return '${distance.toStringAsFixed(2)}$distanceUnit';
    }

    String formatSpeed(double speedKmH) {
      // speed is in km/h, convert to mph if needed
      double speed;
      String speedUnit;
      if (distanceUnit == 'mile') {
        speed = speedKmH / 1.60934;
        speedUnit = 'mph';
      } else {
        speed = speedKmH;
        speedUnit = 'km/h';
      }
      return '${speed.toStringAsFixed(1)}$speedUnit';
    }

    String formatVolumeWithBreakdown(ExerciseProgressDataPoint dataPoint, String unit) {
      final volume = dataPoint.topWeight;
      final weight = dataPoint.weight;
      final reps = dataPoint.reps;

      final volumeStr = volume % 1 == 0
          ? volume.toInt().toString()
          : volume.toStringAsFixed(1);

      if (weight != null && reps != null) {
        final weightStr = weight % 1 == 0
            ? weight.toInt().toString()
            : weight.toStringAsFixed(1);
        return '$volumeStr$unit ($weightStr$unit/$reps ${l10n.repsUnit})';
      } else {
        return '$volumeStr$unit';
      }
    }

    // Determine labels and values based on chart mode
    String latestLabel;
    String latestValue;
    String startingLabel;
    String startingValue;
    String improvementStr;

    if (chartMode == 'cardio_time') {
      latestLabel = l10n.latestBestTime;
      latestValue = formatSeconds(latestWeight);
      startingLabel = l10n.startingBestTime;
      startingValue = formatSeconds(firstWeight);
      improvementStr = improvement >= 0
          ? '+${formatSeconds(improvement)} (+$improvementPercent%)'
          : '-${formatSeconds(improvement.abs())} ($improvementPercent%)';
    } else if (chartMode == 'cardio_distance') {
      latestLabel = l10n.latestBestDistance;
      latestValue = formatDistance(latestWeight);
      startingLabel = l10n.startingBestDistance;
      startingValue = formatDistance(firstWeight);
      improvementStr = improvement >= 0
          ? '+${formatDistance(improvement)} (+$improvementPercent%)'
          : '-${formatDistance(improvement.abs())} ($improvementPercent%)';
    } else if (chartMode == 'cardio_pace') {
      // Speed mode: higher is better
      final speedUnit = distanceUnit == 'mile' ? 'mph' : 'km/h';
      latestLabel = isJapanese ? '最新の平均速度' : 'Latest Avg Speed';
      latestValue = formatSpeed(latestWeight);
      startingLabel = isJapanese ? '初回の平均速度' : 'Starting Avg Speed';
      startingValue = formatSpeed(firstWeight);
      // For speed, higher is better (same as normal improvement)
      final speedImprovement = latestWeight - firstWeight;
      final speedImprovementDisplay = distanceUnit == 'mile'
          ? speedImprovement / 1.60934
          : speedImprovement;
      improvementStr = improvement >= 0
          ? '+${speedImprovementDisplay.toStringAsFixed(1)}$speedUnit (+$improvementPercent%)'
          : '${speedImprovementDisplay.toStringAsFixed(1)}$speedUnit ($improvementPercent%)';
    } else if (chartMode == 'time') {
      latestLabel = l10n.latestBestTime;
      latestValue = formatSeconds(latestWeight);
      startingLabel = l10n.startingBestTime;
      startingValue = formatSeconds(firstWeight);
      improvementStr = improvement >= 0
          ? '+${formatSeconds(improvement)} (+$improvementPercent%)'
          : '-${formatSeconds(improvement.abs())} ($improvementPercent%)';
    } else if (chartMode == 'reps') {
      latestLabel = l10n.latestTopReps;
      latestValue = '${formatReps(latestWeight)} ${l10n.repsUnit}';
      startingLabel = l10n.startingTopReps;
      startingValue = '${formatReps(firstWeight)} ${l10n.repsUnit}';
      improvementStr = improvement >= 0
          ? '+${formatReps(improvement)} ${l10n.repsUnit} (+$improvementPercent%)'
          : '${formatReps(improvement)} ${l10n.repsUnit} ($improvementPercent%)';
    } else if (chartMode == 'volume') {
      latestLabel = l10n.latestTopVolume;
      latestValue = formatVolumeWithBreakdown(progressData.last, unit);
      startingLabel = l10n.startingTopVolume;
      startingValue = formatVolumeWithBreakdown(progressData.first, unit);
      improvementStr = improvement >= 0
          ? '+${improvement.toStringAsFixed(1)} $unit (+$improvementPercent%)'
          : '${improvement.toStringAsFixed(1)} $unit ($improvementPercent%)';
    } else {
      // weight
      latestLabel = l10n.latestTopWeight;
      latestValue = '${latestWeight.toStringAsFixed(1)} $unit';
      startingLabel = l10n.startingWeight;
      startingValue = '${firstWeight.toStringAsFixed(1)} $unit';
      improvementStr = improvement >= 0
          ? '+${improvement.toStringAsFixed(1)} $unit (+$improvementPercent%)'
          : '${improvement.toStringAsFixed(1)} $unit ($improvementPercent%)';
    }

    // For speed (pace), higher is better (same as normal improvement)
    final isImproved = improvement >= 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.summaryLabel,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        // Total workouts
        _buildStatRow(
          l10n.totalWorkouts,
          '${progressData.length}',
        ),
        const SizedBox(height: 12),

        // Latest value
        _buildStatRow(latestLabel, latestValue),
        const SizedBox(height: 12),

        // Starting value
        _buildStatRow(startingLabel, startingValue),
        const SizedBox(height: 12),

        // Improvement
        _buildStatRow(
          l10n.improvement,
          improvementStr,
          valueColor: isImproved ? Colors.green : Colors.red,
        ),
      ],
    );
  }

  Widget _buildStatRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[700],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: valueColor ?? Colors.black,
          ),
        ),
      ],
    );
  }
}

/// Provider to get localized exercise name
final _exerciseNameProvider = FutureProvider.family<String, int>(
  (ref, exerciseId) async {
    final masterDao = ref.read(exerciseMasterDaoProvider);
    final currentLanguage = ref.watch(currentLanguageProvider);

    final exercise = await masterDao.getExerciseById(exerciseId);
    if (exercise == null) {
      return 'Unknown Exercise';
    }

    final isStandard = exercise.isCustom == 0;
    return ExerciseLocalization.getLocalizedName(
      englishName: exercise.name,
      language: currentLanguage,
      isStandard: isStandard,
    );
  },
);

/// Provider to get exercise record type ('reps' or 'time')
final _exerciseRecordTypeProvider = FutureProvider.family<String, int>(
  (ref, exerciseId) async {
    final masterDao = ref.read(exerciseMasterDaoProvider);
    final exercise = await masterDao.getExerciseById(exerciseId);
    return exercise?.recordType ?? 'reps';
  },
);

/// Widget for displaying memo history section
class _MemoHistorySection extends ConsumerWidget {
  final int exerciseId;

  const _MemoHistorySection({required this.exerciseId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final currentLanguage = ref.watch(currentLanguageProvider);
    final memoHistoryAsync = ref.watch(exerciseMemoHistoryProvider(exerciseId));

    return memoHistoryAsync.when(
      data: (memoHistory) {
        if (memoHistory.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.memoHistory,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...memoHistory.map((entry) => _buildMemoCard(
              context,
              entry,
              currentLanguage,
            )),
          ],
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, _) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          'Error: $error',
          style: TextStyle(color: Colors.red[400], fontSize: 12),
        ),
      ),
    );
  }

  Widget _buildMemoCard(
    BuildContext context,
    MemoHistoryEntry entry,
    String language,
  ) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            DateFormatter.formatDate(entry.date, language),
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.format_quote,
                size: 14,
                color: Colors.grey[400],
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  entry.memo,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
