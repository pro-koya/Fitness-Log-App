import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/timer_provider.dart';

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
            color: timerState.isRunning ? Colors.blue : Colors.grey.shade800,
            borderRadius: BorderRadius.circular(40),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
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
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Icon(
                timerState.isRunning ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
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

    // Vibrate 3 times with short intervals
    for (int i = 0; i < 3; i++) {
      HapticFeedback.mediumImpact();
      if (i < 2) {
        await Future.delayed(const Duration(milliseconds: 200));
      }
    }

    // Play system alert sound
    SystemSound.play(SystemSoundType.alert);

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
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.timer_off,
                size: 64,
                color: Colors.green.shade600,
              ),
            ),
            const SizedBox(height: 20),

            // Title
            const Text(
              'Rest Complete!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // Message
            Text(
              'Your rest time is over.\nReady for the next set?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade700,
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
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
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

  @override
  void dispose() {
    _minutesController.dispose();
    _secondsController.dispose();
    super.dispose();
  }

  void _applyCustomTime() {
    final minutes = int.tryParse(_minutesController.text) ?? 0;
    final seconds = int.tryParse(_secondsController.text) ?? 0;

    if (minutes < 0 || seconds < 0 || seconds >= 60) {
      // Invalid input
      return;
    }

    final totalSeconds = minutes * 60 + seconds;
    if (totalSeconds > 0) {
      final timerNotifier = ref.read(timerProvider.notifier);
      // Use setTime to save as custom time, then reset
      timerNotifier.setTime(totalSeconds);
      timerNotifier.reset(); // Reset will use the saved custom time
      _minutesController.clear();
      _secondsController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final timerState = ref.watch(timerProvider);
    final timerNotifier = ref.read(timerProvider.notifier);

    // Get keyboard height
    final viewInsets = MediaQuery.of(context).viewInsets;
    
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusScope.of(context).unfocus(),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
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
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Scrollable content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 24),
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Timer display
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: timerState.isRunning
                            ? Colors.blue.withOpacity(0.1)
                            : Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: timerState.isRunning
                              ? Colors.blue.withOpacity(0.3)
                              : Colors.grey.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: Text(
                        timerState.formattedTime,
                        style: TextStyle(
                          fontSize: 64,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 4,
                          color: timerState.isRunning ? Colors.blue : Colors.black87,
                          fontFeatures: const [
                            FontFeature.tabularFigures(),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 48),

                    // Control buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Start/Pause button
                        ElevatedButton(
                          onPressed: () {
                            if (timerState.isRunning) {
                              timerNotifier.pause();
                            } else {
                              timerNotifier.start();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.all(24),
                            shape: const CircleBorder(),
                            backgroundColor:
                                timerState.isRunning ? Colors.orange : Colors.blue,
                          ),
                          child: Icon(
                            timerState.isRunning ? Icons.pause : Icons.play_arrow,
                            size: 32,
                            color: Colors.white,
                          ),
                        ),

                        // Reset button (will use custom time if set)
                        ElevatedButton(
                          onPressed: () {
                            timerNotifier.reset();
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.all(24),
                            shape: const CircleBorder(),
                            backgroundColor: Colors.grey.shade300,
                          ),
                          child: const Icon(
                            Icons.refresh,
                            size: 32,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Preset buttons (P1 feature, but added for better UX)
                    const Text(
                      'Quick Start',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildPresetButton(context, ref, '60s', 60),
                        _buildPresetButton(context, ref, '90s', 90),
                        _buildPresetButton(context, ref, '2min', 120),
                        _buildPresetButton(context, ref, '3min', 180),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Custom time input
                    const Text(
                      'Custom Time',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 16),

                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 70,
                            child: TextField(
                              controller: _minutesController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(3),
                              ],
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                              onTapOutside: (_) =>
                                  FocusScope.of(context).unfocus(),
                              decoration: InputDecoration(
                                labelText: 'Min',
                                labelStyle: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                  horizontal: 8,
                                ),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12.0),
                            child: Text(
                              ':',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 70,
                            child: TextField(
                              controller: _secondsController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(2),
                              ],
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                              onTapOutside: (_) =>
                                  FocusScope.of(context).unfocus(),
                              decoration: InputDecoration(
                                labelText: 'Sec',
                                labelStyle: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                  horizontal: 8,
                                ),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton.icon(
                            onPressed: timerState.isRunning ? null : _applyCustomTime,
                            icon: const Icon(Icons.check, size: 18),
                            label: const Text('Set'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 16,
                              ),
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),

            // Close button (fixed at bottom)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.close, size: 20),
                  label: const Text(
                    'Close',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    foregroundColor: Colors.grey.shade700,
                    side: BorderSide(color: Colors.grey.shade400, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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

  Widget _buildPresetButton(
    BuildContext context,
    WidgetRef ref,
    String label,
    int seconds,
  ) {
    final timerState = ref.watch(timerProvider);
    final isSelected = timerState.seconds == seconds && !timerState.isRunning;

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: ElevatedButton(
          onPressed: timerState.isRunning
              ? null
              : () {
                  final timerNotifier = ref.read(timerProvider.notifier);
                  timerNotifier.reset(seconds: seconds);
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: isSelected ? Colors.blue : Colors.grey.shade100,
            foregroundColor: isSelected ? Colors.white : Colors.grey.shade800,
            padding: const EdgeInsets.symmetric(vertical: 14),
            elevation: isSelected ? 3 : 0,
            shadowColor: Colors.blue.withOpacity(0.4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: isSelected ? Colors.blue : Colors.grey.shade300,
                width: isSelected ? 2 : 1.5,
              ),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              fontSize: 15,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}
