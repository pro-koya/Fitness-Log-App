import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/localization/exercise_localization.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/database_providers.dart';
import '../../../providers/goal_list_provider.dart';
import '../../../providers/settings_provider.dart';
import '../../../services/bulk_goal_registration_service.dart';
import 'bulk_goal_select_modal.dart';

/// Index for the "custom multiplier" option (5th choice after the 4 presets).
const int _customCourseIndex = 4;

/// Modal: select existing goals with checkboxes, then delete selected or recalculate with coefficient.
class BulkGoalEditModal extends ConsumerStatefulWidget {
  const BulkGoalEditModal({super.key});

  @override
  ConsumerState<BulkGoalEditModal> createState() => _BulkGoalEditModalState();
}

class _BulkGoalEditModalState extends ConsumerState<BulkGoalEditModal> {
  int _selectedCourseIndex = 1;
  Set<int> _selectedExerciseIds = {};
  bool _hasInitializedSelection = false;
  bool _isExecuting = false;
  final TextEditingController _customMultiplierController = TextEditingController(text: '1.25');

  @override
  void dispose() {
    _customMultiplierController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final lang = ref.watch(currentLanguageProvider);
    final unit = ref.watch(currentUnitProvider);
    final distanceUnit = ref.watch(currentDistanceUnitProvider);
    final theme = Theme.of(context);
    final asyncGoals = ref.watch(allGoalsListProvider);

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
                      l10n.bulkGoalEditTitle,
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
              child: asyncGoals.when(
                data: (goals) {
                  if (goals.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Text(
                          l10n.bulkGoalEditEmpty,
                          style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ),
                    );
                  }
                  // 初回のみ全選択で初期化。「すべて解除」後に再び全選択に戻らないようにする。
                  if (!_hasInitializedSelection && goals.isNotEmpty) {
                    _hasInitializedSelection = true;
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        setState(() {
                          _selectedExerciseIds =
                              goals.map((e) => e.goal.exerciseId).toSet();
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
                            l10n.bulkGoalEditSelectGoals,
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    if (_selectedExerciseIds.length == goals.length) {
                                      _selectedExerciseIds = {};
                                    } else {
                                      _selectedExerciseIds =
                                          goals.map((e) => e.goal.exerciseId).toSet();
                                    }
                                  });
                                },
                                child: Text(
                                  _selectedExerciseIds.length == goals.length
                                      ? l10n.bulkGoalDeselectAll
                                      : l10n.bulkGoalSelectAll,
                                ),
                              ),
                            ],
                          ),
                          ...goals.map((item) {
                            final exerciseId = item.goal.exerciseId;
                            final displayName = item.exerciseNameEn.isEmpty
                                ? '${l10n.goalTargetLabel} (ID: $exerciseId)'
                                : ExerciseLocalization.getLocalizedName(
                                    englishName: item.exerciseNameEn,
                                    language: lang,
                                    isStandard: item.isStandard,
                                  );
                            final valueStr = _formatGoalValue(item, l10n);
                            final pastBestStr = _formatPastBest(item, unit, distanceUnit, l10n);
                            return CheckboxListTile(
                              value: _selectedExerciseIds.contains(exerciseId),
                              onChanged: (v) {
                                setState(() {
                                  if (v == true) {
                                    _selectedExerciseIds.add(exerciseId);
                                  } else {
                                    _selectedExerciseIds.remove(exerciseId);
                                  }
                                });
                              },
                              title: Text(displayName),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    valueStr,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${l10n.bulkGoalPastBest}: $pastBestStr',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                                    ),
                                  ),
                                ],
                              ),
                              controlAffinity: ListTileControlAffinity.leading,
                              contentPadding: EdgeInsets.zero,
                            );
                          }),
                          const SizedBox(height: 16),
                          Text(
                            l10n.bulkGoalCourseLabel,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              ...List.generate(bulkGoalCoefficientOptions.length, (i) {
                                final opt = bulkGoalCoefficientOptions[i];
                                final selected = _selectedCourseIndex == i;
                                final multiplier = opt.value == opt.value.toInt()
                                    ? '${opt.value.toInt()}×'
                                    : '${opt.value}×';
                                return Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(right: 4),
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
                                            vertical: 8,
                                            horizontal: 4,
                                          ),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(opt.icon, size: 16,
                                                  color: selected
                                                      ? theme.colorScheme.onPrimaryContainer
                                                      : theme.colorScheme.onSurfaceVariant),
                                              Text(
                                                multiplier,
                                                style: theme.textTheme.labelSmall?.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                  color: selected
                                                      ? theme.colorScheme.onPrimaryContainer
                                                      : theme.colorScheme.onSurfaceVariant,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 4),
                                  child: Material(
                                    color: _selectedCourseIndex == _customCourseIndex
                                        ? theme.colorScheme.primaryContainer
                                        : theme.colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(12),
                                    child: InkWell(
                                      onTap: () => setState(() => _selectedCourseIndex = _customCourseIndex),
                                      borderRadius: BorderRadius.circular(12),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.edit,
                                              size: 16,
                                              color: _selectedCourseIndex == _customCourseIndex
                                                  ? theme.colorScheme.onPrimaryContainer
                                                  : theme.colorScheme.onSurfaceVariant,
                                            ),
                                            Text(
                                              l10n.bulkGoalCourseCustom,
                                              style: theme.textTheme.labelSmall?.copyWith(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 10,
                                                color: _selectedCourseIndex == _customCourseIndex
                                                    ? theme.colorScheme.onPrimaryContainer
                                                    : theme.colorScheme.onSurfaceVariant,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (_selectedCourseIndex == _customCourseIndex) ...[
                            const SizedBox(height: 10),
                            TextField(
                              controller: _customMultiplierController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(
                                hintText: l10n.bulkGoalCustomMultiplierHint,
                                isDense: true,
                                border: const OutlineInputBorder(),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                          ],
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _isExecuting || _selectedExerciseIds.isEmpty
                                      ? null
                                      : () => _executeDelete(context, ref, l10n),
                                  icon: const Icon(Icons.delete_outline, size: 20),
                                  label: Text(l10n.bulkGoalDeleteSelected),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: FilledButton.icon(
                                  onPressed: _isExecuting || _selectedExerciseIds.isEmpty
                                      ? null
                                      : () => _executeRecalc(context, ref, l10n),
                                  icon: _isExecuting
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        )
                                      : const Icon(Icons.refresh, size: 20),
                                  label: Text(l10n.bulkGoalRecalcSelected),
                                ),
                              ),
                            ],
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

  String _formatGoalValue(dynamic item, AppLocalizations l10n) {
    final g = item.goal;
    final typeLabel = _goalTypeLabel(g.goalType, l10n);
    if (g.goalType == 'time') {
      final m = g.goalValue.toInt() ~/ 60;
      final s = g.goalValue.toInt() % 60;
      return '$typeLabel: $m${l10n.goalTimeMinutes} $s${l10n.goalTimeSeconds}';
    }
    if (g.goalType == 'distance') {
      return '$typeLabel: ${(g.goalValue / 1000).toStringAsFixed(1)} km';
    }
    return '$typeLabel: ${g.goalValue.toStringAsFixed(g.goalValue == g.goalValue.truncateToDouble() ? 0 : 1)}';
  }

  /// 過去最高値を種目タイプ・単位に合わせてフォーマット。無い場合は "—"。
  String _formatPastBest(
    dynamic item,
    String unit,
    String distanceUnit,
    AppLocalizations l10n,
  ) {
    final best = item.bestValue;
    if (best == null || best <= 0) return '—';
    final g = item.goal;
    switch (g.goalType) {
      case 'weight':
      case 'volume':
        final v = unit == 'lb' ? best * 2.20462 : best;
        final s = v == v.truncateToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);
        return '$s $unit';
      case 'reps':
        return '${best.toInt()}${l10n.bulkGoalPastBestRepsUnit}';
      case 'time':
        final m = best.toInt() ~/ 60;
        final s = best.toInt() % 60;
        return '$m${l10n.goalTimeMinutes} $s${l10n.goalTimeSeconds}';
      case 'distance':
        final km = best / 1000;
        final display = distanceUnit == 'mile' ? km / 1.609 : km;
        final suffix = distanceUnit == 'mile' ? ' mile' : ' km';
        return '${display.toStringAsFixed(1)}$suffix';
      default:
        return best.toStringAsFixed(1);
    }
  }

  String _goalTypeLabel(String type, AppLocalizations l10n) {
    switch (type) {
      case 'weight': return l10n.goalTypeWeight;
      case 'reps': return l10n.goalTypeReps;
      case 'volume': return l10n.goalTypeVolume;
      case 'time': return l10n.goalTypeTime;
      case 'distance': return l10n.goalTypeDistance;
      default: return type;
    }
  }

  Future<void> _executeDelete(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    final count = _selectedExerciseIds.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.bulkGoalConfirmTitle),
        content: Text(l10n.bulkGoalEditConfirmDelete(count)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancelButton),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: Text(l10n.goalDelete),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    setState(() => _isExecuting = true);
    final goalDao = ref.read(exerciseGoalDaoProvider);
    for (final id in _selectedExerciseIds) {
      await goalDao.deleteByExerciseId(id);
    }
    if (!context.mounted) return;
    setState(() => _isExecuting = false);

    ref.invalidate(allGoalsListProvider);

    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(l10n.bulkGoalEditResultDeleted(count)),
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

  Future<void> _executeRecalc(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    double coefficient;
    if (_selectedCourseIndex == _customCourseIndex) {
      final parsed = double.tryParse(_customMultiplierController.text.trim());
      if (parsed == null || parsed < 0.1 || parsed > 10) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.bulkGoalCustomMultiplierInvalid)),
        );
        return;
      }
      coefficient = parsed;
    } else {
      coefficient = bulkGoalCoefficientOptions[_selectedCourseIndex].value;
    }

    final count = _selectedExerciseIds.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.bulkGoalConfirmTitle),
        content: Text(l10n.bulkGoalEditConfirmRecalc(count)),
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
    final service = BulkGoalRegistrationService(
      setRecordDao: ref.read(setRecordDaoProvider),
      exerciseMasterDao: ref.read(exerciseMasterDaoProvider),
      exerciseGoalDao: ref.read(exerciseGoalDaoProvider),
    );
    final result = await service.register(
      exerciseIds: _selectedExerciseIds.toList(),
      coefficient: coefficient,
    );
    if (!context.mounted) return;
    setState(() => _isExecuting = false);

    ref.invalidate(allGoalsListProvider);

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
                  ? l10n.bulkGoalEditResultRecalculatedWithSkipped(
                      result.savedCount,
                      result.skippedCount,
                    )
                  : l10n.bulkGoalEditResultRecalculated(result.savedCount),
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
