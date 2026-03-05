# 筋トレMemo（Realm）取り込み機能 — まとめ

## 1. 指示（要望）

- **筋トレMemo（iOS）の `default.realm` を Liftly に取り込む**
- **read-only で開き、JSON 中間形式を経由せず直接 Liftly DB に変換・保存する**  
  （`Z_Documents/plan-kintore-memo-import.md` に記載）

---

## 2. 計画（設計方針）

- **Realm スキーマ（推定）**  
  - `EventLog`（トレーニングログ: date, weightKg, weightLbs, reps, setNum, memo, eventMaster）  
  - `EventMaster`（種目: id, name, partsId, partsMaster）  
  - `PartsMaster`（部位: id, name）  
  - ※実際は Realm Studio で確認したスキーマに合わせて調整する前提
- **変換ルール**  
  - `EventLog` を「日付 + 種目名」でグルーピング → `workout_sessions` / `workout_exercises` / `set_records` に変換  
  - 重量: `weightKg` 優先、なければ `weightLbs` を kg 換算（× 0.45359237）  
  - 重複: (date, exerciseName, setIndex, weight, reps) のハッシュで判定し、`import_source_hashes` で除外
- **拡張**  
  - `class_rmMax`, `class_weightHistory` は将来対応用に残す

---

## 3. 実装内容（実施したこと）

| 項目 | 内容 |
|------|------|
| **ファイル選択** | `FilePicker` で `FileType.any` + `withData: true`。選んだ .realm を一時ファイルにコピー（iOS で path が使えない場合に対応） |
| **Realm 読み取り** | 一時ファイルを `Configuration.local(..., isReadOnly: true)` で開き、`EventLog` / `EventMaster` / `PartsMaster` を取得 |
| **モデル** | `kintore_memo_models.dart` + `*.realm.dart`（`@RealmModel()`、`dart run realm generate` で生成） |
| **変換** | `ImportService._convertToLiftlyWorkouts` で (日付, 種目) ごとにグルーピング → `LiftlyWorkoutImport` のリストに変換 |
| **保存** | `WorkoutRepository.saveImportedWorkouts`（実装は `SqliteWorkoutRepository`）。重複は `import_source_hashes` でスキップ |
| **DB** | マイグレーション v11 で `import_source_hashes` テーブルを追加 |
| **UI** | `ImportKintoreMemoScreen`（ファイル選択 → 解析 → プレビュー → 実行）。エラー時は暗号化・スキーマ不一致・無効ファイルを分類して表示 |
| **多言語** | `importKintoreMemoTitle` / `importKintoreMemoDescription` やエラー文言を l10n に追加 |

---

## 4. 「断念」について（コードから分かること）

- **リポジトリ内には「断念した理由」を説明するドキュメントはない。**
- 実装は存在するが、**設定やバックアップ画面から `ImportKintoreMemoScreen` へ遷移するルート（導線）がコードベースにない。**  
  → ユーザーがたどり着けない＝事実上「出していない」状態。
- 断念理由として**推測できるもの**:
  - 実際の筋トレMemo の Realm スキーマが計画と異なり開けなかった／クラッシュした
  - Realm のバージョン差や read-only での不具合
  - 配布時の Realm dSYM 問題など、Realm 依存のコストを避けた
  - 優先度を下げ、バックアップ（JSON/CSV）や他機能に集中した

「なぜ断念したか」を正確に残すには、当時の判断（スキーマが合わなかった、エラーが多かった、など）を覚えている範囲で追記するとよい。

---

## 5. 要点の一覧

- **指示**: 筋トレMemo の `default.realm` を read-only で開き、中間 JSON なしで直接 Liftly DB に取り込む。
- **計画**: 推定スキーマ（EventLog / EventMaster / PartsMaster）と変換ルール（日付+種目グルーピング、重量換算、ハッシュ重複排除）を定義。
- **実装**: ファイル選択 → 一時コピー → Realm で読み取り → 変換 → `import_source_hashes` 付きで SQLite に保存するまで実装済み。専用画面・l10n・DB マイグレーションもあり。
- **断念理由**: コード・ドキュメントには明記なし。画面への導線が未接続で「未リリース」状態。理由は上記のいずれか（または複合）の可能性。
