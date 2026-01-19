import 'dart:convert';

/// バックアップデータのルートモデル
class BackupData {
  final String version;
  final DateTime createdAt;
  final String appVersion;
  final BackupContent data;

  const BackupData({
    required this.version,
    required this.createdAt,
    required this.appVersion,
    required this.data,
  });

  /// 現在のバックアップフォーマットバージョン
  static const String currentVersion = '1.0';

  Map<String, dynamic> toJson() => {
        'version': version,
        'createdAt': createdAt.toIso8601String(),
        'appVersion': appVersion,
        'data': data.toJson(),
      };

  factory BackupData.fromJson(Map<String, dynamic> json) {
    return BackupData(
      version: json['version'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      appVersion: json['appVersion'] as String,
      data: BackupContent.fromJson(json['data'] as Map<String, dynamic>),
    );
  }

  String toJsonString() => jsonEncode(toJson());

  factory BackupData.fromJsonString(String jsonString) {
    return BackupData.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);
  }

  /// バージョンの互換性チェック
  bool get isCompatible => version == currentVersion;
}

/// バックアップの実データ部分
class BackupContent {
  final List<Map<String, dynamic>> exercises;
  final List<Map<String, dynamic>> workoutSessions;
  final List<Map<String, dynamic>> workoutExercises;
  final List<Map<String, dynamic>> workoutSets;
  final List<Map<String, dynamic>> exerciseMemos;
  final Map<String, dynamic>? settings;

  const BackupContent({
    required this.exercises,
    required this.workoutSessions,
    required this.workoutExercises,
    required this.workoutSets,
    required this.exerciseMemos,
    this.settings,
  });

  Map<String, dynamic> toJson() => {
        'exercises': exercises,
        'workoutSessions': workoutSessions,
        'workoutExercises': workoutExercises,
        'workoutSets': workoutSets,
        'exerciseMemos': exerciseMemos,
        'settings': settings,
      };

  factory BackupContent.fromJson(Map<String, dynamic> json) {
    return BackupContent(
      exercises: _parseList(json['exercises']),
      workoutSessions: _parseList(json['workoutSessions']),
      workoutExercises: _parseList(json['workoutExercises']),
      workoutSets: _parseList(json['workoutSets']),
      exerciseMemos: _parseList(json['exerciseMemos']),
      settings: json['settings'] as Map<String, dynamic>?,
    );
  }

  /// JSONのリストを安全にパース
  static List<Map<String, dynamic>> _parseList(dynamic list) {
    if (list == null) return [];
    return (list as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  /// セッション数
  int get sessionCount => workoutSessions.length;

  /// 種目数
  int get exerciseCount => exercises.length;

  /// 完了済みセッション数
  int get completedSessionCount =>
      workoutSessions.where((s) => s['status'] == 'completed').length;
}
