import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_config.dart';

// MARK: - BundleStatusResponse

class BundleStatusResponse {
  final bool bundleActive;
  final String? bundleProductId;
  final int? bundleExpiresAt;
  final int checkedAt;

  const BundleStatusResponse({
    required this.bundleActive,
    this.bundleProductId,
    this.bundleExpiresAt,
    required this.checkedAt,
  });

  factory BundleStatusResponse.fromJson(Map<String, dynamic> json) {
    return BundleStatusResponse(
      bundleActive: json['bundle_active'] as bool? ?? false,
      bundleProductId: json['bundle_product_id'] as String?,
      bundleExpiresAt: json['bundle_expires_at'] as int?,
      checkedAt: json['checked_at'] as int? ?? 0,
    );
  }
}

// MARK: - BundleEntitlementState

class BundleEntitlementState {
  final bool isActive;
  final String? productId;
  final DateTime? expiresAt;
  final bool isLoading;
  final String? errorMessage;

  const BundleEntitlementState({
    this.isActive = false,
    this.productId,
    this.expiresAt,
    this.isLoading = false,
    this.errorMessage,
  });

  BundleEntitlementState copyWith({
    bool? isActive,
    String? productId,
    DateTime? expiresAt,
    bool? isLoading,
    String? errorMessage,
  }) {
    return BundleEntitlementState(
      isActive: isActive ?? this.isActive,
      productId: productId ?? this.productId,
      expiresAt: expiresAt ?? this.expiresAt,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

// MARK: - BundleEntitlementNotifier

/// Muscle360 Pro バンドルの加入状況を Supabase RPC から取得して管理する Notifier。
///
/// 設計方針:
///   - 起動時 + foreground 復帰時（呼び出し元が管理）に refresh() を呼ぶ
///   - キャッシュ TTL: 60分
///   - 未サインイン時は isActive = false のまま（エラーなし）
///   - 失敗時は既存状態を維持
class BundleEntitlementNotifier extends StateNotifier<BundleEntitlementState> {
  BundleEntitlementNotifier() : super(const BundleEntitlementState()) {
    refresh();
  }

  static const Duration _cacheTTL = Duration(hours: 1);
  DateTime? _lastCheckedAt;

  SupabaseClient? get _client {
    if (!SupabaseConfig.isConfigured) return null;
    return Supabase.instance.client;
  }

  /// バンドル加入状況を Supabase RPC から取得して state を更新する。
  /// [forceRefresh]: true の場合は TTL を無視して強制再取得する。
  Future<void> refresh({bool forceRefresh = false}) async {
    final client = _client;
    if (client == null) return;

    // 未サインイン時はスキップ
    final user = client.auth.currentUser;
    if (user == null) return;

    // TTL チェック
    if (!forceRefresh &&
        _lastCheckedAt != null &&
        DateTime.now().difference(_lastCheckedAt!) < _cacheTTL) {
      return;
    }

    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      // supabase_flutter 2.12.0 / supabase 2.10.2 / postgrest 2.6.0:
      // client.rpc('get_bundle_status') returns PostgrestFilterBuilder<dynamic>.
      // When awaited, a Postgres RETURNS JSON function delivers the raw JSON body
      // as a Map<String, dynamic> (no .select() wrapper needed).
      // Defensively handle a single-element List in case of client version variance.
      final raw = await client.rpc('get_bundle_status');
      final Map<String, dynamic>? data;
      if (raw is Map<String, dynamic>) {
        data = raw;
      } else if (raw is List && raw.length == 1 && raw.first is Map<String, dynamic>) {
        data = raw.first as Map<String, dynamic>;
      } else {
        data = null;
      }

      if (data == null || data.containsKey('error')) {
        state = state.copyWith(isLoading: false);
        return;
      }

      final status = BundleStatusResponse.fromJson(data);
      _lastCheckedAt = DateTime.now();

      state = state.copyWith(
        isActive: status.bundleActive,
        productId: status.bundleProductId,
        expiresAt: status.bundleExpiresAt != null
            ? DateTime.fromMillisecondsSinceEpoch(
                status.bundleExpiresAt! * 1000,
              )
            : null,
        isLoading: false,
        errorMessage: null,
      );

      debugPrint(
        'BundleEntitlement: refreshed active=${status.bundleActive} '
        'product=${status.bundleProductId}',
      );
    } catch (e) {
      debugPrint('BundleEntitlement: refresh failed: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  /// バンドル購入を Supabase に記録し、state を最新のサーバー値で更新する。
  ///
  /// [productId]: 購入した bundle 商品 ID
  /// [expiresAtEpoch]: 有効期限（epoch 秒）。不明な場合は null。
  /// [transactionId]: App Store / Google Play のトランザクション ID。
  ///
  /// Supabase RPC 失敗時はソフトフェイルする（ローカル entitlement は維持）。
  Future<void> recordBundlePurchase({
    required String productId,
    required int? expiresAtEpoch,
    required String transactionId,
  }) async {
    final client = _client;
    if (client == null) return;

    try {
      final raw = await client.rpc(
        'record_bundle_purchase',
        params: {
          'p_product_id': productId,
          'p_expires_at': expiresAtEpoch,
          'p_original_transaction_id': transactionId,
        },
      );

      final Map<String, dynamic>? data;
      if (raw is Map<String, dynamic>) {
        data = raw;
      } else if (raw is List && raw.length == 1 && raw.first is Map<String, dynamic>) {
        data = raw.first as Map<String, dynamic>;
      } else {
        data = null;
      }

      if (data != null && !data.containsKey('error')) {
        final status = BundleStatusResponse.fromJson(data);
        _lastCheckedAt = DateTime.now();
        state = state.copyWith(
          isActive: status.bundleActive,
          productId: status.bundleProductId,
          expiresAt: status.bundleExpiresAt != null
              ? DateTime.fromMillisecondsSinceEpoch(status.bundleExpiresAt! * 1000)
              : null,
          isLoading: false,
          errorMessage: null,
        );
        debugPrint(
          'BundleEntitlement: recorded purchase active=${status.bundleActive} '
          'product=${status.bundleProductId}',
        );
      }
    } catch (e) {
      // ソフトフェイル: ログのみ。ローカルの entitlement はこの呼び出し元が管理する。
      debugPrint('BundleEntitlement: recordBundlePurchase failed (soft): $e');
    }
  }

  /// キャッシュを破棄して次回 refresh 時に強制再取得させる。
  void invalidateCache() {
    _lastCheckedAt = null;
  }
}

// MARK: - Providers

final bundleEntitlementProvider =
    StateNotifierProvider<BundleEntitlementNotifier, BundleEntitlementState>(
  (ref) => BundleEntitlementNotifier(),
);

/// バンドルが有効かどうかの簡易プロバイダー
final isBundleActiveProvider = Provider<bool>((ref) {
  return ref.watch(bundleEntitlementProvider).isActive;
});
