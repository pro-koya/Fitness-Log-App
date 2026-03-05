import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import '../data/models/timer_settings.dart';

/// Plays timer completion notification (vibration and/or sound) according to [TimerSettings].
/// Uses device system sounds (iPhone標準アラーム／Android アラーム等) for familiar alarm tones.
class TimerNotificationService {
  /// Performs vibration and sound based on [settings].
  /// Call from UI or timer completion handler.
  static Future<void> play(TimerSettings settings) async {
    if (settings.vibrationEnabled) {
      for (int i = 0; i < 3; i++) {
        HapticFeedback.mediumImpact();
        if (i < 2) {
          await Future.delayed(const Duration(milliseconds: 200));
        }
      }
    }

    if (settings.soundMode == TimerSettings.soundModeNone) return;

    if (TimerSettings.presetSounds.contains(settings.soundMode)) {
      await _playSystemSound(settings.soundMode);
    }
  }

  /// クラシックアラーム / チャイム / ビープ を端末のシステム音で再生。
  /// シミュレータ等でプラグイン未実装の場合は MissingPluginException を握りつぶす。
  static Future<void> _playSystemSound(String soundId) async {
    final player = FlutterRingtonePlayer();
    try {
      switch (soundId) {
        case TimerSettings.soundModeAlarm:
          await player.play(
            android: AndroidSounds.alarm,
            ios: IosSounds.alarm,
            looping: false,
            asAlarm: true,
          );
          break;
        case TimerSettings.soundModeChime:
          await player.play(
            android: AndroidSounds.notification,
            ios: IosSounds.chime,
            looping: false,
            asAlarm: false,
          );
          break;
        case TimerSettings.soundModeBeep:
          await player.play(
            android: AndroidSounds.notification,
            ios: IosSounds.triTone,
            looping: false,
            asAlarm: false,
          );
          break;
        default:
          await player.play(
            android: AndroidSounds.alarm,
            ios: IosSounds.alarm,
            looping: false,
            asAlarm: true,
          );
      }
    } on MissingPluginException catch (e) {
      debugPrint('TimerNotificationService: flutter_ringtone_player not implemented (e.g. simulator): $e');
    } on PlatformException catch (e) {
      debugPrint('TimerNotificationService: $e');
    }
  }
}
