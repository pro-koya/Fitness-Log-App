import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

/// Product IDs for subscriptions
/// These must match the product IDs configured in App Store Connect and Google Play Console
class IAPProductIds {
  static const String monthlySubscription = 'com.fitnesslog.liftly.pro.monthly';
  static const String yearlySubscription = 'com.fitnesslog.liftly.pro.yearly';

  static const Set<String> allProductIds = {
    monthlySubscription,
    yearlySubscription,
  };
}

/// IAP状態
enum IAPStatus {
  /// 初期化中
  initializing,

  /// 利用可能
  available,

  /// 利用不可（デバイスまたはストアがIAPをサポートしていない）
  unavailable,

  /// エラー
  error,
}

/// IAP State
class IAPState {
  final IAPStatus status;
  final List<ProductDetails> products;
  final bool isPurchasing;
  final String? errorMessage;
  final Set<String> purchasedProductIds;

  const IAPState({
    this.status = IAPStatus.initializing,
    this.products = const [],
    this.isPurchasing = false,
    this.errorMessage,
    this.purchasedProductIds = const {},
  });

  /// 月額商品を取得
  ProductDetails? get monthlyProduct {
    try {
      return products.firstWhere(
        (p) => p.id == IAPProductIds.monthlySubscription,
      );
    } catch (_) {
      return null;
    }
  }

  /// 年額商品を取得
  ProductDetails? get yearlyProduct {
    try {
      return products.firstWhere(
        (p) => p.id == IAPProductIds.yearlySubscription,
      );
    } catch (_) {
      return null;
    }
  }

  /// Proサブスクリプションを持っているか
  bool get hasActiveSubscription {
    return purchasedProductIds.contains(IAPProductIds.monthlySubscription) ||
        purchasedProductIds.contains(IAPProductIds.yearlySubscription);
  }

  IAPState copyWith({
    IAPStatus? status,
    List<ProductDetails>? products,
    bool? isPurchasing,
    String? errorMessage,
    Set<String>? purchasedProductIds,
  }) {
    return IAPState(
      status: status ?? this.status,
      products: products ?? this.products,
      isPurchasing: isPurchasing ?? this.isPurchasing,
      errorMessage: errorMessage,
      purchasedProductIds: purchasedProductIds ?? this.purchasedProductIds,
    );
  }
}

/// 購入結果
enum PurchaseResult {
  success,
  cancelled,
  pending,
  error,
}

/// IAP Service Notifier
class IAPServiceNotifier extends StateNotifier<IAPState> {
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  Function(bool isPro, String? subscriptionType)? _onPurchaseStatusChanged;
  Timer? _purchaseTimeoutTimer;

  IAPServiceNotifier() : super(const IAPState()) {
    _initialize();
  }

  /// 購入状態変更時のコールバックを設定
  void setOnPurchaseStatusChanged(
    Function(bool isPro, String? subscriptionType) callback,
  ) {
    _onPurchaseStatusChanged = callback;
  }

  /// 初期化
  Future<void> _initialize() async {
    try {
      // デバッグモードでシミュレーター/エミュレーターの場合はスキップ
      if (kDebugMode && !Platform.isIOS && !Platform.isAndroid) {
        debugPrint('IAP: Running on non-mobile platform in debug mode, skipping IAP initialization');
        state = state.copyWith(status: IAPStatus.unavailable);
        return;
      }

      // IAP利用可能かチェック
      bool isAvailable;
      try {
        isAvailable = await _inAppPurchase.isAvailable();
      } catch (e) {
        // シミュレーターやIAPが設定されていない環境ではエラーが発生する
        debugPrint('IAP: isAvailable() failed: $e');
        state = state.copyWith(status: IAPStatus.unavailable);
        return;
      }

      if (!isAvailable) {
        debugPrint('IAP: Store is not available');
        state = state.copyWith(status: IAPStatus.unavailable);
        return;
      }

      // 購入ストリームを購読
      _subscription = _inAppPurchase.purchaseStream.listen(
        _onPurchaseUpdate,
        onDone: _onPurchaseStreamDone,
        onError: _onPurchaseStreamError,
      );

      // 商品情報を取得
      await _loadProducts();
    } catch (e) {
      // 初期化中の予期せぬエラー
      debugPrint('IAP: Initialization failed: $e');
      state = state.copyWith(status: IAPStatus.unavailable);
    }
  }

