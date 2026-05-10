import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum SyncPromotionChoice { later, apple, google }

/// ワークアウト完了後に未ログインユーザーに表示する連携促進ダイアログ。
/// 一度表示したら二度と表示しない（dismissedフラグで管理）。
class SyncPromotionDialog {
  static const _dismissedKey = 'sync_promotion_dismissed';

  /// 表示すべきかどうか判定
  static Future<bool> shouldShow() async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(_dismissedKey) ?? false);
  }

  /// 表示済みフラグを保存
  static Future<void> markDismissed() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_dismissedKey, true);
  }

  /// ダイアログを表示し、ユーザーの選択を返す
  static Future<SyncPromotionChoice> show(BuildContext context) async {
    final isJa = Localizations.localeOf(context).languageCode == 'ja';

    final result = await showDialog<SyncPromotionChoice>(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.link, size: 36),
        title: Text(isJa ? 'データ同期を有効にしますか？' : 'Enable data sync?'),
        content: Text(
          isJa
              ? 'ログインすると、トレーニング記録をクラウドに同期できます。同期したデータは、連携機能や複数端末で利用できます。'
              : 'Sign in to sync your training records to the cloud. Synced data can be used for connected features and across devices.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.of(context).pop(SyncPromotionChoice.later),
            child: Text(isJa ? 'あとで' : 'Later'),
          ),
          OutlinedButton.icon(
            onPressed: () =>
                Navigator.of(context).pop(SyncPromotionChoice.google),
            icon: const Icon(Icons.g_mobiledata),
            label: Text(isJa ? 'Googleでログイン' : 'Google'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(context).pop(SyncPromotionChoice.apple),
            child: Text(isJa ? 'Appleでログイン' : 'Apple'),
          ),
        ],
      ),
    );

    await markDismissed();
    return result ?? SyncPromotionChoice.later;
  }
}
