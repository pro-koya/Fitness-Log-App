import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/entitlement.dart';
import '../providers/entitlement_provider.dart';

/// 機能ゲートヘルパークラス
///
/// Free/Proプランに応じて各機能へのアクセスを制御する。
/// 履歴は Free/Pro ともに全件閲覧可能（セッション数制限廃止）。
class FeatureGate {
  final EntitlementState entitlement;

  const FeatureGate(this.entitlement);

  /// Proプランかどうか
  bool get isPro => entitlement.isPro;

  /// 全履歴にアクセス可能か（Free/Pro 共通で常に true）
  bool get canAccessFullHistory => true;

  /// サーバー同期が可能か（Free/Pro 共通 — 筋肉360連携のため全ユーザーに開放）
  bool get canSync => true;

  /// グラフ機能にアクセス可能か（Free/Pro共通）
  bool get canAccessCharts => true;

  /// テーマカスタマイズ可能か（Free/Pro共通）
  bool get canCustomizeTheme => true;

  /// 詳細統計にアクセス可能か（Free/Pro共通）
  bool get canAccessDetailedStats => true;

  /// バックアップ/復元可能か（Free/Pro共通）
  bool get canBackup => true;

  /// 高度な種目検索・フィルタが可能か（Free/Pro共通）
  bool get canUseAdvancedSearch => true;

  /// 種目別目標の設定・表示が可能か（Free/Pro 共通）
  bool get canAccessExerciseGoals => true;

  /// セッションがロックされているか判定（履歴制限廃止のため常に false）
  bool isSessionLocked(int sessionIndex) => false;

  /// ロックされているセッション数を計算（常に 0）
  int getLockedCount(int totalSessions) => 0;

  /// アクセス可能なセッション数を計算（常に全件）
  int getAccessibleCount(int totalSessions) => totalSessions;
}

/// 機能ゲートプロバイダー
final featureGateProvider = Provider<FeatureGate>((ref) {
  final entitlement = ref.watch(entitlementProvider);
  return FeatureGate(entitlement);
});

/// 特定セッションがロックされているか（履歴制限廃止のため常に false）
final isSessionLockedProvider = Provider.family<bool, int>((ref, sessionIndex) {
  return false;
});
