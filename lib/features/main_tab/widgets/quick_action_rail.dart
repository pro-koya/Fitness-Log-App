import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/timer_provider.dart';
import '../../../providers/workout_session_provider.dart';
import '../../../providers/routine_provider.dart';
import '../../workout_input/workout_input_screen.dart';
import '../../workout_input/widgets/timer_mini_widget.dart';
import '../../routine/widgets/routine_selector_modal.dart';
import '../../../data/entities/routine_template_entity.dart';
import '../../tutorial/providers/interactive_tutorial_provider.dart';

/// Collapsible vertical rail on the right: Timer, Start workout, Resume, Start from routine.
const double _kRailWidthExpanded = 56;
const double _kRailWidthCollapsed = 44;
const double _kButtonSize = 44;
const double _kTimerButtonSize = 52;

class QuickActionRail extends ConsumerStatefulWidget {
  final double bottomOffset;

  const QuickActionRail({super.key, this.bottomOffset = 0});

  @override
  ConsumerState<QuickActionRail> createState() => _QuickActionRailState();
}

class _QuickActionRailState extends ConsumerState<QuickActionRail> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final sessionAsync = ref.watch(workoutSessionNotifierProvider);
    final hasSession = sessionAsync.valueOrNull != null;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      width: _expanded ? _kRailWidthExpanded : _kRailWidthCollapsed,
      child: Material(
        elevation: 3,
        shadowColor: Colors.black26,
        borderRadius: const BorderRadius.horizontal(left: Radius.circular(20)),
        color: theme.colorScheme.surfaceContainerHigh,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // メニューは開閉ボタンの上に展開（開閉ボタンは常に同じ位置＝右下）
            if (_expanded) ...[
              _RailButton(
                size: _kButtonSize,
                icon: Icon(Icons.repeat_rounded, size: 22, color: theme.colorScheme.tertiary),
                tooltip: l10n.routineLoadIntoWorkout,
                onTap: () => _startFromRoutineModal(context),
              ),
              _RecordRailButton(
                hasSession: hasSession,
                sessionId: sessionAsync.valueOrNull?.id,
                onStart: () => _startWorkout(context),
                onResume: () {
                  final session = sessionAsync.valueOrNull;
                  if (session?.id != null) {
                    setState(() => _expanded = false);
                    _navigateToWorkout(context, session!.id!);
                  }
                },
              ),
              _TimerRailButton(theme: theme),
              const Divider(height: 1, indent: 8, endIndent: 8),
            ],
            // 開閉ボタンは常に下端に固定（同じところをタップで開く／閉じる）
            _RailButton(
              size: _kButtonSize,
              icon: Icon(
                _expanded ? Icons.chevron_right : Icons.chevron_left,
                size: 24,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              tooltip: _expanded ? l10n.timerClose : 'Quick actions',
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() => _expanded = !_expanded);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startWorkout(BuildContext context) async {
    final notifier = ref.read(workoutSessionNotifierProvider.notifier);
    final sessionId = await notifier.createNewSession();
    if (sessionId != null && context.mounted) {
      setState(() => _expanded = false);
      _navigateToWorkout(context, sessionId);
    }
  }

  Future<void> _startFromRoutineModal(BuildContext context) async {
    final sessionAsync = ref.read(workoutSessionNotifierProvider);
    final currentSession = sessionAsync.valueOrNull;
    final hasSession = currentSession != null;

    final routine = await showModalBottomSheet<RoutineTemplateEntity>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.25,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: const RoutineSelectorModal(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (routine == null || !context.mounted) return;

    if (hasSession && currentSession.id != null) {
      final l10n = AppLocalizations.of(context)!;
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.routineAddToCurrentWorkoutTitle),
          content: Text(l10n.routineAddToCurrentWorkoutMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.cancelButton),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l10n.routineLoadIntoWorkout),
            ),
          ],
        ),
      );
      if (confirm == true && context.mounted) {
        setState(() => _expanded = false);
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => WorkoutInputScreen(
              sessionId: currentSession.id!,
              addRoutineId: routine.id,
              isTutorialMode: ref.read(interactiveTutorialProvider).isActive,
            ),
          ),
        ).then((_) {
          ref.read(workoutSessionNotifierProvider.notifier).refresh();
          ref.invalidate(recentWorkoutItemsProvider);
        });
      }
      return;
    }

    final notifier = ref.read(workoutSessionNotifierProvider.notifier);
    final sessionId = await notifier.createNewSession();
    if (sessionId != null && context.mounted) {
      setState(() => _expanded = false);
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => WorkoutInputScreen(
            sessionId: sessionId,
            routineId: routine.id,
            isTutorialMode: ref.read(interactiveTutorialProvider).isActive,
          ),
        ),
      ).then((_) {
        ref.read(workoutSessionNotifierProvider.notifier).refresh();
        ref.invalidate(recentWorkoutItemsProvider);
      });
    }
  }

  void _navigateToWorkout(BuildContext context, int sessionId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => WorkoutInputScreen(
          sessionId: sessionId,
          isTutorialMode: ref.read(interactiveTutorialProvider).isActive,
        ),
      ),
    ).then((_) {
      ref.read(workoutSessionNotifierProvider.notifier).refresh();
      ref.invalidate(recentWorkoutItemsProvider);
    });
  }
}

