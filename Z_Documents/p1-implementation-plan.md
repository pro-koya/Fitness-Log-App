# P1実装計画書（高クオリティ実装）

---

## 目次

1. [P1の目的と位置づけ](#1-p1の目的と位置づけ)
2. [P1要件の整理](#2-p1要件の整理)
3. [実装優先順位の決定](#3-実装優先順位の決定)
4. [各機能の詳細設計](#4-各機能の詳細設計)
5. [技術的考慮事項](#5-技術的考慮事項)
6. [データベース変更](#6-データベース変更)
7. [実装順序](#7-実装順序)
8. [受け入れ基準](#8-受け入れ基準)
9. [追加提案機能](#9-追加提案機能)

---

## 1. P1の目的と位置づけ

### P1とは
**P1（Should）：あると便利だが、無くても100ユーザーは獲得できる**

### P1の役割
- **継続動機の強化**：成長実感を提供し、ユーザーの継続率を高める
- **振り返り体験の充実**：過去の記録を簡単に振り返れるようにする
- **入力体験の最適化**：P0で実現した爆速入力をさらに快適にする
- **改善基盤の構築**：データに基づいた改善を可能にする

### P0との違い
- **P0**：トレ中に使う理由を作る（記録入力、前回参照、タイマー）
- **P1**：継続して使う理由を作る（成長実感、振り返り、入力補助）

### 成功条件
- D7継続率が20%→30%に向上
- 週2回以上記録するユーザーが10%→15%に向上
- ユーザーから「成長が見える」「使いやすい」のフィードバックが得られる

---

## 2. P1要件の整理

### 2.1 継続動機（成長実感）

#### 今月のトレーニング回数表示
- **要件**: Home Screenに今月のワークアウト回数を表示
- **表示例**: 「今月 8回」
- **計算ロジック**: 当月（ローカルタイムゾーン）のcompletedセッション数

#### トレーニング継続日数表示
- **要件**: Home Screenに継続日数を表示
- **表示例**: 「継続 12日」
- **計算ロジック**: 最新のワークアウトから逆算し、連続して記録がある日数
  - 連続判定：前回ワークアウトから2日以内に次のワークアウトがあれば継続とみなす
  - 途切れた場合：1日からカウントリセット

#### 種目別グラフ（最低1指標：例トップ重量、直近3ヶ月）
- **実装状況**: ✅ 既に実装済み（Exercise Progress Screen）
- **確認事項**: 直近3ヶ月のデータ表示が正しく機能しているか確認

---

### 2.2 振り返り体験

#### カレンダー履歴（月表示）
- **要件**: 月間カレンダーでワークアウト実施日を可視化
- **UI**:
  - カレンダー形式（7列×4-6行）
  - ワークアウト実施日にマーカー表示（例：青丸、緑チェック）
  - 前月/次月ボタンで月切替
- **導線**: Home Screenにカレンダーアイコンを追加 → 新規History Screen

#### 履歴の日付タップ→ポップアップサマリ
- **要件**: カレンダーの日付をタップすると、その日のワークアウトサマリをポップアップ表示
- **サマリ内容**:
  - 日付・時刻
  - トレーニング時間
  - 実施種目数
  - 総セット数
- **操作**: サマリをタップすると詳細画面（Workout Detail Screen）へ遷移

#### その日の記録詳細画面（種目一覧・セット一覧）
- **実装状況**: ✅ 既に実装済み（Workout Detail Screen）
- **確認事項**: サマリからの遷移がスムーズか確認

---

### 2.3 入力補助

#### 種目の曖昧検索（部分一致）
- **要件**: Workout Input Screenの種目選択時、部分一致検索を可能にする
- **実装**:
  - 検索ボックスにテキスト入力
  - 種目名（日本語/英語）で部分一致検索
  - 検索結果をリアルタイム表示
- **UX改善**: 種目が多い場合でも素早く目的の種目を見つけられる

#### 自由入力種目の候補化（ユーザー辞書）
- **要件**: ユーザーが自由入力した種目を自動的に候補として保存
- **実装**:
  - 自由入力種目をDBに保存（`is_custom = 1`フラグ）
  - 次回以降、種目選択時に標準種目と一緒に表示
  - 検索にも含める
- **UX改善**: 同じカスタム種目を何度も入力する手間を削減

#### タイマーのプリセット（60s/90s/120s）
- **要件**: タイマーに60秒、90秒、120秒のプリセットボタンを追加
- **実装**:
  - タイマー拡大モーダルにプリセットボタンを配置
  - ボタンタップで該当時間をセットし、自動スタート
- **UX改善**: 毎回手動で時間設定する手間を削減

#### 前回セット一覧の省略表示（3セット以上で"…"＋タップ展開）
- **要件**: 前回記録が3セット以上ある場合、最初の2セットのみ表示し、残りは「…」で省略
- **実装**:
  - 前回記録が3セット以上の場合、2セット表示 + 「+N more」ボタン
  - ボタンタップで全セット展開
- **UX改善**: 種目カードが縦に長くなりすぎるのを防ぐ

---

### 2.4 改善基盤

#### 主要イベントの解析（最小限）
- **要件**: アプリ内の主要アクションをイベント計測し、改善に活用
- **計測イベント**:
  - `app_open`（アプリ起動）
  - `workout_start`（ワークアウト開始）
  - `workout_complete`（ワークアウト完了）
  - `set_added`（セット追加）
  - `prev_copy_used`（前回コピー使用）
  - `timer_start`（タイマー開始）
  - `exercise_progress_open`（種目グラフ閲覧）
  - `history_calendar_open`（カレンダー履歴閲覧）
- **実装**: Firebase Analytics または Mixpanel を使用（最小限の設定）

---

## 3. 実装優先順位の決定

### 優先順位の判断基準
1. **MVP価値**: ユーザーの継続率に直接寄与するか
2. **実装難易度**: 実装コストが低いか
3. **依存関係**: 他の機能に依存しないか

### 優先順位（高→低）

#### 🔥 P1-High（優先実装）

| 順位 | 機能 | MVP価値 | 難易度 | 依存関係 | 理由 |
|------|------|---------|--------|----------|------|
| 1 | 今月のトレーニング回数表示 | 高 | 低 | なし | Home画面の改善、実装が簡単 |
| 2 | トレーニング継続日数表示 | 高 | 中 | なし | 継続動機に直結、計算ロジックが必要 |
| 3 | タイマーのプリセット | 高 | 低 | なし | 入力体験の改善、実装が簡単 |
| 4 | 種目の曖昧検索 | 高 | 中 | なし | 種目数が増えると必須、UX向上 |
| 5 | 自由入力種目の候補化 | 高 | 中 | 検索機能 | カスタム種目の再利用性向上 |

#### 📊 P1-Medium（価値あり、余裕があれば実装）

| 順位 | 機能 | MVP価値 | 難易度 | 依存関係 | 理由 |
|------|------|---------|--------|----------|------|
| 6 | カレンダー履歴（月表示） | 中 | 中 | なし | 振り返り体験の向上、新規画面 |
| 7 | 履歴の日付タップ→サマリ | 中 | 中 | カレンダー | カレンダーとセット実装 |
| 8 | 前回セット一覧の省略表示 | 中 | 低 | なし | UI改善、実装は簡単 |

#### 🔧 P1-Low（あると良いが、後回し可能）

| 順位 | 機能 | MVP価値 | 難易度 | 依存関係 | 理由 |
|------|------|---------|--------|----------|------|
| 9 | 主要イベントの解析 | 低 | 中 | なし | 改善基盤、初期は手動分析でも可 |

---

## 4. 各機能の詳細設計

### 4.1 今月のトレーニング回数表示

#### 画面
Home Screen

#### UI配置
```
┌─────────────────────────────┐
│  [今日の日付]                │
│                             │
│  ┌─────────────────────┐    │
│  │  今月のトレーニング    │    │
│  │  🏋️ 8回               │    │ ← 新規追加
│  └─────────────────────┘    │
│                             │
│  [トレーニング開始ボタン]     │
│  ...                        │
└─────────────────────────────┘
```

#### データ取得ロジック
```dart
// WorkoutSessionDao に追加
Future<int> getMonthlyWorkoutCount(int year, int month) async {
  final startOfMonth = DateTime(year, month, 1);
  final endOfMonth = DateTime(year, month + 1, 0, 23, 59, 59);

  final db = await database;
  final result = await db.query(
    'workout_sessions',
    where: 'status = ? AND completed_at >= ? AND completed_at <= ?',
    whereArgs: [
      'completed',
      startOfMonth.millisecondsSinceEpoch ~/ 1000,
      endOfMonth.millisecondsSinceEpoch ~/ 1000,
    ],
  );

  return result.length;
}
```

#### i18n文言
- `monthly_workout_count`: "This month: {count} workouts" / "今月 {count}回"

---

### 4.2 トレーニング継続日数表示

#### 画面
Home Screen

#### UI配置
```
┌─────────────────────────────┐
│  [今日の日付]                │
│                             │
│  ┌─────────────────────┐    │
│  │  今月のトレーニング    │    │
│  │  🏋️ 8回               │    │
│  └─────────────────────┘    │
│  ┌─────────────────────┐    │
│  │  継続日数              │    │
│  │  🔥 12日               │    │ ← 新規追加
│  └─────────────────────┘    │
│                             │
│  [トレーニング開始ボタン]     │
└─────────────────────────────┘
```

#### 継続日数の計算ロジック
```dart
// WorkoutSessionDao に追加
Future<int> getCurrentStreak() async {
  final db = await database;

  // 完了済みセッションを降順（最新→古い）で取得
  final sessions = await db.query(
    'workout_sessions',
    where: 'status = ?',
    whereArgs: ['completed'],
    orderBy: 'completed_at DESC',
  );

  if (sessions.isEmpty) return 0;

  int streak = 0;
  DateTime? previousDate;

  for (var session in sessions) {
    final completedAt = DateTime.fromMillisecondsSinceEpoch(
      session['completed_at'] as int * 1000
    );
    final currentDate = DateTime(
      completedAt.year,
      completedAt.month,
      completedAt.day,
    );

    if (previousDate == null) {
      // 最初のセッション
      streak = 1;
      previousDate = currentDate;
    } else {
      final daysDiff = previousDate.difference(currentDate).inDays;

      if (daysDiff <= 2) {
        // 2日以内なら継続
        streak++;
        previousDate = currentDate;
      } else {
        // 途切れた
        break;
      }
    }
  }

  return streak;
}
```

#### i18n文言
- `streak_days`: "{count} day streak" / "継続 {count}日"

---

### 4.3 タイマーのプリセット

#### 画面
Timer Modal Widget（タイマー拡大モーダル）

#### UI配置
```
┌─────────────────────────────┐
│  タイマー                    │
│                             │
│       00:45                 │ ← カウントダウン表示
│                             │
│  ┌───┬───┬───┐              │
│  │60s│90s│120s│              │ ← プリセットボタン（新規追加）
│  └───┴───┴───┘              │
│                             │
│  [Start] [Pause] [Reset]    │
│                             │
│  [閉じる]                    │
└─────────────────────────────┘
```

#### 実装
```dart
// Timer Modal Widget に追加
Widget _buildPresetButtons() {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    children: [
      _buildPresetButton(60, '60s'),
      _buildPresetButton(90, '90s'),
      _buildPresetButton(120, '120s'),
    ],
  );
}

Widget _buildPresetButton(int seconds, String label) {
  return ElevatedButton(
    onPressed: () {
      ref.read(timerProvider.notifier).setAndStart(seconds);
    },
    child: Text(label),
  );
}
```

#### TimerProvider に追加
```dart
void setAndStart(int seconds) {
  _remainingSeconds = seconds;
  _initialSeconds = seconds;
  start();
}
```

---

### 4.4 種目の曖昧検索

#### 画面
Exercise Selector Modal（種目選択モーダル）

#### UI配置
```
┌─────────────────────────────┐
│  種目を選択                  │
│                             │
│  [検索ボックス]  🔍          │ ← 検索ボックス（新規追加）
│                             │
│  部位                        │
│  ○ 胸  ○ 背中  ○ 脚  ...     │
│                             │
│  種目                        │
│  - ベンチプレス              │ ← 検索結果をフィルタ表示
│  - ダンベルプレス            │
│  ...                        │
│                             │
│  [自由入力]                  │
└─────────────────────────────┘
```

#### 実装
```dart
// Exercise Selector Modal に追加
class ExerciseSelectorModal extends ConsumerStatefulWidget {
  // ...

  @override
  _ExerciseSelectorModalState createState() => _ExerciseSelectorModalState();
}

class _ExerciseSelectorModalState extends ConsumerState<ExerciseSelectorModal> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 検索ボックス
        TextField(
          decoration: InputDecoration(
            hintText: l10n.searchExercisePlaceholder,
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (value) {
            setState(() {
              _searchQuery = value.toLowerCase();
            });
          },
        ),

        // 種目リスト（検索フィルタ適用）
        Expanded(
          child: _buildExerciseList(),
        ),
      ],
    );
  }

  Widget _buildExerciseList() {
    // 種目リストを取得し、検索クエリでフィルタ
    final exercises = _getFilteredExercises(_searchQuery);

    return ListView.builder(
      itemCount: exercises.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(exercises[index].name),
          onTap: () => _onExerciseSelected(exercises[index]),
        );
      },
    );
  }

  List<Exercise> _getFilteredExercises(String query) {
    if (query.isEmpty) {
      return allExercises; // 全種目表示
    }

    return allExercises.where((exercise) {
      final nameEn = exercise.nameEn.toLowerCase();
      final nameJa = exercise.nameJa.toLowerCase();
      return nameEn.contains(query) || nameJa.contains(query);
    }).toList();
  }
}
```

#### i18n文言
- `search_exercise_placeholder`: "Search exercise" / "種目を検索"

---

### 4.5 自由入力種目の候補化

#### データベース変更
`exercise_master` テーブルに `is_custom` カラムを追加

```sql
ALTER TABLE exercise_master ADD COLUMN is_custom INTEGER DEFAULT 0;
```

#### 実装フロー
1. ユーザーが自由入力で種目を入力
2. `ExerciseMasterDao.insertCustomExercise()` を呼び出し、`is_custom = 1` でDB保存
3. 次回以降、種目選択時に標準種目とカスタム種目を一緒に表示
4. 検索にもカスタム種目を含める

#### ExerciseMasterDao に追加
```dart
Future<int> insertCustomExercise({
  required String nameEn,
  required String nameJa,
  required String bodyPart,
}) async {
  final db = await database;

  // 既存のカスタム種目をチェック
  final existing = await db.query(
    'exercise_master',
    where: 'name_en = ? AND is_custom = 1',
    whereArgs: [nameEn],
  );

  if (existing.isNotEmpty) {
    // 既に存在する場合はIDを返す
    return existing.first['id'] as int;
  }

  // 新規挿入
  return await db.insert('exercise_master', {
    'name_en': nameEn,
    'name_ja': nameJa,
    'body_part': bodyPart,
    'is_custom': 1,
  });
}

Future<List<ExerciseMasterEntity>> getAllExercises() async {
  final db = await database;

  // 標準種目とカスタム種目を両方取得
  final results = await db.query(
    'exercise_master',
    orderBy: 'is_custom ASC, name_en ASC', // 標準種目を先に表示
  );

  return results.map((row) => ExerciseMasterEntity.fromMap(row)).toList();
}
```

---

### 4.6 前回セット一覧の省略表示

#### 画面
Workout Input Screen - Exercise Card Widget

#### UI配置
```
┌─────────────────────────────┐
│  ベンチプレス                │
│                             │
│  前回の記録                  │
│  Set 1: 40kg × 10回          │
│  Set 2: 40kg × 10回          │
│  [+2 more sets]              │ ← 省略表示（新規追加）
│                             │
│  [前回を再現]                │
│                             │
│  今回の記録                  │
│  ...                        │
└─────────────────────────────┘
```

#### 実装
```dart
// Exercise Card Widget に追加
class ExerciseCardWidget extends StatefulWidget {
  // ...
}

class _ExerciseCardWidgetState extends State<ExerciseCardWidget> {
  bool _isPreviousRecordExpanded = false;

  Widget _buildPreviousRecord(List<SetRecord> previousSets) {
    if (previousSets.isEmpty) {
      return Text(l10n.noPreviousRecord);
    }

    final displayedSets = _isPreviousRecordExpanded
        ? previousSets
        : previousSets.take(2).toList();

    return Column(
      children: [
        ...displayedSets.map((set) => _buildPreviousSetRow(set)),

        if (previousSets.length > 2)
          TextButton(
            onPressed: () {
              setState(() {
                _isPreviousRecordExpanded = !_isPreviousRecordExpanded;
              });
            },
            child: Text(
              _isPreviousRecordExpanded
                  ? l10n.showLessSets
                  : l10n.showMoreSets(previousSets.length - 2),
            ),
          ),
      ],
    );
  }
}
```

#### i18n文言
- `show_more_sets`: "+{count} more sets" / "他 {count}セット"
- `show_less_sets`: "Show less" / "閉じる"

---

### 4.7 カレンダー履歴（月表示）

#### 新規画面
History Screen（カレンダー履歴画面）

#### UI配置
```
┌─────────────────────────────┐
│  履歴                        │
│                             │
│  ← 2024年1月 →              │ ← 月切替
│                             │
│  日 月 火 水 木 金 土         │
│     1  2  3  4  5  6        │
│  7  ● 9  10 11 12 ●         │ ← ●: ワークアウト実施日
│  14 15 16 17 ● 19 20        │
│  ...                        │
│                             │
│  今月 8回 | 継続 12日         │ ← 統計表示
└─────────────────────────────┘
```

#### 実装パッケージ
`table_calendar` パッケージを使用

```yaml
dependencies:
  table_calendar: ^3.0.9
```

#### 実装
```dart
// lib/features/history/history_screen.dart
class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<WorkoutSessionEntity>> _workoutDays = {};

  @override
  void initState() {
    super.initState();
    _loadWorkouts();
  }

  Future<void> _loadWorkouts() async {
    // 該当月のワークアウトを取得
    final workouts = await WorkoutSessionDao().getWorkoutsForMonth(
      _focusedDay.year,
      _focusedDay.month,
    );

    // 日付ごとにグループ化
    final Map<DateTime, List<WorkoutSessionEntity>> grouped = {};
    for (var workout in workouts) {
      final date = DateTime(
        workout.completedAt.year,
        workout.completedAt.month,
        workout.completedAt.day,
      );
      grouped.putIfAbsent(date, () => []).add(workout);
    }

    setState(() {
      _workoutDays = grouped;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.historyTitle),
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime(2020, 1, 1),
            lastDay: DateTime(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            eventLoader: (day) {
              final normalized = DateTime(day.year, day.month, day.day);
              return _workoutDays[normalized] ?? [];
            },
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });

              // サマリポップアップ表示
              _showWorkoutSummary(selectedDay);
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
              _loadWorkouts();
            },
          ),

          // 統計表示
          _buildMonthlyStats(),
        ],
      ),
    );
  }

  void _showWorkoutSummary(DateTime day) {
    final normalized = DateTime(day.year, day.month, day.day);
    final workouts = _workoutDays[normalized];

    if (workouts == null || workouts.isEmpty) return;

    showModalBottomSheet(
      context: context,
      builder: (context) => WorkoutSummarySheet(workout: workouts.first),
    );
  }
}
```

#### WorkoutSessionDao に追加
```dart
Future<List<WorkoutSessionEntity>> getWorkoutsForMonth(int year, int month) async {
  final startOfMonth = DateTime(year, month, 1);
  final endOfMonth = DateTime(year, month + 1, 0, 23, 59, 59);

  final db = await database;
  final results = await db.query(
    'workout_sessions',
    where: 'status = ? AND completed_at >= ? AND completed_at <= ?',
    whereArgs: [
      'completed',
      startOfMonth.millisecondsSinceEpoch ~/ 1000,
      endOfMonth.millisecondsSinceEpoch ~/ 1000,
    ],
    orderBy: 'completed_at DESC',
  );

  return results.map((row) => WorkoutSessionEntity.fromMap(row)).toList();
}
```

#### Home Screen に導線追加
```dart
// Home Screen に履歴ボタン追加
AppBar(
  actions: [
    IconButton(
      icon: Icon(Icons.calendar_today),
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => HistoryScreen()),
        );
      },
    ),
    IconButton(
      icon: Icon(Icons.settings),
      onPressed: () { /* 設定画面へ */ },
    ),
  ],
)
```

---

### 4.8 履歴の日付タップ→サマリポップアップ

#### UI配置
```
┌─────────────────────────────┐
│  2024年1月15日のワークアウト  │
│                             │
│  🕒 10:30 - 11:45 (1時間15分)│
│  💪 3種目                    │
│  📊 9セット                  │
│                             │
│  [詳細を見る]                │ ← タップでWorkout Detail Screenへ
└─────────────────────────────┘
```

#### 実装
```dart
// lib/features/history/widgets/workout_summary_sheet.dart
class WorkoutSummarySheet extends StatelessWidget {
  final WorkoutSessionEntity workout;

  const WorkoutSummarySheet({required this.workout, super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _formatDate(workout.completedAt),
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),

          _buildInfoRow(Icons.access_time, _formatDuration()),
          _buildInfoRow(Icons.fitness_center, l10n.exerciseCount(workout.exerciseCount)),
          _buildInfoRow(Icons.bar_chart, l10n.setCount(workout.totalSets)),

          SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => WorkoutDetailScreen(sessionId: workout.id!),
                  ),
                );
              },
              child: Text(l10n.viewDetailsButton),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          SizedBox(width: 12),
          Text(text, style: TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}
```

---

### 4.9 主要イベントの解析

#### 使用ツール
Firebase Analytics（無料、Flutterサポート充実）

#### セットアップ
```yaml
dependencies:
  firebase_core: ^2.24.0
  firebase_analytics: ^10.8.0
```

#### 実装
```dart
// lib/services/analytics_service.dart
class AnalyticsService {
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  // アプリ起動
  Future<void> logAppOpen() async {
    await _analytics.logAppOpen();
  }

  // ワークアウト開始
  Future<void> logWorkoutStart() async {
    await _analytics.logEvent(name: 'workout_start');
  }

  // ワークアウト完了
  Future<void> logWorkoutComplete({
    required int exerciseCount,
    required int totalSets,
    required int durationMinutes,
  }) async {
    await _analytics.logEvent(
      name: 'workout_complete',
      parameters: {
        'exercise_count': exerciseCount,
        'total_sets': totalSets,
        'duration_minutes': durationMinutes,
      },
    );
  }

  // セット追加
  Future<void> logSetAdded() async {
    await _analytics.logEvent(name: 'set_added');
  }

  // 前回コピー使用
  Future<void> logPrevCopyUsed({required String type}) async {
    await _analytics.logEvent(
      name: 'prev_copy_used',
      parameters: {'type': type}, // 'set' or 'all'
    );
  }

  // タイマー開始
  Future<void> logTimerStart({required int seconds}) async {
    await _analytics.logEvent(
      name: 'timer_start',
      parameters: {'seconds': seconds},
    );
  }

  // 種目グラフ閲覧
  Future<void> logExerciseProgressOpen({required String exerciseName}) async {
    await _analytics.logEvent(
      name: 'exercise_progress_open',
      parameters: {'exercise_name': exerciseName},
    );
  }

  // カレンダー履歴閲覧
  Future<void> logHistoryCalendarOpen() async {
    await _analytics.logEvent(name: 'history_calendar_open');
  }
}
```

#### 各画面・機能に組み込み
```dart
// 例：Workout Input Screen
class WorkoutInputScreen extends ConsumerWidget {
  final AnalyticsService _analytics = AnalyticsService();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ワークアウト開始時
    useEffect(() {
      _analytics.logWorkoutStart();
      return null;
    }, []);

    // セット追加時
    void _addSet() {
      // セット追加処理
      _analytics.logSetAdded();
    }

    // 前回コピー使用時
    void _copyPreviousSet() {
      // コピー処理
      _analytics.logPrevCopyUsed(type: 'set');
    }

    // ...
  }
}
```

---

## 5. 技術的考慮事項

### 5.1 パフォーマンス

#### カレンダー履歴の最適化
- **課題**: 月ごとのワークアウト取得が重い可能性
- **対策**:
  - クエリにインデックスを追加（`completed_at`）
  - 月単位でキャッシュ（Provider/Riverpod）
  - ページ切替時のみデータ再取得

#### 種目検索の最適化
- **課題**: 種目数が増えると検索が遅くなる可能性
- **対策**:
  - FTS（Full-Text Search）を使用（SQLiteのFTS5拡張）
  - または、メモリ上でフィルタリング（種目数が100以下なら十分）

### 5.2 データ整合性

#### カスタム種目の重複防止
- 同じ名前のカスタム種目が複数登録されないよう、`name_en` にユニーク制約を追加
- ただし、標準種目と同名のカスタム種目は許可（`is_custom = 1` で区別）

#### 継続日数の計算精度
- タイムゾーンを考慮した日付計算（ローカルタイムゾーン基準）
- 日跨ぎのワークアウト（23:00開始、1:00終了）は開始日でカウント

### 5.3 i18n

#### 新規追加文言
全ての新規文言を `app_en.arb` / `app_ja.arb` に追加

```json
// app_en.arb
{
  "monthly_workout_count": "This month: {count} workouts",
  "streak_days": "{count} day streak",
  "search_exercise_placeholder": "Search exercise",
  "show_more_sets": "+{count} more sets",
  "show_less_sets": "Show less",
  "history_title": "History",
  "view_details_button": "View details",
  "exercise_count": "{count} exercises",
  "set_count": "{count} sets"
}
```

```json
// app_ja.arb
{
  "monthly_workout_count": "今月 {count}回",
  "streak_days": "継続 {count}日",
  "search_exercise_placeholder": "種目を検索",
  "show_more_sets": "他 {count}セット",
  "show_less_sets": "閉じる",
  "history_title": "履歴",
  "view_details_button": "詳細を見る",
  "exercise_count": "{count}種目",
  "set_count": "{count}セット"
}
```

---

## 6. データベース変更

### 6.1 マイグレーション

#### Migration v2: カスタム種目対応

```dart
// lib/data/database/database_helper.dart

Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
  if (oldVersion < 2) {
    // v2: カスタム種目フラグ追加
    await db.execute('''
      ALTER TABLE exercise_master ADD COLUMN is_custom INTEGER DEFAULT 0;
    ''');

    // インデックス追加
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_exercise_custom ON exercise_master(is_custom);
    ''');
  }
}
```

#### Migration v3: クエリ最適化用インデックス

```dart
if (oldVersion < 3) {
  // v3: completed_at にインデックス追加（カレンダー履歴の高速化）
  await db.execute('''
    CREATE INDEX IF NOT EXISTS idx_session_completed ON workout_sessions(completed_at);
  ''');
}
```

### 6.2 マイグレーションテスト

マイグレーション実行後、既存データが正しく保持されることを確認

```dart
test('migration from v1 to v2 preserves data', () async {
  // テストコード
});
```

---

## 7. 実装順序

### 7.1 Phase 1: 継続動機の強化（1週間）

**目的**: Home画面の改善で継続率を向上

| 順序 | タスク | 担当範囲 | 所要時間 |
|------|--------|----------|----------|
| 1 | 今月のトレーニング回数表示 | Home Screen, DAO | 2時間 |
| 2 | トレーニング継続日数表示 | Home Screen, DAO | 4時間 |
| 3 | テスト・動作確認 | 全体 | 2時間 |

**完了条件**:
- Home画面に今月回数・継続日数が表示される
- 数値が正しく計算されることを確認
- 言語切替で文言が変わることを確認

---

### 7.2 Phase 2: 入力補助の最適化（1.5週間）

**目的**: 記録入力体験をさらに快適にする

| 順序 | タスク | 担当範囲 | 所要時間 |
|------|--------|----------|----------|
| 4 | タイマーのプリセット | Timer Widget | 3時間 |
| 5 | 種目の曖昧検索 | Exercise Selector | 6時間 |
| 6 | 自由入力種目の候補化 | Exercise Selector, DAO, Migration | 6時間 |
| 7 | 前回セット一覧の省略表示 | Exercise Card Widget | 3時間 |
| 8 | テスト・動作確認 | 全体 | 3時間 |

**完了条件**:
- タイマープリセットが動作する
- 種目検索が部分一致で動作する
- カスタム種目が候補として表示される
- 前回記録が3セット以上で省略表示される

---

### 7.3 Phase 3: 振り返り体験の充実（2週間）

**目的**: カレンダー履歴で成長実感を提供

| 順序 | タスク | 担当範囲 | 所要時間 |
|------|--------|----------|----------|
| 9 | カレンダー履歴画面作成 | History Screen | 8時間 |
| 10 | 日付タップ→サマリポップアップ | History Screen, Summary Sheet | 4時間 |
| 11 | Home画面に履歴ボタン追加 | Home Screen | 1時間 |
| 12 | テスト・動作確認 | 全体 | 3時間 |

**完了条件**:
- カレンダー形式で履歴が表示される
- ワークアウト実施日にマーカーが表示される
- 日付タップでサマリが表示される
- サマリから詳細画面に遷移できる

---

### 7.4 Phase 4: 改善基盤の構築（1週間）

**目的**: データに基づいた改善を可能にする

| 順序 | タスク | 担当範囲 | 所要時間 |
|------|--------|----------|----------|
| 13 | Firebase Analytics セットアップ | プロジェクト全体 | 4時間 |
| 14 | 主要イベント計測実装 | 各画面・機能 | 6時間 |
| 15 | 動作確認・イベント検証 | 全体 | 2時間 |

**完了条件**:
- Firebase Console でイベントが確認できる
- 主要イベント（8種類）が正しく計測される

---

### 7.5 総実装期間

**合計**: 約5.5週間（余裕を持って6-7週間）

---

## 8. 受け入れ基準

### 8.1 機能的受け入れ基準

#### 継続動機
- [ ] Home画面に今月のトレーニング回数が表示される
- [ ] Home画面に継続日数が表示される
- [ ] 継続日数の計算ロジックが正しい（2日以内で継続、途切れたらリセット）

#### 振り返り体験
- [ ] カレンダー形式で履歴が表示される
- [ ] ワークアウト実施日にマーカーが表示される
- [ ] 日付タップでサマリポップアップが表示される
- [ ] サマリから詳細画面に遷移できる
- [ ] 月切替が正しく動作する

#### 入力補助
- [ ] タイマーにプリセットボタン（60s/90s/120s）が表示される
- [ ] プリセットボタンタップで該当時間がセットされ、自動スタートする
- [ ] 種目検索ボックスが表示される
- [ ] 検索クエリで種目が部分一致フィルタされる
- [ ] カスタム種目が候補として表示される
- [ ] 前回記録が3セット以上の場合、省略表示される
- [ ] 「+N more」ボタンタップで全セット展開される

#### 改善基盤
- [ ] Firebase Analytics が正しくセットアップされている
- [ ] 主要イベント（8種類）が計測される
- [ ] Firebase Console でイベントが確認できる

---

### 8.2 非機能的受け入れ基準

#### パフォーマンス
- [ ] カレンダー履歴の月切替が1秒以内に完了する
- [ ] 種目検索の結果が0.5秒以内に表示される
- [ ] 継続日数・今月回数の計算が1秒以内に完了する

#### UX
- [ ] P0の「爆速入力」体験が損なわれていない
- [ ] 新機能がP0の操作を妨げていない
- [ ] 全ての新規UI要素が親指操作で快適に使える

#### i18n
- [ ] 全ての新規文言が英語・日本語で表示される
- [ ] 言語切替で全ての文言が切り替わる

#### データ整合性
- [ ] カスタム種目の重複が防止されている
- [ ] マイグレーション実行後も既存データが保持されている

---

### 8.3 ユーザーテスト基準

**テスター**: 筋トレを週2回以上する友人/知人 3人

**観察ポイント**:
- [ ] カレンダー履歴を見て「成長が見える」と感じるか
- [ ] 継続日数を見て「続けたい」と感じるか
- [ ] 種目検索がスムーズに使えるか
- [ ] タイマープリセットが便利と感じるか
- [ ] P0の「爆速入力」体験が損なわれていないか

---

## 9. 追加提案機能

### 9.1 データエクスポート（CSV/JSON）

#### 目的
- ユーザーが自分のデータを持ち出せる安心感を提供
- 他のツール（Excel、Googleスプレッドシート等）での分析を可能にする

#### 実装
- Settings Screen に「データエクスポート」ボタンを追加
- エクスポート形式：CSV または JSON
- エクスポート内容：全ワークアウトセッション、種目、セット記録

#### 優先度
P1-Medium（余裕があれば実装）

---

### 9.2 データバックアップ・リストア

#### 目的
- ユーザーのデータ保護
- 機種変更時のデータ移行

#### 実装
- Settings Screen に「バックアップ」「復元」ボタンを追加
- バックアップ形式：JSON
- 保存先：端末のファイルシステム or クラウド（Google Drive / iCloud）

#### 優先度
P1-Medium（余裕があれば実装）

---

### 9.3 週間統計表示

#### 目的
- より詳細な継続動機を提供
- 月単位だけでなく、週単位での成長実感

#### 実装
- Home Screen または History Screen に週間統計を追加
- 表示内容：今週のトレーニング回数、総セット数、総ボリューム等

#### 優先度
P2（100ユーザー達成後）

---

### 9.4 お気に入り種目

#### 目的
- 頻繁に使う種目への素早いアクセス
- 種目選択の手間を削減

#### 実装
- 種目選択モーダルに「お気に入り」セクションを追加
- 種目を長押しでお気に入り登録
- お気に入り種目を上部に表示

#### 優先度
P2（100ユーザー達成後）

---

### 9.5 ワークアウトテンプレート（簡易版）

#### 目的
- 毎回同じルーティンを記録するユーザーのサポート
- 記録開始時の手間を削減

#### 実装
- ワークアウト完了時に「テンプレートとして保存」オプション
- テンプレート選択で種目が自動追加される
- 前回記録も自動コピー

#### 優先度
P2（100ユーザー達成後）

---

## 10. まとめ

### P1実装のゴール

1. **継続率の向上**: D7継続率 20% → 30%
2. **成長実感の提供**: カレンダー履歴、継続日数で「続けたい」と思わせる
3. **入力体験の最適化**: P0の爆速入力をさらに快適にする
4. **改善基盤の構築**: データに基づいた継続的な改善を可能にする

### 実装の進め方

1. **Phase 1**: 継続動機の強化（Home画面改善）
2. **Phase 2**: 入力補助の最適化（検索、プリセット等）
3. **Phase 3**: 振り返り体験の充実（カレンダー履歴）
4. **Phase 4**: 改善基盤の構築（Analytics）

### 次のステップ

P1実装計画の承認後、以下の順序で実装を開始：

1. ✅ P1実装計画の確認・承認
2. Phase 1の実装開始（今月のトレーニング回数・継続日数表示）
3. 各Phaseの完了後、動作確認・ユーザーテスト
4. P1完了後、P2への移行判断

---

**以上、P1実装計画書でした。ご確認ください！**
