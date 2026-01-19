# 実装順序：スムーズかつ変更が少ない実装計画

## 実装順序の基本方針

### 判断基準
1. **依存関係**：他の画面に依存しない画面から実装
2. **データフロー**：データの流れに沿って実装
3. **テスト可能性**：早い段階で動作確認できる
4. **価値の高い順**：コア体験を先に実装
5. **変更の少なさ**：基盤を先に固めることで、後の変更を減らす

### 重要な前提
- **基盤を先に実装**：データモデル、DB操作、状態管理を先に整える
- **独立した画面から**：他に依存しない画面を先に実装してテスト
- **最重要画面は最後**：Workout Input Screenは最も複雑なので、他が揃ってから集中実装

---

## Phase 1: 基盤実装（画面実装前の準備）

### 目的
- 画面実装をスムーズにするため、データ層とロジック層を先に整える
- 変更を最小化するため、基盤を固める

### 実装順序

#### 1. プロジェクトセットアップ
- **内容**:
  - Flutterプロジェクト初期化
  - 依存関係追加（`pubspec.yaml`）
    - `sqflite`（SQLite）
    - `riverpod`または`flutter_bloc`（状態管理）
    - `flutter_localizations`（i18n）
    - `intl`（日付・数値フォーマット）
  - フォルダ構造作成（Feature-first）
- **成果物**: プロジェクトの骨格

#### 2. データモデル定義（Entity/Model）
- **内容**:
  - `database-design.md`を基にDartクラスを作成
  - Entity:
    - `SettingsEntity`
    - `ExerciseMasterEntity`
    - `WorkoutSessionEntity`
    - `WorkoutExerciseEntity`
    - `SetRecordEntity`
  - Model（画面表示用、必要に応じて）:
    - `WorkoutSessionModel`（セッション + 種目 + セット）
    - `PreviousRecordModel`（前回記録）
- **成果物**: `lib/data/entities/` 配下のファイル

#### 3. DB操作（DAO、マイグレーション）
- **内容**:
  - `DatabaseHelper`（SQLite接続、マイグレーション）
  - DAO（Data Access Object）:
    - `SettingsDao`
    - `ExerciseMasterDao`
    - `WorkoutSessionDao`
    - `WorkoutExerciseDao`
    - `SetRecordDao`
  - 前回記録取得ロジック（`PreviousRecordService`）
  - 単位変換ロジック（`UnitConverter`）
- **成果物**: `lib/data/dao/` 配下のファイル
- **テスト**: ユニットテストで動作確認

#### 4. 状態管理の基盤（Riverpod/Bloc）
- **内容**:
  - Provider/Blocのセットアップ
  - 主要なProvider:
    - `settingsProvider`（設定状態）
    - `workoutSessionProvider`（セッション状態）
    - `timerProvider`（タイマー状態）
  - Repository層（必要に応じて）
- **成果物**: `lib/providers/` または `lib/blocs/` 配下のファイル

#### 5. i18nリソース（文字列リソース化）
- **内容**:
  - ARBファイル作成（`lib/l10n/`）
    - `app_en.arb`（英語）
    - `app_ja.arb`（日本語）
  - `all-screens-design.md`の「i18n対象文言」を基に文字列定義
  - `flutter_localizations`のセットアップ
- **成果物**: `lib/l10n/` 配下のARBファイル

### Phase 1の完了条件
- データモデルが定義され、DB操作がユニットテストで確認できる
- 状態管理の基盤が整い、Providerが動作する
- i18nリソースが定義され、文字列が切り替わる

---

## Phase 2: P0コア画面（実装順序）

### 目的
- トレ中の体験を成立させる最小限の画面を実装
- 独立した画面から実装し、段階的に複雑さを増やす

### 実装順序

#### 6. Initial Setup Screen（初回設定画面）

**なぜ最初に実装するか**:
- **依存なし**：他の画面に依存せず、独立している
- **データモデルのテスト**：`SettingsDao`の動作確認ができる
- **i18nのテスト**：言語切替が正しく動作するか確認できる
- **アプリの入口**：初回起動時の体験を整える

**実装内容**:
- 言語選択（English / 日本語）
- 単位選択（kg / lb）
- 「始める」ボタン → Home Screenへ遷移
- 設定をDBに保存

