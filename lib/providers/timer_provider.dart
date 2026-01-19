import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Timer state
class TimerState {
  final int seconds; // Remaining seconds
  final bool isRunning;
  final bool isExpanded; // Mini or expanded view
  final bool hasFinished; // Flag to indicate timer just finished
  final int lastSetSeconds; // Last time set (custom or preset) - used for reset
  final bool notificationShown; // Flag to track if notification has been shown (prevents duplicate)

  const TimerState({
    required this.seconds,
    required this.isRunning,
    this.isExpanded = false,
    this.hasFinished = false,
    this.lastSetSeconds = 90, // Default to 90 seconds
    this.notificationShown = false,
  });

  TimerState copyWith({
    int? seconds,
    bool? isRunning,
    bool? isExpanded,
    bool? hasFinished,
    int? lastSetSeconds,
    bool? notificationShown,
  }) {
    return TimerState(
      seconds: seconds ?? this.seconds,
      isRunning: isRunning ?? this.isRunning,
      isExpanded: isExpanded ?? this.isExpanded,
      hasFinished: hasFinished ?? this.hasFinished,
      lastSetSeconds: lastSetSeconds ?? this.lastSetSeconds,
      notificationShown: notificationShown ?? this.notificationShown,
    );
  }

  String get formattedTime {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}

/// Timer notifier
class TimerNotifier extends StateNotifier<TimerState> {
  TimerNotifier() : super(const TimerState(seconds: 90, isRunning: false));

  Timer? _timer;

  /// Start timer
  void start() {
    if (state.isRunning) return;

    state = state.copyWith(isRunning: true);

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.seconds > 0) {
        state = state.copyWith(seconds: state.seconds - 1, hasFinished: false);
      } else {
        // Timer finished
        stop();
        // Set hasFinished flag to trigger notification in UI
        state = state.copyWith(hasFinished: true);
      }
    });
  }

  /// Pause timer
  void pause() {
    _timer?.cancel();
    state = state.copyWith(isRunning: false);
  }

  /// Stop timer
  void stop() {
    _timer?.cancel();
    state = state.copyWith(isRunning: false);
  }

  /// Reset timer
  /// If seconds is provided, uses that value and saves it as lastSetSeconds
  /// Otherwise, uses lastSetSeconds (the last time that was set, custom or preset)
  void reset({int? seconds}) {
    _timer?.cancel();
    final resetSeconds = seconds ?? state.lastSetSeconds;
    state = TimerState(
      seconds: resetSeconds,
      isRunning: false,
      hasFinished: false,
      lastSetSeconds: seconds ?? state.lastSetSeconds, // Update if new value provided
    );
  }

  /// Clear the finished flag
  void clearFinished() {
    state = state.copyWith(hasFinished: false, notificationShown: false);
  }

  /// Mark notification as shown (prevents duplicate notifications)
  void markNotificationShown() {
    state = state.copyWith(notificationShown: true);
  }

  /// Toggle expanded view
  void toggleExpanded() {
    state = state.copyWith(isExpanded: !state.isExpanded);
  }

  /// Set custom time
  void setTime(int seconds) {
    if (!state.isRunning) {
      state = state.copyWith(
        seconds: seconds,
        lastSetSeconds: seconds, // Save as last set time
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

/// Provider for timer
final timerProvider = StateNotifierProvider<TimerNotifier, TimerState>(
  (ref) => TimerNotifier(),
);
