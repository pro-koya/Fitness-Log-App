# サーバー同期機能 現状仕様と問題洗い出し

## 1. 現状の仕様

### 1.1 フロー概要
1. **設定画面**で「今すぐ同期」ボタン押下
2. `ref.read(syncServiceProvider).syncNow()` を呼び出し（90秒タイムアウト + 91秒セーフティタイマー）
3. **SyncService.syncNow()** の処理:
   - Supabase 未設定 or 未ログイン → 即時でエラーメッセージを返す
   - サーバー側の当該ユーザーデータを**全削除**（set_records → workout_exercises → workout_sessions → body_weight_records → exercise_master）
   - ローカルから取得: 種目全件、完了セッション全件、体重全件
   - **exercise_master** を 1 件ずつ insert（ローカル id → 新 UUID のマップ作成）
   - **workout_sessions** を 1 件ずつ insert（ローカル id → 新 UUID のマップ作成）
   - **workout_exercises** をセッション単位で取得し 1 件ずつ insert（session_id / exercise_id は上記マップの UUID）
   - **set_records** を workout_exercise 単位で取得し 1 件ずつ insert
   - **body_weight_records** を 1 件ずつ insert
   - **SettingsDao.updateLastSyncedAt(now)** で最終同期時刻を更新
   - 成功時は `null`、例外時は `e.toString()` を返す
4. UI: 成功時は緑 SnackBar、失敗時は赤 SnackBar。**finally** で `_isSyncing = false` を必ず実行

### 1.2 使用している主なコンポーネント
- **sync_providers.dart**: `syncServiceProvider`（SyncService）、`lastSyncedAtProvider`（SettingsDao）
- **sync_service.dart**: Supabase client、各 DAO（直接 new）、SettingsDao（注入）
- **settings_screen.dart**: 同期ボタン、try/catch/finally、90秒 timeout、91秒 safety Timer

---

## 2. 問題1: 「ぐるぐる」が終わらない

### 2.1 想定される原因（洗い出し）

| # | 箇所 | 内容 | 可能性 |
|---|------|------|--------|
| A | **syncNow() が Future を返さない** | ネットワークや Supabase の応答待ちでハングし、90秒経過してもタイマーが発火しない（例: メイン isolate がブロックされている） | 低（await で yield するはず） |
| B | **タイムアウトが効いていない** | `.timeout(90 sec)` の Future が、何らかの理由で完了しない | 低 |
| C | **例外が try の外で発生している** | 非同期の隙間に別の例外が発生し、catch されず finally まで届かない | 中 |
| D | **setState が呼べない** | `mounted == false` のため finally 内の setState をスキップしているが、実際は画面にいる | 要確認（finally で mounted チェックあり） |
| E | **Safety タイマーが動いていない** | 91秒タイマーが何らかの理由で発火しない | 低 |
| F | **syncNow() 内で同期的に長時間ブロック** | 最初の `getAllExercises()` や DB アクセスでメインスレッドがブロックし、イベントループが回らない | 理論上はあり得る（SQLite が重い場合など） |
| G | **Supabase クライアントの挙動** | リトライや内部でハングし、Future が完了しない | 要確認 |
| H | **複数回 setState や invalidate の影響** | ref.invalidate(lastSyncedAtProvider) などで再ビルドが走り、状態がおかしくなる | 低 |

### 2.2 確認・修正のポイント
- **syncNow() の先頭で `debugPrint` やログを入れ、少なくとも「処理開始」まで到達しているか確認する**
- **各 await の前後でログを入れ、どの段階で止まっているか特定する**
- **タイムアウト時に確実に `_isSyncing = false` が呼ばれるよう、timeout の onTimeout 内でも setState するなどの二重化を検討**
- **syncNow() を Isolate や compute で実行しているか**: していない。メイン isolate で実行されている

---

## 3. 問題2: データが反映されていない

### 3.1 想定される原因（洗い出し）

