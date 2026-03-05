import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

/// iOS ロック画面にタイマー経過／残り時間を表示する Live Activity 用のネイティブ連携。
/// iOS 16.1+ かつ Widget Extension を Xcode で追加した場合にのみ動作する。
class TimerLiveActivityService {
  TimerLiveActivityService._();
  static const _channel = MethodChannel('fitness_log_app/timer_live_activity');
  static final TimerLiveActivityService _instance = TimerLiveActivityService._();
  factory TimerLiveActivityService() => _instance;

  bool get _isAvailable => !kIsWeb && Platform.isIOS;

  /// タイマー開始時に Live Activity を開始する。endTime はタイマー終了予定の DateTime。
  /// ネイティブ側に未実装（Android／iOSでWidget未追加等）の場合は例外を握りつぶし、タイマー本体の動作には影響させない。
  Future<void> start(int initialSeconds, DateTime endTime) async {
    if (!_isAvailable) return;
    try {
      await _channel.invokeMethod<void>('start', <String, dynamic>{
        'initialSeconds': initialSeconds,
        'endTimeEpochMs': endTime.millisecondsSinceEpoch,
      });
    } on PlatformException catch (e) {
      debugPrint('TimerLiveActivityService.start: $e');
    } on MissingPluginException catch (e) {
      debugPrint('TimerLiveActivityService.start (no native impl): $e');
    }
  }

  /// タイマー停止・一時停止・終了時に Live Activity を終了する。
  Future<void> end() async {
    if (!_isAvailable) return;
    try {
      await _channel.invokeMethod<void>('end');
    } on PlatformException catch (e) {
      debugPrint('TimerLiveActivityService.end: $e');
    } on MissingPluginException catch (e) {
      debugPrint('TimerLiveActivityService.end (no native impl): $e');
    }
  }
}
