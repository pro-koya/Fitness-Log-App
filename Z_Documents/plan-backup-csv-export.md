# バックアップ CSV 形式エクスポート 実装計画

## 1. 要件

- バックアップ取得時に **JSON** または **CSV** をユーザーが選択可能
- JSON: 既存の復元用データ（アプリでの復元に使用）
- CSV: ユーザーが Excel / Google スプレッドシート等で分析しやすい形式

## 2. 設計方針

### 2.1 CSV の用途

- **復元には使用しない**（復元は JSON のまま）
- 分析用のフラットな形式でエクスポート
- 1 行 = 1 セット記録（種目・日付・重量・回数等を含む）

### 2.2 CSV の構造

| 列 | 説明 | 元データ |
|----|------|----------|
| session_date | セッション日付 (yyyy-MM-dd) | workout_sessions.completed_at |
| session_started_at | セッション開始日時 | workout_sessions.started_at |
| exercise_name | 種目名 | exercise_master.name |
| body_part | 部位 | exercise_master.body_part |
| set_number | セット番号 | set_records.set_number |
| weight_kg | 重量 (kg) | set_records.weight_kg |
| weight_lb | 重量 (lb) | set_records.weight_lb |
| reps | 回数 | set_records.reps |
| duration_seconds | 持続時間(秒) | set_records.duration_seconds |
| distance_meters | 距離(m) | set_records.distance_meters |
| memo | メモ | workout_exercises.memo |

- ヘッダー行あり
- カンマ・改行を含むフィールドはダブルクォートでエスケープ
- 空データは空文字

### 2.3 体重記録

- 別 CSV `body_weight.csv` として同時エクスポートは複雑になるため、今回は **ワークアウトセットのみ** を CSV 出力
- 必要に応じて将来的に体重用 CSV を追加可能

## 3. 実装計画

### Phase A: BackupFormat enum と BackupService 拡張

| ファイル | 内容 |
|----------|------|
| `lib/services/backup_service.dart` | `BackupFormat` enum 追加、`exportBackup(format)` で分岐、`_toCsvString()` 追加 |
| `lib/services/backup_csv_converter.dart` | 新規。BackupData → CSV 文字列変換（責務分離） |

### Phase B: BackupScreen UI 変更

| ファイル | 内容 |
|----------|------|
| `lib/features/settings/screens/backup_screen.dart` | フォーマット選択 UI（SegmentedButton または Radio）、選択値を `exportBackup` に渡す |

### Phase C: l10n

| キー | 日本語 | 英語 |
|------|--------|------|
| backupFormatLabel | バックアップ形式 | Backup format |
| backupFormatJson | JSON（アプリで復元可能） | JSON (for restore) |
| backupFormatCsv | CSV（分析・表計算用） | CSV (for analysis) |

## 4. ディレクトリ構成（変更後）

```
lib/
  services/
    backup_service.dart          # exportBackup(format) 追加
    backup_csv_converter.dart    # 新規
  features/settings/screens/
    backup_screen.dart           # フォーマット選択 UI
```

## 5. エラーハンドリング

- CSV 変換時: 空データは空行なしでヘッダーのみ
- ファイル保存: 既存の FilePicker エラーハンドリングを流用

## 6. 制約・注意（更新）

- CSV からの復元も対応（v2 実装済み）
- フォーマット選択 UI で「JSON（アプリで復元可能）」「CSV（分析・表計算用）」と案内

## 7. 実装サマリ（完了）

| ファイル | 役割 |
|----------|------|
| `lib/services/backup_csv_converter.dart` | BackupData → CSV 変換（エクスポート） |
| `lib/services/backup_csv_parser.dart` | CSV → BackupData 変換（インポート） |
| `lib/services/backup_exceptions.dart` | BackupParseException, BackupVersionException |
| `lib/services/backup_service.dart` | BackupFormat enum、exportBackup(format)、pickAndParseBackup で .json/.csv 両対応 |
| `lib/features/settings/screens/backup_screen.dart` | SegmentedButton で形式選択 |
| `lib/l10n/app_ja.arb`, `app_en.arb` | backupFormatLabel, backupFormatJson, backupFormatCsv |
