# P2-3 Pro 追加ベネフィット 実装計画（Phase 1〜4）

深掘り案（`P2-3_Pro追加ベネフィット_深掘り案.md`）に基づく実装計画。メッセージは自然で違和感のない表現に統一する。

---

## Phase 1：種目別目標

### 1.1 データベース
- **テーブル** `exercise_goals`
  - `id` INTEGER PRIMARY KEY
  - `exercise_id` INTEGER NOT NULL (exercise_master.id)
  - `goal_type` TEXT NOT NULL ('weight' | 'reps' | 'volume' | 'time' | 'distance')
  - `goal_value` REAL NOT NULL（重量kg/lbはkgで保存、回数・ボリューム・秒・メートル）
  - `deadline_ts` INTEGER NULL（任意の期限・UNIX秒）
  - `created_at` INTEGER NOT NULL
  - `updated_at` INTEGER NOT NULL
  - UNIQUE(exercise_id) … 1種目1目標
- **マイグレーション**：version 16

### 1.2 ドメイン
- `ExerciseGoalEntity`（lib/data/entities/）
- `ExerciseGoalDao`（lib/data/dao/）：getByExerciseId, upsert, delete

### 1.3 機能ゲート
- `FeatureGate.canAccessExerciseGoals` => isPro。目標の設定・「目標まであと〇〇」の表示は Pro のみ。

### 1.4 UI
- **種目別進捗画面**：Pro 時のみ「目標」セクションを表示。目標未設定なら「目標を設定」ボタン→設定ダイアログ。目標設定済みなら「目標まであと〇〇」または「達成率〇〇%」を表示。Free 時は「Proで目標管理ができます」の案内＋Paywall導線。
- **目標設定ダイアログ**：種目の record_type に合わせて goal_type を制限（reps→weight/reps/volume、time→time、cardio→time/distance）。goal_value 入力、期限（任意）。
- **ワークアウト入力画面**：セット保存後に「この種目に目標があり、今回のセットで達成したか」を判定。達成時は SnackBar で自然な文言（例：「ベンチプレスで目標の100kgを達成しました」）を表示。1セッション中に同一種目で複数回達成しても、最初の1回のみ祝福するか、または「〇kgを達成しました」は1回だけにする。

### 1.5 達成判定ロジック
- セット保存後、当該 exercise_id の目標を取得。goal_type に応じて、セットの weight_kg / reps / (weight*reps) / duration_seconds / distance_meters と比較。以上なら「達成」とみなす。達成時は祝福メッセージを表示し、必要なら「達成済み」フラグをセッション単位で保持して重複表示を防ぐ。

### 1.6 文言（l10n）
- 目標設定：「目標を設定」「目標値」「期限（任意）」「保存」「削除」
- 進捗：「目標まであと〇〇」「達成率〇〇%」「Proで目標管理」
- 達成：「{exercise}で目標の{value}を達成しました」（自然な言い回し）

---

## Phase 2：週次サマリ

### 2.1 データ
- 既存の SetRecordDao / WorkoutSessionDao で週単位の集計を取得。週は「月曜始まり」で固定（必要なら設定で日曜始まりを追加）。

### 2.2 UI
- **週次サマリ画面**（新規）：週選択（前週/今週/翌週など）、選択週の「トレーニング回数」「総ボリューム」「種目数」「前週比」。週次目標「週〇回」は設定画面で1つだけ保存（settings または新テーブル）。Pro のみアクセス可能。Free は履歴タブなどに「週次サマリはProで」カード＋Paywall。

### 2.3 文言
- 「今週のサマリ」「前週比」「週〇回トレーニング」等を l10n 化。

---

## Phase 3：PDF レポート

### 3.1 実装
- パッケージ：`pdf` または `printing` で PDF 生成。週次・月次のサマリ内容（日付範囲・回数・ボリューム・種目別サマリ・前週比など）を1〜数ページの PDF に。保存・共有は `path_provider` + `share_plus` 等で対応。

### 3.2 Pro ゲート
- PDF の生成・保存・共有は Pro のみ。設定または週次サマリ画面から「レポートをエクスポート」ボタンで起動。

---

## Phase 4：次の推奨・目標達成バッジ・自動送信

### 4.1 次の推奨
- 種目ごとの直近完了セッションの最大重量・回数等から「次は 〇kg × 〇回」を算出。ワークアウト入力のセット行付近または種目カードに「推奨：〇kg×〇回」と表示。Pro のみ。

### 4.2 目標達成の祝福（強化）
- Phase 1 の SnackBar に加え、種目別進捗画面で「目標達成日」をマークしたり、短いバッジ表示を追加。文言は Phase 1 と同様に自然に。

### 4.3 週次レポート自動送信（任意）
- バックグラウンドで「毎週〇曜 9:00 に先週分の PDF をメール送信」する機能。実装コストが大きいため、Phase 3 完了後に検討。

---

## 実装順序

1. **Phase 1** を完了（DB・Entity・DAO・FeatureGate・目標設定UI・進捗表示・達成祝福）
2. **Phase 2** 週次サマリ画面
3. **Phase 3** PDF レポート
4. **Phase 4** 次の推奨 → 目標達成バッジ → 自動送信（任意）

---

## メッセージ方針（自然で違和感のない表現）

- **目標達成**：事実を簡潔に。「〇〇で目標の〇〇を達成しました。」「Goal achieved on {exercise}.」過度な感嘆符や絵文字は避ける。
- **目標まであと**：「あと〇kg」「あと〇回」など数字だけでも伝わるように。必要なら「目標まであと〇〇」とラベルを付ける。
- **Pro 案内**：「目標管理はProで利用できます」「週次サマリはProでご利用いただけます」など、誘導ではなく説明するトーンにする。
