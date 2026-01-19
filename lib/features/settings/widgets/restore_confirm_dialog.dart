import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../data/models/backup_data.dart';
import '../../../l10n/app_localizations.dart';

/// バックアップ復元の確認ダイアログ
class RestoreConfirmDialog extends StatelessWidget {
  final BackupData backup;

  const RestoreConfirmDialog({
    super.key,
    required this.backup,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dateFormatter = DateFormat.yMd().add_Hm();

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.warning_amber, color: Colors.orange.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              l10n.restoreConfirmTitle,
              style: const TextStyle(fontSize: 18),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // バックアップ情報
          _buildInfoRow(
            Icons.calendar_today,
            l10n.restoreConfirmBackupDate(
              dateFormatter.format(backup.createdAt),
            ),
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            Icons.fitness_center,
            l10n.restoreConfirmSessionCount(backup.data.completedSessionCount),
          ),
          _buildInfoRow(
            Icons.list,
            l10n.restoreConfirmExerciseCount(backup.data.exerciseCount),
          ),
          const SizedBox(height: 16),

          // 警告メッセージ
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.warning, color: Colors.red.shade700, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.restoreConfirmWarning,
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l10n.cancelButton),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          style: FilledButton.styleFrom(
            backgroundColor: Colors.orange,
          ),
          child: Text(l10n.restoreButton),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
