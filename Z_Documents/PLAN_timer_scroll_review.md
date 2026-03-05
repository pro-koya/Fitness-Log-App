# 実装計画案：タイマーロック画面・スクロール・レビュー促進

## 1. タイマー機能：ロック画面に経過時間を表示

### 1.1 目的
タイマー起動中に iPhone をロックした際、ロック画面に経過時間（または残り時間）を表示する。

### 1.2 技術選定

| 方式 | 概要 | メリット | デメリット |
|------|------|----------|------------|
| **Live Activities** | iOS 16.1+ のロック画面・Dynamic Island にリアルタイム表示 | 経過時間のライブ更新が可能、ネイティブ体験 | Widget Extension が必要、Flutter からは Method Channel でネイティブ連携が必須 |
| **通知の定期更新** | バックグラウンドで通知を「更新」して経過を表示 | 既存の flutter_local_notifications を拡張しやすい | 更新頻度に制限があり、秒単位の滑らかな表示は難しい |
| **フォアグラウンドサービス + 通知** | Android は通知に経過表示、iOS は通知のみ | 実装範囲が限定的 | iOS ロック画面で「ライブ」な経過表示は難しい |

**推奨**: **Live Activities（iOS）** を採用する。  
ロック画面に「残り時間」または「経過時間」を常時更新表示するには、iOS の Live Activities + WidgetKit が標準的な手段となる。

### 1.3 現状の整理

- **既存**: `TimerNotifier`（実時刻ベース）、`TimerPersistenceService`（SharedPreferences）、`TimerLocalNotificationService`（終了時1回の通知）
- **不足**: ロック画面での「経過／残り時間」の常時表示

### 1.4 実装計画（Live Activities 採用時）

#### Phase 1: ネイティブ側（iOS）

| # | 作業内容 |
|---|----------|
| 1.1 | Xcode で **Widget Extension** を追加（「Live Activity を含む」を有効化） |
| 1.2 | **App Groups** を有効化（メインアプリと Widget Extension で共有。例: `group.xxx.fitnesslog`） |
| 1.3 | `ActivityAttributes` を定義（例: `endTime: Date`, `initialSeconds: Int`, `isRunning: Bool` など。経過表示なら `startedAt` + `initialSeconds` で十分） |
| 1.4 | Lock Screen / Dynamic Island 用の UI を SwiftUI で実装（`Text(timerInterval: startDate ...)` で経過時間の自動更新、または残り時間を `endTime` ベースで表示） |
| 1.5 | メインアプリから Live Activity を開始・更新・終了する API を用意（`Activity.request(...)` / `activity.end(...)`） |

#### Phase 2: Flutter 連携

| # | 作業内容 |
|---|----------|
| 2.1 | **Method Channel** を定義（例: `fitness_log/live_activity`） |
| 2.2 | Flutter 側で `startLiveActivity(initialSeconds)`, `updateLiveActivity(remainingSeconds)`, `endLiveActivity()` を呼び出すサービスを実装 |
| 2.3 | `TimerNotifier` の `start()` で `startLiveActivity`、`pause()` / `reset()` / 終了で `endLiveActivity` を呼ぶ（プラットフォーム判定で iOS のみ） |
| 2.4 | （オプション）バックグラウンドでも更新する場合は、ネイティブで Background Task や Push に頼る設計は複雑なため、まずは「アプリがフォアグラウンドの間だけ Live Activity を更新」でも可。ロック画面表示は iOS が自動で行う。 |

#### Phase 3: 動作確認・制約

- Live Activities は iOS 16.1 以上。それ未満は従来どおり「終了時通知」のみとする。
- 実機でロック画面・Dynamic Island（対応機種）の表示を確認する。

### 1.5 代替案（工数削減）

- **「ロック画面に経過表示」を一旦見送り**、現状の「バックグラウンド復帰時に正しい残り時間を再計算」「終了時に通知」のみとする。
- または **通知の内容を「経過 ○ 分」のように定期的に更新**する簡易実装（更新間隔は 1 分など。秒単位は難しい）。

---

## 2. スクロール設定：月間サマリ＋カレンダーのスクロール許容

### 2.1 目的
月間サマリ部分のスクロール幅が小さいため、カレンダー部分とまとめてスクロールできるようにし、「カレンダーの 2/1 まで」（＝カレンダーが約半分見えるところまで）スクロールできるようにする。

### 2.2 現状の構造（history_screen.dart）

