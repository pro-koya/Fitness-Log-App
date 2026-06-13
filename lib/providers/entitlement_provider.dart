import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/entitlement.dart';
import '../services/iap_service.dart';
import '../services/bundle_entitlement_service.dart';
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
    // ストレージから課金状態を読み込む（有効期限チェック含む）
    await _loadFromStorage();

    // バンドル購入確定時に Supabase RPC へ記録するコールバックを設定
    _ref.read(iapServiceProvider.notifier).setOnBundlePurchaseCompleted(
      ({required productId, required expiresAtEpoch, required transactionId}) async {
        await _ref.read(bundleEntitlementProvider.notifier).recordBundlePurchase(
          productId: productId,
          expiresAtEpoch: expiresAtEpoch,
          transactionId: transactionId,
        );
      },
    );

    // IAPサービスに購入状態変更コールバックを設定
    _ref.read(iapServiceProvider.notifier).setOnPurchaseStatusChanged(
      (isPro, subscriptionType) async {
        if (isPro) {
          state = state.copyWith(
            entitlement: Entitlement.pro,
            subscriptionType: subscriptionType,
          );
          // サブスクリプションの推定有効期限を保存
          try {
            final dao = _ref.read(settingsDaoProvider);
            final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
            final expiryDays = subscriptionType == 'yearly' ? 366 : 32;
            final expiresAt = now + (expiryDays * 24 * 60 * 60);
            await dao.updateSubscriptionExpiresAt(expiresAt);
          } catch (_) {}
          await _saveToStorage();
        }
      },
    );

    // アプリ起動時にストアから課金状態を取得し、解約済みの場合は無料プランに反映する
    refreshSubscriptionStatus();
  }

  /// ストア（App Store / Google Play）に問い合わせて課金状態を取得し、アプリの状態に反映する。
  /// ログイン時やアプリ起動時に呼ぶことで、解約済みでも正しく無料プランになる。
  Future<void> refreshSubscriptionStatus() async {
    final iapState = _ref.read(iapServiceProvider);
    if (iapState.status != IAPStatus.available) {
      return;
    }
    try {
      await _ref.read(iapServiceProvider.notifier).restorePurchases();
      await Future.delayed(const Duration(milliseconds: 500));
      await checkEntitlement();
    } catch (_) {}
  }

  /// ストレージから課金状態を読み込む（有効期限チェック含む）
  Future<void> _loadFromStorage() async {
    try {
      final dao = _ref.read(settingsDaoProvider);
      final settings = await dao.getSettings();
      final entitlementStr = settings?.entitlement ?? 'free';

      if (entitlementStr == 'pro') {
        // 有効期限が設定されていて、すでに過ぎている場合はFreeにダウングレード
        final expiresAt = settings?.subscriptionExpiresAt;
        final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        if (expiresAt != null && expiresAt < now) {
          debugPrint('Entitlement: subscription expired at $expiresAt, downgrading to free');
          state = state.copyWith(entitlement: Entitlement.free);
          await _saveToStorage();
        } else {
          state = state.copyWith(entitlement: Entitlement.pro);
        }
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

  /// 課金状態を確認（Liftly 単独 OR バンドル加入 OR 両方）
  ///
  /// バンドル状態は BundleEntitlementNotifier.refresh() の完了後に判定する。
  /// refresh() は内部で TTL（1時間）チェックを行うため、キャッシュ有効時は
  /// 即時リターンし追加の Supabase RPC 呼び出しは発生しない。
  Future<void> checkEntitlement() async {
    // バンドル状態が初期値（未ロード）のまま判定するレース条件を防ぐため、
    // 判定前に refresh() を await する。
    await _ref.read(bundleEntitlementProvider.notifier).refresh();

    final iapState = _ref.read(iapServiceProvider);
    final bundleState = _ref.read(bundleEntitlementProvider);

    // バンドル加入中はバンドル扱いで Pro 判定
    if (bundleState.isActive) {
      state = state.copyWith(
        entitlement: Entitlement.pro,
        subscriptionType: bundleState.productId ?? 'bundle',
      );
      await _saveToStorage();
      return;
    }

    if (iapState.hasActiveSubscription) {
      // Liftly 単独サブスクのサブスクリプションタイプを判定
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
      // IAPがアクティブなサブスクリプションを確認できなかった場合はFreeにダウングレード
      debugPrint('Entitlement: no active subscription found, downgrading to free');
      state = state.copyWith(entitlement: Entitlement.free);
      try {
        final dao = _ref.read(settingsDaoProvider);
        await dao.updateSubscriptionExpiresAt(null);
      } catch (_) {}
      await _saveToStorage();
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

  /// バンドル月額購入
  Future<PurchaseResult> purchaseBundleMonthly() async {
    final iapState = _ref.read(iapServiceProvider);
    if (iapState.status != IAPStatus.available) {
      if (kDebugMode) {
        state = state.copyWith(
          entitlement: Entitlement.pro,
          subscriptionType: 'bundle_monthly',
        );
        await _saveToStorage();
        return PurchaseResult.success;
      }
      return PurchaseResult.error;
    }
    return _ref.read(iapServiceProvider.notifier).purchaseBundleMonthly();
  }

  /// バンドル年額購入
  Future<PurchaseResult> purchaseBundleYearly() async {
    final iapState = _ref.read(iapServiceProvider);
    if (iapState.status != IAPStatus.available) {
      if (kDebugMode) {
        state = state.copyWith(
          entitlement: Entitlement.pro,
          subscriptionType: 'bundle_yearly',
        );
        await _saveToStorage();
        return PurchaseResult.success;
      }
      return PurchaseResult.error;
    }
    return _ref.read(iapServiceProvider.notifier).purchaseBundleYearly();
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

/// Proプランかどうかの簡易プロバイダー（Liftly 単独 OR バンドル加入）
final isProProvider = Provider<bool>((ref) {
  final entitlement = ref.watch(entitlementProvider);
  final bundle = ref.watch(bundleEntitlementProvider);
  return entitlement.isPro || bundle.isActive;
});
