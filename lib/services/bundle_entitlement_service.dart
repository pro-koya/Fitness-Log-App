import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_config.dart';

enum BundlePurchaseEnvironment {
  production('Production', 'get_bundle_status'),
  sandbox('Sandbox', 'get_sandbox_bundle_status');

  const BundlePurchaseEnvironment(this.value, this.statusRPC);
  final String value;
  final String statusRPC;

  static BundlePurchaseEnvironment? parse(String? value) {
    for (final environment in values) {
      if (environment.value == value) return environment;
    }
    return null;
  }
}

Future<BundlePurchaseEnvironment?> _nativePurchaseEnvironment() async {
  if (defaultTargetPlatform == TargetPlatform.android) {
    return BundlePurchaseEnvironment.production;
  }
  if (defaultTargetPlatform != TargetPlatform.iOS) return null;
  try {
    final value = await const MethodChannel(
      'fitness_log_app/purchase_environment',
    ).invokeMethod<String>('getEnvironment');
    return BundlePurchaseEnvironment.parse(value);
  } catch (_) {
    return null;
  }
}

class BundleStatusResponse {
  final String? environment;
  final bool bundleActive;
  final String? bundleProductId;
  final int? bundleExpiresAt;
  final int checkedAt;

  const BundleStatusResponse({
    this.environment,
    required this.bundleActive,
    this.bundleProductId,
    this.bundleExpiresAt,
    required this.checkedAt,
  });

  factory BundleStatusResponse.fromJson(Map<String, dynamic> json) {
    return BundleStatusResponse(
      environment: json['environment'] as String?,
      bundleActive: json['bundle_active'] as bool? ?? false,
      bundleProductId: json['bundle_product_id'] as String?,
      bundleExpiresAt: json['bundle_expires_at'] as int?,
      checkedAt: json['checked_at'] as int? ?? 0,
    );
  }

  bool isActiveAt(DateTime now) =>
      bundleActive &&
      bundleExpiresAt != null &&
      bundleExpiresAt! * 1000 > now.millisecondsSinceEpoch;
}

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

