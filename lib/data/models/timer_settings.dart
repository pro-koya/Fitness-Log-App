import 'dart:convert';

/// Timer completion notification settings.
class TimerSettings {
  /// Master switch: when false, no timer-end notification is scheduled.
  final bool notificationsEnabled;
  final bool vibrationEnabled;

  /// Sound ID: 'none' | 'alarm' | 'chime' | 'beep'（一般的なアラーム音のプリセット）
  final String soundMode;

  const TimerSettings({
    this.notificationsEnabled = true,
    this.vibrationEnabled = true,
    this.soundMode = soundModeAlarm,
  });

  static const String soundModeNone = 'none';
  static const String soundModeAlarm = 'alarm';
  static const String soundModeChime = 'chime';
  static const String soundModeBeep = 'beep';

  /// All preset sound IDs (excluding 'none'). 一般的なアラーム音として選択可能。
  static const List<String> presetSounds = [
    soundModeAlarm,
    soundModeChime,
    soundModeBeep,
  ];

  /// All valid sound mode values.
  static const List<String> allModes = [
    soundModeNone,
    soundModeAlarm,
    soundModeChime,
    soundModeBeep,
  ];

  /// Returns the asset path for a preset sound ID.
  static String assetPath(String soundId) => 'sounds/$soundId.wav';

  Map<String, dynamic> toJson() => {
        'notificationsEnabled': notificationsEnabled,
        'vibrationEnabled': vibrationEnabled,
        'soundMode': soundMode,
      };

  factory TimerSettings.fromJson(Map<String, dynamic> json) {
    var mode = json['soundMode'] as String? ?? soundModeAlarm;
    // 後方互換: 旧 'bell' は chime に、その他未対応値はデフォルトに
    if (mode == 'bell') {
      mode = soundModeChime;
    } else if (!allModes.contains(mode)) {
      mode = soundModeAlarm;
    }
    return TimerSettings(
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
      vibrationEnabled: json['vibrationEnabled'] as bool? ?? true,
      soundMode: mode,
    );
  }

  String toJsonString() => jsonEncode(toJson());

  static TimerSettings fromJsonString(String? jsonString) {
    if (jsonString == null || jsonString.isEmpty) {
      return const TimerSettings();
    }
    try {
      return TimerSettings.fromJson(
        jsonDecode(jsonString) as Map<String, dynamic>,
      );
    } catch (_) {
      return const TimerSettings();
    }
  }

  TimerSettings copyWith({
    bool? notificationsEnabled,
    bool? vibrationEnabled,
    String? soundMode,
  }) {
    return TimerSettings(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      soundMode: soundMode ?? this.soundMode,
    );
  }
}
