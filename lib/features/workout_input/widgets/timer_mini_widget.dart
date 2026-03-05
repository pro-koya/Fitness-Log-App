import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/settings_provider.dart';
import '../../../providers/timer_provider.dart';
import '../../../services/timer_notification_service.dart';

/// Mini timer widget (floating)
class TimerMiniWidget extends ConsumerStatefulWidget {
  const TimerMiniWidget({super.key});

  @override
  ConsumerState<TimerMiniWidget> createState() => _TimerMiniWidgetState();
}

class _TimerMiniWidgetState extends ConsumerState<TimerMiniWidget> {
  bool _hasShownNotification = false;

  @override
  void initState() {
    super.initState();
    _hasShownNotification = false;
  }

  @override
  Widget build(BuildContext context) {
    final timerState = ref.watch(timerProvider);

    // Check if timer just finished and show notification
    // Only show if notification hasn't been shown yet (prevents duplicate with global notification or modal)
    if (timerState.hasFinished &&
        !timerState.isRunning &&
        !timerState.notificationShown &&
        !_hasShownNotification) {
      _hasShownNotification = true;
      // Use addPostFrameCallback to show dialog after build completes
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Mark notification as shown AFTER build completes
        Future(() {
          ref.read(timerProvider.notifier).markNotificationShown();
        });
        _showTimerFinishedNotification();
      });
    }

    // Reset notification flag when timer is reset or started
    if (timerState.isRunning || (!timerState.hasFinished && _hasShownNotification)) {
      _hasShownNotification = false;
    }

    final colorScheme = Theme.of(context).colorScheme;

    return Positioned(
      right: 16,
      bottom: 100,
      child: GestureDetector(
        onTap: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => const TimerModalContent(),
          );
        },
        child: Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: timerState.isRunning ? colorScheme.primary : colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(40),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                timerState.formattedTime,
                style: TextStyle(
                  color: timerState.isRunning ? colorScheme.onPrimary : colorScheme.onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Icon(
                timerState.isRunning ? Icons.pause : Icons.play_arrow,
                color: timerState.isRunning ? colorScheme.onPrimary : colorScheme.onSurface,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showTimerFinishedNotification() async {
    if (!mounted) return;

    final settings = ref.read(timerSettingsProvider);
    await TimerNotificationService.play(settings);

    if (!mounted) return;

    final dialogColorScheme = Theme.of(context).colorScheme;

    // Show enhanced dialog
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Large timer icon with animation-like styling
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: dialogColorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.timer_off,
                size: 64,
                color: dialogColorScheme.primary,
              ),
            ),
            const SizedBox(height: 20),

            // Title
            Text(
              AppLocalizations.of(context)!.timerRestComplete,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // Message
            Text(
              AppLocalizations.of(context)!.timerRestCompleteMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: dialogColorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'OK',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      // Clear the finished flag and reset timer (will use custom time if set)
                      ref.read(timerProvider.notifier).clearFinished();
                      ref.read(timerProvider.notifier).reset();
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: dialogColorScheme.primary,
                      foregroundColor: dialogColorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Reset Timer',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    // Clear the finished flag after dialog is dismissed
    if (mounted) {
      ref.read(timerProvider.notifier).clearFinished();
    }
  }
}

/// Timer modal content (expanded view)
class TimerModalContent extends ConsumerStatefulWidget {
  const TimerModalContent({super.key});

  @override
  ConsumerState<TimerModalContent> createState() => _TimerModalContentState();
}

class _TimerModalContentState extends ConsumerState<TimerModalContent> {
  final TextEditingController _minutesController = TextEditingController();
  final TextEditingController _secondsController = TextEditingController();
  bool _isEditingTime = false;

  @override
  void dispose() {
    _minutesController.dispose();
    _secondsController.dispose();
    super.dispose();
  }

  void _startEditingTime(int currentSeconds) {
    if (!mounted) return;
    setState(() {
      _isEditingTime = true;
      _minutesController.text = (currentSeconds ~/ 60).toString();
      _secondsController.text = (currentSeconds % 60).toString();
    });
  }

  void _applyTimeAndExitEdit() {
    final minutes = int.tryParse(_minutesController.text.trim()) ?? 0;
    final seconds = int.tryParse(_secondsController.text.trim()) ?? 0;
    if (minutes < 0 || seconds < 0 || seconds >= 60) return;
    final totalSeconds = minutes * 60 + seconds;
    if (totalSeconds > 0) {
      final timerNotifier = ref.read(timerProvider.notifier);
      timerNotifier.setTime(totalSeconds);
      timerNotifier.reset();
    }
    if (!mounted) return;
    setState(() => _isEditingTime = false);
    FocusScope.of(context).unfocus();
  }

  /// Consumes arrow up/down to avoid Flutter's vertical caret assertion in single-line TextField.
  KeyEventResult _handleTimeFieldKey(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent &&
        (event.logicalKey == LogicalKeyboardKey.arrowUp ||
            event.logicalKey == LogicalKeyboardKey.arrowDown)) {
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  Widget _buildTimeEditRow(ThemeData theme, ColorScheme colorScheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 72,
          child: Focus(
            onKeyEvent: _handleTimeFieldKey,
            child: TextField(
              controller: _minutesController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(3),
              ],
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                hintText: '0',
              ),
              onChanged: (v) {
                if (v.length >= 2) FocusScope.of(context).nextFocus();
              },
              onSubmitted: (_) => FocusScope.of(context).nextFocus(),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            ':',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        SizedBox(
          width: 72,
          child: Focus(
            onKeyEvent: _handleTimeFieldKey,
            child: TextField(
              controller: _secondsController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(2),
              ],
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                hintText: '0',
              ),
              onSubmitted: (_) => _applyTimeAndExitEdit(),
            ),
          ),
        ),
        const SizedBox(width: 12),
        IconButton.filled(
          onPressed: _applyTimeAndExitEdit,
          icon: const Icon(Icons.check),
          tooltip: 'Set',
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final timerState = ref.watch(timerProvider);
    final timerNotifier = ref.read(timerProvider.notifier);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final viewInsets = MediaQuery.of(context).viewInsets;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusScope.of(context).unfocus(),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.only(bottom: viewInsets.bottom),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Timer display card (tappable when stopped → direct edit)
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: timerState.isRunning
                                ? null
                                : () {
                                    if (_isEditingTime) {
                                      _applyTimeAndExitEdit();
                                    } else {
                                      _startEditingTime(timerState.seconds);
                                    }
                                  },
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: timerState.isRunning
                                      ? [
                                          colorScheme.primaryContainer,
                                          colorScheme.primaryContainer.withValues(alpha: 0.7),
                                        ]
                                      : [
                                          colorScheme.surfaceContainerHighest,
                                          colorScheme.surfaceContainerHigh,
                                        ],
                                ),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: timerState.isRunning
                                      ? colorScheme.primary.withValues(alpha: 0.4)
                                      : colorScheme.outlineVariant.withValues(alpha: 0.6),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: colorScheme.shadow.withValues(alpha: 0.08),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: _isEditingTime && !timerState.isRunning
                                  ? _buildTimeEditRow(theme, colorScheme)
                                  : Center(
                                      child: Text(
                                        timerState.formattedTime,
                                        style: theme.textTheme.displayMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 4,
                                          color: timerState.isRunning
                                              ? colorScheme.primary
                                              : colorScheme.onSurface,
                                          fontFeatures: const [FontFeature.tabularFigures()],
                                        ),
                                      ),
                                    ),
                                    ),
                            ),
                          ),
                        if (!_isEditingTime && !timerState.isRunning)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              AppLocalizations.of(context)!.timerTapTimeToSet,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        const SizedBox(height: 40),
                        // Control buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            FilledButton(
                              onPressed: () {
                                if (timerState.isRunning) {
                                  timerNotifier.pause();
                                } else {
                                  timerNotifier.start();
                                }
                              },
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.all(24),
                                shape: const CircleBorder(),
                                backgroundColor: timerState.isRunning
                                    ? colorScheme.tertiary
                                    : colorScheme.primary,
                                foregroundColor: colorScheme.onPrimary,
                              ),
                              child: Icon(
                                timerState.isRunning ? Icons.pause : Icons.play_arrow,
                                size: 32,
                              ),
                            ),
                            FilledButton.tonal(
                              onPressed: () => timerNotifier.reset(),
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.all(24),
                                shape: const CircleBorder(),
                              ),
                              child: Icon(Icons.refresh, size: 32, color: colorScheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Text(
                          AppLocalizations.of(context)!.timerQuickStart,
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(child: _buildPresetChip(context, ref, _presetLabel(30), 30)),
                            const SizedBox(width: 6),
                            Expanded(child: _buildPresetChip(context, ref, _presetLabel(45), 45)),
                            const SizedBox(width: 6),
                            Expanded(child: _buildPresetChip(context, ref, _presetLabel(60), 60)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Expanded(child: _buildPresetChip(context, ref, _presetLabel(90), 90)),
                            const SizedBox(width: 6),
                            Expanded(child: _buildPresetChip(context, ref, _presetLabel(120), 120)),
                            const SizedBox(width: 6),
                            Expanded(child: _buildPresetChip(context, ref, _presetLabel(180), 180)),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, size: 20),
                      label: Text(AppLocalizations.of(context)!.timerClose, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        foregroundColor: colorScheme.primary,
                        side: BorderSide(color: colorScheme.primary, width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Format preset label: under 60 → "30"/"45", 60+ → "1:00"/"1:30"/"2:00"/"3:00"
  static String _presetLabel(int seconds) {
    if (seconds < 60) return '$seconds';
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  static const double _presetChipHeight = 48;

  Widget _buildPresetChip(
    BuildContext context,
    WidgetRef ref,
    String label,
    int seconds,
  ) {
    final timerState = ref.watch(timerProvider);
    final isSelected = timerState.seconds == seconds && !timerState.isRunning;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SizedBox(
      height: _presetChipHeight,
      child: Material(
        color: isSelected ? colorScheme.primaryContainer : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: timerState.isRunning
              ? null
              : () => ref.read(timerProvider.notifier).reset(seconds: seconds),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: double.infinity,
            height: _presetChipHeight,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? colorScheme.primary : colorScheme.outlineVariant,
                width: 1,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: isSelected ? colorScheme.onPrimaryContainer : colorScheme.onSurface,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
  }
}
