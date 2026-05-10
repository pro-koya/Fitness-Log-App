import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/dao/routine_template_dao.dart';
import '../../data/dao/routine_exercise_dao.dart';
import '../../data/dao/routine_set_dao.dart';
import '../../data/dao/workout_exercise_dao.dart';
import '../../data/dao/set_record_dao.dart';
import '../../data/localization/exercise_localization.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/routine_provider.dart';
import '../../providers/sync_providers.dart';
import '../../services/supabase_auth_service.dart';
import '../routine/services/routine_service.dart';
import 'models/workout_completion_result.dart';

enum _SyncAction { manual, apple, google }

/// Modal shown after workout is completed. Displays summary, exercise details, and muscle message.
class WorkoutCompletionModal extends ConsumerStatefulWidget {
  final WorkoutCompletionResult result;
  final VoidCallback onClose;

  const WorkoutCompletionModal({
    super.key,
    required this.result,
    required this.onClose,
  });

  static Future<void> show(
    BuildContext context, {
    required WorkoutCompletionResult result,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => WorkoutCompletionModal(
        result: result,
        onClose: () => Navigator.of(context).pop(),
      ),
    );
  }

  @override
  ConsumerState<WorkoutCompletionModal> createState() =>
      _WorkoutCompletionModalState();
}