**成果物**:
- `lib/features/initial_setup/initial_setup_screen.dart`
- `lib/features/initial_setup/initial_setup_provider.dart`

**テスト**:
- 言語・単位を選択してDBに保存されることを確認
- 「始める」ボタンでHome Screenへ遷移することを確認

---

#### 7. Settings Screen（設定画面）

**なぜ2番目に実装するか**:
- **依存なし**：他の画面に依存せず、独立している
- **Initial Setupと類似**：言語・単位の選択ロジックを再利用できる
- **データモデルの確認**：`SettingsDao`の更新処理を確認できる

**実装内容**:
- 言語切替（English / 日本語）
- 単位切替（kg / lb）
- 即座に保存（保存ボタン不要）
- 戻るボタン → 前の画面に戻る

**成果物**:
- `lib/features/settings/settings_screen.dart`
- `lib/features/settings/settings_provider.dart`

**テスト**:
- 言語・単位を切り替えてDBに保存されることを確認
- 画面全体の文字列が切り替わることを確認

---

#### 8. Home Screen（ホーム画面）

**なぜ3番目に実装するか**:
- **Initial Setupからの遷移先**：アプリのフロー確認ができる
- **Workout Input Screenへの導線**：次の画面への橋渡し
- **記録中セッションの有無でUI分岐**：状態管理の動作確認ができる

**実装内容**:
- 本日の日付表示
- 「トレーニング開始」ボタン → Workout Input Screenへ遷移
- 記録中セッションがある場合：
  - 「記録中の続き」ボタン（強調表示）
  - セッションサマリ（例：3種目、8セット記録済み）
- 設定ボタン → Settings Screenへ遷移

**成果物**:
- `lib/features/home/home_screen.dart`
- `lib/features/home/home_provider.dart`

**テスト**:
- 「トレーニング開始」ボタンで新規セッションが作成されることを確認
- 記録中セッションがある場合、「記録中の続き」ボタンが表示されることを確認
- 設定ボタンでSettings Screenへ遷移することを確認

---

#### 9. Workout Input Screen（トレーニング記録入力画面）★最重要★

**なぜ最後に実装するか**:
- **最も複雑**：種目追加、セット入力、前回記録表示、タイマー統合など機能が多い
- **他の画面が揃ってから**：Home、Settingsが動作することを前提に集中実装
- **データ層が整っている**：Phase 1で基盤が固まっているので、画面実装に集中できる

**実装内容**:
- 種目追加（部位選択 → 種目選択/自由入力）
- 種目カード表示
  - 種目名
  - 前回記録表示（例：前回 40×10 / 40×10 / 35×12）
  - 「前回を再現」ボタン（全セット一括コピー）
- セット入力（重量・回数）
  - セット追加（+ボタン）
  - セット削除（×ボタン）
  - 前回値コピーボタン（セット単位）
- タイマー統合
  - ミニ表示（フローティング）
  - タップで拡大モーダル
  - Start / Pause / Reset
  - 終了通知
- 記録完了ボタン → Home Screenへ遷移

**成果物**:
- `lib/features/workout_input/workout_input_screen.dart`
- `lib/features/workout_input/widgets/` 配下のウィジェット
  - `exercise_card_widget.dart`（種目カード）
  - `set_row_widget.dart`（セット行）
  - `timer_mini_widget.dart`（タイマーミニ表示）
  - `timer_modal_widget.dart`（タイマー拡大モーダル）
  - `exercise_selector_modal.dart`（種目選択モーダル）
- `lib/features/workout_input/workout_input_provider.dart`
- `lib/features/workout_input/timer_provider.dart`

**テスト**:
- 種目追加 → セット入力 → 記録完了の一連のフローを確認
- 前回記録が正しく表示されることを確認
- 前回値コピー（セット単位 + 全セット一括）が動作することを確認
- タイマーが記録入力を邪魔しないことを確認
- 1セット入力が5秒以内で完了できることを体感確認

---

### Phase 2の完了条件
- Initial Setup → Home → Workout Input → 完了のフローが動作する
- Settings画面で言語・単位の切替ができる
- Workout Input Screenで種目・セット入力、前回コピー、タイマー統合が動作する
- 「1セット5秒以内」「前回コピー1タップ」「タイマーが邪魔しない」が体感できる

