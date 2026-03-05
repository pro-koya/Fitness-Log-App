# Supabase カスタム SMTP 設定手順（無料で本番運用）

本番運用で認証メール（サインアップ確認・パスワードリセット等）を安定して送るため、Supabase でカスタム SMTP を設定する手順です。**無料枠**で使えるサービスを前提にしています。

---

## 無料で使える SMTP の選択肢

| サービス | 無料枠 | 特徴 | クレジットカード |
|---------|--------|------|------------------|
| **Brevo**（旧 Sendinblue） | **300通/日**（約9,000通/月） | 無料枠が大きく、SMTP キーが取得しやすい。Gmail/Outlook の届きやすさも良好。 | 不要 |
| **Resend** | 100通/日 | 開発者向けでシンプル。送信元ドメインの認証が必要。 | 不要 |
| **Gmail**（@gmail.com） | 500通/日（通常アカウント） | 普段使っている Gmail で送信。2段階認証とアプリパスワードが必要。 | 不要 |
| **SendGrid** | 100通/日（無料トライアル 60日間） | 有名だが無料は期間限定。 | トライアルで必要になる場合あり |

**おすすめ**: 無料で長く使うなら **Brevo**（300通/日）。**Gmail で手軽に試したい**場合は方法Cを参照。  
以下は **Brevo** をメインに、Supabase 側の設定まで一通り書きます。Resend を使う場合の違いも末尾にまとめます。

---

## 前提：Supabase ダッシュボードの開き方

