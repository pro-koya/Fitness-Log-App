import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/workout_session_provider.dart';
import '../../providers/settings_provider.dart';
import '../../data/dao/workout_session_dao.dart';
import '../../data/entities/workout_session_entity.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/date_formatter.dart';
import '../settings/settings_screen.dart';
import '../workout_input/workout_input_screen.dart';
import '../workout_input/widgets/timer_icon_button.dart';
import '../workout_detail/workout_detail_screen.dart';
import '../history/history_screen.dart';
import '../history/all_records_screen.dart';
import '../memo_search/memo_search_screen.dart';
import '../exercise_list/exercise_list_screen.dart';
import '../tutorial/providers/interactive_tutorial_provider.dart';
import '../tutorial/models/tutorial_step.dart';
import '../tutorial/widgets/tutorial_overlay.dart';
import '../body_weight/body_weight_screen.dart';
import '../body_weight/providers/body_weight_provider.dart';
import '../goal_list/goal_list_screen.dart';
import '../routine/routine_list_screen.dart';
import '../routine/widgets/routine_selector_modal.dart';
import '../../providers/routine_provider.dart';
import '../../data/entities/routine_template_entity.dart';

/// Home screen - main entry point after initial setup.
/// When [isEmbeddedInTab] is true, used as the first tab of [MainTabScreen]; AppBar shows only Timer.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key, this.isEmbeddedInTab = false});

  final bool isEmbeddedInTab;

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final GlobalKey _startWorkoutButtonKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final sessionAsync = ref.watch(workoutSessionNotifierProvider);
    final currentLanguage = ref.watch(currentLanguageProvider);
    final now = DateTime.now();

    final tutorialState = ref.watch(interactiveTutorialProvider);
    final isTutorialActive = tutorialState.isActive &&
        tutorialState.currentStep == TutorialStep.homeStartWorkout;

    // ヘッダーなし: 設定・タイマーは MainTabScreen で左上/右下に固定。メイン動線はフッターとホーム内のショートカットで確保。
    return Scaffold(
      appBar: widget.isEmbeddedInTab
          ? null
          : AppBar(
              title: const SizedBox.shrink(),
              centerTitle: true,
              leading: IconButton(
                icon: const Icon(Icons.settings),
                tooltip: l10n.settingsTitle,
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const SettingsScreen(),
                    ),
                  );
                },
              ),
              actions: [
                _buildCompactIconButton(
                  icon: Icons.list_alt,
                  tooltip: l10n.allRecordsTitle,
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const AllRecordsScreen(),
                      ),
                    );
                  },
                ),
                _buildCompactIconButton(
                  icon: Icons.fitness_center,
                  tooltip: l10n.exerciseListTooltip,
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const ExerciseListScreen(),
                      ),
                    );
                  },
                ),
                _buildCompactIconButton(
                  icon: Icons.search,
                  tooltip: l10n.memoSearch,
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const MemoSearchScreen(),
                      ),
                    );
                  },
                ),
                _buildCompactIconButton(
                  icon: Icons.calendar_today,
                  tooltip: l10n.historyTitle,
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const HistoryScreen(),
                      ),
                    );
                  },
                ),
                _buildCompactIconButton(
                  icon: Icons.flag,
                  tooltip: l10n.goalListTitle,
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const GoalListScreen(),
                      ),
                    );
                  },
                ),
                const TimerIconButton(),
              ],
            ),
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // タブ埋め込み時: 記録一覧・種目一覧・メモ検索へのショートカット（フッターと併用）
                  if (widget.isEmbeddedInTab) ...[
                    _buildShortcutRow(context, l10n),
                    const SizedBox(height: 16),
                  ],
                  // Date Display
                  Text(
                    DateFormatter.formatMediumDate(now, currentLanguage),
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Statistics Cards (Monthly count & Streak)
                  _buildStatisticsCards(context),

                  const SizedBox(height: 16),

                  // Routine section
                  _buildRoutineSection(context, ref),

                  const SizedBox(height: 16),

                  // Session Status + differentiator hint (P1-1)
                  sessionAsync.when(
                    data: (session) {
                      if (session != null) {
                        // In-progress session exists
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildInProgressCard(context, ref, session),
                            const SizedBox(height: 16),
                            _buildStartNewButton(context, ref, isSecondary: true),
                            const SizedBox(height: 8),
                            _buildDifferentiatorHint(context),
                          ],
                        );
                      } else {
                        // No in-progress session
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildStartNewButton(context, ref),
                            const SizedBox(height: 8),
                            _buildDifferentiatorHint(context),
                          ],
                        );
                      }
                    },
                    loading: () => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    error: (error, stack) => Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.error_outline, size: 40, color: Colors.grey[600]),
                            const SizedBox(height: 12),
                            Text(
                              l10n.errorLoadFailed,
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                            ),
                            const SizedBox(height: 16),
                            TextButton.icon(
                              onPressed: () => ref.invalidate(workoutSessionNotifierProvider),
                              icon: const Icon(Icons.refresh, size: 18),
                              label: Text(l10n.retryButton),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Recent Workouts Section (scrolls with page for wider scroll range)
                  _buildRecentWorkoutsTitle(context, ref),
                  const SizedBox(height: 16),

                  _buildRecentWorkouts(context, ref),
                ],
              ),
            ),
          ),
          // Tutorial overlay - must be Positioned.fill to correctly align spotlight
          if (isTutorialActive)
            Positioned.fill(
              child: TutorialOverlay(
                targetKey: _startWorkoutButtonKey,
                tooltipMessage: l10n.tutorialStartWorkoutMessage,
                onSkip: () {
                  ref.read(interactiveTutorialProvider.notifier).skipTutorial();
                },
              ),
            ),
        ],
      ),
    );
  }

