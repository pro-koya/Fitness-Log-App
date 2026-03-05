/// Supabase 接続設定（Pro サーバー同期用）
///
/// 本番環境では Supabase ダッシュボードの
/// Project Settings → API から URL と anon key をコピーして書き換えてください。
abstract class SupabaseConfig {
  /// Supabase プロジェクトの URL
  /// 例: https://xxxxxxxxxxxx.supabase.co
  static const String url = 'https://lybgdrxsojuaylnvdmwb.supabase.co';

  /// Supabase の anon (public) API key
  static const String anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imx5Ymdkcnhzb2p1YXlsbnZkbXdiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzE2MTIyMDAsImV4cCI6MjA4NzE4ODIwMH0.v9mvcsp2zdIHtiOzWJKjHFf2Zi1OjJvXte51JOcifDc';

  /// 接続情報が設定されているか（プレースホルダーのままか）
  static bool get isConfigured =>
      url.isNotEmpty &&
      !url.contains('your-project') &&
      anonKey.isNotEmpty &&
      !anonKey.contains('your-anon');
}
