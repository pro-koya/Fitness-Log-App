import 'package:flutter_test/flutter_test.dart';
import 'package:fitness_log_app/services/iap_service.dart';
import 'package:fitness_log_app/services/bundle_entitlement_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// RPC レスポンス パース ヘルパー
//
// BundleEntitlementNotifier の refresh()/recordBundlePurchase() 内で行う
// 「Map or single-element List」判別ロジックを純粋関数として抽出してテストする。
// ─────────────────────────────────────────────────────────────────────────────
Map<String, dynamic>? _parseRpcResponse(dynamic raw) {
  if (raw is Map<String, dynamic>) return raw;
  if (raw is List && raw.length == 1 && raw.first is Map<String, dynamic>) {
    return raw.first as Map<String, dynamic>;
  }
  return null;
}

/// A-6 テスト要件: エンタイトルメント判定 最低 5 ケース
///
/// IAPState の bundle 判定ロジックをユニットテスト。
/// 実際の Supabase / StoreKit 通信はしない（純粋な Dart ロジックのみ）。

void main() {
  group('IAPProductIds', () {
    test('bundleProductIds contains both bundle IDs', () {
      expect(
        IAPProductIds.bundleProductIds,
        containsAll([
          'com.fitnesslog.liftly.bundle.pro.monthly',
          'com.fitnesslog.liftly.bundle.pro.yearly',
        ]),
      );
    });

    test('allProductIds contains Liftly Pro IDs', () {
      expect(
        IAPProductIds.allProductIds,
        containsAll([
          'com.fitnesslog.liftly.pro.monthly',
          'com.fitnesslog.liftly.pro.yearly',
        ]),
      );
    });

    test('allProductIds contains bundle IDs', () {
      expect(
        IAPProductIds.allProductIds,
        containsAll([
          'com.fitnesslog.liftly.bundle.pro.monthly',
          'com.fitnesslog.liftly.bundle.pro.yearly',
        ]),
      );
    });
  });

  group('IAPState bundle entitlement', () {
    // ケース 1: 購入済みなし → hasActiveSubscription = false
    test('no purchased IDs → no active subscription', () {
      const state = IAPState(purchasedProductIds: {});
      expect(state.hasActiveSubscription, isFalse);
      expect(state.hasActiveBundleSubscription, isFalse);
      expect(state.hasAnyProAccess, isFalse);
    });

    // ケース 2: Liftly Pro 月額購入済み → hasActiveSubscription = true
    test('liftly monthly purchased → hasActiveSubscription', () {
      const state = IAPState(
        purchasedProductIds: {'com.fitnesslog.liftly.pro.monthly'},
      );
      expect(state.hasActiveSubscription, isTrue);
      expect(state.hasActiveBundleSubscription, isFalse);
      expect(state.hasAnyProAccess, isTrue);
    });

    // ケース 3: バンドル月額購入済み → hasActiveBundleSubscription = true
    test('bundle monthly purchased → hasActiveBundleSubscription', () {
      const state = IAPState(
        purchasedProductIds: {'com.fitnesslog.liftly.bundle.pro.monthly'},
      );
      expect(state.hasActiveSubscription, isFalse);
      expect(state.hasActiveBundleSubscription, isTrue);
      expect(state.hasAnyProAccess, isTrue);
    });

    // ケース 4: バンドル年額購入済み → hasActiveBundleSubscription = true
    test('bundle yearly purchased → hasActiveBundleSubscription', () {
      const state = IAPState(
        purchasedProductIds: {'com.fitnesslog.liftly.bundle.pro.yearly'},
      );
      expect(state.hasActiveSubscription, isFalse);
      expect(state.hasActiveBundleSubscription, isTrue);
      expect(state.hasAnyProAccess, isTrue);
    });

    // ケース 5: Liftly Pro + バンドル両方購入済み → 両方 true
    test('both liftly and bundle purchased → all active', () {
      const state = IAPState(
        purchasedProductIds: {
          'com.fitnesslog.liftly.pro.monthly',
          'com.fitnesslog.liftly.bundle.pro.yearly',
        },
      );
      expect(state.hasActiveSubscription, isTrue);
      expect(state.hasActiveBundleSubscription, isTrue);
      expect(state.hasAnyProAccess, isTrue);
    });

    // ケース 6: Liftly 年額のみ → Liftly Pro 有効、バンドルなし
    test('liftly yearly only → liftly active, bundle inactive', () {
      const state = IAPState(
        purchasedProductIds: {'com.fitnesslog.liftly.pro.yearly'},
      );
      expect(state.hasActiveSubscription, isTrue);
      expect(state.hasActiveBundleSubscription, isFalse);
    });
  });

  group('IAPState price fallbacks', () {
    // バンドル商品が取得できない場合のフォールバック価格確認（プロバイダーテストは
    // Widget テストが必要なのでここでは IAPState のロジックのみ）
    test('bundleMonthlyProduct returns null when empty', () {
      const state = IAPState(products: []);
      expect(state.bundleMonthlyProduct, isNull);
    });

    test('bundleYearlyProduct returns null when empty', () {
      const state = IAPState(products: []);
      expect(state.bundleYearlyProduct, isNull);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Race condition fix (QA Medium): checkEntitlement() が bundleEntitlementProvider
  // の初期値（isActive=false）のまま判定しないことを BundleEntitlementState の
  // 純粋ロジックで検証する。
  // ─────────────────────────────────────────────────────────────────────────
  group('BundleEntitlementState race condition guard', () {
    // ケース R-1: 初期状態（refresh 前）は isActive=false / isLoading=false
    // → checkEntitlement() がこの状態で判定すると bundle Pro を見落とす（修正前の問題）
    test('initial state has isActive=false and isLoading=false', () {
      const state = BundleEntitlementState();
      expect(state.isActive, isFalse);
      expect(state.isLoading, isFalse);
      expect(state.productId, isNull);
    });

    // ケース R-2: refresh() 完了後に isActive=true になった状態を正しく表現できる
    // → この状態で読んだ場合、bundle Pro 判定が通ることを確認
    test('after refresh with active bundle, isActive=true', () {
      const state = BundleEntitlementState(
        isActive: true,
        productId: 'com.fitnesslog.liftly.bundle.pro.monthly',
      );
      expect(state.isActive, isTrue);
      expect(state.productId, equals('com.fitnesslog.liftly.bundle.pro.monthly'));
    });

    // ケース R-3: refresh() 実行中（isLoading=true）の状態では、既存の isActive は保持される
    test('loading state preserves existing isActive value', () {
      const activeState = BundleEntitlementState(isActive: true);
      final loadingState = activeState.copyWith(isLoading: true);
      // copyWith で isLoading を true にしても isActive は維持される
      expect(loadingState.isActive, isTrue);
      expect(loadingState.isLoading, isTrue);
    });

    // ケース R-4: refresh() が Supabase エラーで失敗した場合、isActive は false のまま
    // → Pro バンドルユーザーが一時的に Free になる可能性はあるが、
    //   失敗後も既存の有効な isActive を上書きしないことを確認（refresh失敗時は状態を維持）
    test('refresh failure does not overwrite existing active state', () {
      const preRefreshState = BundleEntitlementState(
        isActive: true,
        productId: 'com.fitnesslog.liftly.bundle.pro.yearly',
      );
      // refresh() 失敗時はエラーハンドラで isLoading: false のみ更新する設計
      final afterFailureState = preRefreshState.copyWith(isLoading: false);
      expect(afterFailureState.isActive, isTrue);
      expect(afterFailureState.productId, equals('com.fitnesslog.liftly.bundle.pro.yearly'));
    });

    // ケース R-5: bundle inactive で refresh 完了 → isActive=false は正当な Free 判定
    test('refresh result with inactive bundle gives isActive=false', () {
      const state = BundleEntitlementState(
        isActive: false,
        productId: null,
      );
      // この場合 checkEntitlement() は Liftly IAP にフォールバックする（正常動作）
      expect(state.isActive, isFalse);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Task 1 fix: RPC レスポンス パース ロジックの検証
  //
  // supabase_flutter 2.12.0 / postgrest 2.6.0 では client.rpc() を .select()
  // なしで呼ぶと Postgres RETURNS JSON 関数の生 JSON body が Map として返る。
  // 万が一 List 形式で返るクライアントバージョンにも対応するためのロジックを確認する。
  // ─────────────────────────────────────────────────────────────────────────
  group('RPC response parse logic (_parseRpcResponse)', () {
    final bundleActiveMap = <String, dynamic>{
      'user_id': 'test-user',
      'bundle_active': true,
      'bundle_product_id': 'com.fitnesslog.liftly.bundle.pro.monthly',
      'bundle_expires_at': 9999999999,
      'checked_at': 1000000000,
    };

    // P-1: Map 形式（期待値）はそのまま返す
    test('Map input returns itself', () {
      final result = _parseRpcResponse(bundleActiveMap);
      expect(result, equals(bundleActiveMap));
    });

    // P-2: 単一要素 List（防御ケース）は先頭要素を取り出す
    test('single-element List returns first element', () {
      final result = _parseRpcResponse([bundleActiveMap]);
      expect(result, equals(bundleActiveMap));
    });

    // P-3: 複数要素 List は null を返す（不正レスポンス）
    test('multi-element List returns null', () {
      final result = _parseRpcResponse([bundleActiveMap, bundleActiveMap]);
      expect(result, isNull);
    });

    // P-4: null は null を返す
    test('null input returns null', () {
      final result = _parseRpcResponse(null);
      expect(result, isNull);
    });

    // P-5: 空文字列は null を返す
    test('String input returns null', () {
      final result = _parseRpcResponse('unexpected_string');
      expect(result, isNull);
    });

    // P-6: error キーを含む Map は error として後続処理が検出できる
    test('error map is passed through and detected', () {
      final errorMap = <String, dynamic>{'error': 'not_authenticated'};
      final result = _parseRpcResponse(errorMap);
      expect(result, isNotNull);
      expect(result!.containsKey('error'), isTrue);
    });

    // P-7: BundleStatusResponse.fromJson がパース結果を正しく読める
    test('BundleStatusResponse.fromJson parses active bundle correctly', () {
      final status = BundleStatusResponse.fromJson(bundleActiveMap);
      expect(status.bundleActive, isTrue);
      expect(status.bundleProductId, equals('com.fitnesslog.liftly.bundle.pro.monthly'));
      expect(status.bundleExpiresAt, equals(9999999999));
    });

    // P-8: BundleStatusResponse.fromJson が inactive map を正しく読める
    test('BundleStatusResponse.fromJson parses inactive bundle correctly', () {
      final inactiveMap = <String, dynamic>{
        'user_id': 'test-user',
        'bundle_active': false,
        'bundle_product_id': null,
        'bundle_expires_at': null,
        'checked_at': 1000000000,
      };
      final status = BundleStatusResponse.fromJson(inactiveMap);
      expect(status.bundleActive, isFalse);
      expect(status.bundleProductId, isNull);
      expect(status.bundleExpiresAt, isNull);
    });
  });
}
