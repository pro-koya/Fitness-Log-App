# 実装計画: 自重トレーニング・時間管理・UI改善

## 概要
以下の4つの機能改善を実装するための計画書

1. **0kg対応**: 自重トレーニングで0kgを登録可能にする
2. **時間管理**: プランク等の種目でrepsではなくminutes(時間)で管理できるようにする
3. **カスタム種目ダイアログの幅**: 横幅を広げて使いやすくする
4. **キーボード非表示**: 入力欄以外をタップした際にキーボードを閉じる

---

## 1. 0kg対応（自重トレーニング）

### 現状の問題
- `WorkoutExerciseModel.isValid`で`weight! > 0`を要求している
- DAOのクエリで`weight_kg > 0`条件がある

### 修正対象ファイル

#### 1.1 lib/features/workout_input/models/workout_exercise_model.dart
**変更箇所**: 98行目付近
```dart
// Before
bool get isValid => weight != null && weight! > 0 && reps != null && reps! > 0;

// After
bool get isValid => weight != null && weight! >= 0 && reps != null && reps! > 0;
```

#### 1.2 lib/data/dao/set_record_dao.dart
**変更箇所1**: 293-294行目付近（getTopWeightForExercise）
```dart
// Before
WHERE we.exercise_id = ? AND sr.weight_kg > 0

// After
WHERE we.exercise_id = ? AND sr.weight_kg >= 0
```

**変更箇所2**: 319-320行目付近（getTopWeightsForExerciseProgress）
```dart
// Before
WHERE we.exercise_id = ? AND sr.weight_kg > 0

// After
WHERE we.exercise_id = ? AND sr.weight_kg >= 0
```

### 影響範囲
- ワークアウト入力画面での保存バリデーション
- 種目別進捗グラフのデータ取得
- 既存データには影響なし

---

## 2. 時間管理（minutes対応）

### 現状の問題
- すべての種目がreps（回数）のみで管理されている
- プランク等の時間ベースの種目に対応できていない

### 設計方針
- `exercise_master`テーブルに`record_type`カラムを追加（'reps' or 'time'）
- `set_records`テーブルに`duration_seconds`カラムを追加
- 既存データはすべて'reps'タイプとしてマイグレーション

### 修正対象ファイル

#### 2.1 lib/data/database/database_helper.dart
**変更内容**: DBバージョンアップ＋マイグレーション追加
```dart
// バージョン: 1 → 2

// マイグレーション処理
if (oldVersion < 2) {
  // exercise_masterにrecord_typeカラム追加
  await db.execute('''
    ALTER TABLE exercise_master ADD COLUMN record_type TEXT NOT NULL DEFAULT 'reps'
  ''');

  // set_recordsにduration_secondsカラム追加
  await db.execute('''
    ALTER TABLE set_records ADD COLUMN duration_seconds INTEGER
  ''');
}
```

#### 2.2 lib/data/entities/exercise_master_entity.dart
**変更内容**: recordTypeフィールド追加
```dart
class ExerciseMasterEntity {
  // 既存フィールド...
  final String recordType; // 'reps' or 'time'

  // fromMap/toMapも更新
}
```

#### 2.3 lib/data/entities/set_record_entity.dart
**変更内容**: durationSecondsフィールド追加
```dart
class SetRecordEntity {
  // 既存フィールド...
  final int? durationSeconds;

  // fromMap/toMapも更新
}
```

#### 2.4 lib/features/workout_input/models/workout_exercise_model.dart
**変更内容**:
- recordTypeフィールド追加
- isValidロジック更新（reps or durationSeconds）
```dart
final String recordType; // 'reps' or 'time'
final int? durationSeconds;

bool get isValid {
  if (weight == null || weight! < 0) return false;
  if (recordType == 'time') {
    return durationSeconds != null && durationSeconds! > 0;
  } else {
    return reps != null && reps! > 0;
  }
}
```

#### 2.5 lib/features/workout_input/widgets/set_row_widget.dart
**変更内容**:
- recordTypeに応じてreps/time入力を切り替え
- 時間入力用のUI追加（分:秒 or 秒数入力）

```dart
// repsフィールドの代わりに条件分岐
if (recordType == 'time')
  _buildDurationInput()
else
  _buildRepsInput()
```

#### 2.6 lib/features/workout_input/widgets/exercise_selector_modal.dart
**変更内容**: カスタム種目追加時にrecordType選択UI追加
```dart
// カスタム種目追加ダイアログに追加
SegmentedButton<String>(
  segments: [
    ButtonSegment(value: 'reps', label: Text('回数')),
    ButtonSegment(value: 'time', label: Text('時間')),
  ],
  selected: {selectedRecordType},
  onSelectionChanged: (value) => setState(() => selectedRecordType = value.first),
)
```

