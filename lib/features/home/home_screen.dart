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
import '../memo_search/memo_search_screen.dart';
import '../exercise_list/exercise_list_screen.dart';
import '../tutorial/providers/interactive_tutorial_provider.dart';
import '../tutorial/models/tutorial_step.dart';
import '../tutorial/widgets/tutorial_overlay.dart';
import 'widgets/locked_session_tile.dart';

/// Home screen - main entry point after initial setup
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

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

    return Scaffold(
      appBar: AppBar(
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
          const TimerIconButton(),
          _buildCompactIconButton(
            icon: Icons.fitness_center,
            tooltip: currentLanguage == 'ja' ? '種目一覧' : 'Exercises',
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
        ],
      ),
      body: Stack(
        children: [
          SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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

              const SizedBox(height: 24),

              // Session Status
              sessionAsync.when(
                data: (session) {
                  if (session != null) {
                    // In-progress session exists
                    return Column(
                      children: [
                        _buildInProgressCard(context, ref, session),
                        const SizedBox(height: 16),
                        _buildStartNewButton(context, ref, isSecondary: true),
                      ],
                    );
                  } else {
                    // No in-progress session
                    return _buildStartNewButton(context, ref);
                  }
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
                error: (error, stack) => Center(
                  child: Text(l10n.errorMessage(error.toString())),
                ),
              ),

              const SizedBox(height: 32),

              // Recent Workouts Section
              _buildRecentWorkoutsTitle(context, ref),
              const SizedBox(height: 16),

              Expanded(
                child: _buildRecentWorkouts(context, ref),
              ),
            ],
          ),
        ),
          ),
          // Tutorial overlay - must be Positioned.fill to correctly align spotlight
          if (isTutorialActive)
            Positioned.fill(
              child: TutorialOverlay(
                targetKey: _startWorkoutButtonKey,
                tooltipMessage: currentLanguage == 'ja'
                    ? 'このボタンをタップしてワークアウトを開始しましょう'
                    : 'Tap this button to start your workout',
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
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            // ロックされているセッションはLockedSessionTileを表示
            if (item.isLocked) {
              return LockedSessionTile(session: item.session);
            }
            return _buildWorkoutHistoryCard(context, ref, item.session);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text(
          l10n.errorLoadingWorkouts,
          style: TextStyle(color: Colors.grey[600]),
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
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: isSecondary ? Colors.grey.shade200 : null,
          foregroundColor: isSecondary ? Colors.black87 : null,
          elevation: isSecondary ? 0 : 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          isSecondary ? l10n.startNewWorkoutButton : l10n.startWorkoutButton,
          style: const TextStyle(fontSize: 16),
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

  /// Build compact icon button with reduced padding for AppBar
  Widget _buildCompactIconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      icon: Icon(icon, size: 22),
      tooltip: tooltip,
      onPressed: onPressed,
      padding: const EdgeInsets.all(8),
      constraints: const BoxConstraints(
        minWidth: 36,
        minHeight: 36,
      ),
      visualDensity: VisualDensity.compact,
    );
  }

}
