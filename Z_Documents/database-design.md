# ローカルDB（SQLite）テーブル設計

## 設計方針

### 前提
- **ローカル完結**（同期・サーバーなし）
- **マイグレーション前提**（後で変更可能）
- **パフォーマンス重視**（前回記録参照が高速）
- **過剰な正規化はしない**（必要に応じて非正規化）

### パフォーマンス最適化のポイント
- **前回記録参照を高速化**：`set_records`に`session_id`と`exercise_id`を非正規化
- **適切なインデックス配置**：頻繁に使うクエリに対してインデックスを設定
- **CASCADE DELETE**：親レコード削除時に子レコードも自動削除

---

## テーブル一覧

1. `settings` - ユーザー設定
2. `exercise_master` - 種目マスタ（標準種目 + ユーザー追加種目）
3. `workout_sessions` - トレーニングセッション
4. `workout_exercises` - セッション内の種目
5. `set_records` - セット記録

---

## 1. settings（ユーザー設定）

### 目的
- 言語・単位の設定を保存
- **シングルレコード**（1行のみ、`id = 1`固定）

### テーブル定義

| カラム名 | 型 | 制約 | 用途 | インデックス |
|---------|-----|------|------|-------------|
| `id` | INTEGER | PRIMARY KEY | レコードID（常に1） | - |
| `language` | TEXT | NOT NULL DEFAULT 'en' | 言語（'en' or 'ja'） | - |
| `unit` | TEXT | NOT NULL DEFAULT 'kg' | 単位（'kg' or 'lb'） | - |
| `created_at` | INTEGER | NOT NULL | 作成日時（UNIX timestamp） | - |
| `updated_at` | INTEGER | NOT NULL | 更新日時（UNIX timestamp） | - |

### SQL（テーブル作成）
```sql
CREATE TABLE settings (
  id INTEGER PRIMARY KEY CHECK(id = 1),
  language TEXT NOT NULL DEFAULT 'en',
  unit TEXT NOT NULL DEFAULT 'kg',
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
);
```

### 初期データ
```sql
INSERT INTO settings (id, language, unit, created_at, updated_at)
VALUES (1, 'en', 'kg', strftime('%s', 'now'), strftime('%s', 'now'));
```

### なぜこの設計か
- **シングルレコード**：ユーザーは1人なので、設定も1レコードのみ
- **DEFAULT値**：初回起動時にデフォルト値で即開始可能

---

## 2. exercise_master（種目マスタ）

### 目的
- 標準種目とユーザー追加種目を管理
- 種目選択時に参照

### テーブル定義

| カラム名 | 型 | 制約 | 用途 | インデックス |
|---------|-----|------|------|-------------|
| `id` | INTEGER | PRIMARY KEY AUTOINCREMENT | 種目ID | - |
| `name` | TEXT | NOT NULL | 種目名（例：ベンチプレス） | ✓（検索用） |
| `body_part` | TEXT | - | 部位（例：chest, back, legs） | - |
| `is_custom` | INTEGER | NOT NULL DEFAULT 0 | 0: 標準種目、1: ユーザー追加種目 | - |
| `created_at` | INTEGER | NOT NULL | 作成日時（UNIX timestamp） | - |
| `updated_at` | INTEGER | NOT NULL | 更新日時（UNIX timestamp） | - |

### SQL（テーブル作成）
```sql
CREATE TABLE exercise_master (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  body_part TEXT,
  is_custom INTEGER NOT NULL DEFAULT 0,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
);

CREATE INDEX idx_exercise_master_name ON exercise_master(name);
```

### 初期データ（標準種目の例）
```sql
INSERT INTO exercise_master (name, body_part, is_custom, created_at, updated_at)
VALUES
  ('Bench Press', 'chest', 0, strftime('%s', 'now'), strftime('%s', 'now')),
  ('Squat', 'legs', 0, strftime('%s', 'now'), strftime('%s', 'now')),
  ('Deadlift', 'back', 0, strftime('%s', 'now'), strftime('%s', 'now'));
```

### なぜこの設計か
- **is_custom**：標準種目とユーザー追加種目を区別（将来的にデフォルト種目の更新に対応）
- **nameにインデックス**：種目検索（曖昧検索はP1）を高速化
- **body_partは任意**：部位で絞り込む場合に使用（P1で検討）

---

## 3. workout_sessions（トレーニングセッション）

### 目的
- 1回のトレーニングを管理
- 記録中（in_progress）と完了（completed）を区別

### テーブル定義

| カラム名 | 型 | 制約 | 用途 | インデックス |
|---------|-----|------|------|-------------|
| `id` | INTEGER | PRIMARY KEY AUTOINCREMENT | セッションID | - |
| `status` | TEXT | NOT NULL | 状態（'in_progress' or 'completed'） | ✓（前回記録検索用） |
| `started_at` | INTEGER | NOT NULL | 開始日時（UNIX timestamp） | - |
| `completed_at` | INTEGER | - | 完了日時（UNIX timestamp、completedの場合のみ） | ✓（前回記録検索用） |
| `created_at` | INTEGER | NOT NULL | 作成日時（UNIX timestamp） | - |
| `updated_at` | INTEGER | NOT NULL | 更新日時（UNIX timestamp） | - |

