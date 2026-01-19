import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Modal for editing workout start and end times (Google Calendar style)
class DateTimeEditModal extends StatefulWidget {
  final int initialStartedAt;
  final int? initialCompletedAt;

  const DateTimeEditModal({
    super.key,
    required this.initialStartedAt,
    this.initialCompletedAt,
  });

  @override
  State<DateTimeEditModal> createState() => _DateTimeEditModalState();
}

class _DateTimeEditModalState extends State<DateTimeEditModal> {
  late DateTime _date;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    final startDateTime = DateTime.fromMillisecondsSinceEpoch(widget.initialStartedAt * 1000);
    _date = DateTime(startDateTime.year, startDateTime.month, startDateTime.day);
    _startTime = TimeOfDay.fromDateTime(startDateTime);

    if (widget.initialCompletedAt != null) {
      final endDateTime = DateTime.fromMillisecondsSinceEpoch(widget.initialCompletedAt! * 1000);
      _endTime = TimeOfDay.fromDateTime(endDateTime);
    } else {
      _endTime = TimeOfDay.now();
    }

    _validateTimes();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _date = picked;
        _validateTimes();
      });
    }
  }

  Future<void> _selectStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
      initialEntryMode: TimePickerEntryMode.input,
    );

    if (picked != null) {
      setState(() {
        _startTime = picked;
        _validateTimes();
      });
    }
  }

  Future<void> _selectEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _endTime,
      initialEntryMode: TimePickerEntryMode.input,
    );

    if (picked != null) {
      setState(() {
        _endTime = picked;
        _validateTimes();
      });
    }
  }

  void _validateTimes() {
    final now = DateTime.now();

    // Build start and end DateTime
    final startDateTime = DateTime(
      _date.year,
      _date.month,
      _date.day,
      _startTime.hour,
      _startTime.minute,
    );

    final endDateTime = DateTime(
      _date.year,
      _date.month,
      _date.day,
      _endTime.hour,
      _endTime.minute,
    );

    // Check if in the future
    if (startDateTime.isAfter(now)) {
      _errorMessage = 'Start time cannot be in the future';
      return;
    }

    if (endDateTime.isAfter(now)) {
      _errorMessage = 'End time cannot be in the future';
      return;
    }

    // Check if start is before end
    if (startDateTime.isAfter(endDateTime) || startDateTime.isAtSameMomentAs(endDateTime)) {
      _errorMessage = 'Start time must be before end time';
      return;
    }

    _errorMessage = null;
  }

  void _handleSave() {
    _validateTimes();

    if (_errorMessage != null) {
      return;
    }

    final startDateTime = DateTime(
      _date.year,
      _date.month,
      _date.day,
      _startTime.hour,
      _startTime.minute,
    );

    final endDateTime = DateTime(
      _date.year,
      _date.month,
      _date.day,
      _endTime.hour,
      _endTime.minute,
    );

    final startedAt = startDateTime.millisecondsSinceEpoch ~/ 1000;
    final completedAt = endDateTime.millisecondsSinceEpoch ~/ 1000;

    Navigator.of(context).pop({
      'startedAt': startedAt,
      'completedAt': completedAt,
    });
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy/MM/dd (E)', 'en');

    return AlertDialog(
      title: const Text('Edit Workout Time'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date picker
            _buildPickerRow(
              label: 'Date',
              value: dateFormat.format(_date),
              icon: Icons.calendar_today,
              onTap: _selectDate,
            ),

            const SizedBox(height: 12),

            // Start time picker
            _buildPickerRow(
              label: 'Start Time',
              value: _startTime.format(context),
              icon: Icons.access_time,
              onTap: _selectStartTime,
            ),

            const SizedBox(height: 12),

            // End time picker
            _buildPickerRow(
              label: 'End Time',
              value: _endTime.format(context),
              icon: Icons.access_time,
              onTap: _selectEndTime,
            ),

            // Error message
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.red.shade300),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _errorMessage == null ? _handleSave : null,
          child: const Text('Save'),
        ),
      ],
    );
  }

  Widget _buildPickerRow({
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 6),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(4),
            splashColor: Colors.grey.shade200,
            highlightColor: Colors.grey.shade100,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Icon(icon, size: 20, color: Colors.grey.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      value,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Icon(Icons.arrow_drop_down, color: Colors.grey.shade600),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
