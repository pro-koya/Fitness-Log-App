/// バックアップファイルのパースエラー
class BackupParseException implements Exception {
  final String message;
  BackupParseException(this.message);

  @override
  String toString() => message;
}

/// バックアップバージョンの互換性エラー
class BackupVersionException implements Exception {
  final String message;
  BackupVersionException(this.message);

  @override
  String toString() => message;
}
