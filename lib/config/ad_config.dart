import 'dart:io';
import 'package:flutter/foundation.dart';

/// 広告IDの管理。本番化時は [prodAppIdAndroid], [prodAppIdIOS], [prodBannerUnitIdAndroid], [prodBannerUnitIdIOS] を
/// AdMob で取得した値に差し替えるのみでよい。
class AdConfig {
  // --- テスト用（公式。審査通過前の表示確認用） ---
  static const String testAppIdAndroid = 'ca-app-pub-3940256099942544~3347511713';
  static const String testAppIdIOS = 'ca-app-pub-3940256099942544~1458002511';
  static const String testBannerUnitIdAndroid = 'ca-app-pub-3940256099942544/9214589741';
  static const String testBannerUnitIdIOS = 'ca-app-pub-3940256099942544/2435281174';

  // --- 本番用（審査通過後に AdMob で取得した値に差し替え） ---
  static const String prodAppIdAndroid = 'ca-app-pub-xxxxxxxxxxxxxxxx~yyyyyyyyyy';
  static const String prodAppIdIOS = 'ca-app-pub-4570439660764279~9920258321';
  static const String prodBannerUnitIdAndroid = 'ca-app-pub-xxxxxxxxxxxxxxxx/aaaaaaaaaa';
  static const String prodBannerUnitIdIOS = 'ca-app-pub-4570439660764279/1725017610';

  /// 現在使用する Banner 広告ユニット ID（デバッグ時はテスト、それ以外は本番）
  static String get bannerAdUnitId {
    if (kDebugMode) {
      return Platform.isAndroid ? testBannerUnitIdAndroid : testBannerUnitIdIOS;
    }
    return Platform.isAndroid ? prodBannerUnitIdAndroid : prodBannerUnitIdIOS;
  }
}