Widget _buildStatisticsCards(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Monthly workout count
          Expanded(
            child: FutureBuilder<int>(
              future: WorkoutSessionDao().countSessionsInMonth(now.year, now.month),
              builder: (context, snapshot) {
                final count = snapshot.data ?? 0;
                return _buildStatCard(
                  context,
                  icon: Icons.fitness_center,
                  iconColor: Colors.blue,
                  title: l10n.thisMonthLabel,
                  value: l10n.monthlyWorkoutCount(count),
                );
              },
            ),
          ),
          const SizedBox(width: 12),

          // Workout streak
          Expanded(
            child: FutureBuilder<int>(
              future: WorkoutSessionDao().getCurrentStreak(),
              builder: (context, snapshot) {
                final streak = snapshot.data ?? 0;
                return _buildStatCard(
                  context,
                  icon: Icons.local_fire_department,
                  iconColor: Colors.orange,
                  title: l10n.streakLabel,
                  value: l10n.streakDays(streak),
                );
              },
            ),
          ),
          const SizedBox(width: 12),

          // Body weight
          Expanded(
            child: _buildWeightStatCard(context),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    String? value,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: iconColor,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            if (value != null) ...[
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRecentWorkoutsTitle(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final recentWorkoutsAsync = ref.watch(recentWorkoutItemsProvider);

    return recentWorkoutsAsync.when(
      data: (items) {
        final count = items.length;
        return Text(
          '${l10n.recentWorkoutsLabel}（$count件）',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        );
      },
      loading: () => Text(
        l10n.recentWorkoutsLabel,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      error: (error, stack) => Text(
        l10n.recentWorkoutsLabel,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildRecentWorkouts(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final recentWorkoutsAsync = ref.watch(recentWorkoutItemsProvider);

    return recentWorkoutsAsync.when(
      data: (items) {
        if (items.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.history,
                  size: 48,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.noWorkoutHistory,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return _buildWorkoutHistoryCard(context, ref, item.session);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 40, color: Colors.grey[600]),
              const SizedBox(height: 12),
              Text(
                l10n.errorLoadFailed,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: () => ref.invalidate(recentWorkoutItemsProvider),
                icon: const Icon(Icons.refresh, size: 18),
                label: Text(l10n.retryButton),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWorkoutHistoryCard(
    BuildContext context,
    WidgetRef ref,
    WorkoutSessionEntity session,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final currentLanguage = ref.watch(currentLanguageProvider);
    final completedAt = session.completedAt != null
        ? DateTime.fromMillisecondsSinceEpoch(session.completedAt! * 1000)
        : null;

    final dateStr = completedAt != null
        ? DateFormatter.formatDate(completedAt, currentLanguage)
        : l10n.unknownDate;

    final timeStr = completedAt != null
        ? _getSessionDuration(context, session.startedAt, session.completedAt!)
        : '';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          if (session.id != null) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => WorkoutDetailScreen(
                  sessionId: session.id!,
                ),
              ),
            ).then((_) {
              // Refresh recent workouts when returning from detail screen
              ref.invalidate(recentWorkoutItemsProvider);
            });
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 32,
              ),
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
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getSessionDuration(BuildContext context, int startedAt, int completedAt) {
    final l10n = AppLocalizations.of(context)!;
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

  Widget _buildInProgressCard(
    BuildContext context,
    WidgetRef ref,
    dynamic session,
  ) {
    final l10n = AppLocalizations.of(context)!;

    return Card(
      elevation: 4,
      color: Colors.blue.shade50,
      child: InkWell(
        onTap: () {
          _navigateToWorkoutInput(context, ref, session.id as int);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.fitness_center,
                    color: Colors.blue,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.resumeWorkoutButton,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.workoutInProgress,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.blue,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDifferentiatorHint(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Text(
        l10n.homeDifferentiatorHint,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[600],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildStartNewButton(
    BuildContext context,
    WidgetRef ref, {
    bool isSecondary = false,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final tutorialState = ref.watch(interactiveTutorialProvider);
    final isTutorialActive = tutorialState.isActive &&
        tutorialState.currentStep == TutorialStep.homeStartWorkout;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        key: isTutorialActive ? _startWorkoutButtonKey : null,
        onPressed: () async {
          // Do NOT complete step here: advancing would hide the overlay on home before push, causing a "mysterious" flash. Advance to step 2 after WorkoutInputScreen is shown.
          await _createNewSession(context, ref);
        },
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: isSecondary ? 16 : 18),
          backgroundColor: isSecondary ? Colors.grey.shade200 : null,
          foregroundColor: isSecondary ? Colors.black87 : null,
          elevation: isSecondary ? 0 : 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          isSecondary ? l10n.startNewWorkoutButton : l10n.startWorkoutButton,
          style: TextStyle(
            fontSize: 16,
            fontWeight: isSecondary ? FontWeight.normal : FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Future<void> _createNewSession(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(workoutSessionNotifierProvider.notifier);
    final sessionId = await notifier.createNewSession();

    if (sessionId != null && context.mounted) {
      _navigateToWorkoutInput(context, ref, sessionId);
    }
  }

  void _navigateToWorkoutInput(
    BuildContext context,
    WidgetRef ref,
    int sessionId,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => WorkoutInputScreen(
          sessionId: sessionId,
          isTutorialMode: ref.read(interactiveTutorialProvider).isActive,
        ),
      ),
    ).then((_) {
      // Refresh session list and recent workouts when returning
      ref.read(workoutSessionNotifierProvider.notifier).refresh();
      ref.invalidate(recentWorkoutItemsProvider);
    });
  }

  Widget _buildWeightStatCard(BuildContext context) {
    final latestAsync = ref.watch(latestBodyWeightProvider);
    final currentUnit = ref.watch(currentUnitProvider);
    final l10n = AppLocalizations.of(context)!;

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const BodyWeightScreen(),
          ),
        ).then((_) {
          ref.invalidate(latestBodyWeightProvider);
        });
      },
      child: latestAsync.when(
        data: (latest) {
          if (latest == null) {
            return _buildStatCard(
              context,
              icon: Icons.monitor_weight_outlined,
              iconColor: Colors.purple,
              title: l10n.bodyWeightLabel,
              value: '—',
            );
          }

          final weight = latest.getWeight(currentUnit);
          final weightStr = '${weight.toStringAsFixed(1)} $currentUnit';

          return _buildStatCard(
            context,
            icon: Icons.monitor_weight_outlined,
            iconColor: Colors.purple,
            title: l10n.bodyWeightLabel,
            value: weightStr,
          );
        },
        loading: () => _buildStatCard(
          context,
          icon: Icons.monitor_weight_outlined,
          iconColor: Colors.purple,
          title: l10n.bodyWeightLabel,
        ),
        error: (_, __) => _buildStatCard(
          context,
          icon: Icons.monitor_weight_outlined,
          iconColor: Colors.purple,
          title: l10n.bodyWeightLabel,
          value: '—',
        ),
      ),
    );
  }

  /// Build compact icon button with reduced padding for AppBar
  /// タブ埋め込み時用: 記録一覧・種目一覧・メモ検索への1行ショートカット
  Widget _buildShortcutRow(BuildContext context, AppLocalizations l10n) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _shortcutChip(
            context: context,
            icon: Icons.list_alt,
            label: l10n.allRecordsTitle,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const AllRecordsScreen(),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
          _shortcutChip(
            context: context,
            icon: Icons.fitness_center,
            label: l10n.exerciseListTooltip,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ExerciseListScreen(),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
          _shortcutChip(
            context: context,
            icon: Icons.search,
            label: l10n.memoSearch,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const MemoSearchScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _shortcutChip({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: Theme.of(context).colorScheme.onSurface),
              const SizedBox(width: 6),
              Text(label, style: const TextStyle(fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoutineSection(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final routinesAsync = ref.watch(routineListProvider);

    return routinesAsync.when(
      data: (routines) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  l10n.routineTitle,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const RoutineListScreen(),
                      ),
                    ).then((_) => ref.invalidate(routineListProvider));
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                  ),
                  child: Text(
                    l10n.routineManage,
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: routines.isEmpty
                    ? null
                    : () => _openRoutineSelectorAndStart(context, ref),
                icon: const Icon(Icons.repeat_rounded, size: 20),
                label: Text(l10n.routineLoadIntoWorkout),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  foregroundColor: routines.isEmpty ? Colors.grey : null,
                ),
              ),
            ),
            if (routines.isEmpty) ...[
              const SizedBox(height: 8),
              Text(
                l10n.routineEmptyHint,
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Future<void> _openRoutineSelectorAndStart(BuildContext context, WidgetRef ref) async {
    final routine = await showModalBottomSheet<RoutineTemplateEntity>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.25,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: const RoutineSelectorModal(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (routine == null || !context.mounted) return;

    final sessionAsync = ref.read(workoutSessionNotifierProvider);
    final currentSession = sessionAsync.valueOrNull;

    if (currentSession != null && currentSession.id != null) {
      final l10n = AppLocalizations.of(context)!;
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.routineAddToCurrentWorkoutTitle),
          content: Text(l10n.routineAddToCurrentWorkoutMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.cancelButton),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l10n.routineLoadIntoWorkout),
            ),
          ],
        ),
      );
      if (confirm == true && context.mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => WorkoutInputScreen(
              sessionId: currentSession.id!,
              addRoutineId: routine.id,
              isTutorialMode: ref.read(interactiveTutorialProvider).isActive,
            ),
          ),
        ).then((_) {
          ref.read(workoutSessionNotifierProvider.notifier).refresh();
          ref.invalidate(recentWorkoutItemsProvider);
        });
      }
      return;
    }

    await _startFromRoutine(context, ref, routine);
  }

  Future<void> _startFromRoutine(
    BuildContext context,
    WidgetRef ref,
    RoutineTemplateEntity routine,
  ) async {
    final notifier = ref.read(workoutSessionNotifierProvider.notifier);
    final sessionId = await notifier.createNewSession();

    if (sessionId != null && context.mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => WorkoutInputScreen(
            sessionId: sessionId,
            routineId: routine.id,
          ),
        ),
      ).then((_) {
        ref.read(workoutSessionNotifierProvider.notifier).refresh();
        ref.invalidate(recentWorkoutItemsProvider);
      });
    }
  }

  Widget _buildCompactIconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      icon: Icon(icon, size: 22),
      tooltip: tooltip,
      onPressed: onPressed,
      padding: const EdgeInsets.all(12),
      constraints: const BoxConstraints(
        minWidth: 36,
        minHeight: 36,
      ),
      visualDensity: VisualDensity.compact,
    );
  }

}
