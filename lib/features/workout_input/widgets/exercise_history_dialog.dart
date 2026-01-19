import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../data/entities/set_record_entity.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/settings_provider.dart';
import '../../../utils/date_formatter.dart';

/// Dialog to show all history for an exercise
class ExerciseHistoryDialog extends ConsumerWidget {
  final String exerciseName;
  final List<Map<String, dynamic>> historyData;
  final String recordType;

  const ExerciseHistoryDialog({
    super.key,
    required this.exerciseName,
    required this.historyData,
    this.recordType = 'reps',
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final currentLanguage = ref.watch(currentLanguageProvider);
    final currentDistanceUnit = ref.watch(currentDistanceUnitProvider);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
          maxWidth: 500,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.exerciseHistoryTitle,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          exerciseName,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // History list
            Expanded(
              child: historyData.isEmpty
                  ? _buildEmptyState(context)
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: historyData.length,
                      itemBuilder: (context, index) {
                        final session = historyData[index];
                        return _buildHistoryCard(context, session, currentLanguage, currentDistanceUnit);
                      },
                    ),
            ),
          ],
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
            Icons.history,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.noHistoryAvailable,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(BuildContext context, Map<String, dynamic> session, String language, String distanceUnit) {
    final completedAt = session['completedAt'] as int;
    final sets = session['sets'] as List<SetRecordEntity>;

    final date = DateTime.fromMillisecondsSinceEpoch(completedAt * 1000);
    final dateStr = DateFormatter.formatDate(date, language);
    final timeStr = DateFormat('HH:mm').format(date);

    // Calculate days ago
    final now = DateTime.now();
    final daysAgo = now.difference(date).inDays;
    final daysAgoStr = _getDaysAgoString(context, daysAgo);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date and time
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '$dateStr • $timeStr',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  daysAgoStr,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Sets
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: sets.asMap().entries.map((entry) {
                final index = entry.key;
                final set = entry.value;
                return _buildSetChip(context, index + 1, set, distanceUnit);
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSetChip(BuildContext context, int setNumber, SetRecordEntity set, String distanceUnit) {
    // Check for reps, duration, or distance
    final hasReps = set.reps != null && set.reps! > 0;
    final hasDuration = set.durationSeconds != null && set.durationSeconds! > 0;
    final hasDistance = set.distanceMeters != null && set.distanceMeters! > 0;
    final isCardio = recordType == 'cardio';
    final hasData = hasReps || hasDuration || hasDistance;

    // Format display text based on record type
    String displayStr;

    if (isCardio) {
      // Cardio: show time + distance
      String timeStr = '';
      if (hasDuration) {
        final minutes = set.durationSeconds! ~/ 60;
        final seconds = set.durationSeconds! % 60;
        timeStr = minutes > 0 ? '${minutes}m${seconds}s' : '${seconds}s';
      }
      String distStr = '';
      if (hasDistance) {
        final distance = set.getDistance(distanceUnit);
        distStr = distance != null ? '${distance.toStringAsFixed(2)}$distanceUnit' : '';
      }
      if (timeStr.isNotEmpty && distStr.isNotEmpty) {
        displayStr = '$timeStr / $distStr';
      } else if (timeStr.isNotEmpty) {
        displayStr = timeStr;
      } else if (distStr.isNotEmpty) {
        displayStr = distStr;
      } else {
        displayStr = '-';
      }
    } else if (hasDuration) {
      // Time-based: weight + duration
      final minutes = set.durationSeconds! ~/ 60;
      final seconds = set.durationSeconds! % 60;
      final valueStr = minutes > 0 ? '${minutes}m${seconds}s' : '${seconds}s';
      final weightStr = set.weightKg % 1 == 0
          ? set.weightKg.toInt().toString()
          : set.weightKg.toStringAsFixed(1);
      displayStr = '$weightStr${set.unit}/$valueStr';
    } else if (hasReps) {
      // Reps-based: weight + reps
      final weightStr = set.weightKg % 1 == 0
          ? set.weightKg.toInt().toString()
          : set.weightKg.toStringAsFixed(1);
      displayStr = '$weightStr${set.unit}/${set.reps}';
    } else {
      displayStr = 'Set $setNumber: -';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: hasData ? Colors.blue.shade50 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: hasData ? Colors.blue.shade200 : Colors.grey.shade300,
        ),
      ),
      child: Text(
        displayStr,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: hasData ? Colors.blue.shade900 : Colors.grey.shade600,
        ),
      ),
    );
  }

  String _getDaysAgoString(BuildContext context, int daysAgo) {
    final l10n = AppLocalizations.of(context)!;

    if (daysAgo == 0) {
      return l10n.today;
    } else if (daysAgo == 1) {
      return l10n.yesterday;
    } else if (daysAgo < 7) {
      return l10n.daysAgo(daysAgo);
    } else if (daysAgo < 30) {
      final weeks = (daysAgo / 7).floor();
      return l10n.weeksAgo(weeks);
    } else if (daysAgo < 365) {
      final months = (daysAgo / 30).floor();
      return l10n.monthsAgo(months);
    } else {
      final years = (daysAgo / 365).floor();
      return l10n.yearsAgo(years);
    }
  }
}