| # | 箇所 | 内容 | 可能性 |
|---|------|------|--------|
| 1 | **workout_exercises がスキップされる** | `serverExerciseId = exerciseIdMap[we.exerciseId]` が null。ローカルの workout_exercise が参照する exercise_id が、exercise_master に存在しない（別テーブルのプリセットのみなど） | 要確認 |
| 2 | **workout_exercises の insert で失敗** | FK（session_id, exercise_id）、RLS、型の不一致などで Postgrest がエラー。例外になり `e.toString()` が返るが、UI に表示されていない or 気づいていない | 中 |
| 3 | **set_records の insert で失敗** | weight_kg/weight_lb が NOT NULL、型、FK（workout_exercise_id 等）で失敗。同様に例外で返る | 中 |
| 4 | **削除の順序** | set_records → workout_exercises → workout_sessions の順で削除しているので、FK 的には正しい | 問題なし |
| 5 | **挿入の順序** | exercise_master → workout_sessions → workout_exercises → set_records → body_weight。FK 的には正しい | 問題なし |
| 6 | **Supabase の RLS** | POLICY が `auth.uid() = user_id`。insert 時に userId を渡しているが、セッション切れや auth のずれで RLS に弾かれる可能性 | 要確認 |
| 7 | **Supabase のテーブル・カラムが未作成 or 不一致** | supabase_schema.sql が実行されていない、またはカラム名・型が違う（例: BIGINT vs INTEGER） | 要確認 |
| 8 | **body_part / memo が null** | スキーマ上は NULL 可。Dart で null を送っている場合、Supabase がどう扱うか（問題ない想定） | 低 |
| 9 | **完了セッションが 0 件** | getCompletedSessions() が空なら workout_exercises も set_records も 0 件になる。セッションは「完了」になっているか | 要確認 |
| 10 | **exercise_master に種目が入っていない** | getAllExercises() が空、または workout_exercises が参照する id が含まれていない | 要確認 |
| 11 | **例外が握りつぶされている** | syncNow() の catch で return e.toString() しているので、呼び出し元には文字列が返る。UI は err != null で SnackBar 表示。表示されていないなら、err が null になっている（例外ではなく正常 return のつもりで別経路） | 要確認 |
| 12 | **lastSyncedAt 更新で失敗** | updateLastSyncedAt が失敗すると例外になり、syncNow() 全体が失敗として返る。その時点では insert は完了している可能性あり | 中 |

### 3.2 データ不整合の切り分け
- **workout_sessions だけ入って workout_exercises が 0 件** → 2 または 1
- **workout_exercises は入るが set_records が 0 件** → 3 または set_records の insert ループで serverSessionId/serverExerciseId が null でスキップされている
- **すべて 0 件** → 7, 9, 10 または認証・RLS

---

## 4. 修正時に確認すべきコード箇所一覧

1. **lib/features/settings/settings_screen.dart**  
   - 同期ボタン onPressed（try/catch/finally、timeout、safetyTimer）  
   - mounted チェックと setState の関係  

2. **lib/services/sync_service.dart**  
   - 各 insert のペイロード（キー名・型が Supabase と一致しているか）  
   - exerciseIdMap に全種目が入るか（getAllExercises と workout_exercises.exercise_id の対応）  
   - workout_exercises で serverExerciseId == null のスキップが多発していないか  
   - set_records で serverSessionId / serverExerciseId が null でスキップされていないか  

3. **lib/providers/sync_providers.dart**  
   - syncServiceProvider の依存（settingsDaoProvider の渡し方）  

4. **lib/data/dao/settings_dao.dart**  
   - updateLastSyncedAt が getSettings → copyWith → updateSettings の流れで正しく動くか  
   - settings が null のとき 0 を返すが、その前に sync の insert は完了している  

5. **supabase_schema.sql**  
   - 実際の Supabase プロジェクトにこのスキーマが適用されているか  
   - カラムの型（BIGINT, REAL, UUID, TEXT）と Dart から送る値の型が一致しているか  

6. **Supabase クライアント**  
   - insert の戻り値やエラーの形式（PostgrestException など）  
   - ネットワークエラー時の挙動（リトライするか、Future がいつ完了するか）  

---

## 5. 次のアクション（推奨）

1. **グラフ**: 成長・体重グラフを曲線→直線（折れ線）に変更済み。  
2. **ぐるぐる対策**:  
   - syncNow() の**最初**と**各ステップ後**に `debugPrint` を入れ、どこまで進んでいるかログで確認する。  
   - 可能なら、**onTimeout 発火時にも setState(() => _isSyncing = false)** を明示的に呼ぶ（現在は finally に依存）。  
3. **データ不反映対策**:  
   - workout_exercises の insert で `serverExerciseId == null` の件数をログに出し、スキップが多発していないか確認する。  
   - Supabase ダッシュボードの Logs / API で、insert の 4xx/5xx や RLS エラーが出ていないか確認する。  
   - 必要なら、**挿入をバッチ化**（複数行を一度に insert）してエラーメッセージをまとめて取得し、どのテーブルで失敗しているか特定しやすくする。

以上を踏まえ、次は「ぐるぐる」と「データ不反映」の両方に対して、ログ追加とエラー表示の明確化から入るのがおすすめです。
