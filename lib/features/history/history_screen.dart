import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../data/dao/body_weight_dao.dart';
import '../../data/dao/workout_session_dao.dart';
import '../../data/dao/workout_exercise_dao.dart';
import '../../data/dao/set_record_dao.dart';
import '../../data/entities/workout_session_entity.dart';
import '../../data/localization/exercise_localization.dart';
import '../../data/localization/body_part_localization.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/settings_provider.dart';
import '../workout_input/widgets/timer_icon_button.dart';
import '../ads/widgets/banner_ad_widget.dart';
import 'widgets/workout_summary_sheet.dart';
import 'all_records_screen.dart';
import '../exercise_list/exercise_list_screen.dart';
import '../memo_search/memo_search_screen.dart';

/// History screen with calendar view.
/// When [isEmbeddedInTab] is true, no AppBar; 全記録・種目一覧・メモ検索への導線は body 上部に表示。
class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key, this.isEmbeddedInTab = false});

  final bool isEmbeddedInTab;

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<WorkoutSessionEntity>> _workoutDays = {};
  bool _isLoading = true;

  // Monthly summary data (for the calendar's focused month)
  int _totalDuration = 0;
  int _totalSets = 0;
  double _totalVolume = 0.0;
  int _totalTime = 0; // Total time in seconds for time-based exercises
  double _totalDistance = 0.0; // Total distance in meters for cardio exercises
  double? _monthlyAverageWeight; // Average body weight for the focused month
  List<Map<String, dynamic>> _topExercises = [];
  List<Map<String, int>> _weeklyData = [];

  // Body part filter
  String? _selectedBodyPart; // null means "all"

  @override
  void initState() {
    super.initState();
    _loadWorkouts();
    _loadMonthlySummary();
  }

  Future<void> _loadWorkouts() async {
    setState(() => _isLoading = true);

    try {
      // Get workouts for the current month
      final workouts = await WorkoutSessionDao().getWorkoutsForMonth(
        _focusedDay.year,
        _focusedDay.month,
      );

      // Group workouts by date
      final Map<DateTime, List<WorkoutSessionEntity>> grouped = {};
      for (var workout in workouts) {
        if (workout.completedAt != null) {
          final completedDate = DateTime.fromMillisecondsSinceEpoch(
            workout.completedAt! * 1000,
          );
          final dateKey = DateTime(
            completedDate.year,
            completedDate.month,
            completedDate.day,
          );

          grouped.putIfAbsent(dateKey, () => []).add(workout);
        }
      }

      setState(() {
        _workoutDays = grouped;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMonthlySummary() async {
    try {
      final sessionDao = WorkoutSessionDao();
      final setDao = SetRecordDao();

      final duration = await sessionDao.getTotalDurationForMonth(
        _focusedDay.year,
        _focusedDay.month,
      );
      final sets = await setDao.getTotalSetsForMonth(
        _focusedDay.year,
        _focusedDay.month,
        bodyPart: _selectedBodyPart,
      );
      final volume = await setDao.getTotalVolumeForMonth(
        _focusedDay.year,
        _focusedDay.month,
        bodyPart: _selectedBodyPart,
      );
      final totalTime = await setDao.getTotalTimeForMonth(
        _focusedDay.year,
        _focusedDay.month,
        bodyPart: _selectedBodyPart,
      );
      final totalDistance = await setDao.getTotalDistanceForMonth(
        _focusedDay.year,
        _focusedDay.month,
        bodyPart: _selectedBodyPart,
      );
      final topExercises = await setDao.getMostFrequentExercisesForMonth(
        _focusedDay.year,
        _focusedDay.month,
        bodyPart: _selectedBodyPart,
      );
      final weeklyData = await sessionDao.getWeeklyCountsForMonth(
        _focusedDay.year,
        _focusedDay.month,
      );
      final unit = ref.read(currentUnitProvider);
      final avgWeight = await BodyWeightDao().getAverageWeightForMonth(
        _focusedDay.year,
        _focusedDay.month,
        unit,
      );

      setState(() {
        _totalDuration = duration;
        _totalSets = sets;
        _totalVolume = volume;
        _totalTime = totalTime;
        _totalDistance = totalDistance;
        _monthlyAverageWeight = avgWeight;
        _topExercises = topExercises;
        _weeklyData = weeklyData;
      });
    } catch (e) {
      // Silently fail, keep default values
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currentLanguage = ref.watch(currentLanguageProvider);
    final locale = currentLanguage == 'ja' ? 'ja_JP' : 'en_US';

    return Scaffold(
      appBar: widget.isEmbeddedInTab
          ? null
          : AppBar(
              title: Text(l10n.historyTitle),
              actions: [
                IconButton(
                  icon: const Icon(Icons.list_alt),
                  tooltip: l10n.allRecordsTitle,
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const AllRecordsScreen(),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.fitness_center),
                  tooltip: l10n.exerciseListTooltip,
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const ExerciseListScreen(),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.search),
                  tooltip: l10n.memoSearch,
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const MemoSearchScreen(),
                      ),
                    );
                  },
                ),
                TimerIconButton(),
              ],
            ),
      body: SafeArea(
        top: widget.isEmbeddedInTab,
        child: Column(
          children: [
            if (_isLoading)
              const Expanded(
                child: Center(child: CircularProgressIndicator()),
              )
            else
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 月クイックボタン＋ピッカー
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8.0, vertical: 8.0),
                        child: SizedBox(
                          height: 48,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            shrinkWrap: true,
                            physics: const ClampingScrollPhysics(),
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _buildMonthQuickButton(
                                      l10n.lastMonthShort,
                                      () => _jumpToMonth(-1)),
                                  const SizedBox(width: 6),
                                  _buildMonthQuickButton(
                                      l10n.thisMonthShort,
                                      () => _jumpToMonth(0)),
                                  const SizedBox(width: 6),
                                  _buildMonthQuickButton(
                                      l10n.nextMonthShort,
                                      () => _jumpToMonth(1)),
                                  const SizedBox(width: 16),
                                  TextButton.icon(
                                    onPressed: _showMonthYearPicker,
                                    icon: const Icon(
                                        Icons.calendar_month, size: 20),
                                    label: Text(l10n.selectMonthYear),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      // カレンダー（高さ制限なし＝すべて表示、オーバーフロー防止）
                      TableCalendar(
                        firstDay: DateTime(2020, 1, 1),
                        lastDay: DateTime(2030, 12, 31),
                        focusedDay: _focusedDay,
                        selectedDayPredicate: (day) =>
                            isSameDay(_selectedDay, day),
                        eventLoader: (day) {
                          final normalized = DateTime(
                              day.year, day.month, day.day);
                          return _workoutDays[normalized] ?? [];
                        },
                        onDaySelected: (selectedDay, focusedDay) {
                          setState(() {
                            _selectedDay = selectedDay;
                            _focusedDay = focusedDay;
                          });
                          _showWorkoutSummary(selectedDay);
                        },
                        onPageChanged: (focusedDay) {
                          setState(() {
                            _focusedDay = focusedDay;
                          });
                          _loadWorkouts();
                          _loadMonthlySummary();
                        },
                        locale: locale,
                        calendarStyle: CalendarStyle(
                          markerDecoration: BoxDecoration(
                            color:
                                Theme.of(context).colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                          todayDecoration: BoxDecoration(
                            color: Colors.blue.shade200,
                            shape: BoxShape.circle,
                          ),
                          selectedDecoration: BoxDecoration(
                            color:
                                Theme.of(context).colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        headerStyle: const HeaderStyle(
                          formatButtonVisible: false,
                          titleCentered: true,
                        ),
                      ),
                      const Divider(),
                      // 月間サマリ
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildQuickStats(),
                            const SizedBox(height: 16),
                            if (_workoutDays.isNotEmpty) ...[
                              _buildTotalDurationCard(),
                              const SizedBox(height: 16),
                              _buildBodyPartFilter(),
                              const SizedBox(height: 16),
                              _buildMonthlySummaryCard(),
                              const SizedBox(height: 16),
                              if (_topExercises.isNotEmpty) ...[
                                _buildTopExercises(),
                                const SizedBox(height: 16),
                              ],
                              _buildWeeklyTrend(),
                            ] else
                              _buildEmptyState(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const BannerAdWidget(),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthQuickButton(String label, VoidCallback onPressed) {
    return FilledButton.tonal(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(label, style: const TextStyle(fontSize: 13)),
    );
  }

  void _jumpToMonth(int offset) {
    final now = DateTime.now();
    final target = DateTime(now.year, now.month + offset, 1);
    setState(() => _focusedDay = target);
    _loadWorkouts();
    _loadMonthlySummary();
  }

  Future<void> _showMonthYearPicker() async {
    final l10n = AppLocalizations.of(context)!;
    final isJa = ref.watch(currentLanguageProvider) == 'ja';
    int selectedYear = _focusedDay.year;
    int selectedMonth = _focusedDay.month;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final years = List.generate(11, (i) => 2020 + i);
            final monthNames = isJa
                ? ['1月', '2月', '3月', '4月', '5月', '6月', '7月', '8月', '9月', '10月', '11月', '12月']
                : ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
            return AlertDialog(
              title: Text(l10n.selectMonthYear),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isJa ? '年' : 'Year',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    DropdownButton<int>(
                      value: selectedYear,
                      isExpanded: true,
                      items: years.map((y) => DropdownMenuItem(value: y, child: Text('$y'))).toList(),
                      onChanged: (v) {
                        if (v != null) setDialogState(() => selectedYear = v);
                      },
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isJa ? '月' : 'Month',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: List.generate(12, (i) {
                        final month = i + 1;
                        final isSelected = selectedMonth == month;
                        return ChoiceChip(
                          label: Text(monthNames[i]),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) setDialogState(() => selectedMonth = month);
                          },
                        );
                      }),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l10n.cancelButton),
                ),
                FilledButton(
                  onPressed: () {
                    setState(() {
                      _focusedDay = DateTime(selectedYear, selectedMonth, 1);
                    });
                    _loadWorkouts();
                    _loadMonthlySummary();
                    Navigator.of(context).pop();
                  },
                  child: Text(l10n.saveButton),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildQuickStats() {
    final l10n = AppLocalizations.of(context)!;
    final totalWorkouts = _workoutDays.values.fold<int>(
      0,
      (sum, sessions) => sum + sessions.length,
    );
    final unit = ref.watch(currentUnitProvider);
    final weightStr = _monthlyAverageWeight != null
        ? '${_monthlyAverageWeight!.toStringAsFixed(1)} $unit'
        : '--';

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _buildStatCard(
              icon: Icons.monitor_weight_outlined,
              color: Colors.teal,
              title: l10n.averageWeightLabel,
              value: weightStr,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              icon: Icons.fitness_center,
              color: Colors.blue,
              title: l10n.thisMonthLabel,
              value: l10n.monthlyWorkoutCount(totalWorkouts),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color color,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTotalDurationCard() {
    final l10n = AppLocalizations.of(context)!;

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(
              Icons.schedule,
              size: 24,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.totalDuration,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDuration(_totalDuration),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBodyPartFilter() {
    final currentLanguage = ref.watch(currentLanguageProvider);

    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          // "All" option
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: FilterChip(
              label: Text(
                currentLanguage == 'ja' ? 'すべて' : 'All',
              ),
              selected: _selectedBodyPart == null,
              onSelected: (selected) {
                setState(() {
                  _selectedBodyPart = null;
                });
                _loadMonthlySummary();
              },
              backgroundColor: Colors.transparent,
              selectedColor: Theme.of(context).colorScheme.primary,
              checkmarkColor: Theme.of(context).colorScheme.onPrimary,
              labelStyle: TextStyle(
                color: _selectedBodyPart == null
                    ? Theme.of(context).colorScheme.onPrimary
                    : null,
              ),
            ),
          ),
          // Body part options
          ...BodyPartLocalization.allBodyParts.map((bodyPart) {
            final localizedName = BodyPartLocalization.getLocalizedName(
              bodyPart,
              currentLanguage,
            );
            final isSelected = _selectedBodyPart == bodyPart;
            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: FilterChip(
                label: Text(localizedName),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _selectedBodyPart = selected ? bodyPart : null;
                  });
                  _loadMonthlySummary();
                },
                backgroundColor: Colors.transparent,
                selectedColor: Theme.of(context).colorScheme.primary,
                checkmarkColor: Theme.of(context).colorScheme.onPrimary,
                labelStyle: TextStyle(
                  color: isSelected
                      ? Theme.of(context).colorScheme.onPrimary
                      : null,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMonthlySummaryCard() {
    final l10n = AppLocalizations.of(context)!;
    final currentLanguage = ref.watch(currentLanguageProvider);
    final currentDistanceUnit = ref.watch(currentDistanceUnitProvider);

    // Check if body part filter is selected and there's no data
    final hasNoData = _selectedBodyPart != null && _totalSets == 0;
    final isCardioSelected = _selectedBodyPart == BodyPartLocalization.cardio;

    if (hasNoData) {
      final bodyPartName = BodyPartLocalization.getLocalizedName(
        _selectedBodyPart!,
        currentLanguage,
      );
      return Card(
        elevation: 1,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.monthlySummary,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  l10n.noBodyPartWorkoutsThisMonth(bodyPartName),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Format distance based on distance unit
    String formatDistance(double meters) {
      if (currentDistanceUnit == 'mile') {
        final miles = meters / 1609.34;
        return '${miles.toStringAsFixed(2)} mile';
      }
      final km = meters / 1000.0;
      return '${km.toStringAsFixed(2)} km';
    }

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.monthlySummary,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildSummaryRow(
              Icons.format_list_numbered,
              l10n.totalSets,
              '$_totalSets ${l10n.setsUnit}',
            ),
            // Show volume for non-cardio, distance for cardio
            if (isCardioSelected) ...[
              if (_totalDistance > 0) ...[
                const Divider(height: 20),
                _buildSummaryRow(
                  Icons.directions_run,
                  currentLanguage == 'ja' ? '総距離' : 'Total Distance',
                  formatDistance(_totalDistance),
                ),
              ],
              if (_totalTime > 0) ...[
                const Divider(height: 20),
                _buildSummaryRow(
                  Icons.timer,
                  l10n.totalTime,
                  _formatDuration(_totalTime ~/ 60),
                ),
              ],
            ] else ...[
              const Divider(height: 20),
              _buildSummaryRow(
                Icons.fitness_center,
                l10n.totalVolume,
                '${_totalVolume.toStringAsFixed(0)} kg',
              ),
              if (_totalTime > 0) ...[
                const Divider(height: 20),
                _buildSummaryRow(
                  Icons.timer,
                  l10n.totalTime,
                  _formatDuration(_totalTime ~/ 60),
                ),
              ],
              // Show distance for any body part if there's cardio data
              if (_totalDistance > 0) ...[
                const Divider(height: 20),
                _buildSummaryRow(
                  Icons.directions_run,
                  currentLanguage == 'ja' ? '総距離' : 'Total Distance',
                  formatDistance(_totalDistance),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildTopExercises() {
    final l10n = AppLocalizations.of(context)!;
    final currentLanguage = ref.watch(currentLanguageProvider);

    // Check if body part filter is selected and there's no data
    final hasNoData = _selectedBodyPart != null && _topExercises.isEmpty;

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.topExercises,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (hasNoData)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  l10n.noBodyPartWorkoutsThisMonth(
                    BodyPartLocalization.getLocalizedName(
                      _selectedBodyPart!,
                      currentLanguage,
                    ),
                  ),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              )
            else
              ..._topExercises.asMap().entries.map((entry) {
              final index = entry.key;
              final exercise = entry.value;
              final medal = index == 0
                  ? '🥇'
                  : index == 1
                      ? '🥈'
                      : '🥉';

              // Get localized exercise name
              final englishName = exercise['exerciseName'] as String;
              final isCustom = (exercise['isCustom'] as int) == 1;
              final displayName = ExerciseLocalization.getLocalizedName(
                englishName: englishName,
                language: currentLanguage,
                isStandard: !isCustom,
              );

              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    Text(
                      medal,
                      style: const TextStyle(fontSize: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        displayName,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    Text(
                      '${exercise['sessionCount']} ${l10n.timesUnit}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
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

  Widget _buildWeeklyTrend() {
    final l10n = AppLocalizations.of(context)!;

    if (_weeklyData.isEmpty) return const SizedBox.shrink();

    final maxCount = _weeklyData.fold<int>(
      0,
      (max, data) => data['count']! > max ? data['count']! : max,
    );

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.weeklyTrend,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 150,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: _weeklyData.map((data) {
                  final week = data['week']!;
                  final count = data['count']!;
                  final height = maxCount > 0 ? (count / maxCount) * 100 : 0.0;

                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (count > 0)
                            Text(
                              '$count',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            )
                          else
                            const SizedBox(height: 15),
                          const SizedBox(height: 4),
                          Container(
                            height: height.clamp(10, 100),
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'W$week',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.noWorkoutsThisMonth,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(int minutes) {
    if (minutes < 60) {
      return '$minutes min';
    } else {
      final hours = minutes ~/ 60;
      final mins = minutes % 60;
      return '${hours}h ${mins}min';
    }
  }

  Future<void> _showWorkoutSummary(DateTime day) async {
    final normalized = DateTime(day.year, day.month, day.day);
    final workouts = _workoutDays[normalized];

    if (workouts == null || workouts.isEmpty) return;

    // If there are multiple workouts on the same day, show a selection dialog
    if (workouts.length > 1) {
      _showMultipleWorkoutsDialog(workouts);
    } else {
      // Show summary for the single workout
      _showSingleWorkoutSummary(workouts.first);
    }
  }

  Future<void> _showSingleWorkoutSummary(
    WorkoutSessionEntity workout,
  ) async {
    // Get exercise and set counts
    final workoutExerciseDao = WorkoutExerciseDao();
    final exercises = await workoutExerciseDao.getExercisesBySessionId(
      workout.id!,
    );

    final exerciseCount = exercises.length;

    // Get total sets count
    final setRecordDao = SetRecordDao();
    int totalSets = 0;
    for (var exercise in exercises) {
      final sets = await setRecordDao.getSetsByWorkoutExerciseId(exercise.id!);
      totalSets += sets.length;
    }

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      builder: (context) => WorkoutSummarySheet(
        workout: workout,
        exerciseCount: exerciseCount,
        totalSets: totalSets,
      ),
    );
  }

  void _showMultipleWorkoutsDialog(List<WorkoutSessionEntity> workouts) {
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${workouts.length} workouts on this day'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: workouts.map((workout) {
            final startTime = DateTime.fromMillisecondsSinceEpoch(
              workout.startedAt * 1000,
            );
            final timeStr =
                '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
            return ListTile(
              leading: const Icon(Icons.fitness_center),
              title: Text('Workout at $timeStr'),
              trailing: Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey.shade400,
              ),
              onTap: () {
                Navigator.of(context).pop();
                _showSingleWorkoutSummary(workout);
              },
            );
          }).toList(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancelButton),
          ),
        ],
      ),
    );
  }
}
