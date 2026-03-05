# Supabase Google SSO 設定（Liftly）

Liftly の Pro 同期では、認証を **Google アカウントのみ** の SSO にしています。メール・パスワード登録およびパスワードリセットは行いません。

---

## 1. Google Cloud Console の詳細手順

Supabase が Google ログインを扱うため、**Google Cloud 側では「ウェブアプリケーション」用の OAuth 2.0 クライアントを 1 つ作成**すれば十分です（Flutter アプリはブラウザ経由で Supabase のコールバック URL に戻るため）。

### 1.1 プロジェクトの作成・選択

1. [Google Cloud Console](https://console.cloud.google.com/) に Google アカウントでログインする。
2. 上部のプロジェクト選択で **「新しいプロジェクト」** をクリックする。
3. プロジェクト名（例: `Liftly`）を入力し、**作成** する。
4. 作成したプロジェクトが選択されていることを確認する。

### 1.2 OAuth 同意画面の設定

1. 左メニュー **「API とサービス」** → **「OAuth 同意画面」** を開く。  
   または [OAuth 同意画面](https://console.cloud.google.com/apis/credentials/consent) に直接アクセスする。
2. **ユーザータイプ** で **「外部」** を選び **「作成」** する（テスト運用なら「外部」で問題ありません）。
3. **OAuth 同意画面（アプリ情報）** を入力する：
   - **アプリ名**: `Liftly`（任意の名前）
   - **ユーザーサポートメール**: 自分のメールを選択
   - **デベロッパーの連絡先情報**: 自分のメールを入力
   - **保存して次へ**
4. **スコープ** 画面で **「スコープを追加または削除」** をクリックする。
5. 次のスコープを追加する（Supabase がプロフィール取得に使用）：
   - `.../auth/userinfo.email`（メール）
   - `.../auth/userinfo.profile`（プロフィール）
   - **`openid`**（手動で検索して追加。必須）
6. **「更新」** → **「保存して次へ」** とする。
7. **テストユーザー**（「外部」で「公開」前の場合）: 必要なら自分のメールを追加。**「保存して次へ」**。
8. **「ダッシュボードに戻る」** で完了。

### 1.3 認証情報（OAuth 2.0 クライアント ID）の作成

1. 左メニュー **「API とサービス」** → **「認証情報」** を開く。  
   または [認証情報](https://console.cloud.google.com/apis/credentials) に直接アクセスする。
2. **「+ 認証情報を作成」** → **「OAuth クライアント ID」** を選ぶ。
3. **アプリケーションの種類** で **「ウェブアプリケーション」** を選ぶ。
4. **名前**: 例として `Liftly Supabase Web` など分かりやすい名前を付ける。
5. **承認済みの JavaScript 生成元** に以下を 1 行ずつ追加する：
   - 本番用: `https://<PROJECT_REF>.supabase.co`  
     （`<PROJECT_REF>` は Supabase のプロジェクト参照 ID。ダッシュボードの URL や Project Settings で確認できる。）
   - ローカル開発のみ使う場合: `http://localhost` または `http://127.0.0.1`  
     （本番公開時は削除してよい。）
6. **承認済みのリダイレクト URI** に以下を追加する：
   - 本番用: `https://<PROJECT_REF>.supabase.co/auth/v1/callback`  
     例: `https://lybgdrxsojuaylnvdmwb.supabase.co/auth/v1/callback`
   - ローカル開発のみ使う場合: `http://127.0.0.1:54321/auth/v1/callback`  
     （Supabase をローカルで動かしている場合。本番のみなら不要。）
7. **「作成」** をクリックする。
8. ダイアログに表示される **クライアント ID** と **クライアントシークレット** を控える（シークレットは再表示できない場合があるので、安全な場所に保存する）。

### 1.4 PROJECT_REF の確認方法

- Supabase ダッシュボードの **Project Settings** → **General** の **Reference ID**。
- またはダッシュボード URL: `https://supabase.com/dashboard/project/<PROJECT_REF>` の `<PROJECT_REF>` 部分。

### 1.5 よくあるエラーと確認ポイント

| 現象 | 確認すること |
|------|----------------|
| **redirect_uri_mismatch** | Google の「承認済みのリダイレクト URI」が `https://<PROJECT_REF>.supabase.co/auth/v1/callback` と**完全一致**しているか（`https`・末尾スラッシュなし・supabase.co の綴り）。 |
| **access_denied** / 同意画面でエラー | OAuth 同意画面のスコープに `openid`・`userinfo.email`・`userinfo.profile` が含まれているか。外部ユーザーの場合は「テストユーザー」に自分のメールを追加しているか。 |
| クライアントシークレットを忘れた | 認証情報一覧で該当クライアントの「編集」→ 新しいシークレットを再発行できる（古いシークレットは無効になるので、Supabase 側も更新する）。 |

---

## 2. Supabase ダッシュボード

1. **Authentication → Providers** で **Google** を有効化する。
2. **Client ID** と **Client Secret** に、上記 1.3 で控えた値を貼り付けて保存する。
   - [Supabase ダッシュボード - Google プロバイダー](https://supabase.com/dashboard/project/_/auth/providers?provider=Google) で設定できる。
3. **Authentication → URL Configuration** の **Redirect URLs** に、**ディープリンクの URL** を 1 件追加する（次の「ディープリンク設定」を参照）。

---

## 3. ディープリンク設定（OAuth 後にアプリへ戻る）

Google ログイン完了後、Supabase が**アプリを再度開く**ために、カスタム URL スキーム（ディープリンク）を使います。以下をすべて行うと、ログイン後に自動でアプリに戻ります。

### 3.1 使っている URL とフロー（外部 Safari で「アドレスが無効」を防ぐ）

外部 Safari で認証すると、Supabase が **カスタムスキーム**（`com.fitnesslog.liftly://auth/callback`）へ直接リダイレクトし、Safari が「アドレスが無効」と表示する問題を避けるため、**HTTPS のコールバックページを経由**しています。

| 項目 | 値 |
|------|-----|
| **redirectTo（アプリから Supabase に渡す）** | `https://pro-koya.github.io/auth/callback.html` |
| コールバックページ | 上記 URL。Supabase が `?code=...` 付きでリダイレクト → ページが `com.fitnesslog.liftly://auth/callback?code=...` へ転送 → アプリが起動してセッション確立 |
| アプリのスキーム（ディープリンク用） | `com.fitnesslog.liftly`（パス: `/auth/callback`） |

- アプリは `SupabaseAuthService.authRedirectUrlHttps` を `redirectTo` に指定しています。
- デプロイ先が異なる場合は `authRedirectUrlHttps` を変更し、Supabase の Redirect URLs も同じ URL にしてください（例: `/docs/auth/` なら `.../docs/auth/callback.html`）。

### 3.2 Supabase ダッシュボードで Redirect URL を追加

1. Supabase ダッシュボード → **Authentication** → **URL Configuration** を開く。
2. **Redirect URLs** に次を追加する（**HTTPS コールバック**を必須とする）：
   ```
   https://pro-koya.github.io/auth/callback.html
   ```
3. **Save** で保存する。
4. デプロイ先が異なる場合（例: `/docs/` 以下）は、実際のコールバックページの URL を登録する（例: `https://pro-koya.github.io/docs/auth/callback.html`）。

### 3.3 iOS（Info.plist）

アプリ側で次の URL スキームを登録済みです（`ios/Runner/Info.plist`）。

- **CFBundleURLTypes** に **CFBundleURLSchemes** = `com.fitnesslog.liftly` を追加している。
- これで `com.fitnesslog.liftly://auth/callback?...` のようなリンクがアプリで開く。

手動で確認・修正する場合:

1. Xcode で `ios/Runner/Info.plist` を開く。
2. **URL Types** を追加（または既存の 1 件を確認）。
3. **URL Schemes** に `com.fitnesslog.liftly` が 1 つ入っていること。
4. **Role** は `Editor` のままでよい。

### 3.4 Android（AndroidManifest.xml）

アプリ側で次の intent-filter を追加済みです（`android/app/src/main/AndroidManifest.xml`）。

- **action**: `VIEW`
- **category**: `DEFAULT`, `BROWSABLE`
- **data**:
  - `android:scheme="com.fitnesslog.liftly"`
  - `android:host="auth"`
  - `android:pathPrefix="/callback"`

これで `com.fitnesslog.liftly://auth/callback?...` がアプリで開きます。

手動で確認・修正する場合:

1. `android/app/src/main/AndroidManifest.xml` を開く。
2. `<activity android:name=".MainActivity" ...>` 内に、上記と同じ **intent-filter** が 1 つあること。
3. **MAIN / LAUNCHER** の intent-filter とは別に、**VIEW 用**の intent-filter が 1 つ必要。

### 3.5 動作の流れ（外部 Safari + HTTPS コールバック）

1. ユーザーが「Google でログイン」をタップ。
2. アプリが `signInWithOAuth(..., redirectTo: authRedirectUrlHttps)` を実行し、**外部 Safari** が開く（iOS は externalApplication）。
3. ユーザーが Google でサインインする。
4. Supabase が **HTTPS コールバック**（`https://pro-koya.github.io/auth/callback.html?code=...`）へリダイレクトする。
5. コールバックページが読み込まれ、即時に `com.fitnesslog.liftly://auth/callback?code=...` へ **転送**する（`window.location.replace`）。
6. OS がその URL でアプリを起動（または前面に出す）。Safari では「アドレスが無効」を出さずに済む。
7. **supabase_flutter** が `app_links` で URL を検知し、`getSessionFromUrl` でセッションを復元する。
8. `onAuthStateChange` でログイン完了が検知され、UI が更新される。

### 3.6 うまく戻ってこない場合の確認

| 確認項目 | 内容 |
|----------|------|
| Redirect URL（HTTPS） | Supabase の **Redirect URLs** に `https://pro-koya.github.io/auth/callback.html`（または実際のデプロイ URL）が入っているか。 |
| コールバックページのデプロイ | `DeveloperSite/docs/auth/callback.html` が GitHub Pages などで公開され、上記 URL で開けるか。 |
| iOS のスキーム | Info.plist の **CFBundleURLSchemes** が `com.fitnesslog.liftly` になっているか。 |
| Android の intent-filter | scheme / host / pathPrefix が `com.fitnesslog.liftly` / `auth` / `/callback` か。 |
| 実機での確認 | シミュレータより実機で検証する。 |

### 3.7 「アドレスが無効」を出さないための HTTPS コールバック

- **対策**: Supabase の `redirectTo` に **HTTPS のコールバックページ**（`authRedirectUrlHttps`）を指定しています。認証後はまずそのページへリダイレクトされ、そのページが `com.fitnesslog.liftly://auth/callback?code=...` へ転送するため、Safari は「アドレスが無効」を表示せず、アプリが確実に URL を受け取れます。
- **認証画面を開く時点で「無効」**: iOS では **外部 Safari** で開くため、認証用の https URL はそのまま開けます。問題が続く場合はネットワークや Supabase の URL を確認してください。

### 3.8 外部ブラウザで Google 認証が挟まれずすぐアプリに戻る場合

- **原因**: Supabase が `redirect_to` を許可していないと判断し、**Google の画面を出さずに**いきなり `redirect_to`（コールバックページ）へリダイレクトし、`?error=...` を付けて返すことがあります。その結果、コールバックページがアプリへ転送し、アプリにはエラー付きの URL が渡り、サインインが完了しません。
- **確認**: コールバックページ（`callback.html`）を **エラー時にアプリへ転送しない**ようにしてあります。ブラウザで「認証でエラーが返されました」と **error / error_description** が表示されたら、その内容を確認してください。
- **対処**:
  1. **Supabase の Redirect URLs** に、**アプリで使っているのと完全に同じ HTTPS URL** を 1 件追加する。
     - 例: `https://pro-koya.github.io/auth/callback.html`  
     - 先頭・末尾のスラッシュ、`http`/`https`、ホスト名の typo がないか確認する。
  2. **Site URL のドメイン** と **Redirect URL のドメイン** を揃える（Supabase が同一ドメインを要求する場合があります）。  
     例: Site URL が `https://pro-koya.github.io/...` なら、Redirect も `https://pro-koya.github.io/...` にする。
  3. 変更後、Supabase ダッシュボードで **Save** し、アプリで再度「Google でログイン」を試す。
- **期待する流れ**: 外部 Safari が開く → **Google のログイン／同意画面が表示される** → 認証後、コールバックページ（「アプリを開いています...」）が一瞬表示 → アプリが起動してサインイン完了。

---

## 4. アプリ側（Flutter）

- **設定 → 同期** で「Google でログイン」をタップすると `signInWithOAuth(OAuthProvider.google, redirectTo: authRedirectUrl)` が呼ばれる。
- ブラウザまたはシステムの認証画面が開き、Google でサインイン後に **ディープリンクでアプリに戻る**。
- 初回は新規ユーザーとして登録され、2回目以降は同じ Google アカウントでログインされる。

## 5. メール・パスワードとパスワードリセットについて

- メール・パスワードでの新規登録・ログインおよび「パスワードを忘れた」は **廃止** しています。
- 開発者サイトの `docs/auth/reset-complete.html` は、Google のみ運用では不要ですが、残しておいても害はありません（参照されないだけ）。

## 参考リンク

- [Login with Google | Supabase Docs](https://supabase.com/docs/guides/auth/social-login/auth-google)
- [Flutter API - signInWithOAuth](https://supabase.com/docs/reference/dart/auth-signinwithoauth)