### SQL（テーブル作成）
```sql
CREATE TABLE workout_sessions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  status TEXT NOT NULL CHECK(status IN ('in_progress', 'completed')),
  started_at INTEGER NOT NULL,
  completed_at INTEGER,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
);

CREATE INDEX idx_workout_sessions_status_completed_at
  ON workout_sessions(status, completed_at);
```

### なぜこの設計か
- **status**：記録中と完了を区別（前回記録は`completed`のみ参照）
- **(status, completed_at)にインデックス**：前回記録検索を高速化
  - クエリ例：`WHERE status = 'completed' AND completed_at < ? ORDER BY completed_at DESC`
- **completed_at**：完了日時でソート・フィルタするために必須

---

## 4. workout_exercises（セッション内の種目）

### 目的
- 1セッション内の種目を管理
- セッションと種目の関連を保持

### テーブル定義

| カラム名 | 型 | 制約 | 用途 | インデックス |
|---------|-----|------|------|-------------|
| `id` | INTEGER | PRIMARY KEY AUTOINCREMENT | レコードID | - |
| `session_id` | INTEGER | NOT NULL, FOREIGN KEY | セッションID（workout_sessions.id） | ✓（セッション内表示用） |
| `exercise_id` | INTEGER | NOT NULL, FOREIGN KEY | 種目ID（exercise_master.id） | ✓（前回記録検索用） |
| `order_index` | INTEGER | NOT NULL | セッション内の表示順（0, 1, 2, ...） | ✓（セッション内表示用） |
| `created_at` | INTEGER | NOT NULL | 作成日時（UNIX timestamp） | - |
| `updated_at` | INTEGER | NOT NULL | 更新日時（UNIX timestamp） | - |

### SQL（テーブル作成）
```sql
CREATE TABLE workout_exercises (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  session_id INTEGER NOT NULL,
  exercise_id INTEGER NOT NULL,
  order_index INTEGER NOT NULL,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  FOREIGN KEY (session_id) REFERENCES workout_sessions(id) ON DELETE CASCADE,
  FOREIGN KEY (exercise_id) REFERENCES exercise_master(id)
);

CREATE INDEX idx_workout_exercises_session_id_order
  ON workout_exercises(session_id, order_index);

CREATE INDEX idx_workout_exercises_exercise_id
  ON workout_exercises(exercise_id);
```

### なぜこの設計か
- **session_id**：セッションとの関連（CASCADE DELETEでセッション削除時に自動削除）
- **exercise_id**：種目マスタとの関連
- **order_index**：セッション内での種目の表示順を保持
- **(session_id, order_index)にインデックス**：セッション内の種目を表示順でソート
- **exercise_idにインデックス**：前回記録検索時に使用

---

## 5. set_records（セット記録）

### 目的
- セット単位の記録（重量・回数）を管理
- **前回記録参照を高速化**するため、`session_id`と`exercise_id`を非正規化

### テーブル定義

| カラム名 | 型 | 制約 | 用途 | インデックス |
|---------|-----|------|------|-------------|
| `id` | INTEGER | PRIMARY KEY AUTOINCREMENT | レコードID | - |
| `workout_exercise_id` | INTEGER | NOT NULL, FOREIGN KEY | 種目レコードID（workout_exercises.id） | ✓（セット表示用） |
| `session_id` | INTEGER | NOT NULL | セッションID（非正規化、前回記録検索用） | ✓（前回記録検索用） |
| `exercise_id` | INTEGER | NOT NULL | 種目ID（非正規化、前回記録検索用） | ✓（前回記録検索用） |
| `set_number` | INTEGER | NOT NULL | セット番号（1, 2, 3, ...） | ✓（セット表示用） |
| `weight` | REAL | NOT NULL | 重量 | - |
| `reps` | INTEGER | NOT NULL | 回数 | - |
| `unit` | TEXT | NOT NULL | 単位（'kg' or 'lb'） | - |
| `created_at` | INTEGER | NOT NULL | 作成日時（UNIX timestamp） | - |
| `updated_at` | INTEGER | NOT NULL | 更新日時（UNIX timestamp） | - |

### SQL（テーブル作成）
```sql
CREATE TABLE set_records (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  workout_exercise_id INTEGER NOT NULL,
  session_id INTEGER NOT NULL,
  exercise_id INTEGER NOT NULL,
  set_number INTEGER NOT NULL,
  weight REAL NOT NULL,
  reps INTEGER NOT NULL,
  unit TEXT NOT NULL CHECK(unit IN ('kg', 'lb')),
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  FOREIGN KEY (workout_exercise_id) REFERENCES workout_exercises(id) ON DELETE CASCADE
);

CREATE INDEX idx_set_records_workout_exercise_id_set_number
  ON set_records(workout_exercise_id, set_number);

CREATE INDEX idx_set_records_exercise_id_session_id
  ON set_records(exercise_id, session_id);
```

