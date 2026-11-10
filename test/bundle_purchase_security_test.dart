import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fitness_log_app/services/bundle_entitlement_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitness_log_app/services/iap_service.dart';
import 'package:fitness_log_app/providers/entitlement_provider.dart';
import 'package:fitness_log_app/providers/database_providers.dart';
import 'package:fitness_log_app/data/dao/settings_dao.dart';
import 'package:fitness_log_app/data/entities/settings_entity.dart';
import 'package:fitness_log_app/utils/feature_gate.dart';

const firstUser = '11111111-1111-4111-8111-111111111111';
const secondUser = '22222222-2222-4222-8222-222222222222';

Map<String, dynamic> bundle(bool active) => {
  'bundle_active': active,
  'bundle_product_id': active
      ? 'com.fitnesslog.liftly.bundle.pro.monthly'
      : null,
  'bundle_expires_at': active
      ? DateTime.now()
                .add(const Duration(minutes: 30))
                .millisecondsSinceEpoch ~/
            1000
      : null,
  'checked_at': DateTime.now().millisecondsSinceEpoch ~/ 1000,
};

http.Response jsonResponse(Object data, [int status = 200]) => http.Response(
  jsonEncode(data),
  status,
  headers: {'content-type': 'application/json'},
);

class Fixture {
  late final SupabaseClient client;
  String userId = firstUser;
  final List<http.Request> verificationRequests = [];
  Future<http.Response> Function()? rpc;
  http.Response verificationResponse = jsonResponse(bundle(true));
  Future<http.Response> Function()? verify;

  Fixture() {
    client = SupabaseClient(
      'https://purchase-test.supabase.co',
      'public-test',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
      httpClient: MockClient((request) async {
        if (request.url.path.endsWith('/token')) {
          final jwt = [
            base64Url.encode(utf8.encode(jsonEncode({'alg': 'HS256'}))),
            base64Url.encode(
              utf8.encode(
                jsonEncode({
                  'sub': userId,
                  'exp': DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600,
                }),
              ),
            ),
            'signature',
          ].join('.');
          return jsonResponse({
            'access_token': jwt,
            'refresh_token': 'fixture-refresh',
            'token_type': 'bearer',
            'expires_in': 3600,
            'user': {
              'id': userId,
              'aud': 'authenticated',
              'email': 'fixture@example.invalid',
              'app_metadata': {},
              'user_metadata': {},
              'created_at': '2026-11-10T00:00:00Z',
            },
          });
        }
        if (request.url.path.endsWith('/get_bundle_status')) {
          final response = rpc == null
              ? jsonResponse(bundle(false))
              : await rpc!();
          return http.Response(
            response.body,
            response.statusCode,
            headers: response.headers,
            request: request,
          );
        }
        if (request.url.path.endsWith('/verify-bundle-purchase')) {
          verificationRequests.add(request);
          return verify == null ? verificationResponse : await verify!();
        }
        if (request.url.path.endsWith('/logout')) return jsonResponse({});
        throw StateError('Unexpected mock request path');
      }),
    );
  }

  Future<void> signIn([String id = firstUser]) async {
    userId = id;
    await client.auth.signInWithPassword(
      email: 'fixture@example.invalid',
      password: 'fixture',
    );
    await Future<void>.delayed(Duration.zero);
  }
}

class DevicePurchases extends IAPServiceNotifier {
  DevicePurchases(Set<String> products) {
    state = IAPState(
      status: IAPStatus.unavailable,
      purchasedProductIds: products,
    );
  }
}

class MemorySettings extends SettingsDao {
  final writes = <String>[];
  @override
  Future<SettingsEntity?> getSettings() async => const SettingsEntity(
    id: 1,
    language: 'ja',
    unit: 'kg',
    distanceUnit: 'km',
    entitlement: 'pro',
    createdAt: 0,
    updatedAt: 0,
  );
  @override
  Future<int> updateEntitlement(String entitlement) async {
    writes.add(entitlement);
    return 1;
  }

