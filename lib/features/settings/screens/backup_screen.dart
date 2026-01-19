import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/workout_session_provider.dart';
import '../../../services/backup_service.dart';
import '../widgets/restore_confirm_dialog.dart';

/// バックアップ/復元画面
class BackupScreen extends ConsumerStatefulWidget {
  const BackupScreen({super.key});

  @override
  ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends ConsumerState<BackupScreen> {
  bool _isLoading = false;
  String? _loadingMessage;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.backupTitle),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // バックアップセクション
                _buildBackupSection(l10n),
                const SizedBox(height: 16),

                // 復元セクション
                _buildRestoreSection(l10n),
                const SizedBox(height: 24),

                // 注意事項
                _buildWarningSection(l10n),
              ],
            ),
          ),

          // ローディングオーバーレイ
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: Center(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        if (_loadingMessage != null) ...[
                          const SizedBox(height: 16),
                          Text(_loadingMessage!),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// バックアップ作成セクション
  Widget _buildBackupSection(AppLocalizations l10n) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.backup,
                    size: 32,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.backupSectionTitle,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.backupSectionDescription,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isLoading ? null : _createBackup,
                icon: const Icon(Icons.upload),
                label: Text(l10n.createBackupButton),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 復元セクション
  Widget _buildRestoreSection(AppLocalizations l10n) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.restore,
                    size: 32,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.restoreSectionTitle,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.restoreSectionDescription,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isLoading ? null : _restoreBackup,
                icon: const Icon(Icons.download),
                label: Text(l10n.restoreBackupButton),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 警告セクション
  Widget _buildWarningSection(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            color: Colors.orange.shade700,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              l10n.backupWarning,
              style: TextStyle(
                color: Colors.orange.shade800,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// バックアップを作成
  Future<void> _createBackup() async {
    final l10n = AppLocalizations.of(context)!;

    setState(() {
      _isLoading = true;
      _loadingMessage = l10n.creatingBackup;
    });

    try {
      final backupService = ref.read(backupServiceProvider);
      // ドキュメントディレクトリに保存
      final savedPath = await backupService.exportToDocuments();

      if (mounted) {
        // 成功メッセージとファイルパスを表示
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.backupCreated),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );

        // ファイルの場所を案内するダイアログ
        _showBackupSuccessDialog(savedPath);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadingMessage = null;
        });
      }
    }
  }

  /// バックアップ成功ダイアログを表示
  void _showBackupSuccessDialog(String filePath) {
    final fileName = filePath.split('/').last;
    final isJapanese = Localizations.localeOf(context).languageCode == 'ja';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isJapanese ? 'バックアップ完了' : 'Backup Complete'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isJapanese
                  ? 'バックアップファイルが保存されました。'
                  : 'Backup file has been saved.',
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                fileName,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              isJapanese
                  ? '「ファイル」アプリからアクセスできます。\n別の端末に転送するには、AirDrop やクラウドストレージをご利用ください。'
                  : 'You can access it from the Files app.\nTo transfer to another device, use AirDrop or cloud storage.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(isJapanese ? '閉じる' : 'Close'),
          ),
        ],
      ),
    );
  }

  /// バックアップから復元
  Future<void> _restoreBackup() async {
    final backupService = ref.read(backupServiceProvider);
    final l10n = AppLocalizations.of(context)!;

    setState(() {
      _isLoading = true;
      _loadingMessage = l10n.loadingBackup;
    });

    try {
      final backup = await backupService.pickAndParseBackup();

      if (backup == null) {
        // ユーザーがキャンセル
        setState(() {
          _isLoading = false;
          _loadingMessage = null;
        });
        return;
      }

      setState(() {
        _isLoading = false;
        _loadingMessage = null;
      });

      if (!mounted) return;

      // 確認ダイアログ表示
      final confirmed = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => RestoreConfirmDialog(backup: backup),
      );

      if (confirmed == true && mounted) {
        setState(() {
          _isLoading = true;
          _loadingMessage = l10n.restoringData;
        });

        await backupService.restore(backup);

        // 復元完了後、関連するプロバイダーをリフレッシュ
        ref.invalidate(recentWorkoutsProvider);
        ref.invalidate(recentWorkoutItemsProvider);
        ref.invalidate(workoutSessionNotifierProvider);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.restoreCompleted),
              backgroundColor: Colors.green,
            ),
          );
          // 復元完了後、設定画面に戻る
          Navigator.pop(context, true);
        }
      }
    } on BackupParseException catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.invalidBackupFile),
            backgroundColor: Colors.red,
          ),
        );
      }
    } on BackupVersionException catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.incompatibleBackupVersion),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadingMessage = null;
        });
      }
    }
  }
}
