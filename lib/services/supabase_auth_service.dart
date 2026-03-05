import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart' show LaunchMode;

import '../core/supabase_config.dart';

/// Pro 同期用 Supabase 認証サービス。
/// 接続情報未設定時はサインイン・サインアウトは行わず null を返す。
class SupabaseAuthService {
  SupabaseClient? get _client {
    if (!SupabaseConfig.isConfigured) return null;
    return Supabase.instance.client;
  }

  /// 現在のユーザー（未ログインまたは未設定時は null）
  User? get currentUser => _client?.auth.currentUser;

  /// 現在のユーザー ID（UUID）。未ログイン時は null
  String? get currentUserId => currentUser?.id;

  /// 現在のユーザーのメールアドレス
  String? get currentUserEmail => currentUser?.email;

  /// ログイン済みか
  bool get isSignedIn => currentUser != null;

  /// 認証状態の変化ストリーム
  Stream<AuthState> get authStateChanges =>
      _client?.auth.onAuthStateChange ?? const Stream.empty();

  /// サインアウト
  Future<void> signOut() async {
    await _client?.auth.signOut();
  }

  /// OAuth 完了後にアプリへ戻るためのリダイレクト用 URL。
  /// カスタムスキーム（アプリのディープリンク）。ネイティブで登録すること。
  static const String authRedirectScheme = 'com.fitnesslog.liftly';
  static const String authRedirectUrl = '$authRedirectScheme://auth/callback';

  /// OAuth の redirectTo に使う HTTPS コールバック URL。
  /// Supabase はここへリダイレクトし、このページがアプリスキームへ転送する。
  /// デプロイ先に合わせて変更可能（Supabase の Redirect URLs にも同じ URL を登録すること）。
  static const String authRedirectUrlHttps =
      'https://pro-koya.github.io/auth/callback.html';

  /// Google アカウントでサインイン（SSO）
  /// 初回は新規ユーザーとして登録され、2回目以降は同じ Google アカウントでログイン。
  /// 外部 Safari で認証後、HTTPS コールバックページを経由してアプリに戻る。
  ///
  /// 流れ: Safari で認証 → Supabase が [authRedirectUrlHttps] へリダイレクト
  /// → コールバックページが [authRedirectUrl] へ転送 → アプリが URL を受け取りセッション確立。
  Future<AuthResult> signInWithGoogle() async {
    if (_client == null) {
      return AuthFailure('Supabase is not configured');
    }
    try {
      final useExternalOnIOS = !kIsWeb && Platform.isIOS;

      await _client!.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: authRedirectUrlHttps,
        authScreenLaunchMode: useExternalOnIOS
            ? LaunchMode.externalApplication
            : LaunchMode.platformDefault,
      );
      return const AuthSuccess();
    } on AuthException catch (e) {
      return AuthFailure(e.message);
    }
  }
}

/// 認証操作の結果
sealed class AuthResult {
  const AuthResult();
}

class AuthSuccess extends AuthResult {
  const AuthSuccess();
}

class AuthFailure extends AuthResult {
  final String message;
  const AuthFailure(this.message);
}
