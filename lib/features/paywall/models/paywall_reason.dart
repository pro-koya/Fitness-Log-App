/// Paywallを表示する理由を表すenum
enum PaywallReason {
  /// 履歴がロックされている（直近20件より古い）
  historyLocked,

  /// グラフ機能へのアクセス
  chart,

  /// テーマカスタマイズ
  theme,

  /// 詳細統計
  stats,

  /// バックアップ/復元
  backup,
}
