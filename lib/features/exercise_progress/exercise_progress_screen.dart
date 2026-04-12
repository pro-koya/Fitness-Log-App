import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/localization/exercise_localization.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/database_providers.dart';
import '../../providers/settings_provider.dart';
import '../../utils/chart_aggregation.dart';
import '../../utils/date_formatter.dart';
import 'providers/exercise_progress_provider.dart';
import 'widgets/progress_chart_widget.dart';
import 'widgets/exercise_goal_section.dart';
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
            exerciseName: exerciseNameAsync.asData?.value ?? exerciseName,
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              AppLocalizations.of(context)!.errorLoadFailed,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    String unit,
    {required String recordType,
    required String exerciseName}
  ) {
    final l10n = AppLocalizations.of(context)!;
    final isTimeMode = recordType == 'time';
    final isCardioMode = recordType == 'cardio';
    final distanceUnit = ref.watch(currentDistanceUnitProvider);

    Widget buildMetricSection({
      required String chartMode,
      bool embedInScrollViewAndHistory = true,
    }) {
      final period = ref.watch(exerciseProgressPeriodProvider(exerciseId));
      final progressAsync = ref.watch(
        exerciseProgressProvider(
          ExerciseProgressQuery(exerciseId: exerciseId, metric: chartMode, period: period),
        ),
      );

      Widget buildContentColumn(Widget? chart, Widget? summary, {bool empty = false}) {
        final children = <Widget>[
          _buildPeriodFilterChips(context, ref),
          const SizedBox(height: 12),
        ];
        if (empty) {
          children.add(Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Text(
              l10n.noDataForExercise,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ));
        } else {
          if (chart != null) children.add(chart);
          if (summary != null) {
            children.add(const SizedBox(height: 32));
            children.add(summary);
          }
        }
        if (embedInScrollViewAndHistory) {
          children.add(const SizedBox(height: 32));
          children.add(_HistorySection(exerciseId: exerciseId, recordType: recordType));
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        );
      }

      return progressAsync.when(
        data: (progressData) {
          if (progressData.isEmpty) {
            final column = buildContentColumn(null, null, empty: true);
            return embedInScrollViewAndHistory
                ? SingleChildScrollView(child: column)
                : column;
          }

          final chart = ProgressChartWidget(
            dataPoints: progressData,
            unit: unit,
            chartMode: chartMode,
            distanceUnit: distanceUnit,
            xAxisBucket: workoutBucketForPeriod(period),
          );
          final summary = _buildSummaryStats(
            context,
            ref,
            exerciseId,
            period,
            progressData,
            unit,
            chartMode: chartMode,
            distanceUnit: distanceUnit,
          );
          final column = buildContentColumn(chart, summary);
          return embedInScrollViewAndHistory
              ? SingleChildScrollView(child: column)
              : column;
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              AppLocalizations.of(context)!.errorLoadFailed,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isCardioMode) ...[
              ExerciseGoalSection(
                exerciseId: exerciseId,
                recordType: recordType,
                exerciseName: exerciseName,
              ),
              const SizedBox(height: 16),
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
                    const SizedBox(height: 12),
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
              ExerciseGoalSection(
                exerciseId: exerciseId,
                recordType: recordType,
                exerciseName: exerciseName,
              ),
              const SizedBox(height: 16),
              buildMetricSection(
                chartMode: 'time',
              ),
            ] else ...[
              _WeightRepsVolumeUnifiedScroll(
                exerciseId: exerciseId,
                recordType: recordType,
                exerciseName: exerciseName,
                goalSection: ExerciseGoalSection(
                  exerciseId: exerciseId,
                  recordType: recordType,
                  exerciseName: exerciseName,
                ),
                buildMetricContent: (chartMode) => buildMetricSection(
                  chartMode: chartMode,
                  embedInScrollViewAndHistory: false,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodFilterChips(BuildContext context, WidgetRef ref) {
    final currentPeriod = ref.watch(exerciseProgressPeriodProvider(exerciseId));
    final periods = ProgressPeriod.values.where((p) => p != ProgressPeriod.oneWeek).toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: periods.map((period) {
          final isSelected = period == currentPeriod;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(period.label),
              selected: isSelected,
              onSelected: (_) {
                ref.read(exerciseProgressPeriodProvider(exerciseId).notifier).state = period;
              },
              selectedColor: Theme.of(context).colorScheme.primaryContainer,
              checkmarkColor: Theme.of(context).colorScheme.primary,
              labelStyle: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey[700],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSummaryStats(
    BuildContext context,
    WidgetRef ref,
    int exerciseId,
    ProgressPeriod period,
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

    // ボリュームタブ: 期間内の最大ボリュームを表示
    final List<Widget> summaryRows = [
      Text(
        l10n.summaryLabel,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 16),
      _buildStatRow(
        l10n.totalWorkouts,
        '${progressData.length}',
      ),
      const SizedBox(height: 12),
      _buildStatRow(latestLabel, latestValue),
      const SizedBox(height: 12),
      _buildStatRow(startingLabel, startingValue),
    ];
    if (chartMode == 'volume' && progressData.isNotEmpty) {
      final maxPoint = progressData.reduce(
        (a, b) => a.topWeight >= b.topWeight ? a : b,
      );
      summaryRows.add(const SizedBox(height: 12));
      summaryRows.add(_buildStatRow(
        l10n.maxTopVolume,
        formatVolumeWithBreakdown(maxPoint, unit),
      ));
    }
    // 過去最高（重量・回数・ボリューム）をコンパクトに表示（重量/回数/ボリュームタブのみ）
    if (chartMode == 'weight' || chartMode == 'reps' || chartMode == 'volume') {
      summaryRows.add(const SizedBox(height: 12));
      summaryRows.add(
        ref.watch(exerciseProgressAllTimeMaxProvider((
          exerciseId: exerciseId,
          period: period,
          unit: unit,
        ))).when(
          data: (stats) => _buildAllTimeCompactSection(
            context,
            stats,
            unit,
            l10n,
            chartMode: chartMode,
          ),
          loading: () => const SizedBox(height: 8),
          error: (_, stackTrace) => const SizedBox.shrink(),
        ),
      );
    }
    if (chartMode == 'weight' || chartMode == 'reps') {
      summaryRows.add(const SizedBox(height: 12));
      summaryRows.add(
        ref.watch(exerciseProgressWeightRepBestProvider((
          exerciseId: exerciseId,
          period: period,
          unit: unit,
        ))).when(
          data: (entries) => entries.isEmpty
              ? const SizedBox.shrink()
              : _buildWeightRepBestSection(
                  context,
                  entries,
                  unit,
                  l10n,
                ),
          loading: () => const SizedBox.shrink(),
          error: (_, stackTrace) => const SizedBox.shrink(),
        ),
      );
    }
    summaryRows.add(const SizedBox(height: 12));
    summaryRows.add(_buildStatRow(
      l10n.improvement,
      improvementStr,
      valueColor: isImproved ? Colors.green : Colors.red,
    ));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: summaryRows,
    );
  }

  Widget _buildWeightRepBestSection(
    BuildContext context,
    List<WeightRepBestEntry> entries,
    String unit,
    AppLocalizations l10n,
  ) {
    final theme = Theme.of(context);
    final isJapanese = Localizations.localeOf(context).languageCode == 'ja';

    String formatWeight(double weight) {
      return weight % 1 == 0
          ? weight.toInt().toString()
          : weight.toStringAsFixed(1);
    }

    String formatReps(int reps) {
      return isJapanese ? '$reps${l10n.repsUnit}' : '$reps ${l10n.repsUnit}';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.leaderboard_rounded,
                size: 16,
                color: theme.colorScheme.primary.withValues(alpha: 0.9),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.bestRepsByWeight,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (int i = 0; i < entries.length; i++) ...[
                  _buildWeightRepBestChip(
                    context,
                    weightLabel: '${formatWeight(entries[i].weight)} $unit',
                    repsLabel: formatReps(entries[i].maxReps),
                  ),
                  if (i != entries.length - 1) const SizedBox(width: 8),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeightRepBestChip(
    BuildContext context, {
    required String weightLabel,
    required String repsLabel,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.14),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            weightLabel,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 1,
            height: 14,
            color: theme.colorScheme.outlineVariant,
          ),
          const SizedBox(width: 8),
          Text(
            repsLabel,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  /// 過去最高をタブに合わせて1項目だけ表示（重量タブ→重量のみ、回数タブ→回数のみ、ボリュームタブ→ボリュームのみ）
  Widget _buildAllTimeCompactSection(
    BuildContext context,
    AllTimeMaxStats stats,
    String unit,
    AppLocalizations l10n, {
    required String chartMode,
  }) {
    final theme = Theme.of(context);
    String label;
    String valueStr;
    IconData icon;

    switch (chartMode) {
      case 'weight':
        label = l10n.allTimeMaxWeight;
        valueStr = (stats.maxWeight != null && stats.maxWeight! > 0)
            ? '${stats.maxWeight!.toStringAsFixed(1)} $unit'
            : '—';
        icon = Icons.fitness_center;
        break;
      case 'reps':
        label = l10n.allTimeMaxReps;
        valueStr = (stats.maxReps != null && stats.maxReps! > 0)
            ? '${stats.maxReps!.toInt()} ${l10n.repsUnit}'
            : '—';
        icon = Icons.repeat;
        break;
      case 'volume':
        label = l10n.allTimeMaxVolume;
        valueStr = (stats.maxVolume != null && stats.maxVolume! > 0)
            ? (stats.maxVolume! % 1 == 0
                ? '${stats.maxVolume!.toInt()}$unit'
                : '${stats.maxVolume!.toStringAsFixed(1)}$unit')
            : '—';
        icon = Icons.bar_chart;
        break;
      default:
        return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary.withValues(alpha: 0.9)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 12,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            valueStr,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[700],
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: valueColor ?? Colors.black,
            ),
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
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

/// History セクションのヘッダー（タイトル＋並び替え）。通常表示と Sticky 表示の両方で利用。
class _HistorySectionHeaderWithParams extends ConsumerWidget {
  final int exerciseId;
  final String recordType;

  const _HistorySectionHeaderWithParams({
    required this.exerciseId,
    required this.recordType,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isJapanese = ref.watch(currentLanguageProvider) == 'ja';
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          isJapanese ? '履歴' : 'History',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Flexible(
          child: _HistorySortSelector(exerciseId: exerciseId, recordType: recordType),
        ),
      ],
    );
  }
}

/// 並び替えセレクター（History ヘッダー内で使用）
class _HistorySortSelector extends ConsumerWidget {
  final int exerciseId;
  final String recordType;

  const _HistorySortSelector({
    required this.exerciseId,
    required this.recordType,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final currentSort = ref.watch(exerciseHistorySortProvider(exerciseId));
    final options = _getSortOptionsForType(recordType);
    return PopupMenuButton<HistorySortOption>(
      tooltip: l10n.sortLabel,
      onSelected: (option) {
        ref.read(exerciseHistorySortProvider(exerciseId).notifier).state = option;
      },
      itemBuilder: (context) => options.map((option) {
        return PopupMenuItem(
          value: option,
          child: Row(
            children: [
              if (option == currentSort)
                Icon(
                  Icons.check,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary,
                )
              else
                const SizedBox(width: 16),
              const SizedBox(width: 8),
              Text(_getSortOptionLabel(l10n, option)),
            ],
          ),
        );
      }).toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.sort,
              size: 16,
              color: Colors.grey.shade600,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                _getSortOptionLabel(l10n, currentSort),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade700,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(
              Icons.arrow_drop_down,
              size: 16,
              color: Colors.grey.shade600,
            ),
          ],
        ),
      ),
    );
  }
}

List<HistorySortOption> _getSortOptionsForType(String recordType) {
  switch (recordType) {
    case 'time':
      return [
        HistorySortOption.dateDesc,
        HistorySortOption.dateAsc,
        HistorySortOption.timeDesc,
        HistorySortOption.timeAsc,
      ];
    case 'cardio':
      return [
        HistorySortOption.dateDesc,
        HistorySortOption.dateAsc,
        HistorySortOption.timeDesc,
        HistorySortOption.timeAsc,
        HistorySortOption.distanceDesc,
        HistorySortOption.distanceAsc,
      ];
    default:
      return [
        HistorySortOption.dateDesc,
        HistorySortOption.dateAsc,
        HistorySortOption.weightDesc,
        HistorySortOption.weightAsc,
        HistorySortOption.repsDesc,
        HistorySortOption.repsAsc,
      ];
  }
}

String _getSortOptionLabel(AppLocalizations l10n, HistorySortOption option) {
  switch (option) {
    case HistorySortOption.dateDesc:
      return l10n.sortByDateDesc;
    case HistorySortOption.dateAsc:
      return l10n.sortByDateAsc;
    case HistorySortOption.weightDesc:
      return l10n.sortByWeightDesc;
    case HistorySortOption.weightAsc:
      return l10n.sortByWeightAsc;
    case HistorySortOption.repsDesc:
      return l10n.sortByRepsDesc;
    case HistorySortOption.repsAsc:
      return l10n.sortByRepsAsc;
    case HistorySortOption.timeDesc:
      return l10n.sortByTimeDesc;
    case HistorySortOption.timeAsc:
      return l10n.sortByTimeAsc;
    case HistorySortOption.distanceDesc:
      return l10n.sortByDistanceDesc;
    case HistorySortOption.distanceAsc:
      return l10n.sortByDistanceAsc;
  }
}

/// Widget for displaying history section with tabs (workout records + memos)
class _HistorySection extends ConsumerStatefulWidget {
  final int exerciseId;
  final String recordType;
  final Key? sectionKey;

  const _HistorySection({
    required this.exerciseId,
    required this.recordType,
    this.sectionKey,
  });

  @override
  ConsumerState<_HistorySection> createState() => _HistorySectionState();
}

class _HistorySectionState extends ConsumerState<_HistorySection> {
  final GlobalKey _sectionKey = GlobalKey();

  Key get _effectiveKey => widget.sectionKey ?? _sectionKey;

  @override
  Widget build(BuildContext context) {
    final currentLanguage = ref.watch(currentLanguageProvider);
    final isJapanese = currentLanguage == 'ja';
    final historyQuery = ExerciseHistoryQuery(
      exerciseId: widget.exerciseId,
      sortOption: ref.watch(exerciseHistorySortProvider(widget.exerciseId)),
    );
    final workoutHistoryAsync = ref.watch(exerciseWorkoutHistoryProvider(historyQuery));
    final memoHistoryAsync = ref.watch(exerciseMemoHistoryProvider(historyQuery));

    final hasWorkoutHistory = workoutHistoryAsync.asData?.value.isNotEmpty ?? false;
    final hasMemoHistory = memoHistoryAsync.asData?.value.isNotEmpty ?? false;

    if (!hasWorkoutHistory && !hasMemoHistory) {
      return const SizedBox.shrink();
    }

    return DefaultTabController(
      length: 2,
      child: Column(
        key: _effectiveKey,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HistorySectionHeaderWithParams(
            exerciseId: widget.exerciseId,
            recordType: widget.recordType,
          ),
          const SizedBox(height: 8),
          TabBar(
            labelColor: Theme.of(context).colorScheme.primary,
            tabs: [
              Tab(text: isJapanese ? '筋トレ記録' : 'Workout'),
              Tab(text: isJapanese ? 'メモ' : 'Memo'),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 400,
            child: TabBarView(
              children: [
                _buildWorkoutHistoryTab(context, workoutHistoryAsync, currentLanguage),
                _buildMemoHistoryTab(context, memoHistoryAsync, currentLanguage),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutHistoryTab(
    BuildContext context,
    AsyncValue<List<WorkoutHistoryEntry>> workoutHistoryAsync,
    String currentLanguage,
  ) {
    final unit = ref.watch(currentUnitProvider);
    final distanceUnit = ref.watch(currentDistanceUnitProvider);
    final isJapanese = currentLanguage == 'ja';
    final isTimeMode = widget.recordType == 'time';
    final isCardioMode = widget.recordType == 'cardio';

    return workoutHistoryAsync.when(
      data: (workoutHistory) {
        if (workoutHistory.isEmpty) {
          return Center(
            child: Text(
              isJapanese ? '記録がありません' : 'No workout records',
              style: TextStyle(color: Colors.grey[600]),
            ),
          );
        }

        return ListView.builder(
          itemCount: workoutHistory.length,
          itemBuilder: (context, index) {
            final entry = workoutHistory[index];
            return _buildWorkoutHistoryCard(
              context,
              entry,
              currentLanguage,
              unit,
              distanceUnit,
              isTimeMode: isTimeMode,
              isCardioMode: isCardioMode,
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            AppLocalizations.of(context)!.errorLoadFailed,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildWorkoutHistoryCard(
    BuildContext context,
    WorkoutHistoryEntry entry,
    String language,
    String unit,
    String distanceUnit, {
    required bool isTimeMode,
    required bool isCardioMode,
  }) {
    final isJapanese = language == 'ja';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date
            Text(
              DateFormatter.formatDate(entry.date, language),
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            // Sets
            ...entry.sets.map((set) {
              String setInfo;
              if (isCardioMode) {
                final time = _formatDuration(set.durationSeconds);
                final distance = set.getDistance(distanceUnit);
                final distanceStr = distance != null
                    ? '${distance.toStringAsFixed(2)} $distanceUnit'
                    : '-';
                setInfo = '$time / $distanceStr';
              } else if (isTimeMode) {
                final weight = set.getWeight(unit);
                final weightStr = weight != null ? '${_formatWeight(weight)} $unit' : '-';
                final time = _formatDuration(set.durationSeconds);
                setInfo = '$weightStr x $time';
              } else {
                final weight = set.getWeight(unit);
                final weightStr = weight != null ? '${_formatWeight(weight)} $unit' : '-';
                final repsStr = set.reps != null ? '${set.reps} ${isJapanese ? "回" : "reps"}' : '-';
                setInfo = '$weightStr x $repsStr';
              }

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    SizedBox(
                      width: 32,
                      child: Text(
                        'S${set.setNumber}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        setInfo,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  String _formatWeight(double weight) {
    if (weight % 1 == 0) {
      return weight.toInt().toString();
    }
    return weight.toStringAsFixed(1);
  }

  String _formatDuration(int? durationSeconds) {
    if (durationSeconds == null || durationSeconds <= 0) return '-';
    final minutes = durationSeconds ~/ 60;
    final seconds = durationSeconds % 60;
    if (minutes > 0) {
      return '${minutes}m${seconds.toString().padLeft(2, '0')}s';
    }
    return '${seconds}s';
  }

  Widget _buildMemoHistoryTab(
    BuildContext context,
    AsyncValue<List<MemoHistoryEntry>> memoHistoryAsync,
    String currentLanguage,
  ) {
    final isJapanese = currentLanguage == 'ja';

    return memoHistoryAsync.when(
      data: (memoHistory) {
        if (memoHistory.isEmpty) {
          return Center(
            child: Text(
              isJapanese ? 'メモがありません' : 'No memos',
              style: TextStyle(color: Colors.grey[600]),
            ),
          );
        }

        return ListView.builder(
          itemCount: memoHistory.length,
          itemBuilder: (context, index) {
            final entry = memoHistory[index];
            return _buildMemoCard(context, entry, currentLanguage);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            AppLocalizations.of(context)!.errorLoadFailed,
            textAlign: TextAlign.center,
          ),
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

/// Weight/Reps/Volume を単一スクロールにまとめ、History ヘッダーのみ Sticky 表示する。
class _WeightRepsVolumeUnifiedScroll extends ConsumerStatefulWidget {
  final int exerciseId;
  final String recordType;
  final String exerciseName;
  final Widget goalSection;
  final Widget Function(String chartMode) buildMetricContent;

  const _WeightRepsVolumeUnifiedScroll({
    required this.exerciseId,
    required this.recordType,
    required this.exerciseName,
    required this.goalSection,
    required this.buildMetricContent,
  });

  @override
  ConsumerState<_WeightRepsVolumeUnifiedScroll> createState() =>
      _WeightRepsVolumeUnifiedScrollState();
}

class _WeightRepsVolumeUnifiedScrollState
    extends ConsumerState<_WeightRepsVolumeUnifiedScroll> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _historySectionKey = GlobalKey();
  bool _showStickyHistoryHeader = false;

  static const List<String> _chartModes = ['weight', 'reps', 'volume'];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _historySectionKey.currentContext;
      if (ctx == null || !mounted) return;
      final box = ctx.findRenderObject() as RenderBox?;
      if (box != null && box.hasSize) {
        final dy = box.localToGlobal(Offset.zero).dy;
        const stickyThreshold = 56.0;
        if (mounted && _showStickyHistoryHeader != (dy <= stickyThreshold)) {
          setState(() => _showStickyHistoryHeader = dy <= stickyThreshold);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final selectedIndex = ref.watch(exerciseProgressMetricTabProvider(widget.exerciseId));
    final chartMode = _chartModes[selectedIndex];

    return Stack(
      children: [
        SingleChildScrollView(
          controller: _scrollController,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                widget.goalSection,
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _MetricTabChip(
                        label: l10n.weightTab,
                        selected: selectedIndex == 0,
                        onTap: () => ref
                            .read(exerciseProgressMetricTabProvider(widget.exerciseId).notifier)
                            .state = 0,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _MetricTabChip(
                        label: l10n.repsTab,
                        selected: selectedIndex == 1,
                        onTap: () => ref
                            .read(exerciseProgressMetricTabProvider(widget.exerciseId).notifier)
                            .state = 1,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _MetricTabChip(
                        label: l10n.volumeTab,
                        selected: selectedIndex == 2,
                        onTap: () => ref
                            .read(exerciseProgressMetricTabProvider(widget.exerciseId).notifier)
                            .state = 2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                widget.buildMetricContent(chartMode),
                const SizedBox(height: 32),
                _HistorySection(
                  sectionKey: _historySectionKey,
                  exerciseId: widget.exerciseId,
                  recordType: widget.recordType,
                ),
              ],
            ),
          ),
        ),
        if (_showStickyHistoryHeader)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Material(
              elevation: 2,
              color: Theme.of(context).scaffoldBackgroundColor,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                  child: _HistorySectionHeaderWithParams(
                    exerciseId: widget.exerciseId,
                    recordType: widget.recordType,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _MetricTabChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _MetricTabChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: selected
          ? theme.colorScheme.primaryContainer
          : theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              color: selected
                  ? theme.colorScheme.onPrimaryContainer
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
