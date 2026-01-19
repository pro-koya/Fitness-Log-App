import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/entitlement.dart';
import '../providers/entitlement_provider.dart';

/// 機能ゲートヘルパークラス
///
/// Free/Proプランに応じて各機能へのアクセスを制御する
class FeatureGate {
  final EntitlementState entitlement;

  const FeatureGate(this.entitlement);

  /// Free版で閲覧可能な履歴の上限（セッション数）
  static const int freeHistoryLimit = 20;

  /// Proプランかどうか
  bool get isPro => entitlement.isPro;

  /// 全履歴にアクセス可能か
  bool get canAccessFullHistory => entitlement.isPro;

  /// グラフ機能にアクセス可能か
  bool get canAccessCharts => entitlement.isPro;

  /// テーマカスタマイズ可能か
  bool get canCustomizeTheme => entitlement.isPro;

  /// 詳細統計にアクセス可能か
  bool get canAccessDetailedStats => entitlement.isPro;

  /// バックアップ/復元可能か
  bool get canBackup => entitlement.isPro;

  /// 高度な種目検索・フィルタが可能か
  bool get canUseAdvancedSearch => entitlement.isPro;

  /// セッションがロックされているか判定
  ///
  /// [sessionIndex] は 0-indexed（新しい順）
  /// Proユーザーは全てアクセス可能
  /// Freeユーザーは直近20件のみアクセス可能
  bool isSessionLocked(int sessionIndex) {
    if (entitlement.isPro) return false;
    return sessionIndex >= freeHistoryLimit;
  }

  /// ロックされているセッション数を計算
  int getLockedCount(int totalSessions) {
    if (entitlement.isPro) return 0;
    return (totalSessions - freeHistoryLimit).clamp(0, totalSessions);
  }

  /// アクセス可能なセッション数を計算
  int getAccessibleCount(int totalSessions) {
    if (entitlement.isPro) return totalSessions;
    return totalSessions.clamp(0, freeHistoryLimit);
  }
}

/// 機能ゲートプロバイダー
final featureGateProvider = Provider<FeatureGate>((ref) {
  final entitlement = ref.watch(entitlementProvider);
  return FeatureGate(entitlement);
});

/// 特定セッションがロックされているかのプロバイダー（ファミリー）
final isSessionLockedProvider = Provider.family<bool, int>((ref, sessionIndex) {
  final gate = ref.watch(featureGateProvider);
  return gate.isSessionLocked(sessionIndex);
});