class _WorkoutCompletionModalState
    extends ConsumerState<WorkoutCompletionModal> {
  bool _routineSaved = false;
  bool _syncDone = false;
  _SyncAction? _activeSyncAction;
  String? _syncError;

  bool get _isBusy => _activeSyncAction != null;

  String _formatDuration(int seconds) {
    if (seconds < 60) return '$seconds秒';
    final m = seconds ~/ 60;
    final s = seconds % 60;
    if (s == 0) return '$m分';
    return '$m分$s秒';
  }

  String _formatDurationEn(int seconds) {
    if (seconds < 60) {
      return '$seconds'
          's';
    }
    final m = seconds ~/ 60;
    final s = seconds % 60;
    if (s == 0) return '$m min';
    return '${m}m ${s}s';
  }

  /// トレーニングデータをクラウドに同期（Supabase に Push）
  Future<void> _syncToCloud() async {
    if (_isBusy) return;
    setState(() {
      _activeSyncAction = _SyncAction.manual;
      _syncError = null;
    });
    await _runCloudSync();
  }

  /// ログイン → 同期
  Future<void> _signInAndSync({required _SyncAction provider}) async {
    if (_isBusy) return;
    setState(() {
      _activeSyncAction = provider;
      _syncError = null;
    });
    try {
      final auth = ref.read(supabaseAuthServiceProvider);
      final result = provider == _SyncAction.apple
          ? await auth.signInWithApple()
          : await auth.signInWithGoogle();
      if (!mounted) return;

      switch (result) {
        case AuthSuccess():
          await _runCloudSync();
        case AuthFailure(:final message):
          setState(() {
            _activeSyncAction = null;
            if (message != 'cancelled') {
              _syncError = message;
            }
          });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _activeSyncAction = null;
          _syncError = e.toString();
        });
      }
    }
  }

  Future<void> _runCloudSync() async {
    try {
      final syncService = ref.read(syncServiceProvider);
      final error = await syncService.syncNow();
      if (!mounted) return;

      setState(() {
        _activeSyncAction = null;
        if (error == null) {
          _syncDone = true;
        } else {
          _syncError = error;
        }
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _activeSyncAction = null;
        _syncError = e.toString();
      });
    }
  }

  Future<void> _saveAsRoutine(BuildContext context) async {
    if (_isBusy) return;
    final l10n = AppLocalizations.of(context)!;
    final nameController = TextEditingController();

    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.routineSaveAsRoutine),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: InputDecoration(
            labelText: l10n.routineNameLabel,
            hintText: l10n.routineNameHint,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancelButton),
          ),
          TextButton(
            onPressed: () {
              final text = nameController.text.trim();
              if (text.isNotEmpty) {
                Navigator.of(context).pop(text);
              }
            },
            child: Text(l10n.routineSave),
          ),
        ],
      ),
    );

    if (name != null && name.isNotEmpty && context.mounted) {
      final service = RoutineService(
        templateDao: RoutineTemplateDao(),
        routineExerciseDao: RoutineExerciseDao(),
        routineSetDao: RoutineSetDao(),
        workoutExerciseDao: WorkoutExerciseDao(),
        setRecordDao: SetRecordDao(),
      );

      await service.createFromSession(
        name: name,
        sessionId: widget.result.sessionId,
      );

      if (context.mounted) {
        ref.invalidate(routineListProvider);
        setState(() => _routineSaved = true);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.routineSaved)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final unitLabel = widget.result.unit == 'kg' ? 'kg' : 'lb';
    final volumeStr = widget.result.totalVolume >= 1000
        ? '${(widget.result.totalVolume / 1000).toStringAsFixed(1)}k'
        : widget.result.totalVolume.toStringAsFixed(0);
    final isJa = Localizations.localeOf(context).languageCode == 'ja';

    return PopScope(
      canPop: !_isBusy,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 560),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.fitness_center,
                  size: 48,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.workoutCompletionTitle,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.workoutCompletionSummary(
                    widget.result.exerciseCount,
                    widget.result.setCount,
                    volumeStr,
                    unitLabel,
                  ),
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                if (widget.result.exerciseDetails.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: widget.result.exerciseDetails.map((e) {
                          String line;
                          if (e.isTimeBased && e.topDurationSeconds != null) {
                            final dur = isJa
                                ? _formatDuration(e.topDurationSeconds!)
                                : _formatDurationEn(e.topDurationSeconds!);
                            line = l10n.workoutCompletionExerciseLineTime(
                              e.name,
                              e.setCount,
                              dur,
                            );
                          } else if (e.topWeight != null) {
                            line = l10n.workoutCompletionExerciseLine(
                              e.name,
                              e.setCount,
                              e.topWeight!.toStringAsFixed(
                                e.topWeight! >= 100 ? 0 : 1,
                              ),
                              unitLabel,
                            );
                          } else {
                            line =
                                '${e.name} ${e.setCount}${isJa ? 'セット' : ' sets'}';
                          }
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Text(
                              line,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
                if (widget.result.achievedGoals.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      l10n.goalAchievedTitle,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  ...widget.result.achievedGoals.map((g) {
                    final displayName = ExerciseLocalization.getLocalizedName(
                      englishName: g.exerciseNameEn,
                      language: Localizations.localeOf(context).languageCode,
                      isStandard: g.isStandard,
                    );
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        l10n.goalAchievedMessage(displayName, g.valueStr),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }),
                ],
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primaryContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    widget.result.message,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 12),
                if (!_routineSaved)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _isBusy ? null : () => _saveAsRoutine(context),
                      icon: const Icon(Icons.repeat, size: 18),
                      label: Text(l10n.routineSaveAsRoutine),
                    ),
                  ),
                if (_routineSaved)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check, size: 16, color: Colors.green.shade700),
                      const SizedBox(width: 4),
                      Text(
                        l10n.routineSaved,
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 8),
                _buildSyncSection(isJa),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _isBusy ? null : widget.onClose,
                    child: Text(l10n.confirmButton),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// データ同期セクション
  Widget _buildSyncSection(bool isJa) {
    ref.watch(authStateChangesProvider);
    final auth = ref.watch(supabaseAuthServiceProvider);
    final isManualSyncing = _activeSyncAction == _SyncAction.manual;
    final isAppleSyncing = _activeSyncAction == _SyncAction.apple;
    final isGoogleSyncing = _activeSyncAction == _SyncAction.google;

    if (_syncDone) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle, size: 16, color: Colors.green.shade700),
          const SizedBox(width: 4),
          Text(
            isJa ? 'データをクラウドに同期しました' : 'Synced data to cloud',
            style: TextStyle(color: Colors.green.shade700, fontSize: 13),
          ),
        ],
      );
    }

    if (_syncError != null) {
      return Column(
        children: [
          Text(
            isJa ? '同期に失敗しました' : 'Sync failed',
            style: TextStyle(color: Colors.red.shade700, fontSize: 12),
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _isBusy ? null : () => _syncToCloud(),
              icon: const Icon(Icons.refresh, size: 18),
              label: Text(isJa ? 'リトライ' : 'Retry'),
            ),
          ),
        ],
      );
    }

    if (auth.isSignedIn) {
      // ログイン済み → 「データをクラウドに同期」ボタン
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: _isBusy ? null : () => _syncToCloud(),
          icon: isManualSyncing
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.sync, size: 18),
          label: Text(
            isManualSyncing
                ? (isJa ? '同期中...' : 'Syncing...')
                : (isJa ? 'データをクラウドに同期' : 'Sync data to cloud'),
          ),
        ),
      );
    } else {
      // 未ログイン → プロバイダーを選んで同期
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _isBusy
                  ? null
                  : () => _signInAndSync(provider: _SyncAction.apple),
              icon: isAppleSyncing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.apple, size: 18),
              label: Text(
                isAppleSyncing
                    ? (isJa ? 'ログイン中...' : 'Signing in...')
                    : (isJa ? 'Appleでログインして同期' : 'Sign in with Apple & sync'),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _isBusy
                  ? null
                  : () => _signInAndSync(provider: _SyncAction.google),
              icon: isGoogleSyncing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.g_mobiledata, size: 22),
              label: Text(
                isGoogleSyncing
                    ? (isJa ? 'ログイン中...' : 'Signing in...')
                    : (isJa ? 'Googleでログインして同期' : 'Sign in with Google & sync'),
              ),
            ),
          ),
        ],
      );
    }
  }
}