/// 共有権利だけを管理する。購入端末の権利は IAPServiceNotifier が別に保持する。
class BundleEntitlementNotifier extends StateNotifier<BundleEntitlementState> {
  BundleEntitlementNotifier({
    SupabaseClient? client,
    Future<BundlePurchaseEnvironment?> Function()? environmentResolver,
  }) : _injectedClient = client,
       _environmentResolver = environmentResolver ?? _nativePurchaseEnvironment,
       super(const BundleEntitlementState()) {
    _authSubscription = _client?.auth.onAuthStateChange.listen(
      (_) {
        _synchronizeUser();
        unawaited(refresh(forceRefresh: true));
      },
      onError: (Object _) {
        debugPrint('BundleEntitlement: auth refresh unavailable');
      },
    );
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      unawaited(refresh());
    });
    unawaited(refresh());
  }

  static const Duration _cacheTTL = Duration(minutes: 5);
  static const String _bundleId = 'com.fitnesslog.fitnessLogApp';
  final SupabaseClient? _injectedClient;
  final Future<BundlePurchaseEnvironment?> Function() _environmentResolver;
  BundlePurchaseEnvironment? _environment;
  DateTime? _lastCheckedAt;
  String? _userId;
  int _requestGeneration = 0;
  Timer? _expiryTimer;
  Timer? _pollTimer;
  StreamSubscription<AuthState>? _authSubscription;

  SupabaseClient? get _client {
    if (_injectedClient != null) return _injectedClient;
    if (!SupabaseConfig.isConfigured) return null;
    return Supabase.instance.client;
  }

  void _synchronizeUser() {
    final userId = _client?.auth.currentUser?.id;
    if (_userId == userId) return;
    _userId = userId;
    _requestGeneration++;
    _lastCheckedAt = null;
    _expiryTimer?.cancel();
    state = const BundleEntitlementState();
  }

  Future<(String, BundlePurchaseEnvironment, int)?> _prepareContext() async {
    _synchronizeUser();
    if (_userId == null) return null;
    final lookup = ++_requestGeneration;
    BundlePurchaseEnvironment? environment;
    try {
      environment = await _environmentResolver();
    } catch (_) {
      environment = null;
    }
    if (!mounted || lookup != _requestGeneration) return null;
    _synchronizeUser();
    if (lookup != _requestGeneration) return null;
    if (_environment != environment) {
      _environment = environment;
      _requestGeneration++;
      _lastCheckedAt = null;
      _expiryTimer?.cancel();
      state = const BundleEntitlementState();
    }
    final userId = _userId;
    if (userId == null || environment == null) return null;
    return (userId, environment, ++_requestGeneration);
  }

  Future<void> refresh({bool forceRefresh = false}) async {
    final context = await _prepareContext();
    final client = _client;
    if (client == null || context == null) return;
    final (userId, environment, generation) = context;
    if (!forceRefresh &&
        _lastCheckedAt != null &&
        DateTime.now().difference(_lastCheckedAt!) <
            (environment == BundlePurchaseEnvironment.sandbox
                ? const Duration(seconds: 30)
                : _cacheTTL)) {
      return;
    }
    state = state.copyWith(isLoading: true);
    try {
      final raw = await client.rpc(environment.statusRPC);
      if (!mounted ||
          generation != _requestGeneration ||
          client.auth.currentUser?.id != userId ||
          _environment != environment) {
        return;
      }
      final data = _parseResponse(raw);
      if (data == null || data.containsKey('error')) {
        state = state.copyWith(isLoading: false);
        return;
      }
      _applyStatus(BundleStatusResponse.fromJson(data), environment);
    } catch (_) {
      if (mounted && generation == _requestGeneration) {
        debugPrint('BundleEntitlement: status refresh unavailable');
        state = state.copyWith(isLoading: false);
      }
    }
  }

  /// 自己申告の取引ID/期限では権利を付けず、Appleの署名済み証明だけを送信する。
  Future<void> recordBundlePurchase({required String signedTransaction}) async {
    final context = await _prepareContext();
    final client = _client;
    if (client == null || context == null) return;
    final (userId, environment, generation) = context;
    if (defaultTargetPlatform != TargetPlatform.iOS ||
        signedTransaction.length > 32768 ||
        signedTransaction.split('.').length != 3) {
      _sharingUnavailable();
      return;
    }
    try {
      var session = client.auth.currentSession;
      if (session?.isExpired ?? true) {
        session = (await client.auth.refreshSession()).session;
      }
      if (session == null || session.user.id != userId) return;
      final response = await client.functions.invoke(
        'verify-bundle-purchase',
        headers: {'Authorization': 'Bearer ${session.accessToken}'},
        body: {'bundleId': _bundleId, 'signedTransaction': signedTransaction},
      );
      if (!mounted ||
          generation != _requestGeneration ||
          client.auth.currentUser?.id != userId ||
          _environment != environment) {
        return;
      }
      final data = _parseResponse(response.data);
      if (response.status != 200 || data == null || data.containsKey('error')) {
        _sharingUnavailable();
        return;
      }
      _applyStatus(BundleStatusResponse.fromJson(data), environment);
    } catch (_) {
      if (mounted &&
          generation == _requestGeneration &&
          client.auth.currentUser?.id == userId) {
        _sharingUnavailable();
      }
    }
  }

  void _sharingUnavailable() {
    debugPrint('BundleEntitlement: purchase sharing not confirmed');
    state = state.copyWith(
      isLoading: false,
      errorMessage: '端末の購入は維持されています。アプリ間共有は購入時のアカウントでログインして復元してください。',
    );
  }

  static Map<String, dynamic>? _parseResponse(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is List && raw.length == 1 && raw.first is Map<String, dynamic>) {
      return raw.first as Map<String, dynamic>;
    }
    return null;
  }

  void _applyStatus(
    BundleStatusResponse status,
    BundlePurchaseEnvironment environment,
  ) {
    if (status.environment != environment.value) {
      _lastCheckedAt = null;
      _expiryTimer?.cancel();
      state = const BundleEntitlementState();
      return;
    }
    final now = DateTime.now();
    final active = status.isActiveAt(now);
    final expiresAt = active
        ? DateTime.fromMillisecondsSinceEpoch(status.bundleExpiresAt! * 1000)
        : null;
    _lastCheckedAt = now;
    _expiryTimer?.cancel();
    state = BundleEntitlementState(
      isActive: active,
      productId: active ? status.bundleProductId : null,
      expiresAt: expiresAt,
    );
    if (expiresAt != null) {
      _expiryTimer = Timer(expiresAt.difference(now), () {
        if (mounted) {
          _lastCheckedAt = null;
          state = const BundleEntitlementState();
        }
      });
    }
  }

  void invalidateCache() {
    _lastCheckedAt = null;
  }

  @override
  void dispose() {
    _expiryTimer?.cancel();
    _authSubscription?.cancel();
    _pollTimer?.cancel();
    super.dispose();
  }
}

final bundleEntitlementProvider =
    StateNotifierProvider<BundleEntitlementNotifier, BundleEntitlementState>(
      (ref) => BundleEntitlementNotifier(),
    );

final isBundleActiveProvider = Provider<bool>((ref) {
  return ref.watch(bundleEntitlementProvider).isActive;
});
