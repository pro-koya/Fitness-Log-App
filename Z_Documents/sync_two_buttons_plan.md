# サーバー同期 2ボタン仕様レビュー・実装計画

## 仕様レビュー

### 提案内容
- **「サーバーへデータを反映」** / **「サーバーからデータを取得」** の2ボタン
- 各実行前に確認ダイアログ:
  1. 取得時: 「サーバーのデータにより、デバイスのデータがすべて書き換えられます」
  2. 反映時: 「デバイスのデータにより、サーバーのデータがすべて書き換えられます」
- 実行するかどうか再度確認するフロー

### レビュー結論: **問題なし・この仕様で実装する**

- 2操作を分離することで目的が明確で、誤操作が起きにくい。
- 文言で「どちらが上書きされるか」が明示されている。
- 1回の確認（ダイアログで警告＋「実行する」「キャンセル」）で「再度確認」を満たせる。二重確認（2段階ダイアログ）は任意とする。

---

## 実装計画

1. **l10n**
   - ボタン: `syncPushToServer`, `syncPullFromServer`
   - ダイアログ: `syncConfirmPullMessage`, `syncConfirmPushMessage`, `syncConfirmTitle`, `syncConfirmExecute`, `syncConfirmCancel`
2. **SyncService**
   - 既存: `syncNow()` はそのまま（サーバーへ反映）。
   - 新規: `pullFromServer()` — サーバーから全件取得 → ローカルを全削除 → ID マッピングしながら挿入。
3. **DAO**
   - プル用に全削除メソッドを追加: set_records, workout_exercises, workout_sessions, body_weight_records, exercise_master の順で削除。
4. **設定画面**
   - 「今すぐ同期」を廃止し、「サーバーへデータを反映」「サーバーからデータを取得」の2ボタンに変更。
   - 各ボタン: 押下 → 確認ダイアログ（上記メッセージ）→ 「実行する」で push / pull 実行、ローディング・SnackBar は現行と同様。

---

## プル処理の詳細

- Supabase から `user_id` でフィルタして取得: exercise_master, workout_sessions, workout_exercises, set_records, body_weight_records。
- ローカルは FK の逆順で全削除（set_records → workout_exercises → workout_sessions → body_weight_records → exercise_master）。
- 挿入順: exercise_master（1件ずつ、server_uuid → local_id のマップ作成）→ workout_sessions（同様）→ workout_exercises（同様）→ set_records（マップで server id を local id に変換して挿入、可能ならバッチ）→ body_weight_records（一括挿入）。
- 最後に `updateLastSyncedAt(now)`。
