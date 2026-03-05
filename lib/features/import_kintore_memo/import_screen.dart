import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/database_providers.dart';
import '../../providers/workout_session_provider.dart';
import 'import_service.dart';
import '../ads/widgets/banner_ad_widget.dart';
import 'data/sqlite_workout_repository.dart';

/// 筋トレMemoインポート画面
class ImportKintoreMemoScreen extends ConsumerStatefulWidget {
  const ImportKintoreMemoScreen({super.key});

  @override
  ConsumerState<ImportKintoreMemoScreen> createState() =>
      _ImportKintoreMemoScreenState();
}

class _ImportKintoreMemoScreenState extends ConsumerState<ImportKintoreMemoScreen> {
  ImportPreview? _preview;
  bool _isAnalyzing = false;
  bool _isImporting = false;
  String? _errorMessage;
  ImportErrorType? _errorType;

  static final _dateFormat = DateFormat('yyyy/MM/dd');

  Future<void> _pickAndParse() async {
    setState(() {
      _preview = null;
      _errorMessage = null;
      _errorType = null;
      _isAnalyzing = true;
    });

    try {
      final file = await ImportService.pickRealmFile();
      if (!mounted) return;
      if (file == null) {
        setState(() {
          _isAnalyzing = false;
        });
        return;
      }

      final preview = await ImportService.parseRealmFile(file);
      if (!mounted) return;
      setState(() {
        _preview = preview;
        _isAnalyzing = false;
        _errorMessage = null;
      });
    } on ImportException catch (e) {
      if (!mounted) return;
      setState(() {
        _isAnalyzing = false;
        _errorMessage = e.message;
        _errorType = e.type;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isAnalyzing = false;
        _errorMessage = e.toString();
        _errorType = ImportErrorType.unknown;
      });
    }
  }

  Future<void> _executeImport({bool forceReimport = false}) async {
    if (_preview == null || _preview!.workouts.isEmpty) return;

    setState(() {
      _isImporting = true;
      _errorMessage = null;
    });

    try {
      final repository = SqliteWorkoutRepository();

      // 再インポート時はハッシュをクリア
      if (forceReimport) {
        await repository.clearImportHashes('kintore_memo');
      }

      final result = await ImportService.executeImport(_preview!, repository);

      if (!mounted) return;

      // 全件スキップ（既にインポート済み）→ 再インポート確認
      if (result.sessionsCreated == 0 && result.skippedDuplicate > 0) {
        setState(() => _isImporting = false);
        final shouldReimport = await _showReimportDialog();
        if (shouldReimport == true) {
          await _executeImport(forceReimport: true);
        }
        return;
      }

      // 関連するプロバイダーをリフレッシュ
      ref.read(databaseStateProvider.notifier).state++;
      ref.invalidate(recentWorkoutsProvider);
      ref.invalidate(recentWorkoutItemsProvider);
      ref.invalidate(workoutSessionNotifierProvider);

      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.importSuccess(
              result.sessionsCreated,
              result.setsCreated,
            ),
          ),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isImporting = false;
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() => _isImporting = false);
      }
    }
  }

  Future<bool?> _showReimportDialog() {
    final l10n = AppLocalizations.of(context)!;
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.importReimportTitle),
        content: Text(l10n.importReimportMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.importReimportCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.importReimportConfirm),
          ),
        ],
      ),
    );
  }

  String _getUserFriendlyError() {
    if (_errorMessage == null) return '';
    switch (_errorType) {
      case ImportErrorType.encrypted:
        return AppLocalizations.of(context)?.importErrorEncrypted ?? _errorMessage!;
      case ImportErrorType.schemaMismatch:
        return AppLocalizations.of(context)?.importErrorSchemaMismatch ?? _errorMessage!;
      case ImportErrorType.invalidFile:
        return AppLocalizations.of(context)?.importErrorInvalidFile ?? _errorMessage!;
      default:
        return AppLocalizations.of(context)?.importErrorUnknown(_errorMessage!) ?? _errorMessage!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.importKintoreMemoTitle),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 説明
                      Text(
                        l10n.importKintoreMemoDescription,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // インポートガイド
                      _buildGuideCard(l10n),
                      const SizedBox(height: 24),

                      // ファイル選択ボタン
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _isAnalyzing ? null : _pickAndParse,
                          icon: _isAnalyzing
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.folder_open),
                          label: Text(
                            _isAnalyzing ? l10n.importAnalyzing : l10n.importSelectFile,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // エラー表示
                      if (_errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline, color: Colors.red.shade700),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _getUserFriendlyError(),
                                  style: TextStyle(
                                    color: Colors.red.shade900,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // プレビュー
                      if (_preview != null) ...[
                        _buildPreviewCard(l10n),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _preview!.workouts.isEmpty || _isImporting
                                ? null
                                : _executeImport,
                            icon: _isImporting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.download),
                            label: Text(l10n.importExecute),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              // Banner ad (Free users only)
              const BannerAdWidget(),
            ],
          ),
          if (_isImporting)
            Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGuideCard(AppLocalizations l10n) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        leading: Icon(Icons.help_outline, color: primaryColor),
        title: Text(
          l10n.importGuideTitle,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 1),
          const SizedBox(height: 16),
          _buildGuideStep(1, Icons.computer, l10n.importGuideStep1Title, l10n.importGuideStep1Desc, primaryColor),
          const SizedBox(height: 16),
          _buildGuideStep(2, Icons.search, l10n.importGuideStep2Title, l10n.importGuideStep2Desc, primaryColor),
          const SizedBox(height: 16),
          _buildGuideStep(3, Icons.send_to_mobile, l10n.importGuideStep3Title, l10n.importGuideStep3Desc, primaryColor),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.lightbulb_outline, size: 18, color: Colors.amber.shade700),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.importGuideTip,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGuideStep(int step, IconData icon, String title, String description, Color primaryColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: primaryColor,
          child: Text(
            '$step',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewCard(AppLocalizations l10n) {
    final p = _preview!;
    final dateStartStr = p.dateRange != null
        ? _dateFormat.format(p.dateRange!.$1)
        : '-';
    final dateEndStr = p.dateRange != null
        ? _dateFormat.format(p.dateRange!.$2)
        : '-';
    final exercisesStr = p.sampleExercises.isNotEmpty
        ? p.sampleExercises.join(', ')
        : '-';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.importPreviewTitle,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildPreviewRow(
              l10n.importPreviewWorkoutCount(p.workoutCount),
            ),
            _buildPreviewRow(
              l10n.importPreviewTotalSets(p.totalSets),
            ),
            _buildPreviewRow(
              l10n.importPreviewDateRange(dateEndStr, dateStartStr),
            ),
            _buildPreviewRow(
              l10n.importPreviewSampleExercises(exercisesStr),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewRow(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(text, style: const TextStyle(fontSize: 14)),
    );
  }
}