#### 2.7 lib/data/dao/exercise_master_dao.dart
**変更内容**:
- insertExerciseにrecordTypeパラメータ追加
- getExerciseByIdでrecordType取得

#### 2.8 lib/data/dao/set_record_dao.dart
**変更内容**:
- insertSetRecordにdurationSeconds対応
- getSetRecordsでdurationSeconds取得

### 標準種目のrecordType設定
- 以下の種目は初期データとして`record_type = 'time'`に設定:
  - Plank (プランク)
  - Side Plank (サイドプランク)
  - Wall Sit (ウォールシット)
  - Dead Hang (デッドハング)

（必要に応じてマイグレーションで更新）

### 影響範囲
- ワークアウト入力画面
- 種目選択モーダル
- 履歴表示（reps表示 → reps or 時間表示）
- 進捗グラフ（時間種目の場合は最長時間を表示）

---

## 3. カスタム種目ダイアログの幅拡大

### 現状の問題
- AlertDialogのデフォルト幅が狭い

### 修正対象ファイル

#### 3.1 lib/features/workout_input/widgets/exercise_selector_modal.dart
**変更箇所**: _showAddCustomExerciseDialogメソッド内
```dart
// Before
return AlertDialog(...)

// After
return Dialog(
  child: ConstrainedBox(
    constraints: BoxConstraints(
      maxWidth: 400, // または MediaQuery.of(context).size.width * 0.9
      minWidth: 300,
    ),
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        // ...既存の内容
      ),
    ),
  ),
);
```

---

## 4. キーボード非表示（タップで閉じる）

### 現状の問題
- 数値入力パッド表示中に、パッド以外をタップしてもキーボードが閉じない

### 修正対象ファイル

#### 4.1 lib/features/workout_input/workout_input_screen.dart
**変更内容**: GestureDetectorでラップしてunfocus
```dart
@override
Widget build(BuildContext context) {
  return GestureDetector(
    onTap: () {
      // キーボードを閉じる
      FocusScope.of(context).unfocus();
    },
    child: Scaffold(
      // 既存の内容
    ),
  );
}
```

#### 4.2 lib/features/workout_input/widgets/set_row_widget.dart
**変更内容**: TextFieldのonTapOutside対応（Flutter 3.7+）
```dart
TextField(
  // 既存のプロパティ...
  onTapOutside: (event) {
    FocusScope.of(context).unfocus();
  },
)
```

---

## 実装順序

### Phase 1: 基盤（DB変更）
1. `database_helper.dart` - マイグレーション追加
2. `exercise_master_entity.dart` - recordType追加
3. `set_record_entity.dart` - durationSeconds追加

### Phase 2: 0kg対応（最小変更）
4. `workout_exercise_model.dart` - isValid修正
5. `set_record_dao.dart` - クエリ条件修正

### Phase 3: 時間管理
6. `exercise_master_dao.dart` - recordType対応
7. `set_record_dao.dart` - durationSeconds対応
8. `workout_exercise_model.dart` - 時間管理フィールド追加
9. `set_row_widget.dart` - 時間入力UI
10. `exercise_selector_modal.dart` - recordType選択UI

### Phase 4: UI改善
11. `exercise_selector_modal.dart` - ダイアログ幅拡大
12. `workout_input_screen.dart` - キーボード非表示
13. `set_row_widget.dart` - onTapOutside追加

### Phase 5: 表示対応
14. 履歴表示の時間対応
15. 進捗グラフの時間対応

---

## テスト項目

### 0kg対応
- [ ] 0kgでセット保存できること
- [ ] 0kgのセットが進捗グラフに表示されること
- [ ] 既存データに影響がないこと

### 時間管理
- [ ] カスタム種目で「時間」タイプを選択できること
- [ ] 時間種目で分:秒入力ができること
- [ ] 時間種目の履歴が正しく表示されること
- [ ] 時間種目の進捗グラフが最長時間で表示されること

### UI改善
- [ ] カスタム種目ダイアログが広くなっていること
- [ ] 入力欄以外をタップでキーボードが閉じること
- [ ] 日本語入力時に問題がないこと

---

## 備考
- DBマイグレーションは後方互換性を維持
- 既存の標準種目は基本的に'reps'タイプ
- 時間種目の追加は今後のマスターデータ更新で対応可能