---

## Phase 3: P0拡張画面（P0コア完成後）

### 目的
- 振り返りと成長実感を提供し、継続動機を高める

### 実装順序

#### 10. Workout Detail Screen（その日の記録詳細画面）

**なぜ最初に実装するか**:
- **データ表示のみ**：入力機能がないので実装が比較的簡単
- **Workout Input Screenの確認**：記録した内容が正しく保存されているか確認できる

**実装内容**:
- 日付、開始〜終了時刻表示
- 種目一覧（種目名 + セット詳細）
- 種目タップ → Exercise Progress Screenへ遷移

**成果物**:
- `lib/features/workout_detail/workout_detail_screen.dart`
- `lib/features/workout_detail/workout_detail_provider.dart`

**テスト**:
- 記録した内容が正しく表示されることを確認
- 種目タップでExercise Progress Screenへ遷移することを確認

---

#### 11. Exercise Progress Screen（種目別グラフ画面）

**なぜ最後に実装するか**:
- **グラフ表示**：可視化ロジックが必要（`fl_chart`等のライブラリ使用）
- **複数回の記録が必要**：テストにはデータが必要

**実装内容**:
- 種目名表示
- グラフ（トップ重量 or 総ボリューム）
- 記録が少ない場合の空状態表示

**成果物**:
- `lib/features/exercise_progress/exercise_progress_screen.dart`
- `lib/features/exercise_progress/exercise_progress_provider.dart`
- `lib/features/exercise_progress/widgets/progress_chart_widget.dart`

**テスト**:
- グラフが正しく表示されることを確認
- 記録が少ない場合に空状態が表示されることを確認

---

### Phase 3の完了条件
- Workout Detail Screenで記録内容が確認できる
- Exercise Progress Screenでグラフが表示され、成長実感が得られる

---

## 実装順序のまとめ（一覧）

| 順序 | 項目 | Phase | 理由 |
|------|------|-------|------|
| 1 | プロジェクトセットアップ | Phase 1 | 基盤準備 |
| 2 | データモデル定義 | Phase 1 | データ層の構築 |
| 3 | DB操作（DAO） | Phase 1 | データ層の構築 |
| 4 | 状態管理の基盤 | Phase 1 | ロジック層の構築 |
| 5 | i18nリソース | Phase 1 | グローバル対応 |
| 6 | **Initial Setup Screen** | Phase 2 | 独立、データモデルのテスト |
| 7 | **Settings Screen** | Phase 2 | 独立、Initial Setupと類似 |
| 8 | **Home Screen** | Phase 2 | Initial Setupからの遷移先 |
| 9 | **Workout Input Screen** | Phase 2 | 最重要、最も複雑、最後に集中実装 |
| 10 | **Workout Detail Screen** | Phase 3 | データ表示のみ、実装が簡単 |
| 11 | **Exercise Progress Screen** | Phase 3 | グラフ表示、テストにデータが必要 |

---

## なぜこの順序か（理由の詳細）

### Phase 1を先に実装する理由
- **基盤を固める**：データモデル、DB操作、状態管理を先に整えることで、画面実装時の変更を最小化
- **テストが容易**：ユニットテストでデータ層の動作を確認できる
- **並行開発が可能**：基盤が整えば、複数の画面を並行して実装できる（チーム開発の場合）

### Initial Setup → Settings → Home → Workout Input の順序
- **Initial Setup**：独立していて、他に影響しない。最初に実装してアプリの入口を整える
- **Settings**：独立していて、Initial Setupと類似。データモデルのテストができる
- **Home**：Initial Setupからの遷移先。Workout Inputへの導線を整える
- **Workout Input**：最も複雑だが、最も重要。他が揃ってから集中実装

### Workout Detail → Exercise Progress の順序
- **Workout Detail**：データ表示のみで実装が簡単。記録内容の確認ができる
- **Exercise Progress**：グラフ表示で実装が複雑。複数回の記録が必要

---

## 次のステップ

この順序に従って実装を進める：
1. **Phase 1の実装**（基盤）
2. **Phase 2の実装**（P0コア画面）
3. **Phase 3の実装**（P0拡張画面）

各Phaseの完了後、動作確認とテストを行い、次のPhaseへ進む。
