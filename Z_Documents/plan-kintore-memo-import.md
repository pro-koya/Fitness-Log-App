# 筋トレMemo（Realm）インポート機能 実装計画

## 1. 概要

筋トレMemo（iOS）の default.realm を Liftly に取り込む機能。read-only で開き、JSON 中間形式を経由せず直接 Liftly DB に変換・保存する。

## 2. Realm スキーマ（推定）

※ Realm Studio で確認した actual schema に合わせて models を調整すること。

| Realm class | 用途 | 想定フィールド |
|-------------|------|----------------|
| class_eventLog | トレーニングログ | date, eventId, weightKg, weightLbs, reps, setNum, memo, eventMaster(link) |
| class_eventMaster | 種目マスタ | id, name, partsId, partsMaster(link) |
| class_partsMaster | 部位マスタ | id, name |

## 3. 変換ルール

- eventLog を date + exerciseName でグルーピング → workout_sessions, workout_exercises, set_records
- 重量: weightKg 優先、なければ weightLbs を kg 換算（× 0.45359237）
- 重複: (date, exerciseName, setIndex, weight, reps) のハッシュで判定

## 4. 拡張ポイント

- class_rmMax, class_weightHistory は将来対応用に残す
