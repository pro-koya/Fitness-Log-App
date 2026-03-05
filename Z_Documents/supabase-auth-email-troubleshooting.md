# Supabase 認証メール（パスワードリセット等）のトラブルシューティング

## 1. メールが届かない場合

### 想定される原因

1. **未登録のメールアドレス**  
   Supabase は「このメールは登録されていない」と返すとメールアドレス列挙攻撃になるため、**登録されていないメールでも API は成功を返しますが、実際にはメールを送りません**。  
   → 必ず「アプリで一度サインアップしたメール」でパスワードリセットを試してください。

2. **標準のメール送信（組み込み SMTP）の制限と届きにくさ**  
   - 標準の Supabase メールは**開発・デモ用**です。  
   - **1時間あたり 2通まで**の制限があります（サインアップ・パスワードリセット・メール変更などすべて合算）。  
   - 送信元ドメインが `supabase.io` のため、受信側で迷惑メール扱いやブロックされやすいです。  
   - 届かない・遅い場合は、迷惑メールフォルダも確認してください。

3. **本番運用時**  
   本番では **カスタム SMTP** の設定を強く推奨します。  
   - ダッシュボード: **Authentication > SMTP Settings** で SendGrid / AWS SES / 自社 SMTP 等を設定。  
   - 設定後は送信数制限を自分で管理でき、届きやすさも改善します。

### 確認してほしいこと

- パスワードリセットを送ったメールは、**その Supabase プロジェクトでサインアップ済み**か。
- Supabase ダッシュボードの **Logs > Auth Logs** で、該当リクエストがエラーになっていないか。
- カスタム SMTP を使っている場合は、その送信ログでブロックやバウンスが出ていないか。

---

## 2. 「Email Limit Exceeded」が出る場合

### 原因

標準の Supabase メール送信には **「メールを送る系」の API 全体で 1時間あたり 2通** という制限があります。

- サインアップ確認メール
- パスワードリセットメール
- メール変更確認メール  

がすべてこの本数に含まれます。

### いつまで送れないか

- **約 1 時間** 経過すると、再度送信できるようになります（ロールリングの 1 時間窓）。
- 正確なリセット時刻はダッシュボードには表示されないため、「約1時間後にもう一度試す」と覚えておくとよいです。

### 対処

- **短期**: 1時間ほど待ってから再度「リセット用メールを送信」を実行する。
- **恒久**: 本番・テストとも、**Authentication > SMTP Settings** でカスタム SMTP を設定する。  
  設定後は「Email Limit Exceeded」は発生せず（自前 SMTP の制限に従う）、届きやすさも改善します。

---

## 参考リンク

- [Rate limits \| Supabase Docs](https://supabase.com/docs/guides/auth/rate-limits)
- [Not receiving Auth emails \| Supabase Troubleshooting](https://supabase.com/docs/guides/troubleshooting/not-receiving-auth-emails-from-the-supabase-project-OFSNzw)
- [Send emails with custom SMTP \| Supabase Docs](https://supabase.com/docs/guides/auth/auth-smtp)
