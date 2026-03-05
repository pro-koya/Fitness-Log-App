既存データの活用イメージ
データ	使えること
トレーニング日時・種目・重量・回数	連続日数・週回数、ボリューム（重量×回数）、種目別の推移
体重	トレンド、月間変化、記録日数
提案1: トレーニング完了時の「一言＋サマリー」画面（おすすめ）
流れ
「記録完了」タップ → 保存処理 → 専用の完了画面（モーダル or 全画面）を表示。
表示内容例
見出し: 「トレーニング記録完了」
サマリー: 今日の種目数・セット数・総ボリューム（重量×回数の合計）など
一言: データに応じて1パターン選んで表示
一言のパターン例（データ連動）
連続記録: 「○日連続で記録できてる。習慣、ついてきてる。」
今週2回目: 「今週2回目。いいペース。」
総ボリュームが前回セッションより増: 「前回よりボリュームアップ。成長してる。」
特に条件なし: 「おつかれさま。また次もコツコツ。」
奇抜寄り
「筋肉から: 今日もありがとう。また来週。」
「記録○日目。数字があなたの証拠になる。」
「プロテインの時間です。（記録は完了してます）」
使うデータ: 今回セッション、過去セッション日付・種目・重量・回数、記録日数など。
提案2: モチベーション通知（プッシュ or アプリ内）
パターン例
「3日連続でトレーニング記録できてる。この調子。」
「今週はまだ記録なし。今日、1セットだけでも記録してみる？」
「先週は○回トレーニング。今週はあと○回で並べる。」
体重を記録している場合: 「今月の体重記録○回。続けてる。」
使うデータ: 直近の記録日リスト（連続日数・週ごと回数）、体重記録日数など。

---

## 実装計画（筋肉からのメッセージ）

### アーキテクチャ方針

- **レイヤー分離**: Repository/DAO → Service → UI
- **単一責任**: メッセージ選定ロジックはService層に集約
- **型安全**: モデルクラスで入出力を明示

### 提案1: トレーニング完了画面

| レイヤー | 担当 | ファイル |
|----------|------|----------|
| DAO | セッション総ボリューム取得、今週回数 | `SetRecordDao`, `WorkoutSessionDao` |
| Service | サマリー算出・メッセージ選定 | `lib/services/muscle_message_service.dart` |
| Model | 完了結果・サマリー | `lib/features/workout_completion/models/` |
| UI | モーダル表示 | `lib/features/workout_completion/` |
| フロー変更 | 記録完了後にモーダル表示 | `workout_input_screen.dart` |

**一言パターン優先順位**（筋肉目線）:
1. 連続記録（2日以上）→ 「○日連続。習慣、ついてきてる。」
2. 今週2回目以上 → 「今週○回目。いいペース。」
3. 総ボリューム増加 → 「前回よりボリュームアップ。成長してる。」
4. デフォルト → 「筋肉から: 今日もありがとう。また次もコツコツ。」

### 提案2: モチベーション通知（アプリ内）

| レイヤー | 担当 | ファイル |
|----------|------|----------|
| Service | ホーム用メッセージ選定 | `muscle_message_service.dart` 拡張 |
| Provider | メッセージ取得 | `lib/features/home/providers/muscle_message_provider.dart` |
| UI | ホーム上のカード | `lib/features/home/widgets/muscle_message_card.dart` |

**表示パターン**:
- 連続記録あり →  streak 文言
- 今週記録なし → 促しメッセージ
- 先週より今週 → 残り○回で並べる
- 体重記録あり → 今月○回の体重記録

### 拡張ポイント（TODO）

- プッシュ通知導入時: `flutter_local_notifications` 連携
- 多言語: `app_ja.arb` / `app_en.arb` に文言追加

---

## 実装計画：バックアップ取り込み時の標準種目優先 & タイマー通知のカスタマイズ

### 1. バックアップ取り込み時の標準種目優先

#### 現状の課題

- JSON/CSV 取り込み時に、バックアップ内の種目をそのまま `exercise_master` に挿入している
- CSV は全種目を `is_custom: 1` で生成
- 標準種目と同じ名前の種目がある場合、カスタムとして扱われ、標準種目の利点（多言語など）が使えない

#### 対応方針

バックアップ復元時に「標準種目リスト」と照合し、名前が一致する種目は標準種目を優先して参照する。

#### レイヤー構成

