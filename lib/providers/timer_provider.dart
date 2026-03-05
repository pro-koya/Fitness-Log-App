import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/app_localizations.dart';
import 'settings_provider.dart';
import '../services/timer_local_notification_service.dart';
import '../services/timer_live_activity_service.dart';
import '../services/timer_persistence_service.dart';

/// Timer state
class TimerState {
  final int seconds;
  final bool isRunning;
  final bool isExpanded;
  final bool hasFinished;
  final int lastSetSeconds;
  final bool notificationShown;

  const TimerState({
    required this.seconds,
    required this.isRunning,
    this.isExpanded = false,
    this.hasFinished = false,
    this.lastSetSeconds = 90,
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

/// Timer notifier: real-time based calculation for background support.
/// - Stores startedAt when timer starts; remaining = initialSeconds - (now - startedAt)
/// - On app background: persists state, cancels ticker; on resume: recalculates from real time
/// - Persists to SharedPreferences so timer survives process kill
/// - Optional schedule/cancel callbacks for background local notification
class TimerNotifier extends StateNotifier<TimerState>
    with WidgetsBindingObserver {
  TimerNotifier(
    this._persistence, [
    this._scheduleNotification,
    this._cancelNotification,
    this._startLiveActivity,
    this._endLiveActivity,
  ]) : super(const TimerState(seconds: 90, isRunning: false)) {
    WidgetsBinding.instance.addObserver(this);
    _restoreFromPersistence();
  }

  final TimerPersistenceService? _persistence;
  final Future<void> Function(DateTime endTime)? _scheduleNotification;
  final void Function()? _cancelNotification;
  final Future<void> Function(int initialSeconds, DateTime endTime)? _startLiveActivity;
  final Future<void> Function()? _endLiveActivity;

  Timer? _ticker;
  DateTime? _startedAt;
  int _initialSeconds = 0;

  void _restoreFromPersistence() {
    final loaded = _persistence?.load();
    if (loaded == null) return;

    if (loaded.isRunning && loaded.startedAt != null && loaded.initialSeconds != null) {
      final remaining = loaded.initialSeconds! -
          (DateTime.now().difference(loaded.startedAt!).inSeconds);
      if (remaining <= 0) {
        state = TimerState(
          seconds: 0,
          isRunning: false,
          hasFinished: true,
          lastSetSeconds: loaded.lastSetSeconds,
        );
        _persistence?.clear();
      } else {
        _startedAt = loaded.startedAt;
        _initialSeconds = loaded.initialSeconds!;
        state = TimerState(
          seconds: remaining,
          isRunning: true,
          lastSetSeconds: loaded.lastSetSeconds,
        );
        _startTicker();
      }
    } else if (loaded.pausedSeconds != null) {
      state = TimerState(
        seconds: loaded.pausedSeconds!,
        isRunning: false,
        lastSetSeconds: loaded.lastSetSeconds,
      );
    }
  }

  int _computeRemaining() {
    if (_startedAt == null) return state.seconds;
    final elapsed = DateTime.now().difference(_startedAt!).inSeconds;
    return (_initialSeconds - elapsed).clamp(0, _initialSeconds);
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    final remaining = _computeRemaining();
    if (remaining <= 0) {
      _ticker?.cancel();
      _ticker = null;
      _startedAt = null;
      _persistence?.clear();
      unawaited(_endLiveActivity?.call());
      state = state.copyWith(
        seconds: 0,
        isRunning: false,
        hasFinished: true,
      );
    } else {
      state = state.copyWith(seconds: remaining, hasFinished: false);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycleState) {
    if (lifecycleState == AppLifecycleState.paused ||
        lifecycleState == AppLifecycleState.inactive) {
      _handleAppBackgrounded();
    } else if (lifecycleState == AppLifecycleState.resumed) {
      _handleAppResumed();
    }
  }

  void _handleAppBackgrounded() {
    if (!state.isRunning) return;

    _ticker?.cancel();
    _ticker = null;

    if (_startedAt != null) {
      _persistence?.saveRunning(
        startedAt: _startedAt!,
        initialSeconds: _initialSeconds,
        lastSetSeconds: state.lastSetSeconds,
      );
    }
  }

  void _handleAppResumed() {
    if (!state.isRunning) return;

    final remaining = _computeRemaining();
    if (remaining <= 0) {
      _startedAt = null;
      _persistence?.clear();
      unawaited(_endLiveActivity?.call());
      state = state.copyWith(
        seconds: 0,
        isRunning: false,
        hasFinished: true,
      );
    } else {
      state = state.copyWith(seconds: remaining);
      _startTicker();
    }
  }

  void start() {
    if (state.isRunning) return;

    _startedAt = DateTime.now();
    _initialSeconds = state.seconds;
    state = state.copyWith(isRunning: true);

    _persistence?.saveRunning(
      startedAt: _startedAt!,
      initialSeconds: _initialSeconds,
      lastSetSeconds: state.lastSetSeconds,
    );

    final endTime = _startedAt!.add(Duration(seconds: _initialSeconds));
    unawaited(_scheduleNotification?.call(endTime));
    unawaited(_startLiveActivity?.call(_initialSeconds, endTime));

    _startTicker();
  }

  void pause() {
    _ticker?.cancel();
    _ticker = null;
    _cancelNotification?.call();
    unawaited(_endLiveActivity?.call());

    final remaining = _computeRemaining();
    _startedAt = null;

    _persistence?.savePaused(
      remainingSeconds: remaining,
      lastSetSeconds: state.lastSetSeconds,
    );

    state = state.copyWith(
      seconds: remaining,
      isRunning: false,
    );
  }

  void stop() {
    _ticker?.cancel();
    _ticker = null;
    _startedAt = null;
    _cancelNotification?.call();
    unawaited(_endLiveActivity?.call());
    _persistence?.clear();
    state = state.copyWith(isRunning: false);
  }

  void reset({int? seconds}) {
    _ticker?.cancel();
    _ticker = null;
    _startedAt = null;
    _cancelNotification?.call();
    unawaited(_endLiveActivity?.call());
    _persistence?.clear();

    final resetSeconds = seconds ?? state.lastSetSeconds;
    state = TimerState(
      seconds: resetSeconds,
      isRunning: false,
      hasFinished: false,
      lastSetSeconds: seconds ?? state.lastSetSeconds,
    );
  }

  void clearFinished() {
    state = state.copyWith(hasFinished: false, notificationShown: false);
  }

  void markNotificationShown() {
    state = state.copyWith(notificationShown: true);
  }

  void toggleExpanded() {
    state = state.copyWith(isExpanded: !state.isExpanded);
  }

  void setTime(int seconds) {
    if (!state.isRunning) {
      state = state.copyWith(
        seconds: seconds,
        lastSetSeconds: seconds,
      );
      _persistence?.saveLastSetSeconds(seconds);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    super.dispose();
  }
}

/// Overridable provider for timer persistence (set in main() after SharedPreferences init)
final timerPersistenceServiceOverride = Provider<TimerPersistenceService?>((ref) => null);

/// Overridable provider for timer background notification (set in main() after plugin init)
final timerLocalNotificationServiceOverride = Provider<TimerLocalNotificationService?>((ref) => null);

final _timerNotificationSchedulerProvider = Provider<Future<void> Function(DateTime)?>((ref) {
  final service = ref.watch(timerLocalNotificationServiceOverride);
  if (service == null) return null;
  return (DateTime endTime) async {
    final settings = ref.read(timerSettingsProvider);
    if (!settings.notificationsEnabled) return;
    final lang = ref.read(currentLanguageProvider);
    final l10n = await AppLocalizations.delegate.load(Locale(lang));
    await service.schedule(endTime, l10n.timerNotificationTitle, l10n.timerNotificationBody);
  };
});

final _timerNotificationCancellerProvider = Provider<void Function()?>((ref) {
  final service = ref.watch(timerLocalNotificationServiceOverride);
  if (service == null) return null;
  return () => unawaited(service.cancel());
});

final _timerLiveActivityStartProvider = Provider<Future<void> Function(int, DateTime)?>((ref) {
  final service = TimerLiveActivityService();
  return (int initialSeconds, DateTime endTime) => service.start(initialSeconds, endTime);
});

final _timerLiveActivityEndProvider = Provider<Future<void> Function()?>((ref) {
  final service = TimerLiveActivityService();
  return () => TimerLiveActivityService().end();
});

final timerProvider = StateNotifierProvider<TimerNotifier, TimerState>((ref) {
  final persistence = ref.watch(timerPersistenceServiceOverride);
  final scheduleFn = ref.watch(_timerNotificationSchedulerProvider);
  final cancelFn = ref.watch(_timerNotificationCancellerProvider);
  final startLiveActivity = ref.watch(_timerLiveActivityStartProvider);
  final endLiveActivity = ref.watch(_timerLiveActivityEndProvider);
  return TimerNotifier(persistence, scheduleFn, cancelFn, startLiveActivity, endLiveActivity);
});