```
body: SafeArea(
  child: Column(
    children: [
      月・年クイックボタン + 月年ピッカー (高さ 48 + padding),
      TableCalendar(...),        // 固定表示
      Divider(),
      Expanded(
        child: SingleChildScrollView(  // ここだけスクロール
          child: Column(
            _buildQuickStats(),
            _buildTotalDurationCard(),
            _buildBodyPartFilter(),
            _buildMonthlySummaryCard(),
            _buildTopExercises(),
            _buildWeeklyTrend(),
          ),
        ),
      ),
      BannerAdWidget(),
    ],
  ),
)
```

- **問題**: スクロール可能なのは `Expanded` 内の `SingleChildScrollView` のみ。カレンダーは常に固定で、サマリは「残りスペース」内でしかスクロールしないため、表示領域が狭い。

### 2.3 方針

- **カレンダーと月間サマリを 1 本のスクロールにまとめる**。
- スクロールで「上に詰めたときに、カレンダーが約半分（または一定量）まで隠れる」ようにし、その分だけサマリの表示領域が広がる。

### 2.4 実装計画

| # | 作業内容 |
|---|----------|
| 2.1 | `Column` の「月ボタン / TableCalendar / Divider / Expanded+SingleChildScrollView」を、**1 つの `CustomScrollView`（または `SingleChildScrollView`）** にまとめる。 |
| 2.2 | スクロールの子要素の順序: ① 月・年クイックボタン ② TableCalendar ③ Divider ④ 月間サマリ（Quick stats, Total duration, Body part filter, Monthly summary card, Top exercises, Weekly trend）。 |
| 2.2a | `TableCalendar` は高さが可変のため、`IntrinsicHeight` で包むか、または **カレンダー部分に `SizedBox(height: 〇〇)` で最小高さを付与**して、スクロール量を「カレンダー高さの約 1/2 まで」と読みやすくする（要調整）。 |
| 2.3 | 下端の `BannerAdWidget` は **スクロール外に固定**（`CustomScrollView` の外で、Column の最後に配置）して、常に画面下部に表示する。 |
| 2.4 | ローディング時は、これまでどおり `_isLoading` で `CircularProgressIndicator` を表示するレイアウトにし、データ取得後に上記スクロール構造に切り替える。 |

### 2.5 レイアウト案（疑似）

```
body: SafeArea(
  child: Column(
    children: [
      Expanded(
        child: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(  // または CustomScrollView
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 月・年
                  Padding(... month buttons ...),
                  TableCalendar(...),
                  Divider(),
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildQuickStats(),
                        ...
                        _buildWeeklyTrend(),
                      ],
                    ),
                  ),
                  // 下端に「カレンダー高さの約1/2」分スクロールできるよう、
                  // 必要なら SizedBox(height: カレンダー高さの約0.5) を末尾に入れて
                  // スクロール量を確保する（任意）
                ],
              ),
            ),
      ),
      BannerAdWidget(),
    ],
  ),
)
```

- 「カレンダーの 2/1 までスクロール」は、**スクロール量の上限を「カレンダー高さの約 1/2」** と解釈し、末尾に `SizedBox(height: 〇〇)` を入れて最大スクロール量を制限する方法で実現可能。または制限なしで「カレンダーが全部隠れるまでスクロール可」でもよい（要件に合わせて調整）。

### 2.6 注意点

- `TableCalendar` は内部で週の行数が変わるため、高さは月によって変動する。`SizedBox` で固定する場合は、おおよその 1 ヶ月分の高さ（例: 6 行想定）で計算する。
- パフォーマンス: `SingleChildScrollView` + `Column(mainAxisSize: min)` で問題なし。リストが極端に長くなければ `ListView.builder` は不要。

---

## 3. レビュー促進：記録 3 回でレビュー依頼モーダル

### 3.1 目的
トレーニング記録を 3 回完了したタイミングで、App Store のレビューを促すモーダルを表示する。

### 3.2 要件の整理

| 項目 | 内容 |
|------|------|
| トリガー | 「記録を 3 回行った」＝ワークアウトを **完了** した回数が 3 回 |
| 表示タイミング | 3 回目の完了直後（例: 記録完了モーダルを閉じた後、または記録完了モーダル表示前に 1 回だけチェック） |
| 重複防止 | 一度レビュー依頼モーダルを表示したら、同じユーザーには再度表示しない（永続化） |
| プラットフォーム | iOS: StoreKit の `requestReview`。Android: in_app_review または Play Store のインテント |

### 3.3 技術選定

- **Flutter**: `in_app_review` パッケージ（App Store / Play Store のネイティブレビュー UI を表示）が一般的。
- **カウントの保存**: 完了回数と「レビュー依頼済みフラグ」を `SharedPreferences`（または既存の `SettingsDao` があればそこ）に保存。

### 3.4 実装計画

