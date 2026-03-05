import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/localization/body_part_localization.dart';
import '../../../data/localization/exercise_localization.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/database_providers.dart';
import '../../../providers/goal_list_provider.dart';
import '../../../providers/settings_provider.dart';
import '../../../services/bulk_goal_registration_service.dart';

/// Coefficient option: short label getter, value, icon.
const List<({
  String Function(AppLocalizations l10n) shortLabel,
  double value,
  IconData icon,
})> bulkGoalCoefficientOptions = [
  (shortLabel: _shortEasy, value: 1.1, icon: Icons.sentiment_satisfied_alt_outlined),
  (shortLabel: _shortMedium, value: 1.2, icon: Icons.trending_up),
  (shortLabel: _shortHard, value: 1.3, icon: Icons.fitness_center),
  (shortLabel: _shortMax, value: 1.5, icon: Icons.whatshot),
];

String _shortEasy(AppLocalizations l10n) => l10n.bulkGoalCourseShortEasy;
String _shortMedium(AppLocalizations l10n) => l10n.bulkGoalCourseShortMedium;
String _shortHard(AppLocalizations l10n) => l10n.bulkGoalCourseShortHard;
String _shortMax(AppLocalizations l10n) => l10n.bulkGoalCourseShortMax;

/// Modal: select coefficient course + exercises with checkboxes, then run bulk goal registration.
class BulkGoalSelectModal extends ConsumerStatefulWidget {
  const BulkGoalSelectModal({super.key});

  @override
  ConsumerState<BulkGoalSelectModal> createState() => _BulkGoalSelectModalState();
}

