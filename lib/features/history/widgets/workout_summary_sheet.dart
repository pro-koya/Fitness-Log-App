import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/entities/workout_session_entity.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/settings_provider.dart';
import '../../../utils/date_formatter.dart';
import '../../workout_detail/workout_detail_screen.dart';

/// Workout summary bottom sheet
class WorkoutSummarySheet extends ConsumerWidget {
  final WorkoutSessionEntity workout;
  final int exerciseCount;
  final int totalSets;

  const WorkoutSummarySheet({
    super.key,
    required this.workout,
    required this.exerciseCount,
    required this.totalSets,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final currentLanguage = ref.watch(currentLanguageProvider);

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            l10n.workoutSummaryTitle(_formatDate(workout.completedAt, currentLanguage)),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),

          // Duration
          _buildInfoRow(
            Icons.access_time,
            _formatDuration(workout.startedAt, workout.completedAt),
          ),
          const SizedBox(height: 12),

          // Exercise count
          _buildInfoRow(
            Icons.fitness_center,
            l10n.exerciseCount(exerciseCount),
          ),
          const SizedBox(height: 12),

          // Set count
          _buildInfoRow(
            Icons.bar_chart,
            l10n.setCount(totalSets),
          ),

          const SizedBox(height: 24),

          // View details button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => WorkoutDetailScreen(
                      sessionId: workout.id!,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(l10n.viewDetailsButton),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 12),
        Text(
          text,
          style: const TextStyle(fontSize: 16),
        ),
      ],
    );
  }

  String _formatDate(int? timestamp, String language) {
    if (timestamp == null) return '';
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return DateFormatter.formatDate(date, language);
  }

  String _formatDuration(int? startedAt, int? completedAt) {
    if (startedAt == null || completedAt == null) return '';

    final start = DateTime.fromMillisecondsSinceEpoch(startedAt * 1000);
    final end = DateTime.fromMillisecondsSinceEpoch(completedAt * 1000);
    final duration = end.difference(start);

    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}min';
    } else {
      return '${minutes}min';
    }
  }
}