class _RailButton extends StatelessWidget {
  final double size;
  final Widget icon;
  final String tooltip;
  final VoidCallback onTap;

  const _RailButton({
    required this.size,
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      preferBelow: false,
      verticalOffset: 0,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(width: size, height: size, child: Center(child: icon)),
        ),
      ),
    );
  }
}

/// 記録開始／記録の続きを1ボタンに統一。記録中は背景色で分かるようにする。
class _RecordRailButton extends StatelessWidget {
  final bool hasSession;
  final int? sessionId;
  final VoidCallback onStart;
  final VoidCallback onResume;

  const _RecordRailButton({
    required this.hasSession,
    required this.sessionId,
    required this.onStart,
    required this.onResume,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final tooltip = hasSession ? l10n.resumeWorkoutButton : l10n.startWorkoutButton;
    final label = l10n.navHomeLabel;
    final isRecording = hasSession && sessionId != null;

    return Tooltip(
      message: tooltip,
      preferBelow: false,
      child: Material(
        color: isRecording
            ? Colors.blue.withValues(alpha: 0.12)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            if (isRecording) {
              onResume();
            } else {
              onStart();
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: _kRailWidthExpanded,
            height: _kButtonSize,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isRecording ? Icons.edit_note : Icons.edit_note_outlined,
                  size: 24,
                  color: isRecording
                      ? Colors.blue.shade700
                      : theme.colorScheme.primary,
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: isRecording
                        ? Colors.blue.shade700
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
    );
  }
}

class _TimerRailButton extends ConsumerWidget {
  final ThemeData theme;

  const _TimerRailButton({required this.theme});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timerState = ref.watch(timerProvider);
    final isRunning = timerState.isRunning && timerState.lastSetSeconds > 0;
    final progress = timerState.lastSetSeconds > 0
        ? (timerState.seconds / timerState.lastSetSeconds).clamp(0.0, 1.0)
        : 1.0;

    return Tooltip(
      message: AppLocalizations.of(context)!.timerLabel,
      preferBelow: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Material(
          color: theme.colorScheme.primary,
          shape: const CircleBorder(),
          elevation: 2,
          child: InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => const TimerModalContent(),
              );
            },
            customBorder: const CircleBorder(),
            child: SizedBox(
              width: _kTimerButtonSize,
              height: _kTimerButtonSize,
              child: isRunning
                  ? Stack(
                      alignment: Alignment.center,
                      children: [
                        CustomPaint(
                          size: const Size(_kTimerButtonSize, _kTimerButtonSize),
                          painter: _CircleProgressPainter(
                            progress: progress,
                            color: theme.colorScheme.onPrimary,
                            backgroundColor: theme.colorScheme.onPrimary.withValues(alpha: 0.25),
                            strokeWidth: 2.5,
                          ),
                        ),
                        Text(
                          timerState.formattedTime,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: theme.colorScheme.onPrimary,
                          ),
                        ),
                      ],
                    )
                  : Icon(Icons.timer_outlined, size: 26, color: theme.colorScheme.onPrimary),
            ),
          ),
        ),
      ),
    );
  }
}

class _CircleProgressPainter extends CustomPainter {
  _CircleProgressPainter({
    required this.progress,
    required this.color,
    required this.backgroundColor,
    required this.strokeWidth,
  });

  final double progress;
  final Color color;
  final Color backgroundColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - strokeWidth / 2;
    final bg = Paint()..color = backgroundColor..style = PaintingStyle.stroke..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, bg);
    if (progress > 0) {
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        -(2 * math.pi * progress),
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_CircleProgressPainter old) =>
      old.progress != progress || old.color != color;
}
