import 'package:shared_preferences/shared_preferences.dart';

/// 永続化されたタイマー状態
class TimerPersistedState {
  final bool isRunning;
  final DateTime? startedAt;
  final int? initialSeconds;
  final int? pausedSeconds;
  final int lastSetSeconds;

  const TimerPersistedState._({
    required this.isRunning,
    this.startedAt,
    this.initialSeconds,
    this.pausedSeconds,
    required this.lastSetSeconds,
  });

  factory TimerPersistedState.running({
    required DateTime startedAt,
    required int initialSeconds,
    required int lastSetSeconds,
  }) =>
      TimerPersistedState._(
        isRunning: true,
        startedAt: startedAt,
        initialSeconds: initialSeconds,
        lastSetSeconds: lastSetSeconds,
      );

  factory TimerPersistedState.paused({
    required int remainingSeconds,
    required int lastSetSeconds,
  }) =>
      TimerPersistedState._(
        isRunning: false,
        pausedSeconds: remainingSeconds,
        lastSetSeconds: lastSetSeconds,
      );
}

/// タイマー状態の永続化（プロセスキル・バックグラウンド復帰時に復元）
class TimerPersistenceService {
  static const _keyStartedAtMs = 'timer_started_at_ms';
  static const _keyInitialSeconds = 'timer_initial_seconds';
  static const _keyLastSetSeconds = 'timer_last_set_seconds';
  static const _keyIsRunning = 'timer_is_running';
  static const _keyPausedSeconds = 'timer_paused_seconds';

  final SharedPreferences _prefs;

  TimerPersistenceService(this._prefs);

  /// 実行中状態を保存（start時）
  Future<void> saveRunning({
    required DateTime startedAt,
    required int initialSeconds,
    required int lastSetSeconds,
  }) async {
    await _prefs.setInt(_keyStartedAtMs, startedAt.millisecondsSinceEpoch);
    await _prefs.setInt(_keyInitialSeconds, initialSeconds);
    await _prefs.setInt(_keyLastSetSeconds, lastSetSeconds);
    await _prefs.setBool(_keyIsRunning, true);
    await _prefs.remove(_keyPausedSeconds);
  }

  /// 一時停止状態を保存（pause時）
  Future<void> savePaused({
    required int remainingSeconds,
    required int lastSetSeconds,
  }) async {
    await _prefs.setInt(_keyPausedSeconds, remainingSeconds);
    await _prefs.setInt(_keyLastSetSeconds, lastSetSeconds);
    await _prefs.setBool(_keyIsRunning, false);
    await _prefs.remove(_keyStartedAtMs);
    await _prefs.remove(_keyInitialSeconds);
  }

  /// クリア（reset/stop/終了時）
  Future<void> clear() async {
    await _prefs.remove(_keyStartedAtMs);
    await _prefs.remove(_keyInitialSeconds);
    await _prefs.remove(_keyIsRunning);
    await _prefs.remove(_keyPausedSeconds);
  }

  /// lastSetSeconds のみ保存
  Future<void> saveLastSetSeconds(int lastSetSeconds) async {
    await _prefs.setInt(_keyLastSetSeconds, lastSetSeconds);
  }

  /// 保存済み状態を読み込み
  TimerPersistedState? load() {
    final isRunning = _prefs.getBool(_keyIsRunning) ?? false;
    final lastSetSeconds = _prefs.getInt(_keyLastSetSeconds) ?? 90;

    if (isRunning) {
      final startedAtMs = _prefs.getInt(_keyStartedAtMs);
      final initialSeconds = _prefs.getInt(_keyInitialSeconds);
      if (startedAtMs != null && initialSeconds != null) {
        return TimerPersistedState.running(
          startedAt: DateTime.fromMillisecondsSinceEpoch(startedAtMs),
          initialSeconds: initialSeconds,
          lastSetSeconds: lastSetSeconds,
        );
      }
    } else {
      final pausedSeconds = _prefs.getInt(_keyPausedSeconds);
      if (pausedSeconds != null) {
        return TimerPersistedState.paused(
          remainingSeconds: pausedSeconds,
          lastSetSeconds: lastSetSeconds,
        );
      }
    }

    return null;
  }
}
