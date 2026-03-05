import 'package:flutter/material.dart';
import '../models/routine_model.dart';

/// A single set row in routine editing (target weight/reps/duration/distance)
class RoutineSetRow extends StatelessWidget {
  final RoutineSetModel setModel;
  final int exerciseIndex;
  final int setIndex;
  final void Function(int exerciseIndex, int setIndex, {double? weight, int? reps, int? durationSeconds, double? distance}) onUpdate;
  final void Function(int exerciseIndex, int setIndex) onDelete;

  const RoutineSetRow({
    super.key,
    required this.setModel,
    required this.exerciseIndex,
    required this.setIndex,
    required this.onUpdate,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final recordType = setModel.recordType;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          // Set number
          SizedBox(
            width: 28,
            child: Text(
              '${setModel.setNumber}',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 8),

          // Weight input (for reps and time types)
          if (recordType != 'cardio')
            SizedBox(
              width: 72,
              child: _NumberField(
                value: setModel.weight,
                suffix: setModel.unit,
                isDecimal: true,
                onChanged: (v) => onUpdate(exerciseIndex, setIndex, weight: v),
              ),
            ),

          if (recordType != 'cardio') const SizedBox(width: 8),

          // Reps input (for reps type)
          if (recordType == 'reps')
            SizedBox(
              width: 64,
              child: _NumberField(
                value: setModel.reps?.toDouble(),
                suffix: 'reps',
                isDecimal: false,
                onChanged: (v) => onUpdate(exerciseIndex, setIndex, reps: v?.toInt()),
              ),
            ),

          // Duration input (for time and cardio types)
          if (recordType == 'time' || recordType == 'cardio')
            SizedBox(
              width: 72,
              child: _NumberField(
                value: setModel.durationSeconds?.toDouble(),
                suffix: 's',
                isDecimal: false,
                onChanged: (v) => onUpdate(exerciseIndex, setIndex, durationSeconds: v?.toInt()),
              ),
            ),

          // Distance input (for cardio type)
          if (recordType == 'cardio') ...[
            const SizedBox(width: 8),
            SizedBox(
              width: 72,
              child: _NumberField(
                value: setModel.distance,
                suffix: setModel.distanceUnit,
                isDecimal: true,
                onChanged: (v) => onUpdate(exerciseIndex, setIndex, distance: v),
              ),
            ),
          ],

          const Spacer(),

          // Delete button
          SizedBox(
            width: 32,
            height: 32,
            child: IconButton(
              icon: const Icon(Icons.close, size: 16),
              onPressed: () => onDelete(exerciseIndex, setIndex),
              padding: EdgeInsets.zero,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}

class _NumberField extends StatefulWidget {
  final double? value;
  final String suffix;
  final bool isDecimal;
  final void Function(double?) onChanged;

  const _NumberField({
    required this.value,
    required this.suffix,
    required this.isDecimal,
    required this.onChanged,
  });

  @override
  State<_NumberField> createState() => _NumberFieldState();
}

class _NumberFieldState extends State<_NumberField> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.value != null
          ? (widget.isDecimal
              ? (widget.value! == widget.value!.roundToDouble()
                  ? widget.value!.toInt().toString()
                  : widget.value!.toStringAsFixed(1))
              : widget.value!.toInt().toString())
          : '',
    );
  }

  @override
  void didUpdateWidget(covariant _NumberField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Don't update if user is typing
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      keyboardType: TextInputType.numberWithOptions(decimal: widget.isDecimal),
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        suffixText: widget.suffix,
        suffixStyle: TextStyle(fontSize: 11, color: Colors.grey[600]),
      ),
      onChanged: (text) {
        if (text.isEmpty) {
          widget.onChanged(null);
        } else {
          final parsed = double.tryParse(text);
          if (parsed != null) {
            widget.onChanged(parsed);
          }
        }
      },
    );
  }
}