class _BulkGoalSelectModalState extends ConsumerState<BulkGoalSelectModal> {
  int _selectedCourseIndex = 1; // default: 1.2 (しっかり伸ばす)
  Set<int> _selectedIds = {};
  bool _isExecuting = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final lang = ref.watch(currentLanguageProvider);
    final theme = Theme.of(context);
    final asyncExercises = ref.watch(exercisesWithHistoryWithoutGoalProvider);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.bulkGoalSetTitle,
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: asyncExercises.when(
                data: (exercises) {
                  if (exercises.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Text(
                          l10n.bulkGoalNoTargetsToSetMessage,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ),
                    );
                  }
                  // Init selection to all when we first get data
                  if (_selectedIds.isEmpty) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        setState(() {
                          _selectedIds = exercises.map((e) => e.id!).whereType<int>().toSet();
                        });
                      }
                    });
                  }
                  return SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            l10n.bulkGoalCourseLabel,
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: List.generate(bulkGoalCoefficientOptions.length, (i) {
                              final opt = bulkGoalCoefficientOptions[i];
                              final selected = _selectedCourseIndex == i;
                              final multiplier = opt.value == opt.value.toInt()
                                  ? '${opt.value.toInt()}×'
                                  : '${opt.value}×';
                              return Expanded(
                                child: Padding(
                                  padding: EdgeInsets.only(
                                    right: i < bulkGoalCoefficientOptions.length - 1 ? 6 : 0,
                                  ),
                                  child: Material(
                                    color: selected
                                        ? theme.colorScheme.primaryContainer
                                        : theme.colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(12),
                                    child: InkWell(
                                      onTap: () => setState(() => _selectedCourseIndex = i),
                                      borderRadius: BorderRadius.circular(12),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 10,
                                          horizontal: 4,
                                        ),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              opt.icon,
                                              size: 18,
                                              color: selected
                                                  ? theme.colorScheme.onPrimaryContainer
                                                  : theme.colorScheme.onSurfaceVariant,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              multiplier,
                                              style: theme.textTheme.labelMedium?.copyWith(
                                                fontWeight: FontWeight.w600,
                                                color: selected
                                                    ? theme.colorScheme.onPrimaryContainer
                                                    : theme.colorScheme.onSurfaceVariant,
                                              ),
                                            ),
                                            Text(
                                              opt.shortLabel(l10n),
                                              style: theme.textTheme.labelSmall?.copyWith(
                                                fontSize: 10,
                                                color: selected
                                                    ? theme.colorScheme.onPrimaryContainer
                                                    : theme.colorScheme.onSurfaceVariant,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              textAlign: TextAlign.center,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                          const SizedBox(height: 16),
                          _buildSupplementSection(theme, l10n),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Text(
                                l10n.bulkGoalSelectExercises,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const Spacer(),
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    if (_selectedIds.length == exercises.length) {
                                      _selectedIds = {};
                                    } else {
                                      _selectedIds = exercises.map((e) => e.id!).whereType<int>().toSet();
                                    }
                                  });
                                },
                                child: Text(
                                  _selectedIds.length == exercises.length
                                      ? l10n.bulkGoalDeselectAll
                                      : l10n.bulkGoalSelectAll,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ...exercises.map((ex) {
                            final id = ex.id!;
                            final isStandard = ex.isCustom == 0;
                            final displayName = ExerciseLocalization.getLocalizedName(
                              englishName: ex.name,
                              language: lang,
                              isStandard: isStandard,
                            );
                            return CheckboxListTile(
                              value: _selectedIds.contains(id),
                              onChanged: (v) {
                                setState(() {
                                  if (v == true) {
                                    _selectedIds.add(id);
                                  } else {
                                    _selectedIds.remove(id);
                                  }
                                });
                              },
                              title: Text(displayName),
                              subtitle: ex.bodyPart != null
                                  ? Text(
                                      BodyPartLocalization.getLocalizedName(ex.bodyPart!, lang),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: theme.colorScheme.onSurfaceVariant,
                                      ),
                                    )
                                  : null,
                              controlAffinity: ListTileControlAffinity.leading,
                              contentPadding: EdgeInsets.zero,
                            );
                          }),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: _isExecuting || _selectedIds.isEmpty
                                  ? null
                                  : () => _executeBulkRegister(context, ref, l10n),
                              icon: _isExecuting
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Icon(Icons.flag),
                              label: Text(l10n.bulkGoalExecute),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (err, _) => Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
                        const SizedBox(height: 16),
                        Text(
                          l10n.errorLoadFailed,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSupplementSection(ThemeData theme, AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.bulkGoalSupplementTitle,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.bulkGoalSupplementMultiplier,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.bulkGoalSupplementExercises,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _executeBulkRegister(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    final count = _selectedIds.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.bulkGoalConfirmTitle),
        content: Text(l10n.bulkGoalConfirmMessage(count)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancelButton),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.confirmButton),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    setState(() => _isExecuting = true);
    final coefficient = bulkGoalCoefficientOptions[_selectedCourseIndex].value;
    final service = BulkGoalRegistrationService(
      setRecordDao: ref.read(setRecordDaoProvider),
      exerciseMasterDao: ref.read(exerciseMasterDaoProvider),
      exerciseGoalDao: ref.read(exerciseGoalDaoProvider),
    );
    final result = await service.register(
      exerciseIds: _selectedIds.toList(),
      coefficient: coefficient,
    );
    if (!context.mounted) return;
    setState(() => _isExecuting = false);

    ref.invalidate(allGoalsListProvider);
    ref.invalidate(exercisesWithHistoryWithoutGoalProvider);
    ref.invalidate(exercisesWithHistoryProvider);

    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              result.skippedCount > 0
                  ? l10n.bulkGoalResultMessageWithSkipped(
                      result.savedCount,
                      result.skippedCount,
                    )
                  : l10n.bulkGoalResultMessage(result.savedCount),
            ),
            if (result.skippedCount > 0) ...[
              const SizedBox(height: 12),
              Text(
                l10n.bulkGoalResultSkippedReason,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.confirmButton),
          ),
        ],
      ),
    );
    if (!context.mounted) return;
    Navigator.of(context).pop(true);
  }
}