| # | 作業内容 |
|---|----------|
| 3.1 | **pubspec.yaml** に `in_app_review` を追加。 |
| 3.2 | **永続化**: 「完了したワークアウト回数」（例: `workout_completion_count`）と「レビュー依頼モーダルを表示したか」（例: `review_prompt_shown`）を SharedPreferences または Settings テーブルで管理。 |
| 3.3 | **カウント増加**: ワークアウト完了時にカウントを +1 する。呼び出し箇所は `workout_input_screen.dart` で `completeSession` の成功後、かつ `WorkoutCompletionModal.show` の前後いずれか（推奨: モーダルを閉じた後でカウント確認し、3 回かつ未表示ならレビュー依頼）。 |
| 3.4 | **レビュー依頼サービス**: `ReviewService`（または `ReviewPromptService`）を新規作成。`in_app_review` の `requestReview()` を呼ぶ。`isAvailable()` が true のときだけ呼ぶ。 |
| 3.5 | **表示タイミング**: 記録完了モーダルを閉じたコールバック内で、(1) 完了回数を +1 して保存、(2) 回数が 3 かつ `review_prompt_shown == false` ならレビュー依頼モーダル（または簡易ダイアログ「レビューをお願いします」→ OK で `requestReview()`）を表示し、`review_prompt_shown = true` を保存。 |
| 3.6 | **文言**: 多言語対応（l10n）で「記録 3 回達成」を祝いつつ「レビューを書いていただけますか？」のような短いメッセージを追加。 |
| 3.7 | **テスト**: 3 回完了で 1 回だけ表示されること、それ以降は表示されないことを確認。`requestReview()` は実機でしかレビュー UI が出ない場合があるため、テスト時は「レビュー依頼済みフラグ」の更新だけでも検証可能。 |

### 3.5 呼び出しフロー案

1. ユーザーが「記録完了」をタップ。
2. `completeSession` 実行 → 成功。
3. `WorkoutCompletionModal.show` で完了サマリを表示。
4. ユーザーがモーダルを閉じる。
5. `onClose` 内で:  
   - 完了回数を +1 して永続化。  
   - 回数が 3 かつ `review_prompt_shown == false` なら、簡易ダイアログ（例: 「3回記録できました！よろしければレビューをお願いします」）→ OK で `ReviewService.requestReview()` を呼び、`review_prompt_shown = true` を保存。

### 3.6 ファイル構成案

| ファイル | 役割 |
|----------|------|
| `lib/services/review_prompt_service.dart` | 完了回数の取得・加算、`review_prompt_shown` の読み書き、`in_app_review` のラップ |
| `lib/features/workout_input/workout_input_screen.dart` | 記録完了モーダル閉じた後に `ReviewPromptService` を呼ぶ |
| `lib/l10n/app_ja.arb` / `app_en.arb` | レビュー依頼の文言追加 |
| `pubspec.yaml` | `in_app_review` 追加 |

---

## 4. 優先度・工数目安

| 項目 | 優先度 | 工数目安 | 備考 |
|------|--------|----------|------|
| 1. タイマー・ロック画面 | 中〜高 | 大（iOS ネイティブ + Method Channel） | Live Activities は新規 Extension が必要 |
| 2. スクロール | 高 | 小 | 既存画面のレイアウト変更のみ |
| 3. レビュー促進 | 高 | 小 | パッケージ追加 + サービス + 1 箇所のフック |

実装順の提案: **2 → 3 → 1**（スクロールとレビューを先に完了し、その後にタイマー・ロック画面に着手）。

---

## 5. 実装サマリ（完了）

- **2. スクロール**: `lib/features/history/history_screen.dart` を修正。カレンダー＋月間サマリを1本の `SingleChildScrollView` にまとめ、下端に `SizedBox(height: 200)` でスクロール余白を確保。
- **3. レビュー促進**: `in_app_review` 追加、`lib/services/review_prompt_service.dart` 新規、記録完了3回目でダイアログ表示→「レビューを書く」で `requestReview()`。l10n に `reviewPromptTitle` 等を追加。
- **1. タイマー・ロック画面**: `lib/services/timer_live_activity_service.dart`（Method Channel）、`lib/providers/timer_provider.dart` で start/end コールバック追加。iOS: `TimerLiveActivityAttributes.swift` / `TimerLiveActivityBridge.swift`、`AppDelegate` にチャンネル登録、`Info.plist` に `NSSupportsLiveActivities`。Widget Extension 用コードは `ios/TimerWidgetExtension/TimerLiveActivity.swift` と手順は `Z_Documents/ios-live-activity-setup.md` を参照。
