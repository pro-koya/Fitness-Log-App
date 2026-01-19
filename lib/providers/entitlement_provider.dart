import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/entitlement.dart';
import 'database_providers.dart';

/// 課金状態を管理するNotifier
///
/// 現在はスタブ実装で、開発用の切り替えのみサポート。
/// 後でIAPに接続する際に実装を差し替える。
class EntitlementNotifier extends StateNotifier<EntitlementState> {
  EntitlementNotifier(this._ref) : super(const EntitlementState()) {
    _loadFromStorage();
  }

  final Ref _ref;

  /// ストレージから課金状態を読み込む
  Future<void> _loadFromStorage() async {
    try {
      final dao = _ref.read(settingsDaoProvider);
      final entitlementStr = await dao.getEntitlement();

      if (entitlementStr == 'pro') {
        state = state.copyWith(entitlement: Entitlement.pro);
      } else {
        state = state.copyWith(entitlement: Entitlement.free);
      }
    } catch (e) {
      // エラー時はFreeのまま
      state = const EntitlementState();
    }
  }

  /// ストレージに課金状態を保存
  Future<void> _saveToStorage() async {
    try {
      final dao = _ref.read(settingsDaoProvider);
      await dao.updateEntitlement(state.isPro ? 'pro' : 'free');
    } catch (e) {
      // 保存エラーは無視
    }
  }

  /// 開発用: Pro/Free切り替え
  Future<void> togglePro() async {
    state = state.copyWith(
      entitlement: state.isPro ? Entitlement.free : Entitlement.pro,
    );
    await _saveToStorage();
  }

  /// 開発用: Proに設定
  Future<void> setPro() async {
    state = state.copyWith(entitlement: Entitlement.pro);
    await _saveToStorage();
  }

  /// 開発用: Freeに設定
  Future<void> setFree() async {
    state = state.copyWith(entitlement: Entitlement.free);
    await _saveToStorage();
  }

  /// 課金状態を確認（IAP接続後に実装）
  Future<void> checkEntitlement() async {
    // TODO: IAP購入状態を確認
    await _loadFromStorage();
  }

  /// 月額購入（IAP接続後に実装）
  Future<bool> purchaseMonthly() async {
    // TODO: 月額購入フロー
    // スタブ: 常に成功としてProに設定
    state = state.copyWith(
      entitlement: Entitlement.pro,
      subscriptionType: 'monthly',
    );
    await _saveToStorage();
    return true;
  }

  /// 年額購入（IAP接続後に実装）
  Future<bool> purchaseYearly() async {
    // TODO: 年額購入フロー
    // スタブ: 常に成功としてProに設定
    state = state.copyWith(
      entitlement: Entitlement.pro,
      subscriptionType: 'yearly',
    );
    await _saveToStorage();
    return true;
  }

  /// 購入復元（IAP接続後に実装）
  Future<bool> restorePurchases() async {
    // TODO: 購入復元
    await _loadFromStorage();
    return state.isPro;
  }
}

/// 課金状態プロバイダー
final entitlementProvider = StateNotifierProvider<EntitlementNotifier, EntitlementState>(
  (ref) => EntitlementNotifier(ref),
);

/// Proプランかどうかの簡易プロバイダー
final isProProvider = Provider<bool>((ref) {
  return ref.watch(entitlementProvider).isPro;
});