  @override
  Future<int> updateSubscriptionExpiresAt(int? expiresAt) async => 1;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
  });
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
  });

  test(
    'only signed proof and fixed bundle ID are sent with the user session',
    () async {
      final fixture = Fixture();
      await fixture.signIn();
      expect(
        await fixture.client.rpc('get_bundle_status'),
        isA<Map<String, dynamic>>(),
      );
      final notifier = BundleEntitlementNotifier(client: fixture.client);
      await notifier.refresh(forceRefresh: true);
      await notifier.recordBundlePurchase(
        signedTransaction: 'header.payload.signature',
      );
      expect(notifier.state.isActive, isTrue);
      expect(fixture.verificationRequests, hasLength(1));
      final request = fixture.verificationRequests.single;
      expect(jsonDecode(request.body), {
        'bundleId': 'com.fitnesslog.fitnessLogApp',
        'signedTransaction': 'header.payload.signature',
      });
      expect(
        request.headers['Authorization'],
        'Bearer ${fixture.client.auth.currentSession!.accessToken}',
      );
      notifier.dispose();
      await fixture.client.dispose();
    },
  );

  test(
    'account-required error keeps existing lease and hides upstream diagnostics',
    () async {
      final fixture = Fixture();
      await fixture.signIn();
      final notifier = BundleEntitlementNotifier(client: fixture.client);
      await notifier.refresh(forceRefresh: true);
      await notifier.recordBundlePurchase(
        signedTransaction: 'header.payload.signature',
      );
      fixture.verificationResponse = jsonResponse({
        'error': 'PURCHASE_ACCOUNT_REQUIRED',
        'details': 'PRIVATE-UPSTREAM',
      }, 409);
      await notifier.recordBundlePurchase(
        signedTransaction: 'old.payload.signature',
      );
      expect(notifier.state.isActive, isTrue);
      expect(notifier.state.errorMessage, isNot(contains('PRIVATE-UPSTREAM')));
      expect(notifier.state.errorMessage, contains('アプリ間共有'));
      notifier.dispose();
      await fixture.client.dispose();
    },
  );

  test(
    'sign-out discards shared state and late former-account response',
    () async {
      final fixture = Fixture();
      await fixture.signIn();
      final notifier = BundleEntitlementNotifier(client: fixture.client);
      await notifier.refresh(forceRefresh: true);
      final pending = Completer<http.Response>();
      fixture.rpc = () => pending.future;
      final refresh = notifier.refresh(forceRefresh: true);
      await fixture.client.auth.signOut();
      await Future<void>.delayed(Duration.zero);
      pending.complete(jsonResponse(bundle(true)));
      await refresh;
      expect(notifier.state.isActive, isFalse);
      notifier.dispose();
      await fixture.client.dispose();
    },
  );

  test('new account cannot inherit an old account response', () async {
    final fixture = Fixture();
    await fixture.signIn();
    final notifier = BundleEntitlementNotifier(client: fixture.client);
    await notifier.refresh(forceRefresh: true);
    final pending = Completer<http.Response>();
    fixture.rpc = () => pending.future;
    final oldRefresh = notifier.refresh(forceRefresh: true);
    fixture.rpc = null;
    await fixture.signIn(secondUser);
    pending.complete(jsonResponse(bundle(true)));
    await oldRefresh;
    await Future<void>.delayed(Duration.zero);
    expect(notifier.state.isActive, isFalse);
    notifier.dispose();
    await fixture.client.dispose();
  });

  test(
    'verification result cannot be overwritten by an earlier pending read',
    () async {
      final fixture = Fixture();
      await fixture.signIn();
      final notifier = BundleEntitlementNotifier(client: fixture.client);
      await notifier.refresh(forceRefresh: true);
      final pending = Completer<http.Response>();
      fixture.rpc = () => pending.future;
      final refresh = notifier.refresh(forceRefresh: true);
      await notifier.recordBundlePurchase(
        signedTransaction: 'header.payload.signature',
      );
      pending.complete(jsonResponse(bundle(false)));
      await refresh;
      expect(notifier.state.isActive, isTrue);
      notifier.dispose();
      await fixture.client.dispose();
    },
  );

  test('missing or expired server expiry never grants access', () {
    final now = DateTime.now();
    expect(
      const BundleStatusResponse(
        bundleActive: true,
        checkedAt: 0,
      ).isActiveAt(now),
      isFalse,
    );
    expect(
      BundleStatusResponse(
        bundleActive: true,
        bundleExpiresAt: now.millisecondsSinceEpoch ~/ 1000,
        checkedAt: 0,
      ).isActiveAt(now),
      isFalse,
    );
  });

  test('non-iOS receipt never reaches the Apple verifier', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final fixture = Fixture();
    await fixture.signIn();
    final notifier = BundleEntitlementNotifier(client: fixture.client);
    await notifier.recordBundlePurchase(
      signedTransaction: 'header.payload.signature',
    );
    expect(fixture.verificationRequests, isEmpty);
    expect(notifier.state.isActive, isFalse);
    notifier.dispose();
    await fixture.client.dispose();
  });
  test(
    'late active verification cannot revive a newer inactive status',
    () async {
      final fixture = Fixture();
      await fixture.signIn();
      final notifier = BundleEntitlementNotifier(client: fixture.client);
      await notifier.refresh(forceRefresh: true);
      final pending = Completer<http.Response>();
      fixture.verify = () => pending.future;
      final verification = notifier.recordBundlePurchase(
        signedTransaction: 'header.payload.signature',
      );
      await Future<void>.delayed(Duration.zero);
      await notifier.refresh(forceRefresh: true);
      expect(notifier.state.isActive, isFalse);
      pending.complete(jsonResponse(bundle(true)));
      await verification;
      expect(notifier.state.isActive, isFalse);
      notifier.dispose();
      await fixture.client.dispose();
    },
  );
  test(
    'shared rights are never persisted as device pro; logout clears effective pro',
    () async {
      final fixture = Fixture();
      await fixture.signIn();
      final shared = BundleEntitlementNotifier(client: fixture.client);
      await shared.refresh(forceRefresh: true);
      final local = DevicePurchases({});
      final settings = MemorySettings();
      final container = ProviderContainer(
        overrides: [
          iapServiceProvider.overrideWith((_) => local),
          bundleEntitlementProvider.overrideWith((_) => shared),
          settingsDaoProvider.overrideWithValue(settings),
        ],
      );
      final controller = container.read(entitlementProvider.notifier);
      await Future<void>.delayed(Duration.zero);
      // An old persisted pro bit (possibly from shared rights) is not current device proof.
      expect(container.read(isProProvider), isFalse);
      await shared.recordBundlePurchase(
        signedTransaction: 'header.payload.signature',
      );
      expect(container.read(isProProvider), isTrue);
      expect(container.read(featureGateProvider).isPro, isTrue);
      await controller.checkEntitlement();
      expect(settings.writes, isNot(contains('pro')));
      await fixture.client.auth.signOut();
      await Future<void>.delayed(Duration.zero);
      expect(container.read(isProProvider), isFalse);
      expect(container.read(featureGateProvider).isPro, isFalse);
      container.dispose();
      await fixture.client.dispose();
    },
  );

  test(
    'legacy account-required error keeps a real device bundle pro',
    () async {
      final fixture = Fixture();
      await fixture.signIn();
      fixture.verificationResponse = jsonResponse({
        'error': 'PURCHASE_ACCOUNT_REQUIRED',
      }, 409);
      final shared = BundleEntitlementNotifier(client: fixture.client);
      await shared.refresh(forceRefresh: true);
      final local = DevicePurchases({IAPProductIds.bundleMonthlySubscription});
      final settings = MemorySettings();
      final container = ProviderContainer(
        overrides: [
          iapServiceProvider.overrideWith((_) => local),
          bundleEntitlementProvider.overrideWith((_) => shared),
          settingsDaoProvider.overrideWithValue(settings),
        ],
      );
      await shared.recordBundlePurchase(
        signedTransaction: 'old.payload.signature',
      );
      await container.read(entitlementProvider.notifier).checkEntitlement();
      expect(shared.state.isActive, isFalse);
      expect(container.read(isProProvider), isTrue);
      container.dispose();
      await fixture.client.dispose();
    },
  );

  test(
    'server lease expiry clears effective pro without device purchases',
    () async {
      final fixture = Fixture();
      await fixture.signIn();
      final expires = DateTime.now().millisecondsSinceEpoch ~/ 1000 + 1;
      fixture.verificationResponse = jsonResponse({
        ...bundle(true),
        'bundle_expires_at': expires,
      });
      final shared = BundleEntitlementNotifier(client: fixture.client);
      await shared.refresh(forceRefresh: true);
      final container = ProviderContainer(
        overrides: [
          iapServiceProvider.overrideWith((_) => DevicePurchases({})),
          bundleEntitlementProvider.overrideWith((_) => shared),
        ],
      );
      await shared.recordBundlePurchase(
        signedTransaction: 'header.payload.signature',
      );
      expect(container.read(isProProvider), isTrue);
      await Future<void>.delayed(const Duration(milliseconds: 1200));
      expect(container.read(isProProvider), isFalse);
      expect(container.read(featureGateProvider).isPro, isFalse);
      container.dispose();
      await fixture.client.dispose();
    },
  );
}
