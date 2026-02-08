import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/workout_exercise_model.dart';

/// Set row widget for weight and reps/duration/distance input
class SetRowWidget extends StatefulWidget {
  final SetRecordModel set;
  final bool canDuplicate;
  final bool canDelete;
  final Function(double? weight, int? reps, int? durationSeconds, double? distance) onUpdate;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;

  const SetRowWidget({
    super.key,
    required this.set,
    required this.canDuplicate,
    required this.canDelete,
    required this.onUpdate,
    required this.onDuplicate,
    required this.onDelete,
  });

  @override
  State<SetRowWidget> createState() => _SetRowWidgetState();
}

class _SetRowWidgetState extends State<SetRowWidget> {
  late TextEditingController _weightController;
  late TextEditingController _repsController;
  late TextEditingController _minutesController;
  late TextEditingController _secondsController;
  late TextEditingController _distanceController;

  @override
  void initState() {
    super.initState();
    _weightController = TextEditingController(
      text: widget.set.weight != null ? _formatNumber(widget.set.weight!) : '',
    );
    _repsController = TextEditingController(
      text: widget.set.reps != null ? widget.set.reps.toString() : '',
    );
    // Initialize minutes/seconds from durationSeconds
    final totalSeconds = widget.set.durationSeconds ?? 0;
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    _minutesController = TextEditingController(
      text: minutes > 0 ? minutes.toString() : '',
    );
    _secondsController = TextEditingController(
      text: seconds > 0 || minutes > 0 ? seconds.toString() : '',
    );
    _distanceController = TextEditingController(
      text: widget.set.distance != null ? _formatNumber(widget.set.distance!) : '',
    );
  }

  String _formatNumber(double value) {
    // If the value is a whole number, don't show decimal point
    if (value % 1 == 0) {
      return value.toInt().toString();
    }
    return value.toString();
  }

  @override
  void didUpdateWidget(SetRowWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update controllers if values changed externally
    if (widget.set.weight != oldWidget.set.weight) {
      _weightController.text =
          widget.set.weight != null ? _formatNumber(widget.set.weight!) : '';
    }
    if (widget.set.reps != oldWidget.set.reps) {
      _repsController.text =
          widget.set.reps != null ? widget.set.reps.toString() : '';
    }
    if (widget.set.durationSeconds != oldWidget.set.durationSeconds) {
      final totalSeconds = widget.set.durationSeconds ?? 0;
      final minutes = totalSeconds ~/ 60;
      final seconds = totalSeconds % 60;
      _minutesController.text = minutes > 0 ? minutes.toString() : '';
      _secondsController.text =
          seconds > 0 || minutes > 0 ? seconds.toString() : '';
    }
    if (widget.set.distance != oldWidget.set.distance) {
      _distanceController.text =
          widget.set.distance != null ? _formatNumber(widget.set.distance!) : '';
    }
  }

  @override
  void dispose() {
    _weightController.dispose();
    _repsController.dispose();
    _minutesController.dispose();
    _secondsController.dispose();
    _distanceController.dispose();
    super.dispose();
  }

  int _calculateDurationSeconds() {
    final minutes = int.tryParse(_minutesController.text) ?? 0;
    final seconds = int.tryParse(_secondsController.text) ?? 0;
    return (minutes * 60) + seconds;
  }

  double? _parseWeight() {
    final text = _weightController.text.trim();
    if (text.isEmpty) return null;
    return double.tryParse(text);
  }

  double? _parseDistance() {
    final text = _distanceController.text.trim();
    if (text.isEmpty) return null;
    return double.tryParse(text);
  }