### なぜこの設計か
- **非正規化（session_id, exercise_id）**：前回記録検索を高速化
  - 正規化すると`workout_exercises`と`workout_sessions`をJOINする必要があり、パフォーマンスが低下
  - MVPでは「パフォーマンス重視」「過剰な正規化はしない」という前提に従う
- **(workout_exercise_id, set_number)にインデックス**：セット表示順でソート
- **(exercise_id, session_id)にインデックス**：前回記録検索を高速化
- **unit**：セット記録時の単位を保持（kg/lb切替時に正しく表示するため）

---

## 前回記録検索のクエリ例

### 前回記録を取得（同一種目の直近completedセッション）

```sql
-- 1. 前回のセッションIDを取得
SELECT ws.id AS prev_session_id
FROM workout_sessions ws
JOIN workout_exercises we ON ws.id = we.session_id
WHERE we.exercise_id = ?  -- 対象種目ID
  AND ws.status = 'completed'
  AND ws.completed_at < ?  -- 現在のセッション開始時刻より前
ORDER BY ws.completed_at DESC
LIMIT 1;

-- 2. 前回のセット記録を取得
SELECT *
FROM set_records
WHERE exercise_id = ?  -- 対象種目ID
  AND session_id = ?   -- 前回のセッションID
ORDER BY set_number ASC;
```

### 非正規化により高速化されたクエリ

```sql
-- 前回のセット記録を1回のクエリで取得
SELECT sr.*
FROM set_records sr
JOIN workout_sessions ws ON sr.session_id = ws.id
WHERE sr.exercise_id = ?  -- 対象種目ID
  AND ws.status = 'completed'
  AND ws.completed_at < ?  -- 現在のセッション開始時刻より前
ORDER BY ws.completed_at DESC, sr.set_number ASC;
```

**インデックスが効く**：
- `workout_sessions(status, completed_at)`
- `set_records(exercise_id, session_id)`

**非正規化のメリット**：
- JOINが1回で済む（`workout_exercises`を経由しない）
- クエリがシンプルで高速

---

## ER図（関連図）

```
settings (1レコードのみ)
  └─ language, unit

exercise_master (種目マスタ)
  └─ name, body_part, is_custom

workout_sessions (セッション)
  ├─ status, started_at, completed_at
  └─ 1:N ─→ workout_exercises (セッション内の種目)
              ├─ exercise_id (FK → exercise_master)
              ├─ order_index
              └─ 1:N ─→ set_records (セット記録)
                        ├─ weight, reps, unit
                        ├─ session_id (非正規化)
                        └─ exercise_id (非正規化)
```

---

## マイグレーション戦略

### 前提
- **マイグレーション前提**（後で変更可能）
- Flutterでは`sqflite_migration`または`drift`（旧Moor）を使用

### 初期マイグレーション（v1）
1. 全テーブルを作成
2. 初期データ挿入（settings, exercise_master）

### 将来のマイグレーション例
- v2：カラム追加（例：`workout_sessions.notes`）
- v3：インデックス追加（例：パフォーマンス改善）
- v4：新テーブル追加（例：P1機能の`workout_history_calendar`）

### マイグレーションコード例（Dart/sqflite）
```dart
// マイグレーション処理
Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
  if (oldVersion < 2) {
    // v1 → v2: notes カラムを追加
    await db.execute('ALTER TABLE workout_sessions ADD COLUMN notes TEXT');
  }
  // 他のバージョンアップ処理...
}
```

---

## パフォーマンス最適化のまとめ

### 1. 前回記録検索を高速化
- **非正規化**：`set_records`に`session_id`と`exercise_id`を追加
- **インデックス**：
  - `workout_sessions(status, completed_at)`
  - `set_records(exercise_id, session_id)`

### 2. セット表示を高速化
- **インデックス**：
  - `set_records(workout_exercise_id, set_number)`
  - `workout_exercises(session_id, order_index)`

### 3. 種目検索を高速化
- **インデックス**：`exercise_master(name)`

### 4. CASCADE DELETE
- セッション削除時に関連する種目・セット記録も自動削除
- データ整合性を保つ

---

## 次のステップ

この設計を基に、以下を実装：
1. **Flutter/Dartでのデータモデル定義**（Entity/Model）
2. **DAOパターンでのDB操作**（Create/Read/Update/Delete）
3. **マイグレーション実装**（`sqflite`または`drift`）
4. **前回記録取得ロジック**（クエリの実装とテスト）
5. **単位変換ロジック**（kg ↔ lb）

実装可能な粒度で設計されており、次のステップへ進める準備が整いました。