| レイヤー | 担当 | ファイル |
|----------|------|----------|
| 標準種目リスト | 定義 | `lib/data/constants/standard_exercise_names.dart`（新規） |
| 復元ロジック | 標準優先マッピング | `lib/services/backup_service.dart` の `restore` 変更 |
| CSV パーサー | オプション対応 | `lib/services/backup_csv_parser.dart`（必要なら） |

#### 処理フロー（restore）

1. 標準種目を先に seed して、`name -> id` マップを構築する
2. バックアップの種目ごとに:
   - 標準リストに名前が含まれる（正規化・大文字小文字無視）→ 標準 ID を採用、その種目は挿入しない
   - 含まれない → カスタムとして挿入し、新規 ID をマッピング
3. `backup_exercise_id -> 実際に使う exercise_id` マップを作成
4. `workout_exercises`, `set_records` の `exercise_id` を上記マップで置き換えて挿入
5. `session_id`, `workout_exercise_id` も再採番が必要なため、同様にマッピングして書き換え

#### 標準種目名の扱い

- `DatabaseHelper` の seed と同じ名前を `standard_exercise_names.dart` に定義
- 比較は `trim().toLowerCase()` で正規化
- 旧名・別表記（例: `Pull Up` vs `Pull-Up`）があれば同一とみなすルールを定義

#### 影響範囲

- `BackupService.restore()` の大幅な書き換え
- セッション・ workout_exercises の ID 再採番ロジックの追加
- 既存の JSON/CSV フォーマットとの互換性維持

---

### 2. タイマー終了時のバイブレーション・音のカスタマイズ

#### 現状

- `timer_mini_widget.dart` と `main.dart` で:
  - `HapticFeedback.mediumImpact()` を 3 回
  - `SystemSound.play(SystemSoundType.alert)` でシステム音
- ユーザーによるオフや変更は不可

#### 対応方針

設定画面で以下を選択可能にする:

- **バイブレーション**: オン / オフ
- **音**: なし / アプリ内の音（システム音など） / ユーザー指定ファイル

#### レイヤー構成

| レイヤー | 担当 | ファイル |
|----------|------|----------|
| 設定保存 | DB・モデル | `SettingsEntity`, `SettingsDao`, DB マイグレーション |
| 通知再生 | バイブ・音再生 | `lib/services/timer_notification_service.dart`（新規） |
| UI | 設定画面 | 設定画面にタイマー設定セクションを追加 |
| 呼び出し | タイマー完了時 | `timer_mini_widget.dart`, `main.dart` |

#### 設定項目（案）

```dart
// 新規フィールド（JSON または専用カラム）
timerVibrationEnabled: bool    // デフォルト true
timerSoundMode: 'none' | 'system' | 'custom'
timerSoundPath: String?        // custom 時のファイルパス
```

#### バイブレーション実装

- オフ: `HapticFeedback` / `vibration` を呼ばない
- オン: 現状どおり `HapticFeedback.mediumImpact()` 3 回  
  （強さを変えたい場合は `vibration` パッケージの検討）

#### 音の実装

- なし: 音を再生しない
- システム: 既存の `SystemSound.play(SystemSoundType.alert)`
- カスタム:
  - 設定画面で `file_picker` により音声ファイルを選択
  - パスを SharedPreferences または settings に保存
  - タイマー終了時に `audioplayers` の `DeviceFileSource` で再生

#### 依存関係

- `audioplayers` を pubspec.yaml に追加
- カスタム音利用時は `path_provider` で永続パスの扱いを検討

#### DB マイグレーション

- `settings` テーブルに `timer_settings` (TEXT, JSON) を追加、または
- `timer_vibration_enabled`, `timer_sound_mode`, `timer_sound_path` を個別カラムとして追加  
※ 既存の `theme_settings` と同様に JSON でも可

#### 拡張案

- アプリ内に複数のプリセット音を用意し、その中から選択
- `vibration` パッケージでパターン（強さ・長さ）を選択可能にする

---

### 実装順序（推奨）

1. **標準種目優先（バックアップ）**  
   - 標準種目リスト定義  
   - `BackupService.restore` の改修  
   - JSON/CSV 両方で動作確認  

2. **タイマー通知カスタマイズ**  
   - DB・Settings の拡張  
   - `TimerNotificationService` の作成  
   - 設定 UI  
   - 既存のタイマー完了処理を差し替え  
   - カスタム音の選択・再生の動作確認