1. [Supabase](https://supabase.com) にログイン
2. 対象の**プロジェクト**を選択
3. 左サイドバー **Authentication** → **Email** または **SMTP** を開く  
   - 画面表記は **Email** / **SMTP Settings** などプロジェクトによって少し違う場合があります

---

# 方法A: Brevo で設定する（推奨・無料 300通/日）

## ステップ1: Brevo アカウント作成と SMTP キー取得

1. **Brevo に登録**
   - https://www.brevo.com/ にアクセス
   - 「無料で始める」からアカウント作成（メールアドレスとパスワードのみでOK、クレジットカード不要）

2. **送信元メールアドレス（送信元ドメイン）の準備**
   - 認証メールの「差出人」になるアドレスを決めます（例: `noreply@yourdomain.com`）
   - **自分のドメイン**（例: `yourdomain.com`）がある場合:
     - Brevo の **設定 > 送信ドメイン** でドメインを追加し、表示される **SPF / DKIM の DNS レコード**をドメインの DNS に追加して「認証」する必要があります（Gmail/Yahoo 等に届きやすくなります）
   - **ドメインがない場合**:
     - Brevo はトランザクションメールでも**送信元ドメインの認証（DNS 設定）**を求めるため、無料のサブドメインサービスや Resend のサンドボックス送信でテストする方法があります。Resend はドメイン認証前に `onboarding@resend.dev` などからテスト送信できる場合があります（要 [Resend ドキュメント](https://resend.com/docs) で確認）

3. **SMTP キーを取得**
   - Brevo にログイン後、右上の **設定（歯車）** → **SMTP と API** → **SMTP** タブを開く
   - 既存の SMTP ログインがある場合はその「パスワード」（SMTP キー）を表示してコピー。ない場合は **「SMTP キーを生成」** で新規作成
   - **SMTP ログイン（ユーザー名）** と **SMTP キー（パスワード）** をメモ  
     - ホスト: `smtp-relay.brevo.com`  
     - ポート: **587**（TLS）または **465**（SSL）  
     - ユーザー名: 表示されている SMTP ログイン（メール形式のことが多い）  
     - パスワード: SMTP キー（API キーとは別です）

## ステップ2: Supabase でカスタム SMTP を有効化

1. **Supabase ダッシュボード**で対象プロジェクトを開く
2. 左サイドバー **Authentication** → **Email**（または **SMTP**）をクリック
3. **「Enable Custom SMTP」** または **「Custom SMTP」** をオンにする
4. 次の項目を入力（Brevo の値で埋めます）:

   | 項目 | 入力例（Brevo） |
   |------|------------------|
   | **Sender email**（送信元メール） | Brevo で認証したアドレス（例: `noreply@yourdomain.com`） |
   | **Sender name**（送信元名） | アプリ名（例: `Fitness Log`） |
   | **Host** | `smtp-relay.brevo.com` |
   | **Port** | `587`（TLS 推奨）または `465`（SSL） |
   | **Username** | Brevo の SMTP ログイン（メール形式） |
   | **Password** | Brevo の SMTP キー |

5. **Save** をクリックして保存

## ステップ3: 送信数制限の調整（任意）

- カスタム SMTP を有効にすると、Supabase 側のデフォルトは「メール送信 30通/時」程度に制限されていることがあります。
- 必要に応じて: **Authentication** → **Rate Limits** で「Email sent」などの制限を確認・変更できます（Brevo の無料枠 300通/日以内に収まる値にするとよいです）。

## ステップ4: 動作確認

1. アプリから「パスワードを忘れた」で**登録済みのメールアドレス**を入力してリセットメールを送信
2. 受信トレイ（迷惑メールも）を確認
3. 届かない場合: Supabase の **Logs > Auth Logs** と Brevo の送信ログでエラーを確認

---

# 方法B: Resend で設定する（無料 100通/日）

1. **Resend に登録**
   - https://resend.com でアカウント作成（無料、クレジットカード不要で開始可能）

2. **ドメイン認証**
   - Resend ダッシュボードの **Domains** で送信に使うドメインを追加し、表示される DNS レコード（SPF/DKIM 等）を設定
   - テストのみの場合は、Resend が提供するサンドボックス用アドレス（例: `onboarding@resend.dev`）で送信できる場合があります（要公式ドキュメント確認）

3. **API キー取得**
   - **API Keys** でキーを発行し、コピー

4. **Supabase に SMTP 設定**
   - **Authentication** → **Email** / **SMTP** を開き、Custom SMTP を有効化
   - 次を入力:

   | 項目 | 入力例（Resend） |
   |------|------------------|
   | **Sender email** | Resend で認証したドメインのアドレス（例: `noreply@yourdomain.com`） |
   | **Sender name** | アプリ名 |
   | **Host** | `smtp.resend.com` |
   | **Port** | `465` |
   | **Username** | `resend`（固定） |
   | **Password** | Resend の **API キー**（SMTP パスワードとして使用） |

5. **Save** で保存し、アプリからパスワードリセット等で送信テスト

---

# 方法C: Gmail を使う（手軽に試す場合）

普段使っている **@gmail.com** のアカウントで認証メールを送れます。無料で 1日あたり約 500通まで送信可能です。

## ステップ1:  Google アカウントで 2段階認証とアプリパスワードを用意

1. **2段階認証を有効化**
   - https://myaccount.google.com/security を開く
   - 「2段階認証」をオンにする（まだの場合）

2. **アプリパスワードを発行**
   - https://myaccount.google.com/apppasswords を開く
   - 「アプリを選択」で「メール」など適当なものを選び、「デバイスを選択」で「その他」を選んで名前（例: Supabase）を入力
   - 「生成」を押すと **16文字のパスワード** が表示されるので、これをコピー（Gmail のログインパスワードとは別です）

## ステップ2: Supabase に Gmail SMTP を設定

1. Supabase ダッシュボード → **Authentication** → **Email** / **SMTP**
2. **Enable Custom SMTP** をオンにし、次を入力:

   | 項目 | 入力例（Gmail） |
   |------|------------------|
   | **Sender email** | その Gmail アドレス（例: `yourapp@gmail.com`） |
   | **Sender name** | アプリ名（例: `Fitness Log`） |
   | **Host** | `smtp.gmail.com` |
   | **Port** | `587` |
   | **Username** | Gmail アドレス（同上） |
   | **Password** | 上で発行した **アプリパスワード**（16文字） |

3. **Save** で保存

## Gmail を使うときの注意

- **パスワード**には、普段の Gmail のログインパスワードではなく、**アプリパスワード**だけを入れます。
- 送信元（差出人）はその Gmail アドレスになるため、「この Gmail からパスワードリセットが届く」形になります。個人用アドレスを本番で使う場合は、専用の Gmail を用意すると分かりやすいです。
- Google は「安全性の低いアプリ」の通常パスワードでのアクセスを段階的に廃止しており、**2段階認証 + アプリパスワード** が前提です。

---

# よくある注意点

- **送信元ドメイン認証**
  - Gmail / Yahoo 等に届きやすくするには、送信元ドメインの **SPF・DKIM（場合により DMARC）** を、Brevo や Resend の案内どおり DNS に追加する必要があります。
- **「Sender email」**
  - Supabase の Sender email には、必ず Brevo/Resend で**認証済み**のアドレスを指定してください。未認証だと送信失敗やブロックの原因になります。
- **パスワードの取り違え**
  - Brevo: **SMTP キー**（SMTP タブで表示）を使います。API キーやログインパスワードではありません。
  - Resend: **API キー**を SMTP のパスワード欄に入れます。
  - Gmail: **アプリパスワード**（2段階認証を有効にしたうえで Google アカウントから発行）を使います。通常の Gmail ログインパスワードは使えません。

---

# サイトURL・リダイレクトURL（パスワードリセットのリンク先）

Supabase の **Authentication** → **URL Configuration** にある **Site URL** と **Redirect URLs** は、メール内の「パスワードリセット」リンクの**行き先**を決める設定です。

## 現状の `http://localhost:3000` について

- **localhost** は「いま使っているパソコン自身」を指します。
- ユーザーが**スマホ**でメールのリンクを開くと、スマホのブラウザが「スマホの localhost:3000」を開こうとして、何も動いていないため**エラーや真っ白**になります。
- そのため、**本番や実機テストでは localhost は使わず、別の URL を設定する必要があります。**

## 設定が必要な理由

1. **Site URL**  
   認証メール内のリンクや、リダイレクトの基準になる「アプリの本来の URL」です。  
   本番では「アプリの Web サイト」または「アプリを開くための URL」を指定します。

2. **Redirect URLs**  
   認証完了後（メール確認・パスワードリセットなど）に**飛んでよい URL の一覧**です。  
   ここに載っていない URL にはリダイレクトされないため、**パスワードリセットのリンク先は必ずここに含まれる必要があります。**

## Flutter アプリ（ネイティブ）の場合の選び方

アプリが **Web ではなくスマホアプリだけ** の場合、次のどちらかになります。

### パターンA: ウェブの「完了ページ」を用意する（おすすめ・簡単）

- 用意するもの: **1枚のウェブページ**（例: `https://yourdomain.com/auth/reset-complete`）
  - 内容例: 「パスワードを再設定するには、メール内のリンクを**この端末のブラウザ**で開いてください。開いたあと、画面の指示に従って新しいパスワードを入力してください。」
  - または Supabase の「Confirm signup / Reset password」用テンプレートのように、**同じページ上で新しいパスワードを入力するフォーム**を置き、Supabase Auth の API（`recoverSession` や `updateUser`）を呼ぶ実装にする方法もあります（要 JavaScript 実装）。
- Supabase の設定例:
  - **Site URL**: `https://yourdomain.com`（あなたのサイトのトップなど）
  - **Redirect URLs** に追加: `https://yourdomain.com/auth/reset-complete` や `https://yourdomain.com/**`（ワイルドカード可かはダッシュボードの表記に従ってください）

こうすると、ユーザーがメールのリンクをタップ → ブラウザでそのページが開く → そこでパスワードを再設定、という流れにできます。  
**DeveloperSite や GitHub Pages など、すでに持っているサイトのパスを 1 つ使う**のが手軽です。

### パターンB: アプリのディープリンクを使う

- アプリで **ディープリンク**（例: `fitnesslogapp://auth/callback`）を扱えるようにし、その URL を Redirect URLs に追加する方法です。
- メールのリンクをタップ → ブラウザからアプリが起動 → アプリ内で「新しいパスワード入力」画面を出し、Supabase の `updateUser` で完了、という流れにできます。
- 実装には、`app_links` などで URL を受け取り、フラグメント内の `access_token` や `type=recovery` を処理するコードが必要です。

## まとめ：何を設定すればよいか

| 状況 | 推奨 |
|------|------|
| 開発中（PC のブラウザでだけ確認） | `http://localhost:3000` のままでよい |
| 本番・実機でパスワードリセットを使う | **Site URL** と **Redirect URLs** を、上記の「ウェブの完了ページ」または「アプリのディープリンク」に変更する。localhost は本番では使わない。 |
| すでに Web サイト（DeveloperSite 等）がある | そのドメインのパスを 1 つ決め（例: `https://yoursite.github.io/auth/callback`）、Site URL と Redirect URLs に追加する。 |

Redirect URLs には、**実際にリダイレクト先として使う URL をすべて列挙**します。Supabase の画面では「Redirect URLs」の欄に 1 行 1 URL で追加できます。

## トラブル：リンクをクリックするとトップページ（index）に飛んでしまう・URL に error や code が付く

- **原因**: **Redirect URLs** に「パスワードリセット専用ページ」の**フルURL**が登録されていない、または **Site URL** だけが登録されていてリダイレクト先がトップになっている。
- **対処**:
  1. Supabase の **Authentication** → **URL Configuration** の **Redirect URLs** に、**専用ページのフルURLを 1 行で追加**してください。
     - 例（GitHub Pages で `docs` を公開している場合）:  
       `https://pro-koya.github.io/docs/auth/reset-complete.html`  
       （`pro-koya.github.io` の部分はあなたの実際のドメインに合わせる。リポジトリ名が URL に含まれる場合は `https://pro-koya.github.io/リポジトリ名/auth/reset-complete.html`）
     - **Site URL** はトップでよいです（例: `https://pro-koya.github.io/`）。**Redirect URLs** に上記の `.../auth/reset-complete.html` を追加すると、次回からメールのリンクを開いたときに最初から専用ページに飛びます。
  2. 設定を変える前にすでにトップ（index）に飛んでしまう場合でも、**index に `?code=...` や `?error=...` が付いていれば自動で `auth/reset-complete.html` にリダイレクト**するようにしています。そのため、トップに飛んでもすぐにパスワードリセット専用画面に遷移します。
- 追加後、メールの「パスワードリセット」リンクを再度送信し、新しいリンクで試してください。

## トラブル：`otp_expired` や「Email link is invalid or has expired」

- **原因**: メール内のリンクには**有効期限**（多くの場合 1 時間）があります。期限を過ぎてクリックするとこのエラーになります。
- **対処**: アプリの 設定 → 同期 で「パスワードを忘れた」から**もう一度リセット用メールを送信**し、届いた**新しいリンク**を有効期限内に開いてください。  
  リダイレクト先のページ（`auth/reset-complete.html`）では、このエラー時に「リンクの有効期限が切れました。再度リセット用メールを送信してください。」と表示するようにしています。

---

# 参考リンク

- [Supabase: Send emails with custom SMTP](https://supabase.com/docs/guides/auth/auth-smtp)
- [Supabase: Auth Rate Limits](https://supabase.com/docs/guides/auth/rate-limits)
- [Brevo: SMTP でトランザクションメールを送る](https://help.brevo.com/hc/en-us/articles/7924908994450-Send-transactional-emails-using-Brevo-SMTP)
- [Resend: Send emails using Supabase with SMTP](https://resend.com/docs/send-with-supabase-smtp)