  @override
  Widget build(BuildContext context) {
    final isTimeMode = widget.set.recordType == 'time';
    final isCardioMode = widget.set.recordType == 'cardio';

    // Cardio mode uses a different layout (time + distance in a column)
    if (isCardioMode) {
      return _buildCardioLayout();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          // Set number
          SizedBox(
            width: 28,
            child: Semantics(
              label: 'Set ${widget.set.setNumber}',
              child: Text(
                'S${widget.set.setNumber}',
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.grey,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),

          // Weight input
          (isTimeMode
              ? Flexible(
                  flex: 3,
                  child: _buildNumberInput(
                    controller: _weightController,
                    label: widget.set.unit,
                    onChanged: (value) {
                      final weight = double.tryParse(value);
                      // Keep duration intact even if weight is edited after setting time.
                      widget.onUpdate(weight, null, _calculateDurationSeconds(), null);
                    },
                  ),
                )
              : Expanded(
                  child: _buildNumberInput(
                    controller: _weightController,
                    label: widget.set.unit,
                    onChanged: (value) {
                      final weight = double.tryParse(value);
                      widget.onUpdate(weight, widget.set.reps, null, null);
                    },
                  ),
                )),

          const SizedBox(width: 6),

          // Reps or Duration input based on recordType
          if (isTimeMode) ...[
            // Duration input (minutes:seconds)
            // Minutes input
            Flexible(
              flex: 3,
              child: _buildNumberInput(
                controller: _minutesController,
                label: 'm',
                onChanged: (value) {
                  final durationSeconds = _calculateDurationSeconds();
                  // Keep weight intact even if minutes/seconds are edited after weight.
                  widget.onUpdate(_parseWeight(), null, durationSeconds, null);
                },
                allowDecimal: false,
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 2),
              child: Text(
                ':',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ),
            // Seconds input
            Flexible(
              flex: 3,
              child: _buildNumberInput(
                controller: _secondsController,
                label: 's',
                onChanged: (value) {
                  final durationSeconds = _calculateDurationSeconds();
                  widget.onUpdate(_parseWeight(), null, durationSeconds, null);
                },
                allowDecimal: false,
                maxValue: 59,
              ),
            ),
          ] else ...[
            // Reps input
            Expanded(
              child: _buildNumberInput(
                controller: _repsController,
                label: 'reps',
                onChanged: (value) {
                  final reps = int.tryParse(value);
                  widget.onUpdate(widget.set.weight, reps, null, null);
                },
                allowDecimal: false,
              ),
            ),
          ],

          const SizedBox(width: 4),

          // Duplicate set button
          IconButton(
            icon: const Icon(Icons.content_copy),
            iconSize: 16,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 22, height: 22),
            visualDensity: VisualDensity.compact,
            onPressed: widget.canDuplicate ? widget.onDuplicate : null,
            color: widget.canDuplicate ? Colors.blue : Colors.grey,
            tooltip: 'Duplicate set',
          ),

          // Delete button
          IconButton(
            icon: const Icon(Icons.close),
            iconSize: 16,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 22, height: 22),
            visualDensity: VisualDensity.compact,
            onPressed: widget.canDelete ? widget.onDelete : null,
            color: widget.canDelete ? Colors.red : Colors.grey,
            tooltip: 'Delete set',
          ),
        ],
      ),
    );
  }

  /// Build cardio-specific layout (time + distance)
  Widget _buildCardioLayout() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          // Set number
          SizedBox(
            width: 28,
            child: Semantics(
              label: 'Set ${widget.set.setNumber}',
              child: Text(
                'S${widget.set.setNumber}',
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.grey,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),

          // Time input (minutes:seconds)
          Flexible(
            flex: 2,
            child: _buildNumberInput(
              controller: _minutesController,
              label: 'm',
              onChanged: (value) {
                final durationSeconds = _calculateDurationSeconds();
                widget.onUpdate(null, null, durationSeconds, _parseDistance());
              },
              allowDecimal: false,
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 2),
            child: Text(
              ':',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Flexible(
            flex: 2,
            child: _buildNumberInput(
              controller: _secondsController,
              label: 's',
              onChanged: (value) {
                final durationSeconds = _calculateDurationSeconds();
                widget.onUpdate(null, null, durationSeconds, _parseDistance());
              },
              allowDecimal: false,
              maxValue: 59,
            ),
          ),

          const SizedBox(width: 6),

          // Distance input
          Flexible(
            flex: 3,
            child: _buildNumberInput(
              controller: _distanceController,
              label: widget.set.distanceUnit,
              onChanged: (value) {
                final distance = double.tryParse(value);
                widget.onUpdate(null, null, _calculateDurationSeconds(), distance);
              },
            ),
          ),

          const SizedBox(width: 4),

          // Duplicate set button
          IconButton(
            icon: const Icon(Icons.content_copy),
            iconSize: 16,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 22, height: 22),
            visualDensity: VisualDensity.compact,
            onPressed: widget.canDuplicate ? widget.onDuplicate : null,
            color: widget.canDuplicate ? Colors.blue : Colors.grey,
            tooltip: 'Duplicate set',
          ),

          // Delete button
          IconButton(
            icon: const Icon(Icons.close),
            iconSize: 16,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 22, height: 22),
            visualDensity: VisualDensity.compact,
            onPressed: widget.canDelete ? widget.onDelete : null,
            color: widget.canDelete ? Colors.red : Colors.grey,
            tooltip: 'Delete set',
          ),
        ],
      ),
    );
  }

  Widget _buildNumberInput({
    required TextEditingController controller,
    required String label,
    required Function(String) onChanged,
    bool allowDecimal = true,
    int? maxValue,
  }) {
    return TextField(
      controller: controller,
      keyboardType: allowDecimal
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.number,
      inputFormatters: [
        if (allowDecimal)
          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))
        else
          FilteringTextInputFormatter.digitsOnly,
        if (maxValue != null) _MaxValueFormatter(maxValue),
      ],
      decoration: InputDecoration(
        suffixText: label,
        suffixStyle: const TextStyle(fontSize: 12, color: Colors.grey),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.blue, width: 2),
        ),
      ),
      onChanged: onChanged,
      onTapOutside: (event) {
        FocusScope.of(context).unfocus();
      },
    );
  }
}

/// Input formatter to limit max value
class _MaxValueFormatter extends TextInputFormatter {
  final int maxValue;

  _MaxValueFormatter(this.maxValue);

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;
    final value = int.tryParse(newValue.text);
    if (value == null || value > maxValue) {
      return oldValue;
    }
    return newValue;
  }
}
