import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/workout_detail_provider.dart';
import 'models/workout_detail_model.dart';
import 'widgets/datetime_edit_modal.dart';
import '../../providers/database_providers.dart';
import '../../providers/settings_provider.dart';
import '../../providers/workout_session_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/date_formatter.dart';
import '../../utils/feature_gate.dart';
import '../exercise_progress/exercise_progress_screen.dart';
import '../paywall/paywall_service.dart';
import '../paywall/models/paywall_reason.dart';
import '../workout_input/workout_input_screen.dart';
import '../workout_input/widgets/timer_icon_button.dart';

class WorkoutDetailScreen extends ConsumerWidget {
  final int sessionId;

  const WorkoutDetailScreen({
    super.key,
    required this.sessionId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final workoutDetailAsync = ref.watch(workoutDetailProvider(sessionId));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.workoutDetailTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          TimerIconButton(),
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: l10n.editWorkoutButton,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => WorkoutInputScreen(
                    sessionId: sessionId,
                  ),
                ),
              ).then((_) {
                // Refresh the detail screen when returning
                ref.invalidate(workoutDetailProvider(sessionId));
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: l10n.shareWorkoutButton,
            onPressed: () {
              workoutDetailAsync.whenData((workoutDetail) {
                if (workoutDetail != null) {
                  _showShareDialog(context, ref, workoutDetail);
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: l10n.deleteWorkoutButton,
            onPressed: () => _showDeleteDialog(context, ref),
          ),
        ],
      ),
      body: workoutDetailAsync.when(
        data: (workoutDetail) {
          if (workoutDetail == null) {
            return _buildEmptyState(context);
          }
          return _buildContent(context, ref, workoutDetail);
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 48,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(l10n.errorMessage(error.toString())),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assignment_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            l10n.emptyStateMessage,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, WorkoutDetailModel workoutDetail) {
    final currentLanguage = ref.watch(currentLanguageProvider);
    final date = workoutDetail.session.completedAt != null
        ? DateTime.fromMillisecondsSinceEpoch(workoutDetail.session.completedAt! * 1000)
        : null;
    
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date and session time card with edit button
            Card(
              margin: const EdgeInsets.only(bottom: 16),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Date
                          if (date != null)
                            Text(
                              DateFormatter.formatDate(date, currentLanguage),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          const SizedBox(height: 8),

                          // Session time
                          if (workoutDetail.getFormattedSessionTime().isNotEmpty)
                            Text(
                              workoutDetail.getFormattedSessionTime(),
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[700],
                              ),
                            ),
                        ],
                      ),
                    ),
                    // Edit button
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      onPressed: () => _showEditDateTimeDialog(
                        context,
                        ref,
                        workoutDetail,
                      ),
                      tooltip: 'Edit time',
                      color: Colors.grey.shade600,
                    ),
                  ],
                ),
              ),
            ),

            // Exercise list
            if (workoutDetail.exercises.isEmpty)
              _buildEmptyState(context)
            else
              ...workoutDetail.exercises.map((exerciseDetail) {
                return _buildExerciseCard(context, ref, exerciseDetail);
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseCard(
    BuildContext context,
    WidgetRef ref,
    ExerciseDetailModel exerciseDetail,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final currentUnit = ref.watch(currentUnitProvider);
    final currentDistanceUnit = ref.watch(currentDistanceUnitProvider);

    final gate = ref.watch(featureGateProvider);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: InkWell(
        onTap: () async {
          // Check if charts are accessible
          if (!gate.canAccessCharts) {
            await showPaywall(context, reason: PaywallReason.chart);
            return;
          }

          // Navigate to Exercise Progress Screen
          if (exerciseDetail.exercise.exerciseId != null) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => ExerciseProgressScreen(
                  exerciseId: exerciseDetail.exercise.exerciseId!,
                  exerciseName: exerciseDetail.exerciseName,
                ),
              ),
            );
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Exercise name with chart indicator
              Row(
                children: [
                  Expanded(
                    child: Text(
                      exerciseDetail.exerciseName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  // Chart access indicator
                  Icon(
                    gate.canAccessCharts ? Icons.show_chart : Icons.lock,
                    size: 20,
                    color: gate.canAccessCharts
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey,
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Sets
              if (exerciseDetail.sets.isNotEmpty)
                SizedBox(
                  width: double.infinity,
                  child: Text(
                    exerciseDetail.getFormattedSets(currentUnit, distanceUnit: currentDistanceUnit),
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[800],
                    ),
                    overflow: TextOverflow.visible,
                    softWrap: true,
                  ),
                )
              else
                Text(
                  l10n.noSetsRecorded,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[500],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              const SizedBox(height: 8),

              // Set count info
              Text(
                l10n.setsCountLabel(exerciseDetail.setCount),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),

              // Memo section
              if (exerciseDetail.memo != null &&
                  exerciseDetail.memo!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.format_quote,
                      size: 16,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        exerciseDetail.memo!,
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
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showDeleteDialog(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(l10n.deleteWorkoutDialogTitle),
          content: Text(l10n.deleteWorkoutDialogMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.cancelButton),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: Text(l10n.deleteButton),
            ),
          ],
        );
      },
    );

    if (confirmed == true && context.mounted) {
      await _deleteWorkout(context, ref);
    }
  }

  Future<void> _deleteWorkout(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;

    try {
      final dao = ref.read(workoutSessionDaoProvider);
      await dao.deleteSession(sessionId);

      // Invalidate providers to refresh the UI
      ref.invalidate(recentWorkoutsProvider);
      ref.invalidate(workoutDetailProvider(sessionId));

      if (context.mounted) {
        Navigator.of(context).pop(); // Go back to previous screen
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.errorDeletingWorkout(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showEditDateTimeDialog(
    BuildContext context,
    WidgetRef ref,
    WorkoutDetailModel workoutDetail,
  ) async {
    final result = await showDialog<Map<String, int>>(
      context: context,
      builder: (context) => DateTimeEditModal(
        initialStartedAt: workoutDetail.session.startedAt,
        initialCompletedAt: workoutDetail.session.completedAt,
      ),
    );

    if (result != null && context.mounted) {
      final startedAt = result['startedAt']!;
      final completedAt = result['completedAt'];

      try {
        // Update session times
        final sessionNotifier = ref.read(workoutSessionNotifierProvider.notifier);
        await sessionNotifier.updateSessionTimes(sessionId, startedAt, completedAt);

        // Refresh the detail screen
        ref.invalidate(workoutDetailProvider(sessionId));
        ref.invalidate(recentWorkoutsProvider);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Workout time updated successfully'),
              backgroundColor: Colors.green,
              duration: Duration(milliseconds: 1500),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error updating workout time: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  /// Generate share text for workout
  String _generateShareText(BuildContext context, WidgetRef ref, WorkoutDetailModel workoutDetail) {
    final l10n = AppLocalizations.of(context)!;
    final currentLanguage = ref.watch(currentLanguageProvider);
    final currentUnit = ref.watch(currentUnitProvider);
    final currentDistanceUnit = ref.watch(currentDistanceUnitProvider);

    final date = workoutDetail.session.completedAt != null
        ? DateTime.fromMillisecondsSinceEpoch(workoutDetail.session.completedAt! * 1000)
        : null;

    final dateStr = date != null
        ? DateFormatter.formatDate(date, currentLanguage)
        : l10n.unknownDate;

    final buffer = StringBuffer();
    
    // Add date header
    if (currentLanguage == 'ja') {
      buffer.writeln('📅 $dateStr');
    } else {
      buffer.writeln('📅 $dateStr');
    }
    buffer.writeln('');

    // Add exercises
    for (final exercise in workoutDetail.exercises) {
      final setsStr = exercise.getFormattedSets(currentUnit, distanceUnit: currentDistanceUnit);
      if (setsStr.isNotEmpty) {
        buffer.writeln('${exercise.exerciseName} $setsStr');
      }
    }

    // Add hashtags
    buffer.writeln('');
    if (currentLanguage == 'ja') {
      buffer.writeln('#筋トレ #FitnessLog');
    } else {
      buffer.writeln('#Workout #FitnessLog');
    }

    return buffer.toString();
  }

  /// Show share dialog with workout text
  Future<void> _showShareDialog(
    BuildContext context,
    WidgetRef ref,
    WorkoutDetailModel workoutDetail,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final shareText = _generateShareText(context, ref, workoutDetail);

    await showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(l10n.shareWorkoutDialogTitle),
          content: SingleChildScrollView(
            child: SelectableText(
              shareText,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(l10n.cancelButton),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: shareText));
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.copiedToClipboard),
                      backgroundColor: Colors.green,
                      duration: const Duration(milliseconds: 1500),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.copy, size: 18),
              label: Text(l10n.copyToClipboard),
            ),
          ],
        );
      },
    );
  }
}
