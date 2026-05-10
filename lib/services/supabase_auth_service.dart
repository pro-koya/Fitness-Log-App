import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';

import '../core/supabase_config.dart';

/// Supabase 認証サービス。
/// ASWebAuthenticationSession を使用してアプリ内でOAuth認証を行い、
/// 認証完了後に自動でアプリに戻る。
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

  /// OAuth 完了後にアプリへ戻るためのカスタム URL スキーム
  static const String authRedirectScheme = 'com.fitnesslog.liftly';
  static const String authRedirectUrl = '$authRedirectScheme://auth/callback';

  /// Google アカウントでサインイン（SSO）
  /// ASWebAuthenticationSession を使用してアプリ内ブラウザで認証し、
  /// 認証完了後に自動でブラウザが閉じてアプリに戻る。
  Future<AuthResult> signInWithGoogle() async {
    return _signInWithOAuthProvider(OAuthProvider.google);
  }

  /// Apple アカウントでサインイン（SSO）
  /// Google と同じ Supabase OAuth + ASWebAuthenticationSession の経路を使う。
  Future<AuthResult> signInWithApple() async {
    return _signInWithOAuthProvider(OAuthProvider.apple);
  }

  /// 現在の Supabase アカウントとクラウド同期データの削除を要求する。
  /// サーバー側 Edge Function `delete-current-user` が JWT を検証して削除する。
  Future<AuthResult> deleteAccount() async {
    final client = _client;
    if (client == null) {
      return const AuthFailure('Supabase is not configured');
    }
    if (client.auth.currentSession == null) {
      return const AuthFailure('Not signed in');
    }

    try {
      await client.functions.invoke('delete-current-user');
      await client.auth.signOut();
      return const AuthSuccess();
    } on AuthException catch (e) {
      return AuthFailure(e.message);
    } catch (e) {
      return AuthFailure(e.toString());
    }
  }

  Future<AuthResult> _signInWithOAuthProvider(OAuthProvider provider) async {
    final client = _client;
    if (client == null) {
      return const AuthFailure('Supabase is not configured');
    }
    try {
      // 1. Supabase から OAuth URL を取得
      final oAuthResponse = await client.auth.getOAuthSignInUrl(
        provider: provider,
        redirectTo: authRedirectUrl,
      );

      // 2. ASWebAuthenticationSession でブラウザを開く
      //    認証完了後、カスタムスキームへのリダイレクトを検知して自動で閉じる
      final callbackUrl = await FlutterWebAuth2.authenticate(
        url: oAuthResponse.url.toString(),
        callbackUrlScheme: authRedirectScheme,
      );

      // 3. コールバック URL からセッションを確立
      final uri = Uri.parse(callbackUrl);
      await client.auth.getSessionFromUrl(uri);

      return const AuthSuccess();
    } on AuthException catch (e) {
      return AuthFailure(e.message);
    } catch (e) {
      // ユーザーがキャンセルした場合など
      if (e.toString().contains('CANCELED') ||
          e.toString().contains('cancelled')) {
        return const AuthFailure('cancelled');
      }
      return AuthFailure(e.toString());
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