  /// 商品情報を読み込み
  Future<void> _loadProducts() async {
    debugPrint('IAP: Loading products for IDs: ${IAPProductIds.allProductIds}');
    try {
      final response = await _inAppPurchase.queryProductDetails(
        IAPProductIds.allProductIds,
      );

      if (response.notFoundIDs.isNotEmpty) {
        debugPrint('IAP: Products not found: ${response.notFoundIDs}');
      }

      if (response.error != null) {
        debugPrint('IAP: queryProductDetails error: ${response.error!.message}');
        state = state.copyWith(
          status: IAPStatus.error,
          errorMessage: response.error!.message,
        );
        return;
      }

      debugPrint('IAP: Loaded ${response.productDetails.length} products');
      for (final product in response.productDetails) {
        debugPrint('IAP:   - ${product.id}: ${product.price} (${product.currencyCode})');
      }

      state = state.copyWith(
        status: IAPStatus.available,
        products: response.productDetails,
      );
    } catch (e) {
      debugPrint('IAP: _loadProducts exception: $e');
      state = state.copyWith(
        status: IAPStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// 月額購入
  Future<PurchaseResult> purchaseMonthly() async {
    final product = state.monthlyProduct;
    if (product == null) {
      state = state.copyWith(errorMessage: 'Monthly product not found');
      return PurchaseResult.error;
    }
    return _purchase(product);
  }

  /// 年額購入
  Future<PurchaseResult> purchaseYearly() async {
    final product = state.yearlyProduct;
    if (product == null) {
      state = state.copyWith(errorMessage: 'Yearly product not found');
      return PurchaseResult.error;
    }
    return _purchase(product);
  }

  /// 購入処理
  Future<PurchaseResult> _purchase(ProductDetails product) async {
    debugPrint('IAP: _purchase called for ${product.id} (isPurchasing=${state.isPurchasing})');

    if (state.isPurchasing) {
      debugPrint('IAP: Already purchasing, returning error');
      return PurchaseResult.error;
    }

    state = state.copyWith(isPurchasing: true, errorMessage: null);

    try {
      final purchaseParam = PurchaseParam(productDetails: product);

      debugPrint('IAP: Calling buyNonConsumable for ${product.id}');
      final success = await _inAppPurchase.buyNonConsumable(
        purchaseParam: purchaseParam,
      );

      debugPrint('IAP: buyNonConsumable returned: $success');

      if (!success) {
        state = state.copyWith(isPurchasing: false);
        return PurchaseResult.error;
      }

      // 結果は purchaseStream (_onPurchaseUpdate) で処理される
      // Safety timeout: Sandbox環境でログインダイアログをキャンセルした場合など、
      // purchaseStreamにイベントが配信されないケースに対応
      _startPurchaseTimeout();
      return PurchaseResult.pending;
    } catch (e) {
      debugPrint('IAP: _purchase exception: $e');

      // StoreKit 2: ユーザーが購入ダイアログまたはログインダイアログをキャンセルした場合
      if (e is PlatformException && e.code == 'userCancelled') {
        debugPrint('IAP: User cancelled purchase (PlatformException)');
        state = state.copyWith(isPurchasing: false);
        return PurchaseResult.cancelled;
      }

      state = state.copyWith(
        isPurchasing: false,
        errorMessage: e.toString(),
      );
      return PurchaseResult.error;
    }
  }

  /// 購入を復元
  Future<bool> restorePurchases() async {
    if (state.status != IAPStatus.available) {
      return false;
    }

    state = state.copyWith(isPurchasing: true, errorMessage: null);

    try {
      await _inAppPurchase.restorePurchases();
      // 結果は purchaseStream (_onPurchaseUpdate) で非同期に届く
      // プラットフォーム呼び出し完了後に isPurchasing をリセット
      // （ストリームイベントが届けば _handlePurchase が状態を更新する）
      state = state.copyWith(isPurchasing: false);
      return true;
    } catch (e) {
      debugPrint('IAP: restorePurchases exception: $e');
      state = state.copyWith(
        isPurchasing: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  /// 購入タイムアウトを開始
  /// buyNonConsumableがtrueを返した後、purchaseStreamからイベントが届かない場合の安全策
  void _startPurchaseTimeout() {
    _purchaseTimeoutTimer?.cancel();
    _purchaseTimeoutTimer = Timer(const Duration(seconds: 30), () {
      if (mounted && state.isPurchasing) {
        debugPrint('IAP: Purchase timeout - no stream event received in 30s, resetting isPurchasing');
        state = state.copyWith(isPurchasing: false);
      }
    });
  }

  /// 購入タイムアウトをキャンセル（ストリームイベントが届いた場合）
  void _cancelPurchaseTimeout() {
    _purchaseTimeoutTimer?.cancel();
    _purchaseTimeoutTimer = null;
  }

  /// 購入更新コールバック
  void _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) {
    _cancelPurchaseTimeout();
    for (final purchaseDetails in purchaseDetailsList) {
      _handlePurchase(purchaseDetails);
    }
  }

  /// 個別の購入を処理
  Future<void> _handlePurchase(PurchaseDetails purchaseDetails) async {
    debugPrint('IAP: _handlePurchase status=${purchaseDetails.status} '
        'productID=${purchaseDetails.productID} '
        'pendingComplete=${purchaseDetails.pendingCompletePurchase} '
        'error=${purchaseDetails.error?.message} code=${purchaseDetails.error?.code}');

    switch (purchaseDetails.status) {
      case PurchaseStatus.pending:
        debugPrint('IAP: Purchase pending for ${purchaseDetails.productID}');
        break;

      case PurchaseStatus.purchased:
      case PurchaseStatus.restored:
        debugPrint('IAP: Purchase completed/restored for ${purchaseDetails.productID}');

        // 購入済みリストに追加
        final newPurchasedIds = Set<String>.from(state.purchasedProductIds)
          ..add(purchaseDetails.productID);

        state = state.copyWith(
          purchasedProductIds: newPurchasedIds,
          isPurchasing: false,
        );

        // サブスクリプションタイプを判定
        String? subscriptionType;
        if (purchaseDetails.productID == IAPProductIds.monthlySubscription) {
          subscriptionType = 'monthly';
        } else if (purchaseDetails.productID == IAPProductIds.yearlySubscription) {
          subscriptionType = 'yearly';
        }

        // コールバックを呼び出し（EntitlementProviderに通知）
        _onPurchaseStatusChanged?.call(true, subscriptionType);
        break;

      case PurchaseStatus.error:
        final code = purchaseDetails.error?.code;
        final isUserCancelled = code == 'userCancelled' ||
            (purchaseDetails.error?.message ?? '').toLowerCase().contains('cancel');
        if (isUserCancelled) {
          debugPrint('IAP: Purchase cancelled (via error status)');
          state = state.copyWith(isPurchasing: false, errorMessage: null);
        } else {
          debugPrint('IAP: Purchase error: ${purchaseDetails.error?.message} '
              'code=$code');
          state = state.copyWith(
            isPurchasing: false,
            errorMessage: purchaseDetails.error?.message ?? 'Purchase failed',
          );
        }
        break;

      case PurchaseStatus.canceled:
        debugPrint('IAP: Purchase cancelled');
        state = state.copyWith(isPurchasing: false, errorMessage: null);
        break;
    }

    // 未完了トランザクションが残ると次回以降の購入がブロックされるため、
    // pendingCompletePurchase のときは必ず completePurchase を呼ぶ
    if (purchaseDetails.pendingCompletePurchase) {
      debugPrint('IAP: Completing purchase for ${purchaseDetails.productID}');
      await _inAppPurchase.completePurchase(purchaseDetails);
    }
  }

  void _onPurchaseStreamDone() {
    _subscription?.cancel();
  }

  void _onPurchaseStreamError(dynamic error) {
    debugPrint('IAP: Purchase stream error: $error');
    state = state.copyWith(
      status: IAPStatus.error,
      errorMessage: error.toString(),
    );
  }

  @override
  void dispose() {
    _purchaseTimeoutTimer?.cancel();
    _subscription?.cancel();
    super.dispose();
  }
}

/// IAP Service Provider
final iapServiceProvider = StateNotifierProvider<IAPServiceNotifier, IAPState>(
  (ref) => IAPServiceNotifier(),
);

/// 月額価格の表示用Provider
final monthlyPriceProvider = Provider<String>((ref) {
  final iapState = ref.watch(iapServiceProvider);
  return iapState.monthlyProduct?.price ?? '¥150/月';
});

/// 年額価格の表示用Provider
final yearlyPriceProvider = Provider<String>((ref) {
  final iapState = ref.watch(iapServiceProvider);
  return iapState.yearlyProduct?.price ?? '¥1,500/年';
});
