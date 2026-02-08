import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/timer_provider.dart';
import 'timer_mini_widget.dart';

/// Timer widget for AppBar
/// Shows a compact timer display with continuously animated progress ring border
class TimerIconButton extends ConsumerStatefulWidget {
  const TimerIconButton({super.key});

  @override
  ConsumerState<TimerIconButton> createState() => _TimerIconButtonState();
}

class _TimerIconButtonState extends ConsumerState<TimerIconButton> {
  Timer? _smoothTimer;
  double _displayProgress = 1.0;
  int _lastSeconds = 0;
  int _lastSetSeconds = 0;

  @override
  void dispose() {
    _smoothTimer?.cancel();
    super.dispose();
  }

  void _startSmoothTimer(TimerState timerState) {
    _smoothTimer?.cancel();

    if (!timerState.isRunning || timerState.lastSetSeconds <= 0) {
      return;
    }

    // Update every 50ms for smooth animation
    _smoothTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      final currentTimerState = ref.read(timerProvider);
      if (!currentTimerState.isRunning) {
        timer.cancel();
        return;
      }

      // Calculate precise progress based on elapsed time
      // Decrease by 1/20 of a second's worth every 50ms
      final decrementPerTick = 1.0 / (currentTimerState.lastSetSeconds * 20);
      setState(() {
        _displayProgress = (_displayProgress - decrementPerTick).clamp(0.0, 1.0);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final timerState = ref.watch(timerProvider);
    final colorScheme = Theme.of(context).colorScheme;

    // Sync display progress when seconds change or timer state changes
    if (timerState.seconds != _lastSeconds ||
        timerState.lastSetSeconds != _lastSetSeconds) {
      _lastSeconds = timerState.seconds;
      _lastSetSeconds = timerState.lastSetSeconds;

      if (timerState.lastSetSeconds > 0) {
        _displayProgress = timerState.seconds / timerState.lastSetSeconds;
      } else {
        _displayProgress = 1.0;
      }

      // Start or stop smooth timer based on running state
      if (timerState.isRunning) {
        _startSmoothTimer(timerState);
      } else {
        _smoothTimer?.cancel();
      }
    }

    // Handle running state change
    if (timerState.isRunning && _smoothTimer == null) {
      _startSmoothTimer(timerState);
    } else if (!timerState.isRunning && _smoothTimer != null) {
      _smoothTimer?.cancel();
      _smoothTimer = null;
    }

    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => const TimerModalContent(),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: timerState.seconds > 0 || timerState.isRunning
            ? _buildTimerWithProgress(timerState, colorScheme)
            : _buildTimerIcon(colorScheme),
      ),
    );
  }

  /// Build timer display with continuously animated progress ring border
  Widget _buildTimerWithProgress(TimerState timerState, ColorScheme colorScheme) {
    final isRunning = timerState.isRunning;

    final textColor = colorScheme.onPrimary;
    final ringColor = colorScheme.onPrimary;
    final backgroundColor = colorScheme.onPrimary.withValues(alpha: 0.1);

    return CustomPaint(
      painter: _ProgressRingPainter(
        progress: _displayProgress.clamp(0.0, 1.0),
        ringColor: ringColor,
        backgroundColor: backgroundColor,
        strokeWidth: 2.5,
        isRunning: isRunning,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          timerState.formattedTime,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: textColor,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  /// Build simple timer icon when no time is set
  Widget _buildTimerIcon(ColorScheme colorScheme) {
    return Icon(
      Icons.timer_outlined,
      size: 22,
      color: colorScheme.onPrimary,
    );
  }
}

/// Custom painter for progress ring border (counter-clockwise reduction)
class _ProgressRingPainter extends CustomPainter {
  final double progress;
  final Color ringColor;
  final Color backgroundColor;
  final double strokeWidth;
  final bool isRunning;

  _ProgressRingPainter({
    required this.progress,
    required this.ringColor,
    required this.backgroundColor,
    required this.strokeWidth,
    required this.isRunning,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(12));

    // Background border (track)
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawRRect(rrect, backgroundPaint);

    // Progress border (counter-clockwise from top-center, so it reduces clockwise)
    if (progress > 0) {
      final progressPaint = Paint()
        ..color = isRunning ? ringColor : ringColor.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      // Calculate path length for rounded rectangle
      final totalLength = _calculateRRectPerimeter(size, 12);
      final progressLength = totalLength * progress;

      // Draw progress along the rounded rectangle border (counter-clockwise)
      // This makes the gauge appear to reduce in clockwise direction
      final path = _createCounterClockwiseRRectPath(size, 12);
      final pathMetrics = path.computeMetrics().first;
      final progressPath = pathMetrics.extractPath(0, progressLength);

      canvas.drawPath(progressPath, progressPaint);
    }
  }

  double _calculateRRectPerimeter(Size size, double radius) {
    // Approximate perimeter of rounded rectangle
    final straightParts = 2 * (size.width - 2 * radius) + 2 * (size.height - 2 * radius);
    final cornerParts = 2 * math.pi * radius; // 4 quarter circles = 1 full circle
    return straightParts + cornerParts;
  }

  /// Create path that goes counter-clockwise from top-center
  /// This makes the progress appear to shrink in clockwise direction
  Path _createCounterClockwiseRRectPath(Size size, double radius) {
    final path = Path();

    // Start from top-center and go counter-clockwise (left first)
    path.moveTo(size.width / 2, 0);

    // Top edge to top-left corner
    path.lineTo(radius, 0);
    path.arcToPoint(
      Offset(0, radius),
      radius: Radius.circular(radius),
      clockwise: false,
    );

    // Left edge to bottom-left corner
    path.lineTo(0, size.height - radius);
    path.arcToPoint(
      Offset(radius, size.height),
      radius: Radius.circular(radius),
      clockwise: false,
    );

    // Bottom edge to bottom-right corner
    path.lineTo(size.width - radius, size.height);
    path.arcToPoint(
      Offset(size.width, size.height - radius),
      radius: Radius.circular(radius),
      clockwise: false,
    );

    // Right edge to top-right corner
    path.lineTo(size.width, radius);
    path.arcToPoint(
      Offset(size.width - radius, 0),
      radius: Radius.circular(radius),
      clockwise: false,
    );

    // Back to start
    path.lineTo(size.width / 2, 0);

    return path;
  }

  @override
  bool shouldRepaint(_ProgressRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.isRunning != isRunning ||
        oldDelegate.ringColor != ringColor;
  }
}
