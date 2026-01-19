import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/timer_provider.dart';
import 'timer_mini_widget.dart';

/// Timer icon button for AppBar
/// Shows timer icon with current time and opens timer modal on tap
class TimerIconButton extends ConsumerStatefulWidget {
  const TimerIconButton({super.key});

  @override
  ConsumerState<TimerIconButton> createState() => _TimerIconButtonState();
}

class _TimerIconButtonState extends ConsumerState<TimerIconButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final timerState = ref.watch(timerProvider);

    return IconButton(
      padding: const EdgeInsets.all(8),
      constraints: const BoxConstraints(
        minWidth: 48,
        minHeight: 48,
      ),
      icon: SizedBox(
        width: 40,
        height: 40,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated icon when timer is running
            timerState.isRunning
                ? ScaleTransition(
                    scale: _scaleAnimation,
                    child: const Icon(
                      Icons.timer,
                      color: Colors.blue,
                      size: 24,
                    ),
                  )
                : Icon(
                    timerState.seconds > 0
                        ? Icons.timer
                        : Icons.timer_outlined,
                    color: timerState.seconds > 0 ? Colors.orange : null,
                    size: 24,
                  ),
            // Time display below icon
            if (timerState.isRunning || timerState.seconds > 0)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  timerState.formattedTime,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    height: 1,
                    color: timerState.isRunning ? Colors.blue : Colors.orange,
                  ),
                ),
              ),
          ],
        ),
      ),
      tooltip: 'Timer',
      onPressed: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => const TimerModalContent(),
        );
      },
    );
  }
}
