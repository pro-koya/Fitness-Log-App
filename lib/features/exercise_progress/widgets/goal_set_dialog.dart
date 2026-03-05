import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/entities/exercise_goal_entity.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/database_providers.dart';
import '../../../providers/exercise_goal_provider.dart';
import '../../../providers/goal_list_provider.dart';

/// Dialog to set or edit a per-exercise goal (Pro). goal_type is constrained by recordType.
class GoalSetDialog extends ConsumerStatefulWidget {
  final int exerciseId;
  final String recordType; // 'reps' | 'time' | 'cardio'
  final String unit; // 'kg' or 'lb'
  final ExerciseGoalEntity? existing;

  const GoalSetDialog({
    super.key,
    required this.exerciseId,
    required this.recordType,
    required this.unit,
    this.existing,
  });

  @override
  ConsumerState<GoalSetDialog> createState() => _GoalSetDialogState();
}

class _GoalSetDialogState extends ConsumerState<GoalSetDialog> {
  late List<String> _allowedGoalTypes;
  String _goalType = 'weight';
  final _valueController = TextEditingController();
  final _timeMinController = TextEditingController();
  final _timeSecController = TextEditingController();
  DateTime? _deadline;
  int _priority = 2; // 1=low, 2=medium, 3=high
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.recordType == 'reps') {
      _allowedGoalTypes = ['weight', 'reps', 'volume'];
    } else if (widget.recordType == 'time') {
      _allowedGoalTypes = ['time'];
    } else {
      _allowedGoalTypes = ['time', 'distance'];
    }
    _goalType = _allowedGoalTypes.first;
    if (widget.existing != null) {
      _goalType = widget.existing!.goalType;
      _priority = widget.existing!.priority;
      if (widget.existing!.goalType == 'time') {
        final totalSec = widget.existing!.goalValue.toInt();
        _timeMinController.text = (totalSec ~/ 60).toString();
        _timeSecController.text = (totalSec % 60).toString();
      } else {
        _valueController.text = _formatGoalValueForEdit(widget.existing!.goalValue);
      }
      if (widget.existing!.deadlineTs != null) {
        _deadline = DateTime.fromMillisecondsSinceEpoch(widget.existing!.deadlineTs! * 1000);
      }
    }
    // Time fields: no default value (leave empty for easier input)
  }

  String _formatGoalValueForEdit(double v) {
    if (_goalType == 'weight' || _goalType == 'volume') {
      return v == v.truncateToDouble() ? v.toInt().toString() : v.toString();
    }
    // distance: value is stored in meters, show in km (e.g. 2500 -> "2.5")
    if (_goalType == 'distance') {
      final km = v / 1000;
      return km == km.truncateToDouble() ? km.toInt().toString() : km.toString();
    }
    return v.toInt().toString();
  }

  @override
  void dispose() {
    _valueController.dispose();
    _timeMinController.dispose();
    _timeSecController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    double value;
    if (_goalType == 'time') {
      final min = int.tryParse(_timeMinController.text.trim()) ?? 0;
      final sec = int.tryParse(_timeSecController.text.trim()) ?? 0;
      value = (min * 60 + sec).toDouble();
      if (value <= 0) return;
    } else {
      final valueText = _valueController.text.trim();
      if (valueText.isEmpty) return;
      final parsed = double.tryParse(valueText);
      if (parsed == null || parsed <= 0) return;
      // distance: input is in km, store in meters
      value = _goalType == 'distance' ? parsed * 1000 : parsed;
    }

    setState(() => _saving = true);
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final entity = ExerciseGoalEntity(
      id: widget.existing?.id,
      exerciseId: widget.exerciseId,
      goalType: _goalType,
      goalValue: value,
      deadlineTs: _deadline != null ? _deadline!.millisecondsSinceEpoch ~/ 1000 : null,
      priority: _priority,
      createdAt: widget.existing?.createdAt ?? now,
      updatedAt: now,
    );
    await ref.read(exerciseGoalDaoProvider).upsert(entity);
    if (mounted) {
      ref.invalidate(exerciseGoalProvider(widget.exerciseId));
      ref.invalidate(allGoalsListProvider);
      setState(() => _saving = false);
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.goalDelete),
        content: Text(AppLocalizations.of(context)!.goalDeleteConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(MaterialLocalizations.of(ctx).cancelButtonLabel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(AppLocalizations.of(context)!.deleteButton),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _saving = true);
    await ref.read(exerciseGoalDaoProvider).deleteByExerciseId(widget.exerciseId);
    if (mounted) {
      ref.invalidate(exerciseGoalProvider(widget.exerciseId));
      ref.invalidate(allGoalsListProvider);
      setState(() => _saving = false);
      Navigator.of(context).pop(true);
    }
  }

  String _goalTypeLabel(String type) {
    final l10n = AppLocalizations.of(context)!;
    switch (type) {
      case 'weight': return l10n.goalTypeWeight;
      case 'reps': return l10n.goalTypeReps;
      case 'volume': return l10n.goalTypeVolume;
      case 'time': return l10n.goalTypeTime;
      case 'distance': return l10n.goalTypeDistance;
      default: return type;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.goalSetTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_allowedGoalTypes.length > 1) ...[
              DropdownButtonFormField<String>(
                value: _allowedGoalTypes.contains(_goalType) ? _goalType : _allowedGoalTypes.first,
                decoration: InputDecoration(labelText: l10n.goalValueLabel),
                items: _allowedGoalTypes.map((t) => DropdownMenuItem(value: t, child: Text(_goalTypeLabel(t)))).toList(),
                onChanged: (v) {
                  setState(() => _goalType = v ?? _goalType);
                },
              ),
              const SizedBox(height: 16),
            ],
            if (_goalType == 'time') ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _timeMinController,
                      decoration: InputDecoration(
                        labelText: l10n.goalTimeMinutes,
                        hintText: '0',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _timeSecController,
                      decoration: InputDecoration(
                        labelText: l10n.goalTimeSeconds,
                        hintText: '0',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
            ] else
              TextField(
                controller: _valueController,
                decoration: InputDecoration(
                  labelText: l10n.goalValueLabel,
                  hintText: _goalType == 'weight' ? widget.unit : (_goalType == 'distance' ? 'km' : ''),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                autofocus: true,
              ),
            const SizedBox(height: 16),
            Text(l10n.goalPriorityLabel, style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 4),
            Row(
              children: [
                ChoiceChip(
                  label: Text(l10n.goalPriorityLow),
                  selected: _priority == 1,
                  onSelected: (v) => setState(() => _priority = 1),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: Text(l10n.goalPriorityMedium),
                  selected: _priority == 2,
                  onSelected: (v) => setState(() => _priority = 2),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: Text(l10n.goalPriorityHigh),
                  selected: _priority == 3,
                  onSelected: (v) => setState(() => _priority = 3),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListTile(
              title: Text(l10n.goalDeadlineOptional),
              trailing: _deadline == null
                  ? TextButton(
                      onPressed: () async {
                        final d = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                        );
                        if (d != null) setState(() => _deadline = d);
                      },
                      child: const Text('選択'),
                    )
                  : Text(
                      '${_deadline!.year}/${_deadline!.month}/${_deadline!.day}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
            ),
          ],
        ),
      ),
      actions: [
        if (widget.existing != null)
          TextButton(
            onPressed: _saving ? null : _delete,
            child: Text(l10n.goalDelete, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : Text(l10n.goalSave),
        ),
      ],
    );
  }
}
