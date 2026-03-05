import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_auth_service.dart';
import '../services/sync_service.dart';
import 'database_providers.dart';
import '../utils/feature_gate.dart';

final supabaseAuthServiceProvider = Provider<SupabaseAuthService>((ref) {
  return SupabaseAuthService();
});

/// 認証状態の変化をストリームで監視するプロバイダ。
/// OAuth リダイレクト後にセッションが復元されるとここが更新され、
/// 同期カードなどが即座にログイン状態で再描画される。
final authStateChangesProvider = StreamProvider<AuthState>((ref) {
  final auth = ref.watch(supabaseAuthServiceProvider);
  return auth.authStateChanges;
});

final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService(
    authService: ref.watch(supabaseAuthServiceProvider),
    settingsDao: ref.watch(settingsDaoProvider),
  );
});

/// Pro かつ設定済みの場合のみ同期可能
final canSyncProvider = Provider<bool>((ref) {
  final gate = ref.watch(featureGateProvider);
  return gate.canSync;
});

/// 最終同期日時（epoch 秒）。未同期なら null
final lastSyncedAtProvider = FutureProvider<int?>((ref) async {
  final dao = ref.watch(settingsDaoProvider);
  return dao.getLastSyncedAt();
});
