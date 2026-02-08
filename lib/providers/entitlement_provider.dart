import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/entitlement.dart';
import '../services/iap_service.dart';
import 'database_providers.dart';

/// 課金状態を管理するNotifier
///
/// IAPServiceと連携して実際の購入状態を管理
class EntitlementNotifier extends StateNotifier<EntitlementState> {
  EntitlementNotifier(this._ref) : super(const EntitlementState()) {
    _initialize();
  }

  final Ref _ref;

  /// 初期化
  Future<void> _initialize() async {
    // ストレージから課金状態を読み込む
    await _loadFromStorage();

    // IAPサービスに購入状態変更コールバックを設定
    _ref.read(iapServiceProvider.notifier).setOnPurchaseStatusChanged(
      (isPro, subscriptionType) async {
        if (isPro) {
          state = state.copyWith(
            entitlement: Entitlement.pro,
            subscriptionType: subscriptionType,
          );
          await _saveToStorage();
        }
      },
    );
  }

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

  /// 開発用: Pro/Free切り替え（デバッグモードのみ）
  Future<void> togglePro() async {
    if (!kDebugMode) return;
    state = state.copyWith(
      entitlement: state.isPro ? Entitlement.free : Entitlement.pro,
    );
    await _saveToStorage();
  }

  /// 開発用: Proに設定（デバッグモードのみ）
  Future<void> setPro() async {
    if (!kDebugMode) return;
    state = state.copyWith(entitlement: Entitlement.pro);
    await _saveToStorage();
  }

  /// 開発用: Freeに設定（デバッグモードのみ）
  Future<void> setFree() async {
    if (!kDebugMode) return;
    state = state.copyWith(entitlement: Entitlement.free);
    await _saveToStorage();
  }

  /// 課金状態を確認
  Future<void> checkEntitlement() async {
    // IAP購入状態を確認
    final iapState = _ref.read(iapServiceProvider);
    if (iapState.hasActiveSubscription) {
      // サブスクリプションタイプを判定
      String? subscriptionType;
      if (iapState.purchasedProductIds.contains(IAPProductIds.monthlySubscription)) {
        subscriptionType = 'monthly';
      } else if (iapState.purchasedProductIds.contains(IAPProductIds.yearlySubscription)) {
        subscriptionType = 'yearly';
      }

      state = state.copyWith(
        entitlement: Entitlement.pro,
        subscriptionType: subscriptionType,
      );
      await _saveToStorage();
    } else {
      await _loadFromStorage();
    }
  }

  /// 月額購入
  Future<PurchaseResult> purchaseMonthly() async {
    final iapState = _ref.read(iapServiceProvider);

    // IAP利用不可の場合（デバッグモード時はスタブ動作）
    if (iapState.status != IAPStatus.available) {
      if (kDebugMode) {
        // デバッグモード: スタブとしてProに設定
        state = state.copyWith(
          entitlement: Entitlement.pro,
          subscriptionType: 'monthly',
        );
        await _saveToStorage();
        return PurchaseResult.success;
      }
      return PurchaseResult.error;
    }

    // 実際のIAP購入
    final result = await _ref.read(iapServiceProvider.notifier).purchaseMonthly();
    return result;
  }

  /// 年額購入
  Future<PurchaseResult> purchaseYearly() async {
    final iapState = _ref.read(iapServiceProvider);

    // IAP利用不可の場合（デバッグモード時はスタブ動作）
    if (iapState.status != IAPStatus.available) {
      if (kDebugMode) {
        // デバッグモード: スタブとしてProに設定
        state = state.copyWith(
          entitlement: Entitlement.pro,
          subscriptionType: 'yearly',
        );
        await _saveToStorage();
        return PurchaseResult.success;
      }
      return PurchaseResult.error;
    }

    // 実際のIAP購入
    final result = await _ref.read(iapServiceProvider.notifier).purchaseYearly();
    return result;
  }

  /// 購入復元
  Future<bool> restorePurchases() async {
    final iapState = _ref.read(iapServiceProvider);

    // IAP利用不可の場合
    if (iapState.status != IAPStatus.available) {
      if (kDebugMode) {
        // デバッグモード: ストレージから読み込み
        await _loadFromStorage();
        return state.isPro;
      }
      return false;
    }

    // 実際の購入復元（fire-and-forget: 結果はstreamで非同期に届く）
    final success = await _ref.read(iapServiceProvider.notifier).restorePurchases();
    if (success) {
      // ストリームイベントが処理されるのを少し待つ
      await Future.delayed(const Duration(milliseconds: 500));
      await checkEntitlement();
    }
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
