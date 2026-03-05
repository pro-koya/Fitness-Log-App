# タイマー バックグラウンド対応 修正計画

## 1. 現状分析

### 1.1 現在の実装

- `lib/providers/timer_provider.dart`: `TimerNotifier` が `WidgetsBindingObserver` を使用
- バックグラウンド時: `_endTime = DateTime.now() + remaining` を保存し、`Timer.periodic` をキャンセル
- フォアグラウンド復帰時: `remaining = _endTime - now` で再計算し、状態を更新

### 1.2 想定される問題

1. **プロセス再起動時**: アプリがOSにキルされた場合、メモリ上の状態が失われる
2. **Observer のタイミング**: `didChangeAppLifecycleState` が呼ばれる前にプロセスがサスペンドされる可能性
3. **状態の永続化なし**: `_endTime` 等がメモリのみで、再起動時に復元できない

## 2. 修正方針

**経過時間を常に実時刻ベースで計算する**方式に変更する。

- タイマー開始時に `startedAt` (DateTime) を記録
- 表示する残り時間は `remaining = initialSeconds - (now - startedAt).inSeconds` で毎回計算
- `Timer.periodic` は UI 更新のトリガーのみに使用（1秒ごとに再計算して state を更新）
- バックグラウンド復帰時は、保存済みの `startedAt` と `initialSeconds` から即座に正しい残り時間を算出

これにより:
- バックグラウンド中はタイマーが動かなくても、復帰時に実経過時間で正しく表示される
- プロセス再起動後も永続化していれば復元可能（オプション）

## 3. 実装計画

### Phase A: 実時刻ベースの計算に変更

| 項目 | 内容 |
|------|------|
| TimerState | `startedAt: DateTime?` を追加（タイマー実行中のみ設定） |
| start() | `startedAt = DateTime.now()` を記録 |
| pause() | `startedAt = null`、`seconds` に現在の残り時間を保存 |
| _tick 時の計算 | `remaining = lastSetSeconds - (now - startedAt!).inSeconds` |
| _handleAppResumed | `startedAt` が有効なら `remaining` を再計算して state 更新、0以下なら終了処理 |

### Phase B: 永続化（プロセスキル耐性）

- `shared_preferences` で以下を保存:
  - `timer_started_at` (epoch ms)
  - `timer_initial_seconds`
  - `timer_is_running`
  - `timer_paused_seconds`（一時停止時の残り秒数）
- アプリ起動時 / 復帰時に復元
- タイマー終了・リセット時にクリア

### Phase C: 既存挙動の維持

- `hasFinished`、通知、`lastSetSeconds` 等の既存ロジックはそのまま
- `TimerIconButton` のスムーズアニメーションは `seconds` を参照するため、state 更新で自動的に追従

## 4. 実装チェックリスト

- [x] Phase A: 内部で `_startedAt` / `_initialSeconds` を管理
- [x] Phase A: start/pause/reset で実時刻ベースの計算
- [x] Phase A: 経過時間を `_initialSeconds - (now - _startedAt).inSeconds` で計算
- [x] Phase A: `_handleAppBackgrounded` / `_handleAppResumed` の見直し
- [x] Phase B: shared_preferences 追加
- [x] Phase B: TimerPersistenceService で永続化・復元

## 5. 実装サマリ（完了）

### 5.1 追加・変更ファイル

| ファイル | 役割 |
|----------|------|
| `lib/services/timer_persistence_service.dart` | タイマー状態の永続化（SharedPreferences） |
| `lib/providers/timer_provider.dart` | 実時刻ベース計算・ライフサイクル対応・永続化連携 |
| `lib/main.dart` | SharedPreferences 初期化と TimerPersistenceService の override |
| `pubspec.yaml` | shared_preferences 依存追加 |

### 5.2 動作の流れ

1. **start()**: `_startedAt = now`, `_initialSeconds = state.seconds` を記録し、永続化
2. **_tick()**: `remaining = _initialSeconds - (now - _startedAt).inSeconds` で残り時間を計算
3. **バックグラウンド**: 永続化して `Timer.periodic` を停止
4. **フォアグラウンド復帰**: `_computeRemaining()` で経過時間を再計算し、state を更新して再開
5. **プロセス再起動**: 永続化データから `_restoreFromPersistence()` で復元
